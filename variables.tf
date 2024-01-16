# ====================================================================== npm ===

variable "npm_verison" {
  type        = string
  description = "The runtime version of nginx proxy manager (npm)."
}

variable "experimental_mode" {
  type        = bool
  description = "Toggle to enable a preset of settings such as log retention."
  default     = false
}

# ----------------------------------------------------------------- instance ---

variable "instance_sizes" {
  type    = list(string)
  default = ["t3.micro", "t3a.micro"]
}

variable "instance_spot_enabled" {
  type        = bool
  description = "Toggle to use spot instances."
  default     = false
}

# ------------------------------------------------------------------ network ---

variable "vpc_id" {
  type        = string
  description = "The ID of the VPC to deploy resources into."
}

variable "vpc_public_subnet_ids" {
  type        = list(string)
  description = "The IDs of the public subnets in the VPC to deploy resources into."
}

# ================================================================== context ===

variable "aws_region_name" {
  type        = string
  description = "The name of the AWS region."
  default     = ""
}

variable "aws_account_id" {
  type        = string
  description = "The ID of the AWS account."
  default     = ""
}

variable "aws_kv_namespace" {
  type        = string
  description = "The namespace or prefix for AWS SSM parameters and similar resources."
  default     = ""
}
