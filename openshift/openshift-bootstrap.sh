#!/bin/bash -ex

#set up AWS Credentials
sudo su<<EOF
rm -r ~/.aws && mkdir ~/.aws
echo '[default]' > ~/.aws/credentials
echo 'aws_access_key_id=${AWS_ACCESS_KEY_ID}' >> ~/.aws/credentials
echo 'aws_secret_access_key=${AWS_SECRET_ACCESS_KEY}' >> ~/.aws/credentials
echo '[default]' > ~/.aws/config
echo 'region=${REGION}' >> ~/.aws/config
echo 'output=json' >> ~/.aws/config
EOF

sudo su<<EOF
cp -r /home/ec2-user/openshift-ansible ~/
EOF

