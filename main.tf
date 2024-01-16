locals {
  enabled = coalesce(var.enabled, true)
  name    = coalesce(var.name, module.this.name, "nginx-proxy-manager-${random_string.npm_random_suffix.result}")

  aws_account_id   = var.aws_account_id != "" ? var.aws_account_id : try(data.aws_caller_identity.current[0].account_id, "")
  aws_region_name  = var.aws_region_name != "" ? var.aws_region_name : try(data.aws_region.current[0].name, "")
  aws_kv_namespace = trim(coalesce(var.aws_kv_namespace, "nginx-proxy-manager/${module.npm_label.id}"), "/")

  instance_image_id     = try(data.aws_ssm_parameter.this[0].value, "")
  eip_count             = 1
  eip_manager_key_name  = "${local.aws_kv_namespace}/eip-manager-pool"
  eip_manager_key_value = "servers"

  asg_desired_capacity = 1
  asg_min_size         = 1
  asg_max_size         = 1

  docker_compose = {
    version = "3.8"
    services = {
      app = {
        image        = "jc21/nginx-proxy-manager:latest"
        restart      = "unless-stopped"
        network_mode = "host"
        ports = [
          "80:80",
          "443:443",
          "81:81" # admin console
        ]
        volumes = [
          "/mnt/s3/data:/data",
          "/mnt/s3/letsencrypt:/etc/letsencrypt"
        ]
        environment = {
          DB_SQLITE_FILE = "/data/database.sqlite"
        }
      }
    }
  }

  cloud_init_parts = [{
    content_type = "text/cloud-config"
    content = templatefile("${path.module}/assets/cloud-init/cloud-config.yaml", {
      cloudwatch_agent_config_encoded = base64encode(
        templatefile("${path.module}/assets/cloud-init/cw-agent-config.json", {
          log_group_name = try(aws_cloudwatch_log_group.this[0].name, "")
        })
      )
      docker_compose_encoded = base64encode(yamlencode(local.docker_compose))
    })
    },
    {
      content_type = "text/x-shellscript"
      content      = file("${path.module}/assets/cloud-init/start_services.sh")
    },
    {
      content_type = "text/x-shellscript"
      content      = file("${path.module}/assets/cloud-init/install_packages.sh")
    },
    {
      content_type = "text/x-shellscript"
      content = templatefile("${path.module}/assets/cloud-init/userdata.sh", {
        s3_bucket_name = module.s3_buckets.bucket_id
      })
  }]
}

data "aws_caller_identity" "current" {
  count = module.this.enabled && var.aws_account_id == "" ? 1 : 0
}

data "aws_region" "current" {
  count = module.this.enabled && var.aws_region_name == "" ? 1 : 0
}

# ====================================================== nginx-proxy-manager ===

module "npm_label" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  name    = local.name
  context = module.this.context
}

# only appliable if name variable was not set
resource "random_string" "npm_random_suffix" {
  length  = 6
  special = false
  upper   = false
}

# ------------------------------------------------------------------ servers ---

module "servers" {
  source  = "cloudposse/ec2-autoscale-group/aws"
  version = "0.39.0"

  image_id                    = local.instance_image_id
  instance_type               = "t3.nano"
  health_check_type           = "EC2"
  user_data_base64            = base64encode(data.template_cloudinit_config.this[0].rendered)
  associate_public_ip_address = true

  subnet_ids         = var.vpc_public_subnet_ids
  security_group_ids = [module.security_group.id]

  iam_instance_profile_name     = local.enabled ? resource.aws_iam_instance_profile.this[0].id : null
  key_name                      = "" # no ssh access allowed
  metadata_http_tokens_required = true

  mixed_instances_policy = {
    instances_distribution = {
      on_demand_base_capacity                  = var.instance_spot_enabled ? 0 : 1
      on_demand_percentage_above_base_capacity = var.instance_spot_enabled ? 0 : 100
      on_demand_allocation_strategy            = "prioritized"
      spot_allocation_strategy                 = "capacity-optimized"
      spot_instance_pools                      = 0
      spot_max_price                           = ""
    }
    override = [
      for x in var.instance_sizes : {
        instance_type     = x
        weighted_capacity = 1
      }
    ]
  }

  autoscaling_policies_enabled      = false
  desired_capacity                  = local.asg_desired_capacity
  min_size                          = local.asg_min_size
  max_size                          = local.asg_max_size
  max_instance_lifetime             = null
  wait_for_capacity_timeout         = "300s"
  tag_specifications_resource_types = concat(["instance", "volume"], var.instance_spot_enabled ? ["spot-instances-request"] : [])

  force_delete            = var.experimental_mode
  disable_api_termination = false

  instance_refresh = {
    strategy = "Rolling"
    triggers = ["tag"]
    preferences = {
      instance_warmup        = 300
      min_healthy_percentage = 0
    }
  }

  tags    = merge(module.npm_label.tags, { Name = module.npm_label.id }, { (local.eip_manager_key_name) = local.eip_manager_key_value })
  context = module.npm_label.context
}

data "template_cloudinit_config" "this" {
  count = local.enabled ? 1 : 0

  gzip          = true
  base64_encode = true

  dynamic "part" {
    for_each = local.cloud_init_parts

    content {
      content_type = part.value.content_type
      content      = part.value.content
    }
  }
}

# ------------------------------------------------------------------ logging ---

resource "aws_cloudwatch_log_group" "this" {
  count = local.enabled ? 1 : 0

  name              = module.npm_label.id
  retention_in_days = var.experimental_mode ? 90 : 180
  tags              = module.npm_label.tags
}

# --------------------------------------------------------------------- eips ---

resource "aws_eip" "this" {
  count = local.eip_count

  tags = merge(
    module.npm_label.tags,
    { "Name" = module.npm_label.id },
    { (local.eip_manager_key_name) = local.eip_manager_key_value },
  )
}

module "eip_manager" {
  source  = "cruxstack/eip-manager/aws"
  version = "0.1.0"

  enabled         = true
  attributes      = ["eip-manager"]
  pool_tag_key    = local.eip_manager_key_name
  pool_tag_values = [module.npm_label.id]

  context = module.npm_label.context
}

# ----------------------------------------------------------- security-group ---

module "security_group" {
  source  = "cloudposse/security-group/aws"
  version = "0.4.0"

  vpc_id = var.vpc_id
  rules = [{
    key                      = "egress"
    type                     = "egress"
    from_port                = 0
    to_port                  = 0
    protocol                 = "all"
    description              = "allow all egress"
    cidr_blocks              = ["0.0.0.0/0"]
    source_security_group_id = null
    self                     = null
    }, {
    key                      = "web-80"
    type                     = "ingress"
    from_port                = 80
    to_port                  = 80
    protocol                 = "tcp"
    description              = "allow all http traffic"
    cidr_blocks              = ["0.0.0.0/0"]
    source_security_group_id = null
    self                     = null
    }, {
    key                      = "web-443"
    type                     = "ingress"
    from_port                = 443
    to_port                  = 443
    protocol                 = "tcp"
    description              = "allow all https traffic"
    cidr_blocks              = ["0.0.0.0/0"]
    source_security_group_id = null
    self                     = null
  }]

  tags    = merge(module.npm_label.tags, { Name = module.npm_label.id })
  context = module.npm_label.context
}

# =================================================================== storge ===

module "s3_buckets" {
  source  = "cloudposse/s3-bucket/aws"
  version = "4.0.1"

  acl                     = "private"
  force_destroy           = var.experimental_mode
  sse_algorithm           = "AES256"
  allow_ssl_requests_only = true

  lifecycle_configuration_rules = [{
    enabled = true
    id      = "main"

    abort_incomplete_multipart_upload_days = 5
    expiration                             = null
    filter_and                             = null
    transition                             = []
    noncurrent_version_expiration          = null
    noncurrent_version_transition          = []
  }]

  context = module.npm_label.context
}

# ====================================================================== iam ===

resource "aws_iam_instance_profile" "this" {
  count = local.enabled ? 1 : 0

  name = module.npm_label.id
  role = aws_iam_role.this[0].name
}

resource "aws_iam_role" "this" {
  count = local.enabled ? 1 : 0

  name                 = module.npm_label.id
  description          = ""
  max_session_duration = "3600"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = ["sts:AssumeRole", "sts:TagSession"]
    }]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
  ]

  inline_policy {
    name   = "access"
    policy = data.aws_iam_policy_document.this[0].json
  }

  tags = module.npm_label.tags
}

data "aws_iam_policy_document" "this" {
  count = local.enabled ? 1 : 0

  statement {
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${module.s3_buckets.bucket_id}"]
  }

  statement {
    effect    = "Allow"
    actions   = ["s3:*Object*"]
    resources = ["arn:aws:s3:::${module.s3_buckets.bucket_id}/*"]
  }
}

# ================================================================== lookups ===

data "aws_ssm_parameter" "this" {
  count = local.enabled ? 1 : 0
  name  = "/aws/service/ecs/optimized-ami/amazon-linux-2023/recommended/image_id"
}
