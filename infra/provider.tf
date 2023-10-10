terraform {
  required_providers {
    huaweicloud = {
      source  = "huaweicloud/huaweicloud"
      version = ">= 1.55.0"
    }
  }
}

provider "huaweicloud" {
  region = "ap-southeast-3"
}

provider "huaweicloud" {
  alias  = "hk"
  region = "ap-southeast-1"
}