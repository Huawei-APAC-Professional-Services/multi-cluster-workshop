locals {
  fleetmanager_master_cidr = cidrsubnet(var.fleetmanager_cidr, 8, 0)
  fleetmanager_pod_cidr    = cidrsubnet(var.fleetmanager_cidr, 4, 1)
  fleetmanager_public_cidr = cidrsubnet(var.fleetmanager_cidr, 8, 1)
}

resource "huaweicloud_vpc" "fleetmanager" {
  name = "fleetmanager"
  cidr = var.fleetmanager_cidr
}

resource "huaweicloud_vpc_subnet" "fleetmanager_master" {
  name = "fleetmanager_master"
  cidr = local.fleetmanager_master_cidr

  gateway_ip = cidrhost(local.fleetmanager_master_cidr, 1)
  vpc_id     = huaweicloud_vpc.fleetmanager.id
}

resource "huaweicloud_vpc_subnet" "fleetmanager_pod" {
  name = "fleetmanager_pod"
  cidr = local.fleetmanager_pod_cidr

  gateway_ip = cidrhost(local.fleetmanager_pod_cidr, 1)
  vpc_id     = huaweicloud_vpc.fleetmanager.id
}

resource "huaweicloud_vpc_subnet" "fleetmanager_public" {
  name = "fleetmanager_public"
  cidr = local.fleetmanager_public_cidr

  gateway_ip = cidrhost(local.fleetmanager_public_cidr, 1)
  vpc_id     = huaweicloud_vpc.fleetmanager.id
}

resource "huaweicloud_nat_gateway" "fleetmanager_nat" {
  name      = "fleetmanager"
  spec      = "1"
  vpc_id    = huaweicloud_vpc.fleetmanager.id
  subnet_id = huaweicloud_vpc_subnet.fleetmanager_public.id
}

resource "huaweicloud_vpc_eip" "fleetmanager_nat" {
  publicip {
    type = "5_bgp"
  }
  bandwidth {
    name        = "fleetmanager-nat"
    size        = 8
    share_type  = "PER"
    charge_mode = "traffic"
  }
}

resource "huaweicloud_nat_snat_rule" "fleetmanager_cce" {
  nat_gateway_id = huaweicloud_nat_gateway.fleetmanager_nat.id
  floating_ip_id = huaweicloud_vpc_eip.fleetmanager_nat.id
  subnet_id      = huaweicloud_vpc_subnet.fleetmanager_pod.id
}

resource "huaweicloud_nat_snat_rule" "fleetmanager_cce_master" {
  nat_gateway_id = huaweicloud_nat_gateway.fleetmanager_nat.id
  floating_ip_id = huaweicloud_vpc_eip.fleetmanager_nat.id
  subnet_id      = huaweicloud_vpc_subnet.fleetmanager_master.id
}

resource "huaweicloud_vpc_eip" "fleetmanager_api" {
  publicip {
    type = "5_bgp"
  }
  bandwidth {
    name        = "fleetmanager-api"
    size        = 8
    share_type  = "PER"
    charge_mode = "traffic"
  }
}

resource "huaweicloud_cce_cluster" "fleetmanager" {
  name                   = "fleetmanager"
  flavor_id              = "cce.s2.small"
  vpc_id                 = huaweicloud_vpc.fleetmanager.id
  subnet_id              = huaweicloud_vpc_subnet.fleetmanager_master.id
  container_network_type = "eni"
  eni_subnet_id          = huaweicloud_vpc_subnet.fleetmanager_pod.ipv4_subnet_id
  eip                    = huaweicloud_vpc_eip.fleetmanager_api.address
}

resource "huaweicloud_cce_node_pool" "fleetmanager" {
  cluster_id               = huaweicloud_cce_cluster.fleetmanager.id
  name                     = "fleetmanager"
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

data "huaweicloud_elb_flavors" "argocd" {
  type            = "L4"
  max_connections = 500000
  cps             = 10000
  bandwidth       = 50
}

resource "huaweicloud_vpc_eip" "argocd_elb" {
  publicip {
    type = "5_bgp"
  }

  bandwidth {
    share_type  = "PER"
    name        = "argocd"
    size        = 300
    charge_mode = "traffic"
  }
}

resource "huaweicloud_elb_loadbalancer" "argocd" {
  name              = "argocd"
  cross_vpc_backend = true

  vpc_id         = huaweicloud_vpc.fleetmanager.id
  ipv4_subnet_id = huaweicloud_vpc_subnet.fleetmanager_public.ipv4_subnet_id

  l4_flavor_id = data.huaweicloud_elb_flavors.argocd.ids[0]

  availability_zone = var.argocd_elb_azs

  ipv4_eip_id = huaweicloud_vpc_eip.argocd_elb.id
}

#resource "local_file" "cluster_fleetmanager_kubeconfig" {
#  content  = huaweicloud_cce_cluster.fleetmanager.kube_config_raw
#  filename = "cluster_fleetmanager_kubeconfig.json"
#}

output "cluster_fleetmanager_api_server" {
  value = [for s in huaweicloud_cce_cluster.fleetmanager.certificate_clusters : s.server if s.name == "externalClusterTLSVerify"][0]
}

output "cluster_fleetmanager_ca_certificate" {
  value = base64decode([for s in huaweicloud_cce_cluster.fleetmanager.certificate_clusters : s.certificate_authority_data if s.name == "externalClusterTLSVerify"][0])
}

output "cluster_fleetmanager_client_key" {
  value = base64decode(huaweicloud_cce_cluster.fleetmanager.certificate_users[0]["client_key_data"])
}

output "cluster_fleetmanager_client_certificate" {
  value = base64decode(huaweicloud_cce_cluster.fleetmanager.certificate_users[0]["client_certificate_data"])
}

output "argocd_lb_id" {
  value = huaweicloud_elb_loadbalancer.argocd.id
}

output "argocd_lb_public_ip" {
  value = huaweicloud_vpc_eip.argocd_elb.address
}