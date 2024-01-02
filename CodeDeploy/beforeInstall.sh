#!/usr/bin/env bash

#Program Name: beforeInstall.sh
#Author name: Wenhao Fang
#Date Created: Jan 1st 2024
#Date updated: Jan 1st 2024
#Description of the script:
# Script for application start, including removal of existing folde

###########################################################
## Arguments
###########################################################

P_HOME=/home/ubuntu                         # path of home dir
P_LOG=${P_HOME}/log                         # log file
P_GITHUB_REPO_NAME=AWS_arguswatcher_net     # github repo name
P_REPO_PATH=${P_HOME}/${P_GITHUB_REPO_NAME} # path of repo
log() {
    sudo echo -e "$(date +'%Y-%m-%d %R'): ${1}" >>$P_LOG
}

sudo rm -rf $P_REPO_PATH
log "remove existing folder"
