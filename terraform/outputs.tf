output "resource_details" {
  value = {
    vpc_id               = module.network.output_details.id
    vpc_region           = module.network.output_details.vpc_region
    eks_name             = module.kubernetes.cluster_name
    eks_url              = module.kubernetes.cluster_endpoint
    # eks_certificate_data = module.kubernetes.cluster_certificate_authority_data
    # eks_oidc_issuer_url  = module.kubernetes.cluster_oidc_issuer_url
    # node_grp_arn         = module.kubernetes.node_group_arn
    # kubeconfig           = module.kubernetes.kubeconfig
    assets_bucket        = module.serverless.output_details.bucket_name
  }
  description = "Values of all the resources created."
  # sensitive   = true
}
