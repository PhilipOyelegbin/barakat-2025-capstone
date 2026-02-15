#============================================ EKS Cluster IAM Role ============================================#
# IAM role for EKS Cluster
resource "aws_iam_role" "eks_cluster_role" {
  name        = "project-${var.project_name}-cluster-role"
  description = "IAM role for EKS cluster to manage AWS resources"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name    = "project-${var.project_name}-cluster-role"
    Project = var.project_tag
  }
}

# Attach required AWS managed policies for EKS Cluster
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# Attach VPC Resource Controller policy (required for networking)
resource "aws_iam_role_policy_attachment" "eks_vpc_resource_controller" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
}

#============================================ EKS Node Group IAM Role ============================================#
# IAM role for EKS Node Groups
resource "aws_iam_role" "eks_node_group_role" {
  name        = "project-${var.project_name}-node-group-role"
  description = "IAM role for EKS node groups to manage AWS resources"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name    = "project-${var.project_name}-node-group-role"
    Project = var.project_tag
  }
}

# Attach required AWS managed policies for EKS Node Groups
resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  role       = aws_iam_role.eks_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  role       = aws_iam_role.eks_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "ecr_read_only_policy" {
  role       = aws_iam_role.eks_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

#============================================ Developer IAM User (REQUIRED) ============================================#
# Developer IAM User - MUST be named exactly: bedrock-dev-view
resource "aws_iam_user" "bedrock_dev_view" {
  name = "${var.project_name}-dev-view"
  path = "/"

  tags = {
    Name    = "${var.project_name}-dev-view"
    Project = var.project_tag
  }
}

resource "aws_iam_user_login_profile" "console_access" {
  user                    = aws_iam_user.bedrock_dev_view.name
  password_reset_required = false
}

# Attach ReadOnlyAccess policy as required
resource "aws_iam_user_policy_attachment" "readonly_access" {
  user       = aws_iam_user.bedrock_dev_view.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# Create Access Key for grading
resource "aws_iam_access_key" "bedrock_dev_view_key" {
  user = aws_iam_user.bedrock_dev_view.name
}

# Create a policy for specific S3 bucket access
resource "aws_iam_user_policy" "s3_bucket_access" {
  name = "bedrock-dev-view-s3-access"
  user = aws_iam_user.bedrock_dev_view.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::bedrock-assets-*",
          "arn:aws:s3:::bedrock-assets-*/*"
        ]
      }
    ]
  })
}

# Save credentials to file
resource "local_sensitive_file" "iam_credentials" {
  filename = "${path.root}/bedrock-dev-credentials.txt"
  content  = <<EOT
  IAM_Console_URL: https://console.aws.amazon.com/iam/home?region=${var.region}#/users/${aws_iam_user.bedrock_dev_view.name}
  IAM_User: ${aws_iam_user.bedrock_dev_view.name}
  IAM_Password: ${aws_iam_user_login_profile.console_access.password}
  AWS_ACCESS_KEY_ID=${aws_iam_access_key.bedrock_dev_view_key.id}
  AWS_SECRET_ACCESS_KEY=${aws_iam_access_key.bedrock_dev_view_key.secret}
  EOT
}

#============================================ Lambda IAM Role ============================================
# IAM role for Lambda function
resource "aws_iam_role" "lambda_exec_role" {
  name = "${var.project_name}-asset-processor-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Attach basic execution policy to Lambda role
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
