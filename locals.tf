locals {
  name   = "pro-python-app" #"ex-${basename(path.cwd)}"
  region = "eu-east-2"

  vpc_cidr = "10.20.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)

  tags = {
    Name       = local.name
  }
  user_data                 = <<-EOT
    #!/bin/bash

    # Update package lists and install Docker
    sudo apt-get update -y
    sudo apt-get install -y docker.io

    # Pull the simple python Docker image
    sudo docker pull heder24/simple-python

    # Run the Juice Shop container
    sudo docker run  -p 80:8000 heder24/simple-python
        
  EOT
}

