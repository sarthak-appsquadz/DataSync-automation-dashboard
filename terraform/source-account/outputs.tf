output "source_bucket_arn" {
  description = "ARN of the source S3 bucket"
  value       = "arn:aws:s3:::${var.source_bucket}"
}

output "source_bucket_name" {
  description = "Name of the source S3 bucket"
  value       = var.source_bucket
}
