variable "source_profile" {
  description = "AWS CLI profile for source account"
  type        = string
}

variable "source_region" {
  description = "Region for source account"
  type        = string
}

variable "destination_profile" {
  description = "AWS CLI profile for destination account"
  type        = string
}

variable "destination_region" {
  description = "Region for destination account"
  type        = string
}

variable "source_bucket_name" {
  description = "S3 bucket name in source account"
  type        = string
}

variable "destination_bucket_name" {
  description = "S3 bucket name in destination account"
  type        = string
}

variable "source_role_name" {
  description = "IAM role name in source account"
  type        = string
}

variable "destination_role_name" {
  description = "IAM role name in destination account"
  type        = string
}

variable "destination_account_id" {
  description = "Destination AWS account ID"
  type        = string
}
