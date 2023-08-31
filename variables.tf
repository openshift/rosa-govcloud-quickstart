variable "name" {
  type        = string
  description = "ROSA cluster name"
}

variable "cidr" {
  type        = string
  default     = "10.0.0.0/16"
  description = "ROSA cluster VPC CIDR"
}

variable "multi_az" {
  type        = bool
  default     = false
  description = "Setup a multi-AZ VPC for the cluster"
}

variable "create_elb_iam_role" {
  type        = bool
  default     = false
  description = "Create the elasticloadbalancing IAM service-linked role"
}
