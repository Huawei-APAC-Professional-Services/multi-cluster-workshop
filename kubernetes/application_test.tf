#resource "kubernetes_manifest" "demo" {
#  provider = kubernetes.cluster_fleetmanager
#  manifest = {
#    "apiVersion" = "argoproj.io/v1alpha1"
#    "kind"       = "Application"
#    "metadata" = {
#      "name"      = "webapp"
#      "namespace" = "argocd"
#    }
#    "spec" = {
#      "destination" = {
#        "server" = data.terraform_remote_state.cloud.outputs.cluster_a_api_server
#      }
#      "source" = {
#        "path"           = "."
#        "repoURL"        = "https://github.com/agoodmu/demo.git"
#        "targetRevision" = "HEAD"
#      }
#      "project" = "default"
#      "syncPolicy" = {
#        "syncOptions" = [
#          "CreateNamespace=true"
#        ]
#        "automated" = {
#          "prune"    = true
#          "selfHeal" = true
#        }
#      }
#    }
#  }
#  depends_on = [helm_release.argocd]
#}

#