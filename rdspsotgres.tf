# Configure the AWS provider
provider "aws" {
  region = "us-east-1"
}

# Define the existing VPC and public subnet
data "aws_vpc" "existing" {
  id = "vpc-0123456789abcdefg"
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
