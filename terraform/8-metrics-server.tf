// metrics server installed using helm chat for HPA
resource "helm_release" "metrics_server" {
  name = "metrics-server"

  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  namespace  = "kube-system"
  version    = "3.12.1"

  values = [file("${path.module}/values/metrics-server.yaml")]

  depends_on = [aws_eks_node_group.general]
}

# Use the command kubectl get pods -n kube-system to find verify that the metrics server pod is running
# Use the command kubectl logs -l app.kubernetes.io/instance=metrics-server -f -n kube-system to check the logs of the metrics server
# Use the command kubectl top pods/nodes -n kube-system to get the metrics from the metrics server


