#!/bin/bash

#If you are using iterm (Free @ https://www.iterm2.com/) (Mac OSX)
#you should place this file in ~/Library/Application\ Support/iTerm/Scripts/
#Make it executable with ` chmod u+x ~/Library/Application\ Support/iTerm/Scripts/ec2.sh `
#also, add ` . ~/Library/Application\ Support/iTerm/Scripts/ec2.sh ` to your ~/.bash_profile
#after you set up the aws stuff (instructions below), run ec2init from your terminal
#to input all the information ec2connect will need.
#in the future you will be able to start and connect to your ec2 by simply typing ec2.
#read through the code below to see what other functions this script adds.

##you will need to install aws command line tools. This was pretty easy:
#Full instructions: http://docs.aws.amazon.com/cli/latest/userguide/installing.html
#I did have to add an export to my path file as described here: http://docs.aws.amazon.com/cli/latest/userguide/cli-install-macos.html#awscli-install-osx-path

##you will need to configure your aws
# http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html
##in order to finish this you will need to create Access keys.
#the give you instructions on the link above using the IAM console
#but before I had seen that I had already created an access key using the instructions here: http://docs.aws.amazon.com/general/latest/gr/managing-aws-access-keys.html

##set an elastic ip address for your instance
#very easy to set up from https://console.aws.amazon.com/ec2/v2/home?region=us-east-1#Addresses

ec2init(){
  command -v aws >/dev/null 2>&1 || { echo "I require aws but it's not installed.  See Notes" >&2; return 0; }

  if ! [ -d ~/.ec2connect/ ]; then
    mkdir ~/.ec2connect/
  fi

  touch ~/.ec2connect/ec2_instance_id.txt
  while true; do
    echo "enter an INSTANCE_ID, followed by [ENTER]:"
    read instance_id_input
    owner="$(aws ec2 describe-instances --instance-ids $instance_id_input --output text --query 'Reservations[*].OwnerId')"
    echo "$owner"
    re='^[0-9]+$'
    if [[ $owner =~ $re ]] ; then
      echo "$instance_id_input" > ~/.ec2connect/ec2_instance_id.txt
      echo "instance id verified"
      break
    else
      echo "invalid instance id"
    fi
  done

  while true; do
    echo "enter the full path of your .pem file, followed by [ENTER]:"
    read pem_path_input
    if [ -e $pem_path_input ]; then
      echo "$pem_path_input" > ~/.ec2connect/ec2_pem_path.txt
      break
    else
      echo "invalid pem path, no such file exists"
    fi
  done
}

function ec2 () {
  ## ec2 will:
  #   check to see if my ec2 instance is running
  #   start my instance if not
  #   wait for it to start
  #   print the command I use to log in via ssh
  #   log into my ec2 as root using SSH
  #
  #   after I exit my ec2 instance I will be asked if I want to stop my instance
  #   if I answer yes ("y" or "stop"), it will stop my instance
  #   if I answer anything else, it will warn me that my instance in running

  if [ "$(ec2status)" != "running" ]
  then
    ec2start
    sleep 1
  fi


  instance_id=$(head -n 1 ~/.ec2connect/ec2_instance_id.txt)
  pem_path=$(head -n 1 ~/.ec2connect/ec2_pem_path.txt)

  ec2_IP=$(aws ec2 describe-instances --instance-ids $instance_id --output text --query 'Reservations[*].Instances[0].PublicIpAddress')
  echo "$ec2_IP"

  echo EXECUTE: ssh -i $pem_path root@$ec2_IP
  ssh -i $pem_path root@$ec2_IP

  ##this block will only execute after you exit your ec2
  #
  read -r -p "Do you want to stop your instance? [y/N] " response
  if [[ "$response" =~ ^([sSyY])+$ ]]
    then #if it's no
    read -r -p "TO CONFIRM TYPE \"stop\" (ALL LOWERCASE NO QUOTES):  " response
    if [ "$response" = "stop" ]
      then
        ec2stop
      else
        printf '\7'
        printf "\n###################################\nYOU HAVE LEFT YOUR INSTANCE RUNNING\n###################################\n\n"
        printf '\7'
    fi
  elif [ "$response" = "stop" ]  ##shortcut if you type 'stop' at the first prompt
    then
      ec2stop
  else
    printf '\7'
    printf "\n###################################\nYOU HAVE LEFT YOUR INSTANCE RUNNING\n###################################\n\n"
    printf '\7'
  fi
}

ec2status () {
  instance_id=$(head -n 1 ~/.ec2connect/ec2_instance_id.txt)
  ##ec2status will return "running" if the ec2 is running and return an empty string otherwise.
  echo "$(aws ec2 describe-instances --instance-ids $instance_id --output text --query 'Reservations[*].Instances[0].State.Name')"
}

function ec2start () {
  instance_id=$(head -n 1 ~/.ec2connect/ec2_instance_id.txt)
  ##ec3start will:
  #   execute the command to start your ec2 instance
  #   wait for your ec2 instance to finish starting (or fail to start)
  #   report the status of your instance (tell you it is running) after it is done starting
  echo EXECUTE: aws ec2 start-instances --instance-ids $instance_id
  printf "Starting ec2 instance."
  aws ec2 start-instances --instance-ids $instance_id > /dev/null
  while state=$(aws ec2 describe-instances --instance-ids $instance_id --output text --query 'Reservations[*].Instances[*].State.Name'); test ! "$state" = "running"; do
    sleep .5
    echo -n '.'
  done;
  printf "\n"
  echo "Result: Your instance is $state."
}

function ec2stop () {
  ##ec3stop will:
  #   execute the command to stop your ec2 instance
  #   wait for your ec2 instance to finish stopping (or fail to stop)
  #   report the status of your instance (tell you it is running) after it is done starting
  instance_id=$(head -n 1 ~/.ec2connect/ec2_instance_id.txt)
  echo EXECUTE: aws ec2 stop-instances --instance-ids $instance_id
  printf "Stopping ec2 instance."
  aws ec2 stop-instances --instance-ids $instance_id > /dev/null
  while state=$(aws ec2 describe-instances --instance-ids $instance_id --output text --query 'Reservations[*].Instances[*].State.Name'); test ! "$state" = "stopped"; do
    sleep .5
    echo -n '.'
  done;
  printf "\n"
  echo "Result: Your instance is $state."
}
