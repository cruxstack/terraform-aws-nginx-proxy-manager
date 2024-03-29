# Example: Complete

This directory contains a complete example of how to use the AWS Nginx Proxy
Manager module in a real-world scenario.

## Overview

This example deploys a Teleport cluster with the following configuration:

- Teleport auth, node, and proxy services deployed in a high-availability (HA)
  configuration.
- Deployment into a specified AWS VPC and subnets.

## Usage

To run this example, provide your own values for the following variables in a
`.terraform.tfvars` file:

```hcl
vpc_id                     = "your-vpc-id"
vpc_public_subnet_ids      = ["your-public-subnet-id"]
```

## Inputs

| Name                  | Description                                                        | Type           | Default | Required |
|-----------------------|--------------------------------------------------------------------|----------------|---------|:--------:|
| vpc_id                | The ID of the VPC to deploy resources into.                        | `string`       | n/a     |   yes    |
| vpc_public_subnet_ids | The IDs of the public subnets in the VPC to deploy resources into. | `list(string)` | n/a     |   yes    |

## Outputs

N/A
```
