environment = "dev"

cluster_version = "1.33"

vpc_cidr = "10.0.0.0/16"

availability_zones = [
  "us-east-1a",
  "us-east-1b"
]

private_subnet_cidrs = [
  "10.0.1.0/24",
  "10.0.2.0/24"
]

public_subnet_cidrs = [
  "10.0.101.0/24",
  "10.0.102.0/24"
]

node_groups = {
  default = {
    instance_types = ["t3.medium"]
    capacity_type  = "ON_DEMAND"

    scaling_config = {
      desired_size = 3      
      min_size     = 2
      max_size     = 4
    }
  }
}
