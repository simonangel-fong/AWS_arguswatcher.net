#!/bin/bash
#Program Name: deploy_django_ubuntu.sh
#Author name: Wenhao Fang
#Date Created: Dec 30th 2023
#Date updated: Dec 30th 2023
#Description of the script: Sets up EC2 to deploy django app using user data.

###########################################################
## Arguments, subject to be changed
###########################################################
P_GITHUB_URL=https://github.com/simonangel-fong/AWS_arguswatcher_net.git # github repo url
P_GITHUB_REPO_NAME=AWS_arguswatcher_net                                  # github repo name
P_PROJECT_NAME=Arguswatcher                                              # the name of django project name
P_HOST_IP=$(dig +short myip.opendns.com @resolver1.opendns.com)          # public IP, call method to update automatically
P_DOMAIN="arguswatcher.net"                                              # the domain name

P_HOME=/home/ubuntu                             # path of home dir
P_VENV_PATH=${P_HOME}/env                       # path of venv
P_REPO_PATH=${P_HOME}/${P_GITHUB_REPO_NAME}     # path of repo
P_PROJECT_PATH=${P_REPO_PATH}/${P_PROJECT_NAME} # path of project, where the manage.py locates.

###########################################################
## Updates Linux package
###########################################################
echo -e "$(date +'%Y-%m-%d %R') Update Linux package starts..."
sudo DEBIAN_FRONTEND=noninteractive apt-get -y update  # update the package on Linux system.
sudo DEBIAN_FRONTEND=noninteractive apt-get -y upgrade # downloads and installs the updates for each outdated package and dependency
echo -e "$(date +'%Y-%m-%d %R') Updating Linux package completed.\n"

###########################################################
## Install python3-venv package
###########################################################
echo -e "$(date +'%Y-%m-%d %R') Install virtual environment package starts..."
sudo DEBIAN_FRONTEND=noninteractive apt-get -y install python3-venv # Install pip package
# DEBIAN_FRONTEND=noninteractive apt-get -y install virtualenv # Install pip package
echo -e "$(date +'%Y-%m-%d %R') Install virtual environment package completed.\n"

###########################################################
## Establish virtual environment
###########################################################
echo -e "$(date +'%Y-%m-%d %R') Create Virtual environment starts..."
sudo rm -rf $P_VENV_PATH     # remove existing venv
python3 -m venv $P_VENV_PATH # Creates virtual environment
echo -e "$(date +'%Y-%m-%d %R') Create Virtual environment completed.\n"

###########################################################
## Download codes from github
###########################################################
echo -e "$(date +'%Y-%m-%d %R') Download codes from github..."
sudo rm -rf ${P_REPO_PATH}           # remove the exsting directory
git clone $P_GITHUB_URL $P_REPO_PATH # clone codes from github
echo -e "$(date +'%Y-%m-%d %R') Download codes from github completed.\n"

###########################################################
## Install app dependencies
###########################################################
echo -e "$(date +'%Y-%m-%d %R') Activate venv.\n"
source ${P_VENV_PATH}/bin/activate # activate venv

echo -e "\n$(date +'%Y-%m-%d %R') Installing dependencies within virtual environment..."
pip install -r ${P_REPO_PATH}/requirements.txt # install dependencies based on the requirements.txt
pip list                                       # list all installed dependencies
echo -e "\n$(date +'%Y-%m-%d %R') Installing dependencies within virtual environment completed.\n"s

## Migrate App
echo -e "$(date +'%Y-%m-%d %R') Django migrate..."
python3 ${P_PROJECT_PATH}/manage.py makemigrations # update changes
python3 ${P_PROJECT_PATH}/manage.py migrate        # migrate changes
echo -e "$(date +'%Y-%m-%d %R') Django migrate completed.\n"

###########################################################
## Test on EC2 with port 8000
###########################################################
# ## Test App
# echo -e "\n$(date +'%Y-%m-%d %R') Testing on 8000 (Crtl+C to quit testing)..."
# python3 ${P_PROJECT_PATH}/manage.py runserver 0.0.0.0:8000
# echo -e "$(date +'%Y-%m-%d %R') Testing completed.\n"

echo -e "$(date +'%Y-%m-%d %R') Deactivate venv.\n"
deactivate

###########################################################
## Install gunicorn in venv
###########################################################
echo -e "$(date +'%Y-%m-%d %R') Installing gunicorn..."
echo -e "$(date +'%Y-%m-%d %R') Activate venv.\n"
source ${P_VENV_PATH}/bin/activate # activate venv
pip install gunicorn               # install gunicorn
deactivate
echo -e "$(date +'%Y-%m-%d %R') Deactivate venv.\n"

###########################################################
## Configuration gunicorn
###########################################################
## Configuration gunicorn.socket
echo -e "$(date +'%Y-%m-%d %R') Create gunicorn socket conf file."
socket_conf=/etc/systemd/system/gunicorn.socket

sudo bash -c "sudo cat >$socket_conf <<SOCK
[Unit]
Description=gunicorn socket

[Socket]
ListenStream=/run/gunicorn.sock

[Install]
WantedBy=sockets.target
SOCK"

## Configuration gunicorn.service
echo -e "$(date +'%Y-%m-%d %R') Create gunicorn service conf file"
service_conf=/etc/systemd/system/gunicorn.service

sudo bash -c "sudo cat >$service_conf <<SERVICE
[Unit]
Description=gunicorn daemon
Requires=gunicorn.socket
After=network.target

[Service]
User=root
Group=www-data 
WorkingDirectory=${P_PROJECT_PATH}
ExecStart=/home/ubuntu/env/bin/gunicorn \
    --access-logfile - \
    --workers 3 \
    --bind unix:/run/gunicorn.sock \
    ${P_PROJECT_NAME}.wsgi:application

[Install]
WantedBy=multi-user.target
SERVICE"

###########################################################
## Apply gunicorn configuration
###########################################################
echo -e "$(date +'%Y-%m-%d %R') Apply gunicorn configuration."
sudo systemctl daemon-reload          # reload daemon
sudo systemctl start gunicorn.socket  # Start gunicorn
sudo systemctl enable gunicorn.socket # enable on boots
sudo systemctl restart gunicorn       # restart gunicorn
# sudo systemctl status gunicorn        # Start gunicorn

# # visit port 8000 to test
# echo -e "$(date +'%Y-%m-%d %R') Test gunicorn..."
# cd ${P_PROJECT_PATH}
# gunicorn --bind 0.0.0.0:8000 ${P_PROJECT_NAME}.wsgi:application
# cd ~
# echo -e "$(date +'%Y-%m-%d %R') Test gunicorn completed.\n"

###########################################################
## Configuration nginx
###########################################################
echo -e "$(date +'%Y-%m-%d %R') Installing nginx package..."
sudo apt-get install -y nginx # install nginx
echo -e "$(date +'%Y-%m-%d %R') Nginx package installed."

echo -e "$(date +'%Y-%m-%d %R') Configure nginx."
# overwrites user
nginx_conf=/etc/nginx/nginx.conf
sudo sed -i '1cuser root;' $nginx_conf

# create conf file
django_conf=/etc/nginx/sites-available/django.conf
sudo bash -c "cat >$django_conf <<DJANGO_CONF
server {
listen 80;
server_name ${P_HOST_IP} ${P_DOMAIN} www.${P_DOMAIN};
location = /favicon.ico { access_log off; log_not_found off; }
location /static/ {
    root ${P_PROJECT_PATH};
}

location /media/ {
    root ${P_PROJECT_PATH};
}

location / {
    include proxy_params;
    proxy_pass http://unix:/run/gunicorn.sock;
}
}
DJANGO_CONF"

#  Creat link in sites-enabled directory
sudo ln -sf /etc/nginx/sites-available/django.conf /etc/nginx/sites-enabled

# restart nginx
echo -e "$(date +'%Y-%m-%d %R') Restart nignx."
sudo nginx -t
sudo systemctl restart nginx

###########################################################
## Configuration supervisor
###########################################################
echo -e "\n$(date +'%Y-%m-%d %R') Installing supervisor package..."
sudo apt-get install -y supervisor # install supervisor
echo -e "$(date +'%Y-%m-%d %R') Supervisor package installed."

echo -e "$(date +'%Y-%m-%d %R') Configure supervisor for gunicorn"
sudo mkdir -p /var/log/gunicorn # create directory for logging

supervisor_gunicorn=/etc/supervisor/conf.d/gunicorn.conf # create configuration file
sudo bash -c "cat >$supervisor_gunicorn <<SUP_GUN
[program:gunicorn]
    directory=${P_PROJECT_PATH}
    command=${P_VENV_PATH}/bin/gunicorn --workers 3 --bind unix:/run/gunicorn.sock  ${P_PROJECT_NAME}.wsgi:application
    autostart=true
    autorestart=true
    stderr_logfile=/var/log/gunicorn/gunicorn.err.log
    stdout_logfile=/var/log/gunicorn/gunicorn.out.log

[group:guni]
    programs:gunicorn
SUP_GUN"

echo -e "$(date +'%Y-%m-%d %R') Apply configuration."
sudo supervisorctl reread # tell supervisor read configuration file
sudo supervisorctl update # update supervisor configuration
sudo supervisorctl reload # Restarted supervisord
# sudo supervisorctl status # verify configuration status
