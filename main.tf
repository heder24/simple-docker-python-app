################################################################################
# VPC Module
################################################################################

module "vpc" {
  source  = "app.terraform.io/heder24/vpc/aws"
  version = "1.0.0"

  name = local.name
  cidr = local.vpc_cidr

  azs             = local.azs
  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 4)]


  private_subnet_names = ["Private Subnet One", "Private Subnet Two"]
  # public_subnet_names omitted to show default name generation for all three subnets
  database_subnet_names    = ["DB Subnet One"]
  elasticache_subnet_names = ["Elasticache Subnet One", "Elasticache Subnet Two"]
  redshift_subnet_names    = ["Redshift Subnet One", "Redshift Subnet Two", "Redshift Subnet Three"]
  intra_subnet_names       = []

  create_database_subnet_group  = false
  manage_default_network_acl    = false
  manage_default_route_table    = false
  manage_default_security_group = false

  enable_dns_hostnames = true
  enable_dns_support   = true

  enable_nat_gateway = true
  single_nat_gateway = true


  # VPC Flow Logs (Cloudwatch log group and IAM role will be created)
  enable_flow_log                      = true
  create_flow_log_cloudwatch_log_group = true
  create_flow_log_cloudwatch_iam_role  = true
  flow_log_max_aggregation_interval    = 60

  tags = local.tags
}

################################################################################
# Security groups modules
################################################################################

module "public_sg" {
  source  = "app.terraform.io/heder24/public-security-groups/aws"
  version = "1.0.0"

  name   = var.public_sg
  vpc_id = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      description = "Allow HTTP from public IPV4"
      from_port   = 80
      to_port     = 80
      protocol    = 6
      cidr_blocks = "0.0.0.0/0"

    },

  ]

  ingress_with_ipv6_cidr_blocks = [

    {
      description      = "HTTP from public IPV6"
      from_port        = 80
      to_port          = 80
      protocol         = 6
      ipv6_cidr_blocks = "::/0"
    },

  ]
 egress_with_cidr_blocks = [
    {
      description = "HTTP to anywhere IPV4"
      from_port   = 80
      to_port     = 80
      protocol    = 6
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  egress_with_ipv6_cidr_blocks = [
    {
      description      = "HTTP to anywhere IPV4"
      from_port        = 80
      to_port          = 80
      protocol         = 6
      ipv6_cidr_blocks = "::/0"
    }
  ]

}


################################################################################
# IAM Module
################################################################################

module "base-ec2-role" {
  source  = "app.terraform.io/heder24/iam/aws"
  version = "1.0.0"

  trusted_role_services = [
    "ec2.amazonaws.com"
  ]

  create_role             = true
  create_instance_profile = true

  role_name         = var.base-role
  role_requires_mfa = false

  custom_role_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonS3FullAccess",
    "arn:aws:iam::aws:policy/AmazonSSMFullAccess",

  ]
}

################################################################################
# EC2 Module
################################################################################

module "prod-python-web" {
  source  = "app.terraform.io/heder24/ec2/aws"
  version = "1.0.0"

  name                        = "${local.name}-web"
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro" # used to set core count below
  availability_zone           = element(module.vpc.azs, 0)
  subnet_id                   = element(module.vpc.public_subnets, 0)
  vpc_security_group_ids      = [module.public_sg.security_group_id]
  associate_public_ip_address = true
  disable_api_stop            = false
  key_name                    = var.key_name
  iam_instance_profile        = module.base-ec2-role.iam_instance_profile_id
  create_iam_instance_profile = false
  user_data_base64            = base64encode(local.user_data)
  user_data_replace_on_change = true
  tags = {
    Name = local.name
  }
}