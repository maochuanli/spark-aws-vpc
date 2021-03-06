#!/bin/bash

usage() {
        me=`basename "$0"`
	echo ""
	echo "Usage:"
        echo "	$me [create|destroy|setupweb|help]"
	echo ""
	echo "Options:"
	echo "	- create,   Create a VPC network and an EC2 instance on top of that"
	echo "	- destroy,  Destroy the VPC network and all elements inside"
	echo "	- setupweb, Set up a web server and deploy a web application to the EC2 instance"
	echo "	- help,     Show this help"
	echo ""
    exit 0
}

createVPC="false"
destroyVPC="false"
setupVPC="false"

if [ -z "$1" ]; then
    usage
fi

key="$1"

case $key in
    help)
    usage
    shift
    ;;
    create)
    createVPC="true"
    shift
    ;;
    destroy)
    destroyVPC="true"
    shift
    ;;
    setupweb)
    setupVPC="true"
    shift
    ;;
    *)    # unknown option
    echo "Unknown option: $key"
    exit 1
    ;;
esac


if [ "$createVPC" = "false" ] && [ "$destroyVPC" = "false" ] && [ "$setupVPC" = "false" ]; then
	usage
fi


if [ -z "$AWS_ACCESS_KEY" ] || [ -z "$AWS_SECRET_KEY" ]; then
    echo "ERROR: "
	echo "    \$AWS_ACCESS_KEY variable and/or \$AWS_SECRET_KEY is not set"
	echo ""
	exit 1
fi

SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"

if [ "$createVPC" = "true" ]; then
    ansible-playbook -i "local, " -e @$SCRIPTPATH/default.vars.yml -e aws_access_key=$AWS_ACCESS_KEY -e aws_secret_key=$AWS_SECRET_KEY $SCRIPTPATH/CreateVPC.yml $@
elif [ "$destroyVPC" = "true" ]; then
    ansible-playbook -i "local, " -e @$SCRIPTPATH/default.vars.yml -e aws_access_key=$AWS_ACCESS_KEY -e aws_secret_key=$AWS_SECRET_KEY $SCRIPTPATH/DestroyVPC.yml $@
elif [ "$setupVPC" = "true" ]; then
    if [ -z "$GODADDY_ACCESS_KEY" ] || [ -z "$GODADDY_SECRET_KEY" ]; then
        echo "ERROR: "
        echo "    \$GODADDY_ACCESS_KEY variable and/or \$GODADDY_SECRET_KEY is not set"
        echo ""
        exit 1
    fi
    ansible-playbook -i $SCRIPTPATH/ec2_instance_inventory.txt -e @$SCRIPTPATH/default.vars.yml \
        -e ansible_user=ubuntu -e ansible_ssh_private_key_file=$SCRIPTPATH/maoli_key_pair.pem \
        -e go_daddy_key=$GODADDY_ACCESS_KEY -e go_daddy_secret=$GODADDY_SECRET_KEY \
        -e aws_access_key=$AWS_ACCESS_KEY -e aws_secret_key=$AWS_SECRET_KEY \
        SetupWeb.yml $@
fi
