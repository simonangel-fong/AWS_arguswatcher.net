#!/bin/bash

# Program Name: beforeInstall.sh
# Author name: Wenhao Fang
# Date Created: Jan 1st 2024
# Date updated: Jan 2nd 2024
# Description of the script:
#   Script for afterinstall, including packages installation.

###########################################################
## Arguments, subject to be changed
###########################################################
P_GITHUB_REPO_NAME=AWS_arguswatcher_net                         # github repo name
P_PROJECT_NAME=Arguswatcher                                     # the name of django project name
P_HOST_IP=$(dig +short myip.opendns.com @resolver1.opendns.com) # public IP, call method to update automatically
P_DOMAIN="arguswatcher.net"

P_HOME=/home/ubuntu                             # path of home dir
P_LOG=${P_HOME}/deploy_log                      # log file
P_VENV_PATH=${P_HOME}/env                       # path of venv
P_REPO_PATH=${P_HOME}/${P_GITHUB_REPO_NAME}     # path of repo
P_PROJECT_PATH=${P_REPO_PATH}/${P_PROJECT_NAME} # path of project, where the manage.py locates.

log() {
    sudo echo -e "$(date +'%Y-%m-%d %R'): ${1}" >>$P_LOG
}

touch $P_LOG

###########################################################
## Establish virtual environment
###########################################################
# Remove existing venv
sudo rm -rf $P_VENV_PATH &&
    log "remove existing venv" || log "Fail: remove existing venv"

# Install python3-venv package
sudo apt-get -y install python3-venv &&
    log "Install python3-venv package" || log "Fail: Install python3-venv package"

# Creates virtual environment
python3 -m venv $P_VENV_PATH &&
    log "Creates virtual environment" || log "Fail: Creates virtual environment"

###########################################################
## Install app dependencies
###########################################################
# activate venv
source ${P_VENV_PATH}/bin/activate &&
    log "Activate venv" || log "Fail: Activate venv"

# install dependencies based on the requirements.txt
pip install -r ${P_REPO_PATH}/requirements.txt &&
    log "install dependencies based on the requirements.txt" || log "Fail: install dependencies based on the requirements.txt"

# deactivate venv
deactivate &&
    log "Deactivate venv" || log "Fail: Deactivate venv"

###########################################################
## Install gunicorn in venv
###########################################################
# activate venv
source ${P_VENV_PATH}/bin/activate &&
    log "Activate venv" || log "Fail: Activate venv"

# install gunicorn
pip install gunicorn &&
    log "install gunicorn" || log "Fail: install gunicorn"

# deactivate venv
deactivate &&
    log "Deactivate venv" || log "Fail: Deactivate venv"

###########################################################
## Configuration gunicorn.socket
###########################################################
socket_conf=/etc/systemd/system/gunicorn.socket

sudo bash -c "sudo cat >$socket_conf <<SOCK
[Unit]
Description=gunicorn socket

[Socket]
ListenStream=/run/gunicorn.sock

[Install]
WantedBy=sockets.target
SOCK" &&
    log "Configure gunicorn.socket" || log "Fail: Configure gunicorn.socket"

###########################################################
## Configuration gunicorn.service
###########################################################
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
SERVICE" &&
    log "Configure gunicorn.service." || log "Fail: Configure gunicorn.service."

###########################################################
## Apply gunicorn configuration
###########################################################
# reload daemon
sudo systemctl daemon-reload &&
    log "reload daemon." || log "Fail: reload daemon."

# Start gunicorn
sudo systemctl start gunicorn.socket &&
    log "Start gunicorn." || log "Fail: Start gunicorn."

# enable on boots
sudo systemctl enable gunicorn.socket &&
    log "enable on boots." || log "Fail: enable on boots."

# restart gunicorn
sudo systemctl restart gunicorn &&
    log "restart gunicorn." || log "Fail: restart gunicorn."

###########################################################
## Configuration nginx
###########################################################
# install nginx
sudo apt-get install -y nginx &&
    log "install nginx." || log "Fail: install nginx."

nginx_conf=/etc/nginx/nginx.conf
# overwrites user
sudo sed -i '1cuser root;' $nginx_conf &&
    log "overwrites user." || log "Fail: overwrites user."

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
DJANGO_CONF" &&
    log "create django.conf file." || log "Fail: create django.conf file."

#  Creat link in sites-enabled directory
sudo ln -sf /etc/nginx/sites-available/django.conf /etc/nginx/sites-enabled &&
    log "Creat link in sites-enabled directory." || log "Fail: Creat link in sites-enabled directory."

# restart nginx
sudo systemctl restart nginx &&
    log "restart nginx." || log "Fail: restart nginx."

###########################################################
## Configuration supervisor
###########################################################
# install supervisor
sudo apt-get install -y supervisor

# create directory for logging
sudo mkdir -p /var/log/gunicorn &&
    log "create directory for logging." || log "Fail: create directory for logging."

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
SUP_GUN" &&
    log "create supervisor file for gunicorn logging." || log "Fail: create supervisor file for gunicorn logging."

# tell supervisor read configuration file
sudo supervisorctl reread &&
    log "tell supervisor read configuration file." || log "Fail: tell supervisor read configuration file."

# update supervisor configuration
sudo supervisorctl update &&
    log "update supervisor configuration." || log "Fail: update supervisor configuration."

sudo systemctl daemon-reload &&
    log "daemon-reload." || log "Fail: daemon-reload."

# Restarted supervisord
sudo supervisorctl reload &&
    log "Restarted supervisord." || log "Fail: Restarted supervisord."
