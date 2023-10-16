#resource "kubernetes_secret_v1" "demo_repo_credentials" {
#  provider = kubernetes.cluster_fleetmanager
#  metadata {
#    name = "demo-repo-credentials"
#    namespace = "argocd"
#    labels = {
#      "argocd.argoproj.io/secret-type" = "repository"
#    }
#  }
#
#  data = {
#    "type" = "git"
#    "url" = "https://example.com/demo.git"
#    "username" = "xxxx/xxxx"
#    "password" = "xxxx"
#  }
#}
#
#resource "kubernetes_manifest" "globalweb" {
#  provider = kubernetes.cluster_fleetmanager
#  manifest = {
#    "apiVersion" = "argoproj.io/v1alpha1"
#    "kind"       = "ApplicationSet"
#    "metadata" = {
#      "name" = "globalweb"
#      "namespace" = "argocd"
#    }
#    "spec" = {
#      "generators" = [
#        {
#          "list" = {
#            "elements" = [
#              {
#                "cluster" = "cluster-a"
#                "url"     = data.terraform_remote_state.cloud.outputs.cluster_a_api_server
#              },
#              {
#                "cluster" = "cluster-b"
#                "url"     = data.terraform_remote_state.cloud.outputs.cluster_b_api_server
#              }
#            ]
#          }
#        }
#      ]
#      "template" = {
#        "metadata" = {
#          "name" = "{{cluster}}-web"
#        }
#        "spec" = {
#          "project" = "default"
#          "source" = {
#            "path"           = "{{cluster}}"
#            "repoURL"        = "https://example.com/demo.git"
#            "targetRevision" = "HEAD"
#          }
#          "destination" = {
#            "server" = "{{url}}"
#          }
#          "syncPolicy" = {
#            "syncOptions" = [
#                "CreateNamespace=true"
#            ]
#            "automated" = {
#                "prune"    = true
#                "selfHeal" = true
#            }
#          }
#        }
#      }
#    }
#  }
#  depends_on = [ kubernetes_secret_v1.demo_repo_credentials ]
#}