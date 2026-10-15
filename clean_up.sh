#!/usr/bin/bash

#----------------------------------------------------------------------------------------------------
# clean_up.sh
# author: Kabera Clapton
#
# description: Cleans up all the resources created by other scripts in this repo.
#----------------------------------------------------------------------------------------------------

# if an error happens, the whole script should fail without cascading failure
set -euo pipefail

# load all IDs in the infrastructure.env file into memory for this script
source .infrastructure.env

# deletes every entry of one kind ("Versions" or "DeleteMarkers") from a versioned bucket,
# in batches of up to 1000 (the delete-objects limit)
delete_all_versions() 
{
    local bucket="$1"
    local field="$2"
    local batch
 
    while true; do
        batch=$(aws s3api list-object-versions --bucket "${bucket}" \
            --query "{Objects: ${field}[0:1000].{Key: Key, VersionId: VersionId}, Quiet: \`true\`}" \
            --output json)
 
        # Objects is null or empty once nothing of this kind is left
        if [ "$(echo "${batch}" | jq '.Objects | length')" -eq 0 ]; then
            break
        fi
 
        aws s3api delete-objects --bucket "${bucket}" --delete "${batch}" > /dev/null
    done
}

# terminate the ec2 instance first
echo "Terminating the EC2 instance..."
aws ec2 terminate-instances --instance-ids "${INSTANCE_ID}"

# wait for the instance to fully terminate
echo "Waiting for instance to fully terminate..."
aws ec2 wait instance-terminated --instance-ids "${INSTANCE_ID}"

# delete the key pairs for the instance
echo "Deleting EC2 key pair..."
aws ec2 delete-key-pair --key-name "${KEY_NAME}"
rm -f "${PEM_FILE}"

# delete security group
echo "Deleting security group..."
aws ec2 delete-security-group --group-id "${SG_ID}"

# detach internet gateway from VPC
echo "Detaching internet gateway from VPC..."
aws ec2 detach-internet-gateway --internet-gateway-id "${IGW_ID}" --vpc-id "${VPC_ID}"

# delete intenet gateway
echo "Deleting internet gateway..."
aws ec2 delete-internet-gateway --internet-gateway-id "${IGW_ID}"

# delete subnet before the route-table. This removes the association between the subnet and the route table
echo "Deleting subnet..."
aws ec2 delete-subnet --subnet-id "${SUBNET_ID}"

# delete route table
echo "Deleting route table..."
aws ec2 delete-route-table --route-table-id "${ROUTE_TABLE_ID}"

# delete vpc
echo "Deleting VPC..."
aws ec2 delete-vpc --vpc-id "${VPC_ID}"

# empty the versioned bucket: "aws s3 rm" only adds delete markers on a versioned bucket,
# so every object version and every delete marker has to be removed explicitly
echo "Deleting all object versions in S3 bucket..."
delete_all_versions "${BUCKET_NAME}" "Versions"

echo "Deleting all delete markers in S3 bucket..."
delete_all_versions "${BUCKET_NAME}" "DeleteMarkers"

# delete the s3 bucket itself
echo "Deleting the S3 bucket..."
aws s3api delete-bucket --bucket "${BUCKET_NAME}"

# delete the bucket policy json file
echo "Deleting the bucket policy file..."
rm -f bucket-policy.json

# delete the welcome.txt sample file
echo "Deleting the s3 bucket sample file..."
rm -f welcome.txt

echo "Done..."
