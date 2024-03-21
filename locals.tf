locals {
  name   = "pro-python-app" #"ex-${basename(path.cwd)}"
  region = "eu-east-2"

  vpc_cidr = "10.20.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)

  tags = {
    Name       = local.name
  }
  user_data                 = <<-EOT
    #!/bin/bash
    sudo yum update -y
    sudo yum install docker -y
    sudo service docker start
    sudo docker run -d -p 80:3000 bkimminich/juice-shop
    
  EOT
}

