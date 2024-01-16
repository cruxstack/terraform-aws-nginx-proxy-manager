locals {
  name = "tf-example-complete-${random_string.example_random_suffix.result}"
  tags = { tf_module = "cruxstack/nginx-proxy-manager/aws", tf_module_example = "complete" }
}

# ================================================================== example ===

module "npm_servers" {
  source = "../.."

  npm_verison           = "2.10.14"
  experimental_mode     = true
  instance_spot_enabled = true
  vpc_id                = var.vpc_id
  vpc_public_subnet_ids = var.vpc_public_subnet_ids

  context = module.example_label.context # not required
}

# ===================================================== supporting-resources ===

module "example_label" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  name        = local.name
  environment = "use1" # us-east-1
  tags        = local.tags

  context = module.this.context
}

resource "random_string" "example_random_suffix" {
  length  = 6
  special = false
  upper   = false
}
