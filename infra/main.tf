provider "aws" {
    region = "eu-central-1"
    access_key = "ACCESS_KEY"
    secret_key = "SECRET_KEY"
}

resource "aws_vpc" "asimov-vpc" {
    cidr_block = "10.0.0.0/16"
    tags       = {
        Name = "Asimov VPC"
    }
}

resource "aws_internet_gateway" "asimov-igw" {
    vpc_id = aws_vpc.asimov-vpc.id
    tags       = {
        Name = "Asimov IGW"
    }
}

resource "aws_subnet" "asimov-pub-subnet" {
    vpc_id                  = aws_vpc.asimov-vpc.id
    cidr_block              = "10.0.1.0/24"
    tags       = {
        Name = "Asimov Public Subnet"
    }
    availability_zone = "eu-central-1a"
}

resource "aws_route_table" "asimov-public-route-table" {
    vpc_id = aws_vpc.asimov-vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.asimov-igw.id
    }

    tags       = {
        Name = "Asimov Public Route Table"
    }
}

resource "aws_route_table_association" "asimov-route-table-association" {
    subnet_id      = aws_subnet.asimov-pub-subnet.id
    route_table_id = aws_route_table.asimov-public-route-table.id
}

resource "aws_security_group" "asimov-sg" {
    vpc_id      = aws_vpc.asimov-vpc.id

    ingress {
        from_port       = 80
        to_port         = 80
        protocol        = "tcp"
        cidr_blocks     = ["0.0.0.0/0"]
    }

    ingress {
        from_port       = 22
        to_port         = 22
        protocol        = "tcp"
        cidr_blocks     = ["0.0.0.0/0"]
    }

    # for ECR image pull
    ingress {
        from_port       = 443
        to_port         = 443
        protocol        = "tcp"
        cidr_blocks     = ["0.0.0.0/0"] # TODO: Allow requests from only private subnet
    }

    egress {
        from_port       = 0
        to_port         = 0
        protocol        = "-1"
        cidr_blocks     = ["0.0.0.0/0"]
    }

    tags = {
      Name = "Asimov SG"
    }
}

# IAM role for instances in ASG to register
data "aws_iam_policy_document" "ecs_agent" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_agent" {
  name               = "ecs-agent"
  assume_role_policy = data.aws_iam_policy_document.ecs_agent.json
}


resource "aws_iam_role_policy_attachment" "ecs_agent" {
  depends_on = [aws_iam_role.ecs_agent]
  role       = aws_iam_role.ecs_agent.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ecs_agent" {
  depends_on = [aws_iam_role.ecs_agent]
  name = "ecs-agent"
  role = aws_iam_role.ecs_agent.name
}
##########################################


resource "aws_launch_configuration" "ecs_launch_config" {
    image_id             = "ami-089a2199aac0b0147" # Amazon ECS-Optimized Amazon Linux 2 (AL2) x86_64 AMI
    iam_instance_profile = aws_iam_instance_profile.ecs_agent.name
    security_groups      = [aws_security_group.asimov-sg.id]
    user_data            = "#!/bin/bash\necho ECS_CLUSTER=asimov-cluster >> /etc/ecs/ecs.config"
    instance_type        = "t2.micro"
    associate_public_ip_address = true
    key_name = "asimov-kp"
}

resource "aws_autoscaling_group" "failure_analysis_ecs_asg" {
    name                      = "asg"
    vpc_zone_identifier       = [aws_subnet.asimov-pub-subnet.id]
    launch_configuration      = aws_launch_configuration.ecs_launch_config.name

    desired_capacity          = 1
    min_size                  = 1
    max_size                  = 2
    health_check_grace_period = 300
    health_check_type         = "EC2"
}


# ECS Cluster
resource "aws_ecs_cluster" "ecs_cluster" {
    name  = "asimov-cluster"
}

resource "aws_ecs_cluster_capacity_providers" "asimov-cluster-capacity-providers" {
  cluster_name = aws_ecs_cluster.ecs_cluster.name

  capacity_providers = [aws_ecs_capacity_provider.asimov-capacity-provider.name]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = aws_ecs_capacity_provider.asimov-capacity-provider.name
  }
}

resource "aws_ecs_capacity_provider" "asimov-capacity-provider" {
  name = "asimov-capacity-provider"

  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.failure_analysis_ecs_asg.arn
  }
}

##########################################

resource "aws_ecr_repository" "asimov-ecr-repository" {
  name                 = "asimov-ecr-repository"
  image_tag_mutability = "IMMUTABLE"
  tags = {
    Name = "Asimov ECR Repository"
  }
}
