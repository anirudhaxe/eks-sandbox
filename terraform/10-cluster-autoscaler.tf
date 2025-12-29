// CLUSTER AUTOSCALER CONFIG

resource "aws_iam_role" "cluster_autoscaler" {
  name = "${aws_eks_cluster.eks.name}-cluster-autoscaler"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
        Principal = {
          # using POD Identity
          Service = "pods.eks.amazonaws.com"
        }
      }
    ]
  })
}

// policy for cluster autoscaler to access AWS ASG
resource "aws_iam_policy" "cluster_autoscaler" {
  name = "${aws_eks_cluster.eks.name}-cluster-autoscaler"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeLaunchConfigurations",
          "autoscaling:DescribeScalingActivities",
          "autoscaling:DescribeTags",
          "ec2:DescribeImages",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeLaunchTemplateVersions",
          "ec2:GetInstanceTypesFromInstanceRequirements",
          "eks:DescribeNodegroup"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "autoscaling:SetDesiredCapacity",
          "autoscaling:TerminateInstanceInAutoScalingGroup"
        ]
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cluster_autoscaler" {
  policy_arn = aws_iam_policy.cluster_autoscaler.arn
  role       = aws_iam_role.cluster_autoscaler.name
}

// Associate with k8s service account
resource "aws_eks_pod_identity_association" "cluster_autoscaler" {
  cluster_name    = aws_eks_cluster.eks.name
  namespace       = "kube-system"
  service_account = "cluster-autoscaler"
  role_arn        = aws_iam_role.cluster_autoscaler.arn
}

// using helm chart to deploy cluster autoscaler
resource "helm_release" "cluster_autoscaler" {
  name = "autoscaler"

  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  namespace  = "kube-system"
  version    = "9.37.0"

  set = [{
    name  = "rbac.serviceAccount.name"
    value = "cluster-autoscaler"
    }, {
    name  = "autoDiscovery.clusterName"
    value = aws_eks_cluster.eks.name
    }, {
    # MUST be updated to match your region 
    name  = "awsRegion"
    value = "eu-central-1"
    }
  ]

  depends_on = [helm_release.metrics_server]
}

# Run terraform apply
# Use kubectl get pods -n kube-system to verify cluster autoscaler POD is running
# If the POD remain in pending state and dont trigger autoscaling, search the autoscaler log by:
# kubectl logs -l app.kubernetes.io/instance=autoscaler -f -n kube-system
