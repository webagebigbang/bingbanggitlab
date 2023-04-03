# Configure the AWS provider
provider "aws" {
  region = "us-east-1"
}

# Define the instance ID of the existing EC2 instance
variable "instance_id" {
  default = "i-0123456789abcdefg"
}

# Define the size of the EBS volume to attach (in GB)
variable "volume_size" {
  default = 10
}

# Define the device name for the EBS volume
variable "device_name" {
  default = "/dev/sdf"
}

# Create an EBS volume to attach
resource "aws_ebs_volume" "example" {
  availability_zone = "us-east-1a"
  size              = var.volume_size
  type              = "gp2"
}

# Attach the EBS volume to the EC2 instance
resource "aws_volume_attachment" "example" {
  device_name = var.device_name
  volume_id   = aws_ebs_volume.example.id
  instance_id = var.instance_id
}
