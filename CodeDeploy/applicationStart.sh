#!/bin/bash

# Program Name: applicationStart.sh
# Author name: Wenhao Fang
# Date Created: Jan 1st 2024
# Date updated: Jan 1st 2024
# Description of the script:
#   Script for application start, including Django migrationgs

###########################################################
## Arguments
###########################################################
P_GITHUB_REPO_NAME=AWS_arguswatcher_net # github repo name
P_PROJECT_NAME=Arguswatcher             # the name of django project name

P_HOME=/home/ubuntu                             # path of home dir
P_LOG=${P_HOME}/log                             # log file
P_VENV_PATH=${P_HOME}/env                       # path of venv
P_REPO_PATH=${P_HOME}/${P_GITHUB_REPO_NAME}     # path of repo
P_PROJECT_PATH=${P_REPO_PATH}/${P_PROJECT_NAME} # path of project, where the manage.py locates.

log() {
    sudo echo -e "$(date +'%Y-%m-%d %R'): ${1}" >>$P_LOG
}

###########################################################
## Django migrations
###########################################################
# activate venv
source ${P_VENV_PATH}/bin/activate &&
    log "activate venv" || log "Fail: activate venv"

# update changes
python3 ${P_PROJECT_PATH}/manage.py makemigrations &&
    log "update changes" || log "Fail: update changes"

# migrate changes
python3 ${P_PROJECT_PATH}/manage.py migrate &&
    log "migrate changes" || log "Fail: migrate changes"

# python3 manage.py collectstatic
# python3 ${P_PROJECT_PATH}/manage.py collectstatic # update changes

###########################################################
## restart gunicorn + restart
###########################################################
sudo service gunicorn restart &&
    log "restart gunicorn" || log "Fail: restart gunicorn"

sudo service nginx restart &&
    log "restart nginx" || log "Fail: restart nginx"
