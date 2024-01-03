#!/bin/bash

# Program Name: userdata_codedeploy.sh
# Author name: Wenhao Fang
# Date Created: Jan 1st 2024
# Date updated: Jan 2nd 2024
# Description of the script:
#   Script for user data, including installation of codedeploy.

###########################################################
## Arguments
###########################################################
P_HOME=/home/ubuntu          # path of home dir
P_LOG=${P_HOME}/userdata_log # log file

log() {
    echo -e "$(date +'%Y-%m-%d %R'): ${1}" >>$P_LOG
}

touch $P_LOG

###########################################################
## Install CodeDeploy
###########################################################
# update the package on Linux system.
sudo DEBIAN_FRONTEND=noninteractive apt-get -y update &&
    log "update os packages." || log "Fail: update os packages"

# upgrade the package on Linux system.
sudo DEBIAN_FRONTEND=noninteractive apt-get -y upgrade &&
    log "upgrade os packages." || log "Fail: upgrade os packages"

# install ruby-full package
sudo apt install -y ruby-full &&
    log "install ruby-full package" || log "Fail: install ruby-full package"

# install wget utility
sudo apt install -y wget &&
    log "install wget utility" || log "Fail: install wget utility"

# download codedeploy on the EC2
wget https://aws-codedeploy-us-east-1.s3.amazonaws.com/latest/install &&
    log "download codedeploy" || log "Fail: download codedeploy"

# change permission of the install file
sudo chmod +x ./install &&
    log "change permission" || log "Fail: change permission"

# install and log the output to the tmp/logfile.file
sudo ./install auto >/tmp/logfile &&
    log "install and log the output" || log "Fail: install and log the output"

###########################################################
## Create env file
###########################################################
# create env file for django project
P_ENV=${P_HOME}/.env # env file
sudo bash -c "cat >$P_ENV <<ENV_FILE
DEBUG=False
SECRET_KEY='SECRET_KEY'
DATABASE='DATABASE'
HOST='HOST'
USER='USER'
PASSWORD='PASSWORD'
ENV_FILE" &&
    log "create env file." || log "Fail: create env file."

###########################################################
## install mysql package
###########################################################
sudo apt install -y mysql-client
