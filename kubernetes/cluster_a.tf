resource "kubernetes_service_account_v1" "argocd_manager_cluster_a" {
  provider = kubernetes.cluster_a
  metadata {
    name      = "argocd-manager"
    namespace = "kube-system"
  }
  automount_service_account_token = true
}

resource "kubernetes_secret_v1" "argocd_manager_cluster_a" {
  provider = kubernetes.cluster_a
  metadata {
    name      = "argocd-manager"
    namespace = "kube-system"
    annotations = {
      "kubernetes.io/service-account.name" = "argocd-manager"
    }
  }
  type = "kubernetes.io/service-account-token"
}

resource "kubernetes_cluster_role_v1" "argocd_manager_cluster_a" {
  provider = kubernetes.cluster_a
  metadata {
    name = "argocd-manager-role"
  }

  rule {
    api_groups = ["*"]
    resources  = ["*"]
    verbs      = ["*"]
  }
}

resource "kubernetes_cluster_role_binding_v1" "argocd_manager_cluster_a" {
  provider = kubernetes.cluster_a
  metadata {
    name = "argocd-manager-role-binding"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "argocd-manager-role"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "argocd-manager"
    namespace = "kube-system"
  }
  depends_on = [kubernetes_cluster_role_v1.argocd_manager_cluster_a, kubernetes_service_account_v1.argocd_manager_cluster_a]
}

data "kubernetes_secret_v1" "argocd_manager_cluster_a" {
  provider = kubernetes.cluster_a
  metadata {
    name      = "argocd-manager"
    namespace = "kube-system"
  }
  depends_on = [kubernetes_service_account_v1.argocd_manager_cluster_a, kubernetes_secret_v1.argocd_cluster_a]
}