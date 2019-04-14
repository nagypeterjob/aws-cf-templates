DIR=`pwd`/cluster-autoscaler
NODE_GROUP_NAME=`aws autoscaling describe-auto-scaling-groups  --query 'AutoScalingGroups[].[AutoScalingGroupName]' --region $AWS_REGION | grep -i groupstack | jq -r .`

sed -i "s/:<AUTOSCALING GROUP NAME>/:$NODE_GROUP_NAME/g" $DIR/cluster_autoscaler.yml
sed -i "s/2:8/2:$MAX_NODES/g" $DIR/cluster_autoscaler.yml
sed -i "s/us-west-2/$AWS_REGION/g" $DIR/cluster_autoscaler.yml

NODE_INSTANCE_ROLE=`aws iam list-roles  --query 'Roles[].[RoleName]' --region $AWS_REGION | grep -i $EKS_CLUSTER_NAME | grep -i NodeInstanceRole | jq  -r .`

cat <<EOF > $DIR/k8s-asg-policy.json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "autoscaling:DescribeAutoScalingGroups",
        "autoscaling:DescribeAutoScalingInstances",
        "autoscaling:SetDesiredCapacity",
        "autoscaling:TerminateInstanceInAutoScalingGroup"
      ],
      "Resource": "*"
    }
  ]
}
EOF
aws iam put-role-policy --role-name $NODE_INSTANCE_ROLE --policy-name ASG-Policy-For-Worker --policy-document  file://$DIR/k8s-asg-policy.json

kubectl apply -f $DIR/cluster_autoscaler.yml

for i in {0..10}; 
do 
    status=`kubectl get po -n kube-system | egrep cluster-autoscaler[a-zA-Z0-9-]+ | awk '{print $3}'`
    if [[ ${status} == "Running" ]] || [[ ${status} == "Succeeded" ]] || [[ ${status} == "Failed" ]] || [[ ${status} == "CrashLoopBackOff"  ]]; 
    then 
      echo "Pod state is ${status}."
      break;  
    else 
      echo "$i, Waiting for deployment to finish... ${status} ..."
      sleep 2; 
    fi 
done

kubectl logs -n kube-system $(kubectl get po -n kube-system | egrep -o cluster-autoscaler[a-zA-Z0-9-]+)