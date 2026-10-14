# Automate AWS Resource Creation with Bash
The goal of this lab is to create scripts that automate the creation of AWS resources such as the VPC, Subnets, Security Groups, EC2 instances and S3 buckets.
* * *
The repository is made up of the following files:
- **create_ec2.sh:** This is a bash script that contains the logic for provisioning and launching an EC2 instance.
- **create_security_group.sh:** A bash script that automates the creation of a security group for the EC2 instance that allows SSH and HTTP traffic.
- **create_s3_bucket.sh:** This script creates an S3 bucket with versioning capabilities and uploads a simple text file.
- **cleanup_resources.sh:** Reverses the work of all the above scripts by terminating all the provisioned resources.
