# cogntive-assignment

AWS Account Setup

1) Created the AWS Account
2) Logged in as a root user and created the aws keys and given necessary permission to launch the stack
3) Created the pem file (Key Pair) 

AWS SetUP on the Local machine
   
   1) Installed the machined packages in the local machine to use aws cli
           sudo apt-get install python-pip
           sudo pip install cli53 requests
           sudo pip install awscli 
   2) Configure the keys to deploy from the local machine        
   
          cat <<EOF
            [default]
            aws_access_key_id= "XXXXXXXXXXXXXXXXXXX"
            aws_secret_access_key= "XXXXXXXXXXXXXXXXXXXXXXXXXXX"
            region = "us-west-2"
            EOF
            ) > ~/.aws/config

CHEF HOSTED SERVER CONFIGURATION (USED Only for the Demo Purpose, Instead we need to launch own centralized chef server)

1) Create an account in https://manage.chef.io/login

Go to the Adminstartion tab and Create the organization

Click on Generate knife config link to configure in the client

      current_dir = File.dirname(__FILE__)
      log_level                :info
      log_location             STDOUT
      node_name                "ramakrishnathandra"
      client_key               "~/chef-repo/.chef/ramakrishnathandra.pem"
      chef_server_url          "https://api.chef.io/organizations/cleotest"
      cookbook_path            ["~/chef-repo/cookbooks"]

2)Download the chef starterkit to get the private key

Setting Up a Workstation

1) Download the latest Chef Development Kit wget https://packages.chef.io/files/stable/chefdk/2.4.17/ubuntu/14.04/chefdk_2.4.17-1_amd64.deb

2) Install ChefDK
     sudo dpkg -i chefdk_2.4.17-1_amd64.deb

3)  Verify the components of the development kit
     chef verify

4) Generate the chef-repo and move into the newly-created directory
     chef generate repo chef-repo
     cd chef-repo

5) Make the .chef directory
     mkdir .chef

6) create the knife configuration(knife.rb) in .chef folder
    
         current_dir = File.dirname(__FILE__)
         log_level                :info
         log_location             STDOUT
         node_name                "ramakrishnathandra"
         client_key               "~/chef-repo/.chef/ramakrishnathandra.pem"
         chef_server_url          "https://api.chef.io/organizations/cogntivedemo"
         cookbook_path            ["~/chef-repo/cookbooks"]

         knife[:aws_access_key_id] = "XXXXXXXXXXXXXXXX"  # AWS Access KEY
         knife[:aws_secret_access_key] = "XXXXXXXXXXXXXXXXXX" # AWS SECRET KEY
         knife[:ssh_key_name] = "test"
         knife[:availability_zone] = "us-west-2a"
         knife[:region] = "us-west-2"

  7) Move to the chef-repo and copy the needed SSL certificates from the server
       cd ..
       knife ssl fetch

  8) Confirm that knife.rb is set up correctly by running the client list
       knife client list
       

            
Clone the cogntive-assignment and deploy the stack

1) Go to Chef-repo folder in the Workstation
   
   2) Git clone git@github.com:ramakrishnathandra/cogntive-assaignment.git, you can find below folders in the respository
             cookbooks/
             data_bags/
             deploy.sh
             roles/
             base-network.template
             Dockerfile
             files/nginx.conf
   
   3) Create the keypair in the region where we are going to launch the stack and copy the key pair in your work station
   
   4) base-network.template will Create a VPC, Subnets, Security Groups, EIP, Internet Gateway, Route Tables, SNS Topic Arn, InstancdProfile Name
   
   Before deploying, please change the External security group in the base network template, currently it is poiting to 0.0.0.0/0, instead you need to add cogntive company n/w ids, in the place 0.0.0.0/0, if you have multiple ips, copy the same json which is securityGroupIngress section for multiple ips
   
     "ExternalSshAccessSG": {
      "Type": "AWS::EC2::SecurityGroup",
      "Properties": {
        "GroupDescription": "External SSH Access",
        "SecurityGroupEgress": [
          {
            "CidrIp": "0.0.0.0/0",
            "IpProtocol": "-1"
          }
        ],
        "SecurityGroupIngress": [
          {
            "IpProtocol": "tcp",
            "FromPort": "22",
            "ToPort": "22",
            "CidrIp": "0.0.0.0/0"
          },
          {
            "IpProtocol": "tcp",
            "FromPort": "80",
            "ToPort": "80",
            "CidrIp": "0.0.0.0/0"
          }
        ],
        "VpcId": {
          "Ref": "VPC"
        },
        "Tags": [
          {
            "Key": "Name",
            "Value": {
              "Fn::Join": [
                "",
                [
                  {
                    "Ref": "EnvironmentName"
                  },
                  "-ExternalSshAccessSG"
                ]
              ]
            }
          }
        ]
      }
    },
   
   
   Commands to create the cloudfromation stack Create,update,delete and list
   
      1) Trigger the cloudfromation using following command
          
             aws cloudformation create-stack --stack-name demo --template-body file://base-network.template --parameters ParameterKey=EnvironmentName,ParameterValue=Demo --region us-west-2 --disable-rollback --timeout-in-minutes 120 --capabilities CAPABILITY_IAM

      2) Describe the created stack to get the output parameters
        
        aws cloudformation describe-stacks --stack-name demo

      3) Delete the created stack using following command
     
        aws cloudformation delete-stack --stack-name demo
   
   
   
   5) ./deploy.sh will upload the databag, cookbook and create the ec2 box to launch openresty server, please find the deploy.sh help, none of them are mandatory.
           
           ubuntu@ip-172-31-7-177:~/chef-repo$ ./deploy.sh -h

                usage: deploy.sh -x [os] -i [keyname] -N [ec2 instance name] -I [ubuntu 14.04 amiid] -f [ec2 instance type] -e [elasticip] -g [security group] -s [subnetid] -n [snstopicarn] -r [instanceprofilename]
                -x aws os
                -i aws keyname [ need to specify whole path, to connect the ec2 machine we launched]
                -N aws name of the ec2 instance
                -I aws ubuntu 14.04 amiid
                -f aws instance type
                -e aws elasticip
                -g aws security group
                -s aws subnet id to launch ec2 in vpc
                -n aws sns topic arn
                -r aws instance profile name
                -h help

  6) Delete the created ec2-box with knife command, ist command will list the instances, and pass the instanceid in second command
  
         knife ec2 server list 
         knife ec2 server delete {instanceid}
         
         
 Docker Build to make the image of openresty
 
    1) git clone the openrety project (git clone https://github.com/openresty/openresty.git )
    2) go to the openresty folder (cd openresty)
    3) git checkout v1.13.6.1
    4) make  (Note: make is failing with following error)
        mv: cannot stat ‘simpl-ngx_devel_kit-*’: No such file or directory
        make: *** [all] Error 1
    5) Change the below mentioned line in util/mirror-tarballs
         ver=0.3.0
         $root/util/get-tarball "https://github.com/simpl/ngx_devel_kit/tarball/v$ver" -O ngx_devel_kit-$ver.tar.gz
         tar -xzf ngx_devel_kit-$ver.tar.gz || exit 1
         mv simpl-ngx_devel_kit-* ngx_devel_kit-$ver || exit 1

         to

         ver=0.3.0
         $root/util/get-tarball "https://github.com/simpl/ngx_devel_kit/tarball/v$ver" -O ngx_devel_kit-$ver.tar.gz
         tar -xzf ngx_devel_kit-$ver.tar.gz || exit 1
         mv ngx_devel_kit-* ngx_devel_kit-$ver || exit 1

    6) install dos2unix and mercurial As i am using ubuntu as my local machine (sudo apt-get install -y dos2unix mercurial)
    7) then run make (make)
    8) which will build the tar file
      

Docker open Resty

      1) Becuase of the above error, Just downlaod the package & made the image, please refer Dockerfile
      2) Create git hub repository to upload the openresty image
      3) Same thing used in chef recipe.

Commands to build& push the docker image to repository

     1) docker login -u={username} -p={password} 
     2) docker build -t ramakrishna2106/cogntive:latest .
     3) docker push ramakrishna2106/cogntive:latest
     
Command to run the docker image

     1) docker run --name openresty -d ramakrishna2106/cogntive:latest
     2) docker ps -a ( To list the containers)
     3) docker images (to list the images)

 
 
