resource "aws_flow_log" "another_flow" {
  iam_role_arn    = aws_iam_role.another_flow_role.arn
  log_destination = aws_cloudwatch_log_group.utility_flow_log.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.utility.id
  tags = {
    yor_trace = "60f26394-27ed-42e6-8a63-1a54d8eea3e3"
    git_org   = "dukekautington3rd"
    git_repo  = "tf-nodered-aws"
  }
}

resource "aws_cloudwatch_log_group" "utility_flow_log" {
  name              = "utility_flow_log-${random_string.suffix.id}"
  retention_in_days = 1
  tags = {
    yor_trace = "cc0e46b3-729e-4fb2-a72a-5b0025ddbc3e"
    git_org   = "dukekautington3rd"
    git_repo  = "tf-nodered-aws"
  }
}