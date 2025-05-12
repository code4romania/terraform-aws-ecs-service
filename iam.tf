### IAM resources
data "aws_iam_policy_document" "ecs_task_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "ecs_secret_policy" {
  statement {
    actions   = ["secretsmanager:GetSecretValue"]
    resources = var.allowed_secrets
  }
}

data "aws_iam_policy_document" "ssm_policy" {
  statement {
    actions = [
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "${var.namespace}-ecs-task-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume.json
}

resource "aws_iam_role_policy" "ecs_secret_policy" {
  count  = var.allowed_secrets != null ? 1 : 0
  role   = aws_iam_role.ecs_task_execution_role.name
  name   = "SecretsPolicy"
  policy = data.aws_iam_policy_document.ecs_secret_policy.json
}

resource "aws_iam_role_policy" "ssm_policy" {
  count  = var.enable_execute_command ? 1 : 0
  role   = aws_iam_role.ecs_task_execution_role.name
  name   = "SSMPolicy"
  policy = data.aws_iam_policy_document.ssm_policy.json
}

resource "aws_iam_role_policy" "additional_policy" {
  count  = var.additional_policy != null ? 1 : 0
  role   = aws_iam_role.ecs_task_execution_role.name
  name   = "AdditionalPolicy"
  policy = var.additional_policy
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerServiceforEC2Role" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role_policy_attachment" "managed_policies_attachment" {
  count      = length(var.managed_policies)
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = var.managed_policies[count.index]
}
