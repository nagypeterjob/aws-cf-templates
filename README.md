# Jenkins AWS Cloudformation template
CloudFormation template for spinning up a HA, self-healing single-master Jenkins cluster 

## What the package contains
- VPC with 4 subnets (2 public / 2 private) spread in 2 AZs
- Internet Gateway for the public subnets
- Autoscaling Group + Launch Configuration to boostrap an EC2 instance & mounting the EFS
- EFS with Mount targets in each AZ

## Why is it any good?
- It allows you the have a secure, HA, self-healing Jenkins server setup in a reproducible & tweakable way

### Prerequisites
You need to have a keypair created in the given region

### Inputs
- **AllowedSSHRange:** Ideally, your allowed SSH IP range (eg 196.172.0.0/32).
- **KeyPair:** The pre-created Keypair you will use to ssh in to the Jenkins master.
- **MasterInstanceType:** Instance type for the master node (according to AWS, m4.large is the best value/performance choice).
- **MasterAMI:** Instance AMI for the master node (default one is free tier eligible).
- **MasterDetailedMonitoring:** Specifies whether detailed monitoring is enabled for the master instance.
- **MasterEBSVolumeSize:** Specifies the EBS volume size of the master instance.
- **MasterEFSEncrypted:** Encryption of the Master's EFS drive storing JENKINS_HOME.

### Outputs
- **LoadBalancerDNSName**: The DNS name of the ALB

### How to get started
1. Create the stack on AWS
2. If you have previous JENKINS_HOME, tweak the security groups & copy the directory to the EFS drive. You are all set. If you don't have previous configuration, head to step 3.
3. Open the Load Balancer URL
4. SSH into the Master instance, get sudo privileges (sudo su -), copy the Jenkins secret from the location specified in step 2
5. Paste the secret to the Webpage seen in step 3 & go through the registration steps
6. To set up Jenkins nodes on AWS, head to https://wiki.jenkins.io/display/JENKINS/Amazon+EC2+Fleet+Plugin

### How to save more costs
- If you will use the master instance(s) for a long time, buy reserved instances to save money on the long run.

### Possible improvements
These improvements vastly depends on the given use-case / policies / previous setups:
- Logging
- EFS backup to S3
- Better ALB tweaks
- Better Launch Configuration
- Fine grained Auto Scaling rules
