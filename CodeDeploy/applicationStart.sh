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
P_VENV_PATH=${P_HOME}/env                       # path of venv
P_REPO_PATH=${P_HOME}/${P_GITHUB_REPO_NAME}     # path of repo
P_PROJECT_PATH=${P_REPO_PATH}/${P_PROJECT_NAME} # path of project, where the manage.py locates.

###########################################################
## Django migrations
###########################################################
source ${P_VENV_PATH}/bin/activate # activate venv
echo -e "$(date +'%Y-%m-%d %R') activate venv" >>~/log

python3 ${P_PROJECT_PATH}/manage.py makemigrations # update changes
echo -e "$(date +'%Y-%m-%d %R') update changes" >>~/log

python3 ${P_PROJECT_PATH}/manage.py migrate # migrate changes
echo -e "$(date +'%Y-%m-%d %R') migrate changes" >>~/log

# python3 manage.py collectstatic
# python3 ${P_PROJECT_PATH}/manage.py collectstatic # update changes

###########################################################
## restart gunicorn + restart
###########################################################
sudo service gunicorn restart
echo -e "$(date +'%Y-%m-%d %R') restart gunicorn" >>~/log

sudo service nginx restart
echo -e "$(date +'%Y-%m-%d %R') restart nginx" >>~/log
