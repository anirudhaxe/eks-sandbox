// CLUSTER AUTOSCALER CONFIG
resource "aws_eks_addon" "pod_identity" {
  cluster_name  = aws_eks_cluster.eks.name
  addon_name    = "eks-pod-identity-agent"
  addon_version = "v1.2.0-eksbuild.1"
}
# To find the lateest version of any specific addon:
# aws eks describe-addon-versions --region eu-central-1 --addon-name eks-pod-identity-agent

# Run tf apply to create the agent then run the following to verify the agent pod is running:
# kubectl get pods -n kube-system
# (one agent should be deployed per agent node)

# Also can use to verify all the agents are running: kubectl get daemonset eks-pod-identity-agent -n kube-system



