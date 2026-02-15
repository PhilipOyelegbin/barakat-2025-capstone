output "resource_details" {
  value = {
    vpc_id               = module.network.output_details.id
    vpc_region           = module.network.output_details.vpc_region
    eks_name             = module.kubernetes.cluster_name
    eks_url              = module.kubernetes.cluster_endpoint
    eks_certificate_data = module.kubernetes.cluster_certificate_authority_data
    eks_oidc_issuer_url  = module.kubernetes.cluster_oidc_issuer_url
    node_grp_arn         = module.kubernetes.node_group_arn
    kubeconfig           = module.kubernetes.kubeconfig
    assets_bucket        = module.storage.output_details.bucket_name
  }
  description = "Values of all the resources created."
  sensitive   = true
}

# output "install_commands" {
#   value = <<-EOT
#     #!/bin/bash
#     # EKS Cluster: ${module.kubernetes.cluster_name}
#     # Region: ${var.aws_region}

#     # Configure kubectl
#     aws eks --region ${var.aws_region} update-kubeconfig --name ${module.kubernetes.cluster_name}

#     # Add Helm repos
#     helm repo add eks https://aws.github.io/eks-charts
#     helm repo add aws-containers https://aws-containers.github.io/retail-store-sample-app
#     helm repo update

#     # Install ALB Controller
#     helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
#       --namespace kube-system \
#       --set clusterName=${module.kubernetes.cluster_name} \
#       --set serviceAccount.create=true \
#       --set serviceAccount.name=aws-load-balancer-controller \
#       --set serviceAccount.annotations."eks\\.amazonaws\\.com/role-arn"=${module.kubernetes.alb_controller_role_arn} \
#       --set region=${var.aws_region} \
#       --set vpcId=${module.network.output_details.id}

#     # Install Retail Store App
#     helm install retail-store-app aws-containers/retail-store-sample-app \
#       --namespace retail-app \
#       --create-namespace

#     echo "Installation complete!"
#   EOT
# }
