# ---------------------------
# AWS Provider Config
# ---------------------------

variable "profile" {
  type        = string
  description = "AWS CLI profile to use for authentication"
}

variable "source_region" {
  type        = string
  description = "Region of the source S3 bucket"
}

variable "destination_region" {
  type        = string
  description = "Region of the destination S3 bucket"
}


# ---------------------------
# S3 Buckets (Source & Destination)
# ---------------------------
variable "source_bucket" {
  type        = string
  description = "Name of the source S3 bucket (from source account)"
}

variable "destination_bucket" {
  type        = string
  description = "Name of the destination S3 bucket in the destination account"
}

# ---------------------------
# IAM Roles
# ---------------------------
variable "source_role_arn" {
  type        = string
  description = "The ARN of the IAM role in the source account that will access the destination bucket"
}

variable "destination_role_arn" {
  type        = string
  description = "The full ARN of the IAM role in the destination account used by DataSync"
}

variable "destination_account_id" {
  type        = string
  description = "The AWS account ID of the destination account"
}

# ---------------------------
# DataSync Task Configuration
# ---------------------------
variable "task_name" {
  type        = string
  description = "Name of the DataSync task"
  default     = "cross-account-s3-datasync"
}
