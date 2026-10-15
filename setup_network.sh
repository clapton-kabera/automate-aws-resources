#!/usr/bin/bash

#----------------------------------------------------------------------------------------------------
# setup_network.sh
# author: Kabera Clapton
#
# description: A script that automates the creation of a VPC, public subnet, internet gateway and 
# security group. The security group allows for SSH and HTTP traffic. The Subnet and Security Group
# IDs generated from this file are the stored in a .env file that's read by the script that creates
# an EC2 instance.
#----------------------------------------------------------------------------------------------------

# create the VPC (Virtual Private Cloud)
readonly VPC_ID=$(aws ec2 create-vpc \
                    --cidr-block 10.0.0.0/16 \
                    --query "Vpc.VpcId" \
                    --output text)

# create the public subnet in which the ec2 will reside
readonly SUBNET_ID=$(aws ec2 create-subnet \
                        --vpc-id "${VPC_ID}" \
                        --cidr-block 10.0.1.0/24 \
                        --query "Subnet.SubnetId" \
                        --output text)

# we want all ec2 instances created within this subnet to have a public IP otherwise we'd have to create a NAT
# gateway that translates from private IP to public just like we do at home
aws ec2 modify-subnet-attribute --subnet-id "${SUBNET_ID}" \
    --map-public-ip-on-launch

# now we create an internet gateway to route inbound traffic to the subnet and outbound traffic to the internet
readonly IGW_ID=$(aws ec2 create-internet-gateway \
                    --query "InternetGateway.InternetGatewayId" \
                    --output text)

# attach the internet gateway to the VPC
aws ec2 attach-internet-gateway --internet-gateway-id "${IGW_ID}" --vpc-id "${VPC_ID}"

# create a route table to hold route rules for the VPC
readonly ROUTE_TABLE_ID=$(aws ec2 create-route-table --vpc-id "${VPC_ID}" \
                            --query "RouteTable.RouteTableId" \
                            --output text)

# create a routing rule that points outbound traffic to the internet gateway.
# note, these rules are stateful so once you create an outbound rule, inbound traffic is allowed.
aws ec2 create-route --route-table-id "${ROUTE_TABLE_ID}" \
    --gateway-id "${IGW_ID}" \
    --destination-cidr-block 0.0.0.0/0

# associate the route table with the subnet
aws ec2 associate-route-table --subnet-id "${SUBNET_ID}" --route-table-id "${ROUTE_TABLE_ID}"

# create security group (the firewall) that allows this traffic to move back and forth
readonly SG_ID=$(aws ec2 create-security-group --group-name "devops-sg" \
                  --description "SG for the devops team for SSH and HTTP only" \
                  --vpc-id "${VPC_ID}" \
                  --query "GroupId" \
                  --output text)

# create the rules for the sg to allow inbound/outbound SSH and HTTP traffic
aws ec2 authorize-security-group-ingress --group-id "${SG_ID}" --ip-permissions \
    'IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=0.0.0.0/0,Description="SSH from the internet"}]' \
    'IpProtocol=tcp,FromPort=80,ToPort=80,IpRanges=[{CidrIp=0.0.0.0/0,Description="HTTP from the internet"}]'

# Print out the Security Group ID and the rules so far had
echo "Subnet ID: ${SUBNET_ID}"
aws ec2 describe-security-groups --filters "Name=group-name,Values=devops-sg" |
    jq -r '.SecurityGroups[] | "Rules:", (.IpPermissions[] | "    - Allow \(.IpProtocol | upcase) on port \(.FromPort)-\(.ToPort) from \([.IpRanges[].CidrIp] | join(", "))")'

# store the subnet id and security group id in the netconfig.env file so that they're accessible to the script
# that creates the EC2 instance.
echo "SUBNET_ID=${SUBNET_ID}" > .infrastructure.env
echo "SG_ID=${SG_ID}" >> .infrastructure.env
