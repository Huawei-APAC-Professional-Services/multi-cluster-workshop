terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.0"
    }
  }
}

data "terraform_remote_state" "cloud" {
  backend = "local"

  config = {
    path = "${path.module}/../infra/terraform.tfstate"
  }
}

provider "kubernetes" {
  alias                  = "cluster_fleetmanager"
  host                   = data.terraform_remote_state.cloud.outputs.cluster_fleetmanager_api_server
  cluster_ca_certificate = data.terraform_remote_state.cloud.outputs.cluster_fleetmanager_ca_certificate
  client_key             = data.terraform_remote_state.cloud.outputs.cluster_fleetmanager_client_key
  client_certificate     = data.terraform_remote_state.cloud.outputs.cluster_fleetmanager_client_certificate
}

provider "kubernetes" {
  alias                  = "cluster_a"
  host                   = data.terraform_remote_state.cloud.outputs.cluster_a_api_server
  cluster_ca_certificate = data.terraform_remote_state.cloud.outputs.cluster_a_ca_certificate
  client_key             = data.terraform_remote_state.cloud.outputs.cluster_a_client_key
  client_certificate     = data.terraform_remote_state.cloud.outputs.cluster_a_client_certificate
}

provider "kubernetes" {
  alias                  = "cluster_b"
  host                   = data.terraform_remote_state.cloud.outputs.cluster_b_api_server
  cluster_ca_certificate = data.terraform_remote_state.cloud.outputs.cluster_b_ca_certificate
  client_key             = data.terraform_remote_state.cloud.outputs.cluster_b_client_key
  client_certificate     = data.terraform_remote_state.cloud.outputs.cluster_b_client_certificate
}

provider "helm" {
  alias = "cluster_fleetmanager"
  kubernetes {
    host                   = data.terraform_remote_state.cloud.outputs.cluster_fleetmanager_api_server
    cluster_ca_certificate = data.terraform_remote_state.cloud.outputs.cluster_fleetmanager_ca_certificate
    client_key             = data.terraform_remote_state.cloud.outputs.cluster_fleetmanager_client_key
    client_certificate     = data.terraform_remote_state.cloud.outputs.cluster_fleetmanager_client_certificate
  }
}

provider "helm" {
  alias = "cluster_a"
  kubernetes {
    host                   = data.terraform_remote_state.cloud.outputs.cluster_a_api_server
    cluster_ca_certificate = data.terraform_remote_state.cloud.outputs.cluster_a_ca_certificate
    client_key             = data.terraform_remote_state.cloud.outputs.cluster_a_client_key
    client_certificate     = data.terraform_remote_state.cloud.outputs.cluster_a_client_certificate
  }
}

provider "helm" {
  alias = "cluster_b"
  kubernetes {
    host                   = data.terraform_remote_state.cloud.outputs.cluster_b_api_server
    cluster_ca_certificate = data.terraform_remote_state.cloud.outputs.cluster_b_ca_certificate
    client_key             = data.terraform_remote_state.cloud.outputs.cluster_b_client_key
    client_certificate     = data.terraform_remote_state.cloud.outputs.cluster_b_client_certificate
  }
}