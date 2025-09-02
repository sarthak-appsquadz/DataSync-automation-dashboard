# terraform {
#   required_providers {
#     aws = {
#       source  = "hashicorp/aws"
#       version = ">= 5.0"
#     }
#   }
# }


# # ---------------------------
# # Providers for both regions
# # ---------------------------
# provider "aws" {
#   profile = var.profile
#   region  = var.destination_region
# }

# provider "aws" {
#   alias   = "source"
#   profile = var.profile
#   region  = var.source_region
# }

# # ---------------------------
# # Destination Bucket
# # ---------------------------
# resource "aws_s3_bucket" "destination_bucket" {
#   provider = aws
#   bucket   = var.destination_bucket
# }

# # ---------------------------
# # DataSync Source Location
# # ---------------------------
# resource "aws_datasync_location_s3" "source" {
#   provider       = aws.source
#   s3_bucket_arn  = "arn:aws:s3:::${var.source_bucket}"
#   subdirectory   = "/"

#   s3_config {
#     bucket_access_role_arn = var.source_role_arn
#   }
# }

# # ---------------------------
# # DataSync Destination Location
# # ---------------------------
# resource "aws_datasync_location_s3" "destination" {
#   provider       = aws
#   s3_bucket_arn  = aws_s3_bucket.destination_bucket.arn
#   subdirectory   = "/"

#   s3_config {
#     bucket_access_role_arn = var.destination_role_arn
#   }
# }

# # ---------------------------
# # DataSync Task
# # ---------------------------
# resource "aws_datasync_task" "s3_cross_account_task" {
#   provider = aws
#   name     = var.task_name

#   source_location_arn      = aws_datasync_location_s3.source.arn
#   destination_location_arn = aws_datasync_location_s3.destination.arn

#   options {
#     overwrite_mode                 = "ALWAYS"
#     atime                          = "BEST_EFFORT"
#     bytes_per_second               = -1
#     gid                            = "NONE"
#     mtime                          = "PRESERVE"
#     posix_permissions              = "NONE"
#     preserve_deleted_files         = "PRESERVE"
#     preserve_devices               = "NONE"
#     uid                            = "NONE"
#     object_tags                    = "PRESERVE"
#     transfer_mode                  = "ALL"
#     verify_mode                    = "POINT_IN_TIME_CONSISTENT"
#     security_descriptor_copy_flags = "NONE"
#     task_queueing                  = "ENABLED"
#   }
# }


terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

# ---------------------------
# Provider (Destination Account Only)
# ---------------------------
provider "aws" {
  alias   = "destination"
  profile = var.profile
  region  = var.destination_region
}

provider "aws" {
  alias   = "source"
  profile = var.profile
  region  = var.source_region
}

# ---------------------------
# Destination Bucket
# ---------------------------
resource "aws_s3_bucket" "destination_bucket" {
  bucket = var.destination_bucket
}

# ---------------------------
# DataSync Source Location (created in destination account)
# ---------------------------
# resource "aws_datasync_location_s3" "source" {
#   s3_bucket_arn = "arn:aws:s3:::${var.source_bucket}"
#   subdirectory  = "/"

#   s3_config {
#     bucket_access_role_arn = var.destination_role_arn
#   }
# }

resource "aws_datasync_location_s3" "source" {
  provider      = aws.source
  s3_bucket_arn = "arn:aws:s3:::${var.source_bucket}"
  subdirectory  = "/"

  s3_config {
    bucket_access_role_arn = var.destination_role_arn
  }
}

# ---------------------------
# DataSync Destination Location
# ---------------------------
# resource "aws_datasync_location_s3" "destination" {
#   s3_bucket_arn = aws_s3_bucket.destination_bucket.arn
#   subdirectory  = "/"

#   s3_config {
#     bucket_access_role_arn = var.destination_role_arn
#   }
# }

resource "aws_datasync_location_s3" "destination" {
  provider      = aws.destination
  s3_bucket_arn = aws_s3_bucket.destination_bucket.arn
  subdirectory  = "/"

  s3_config {
    bucket_access_role_arn = var.destination_role_arn
  }
}
# ---------------------------
# DataSync Task
# ---------------------------
# resource "aws_datasync_task" "s3_cross_account_task" {
#   name = var.task_name

#   source_location_arn      = aws_datasync_location_s3.source.arn
#   destination_location_arn = aws_datasync_location_s3.destination.arn

resource "aws_datasync_task" "s3_cross_account_task" {
  provider = aws.destination
  name     = var.task_name

  source_location_arn      = aws_datasync_location_s3.source.arn
  destination_location_arn = aws_datasync_location_s3.destination.arn

  options {
    overwrite_mode                 = "ALWAYS"
    atime                          = "BEST_EFFORT"
    bytes_per_second               = -1
    gid                            = "NONE"
    mtime                          = "PRESERVE"
    posix_permissions              = "NONE"
    preserve_deleted_files         = "PRESERVE"
    preserve_devices               = "NONE"
    uid                            = "NONE"
    object_tags                    = "PRESERVE"
    transfer_mode                  = "ALL"
    verify_mode                    = "POINT_IN_TIME_CONSISTENT"
    security_descriptor_copy_flags = "NONE"
    task_queueing                  = "ENABLED"
  }
}
