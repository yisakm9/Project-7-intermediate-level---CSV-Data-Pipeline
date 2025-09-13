resource "aws_iam_role" "this" {
  name               = var.role_name
  assume_role_policy = var.assume_role_policy_json
  tags               = var.tags
}

# Attachment for custom inline policy
resource "aws_iam_policy" "custom" {
  # This now depends on a simple boolean, which is known at plan time.
  count  = var.create_custom_policy ? 1 : 0
  name   = "${var.role_name}-CustomPolicy"
  policy = var.custom_policy_json
}

resource "aws_iam_role_policy_attachment" "custom" {
  # This also depends on the simple boolean.
  count      = var.create_custom_policy ? 1 : 0
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.custom[0].arn
}

# Attachment for AWS managed policies
resource "aws_iam_role_policy_attachment" "managed" {
  for_each   = toset(var.managed_policy_arns)
  role       = aws_iam_role.this.name
  policy_arn = each.value
}