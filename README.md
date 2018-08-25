# How to run the tasks
0. Buy a domain name from [godaddy.com](godaddy.com) and acquire a pair of API key and secret key from the [website](https://developer.godaddy.com/)

1. Download the project to local system with
      * `git clone git@github.com:maochuanli/spark-aws-vpc.git` OR
      * `curl https://github.com/maochuanli/spark-aws-vpc/archive/master.zip --output spark-aws-vpc.zip && unzip spark-aws-vpc.zip`
2. Install latest python, ansible and required packages
      * For debian/ubuntu: `sudo apt install -y python ansible boto boto3` 
      * For redhat/centos: `sudo yum -y python ansible boto boto3`
3. Open a linux terminal and set the following environment variables for the ansible tasks:
      ```
    export AWS_ACCESS_KEY=you_aws_key
    export AWS_SECRET_KEY=your_aws_secret
    export GODADDY_ACCESS_KEY=your_godaddy_key
    export GODADDY_SECRET_KEY=your_godaddy_secret
      ```
4. Execute the Ansible task for creating the VPC infrastructure and EC2 instance
   * `$> ~/spark-aws-vpc/run.sh create`
   * **Notice:** besides the above 4 variables, all other variables defined in the default.vars.yml file could be customized on the command such as:
   * `$> ~/spark-aws-vpc/run.sh create -vvvv -e region=us-east-2 -e vpc_cidr=10.240.0.0/20 -e domain_host_name=guo.place`

5. Execute the Ansible task for Set up the EC2 instance, the Apache web server and the Django web application
   * `$> ~/spark-aws-vpc/run.sh setupweb`

6. Access the new web server with the given domain name: [http://guo.place](http://guo.place), the request will be automatially redirected by apache to a secure connection https://guo.place

7. Execute the Ansible task for destroying everyting
   * `$> ~/spark-aws-vpc/run.sh destroy`
# What I have done
1. Create an Ansible project to manage the AWS VPC resources which contains the following artefacts:
   * ![VPC Architecture](https://docs.aws.amazon.com/AmazonVPC/latest/UserGuide/images/Case1_Diagram.png)
   * **CreateVPC.yml** - the main playbook to create VPC infrastructure and EC2 instance for the VPC network. With successful creation, all VPC network id, EC2 instance id and temporary key file for accessing the EC2 instance will be generated under the working directory.
      * Create a VPC network with given network CIDR
      * Create a public subnet under the VPC
      * Create an internet gateway for routing public requests from and to the EC2 machine
      * Create a route entry for internet gateway
      * Create a security group to allow http, https and ssh access to the EC2 machine
      * Create a temporary keypair and download it locally
      * At last, create an EC2 instance with given image ID and associate it to the above subnet
   * **DestroyVPC.yml** - the playbook to destroy all resources created by above playbook in a reversed order
   * **SetupWeb.yml** - the playbook to control the created EC2 instance with the generated instance public IP address. 
      * Update hostname with the given hostname
      * Reboot OS
      * Install required packages including the apache web server
      * Enable the WSGi configuration
      * Download the Django project onto the home directory
      * Run the certbot toolkit to help generate dynamically a certificate for the domain
      * Finally restart the apache2 service
   * **default.vars.yml** - the variables used by above 3 playbooks
   * **run.sh** - the shell script to help run the above 3 playbooks:
       ```
       Usage:
       	run.sh [create|destroy|setupweb|help]

       Options:
	       - create,   Create a VPC network and an EC2 instance on top of that
	       - destroy,  Destroy the VPC network and all elements inside
	       - setupweb, Set up a web server and deploy a web application to the EC2 instance
	       - help,     Show this help
       ```
2. Create a separate Django Web project to be deployed by the above Ansible project to target EC2 instance. Here is the project link: https://github.com/maochuanli/spark-aws-webapp
   * / or /index URL to server the web page for users to upload a file into the bucket
   * /upload URL to process the uploaded files and then redirect the request back to /index URL

# Questions and Answers
1. - Can you make the deployment tolerant to failures? Eg: EC2 instance gets terminated by accident and recovers automatically.
   * **Answer:** Create a launch configuration as what I have done above and create an Auto Scaling group that connects to the VPC network. Set the group size to 1(default). with this setting, any failure of EC2 instance will be recovered/replaced with a healthy instance within 5 minutes. Refer to [EC2 Auto Scaling](https://docs.aws.amazon.com/autoscaling/ec2/userguide/what-is-amazon-ec2-auto-scaling.html). 

2. - Can you come up with a DR strategy? Eg: Backups.
   * **Answer:** For this simple web application, the most important data is:
      * The user data - all the files user has uploaded to AWS bucket. 
         * If local storage capacity is big enough, it's easy to periodically download the latest S3 bucket data with the AWS command line tool.  `/usr/bin/aws s3 sync s3://{BUCKET_NAME} /home/ubuntu/s3/{BUCKET_NAME}/`. 
	     * A cron job can be easily set up to run the above command at a specified interval
         * Or we can rely on the versioning of S3 bucket to keep every change if the bucket size is not huge
      * The automation control code (in my case) is saved in a public git repository github, which has it's own DR solution that can help prevent data loss. So for this data, I don't think we need backup. Refer to [github security](https://help.github.com/articles/github-security/)
      * The EC2 instances all all dynamically generated from template, nothing need be backed up 
