# Updates to the MSTR Cloudformation scripts to make them work for us.

## Main things updated
1) Updates the global cloudformation stack (MicroStrategyOnAWS) and locks down security groups
2) Use a version of BuildCloudFormationParameters given to us by MSTR that skips the installation of unnecessary packages
3) Now using the new MSTR Macro feature as opposed to preprocessing https://community.microstrategy.com/s/article/MicroStrategy-On-AWS-Encryption?language=en_US
    1) Updates security groups to lock then down more
    2) Removes usher from the deployment (which breaks with the lock down from #1)
    3) Pulls our custom packer AMI our list by source_ami tag
    4) Adds extra ssl and monitoring not originally provided.

**Please note that this is a global configuration per account, so it can really only be used once per account.   The lambda that MSTR provide have hard coded names.**