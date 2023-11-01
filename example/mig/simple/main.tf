provider "google" {
  project = "opz0-397319"
  region  = "asia-northeast1"
  zone    = "asia-northeast1-a"
}

######==============================================================================
###### vpc module call.
######==============================================================================
module "vpc" {
  source                                    = "git::git@github.com:opz0/terraform-gcp-vpc.git?ref=master"
  name                                      = "app"
  environment                               = "test"
  network_firewall_policy_enforcement_order = "AFTER_CLASSIC_FIREWALL"
}

######==============================================================================
###### subnet module call.
######==============================================================================
module "subnet" {
  source        = "git::git@github.com:opz0/terraform-gcp-subnet.git?ref=master"
  name          = "subnet"
  environment   = "test"
  gcp_region    = "asia-northeast1"
  network       = module.vpc.vpc_id
  source_ranges = ["10.10.0.0/16"]
}

######==============================================================================
##### firewall module call.
#####==============================================================================
module "firewall" {
  source        = "git::git@github.com:opz0/terraform-gcp-firewall.git?ref=master"
  name          = "app"
  environment   = "test"
  network       = module.vpc.vpc_id
  source_ranges = ["0.0.0.0/0"]

  allow = [
    { protocol = "tcp"
      ports    = ["22", "80"]
    }
  ]
}


#####==============================================================================
##### instance_template module call.
#####==============================================================================
module "instance_template" {
  source               = "git::git@github.com:opz0/terraform-gcp-template-instance.git?ref=master"
  instance_template    = true
  name                 = "template"
  environment          = "test"
  region               = "asia-northeast1"
  source_image         = "ubuntu-2204-jammy-v20230908"
  source_image_family  = "ubuntu-2204-lts"
  source_image_project = "ubuntu-os-cloud"
  subnetwork           = module.subnet.subnet_id
  service_account      = null
  metadata = {
    ssh-keys = <<EOF
          dev:ssh-rsa +j/FmgC27u/+L6ihYrPhcx5////+/+nOlPpV2QeNspI/6wih87hbyvUsE0y1fyds3kD9zVWQNzLd2BW4QZ/ZoaYRVY365S8LEqGxUVRbuyzni+51lj99yDW8X8W/zKU+lCBaggRjlkx4Q3NWS1gefgv3k/3mwt2y+PDQMU= suresh@suresh

        EOF
  }
  access_config = [{
    nat_ip       = ""
    network_tier = ""
  }, ]
}

#####==============================================================================
##### instance_group module call.
#####==============================================================================
module "mig" {
  source              = "../../../"
  region              = "asia-northeast1"
  target_size         = 2
  hostname            = "test"
  environment         = "mig-simple"
  instance_template   = module.instance_template.self_link_unique
  autoscaling_enabled = false

  autoscaling_cpu = [
    {
      target            = 0.7
      predictive_method = null
    },
  ]
}