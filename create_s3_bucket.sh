#!/usr/bin/bash

#----------------------------------------------------------------------------------------------------
# create_s3_bucket.sh
# author: Kabera Clapton
#
# description: A script that creates an s3 bucket in the aws cloud and uploads a sample file to it
#----------------------------------------------------------------------------------------------------

# if an error happens, the whole script should fail without cascading failure
set -euo pipefail

readonly BUCKET_NAME="devops-sandbox-bucket-$RANDOM"
readonly REGION="eu-west-1"
readonly INFRA_FILE=".infrastructure.env"

# key and file to be uploaded to s3
readonly OBJ_KEY="home/welcome.txt"
readonly OBJ_FILE="welcome.txt"

# create the bucket. Since the region is not us-east-1, we have to add options for our specific region
echo "Creating the bucket..."
aws s3api create-bucket --bucket "${BUCKET_NAME}" --region "${REGION}" \
    --create-bucket-configuration LocationConstraint="${REGION}"

# enable versioning on the s3 bucket in question
echo "Enabling versioning..."
aws s3api put-bucket-versioning --bucket "${BUCKET_NAME}" \
    --versioning-configuration Status=Enabled

# by default s3 buckets block public access. For our policy to be applied to the bucket, we need to disable this
echo "Disabling public access block..."
aws s3api put-public-access-block --bucket "${BUCKET_NAME}" \
  --public-access-block-configuration "BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false"

readonly POLICY_FILE="file://./bucket-policy.json"

# define the policy in a heredoc. Allows for anyone to read and download the objects on the s3 bucket
echo "Creating bucket policy..."
cat <<EOF > bucket-policy.json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::${BUCKET_NAME}/*"
    }
  ]
}
EOF

# attach the policy to the bucket
echo "Attaching bucket policy..."
aws s3api put-bucket-policy --bucket "${BUCKET_NAME}" --policy "${POLICY_FILE}"

# create and add some sample text in the file welcome.txt
echo "Creating sample bucket object..."
echo "Hello DevOps guru! Welcome to your s3 bucket!" > welcome.txt


# put the file in the s3 bucket
echo "Uploading sample object to bucket..."
aws s3api put-object --bucket "${BUCKET_NAME}" \
    --key "${OBJ_KEY}" \
    --body "${OBJ_FILE}"

echo "BUCKET_NAME=${BUCKET_NAME}" >> "${INFRA_FILE}"

echo "Done..."
