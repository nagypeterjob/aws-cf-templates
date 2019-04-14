sudo yum install -y jq > /dev/null 2>&1

function main() {
    while test $# -gt 0; do
        case "$1" in
                -h|--help)
                    echo "--max-nodes           [number]     number of autoscalable nodes"
                    echo "--cluster-name        [string]     name of the cluster"
                    echo "--ingress-controller               whether you want to install ingress controller"
                    echo "--cluster-autoscaler               whether you want to install cluster autoscaler"
                    echo "--dashboard                        whether you want to install dashboard"
                    echo "--logging                          whether you want to install logging (Fluentd)"
                    echo "--monitoring                       whether you want to install monitoring (Prom/Graf)"
                    exit 0;
                    ;;
                --max-nodes)
                    shift
                    if [[ $1 -ge 0 ]]; then
                        MAX_NODES=$1
                    else
                        echo "Please specify a positive number for max nodes."
                        exit 1;
                    fi
                    shift
                    ;;
                 --cluster-name)
                    shift
                    if [[ ! -z $1 ]]; then
                      EKS_CLUSTER_NAME=$1
                    else
                      echo "Please specify the cluster name!"
                      exit 1;
                    fi
                    shift
                    ;;
                 --ingress-controller)
                    WANT_INGRESS=true
                    shift
                    ;;
                 --cluster-autoscaler)
                    WANT_AUTOSCALER=true
                    shift
                    ;;
                *)
                    echo "Unrecognized flag!"
                    return 1;
                    ;;
        esac
    done
}

main $@

if [[ -z $EKS_CLUSTER_NAME ]]; then
    echo "Please specify the cluster name!"
    exit 1;
fi

if [[ $WANT_AUTOSCALER == true ]] && [[ -z $MAX_NODES ]]; then
    MAX_NODES=10
    echo "MAX_NODES was unset. Script continues with default (10)."
fi

EC2_AVAIL_ZONE=`curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone`
AWS_REGION="`echo \"$EC2_AVAIL_ZONE\" | sed 's/[a-z]$//'`"

if [[ $WANT_INGRESS == true ]]; then
    echo "-------------------------------------------------"
    echo "---Deploying module #1: ALB-Ingress-Controller---"
    echo "-------------------------------------------------"
    chmod +x ./alb-ingress-controller/deploy-alb-ingress.sh
    EKS_CLUSTER_NAME=$EKS_CLUSTER_NAME ./alb-ingress-controller/deploy-alb-ingress.sh
else
    echo "------------------------------------------------"
    echo "---Skipping module #1: ALB-Ingress-Controller---"
    echo "------------------------------------------------"
fi;

if [[ $WANT_AUTOSCALER == true ]]; then
    echo "-------------------------------------------------"
    echo "-----Deploying module #2: Cluster Autoscaler-----"
    echo "-------------------------------------------------"
    chmod +x ./cluster-autoscaler/deploy-ca.sh
    AWS_REGION=$AWS_REGION MAX_NODES=$MAX_NODES EKS_CLUSTER_NAME=$EKS_CLUSTER_NAME ./cluster-autoscaler/deploy-ca.sh
else
    echo "------------------------------------------------"
    echo "-----Skipping module #2: Cluster Autoscaler-----"
    echo "------------------------------------------------"
fi;