#!/bin/bash

backup() {
  backup_folder=$cwd/backups/$2
  mkdir -p $backup_folder
  sudo cp $1 $backup_folder
  log "Created a copy of $2 config in $backup_folder" INFO
}
update() {
  # Make sure to backup important config files before update
  backup "/etc/netplan/*" "netplan"
  
  log "Installing updates...this may take a while" INFO
  { 
    sudo apt update -y && sudo apt upgrade -y
  } 2> $errorlog 1> $outputlog
  log "Updated system packages" INFO
}
jail() {
  if [[ $(command_exists "fail2ban-client") = false ]]; then
    log "fail2ban installation not found. Installing now..." INFO
    install_fail2ban
  fi
  log "Enabling fail2ban jail $1" VERBOSE
  replace_all "[$1]" "[$1]\nenabled=true" /etc/fail2ban/jail.local
}
nginx_link() {
  # Create symlink (good practise)
  log "Creating symlink for nginx config" VERBOSE
  sudo ln -sf /etc/nginx/sites-available/* /etc/nginx/sites-enabled/
}
nginx_ok() {
  if [[ $(command_exists "nginx") = false ]]; then
    log "nginx installation not found. Installing now..." INFO
    install_nginx
  fi

  if out=$(sudo nginx -t 2>&1); then
    log "nginx config is OK." INFO
  else
    log "There is an issue with the nginx config. Please check the logs at $errorlog" ERROR
    exit 1
  fi
}
append_to_file() {
  # TODO: doesn't work
  log "Appending $1 to file $2" DEBUG
  echo -e "\n$1" | sudo tee -a $2 &> /dev/null 
}