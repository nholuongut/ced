![](https://i.imgur.com/waxVImv.png)
### [View all Roadmaps](https://github.com/nholuongut/all-roadmaps) &nbsp;&middot;&nbsp; [Best Practices](https://github.com/nholuongut/all-roadmaps/blob/main/public/best-practices/) &nbsp;&middot;&nbsp; [Questions](https://www.linkedin.com/in/nholuong/)
<br/>

# How to use
Run one of the following commands (curl or wget) to install the setup script
```
curl https://raw.githubusercontent.com/CIP43R/setup-linux-server/master/install.sh -o install.sh && bash install.sh
```
```
wget -qO- https://raw.githubusercontent.com/CIP43R/setup-linux-server/master/install.sh && bash install.sh
```

After installation, either open a new terminal or execute `source ~/.bashrc` to use it immediately.
Then you can use `ced` everywhere on your machine to use this tool (it will add itself to the PATH env variable).
The package itself will be copied into `/opt/ced`. Logs and backups will be placed in there, too.

# What is this?
This is just a small personal thing I created. I like experimenting with servers, so I often end up destroying mine in incredibly interesting ways.
Sometimes it's easier to reinstall it, and since my snapshots are getting deleted after a while, I wanted to have a quick way of bootstrapping everything I need.

It's basically a small script that lets you pick some very basic but useful tools and configs for a nice and safe admin UX.

This repo is mostly just for my personal educational purposes! I'm experimenting with linux and am not an expert with either bash scripting or security measures. Please keep that in mind in case you want to use this for anything.

However, I would like to help others learn aswell, so I will try my best to write down my experiences, practises and steps in comments (of course no guarantee that it will be 100% correct or perfect!)

## What can it do?
It can make your life easier if you i.e. just want to create a small server for testing, development, gaming whatever.
The focus lies on the security aspect and easy configuration. I provided the (in my opinion) most useful and important things to have on a server, as well as the most crucial basic configurations for these.

# Expand / Edit
You can either create a `config.conf` from the `config.template`, or let the CLI use the defaults (also taken from `config.template`).
You can just clone this repo to your server and adjust all the third party configs you'd like to. Since they are all in `thirdparty` you have all the configs you need in place!
Protip: If you run `ced i configs <thirdparty app or *>`, all the config files will be backuped and copied again (also performs service restarts).

The original configs for all third party apps will be saved in /backup, everytime you use this tool. You can change this behavior by setting `backups` to either `overwrite` or `off` in your `config.conf` file.

## Config
| Option | Explanation | Possible values |
| ------ | ----------- | --------------- |
| first_run | Whether this is the first run of the tool. Should not be touched, at least this won't give you anything | true, false |
| log_level | The level at which certain logs will be shown (or hidden) | 1 = Debug, 2 = Verbose, 3 = Info, 4 = Warnings, 5 = Errors\nTip: Enable verbose logging if you want to understand what's happening behind the scenes ;D |


# Full list of supported packages
Some of these packages will be installed on first run automatically, because they are essential.

## Essential packages
| Package | Purpose | Notes |
| ------- | ------- | ----- |
| fail2ban | Detect and ban intruders | 
| ssh | openssh server to connect to your server | Will automatically be configured to use RSA and optionally 2FA (google auth) |
| ufw | Simply but effective firewall |

## Non-essential packages
| Package | Purpose | 
| ------- | ------- |
| vsftpd | Secure FTP server |
| nginx | Webserver, easy configurable |
| webmin | Rather ugly, but useful server management / admin GUI, good for beginners |
| certbot | Handy tool to get and maintain SSL certificates from Let's Encrypt |
| docker | If you don't know what this is, you probably don't need it. |
| portainer | Docker management UI |

# TODO / Plans
- Make the script usable for multi-user purposes
- More options for the security measures (such as fail2ban)
- Cronjob to regularly update everything
- Security checks (suspicious networt traffic, rootkits etc.)
- Time or condition limited service (vsftpd, custom servers)
- Allow apache and certbot with apache, too
- Add more comments
- Proper check if certain packages are installed (those that are required)
- More functionality (ced nginx add, ced nginx activate/deactivate etc.)

# Things to keep in mind regarding security
- SSH servers should ideally be secured with RSA keys. They are a fair bit safer than passwords. It can be a bit tricky to set it up, especially for a beginner. You can easily misconfigure it and end up locking yourself out from your own server! This is why it's advised to test the connection in a new terminal before closing the one where you are adjusting your config. Because fun fact: The SSH session you are in will remain, even after changing the SSH config and restarting the service! That way you can test out different configurations and just open a new terminal to see if you can still login.
- Fail2ban basically detects intruders by checking the logs of certain applications. Each application will have a jail, which basically is a configuration to help fail2ban detect odd behavior. Whenever system authentication is being used (i.e. webmin), you technically don't have to add an extra jail, unless you want to filter it separately and have more distinct logs for your bans. Webmin however uses the same logs as SSH.
- VSFTPD is (here) configured to allow all local linux users to use ftp, but restricts them to only get access to their home dir. You should probably keep it this way. If you want to be extra safe you can specify a custom folder in the home folders to only give users access to a minimal portion.
- SELinux is a great way to secure your server if you want to have more control over permissions & roles. However, it's quite complicated to set up and not recommended for a beginner (in my opinion)
- Ports should be kept closed whenever possible. Each open port is a way for attackers to spam your server with more requests and attacks. If an app runs on a port in your local network (i.e. Webmin on 10000) it'd be better to create an nginx reverse proxy config and pass the incoming requests to http/https to that app. Opening the port of your app will allow everyone on the internet to access it.

# Useful locations to keep in sight

Important logs are in `/var/log`

# Useful commands to keep in mind

### List all IPs banned by fail2ban:
`sudo zgrep 'Ban' /var/log/fail2ban.log*`

### List all system groups pretty:
`cut -d: -f1 /etc/group`

### Get error logs if a service didn't start

`sudo journalctl | grep -i <SERVICE NAME>`


![](https://i.imgur.com/waxVImv.png)
# I'm are always open to your feedback🚀
# **[Contact Me🇻]**
* [Name: Nho Luong]
* [Telegram](+84983630781)
* [WhatsApp](+84983630781)
* [PayPal.Me](https://www.paypal.com/paypalme/nholuongut)
* [Linkedin](https://www.linkedin.com/in/nholuong/)

![](https://i.imgur.com/waxVImv.png)
![](Donate.jpg)
[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/nholuong)

# License🇻
* Nho Luong (c). All Rights Reserved.🌟
