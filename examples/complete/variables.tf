variable "vpc_id" {
  type        = string
  description = "The ID of the VPC to deploy resources into."
}

variable "vpc_public_subnet_ids" {
  type        = list(string)
  description = "The IDs of the public subnets in the VPC to deploy resources into."
}
