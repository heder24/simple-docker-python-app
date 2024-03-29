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

resource "aws_security_group" "sg-all" {
  name        = "all_security_group"
  description = "Security group for all access" #not recommended. for testing only

  vpc_id = module.vpc.vpc_id  

  // Ingress rule for SSH traffic
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allowing traffic from anywhere (open to the world)
  }

  // Egress rule to allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]  # Allow all outbound traffic to anywhere
  }
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
  vpc_security_group_ids      = [aws_security_group.sg-all.id]
  associate_public_ip_address = true
  disable_api_stop            = false
  key_name                    = var.key_name
  iam_instance_profile        = module.base-ec2-role.iam_instance_profile_id
  create_iam_instance_profile = false
  user_data_base64            = base64encode(local.user_data)
  user_data_replace_on_change = true
  
  metadata_options = {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 8
    instance_metadata_tags      = "enabled"
  }
  tags = {
    Name = local.name
  }
}