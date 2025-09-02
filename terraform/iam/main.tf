terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

# --- Source Account Provider ---
provider "aws" {
  alias   = "source"
  region  = var.source_region
  profile = var.source_profile
}

# --- Destination Account Provider ---
provider "aws" {
  alias   = "destination"
  region  = var.destination_region
  profile = var.destination_profile
}

# --- Source IAM Role (assumed by DataSync in destination) ---
resource "aws_iam_role" "datasync_source_role" {
  provider = aws.source
  name     = var.source_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "datasync.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "datasync_source_policy" {
  provider = aws.source
  name     = "DataSyncSourceS3Policy"
  role     = aws_iam_role.datasync_source_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:ListObjectsV2"
        ],
        Resource = [
          "arn:aws:s3:::${var.source_bucket_name}",
          "arn:aws:s3:::${var.source_bucket_name}/*"
        ]
      }
    ]
  })
}

# --- Destination IAM Role ---
resource "aws_iam_role" "datasync_destination_role" {
  provider = aws.destination
  name     = var.destination_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "datasync.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}


resource "aws_iam_role_policy" "datasync_destination_policy" {
  provider = aws.destination
  name     = "DataSyncDestinationS3Policy"
  role     = aws_iam_role.datasync_destination_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Permissions for SOURCE bucket (read operations)
      {
        Effect = "Allow"
        Action = [
          "s3:GetBucketLocation",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads",
          "s3:GetBucketPolicy"
          # "s3:ListObjectsV2"
        ]
        Resource = "arn:aws:s3:::${var.source_bucket_name}"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:GetObjectTagging",
          "s3:ListMultipartUploadParts"
        ]
        Resource = "arn:aws:s3:::${var.source_bucket_name}/*"
      },
      
      # Permissions for DESTINATION bucket (write operations)
      {
        Effect = "Allow"
        Action = [
          "s3:GetBucketLocation",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads",
          "s3:PutObject",
          "s3:PutObjectTagging",
          "s3:GetObjectTagging",
          "s3:DeleteObject",
          "s3:AbortMultipartUpload"
        ]
        Resource = [
          "arn:aws:s3:::${var.destination_bucket_name}",
          "arn:aws:s3:::${var.destination_bucket_name}/*"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:GetObjectTagging",
          "s3:GetObjectVersion",
          "s3:GetObjectVersionTagging"
        ],
        Resource = "arn:aws:s3:::${var.destination_bucket_name}/*"
      }
    ]
  })
}