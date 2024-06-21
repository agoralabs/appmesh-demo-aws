output "eks_cluster_name" {
  value       = module.eks.cluster_name
  description = "The EKS cluster name"
}

output "eks_cluster_id" {
  value       = module.eks.cluster_id
  description = "The EKS cluster id"
}
