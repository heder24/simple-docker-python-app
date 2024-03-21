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

    # Uninstall unofficial versions of Docker and related packages
    for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do 
        sudo apt remove $pkg -y
    done

    # Update package lists
    sudo apt-get update -y

    # Install necessary tools for adding Docker's Apt repository
    sudo apt-get install ca-certificates curl gnupg -y

    # Add Docker's official GPG key
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg 

    # Add Docker's repository to Apt sources
    echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo $VERSION_CODENAME) stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Update package lists again to include Docker's repository
    sudo apt-get update -y

    # Install Docker packages
    sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

    # Start and enable Docker service
    sudo service docker start
    sudo service docker enable

    # Add user 'cyber' to the 'docker' group to allow Docker commands without sudo
    sudo usermod -a -G docker cyber

    # Update Docker socket permissions
    sudo chmod 666 /var/run/docker.sock

    # Pull and run simple-python-app container
    docker pull heder24/simple-python
    docker run -d -p 80:8000 heder24/simple-python
    
  EOT
}

