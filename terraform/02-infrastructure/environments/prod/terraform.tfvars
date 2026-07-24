environment = "prod"

cluster_name = "otel-demo-prod"

node_groups = {
  default = {
    instance_types = ["m7i.large"]
    capacity_type  = "ON_DEMAND"

    scaling_config = {
      desired_size = 3
      max_size     = 10
      min_size     = 3
    }
  }
}
