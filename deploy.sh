#!/bin/bash
set -e

function help()
{
    echo ""
    echo "usage: deploy.sh -x [os] -i [keyname] -N [ec2 instance name] -I [ubuntu 14.04 amiid] -f [ec2 instance type] -e [elasticip] -g [security group] -s [subnetid] -n [Notification topic]"
    echo "-x aws os"
    echo "-i aws keyname"
    echo "-N aws name of the ec2 instance"
    echo "-I aws ubuntu 14.04 amiid"
    echo "-f aws instance type"
    echo "-e aws elasticip"
    echo "-g aws security group"
    echo "-s aws subnet id to launch ec2 in vpc"
    echo "-n aws SNS notification topic"
    echo "-h help"
}

OS="ubuntu"
KEYNAME="test.pem"
EC2NAME="cogntiveapp"
AMIID="ami-25cf1c5d"
EC2TYPE="t2.micro"
EIP="35.163.119.121"
SECURITYGROUP="sg-cf438fb0"
SUBNETID="subnet-13d3d95b"
SNSNOTIFICATION="test"

while getopts "x:i:N:I:f:e:g:s:n:h" opt
do
    case $opt in
        h)
            help
            exit 0
            ;;
        [?])
            echo "Invalid option"
            help
            exit -1
            ;;
        x)
            OS=$OPTARG;;
        i)
            KEYNAME=$OPTARG;;
        N)
            EC2NAME=$OPTARG;;
        I)
            AMIID=$OPTARG;;
        f)
            EC2TYPE=$_OPTARG;;
        e)
            EIP=$OPTARG;;
        g)
            SECURITYGROUP=$OPTARG;;
        s)
            SUBNETID=$OPTARG;;
        n)
            SNSNOTIFICATION=$OPTARG;;
    esac
done



sed -i '/"snstopicarn"/c\"snstopicarn": "'$SNSNOTIFICATION'"' data_bags/cogntive/cogntive.json
knife data bag create cogntive
knife data bag from file cogntive data_bags/cogntive/cogntive.json
knife cookbook upload cogntiveapp --force

knife ec2 server create -x $OS -i $KEYNAME -N $EC2NAME -I $AMIID  -f $EC2TYPE --node-ssl-verify-mode none -r 'recipe[cogntiveapp]' --associate-eip $EIP -g $SECURITYGROUP --subnet $SUBNETID --iam-profile demo-ApplicationRoleProfile-19Z9S00BNITPD --server-connect-attribute public_ip_address -environment staging

