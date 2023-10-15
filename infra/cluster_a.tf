locals {
  cluster_a_master_cidr = cidrsubnet(var.cluster_a_cidr, 8, 0)
  cluster_a_public_cidr = cidrsubnet(var.cluster_a_cidr, 8, 1)
  cluster_a_elb_cidr    = cidrsubnet(var.cluster_a_cidr, 8, 2)
  cluster_a_pod_cidr    = cidrsubnet(var.cluster_a_cidr, 4, 1)
}

resource "huaweicloud_vpc" "cluster_a" {
  provider = huaweicloud.th
  name = "cluster_a"
  cidr = var.cluster_a_cidr
}

resource "huaweicloud_vpc_subnet" "cluster_a_master" {
  provider = huaweicloud.th
  name = "cluster_a_master"
  cidr = local.cluster_a_master_cidr

  gateway_ip = cidrhost(local.cluster_a_master_cidr, 1)
  vpc_id     = huaweicloud_vpc.cluster_a.id
}

resource "huaweicloud_vpc_subnet" "cluster_a_pod" {
  provider = huaweicloud.th
  name = "cluster_a_pod"
  cidr = local.cluster_a_pod_cidr

  gateway_ip = cidrhost(local.cluster_a_pod_cidr, 1)
  vpc_id     = huaweicloud_vpc.cluster_a.id
}

resource "huaweicloud_vpc_subnet" "cluster_a_elb" {
  provider = huaweicloud.th
  name = "cluster_a_elb"
  cidr = local.cluster_a_elb_cidr

  gateway_ip = cidrhost(local.cluster_a_elb_cidr, 1)
  vpc_id     = huaweicloud_vpc.cluster_a.id
}

resource "huaweicloud_vpc_subnet" "cluster_a_public" {
  provider = huaweicloud.th
  name = "cluster_a_public"
  cidr = local.cluster_a_public_cidr

  gateway_ip = cidrhost(local.cluster_a_public_cidr, 1)
  vpc_id     = huaweicloud_vpc.cluster_a.id
}

resource "huaweicloud_nat_gateway" "cluster_a_nat" {
  provider = huaweicloud.th
  name      = "cluster_a"
  spec      = "1"
  vpc_id    = huaweicloud_vpc.cluster_a.id
  subnet_id = huaweicloud_vpc_subnet.cluster_a_public.id
}

resource "huaweicloud_vpc_eip" "cluster_a_nat" {
  provider = huaweicloud.th
  publicip {
    type = "5_bgp"
  }
  bandwidth {
    name        = "cluster-a-nat"
    size        = 8
    share_type  = "PER"
    charge_mode = "traffic"
  }
}

resource "huaweicloud_nat_snat_rule" "cluster_a_cce" {
  provider = huaweicloud.th
  nat_gateway_id = huaweicloud_nat_gateway.cluster_a_nat.id
  floating_ip_id = huaweicloud_vpc_eip.cluster_a_nat.id
  subnet_id      = huaweicloud_vpc_subnet.cluster_a_pod.id
}

resource "huaweicloud_nat_snat_rule" "cluster_a_cce_master" {
  provider = huaweicloud.th
  nat_gateway_id = huaweicloud_nat_gateway.cluster_a_nat.id
  floating_ip_id = huaweicloud_vpc_eip.cluster_a_nat.id
  subnet_id      = huaweicloud_vpc_subnet.cluster_a_master.id
}

//

resource "huaweicloud_vpc_eip" "cluster_a_api" {
  provider = huaweicloud.th
  publicip {
    type = "5_bgp"
  }
  bandwidth {
    name        = "cluster-a-api"
    size        = 8
    share_type  = "PER"
    charge_mode = "traffic"
  }
}

resource "huaweicloud_cce_cluster" "cluster_a" {
  provider = huaweicloud.th
  name                   = "cluster-a"
  flavor_id              = "cce.s2.small"
  vpc_id                 = huaweicloud_vpc.cluster_a.id
  subnet_id              = huaweicloud_vpc_subnet.cluster_a_master.id
  container_network_type = "eni"
  eni_subnet_id          = huaweicloud_vpc_subnet.cluster_a_pod.ipv4_subnet_id
  eip                    = huaweicloud_vpc_eip.cluster_a_api.address
}

resource "huaweicloud_cce_node_pool" "cluster_a" {
  provider = huaweicloud.th
  cluster_id               = huaweicloud_cce_cluster.cluster_a.id
  name                     = "cluster-a"
  os                       = "Ubuntu 22.04"
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

#resource "local_file" "cluster_a_kubeconfig" {
#  content  = huaweicloud_cce_cluster.cluster_a.kube_config_raw
#  filename = "cluster_a_kubeconfig.json"
#}

output "cluster_a_api_server" {
  value = [for s in huaweicloud_cce_cluster.cluster_a.certificate_clusters : s.server if s.name == "externalClusterTLSVerify"][0]
}

output "cluster_a_ca_certificate" {
  value = base64decode([for s in huaweicloud_cce_cluster.cluster_a.certificate_clusters : s.certificate_authority_data if s.name == "externalClusterTLSVerify"][0])
}

output "cluster_a_client_key" {
  value = base64decode(huaweicloud_cce_cluster.cluster_a.certificate_users[0]["client_key_data"])
}

output "cluster_a_client_certificate" {
  value = base64decode(huaweicloud_cce_cluster.cluster_a.certificate_users[0]["client_certificate_data"])
}