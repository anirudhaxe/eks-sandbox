# At this point in time, EFS CSI Driver does not support eks pod identities. We have two options: either attach all permissions to the k8s nodes OR use openid connect provider and link k8s service account with IAM Role
# extract the cert from eks cluster and use it to create openid connect provider
data "tls_certificate" "eks" {
  url = aws_eks_cluster.eks.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.eks.identity[0].oidc[0].issuer
}
