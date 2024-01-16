# Terraform Module: AWS Nginx Proxy Manager

**THIS MODULE IS IN DEVELOPMENT AND IS NOT READY FOR PRODUCTION USE**

This Terraform module deploys a server running Nginx Proxy Manager (NPM).

### Features

- **Integrated**: Works well with your existing infrastructure by following
  CloudPosse's context and labeling patterns.

## Usage

Deploy it using the block below. For the first time deployments, it make take 10
minutes before the web portal is available.

```hcl
module "nginx_proxy_manager" {
  source  = "cruxstack/nginx-proxy-manager/aws"
  version = "x.x.x"

  npm_verison           = "v2.10.4"
  vpc_id                = "vpc-00000000000000"
  vpc_public_subnet_ids = ["subnet-33333333333333", "subnet-44444444444444444", "subnet-55555555555555555"]
}
```

## Inputs

In addition to the variables documented below, this module includes several
other optional variables (e.g., `name`, `tags`, etc.) provided by the
`cloudposse/label/null` module. Please refer to its [documentation](https://registry.terraform.io/modules/cloudposse/label/null/latest)
for more details on these variables.

| Name                    | Description                                                           | Type           | Default | Required |
|-------------------------|-----------------------------------------------------------------------|----------------|---------|:--------:|
| `npm_verison`           | The name of the parent DNS zone.                                      | `string`       | n/a     |   yes    |
| `vpc_id`                | The ID of the VPC to deploy resources into.                           | `string`       | n/a     |   yes    |
| `vpc_public_subnet_ids` | The IDs of the public subnets in the VPC to deploy resources into.    | `list(string)` | n/a     |   yes    |
| `aws_region_name`       | The name of the AWS region.                                           | `string`       | `""`    |    no    |
| `aws_account_id`        | The ID of the AWS account.                                            | `string`       | `""`    |    no    |
| `aws_kv_namespace`      | The namespace or prefix for AWS SSM parameters and similar resources. | `string`       | `""`    |    no    |

### Outputs

| Name                  | Description                                                      |
|-----------------------|------------------------------------------------------------------|
| `security_group_id`   | The ID of the security group created for the Teleport service.   |
| `security_group_name` | The name of the security group created for the Teleport service. |

## Contributing

We welcome contributions to this project. For information on setting up a
development environment and how to make a contribution, see [CONTRIBUTING](./CONTRIBUTING.md)
documentation.
