#!/usr/bin/bash

# ----------------------------------------------------------------------------------------------------
# create_ec2.sh
# author: Kabera Clapton
# 
# description: This script creates and ec2 key pair with a free-tier linux AMI, tags it launches it
#               and prints its instance ID and public IP to the user.
#----------------------------------------------------------------------------------------------------

# if an error happens, the whole script should fail without cascading failure
set -euo pipefail

readonly PEM_FILE="automate_lab_ec2_key.pem"
readonly KEY_NAME="automate_lab_ec2_key"
readonly INFRA_FILE=".infrastructure.env"

# delete the .pem file if it already exists
echo "Checking if .pem file exists..."
if [[ -f "$PEM_FILE" ]]; then
  echo "Deleting old .pem file"
  rm -f "$PEM_FILE"
fi

# Create the ec2 key pair
# Note that it returns a json and we need to extract the private key and save it in a .pem file
# the --query option fetches the key in the json with the private key to access the ec2 instance thru SSH
echo "Creating new key pair..."
aws ec2 create-key-pair --key-name "${KEY_NAME}" --query "KeyMaterial" --output text > "${PEM_FILE}"

# make the .pem file read-only for every one!
chmod 400 "${PEM_FILE}"

readonly AMI_ID_PARAM_STORE_PATH="/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"

# set up the linux AMI. We shall fetch this from aws' public parameter store which has the AMI IDs for
# different AMIs. The altnernative would be to copy an AMI ID and paste it directly in the script. 
# Here we are querying this public param store and getting an AMI ID that we can use for the ec2 machine
echo "Fetching AMI ID..."
AMI_ID=$(aws ssm get-parameter --name "${AMI_ID_PARAM_STORE_PATH}" --query "Parameter.Value" --output text)

# fetch the subnet and security group ids to be used in launching the instance.
source "${INFRA_FILE}"

# launch the ec2 instance with the run-instances command
# query the instance id coz we need it for waiting for the instance to start running inorder to get its public IP2
echo "Creating EC2 instance..."
readonly INSTANCE_ID=$(aws ec2 run-instances \
    --image-id "${AMI_ID}" \
    --instance-type t2.micro \
    --subnet-id "${SUBNET_ID}" \
    --security-group-ids "${SG_ID}" \
    --key-name "${KEY_NAME}" \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Project,Value=AutomationLab}]' \
    --query "Instances[0].InstanceId" --output text)

# wait for the instance to start running in order to capture it public IP address
echo "Waiting for EC2 instance to launch..."
aws ec2 wait instance-running --instance-ids "${INSTANCE_ID}"

# by the time execution reaches here, the instance is running
echo "Fetching EC2 Public IP..."
readonly PUBLIC_IP=$(aws ec2 describe-instances \
    --instance-ids "${INSTANCE_ID}" \
    --query "Reservations[].Instances[].PublicIpAddress" \
    --output text)

echo -e "\n---------------\nInstance ID: ${INSTANCE_ID}\nPublic IP Address: ${PUBLIC_IP}\n---------------"

# store all IDs needed to delete the infrastructure in the .infrastructure.env file
echo "INSTANCE_ID=${INSTANCE_ID}" >> "${INFRA_FILE}"
echo "PEM_FILE=${PEM_FILE}" >> "${INFRA_FILE}"
echo "KEY_NAME=${KEY_NAME}" >> "${INFRA_FILE}"

