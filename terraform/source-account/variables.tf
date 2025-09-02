# variable "region" {
#   type        = string
#   description = "AWS region"
# }

variable "source_region" {
  type        = string
  description = "AWS region"
}

variable "aws_profile" {
  default = "AccountA"
}

variable "source_bucket" {
  type        = string
  description = "Source S3 bucket name (already exists)"
}


variable "profile" {
  type        = string
  description = "AWS CLI profile to use for authentication"
}

variable "source_role_arn" {
  type = string
}

variable "destination_role_arn" {
  description = "IAM role in destination account that pulls from source"
  type        = string
}
