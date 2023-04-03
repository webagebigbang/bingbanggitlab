# Configure the AWS provider
provider "aws" {
  region = "us-east-1"
}

# Create a VPC
resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"
}

# Create an internet gateway
resource "aws_internet_gateway" "example" {
  vpc_id = aws_vpc.example.id
}

# Attach the internet gateway to the VPC
resource "aws_vpc_attachment" "example" {
  vpc_id             = aws_vpc.example.id
  internet_gateway_id = aws_internet_gateway.example.id
}

# Create a public subnet
resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.example.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
}

# Create a security group for the EC2 instance
resource "aws_security_group" "instance" {
  name_prefix = "example-instance-"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create the EC2 instance
resource "aws_instance" "example" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  key_name      = "my-key"
  subnet_id     = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.instance.id]

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("~/.ssh/id_rsa")
    host        = self.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update"
    ]
  }
}


# Define the existing VPC and public subnet
data "aws_vpc" "existing" {
  id = "aws_vpc.example.id"
}

data "aws_subnet_ids" "public" {
  vpc_id = data.aws_vpc.existing.id

  filter {
    name   = "tag:Name"
    values = ["public-subnet"]
  }
}

# Create a PostgreSQL RDS instance
resource "aws_db_instance" "postgresql" {
  identifier                = "example-postgresql"
  engine                    = "postgres"
  instance_class            = "db.t2.micro"
  allocated_storage         = 20
  publicly_accessible       = true
  storage_type              = "gp2"
  storage_encrypted         = true
  db_subnet_group_name      = "example-subnet-group"
  vpc_security_group_ids    = ["sg-0123456789abcdefg"]
  parameter_group_name      = "example-postgresql-parameters"
  deletion_protection       = false
  skip_final_snapshot       = true
  allow_major_version_upgrade = true

  # Set the username and password for the master user
  master_username = "example"
  master_password = "examplepassword"

  # Set the name of the database to create
  name = "exampledb"
}

# Create a subnet group for the RDS instance
resource "aws_db_subnet_group" "postgresql" {
  name       = "example-subnet-group"
  subnet_ids = data.aws_subnet_ids.public.ids
}

# Create a security group for the RDS instance
resource "aws_security_group" "postgresql" {
  name_prefix = "example-postgresql-"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Add an ingress rule to allow traffic to the RDS instance
resource "aws_security_group_rule" "postgresql_ingress" {
  security_group_id = aws_security_group.postgresql.id

  type        = "ingress"
  from_port   = 5432
  to_port     = 5432
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}


# attach a volume


