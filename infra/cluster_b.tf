locals {
  cluster_b_master_cidr = cidrsubnet(var.cluster_b_cidr, 8, 0)
  cluster_b_public_cidr = cidrsubnet(var.cluster_b_cidr, 8, 1)
  cluster_b_elb_cidr    = cidrsubnet(var.cluster_b_cidr, 8, 2)
  cluster_b_pod_cidr    = cidrsubnet(var.cluster_b_cidr, 4, 1)
}

resource "huaweicloud_vpc" "cluster_b" {
  provider = huaweicloud.hk
  name     = "cluster_b"
  cidr     = var.cluster_b_cidr
}

resource "huaweicloud_vpc_subnet" "cluster_b_master" {
  provider = huaweicloud.hk
  name     = "cluster_b_master"
  cidr     = local.cluster_b_master_cidr

  gateway_ip = cidrhost(local.cluster_b_master_cidr, 1)
  vpc_id     = huaweicloud_vpc.cluster_b.id
}

resource "huaweicloud_vpc_subnet" "cluster_b_pod" {
  provider = huaweicloud.hk
  name     = "cluster_b_pod"
  cidr     = local.cluster_b_pod_cidr

  gateway_ip = cidrhost(local.cluster_b_pod_cidr, 1)
  vpc_id     = huaweicloud_vpc.cluster_b.id
}

resource "huaweicloud_vpc_subnet" "cluster_b_elb" {
  provider = huaweicloud.hk
  name     = "cluster_b_elb"
  cidr     = local.cluster_b_elb_cidr

  gateway_ip = cidrhost(local.cluster_b_elb_cidr, 1)
  vpc_id     = huaweicloud_vpc.cluster_b.id
}

//
resource "huaweicloud_vpc_subnet" "cluster_b_public" {
  provider = huaweicloud.hk
  name     = "cluster_b_public"
  cidr     = local.cluster_b_public_cidr

  gateway_ip = cidrhost(local.cluster_b_public_cidr, 1)
  vpc_id     = huaweicloud_vpc.cluster_b.id
}

resource "huaweicloud_nat_gateway" "cluster_b_nat" {
  provider  = huaweicloud.hk
  name      = "cluster_b"
  spec      = "1"
  vpc_id    = huaweicloud_vpc.cluster_b.id
  subnet_id = huaweicloud_vpc_subnet.cluster_b_public.id
}

resource "huaweicloud_vpc_eip" "cluster_b_nat" {
  provider = huaweicloud.hk
  publicip {
    type = "5_bgp"
  }
  bandwidth {
    name        = "cluster-b-nat"
    size        = 8
    share_type  = "PER"
    charge_mode = "traffic"
  }
}

resource "huaweicloud_nat_snat_rule" "cluster_b_cce" {
  provider       = huaweicloud.hk
  nat_gateway_id = huaweicloud_nat_gateway.cluster_b_nat.id
  floating_ip_id = huaweicloud_vpc_eip.cluster_b_nat.id
  subnet_id      = huaweicloud_vpc_subnet.cluster_b_pod.id
}

resource "huaweicloud_nat_snat_rule" "cluster_b_cce_master" {
  provider       = huaweicloud.hk
  nat_gateway_id = huaweicloud_nat_gateway.cluster_b_nat.id
  floating_ip_id = huaweicloud_vpc_eip.cluster_b_nat.id
  subnet_id      = huaweicloud_vpc_subnet.cluster_b_master.id
}
//

resource "huaweicloud_vpc_eip" "cluster_b_api" {
  provider = huaweicloud.hk
  publicip {
    type = "5_bgp"
  }
  bandwidth {
    name        = "cluster-b-api"
    size        = 8
    share_type  = "PER"
    charge_mode = "traffic"
  }
}

resource "huaweicloud_cce_cluster" "cluster_b" {
  provider               = huaweicloud.hk
  name                   = "cluster-b"
  flavor_id              = "cce.s2.small"
  vpc_id                 = huaweicloud_vpc.cluster_b.id
  subnet_id              = huaweicloud_vpc_subnet.cluster_b_master.id
  container_network_type = "eni"
  eni_subnet_id          = huaweicloud_vpc_subnet.cluster_b_pod.ipv4_subnet_id
  eip                    = huaweicloud_vpc_eip.cluster_b_api.address
}

resource "huaweicloud_cce_node_pool" "cluster_b_app" {
  provider                 = huaweicloud.hk
  cluster_id               = huaweicloud_cce_cluster.cluster_b.id
  name                     = "cluster-b-app"
  os                       = "Ubuntu 18.04"
  initial_node_count       = 2
  flavor_id                = "c7n.large.4"
  password                 = "ucs@workshop2023"
  scall_enable             = true
  min_node_count           = 2
  max_node_count           = 5
  scale_down_cooldown_time = 100
  priority                 = 1
  type                     = "vm"

  root_volume {
    size       = 40
    volumetype = "SSD"
  }
  data_volumes {
    size       = 100
    volumetype = "SSD"
  }
}

#resource "local_file" "cluster_b_kubeconfig" {
#  content  = huaweicloud_cce_cluster.cluster_b.kube_config_raw
#  filename = "cluster_b_kubeconfig.json"
#}

output "cluster_b_api_server" {
  value = [for s in huaweicloud_cce_cluster.cluster_b.certificate_clusters : s.server if s.name == "externalClusterTLSVerify"][0]
}

output "cluster_b_ca_certificate" {
  value = base64decode([for s in huaweicloud_cce_cluster.cluster_b.certificate_clusters : s.certificate_authority_data if s.name == "externalClusterTLSVerify"][0])
}

output "cluster_b_client_key" {
  value = base64decode(huaweicloud_cce_cluster.cluster_b.certificate_users[0]["client_key_data"])
}

output "cluster_b_client_certificate" {
  value = base64decode(huaweicloud_cce_cluster.cluster_b.certificate_users[0]["client_certificate_data"])
}