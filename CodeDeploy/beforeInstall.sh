#!/usr/bin/env bash

#Program Name: beforeInstall.sh
#Author name: Wenhao Fang
#Date Created: Jan 1st 2024
#Date updated: Jan 1st 2024
#Description of the script:
# Script for application start, including removal of existing folde

sudo rm -rf /home/ubuntu/AWS_arguswatcher_net/*
echo -e "$(date +'%Y-%m-%d %R') remove existing folder" >>~/log
