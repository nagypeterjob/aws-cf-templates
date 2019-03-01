#!/bin/bash -ex

#set up AWS Credentials
sudo su<<EOF
if [ -d ~/.aws ]; then
    rm -r ~/.aws
fi
mkdir ~/.aws
echo '[default]' > ~/.aws/credentials
echo 'aws_access_key_id=${AWS_ACCESS_KEY_ID}' >> ~/.aws/credentials
echo 'aws_secret_access_key=${AWS_SECRET_ACCESS_KEY}' >> ~/.aws/credentials
echo '[default]' > ~/.aws/config
echo 'region=${AWS_REGION}' >> ~/.aws/config
echo 'output=json' >> ~/.aws/config
EOF

VPC_CIDR=`sudo aws ec2 describe-vpcs --vpc-ids ${AWS_VPC_ID} | jq '.Vpcs[].CidrBlock'`
VPC_NAME=`sudo aws ec2 describe-vpcs --vpc-ids ${AWS_VPC_ID} | jq '.Vpcs[].Tags[].Value'`

SUBNETA_CIDR=`sudo aws ec2 describe-subnets --filters "Name=vpc-id,Values=${AWS_VPC_ID}" | jq '.Subnets[] | select(.Tags[].Value == "subnet-a")' | jq '.CidrBlock'`
SUBNETB_CIDR=`sudo aws ec2 describe-subnets --filters "Name=vpc-id,Values=${AWS_VPC_ID}" | jq '.Subnets[] | select(.Tags[].Value == "subnet-b")' | jq '.CidrBlock'`
SUBNETC_CIDR=`sudo aws ec2 describe-subnets --filters "Name=vpc-id,Values=${AWS_VPC_ID}" | jq '.Subnets[] | select(.Tags[].Value == "subnet-c")' | jq '.CidrBlock'`

touch /home/ec2-user/inventory.yaml
touch /home/ec2-user/vars.yaml

#Create ansible inventory
cat <<EOF > /home/ec2-user/inventory.yaml
[OSEv3:children]
masters
nodes
etcd

[OSEv3:vars]

ansible_ssh_user=centos
ansible_sudo=true
ansible_become=true
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
openshift_deployment_type=origin

openshift_aws_clusterid=${OKD_CLUSTER_ID}
openshift_clusterid=${OKD_CLUSTER_ID}
openshift_cloudprovider_kind=aws
openshift_cloudprovider_aws_access_key= "{{ lookup('env','AWS_ACCESS_KEY_ID') }}"
openshift_cloudprovider_aws_secret_key= "{{ lookup('env','AWS_SECRET_ACCESS_KEY') }}"

openshift_master_identity_providers=[{'name':'htpasswd_auth', 'login':'true', 'challenge':'true', 'kind':'HTPasswdPasswordIdentityProvider'}]
openshift_master_htpasswd_users={${OKD_USERNAME}:${OKD_PASSWORD}}

openshift_master_default_subdomain=${OKD_PUBLIC_SUBDOMAIN}
openshift_master_cluster_public_hostname=${OKD_PUBLIC_HOSTNAME}

openshift_cluster_monitoring_operator_install=${OKD_MONITORING}

[masters]

[etcd]

[nodes]
EOF

#Create ansible inventory
cat <<EOF > /home/ec2-user/vars.yaml
---
openshift_deployment_type: origin

openshift_aws_clusterid: ${OKD_CLUSTER_ID}

openshift_aws_region: ${AWS_REGION}

openshift_aws_create_vpc: false

openshift_aws_vpc:
  name: "{{ openshift_aws_vpc_name }}"
  cidr: ${VPC_CIDR}
  subnets:
    ${AWS_REGION}:
    - cidr: ${SUBNETC_CIDR}
      az: "eu-central-1c"
    - cidr: ${SUBNETB_CIDR}
      az: "eu-central-1b"
    - cidr: ${SUBNETA_CIDR}
      az: "eu-central-1a"

openshift_aws_vpc_name: ${AWS_VPC_ID}

openshift_aws_create_security_groups: true

openshift_aws_ssh_key_name: openshift

openshift_aws_build_ami_ssh_user: centos

container_runtime_docker_storage_type: overlay2
container_runtime_docker_storage_setup_device: /dev/xvdb

openshift_aws_base_ami: ${OKD_AMI_TO_USE}

openshift_aws_master_group_desired_size: ${OKD_MASTER_GROUP_DESIRED_SIZE}
openshift_aws_compute_group_desired_size: ${OKD_COMPUTE_GROUP_DESIRED_SIZE}
openshift_aws_compute_group_min_size: ${OKD_COMPUTE_GROUP_MIN_SIZE}
openshift_aws_infra_group_desired_size: ${OKD_INFRA_GROUP_DESIRED_SIZE}
openshift_aws_infra_group_min_size: ${OKD_INFRA_GROUP_MIN_SIZE}

openshift_aws_create_s3: True
openshift_aws_s3_bucket_name: ${OKD_REGISTRY_BUCKET_NAME}

openshift_aws_elb_cert_arn: ${AWS_MASTER_ELB_CERT_ARN}
EOF

sudo su<<EOF
cp -r /home/ec2-user/openshift-ansible ~/
cp /home/ec2-user/inventory.yaml ~/
cp /home/ec2-user/vars.yaml ~/
EOF