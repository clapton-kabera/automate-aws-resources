# Automate AWS Resource Creation with Bash
The goal of this lab is to create scripts that automate the creation of AWS resources such as the VPC, Subnets, Security Groups, EC2 instances and S3 buckets.
* * *
The repository is made up of the following files:
- **setup_network.sh:** A bash script that automates the creation of the whole networking infrastructure necessary for the EC2 instance to work.
- **create_ec2.sh:** This is a bash script that contains the logic for provisioning and launching an EC2 instance.
- **create_s3_bucket.sh:** This script creates an S3 bucket with versioning capabilities and uploads a simple text file.
- **clean_up.sh:** Reverses the work of all the above scripts by terminating all the provisioned resources.
* * *
### How to run the scripts
For the entire process to work smoothly, run the scripts in the following order:
1. Run the `setup_network.sh`. This provisions the VPC, Subnet, Internet Gateway, Route Table and Security Group that the EC2 instance needs to be provisioned. The `create_ec2.sh` script will not work at all if this script does not complete successfully.
2. Run the `create_ec2.sh` file.
3. Run the `create_s3_bucket.sh`. This script is unique in that it is not dependent on the `setup_network.sh` script so you can run it out of this order.
4. Run the `clean_up.sh`. For this script to work, the other scripts should have done their job otherwise it will fail when it tries to delete a resource that does not exist.


