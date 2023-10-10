resource "helm_release" "argocd" {
  provider         = helm.cluster_fleetmanager
  name             = "argocd"
  namespace        = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  create_namespace = true
  wait             = true

  set {
    name  = "configs.params.server\\.insecure"
    value = true
  }
}

resource "kubernetes_service_v1" "argocdweb" {
  provider = kubernetes.cluster_fleetmanager
  metadata {
    name      = "argocdweb"
    namespace = "argocd"
    annotations = {
      "kubernetes.io/elb.id"           = data.terraform_remote_state.cloud.outputs.argocd_lb_id
      "kubernetes.io/elb.class"        = "performance"
      "kubernetes.io/elb.lb-algorithm" = "ROUND_ROBIN"
      "kubernetes.io/elb.pass-through" = "true"
    }
  }
  spec {
    selector = {
      "app.kubernetes.io/name" = "argocd-server"
    }
    port {
      port        = 80
      target_port = 8080
      name        = "http"
    }
    type = "LoadBalancer"
  }
  lifecycle {
    ignore_changes = [spec[0].load_balancer_ip]
  }
}

data "kubernetes_secret_v1" "argocd_admin_password" {
  provider = kubernetes.cluster_fleetmanager
  metadata {
    name      = "argocd-initial-admin-secret"
    namespace = "argocd"
  }
  depends_on = [helm_release.argocd]
}

resource "kubernetes_secret_v1" "argocd_cluster_a" {
  provider = kubernetes.cluster_fleetmanager
  metadata {
    name      = "cluster-a"
    namespace = "argocd"
    labels = {
      "argocd.argoproj.io/secret-type" : "cluster"
    }
  }
  type = "Opaque"
  data = {
    "name"   = "cluster-a"
    "server" = data.terraform_remote_state.cloud.outputs.cluster_a_api_server
    "config" = jsonencode(
      {
        "bearerToken" = nonsensitive(kubernetes_secret_v1.argocd_manager_cluster_a.data["token"])
        "tlsClientConfig" = {
          "insecure" = false
          "caData"   = base64encode(data.terraform_remote_state.cloud.outputs.cluster_a_ca_certificate)
        }
      }
    )
  }
  depends_on = [helm_release.argocd]
}

resource "kubernetes_secret_v1" "argocd_cluster_b" {
  provider = kubernetes.cluster_fleetmanager
  metadata {
    name      = "cluster-b"
    namespace = "argocd"
    labels = {
      "argocd.argoproj.io/secret-type" : "cluster"
    }
  }
  type = "Opaque"
  data = {
    "name"   = "cluster-b"
    "server" = data.terraform_remote_state.cloud.outputs.cluster_b_api_server
    "config" = jsonencode(
      {
        "bearerToken" = nonsensitive(kubernetes_secret_v1.argocd_manager_cluster_b.data["token"])
        "tlsClientConfig" = {
          "insecure" = false
          "caData"   = base64encode(data.terraform_remote_state.cloud.outputs.cluster_b_ca_certificate)
        }
      }
    )
  }
  depends_on = [helm_release.argocd]
}

output "argocd_password" {
  value = nonsensitive(data.kubernetes_secret_v1.argocd_admin_password.data)["password"]
}
output "argcd_url" {
  value = "http://${data.terraform_remote_state.cloud.outputs.argocd_lb_public_ip}"
}