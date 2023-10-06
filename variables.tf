data "aws_ami" "rhel8" {
  most_recent      = true

  filter {
    name   = "name"
    values = ["RHEL-8.6*"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

}

variable "name" {
  type        = string
  description = "ROSA cluster name"

  validation {
    condition     = length(var.name) <= 15
    error_message = "The ROSA cluster name must be 15 characters or fewer."
  }
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

variable "bastion_key_loc" {
  type        = string
  default     = "./jumphost-key.pub"
  description = "Location of public key for bastion"
}
