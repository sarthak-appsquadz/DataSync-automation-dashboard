output "source_role_arn" {
  value = aws_iam_role.datasync_source_role.arn
}

output "destination_role_arn" {
  value = aws_iam_role.datasync_destination_role.arn
}
