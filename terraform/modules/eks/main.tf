#============================================ Provider ============================================#
data "aws_eks_cluster_auth" "cluster" {
  name = aws_eks_cluster.project_bedrock_cluster.name
}

provider "kubernetes" {
  host                   = aws_eks_cluster.project_bedrock_cluster.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.project_bedrock_cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks",
      "get-token",
      "--cluster-name",
      aws_eks_cluster.project_bedrock_cluster.name,
      "--region",
      "us-east-1"
    ]
  }
}

provider "helm" {
  kubernetes {
    host                   = aws_eks_cluster.project_bedrock_cluster.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.project_bedrock_cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.cluster.token

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args = [
        "eks",
        "get-token",
        "--cluster-name",
        aws_eks_cluster.project_bedrock_cluster.name,
        "--region",
        "us-east-1"
      ]
    }
  }
}

#============================================ EKS Cluster ============================================#
# EKS Cluster
resource "aws_eks_cluster" "project_bedrock_cluster" {
  name     = "project-${var.project_name}-cluster"
  role_arn = var.cluster_iam_role_arn
  version  = var.eks_version

  vpc_config {
    subnet_ids              = var.private_subnet_ids
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  enabled_cluster_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]

  tags = {
    Name    = "project-${var.project_name}-cluster"
    Project = var.project_tag
  }

  depends_on = [
    aws_cloudwatch_log_group.eks_cluster
  ]
}

# CloudWatch Log Group for EKS Cluster Logs
resource "aws_cloudwatch_log_group" "eks_cluster" {
  name              = "/aws/eks/project-${var.project_name}-cluster/cluster"
  retention_in_days = 7

  lifecycle {
    ignore_changes = [name]
  }

  tags = {
    Name    = "eks-${var.project_name}-cluster-logs"
    Project = var.project_tag
  }
}

# EKS Security Group
resource "aws_security_group" "cluster" {
  name        = "project-${var.project_name}-cluster-sg"
  description = "EKS cluster security group"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow nodes to communicate with control plane"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.private_subnet_cidrs
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "project-${var.project_name}-cluster-sg"
    Project = var.project_tag
  }
}

#============================================ Node Groups ============================================#
# EKS Managed Node Group
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.project_bedrock_cluster.name
  node_group_name = "project-${var.project_name}-node-group"
  node_role_arn   = var.node_iam_role_arn
  instance_types  = var.node_instance_types
  subnet_ids      = var.private_subnet_ids
  capacity_type   = "ON_DEMAND"

  scaling_config {
    desired_size = var.desired_size
    max_size     = var.max_size
    min_size     = var.min_size
  }

  update_config {
    max_unavailable = 1
  }

  # Labels
  labels = {
    role = "general"
  }

  # Node group tags
  tags = {
    Name    = "project-${var.project_name}-node"
    Project = var.project_tag
  }

  depends_on = [
    aws_eks_cluster.project_bedrock_cluster,
    kubernetes_config_map_v1.aws_auth
  ]
}

#============================================ EKS Addons ============================================#
# AWS Managed Addons - vpc-cni, coredns, kube-proxy
resource "aws_eks_addon" "vpc_cni" {
  cluster_name                = aws_eks_cluster.project_bedrock_cluster.name
  addon_name                  = "vpc-cni"
  resolve_conflicts_on_create = "OVERWRITE"

  depends_on = [
    aws_eks_node_group.main,
  ]
}

resource "aws_eks_addon" "coredns" {
  cluster_name                = aws_eks_cluster.project_bedrock_cluster.name
  addon_name                  = "coredns"
  resolve_conflicts_on_create = "OVERWRITE"

  depends_on = [
    aws_eks_addon.vpc_cni,
  ]
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name                = aws_eks_cluster.project_bedrock_cluster.name
  addon_name                  = "kube-proxy"
  resolve_conflicts_on_create = "OVERWRITE"

  depends_on = [
    aws_eks_addon.coredns,
  ]
}

# CloudWatch Observability Addon
resource "aws_eks_addon" "cloudwatch_observability" {
  cluster_name                = aws_eks_cluster.project_bedrock_cluster.name
  addon_name                  = "amazon-cloudwatch-observability"
  service_account_role_arn    = aws_iam_role.cloudwatch_observability_role.arn
  resolve_conflicts_on_create = "OVERWRITE"

  depends_on = [
    aws_iam_role.cloudwatch_observability_role,
    aws_eks_cluster.project_bedrock_cluster,
    aws_eks_addon.kube_proxy,
  ]
}

#============================================ Kubernetes Resources ============================================#
# AWS Auth ConfigMap
resource "kubernetes_config_map_v1" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = yamlencode([
      {
        rolearn  = var.node_iam_role_arn
        username = "system:node:{{EC2PrivateDNSName}}"
        groups = [
          "system:bootstrappers",
          "system:nodes",
        ]
      },
      {
        rolearn  = var.terraform_role_arn
        username = "automation"
        groups   = ["system:masters"]
      }
    ])
  }

  depends_on = [
    aws_eks_cluster.project_bedrock_cluster,
  ]
}

# Create retail-app namespace
resource "kubernetes_namespace_v1" "retail_app" {
  metadata {
    name = "retail-app"
    labels = {
      name    = "retail-app"
      project = var.project_tag
    }
  }

  depends_on = [kubernetes_config_map_v1.aws_auth]
}

# Create RBAC for developer user
resource "kubernetes_cluster_role_binding_v1" "developer_view_access" {
  metadata {
    name = "bedrock-dev-view-binding"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "view"
  }

  subject {
    kind      = "User"
    name      = "bedrock-dev-view"
    api_group = "rbac.authorization.k8s.io"
  }

  depends_on = [kubernetes_config_map_v1.aws_auth]
}

# ============================================ OIDC ============================================
data "tls_certificate" "oidc" {
  url = aws_eks_cluster.project_bedrock_cluster.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  url = aws_eks_cluster.project_bedrock_cluster.identity[0].oidc[0].issuer

  client_id_list = ["sts.amazonaws.com"]

  thumbprint_list = [
    data.tls_certificate.oidc.certificates[0].sha1_fingerprint
  ]

  tags = {
    Name    = "project-${var.project_name}-oidc-provider"
    Project = var.project_tag
  }
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

resource "aws_iam_role" "cloudwatch_observability_role" {
  name = "project-${var.project_name}-cloudwatch-observability-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.eks.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(aws_eks_cluster.project_bedrock_cluster.identity[0].oidc[0].issuer, "https://", "")}:sub" = "system:serviceaccount:amazon-cloudwatch:cloudwatch-agent"
          }
        }
      }
    ]
  })
}

# Attach to node role
resource "aws_iam_role_policy_attachment" "cloudwatch_observability_policy_attachment" {
  role       = aws_iam_role.cloudwatch_observability_role.name
  policy_arn = aws_iam_policy.cloudwatch_observability_policy.arn
}

#============================================ LB Controller IAM Role ============================================
resource "aws_iam_policy" "aws_load_balancer_controller" {
  name        = "${var.project_name}-alb-controller-policy"
  description = "IAM policy for AWS Load Balancer Controller"
  path        = "/"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "iam:CreateServiceLinkedRole"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "iam:AWSServiceName" = "elasticloadbalancing.amazonaws.com"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeAccountAttributes",
          "ec2:DescribeAddresses",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeInternetGateways",
          "ec2:DescribeVpcs",
          "ec2:DescribeVpcPeeringConnections",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeInstances",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeTags",
          "ec2:GetCoipPoolUsage",
          "ec2:DescribeCoipPools",
          "elasticloadbalancing:DescribeLoadBalancers",
          "elasticloadbalancing:DescribeLoadBalancerAttributes",
          "elasticloadbalancing:DescribeListeners",
          "elasticloadbalancing:DescribeListenerCertificates",
          "elasticloadbalancing:DescribeSSLPolicies",
          "elasticloadbalancing:DescribeRules",
          "elasticloadbalancing:DescribeTargetGroups",
          "elasticloadbalancing:DescribeTargetGroupAttributes",
          "elasticloadbalancing:DescribeTargetHealth",
          "elasticloadbalancing:DescribeTags"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "cognito-idp:DescribeUserPoolClient",
          "acm:ListCertificates",
          "acm:DescribeCertificate",
          "iam:ListServerCertificates",
          "iam:GetServerCertificate",
          "waf-regional:GetWebACL",
          "waf-regional:GetWebACLForResource",
          "waf-regional:AssociateWebACL",
          "waf-regional:DisassociateWebACL",
          "wafv2:GetWebACL",
          "wafv2:GetWebACLForResource",
          "wafv2:AssociateWebACL",
          "wafv2:DisassociateWebACL",
          "shield:GetSubscriptionState",
          "shield:DescribeProtection",
          "shield:CreateProtection",
          "shield:DeleteProtection"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:DeleteSecurityGroup"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateSecurityGroup"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateTags",
          "ec2:DeleteTags"
        ]
        Resource = "arn:aws:ec2:*:*:security-group/*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:AuthorizeSecurityGroupEgress"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:RevokeSecurityGroupEgress"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:CreateLoadBalancer",
          "elasticloadbalancing:CreateTargetGroup"
        ]
        Resource = "*"
        Condition = {
          Null = {
            "aws:RequestTag/elbv2.k8s.aws/cluster" = "false"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:CreateListener",
          "elasticloadbalancing:DeleteListener",
          "elasticloadbalancing:CreateRule",
          "elasticloadbalancing:DeleteRule"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:AddTags",
          "elasticloadbalancing:RemoveTags"
        ]
        Resource = [
          "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*",
          "arn:aws:elasticloadbalancing:*:*:loadbalancer/net/*/*",
          "arn:aws:elasticloadbalancing:*:*:loadbalancer/app/*/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:ModifyLoadBalancerAttributes",
          "elasticloadbalancing:SetIpAddressType",
          "elasticloadbalancing:SetSecurityGroups",
          "elasticloadbalancing:SetSubnets",
          "elasticloadbalancing:DeleteLoadBalancer",
          "elasticloadbalancing:ModifyTargetGroup",
          "elasticloadbalancing:ModifyTargetGroupAttributes",
          "elasticloadbalancing:DeleteTargetGroup"
        ]
        Resource = "*"
        Condition = {
          Null = {
            "aws:RequestTag/elbv2.k8s.aws/cluster" = "false"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:RegisterTargets",
          "elasticloadbalancing:DeregisterTargets"
        ]
        Resource = "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*"
      },
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:SetWebAcl",
          "elasticloadbalancing:SetSecurityGroups",
          "elasticloadbalancing:SetSubnets",
          "elasticloadbalancing:SetIpAddressType"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Project = var.project_tag
  }
}

# Create the IAM role with a trust policy for the OIDC provider
resource "aws_iam_role" "aws_load_balancer_controller" {
  name = "${var.project_name}-alb-controller-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.eks.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${aws_eks_cluster.project_bedrock_cluster.identity[0].oidc[0].issuer}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
          }
        }
      }
    ]
  })

  tags = {
    Project = var.project_tag
  }
}

# Attach the policy to the role
resource "aws_iam_role_policy_attachment" "aws_load_balancer_controller" {
  role       = aws_iam_role.aws_load_balancer_controller.name
  policy_arn = aws_iam_policy.aws_load_balancer_controller.arn
}
