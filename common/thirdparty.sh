#!/bin/bash

install_ssh() {
  # Install SSH
  log "Installing openSSH Server" INFO
  sudo apt install openssh-server -y 2> $errorlog 1> $outputlog
  sudo systemctl enable ssh 2> $errorlog 1> $outputlog

  # Configure SSH
  sudo mkdir -p /home/$adminusr/.ssh
  sudo touch /home/$adminusr/.ssh/authorized_keys
  read -p "Fill in RSA pub key (leave empty to skip): " adminkey
  
  # TODO: change target dir to whatever will be in the sshd config at this time, and only default to home
  # Check if skipped
  if [ ! -z "$adminkey" ]; then
    # Check if the given SSH key already exists, otherwise add it to the authorized keys
    if [[ $(file_contains "$adminkey" /home/$adminusr/.ssh/authorized_keys) = true ]]; then
      log "SSH key already present. Skipping." INFO
    else
      append_to_file "$adminkey" /home/$adminusr/.ssh/authorized_keys
    fi
  fi

  # Prepare allowed users and copy our SSH config (not waiting for config to keep our config clean)
  # TODO let user decide, only add user if property already exists!
  allowusers="AllowUsers $adminusr"
  yes | sudo cp $third_party/ssh/sshd_config /etc/ssh/sshd_config

  # Check if allowed user already present
  if [[ $(file_contains "$allowusers" /etc/ssh/sshd_config) = true ]]; then
    log "User already in allowed section. Skipping." INFO
  else
    append_to_file "$allowusers" /etc/ssh/sshd_config
  fi
  log "Configured sshd to use RSA authentication only with provided key" INFO

  # Optionally configure 2FA
  if [[ $(confirm "Enable 2FA (google authenticator?)") = true ]]; then
    sudo apt install libpam-google-authenticator -y 2> $errorlog 1> $outputlog
    echo "Scan the following QR code with the google authenticator app and insert the code when prompted."
    # Make sure to set the parameters here to prevent long annoying interactive mode. These are the recommended settings
    # https://manpages.ubuntu.com/manpages/impish/man8/pam_google_authenticator.8.html
    sudo -u $adminusr google-authenticator -t -d -f --step-size=30 --rate-limit=2 --rate-time=30 --window-size=3

    # Add google authenticator to pam config if not present
    if [[ $(file_contains "auth required pam_google_authenticator.so" /etc/pam.d/sshd) = true ]]; then
      log "Google authenticator already configured for PAM. Skipping..." VERBOSE
    else
      append_to_file "auth required pam_google_authenticator.so" /etc/pam.d/sshd
    fi
    # replace_all pam and ssh config properties to use PAM (required for google auth) and add keyboard interactive method for auth
    replace_all "@include common-auth" "#@include common-auth" /etc/pam.d/sshd
    replace_all "AuthenticationMethods publickey,password publickey" "AuthenticationMethods publickey,password publickey,keyboard-interactive" /etc/ssh/sshd_config
    replace_all "UsePAM no" "UsePAM yes" /etc/ssh/sshd_config
    log "Set up google authenticator for 2FA authentication" INFO
  else
    # replace_all pam and ssh config properties to NOT use PAM (required only for google auth) and remove keyboard interactive method for auth
    replace_all "auth required pam_google_authenticator.so" "" /etc/pam.d/sshd
    replace_all "AuthenticationMethods publickey,password publickey,keyboard-interactive" "AuthenticationMethods publickey,password publickey" /etc/ssh/sshd_config
    replace_all "UsePAM yes" "UsePAM no" /etc/ssh/sshd_config
    replace_all "#@include common-auth" "@include common-auth" /etc/pam.d/sshd
  fi
  sudo systemctl restart sshd.service

  # Allow ufw
  if [ $(command_exists "ufw") = false ]; then
    install_ufw
  fi 
  sudo ufw allow ssh 2> $errorlog 1> $outputlog
}

install_ufw() {
  # Install ufw
  log "Installing ufw firewall" INFO
  sudo apt install ufw -y 2> $errorlog 1> $outputlog
  echo "y" | sudo ufw --force enable 2> $errorlog 1> $outputlog
  log "Installed and enabled ufw firewall" INFO
}

install_fail2ban() {
  # Install and setup fail2ban with custom config
  log "Installing fail2ban" INFO
  sudo apt install fail2ban -y 2> $errorlog 1> $outputlog
  yes | sudo cp $third_party/fail2ban/jail.local /etc/fail2ban/
  yes | sudo cp $third_party/fail2ban/fail2ban.local /etc/fail2ban/
  yes | sudo cp $third_party/fail2ban/iptables-multiport.conf /etc/fail2ban/action.d/
  sudo service fail2ban restart
  log "Installed and configured fail2ban. May they come." INFO
}

install_selinux() {
  log "Installing SELinux. Do not interrupt the process." WARN
  # Stop apparmor. This is the default service for most linux distributions to manage permissions / roles
  sudo systemctl stop apparmor
  sudo systemctl disable apparmor
  # Install SELinux packages and active it
  sudo apt install policycoreutils selinux-basics selinux-utils -y 2> $errorlog 1> $outputlog
  sudo selinux-activate 2> $errorlog 1> $outputlog
  if ! [[ $(getenforce) =~ "Disabled" ]]; then
    log "SELinux is not ready to work yet. Something went wrong while activating" ERROR
    exit 1
  fi
  log "Installed SELinux. System will be rebooted after successful setup." INFO
}

install_docker() {
  # Install and test installation
  log "Installing docker...Please wait" INFO
  sudo apt install ca-certificates curl gnupg lsb-release -y 2> $errorlog 1> $outputlog
  sudo mkdir -p /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --yes --dearmor -o /etc/apt/keyrings/docker.gpg
  append_to_file \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) stable" /etc/apt/sources.list.d/docker.list
  sudo apt update 2> $errorlog 1> $outputlog
  sudo apt install docker-ce docker-ce-cli containerd.io docker-compose-plugin -y 2> $errorlog 1> $outputlog

  # Run test container to see if it works or not
  sudo docker run hello-world 2> $errorlog 1> $outputlog || {
    log "Docker hello world container was not booted correctly. You need to check the installation and try again" ERROR
    exit 1
  }
  log "Installed docker successfully" INFO

}

install_webmin() {
  log "Installing webmin...Please wait" INFO

  # Install or install requirements and try again if unsuccessful
  wget http://prdownloads.sourceforge.net/webadmin/webmin_2.011_all.deb
  sudo dpkg --install webmin_2.011_all.deb 2> $errorlog 1> $outputlog || {
    sudo apt install perl libnet-ssleay-perl openssl libauthen-pam-perl libpam-runtime libio-pty-perl apt-show-versions python unzip shared-mime-info -y 2> $errorlog 1> $outputlog
    sudo dpkg --install webmin_2.011_all.deb 2> $errorlog 1> $outputlog || {
      log "Something went wrong while installing webmin." ERROR
      exit 1
    }
  }

  # Check for nginx config
  if [[ $(confirm "Would you like me to create a reverse config for webmin to be accessible through the internet (installs nginx if not present)?") = true ]]; then
    read -p "Please enter a hostname for webmin (i.e. webmin.yourdomain.com):" hostname
    sudo cp $third_party/nginx/webmin.conf /etc/nginx/sites-available
    replace_all "{HOSTNAME}" $hostname "/etc/nginx/sites-available/webmin.conf"

    # TODO: ask for cert!
    sudo service nginx restart
  fi
  
  # Add to fail2ban jail
  jail "webmin-auth"

  log "Installed webmin successfully" INFO
}

install_nginx() {
  # Install and optionally add a reverse proxy conf
  log "Installing nginx...Please wait" INFO
  sudo apt install nginx -y 2> $errorlog 1> $outputlog

  # Remove default nginx config
  log "Removing default nginx config" VERBOSE
  #sudo rm -f /etc/nginx/sites-available/default
  #sudo rm -f /etc/nginx/sites-enabled/default

  # Optionally create nginx config
  if [[ $(confirm "Installed nginx. Would you like to create a reverse proxy configuration right now?") = true ]]; then 
    sudo nano /etc/nginx/sites-available/reverse-proxies.conf
    nginx_link
    nginx_ok
    log "Created /etc/nginx/sites-available/reverse-proxies.conf and tested it! You're good to go." INFO
  fi

  # Restart nginx
  log "Restarting nginx service" DEBUG
  sudo service nginx restart

  # Add to fail2ban jail and restart its service
  log "Adding nginx http authentication to fail2ban" DEBUG
  jail "nginx\-http\-auth" # Needs to be escaped!
  log "Restarting fail2ban service" DEBUG
  sudo service fail2ban restart

  log "Installed and configured nginx successfully" INFO
}

install_portainer() {
  log "Installing portainer...Please wait" INFO

  # Check if docker installed, otherwise prompt for install
  # TODO error fix
  if [ $(command_exists "docker") = false ]; then
    if [[ $(confirm "No docker installation found. Would you like to install it now (required to install portainer)?") = true ]]; then 
      install_docker
    else 
      log "Portainer installation cancelled." INFO
      return [n]
    fi
  fi
  
  # Add portainer volume and run its docker container on exposed default port
  log "Creating portainer volume and running container..." INFO
  sudo docker volume create portainer_data 2> $errorlog 1> $outputlog
  sudo docker run -d -p 8000:8000 -p 9443:9443 --name portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce:latest 2> $errorlog 1> $outputlog
  
  # Check for nginx config
  if [[ $(confirm "Would you like me to create a reverse config for portainer to be accessible through the internet (installs nginx if not present)?") = true ]]; then
    read -p "Please enter a hostname for portainer (i.e. portainer.yourdomain.com):" hostname
    sudo cp $third_party/nginx/portainer.conf /etc/nginx/sites-available
    replace_all "{HOSTNAME}" $hostname "/etc/nginx/sites-available/portainer.conf"
    nginx_link
    nginx_ok
    # TODO: ask for cert!
    sudo service nginx restart
  fi

  log "Installed portainer.Open a browser and go to http://${hostname:-public_ip} to create a portainer admin user." INFO
}

install_vsftpd() {
  # Install and create cert for vsftpd
  log "Installing vsftpd...Please wait" INFO
  sudo apt install vsftpd -y 2> $errorlog 1> $outputlog

  # Check if passive or active mode. Currently it's only for passive mode.
  # TODO: make sure to renew this or use certbot
  log "Creating secure ssl certificate for vsftpd (works without domain)..." INFO 
  if [ $(file_exists "/etc/ssl/private/vsftpd.pem") = false ]; then
    sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/vsftpd.pem -out /etc/ssl/private/vsftpd.pem
  fi

  # Backup old config
  timestamp=$(date +%s)
  backup_folder=$cwd/backups/vsftpd/$timestamp/
  sudo mkdir -p $backup_folder
  sudo cp /etc/vsftpd.conf $backup_folder

  # Copy our config
  sudo cp $third_party/vsftpd/vsftpd.conf /etc/

  # Allow ports for vsftpd
  if [ $(command_exists "ufw") = false ]; then
    install_ufw
  fi 
  sudo ufw allow 20/tcp,21/tcp,990/tcp,40000:50000/tcp 2> $errorlog 1> $outputlog

  # Add to fail2ban jail
  jail "vsftpd"

  # TODO: Ask for users
  # Restart vsftpd and fail2ban with new jail
  sudo service vsftpd restart
  sudo service fail2ban restart
  log "Installed vsftpd. Make sure to add all users you want to grant access to /etc/vsftpd.userlist" INFO
}

install_certbot() {
  # Install certbot for nginx
  log "Installing and configuring certbot..." INFO
  sudo apt install certbot python3-certbot-nginx -y 2> $errorlog 1> $outputlog

  # Check if there's any nginx config
  if [ $(any_file_exists "/etc/nginx/sites-enabled/*") = false ]; then
    log "There is no nginx config present. Certbot will not work without one. Aborting..." WARN
    return [n]
  fi

  # Allow full nginx profile and remove only the http rules (since http traffic will be redirected when using certs)
  log "Allow full nginx profile except for HTTP using ufw" VERBOSE
  if [ $(command_exists "ufw") = false ]; then
    install_ufw
  fi 
  sudo ufw allow 'Nginx Full' 2> $errorlog 1> $outputlog
  sudo ufw delete allow 'Nginx HTTP' 2> $errorlog 1> $outputlog


  # Check if certbot installation was alright
  log "Testing certbot installation by running a dry run renew" VERBOSE
  sudo certbot renew --dry-run || {
    log "It seems like there's an error with the certbot/nginx configuration. Please check your config and run certbot again." ERROR
    exit 1
  }

  # Install renew cronjob
  log "Installing auto cert renew cronjob" VERBOSE
  crontab -l | { cat; echo "0 12 * * * /usr/bin/certbot renew --quiet"; } | crontab -
}
