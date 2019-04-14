DIR=`pwd`/alb-ingress-controller
echo "Downloading alb-ingress resources..."
wget "https://raw.githubusercontent.com/kubernetes-sigs/aws-alb-ingress-controller/v1.1.0/docs/examples/alb-ingress-controller.yaml" -P $DIR
wget "https://raw.githubusercontent.com/kubernetes-sigs/aws-alb-ingress-controller/v1.1.0/docs/examples/rbac-role.yaml" -P $DIR

sed -i "s/devCluster/$EKS_CLUSTER_NAME/g" $DIR/alb-ingress-controller.yaml

echo "Deploying alb-ingress-resources..."
kubectl apply -f $DIR/rbac-role.yaml
kubectl apply -f $DIR/alb-ingress-controller.yaml

for i in {0..10}; 
do 
    status=`kubectl get po -n kube-system | egrep alb-ingress[a-zA-Z0-9-]+ | awk '{print $3}'`
    if [[ ${status} == "Running" ]] || [[ ${status} == "Succeeded" ]] || [[ ${status} == "Failed" ]] || [[ ${status} == "CrashLoopBackOff"  ]]; 
    then 
      echo "Pod state is ${status}."
      break;  
    else 
      echo "$i, Waiting for deployment to finish... ${status} ..."
      sleep 2; 
    fi 
done

kubectl logs -n kube-system $(kubectl get po -n kube-system | egrep -o alb-ingress[a-zA-Z0-9-]+)
