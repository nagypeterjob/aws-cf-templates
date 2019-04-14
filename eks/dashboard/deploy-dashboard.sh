sudo yum install -y nginx

DIR=`pwd`/dashboard

MAC_ADDRESS=`curl http://169.254.169.254/latest/meta-data/mac`
VPC_ID=`curl http://169.254.169.254/latest/meta-data/network/interfaces/macs/$MAC_ADDRESS/vpc-id`

DASHBOARD_SG=`aws ec2 create-security-group --group-name $EKS_CLUSTER_NAME-k8s-dashboard-ingress-sg --description "opens port 80 for kubernetes dashboard" --vpc-id $VPC_ID --region $AWS_REGION` | jq -r ".GroupId"
EXISTING_SG=`curl http://169.254.169.254/latest/meta-data/security-groups`

INSTANCE_ID=`curl http://169.254.169.254/latest/meta-data/instance-id`


aws ec2 authorize-security-group-ingress --group-id $DASHBOARD_SG --protocol tcp --port 80 --cidr 0.0.0.0/0 --region $AWS_REGION
aws ec2 authorize-security-group-ingress --group-id $DASHBOARD_SG --protocol tcp --port 443 --cidr 0.0.0.0/0 --region $AWS_REGION

aws ec2 describe-security-groups --filter Name=vpc-id,Values=$VPC_ID Name=group-name,Values=$EXISTING_SG --query 'SecurityGroups[0].GroupId' --region $AWS_REGION --output text

aws ec2 modify-instance-attribute --instance-id $INSTANCE_ID --groups $DASHBOARD_SG  $EXISTING_SG  --region $AWS_REGION

kubectl proxy --port=8080 --address='0.0.0.0' &

cat <<EOF > $DIR/dashboard-policy.yml
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: kubernetes-dashboard
  labels:
    k8s-app: kubernetes-dashboard
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: kubernetes-dashboard
  namespace: kube-system
EOF

kubectl apply -f $DIR/dashboard-policy.yml

sudo sh -c "echo '$USER:$(echo $PASSWORD | openssl passwd -apr1 -stdin)' >> /etc/nginx/.htpasswd"


sudo service nginx start