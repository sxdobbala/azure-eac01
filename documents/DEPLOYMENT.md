# Deployment

How does this all fit together

In the terraform directory, there are 3 subdirectories where 3 "environments" are created based off the lifecycle of the resources

1. nonprod-persistent
    * This provisions the VPCs, subnets, flow logs, NACL's, AWS Inspector, base security groups, and an s3 bucket to use for deployment artifacts. Standard terraform init; terraform plan;terraform apply to use it.
    * Currently using NAT gateways, but need to move to egress proxy.   Some other work to get there.
    * Mean for "long lived" resources
2. nonprod-transient
   * Provisions redshift.  There is a nightly job to backup and destroy the redshift cluster.   Eventually this should also have some way to create the "transient" Microstrategy instances, but it doesn't yet.
   * Dependency - nonprodprod-persistent must have been run
   * Now are able to create Microstrategy resources and "stop" them, but it isn't great.   With Terraform, have to use null_resources, and null_resources don't call "destroy" when you remove the resource completely.  Also, the MSTR API doesn't allow "stop" commands unless fully provisioned or "terminate" unless fully "stopped".  This causes some issues in really tearing down things.  Because of this, you have to change the state to "stop" before you actually remove it.  This stops the instances, but does not terminate them.
 . nonprod-packer
   * Likely to be combined with nonprod-persistent.  
   * This pulls a zip from the ../packer directory, creates a codedeploy project with that, plus an s3 bucket for input and output for codedeploy
   * Dependencies - nonprod-persistent, and the stuff in the "packer" directory

In the "packer" directory
* Dependency - must have VPCs and subnets set up, so nonprod-packer must have been run.  Currently hard coding the vpc and subnet in buildspec.yml, needs to be fixed.
* buildspec.yml - this is what actually controls the codebuild.  Mostly installs python packages and calls updatecloudformations.py
* packer.zip (not checked in) - the artifact that is uploaded to codebuild
* harden-mstr-linux.json and harden-mstr-windows.json - these are the packer json files to re-pack the MSTR provided Windows and Amazon Linux images.  Right now, they don't do much other than encrypt and install some basic packages.  I want do do more, but need to figure out the most hardening I can do without breaking MSTR.
* updatecloudformations.py - called from the buildspec.yml.  This downloads cloudformation scripts from Microstrategy, finds the latest AMI's for whatever versions I put in the script (currently 10.11.01 and 11.0.0), then runs the "harden-*" packers to encrypt them.  It then replaces the AMI names.  It also adds encryption to RDS and EFS, some necessary tags for AWS Inspector, and enabled detailed monitoring for EC2 Instances (recommended by Config)
* create_packer_codebuild.sh (there is likely a better way to do this).  Simple shell script which zips the files in this directory, then calls terraform in the nonprod-packer terraform directory to upload them.  It then kicks off a codebuild.
* TODO: Need some mechanism to call codebuild on a schedule (maybe a lambda)
* linux/ directory
    *  various scripts to try to harden the linux scripts
    * build_ami.sh - adapted from here https://github.optum.com/CommercialCloud-EAC/aws_ami/blob/master/build-ami
       * this is really just installing some packages (ossec, ssm, awslogs, and aws_inspector) and disabling root logins on ssh
    * ossec_logs.conf - also pulled from above, configures awslogs to send ossec to cloudwatch
    * preloaed-vars.conf - configures ossec watches
* windows/ directory 
   * ec2-userdata1.ps1 Enables RMI (necessary for packer to connect if you want to do something besides encryption)
   * bootstrap.ps1.  Installed AWS Inspector


In the "provisioning" directory
* Dependencies: Needs vpc's and subnets, also have to run the microstrategy cloudformation from their console first.  If we are intercepting the cloudformation call, then the custom lambda must be uploaded.
* Now called from the terraform nonprod-transient set, but can also be called manually

In the "lambda" directory
* Dependencies - Must have custom cloudformations in the bucket.  In order to do this, the main cloudformation from MSTR must have been run at least once.
* MSTRCloudCreate_TriggerCloudFormation-v8.py - a customized version of the MSTR lambda functions that pulls the customized cloudformation templates created by updatecloudformations.py (so encrypted and re-packed).  Currently deployed manually with copy-paste.  Should be in terraform, just haven't done it yet.


So, there are several pieces that are somewhat disconnected.  Ideally, this would all be instrumented via terraform, but currently it is not.   I think it's possible, just need to get to stringing them together.


There is now a Jenkinsfile so that the terraform can be checked in and applied against the AWS account.   This is a WIP, but it is working.