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

#============================================ Custom Least-Privilege Policies for Node Groups ============================================#
# CloudWatch policy for observability addon
resource "aws_iam_policy" "cloudwatch_observability_policy" {
  name        = "project-${var.project_name}-cloudwatch-observability-policy"
  description = "Policy for CloudWatch Observability addon"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:PutRetentionPolicy"
        ]
        Resource = [
          "arn:aws:logs:*:*:log-group:/aws/eks/project-${var.project_name}-cluster/*",
          "arn:aws:logs:*:*:log-group:/aws/containerinsights/project-${var.project_name}-cluster/*",
          "arn:aws:logs:*:*:log-group:*:*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData",
          "cloudwatch:GetMetricData",
          "cloudwatch:ListMetrics"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name    = "project-bedrock-cloudwatch-observability-policy"
    Project = "barakat-2025-capstone"
  }
}

# Attach to node role
resource "aws_iam_role_policy_attachment" "cloudwatch_observability_policy_attachment" {
  role       = aws_iam_role.eks_node_group_role.name
  policy_arn = aws_iam_policy.cloudwatch_observability_policy.arn
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

# Attach ReadOnlyAccess policy as required
resource "aws_iam_user_policy_attachment" "readonly_access" {
  user       = aws_iam_user.bedrock_dev_view.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# Create Access Key for grading - THIS IS REQUIRED FOR DELIVERABLES
resource "aws_iam_access_key" "bedrock_dev_view_key" {
  user = aws_iam_user.bedrock_dev_view.name
}

# Optional: Create a policy for specific S3 bucket access (for bonus section)
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
