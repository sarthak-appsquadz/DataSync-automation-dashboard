
output "destination_bucket_name" {
  description = "Name of the destination S3 bucket"
  value       = aws_s3_bucket.destination_bucket.id
}

# output "destination_bucket_policy_id" {
#   description = "ID of the applied S3 bucket policy"
#   value       = aws_s3_bucket_policy.destination_bucket_policy.id
# }
