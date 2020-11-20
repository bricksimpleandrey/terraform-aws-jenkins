# If you want to make more than one Jenkins, this env_name is all that needs to change
variable "env_name" {
  description = "The name of the environment and resource namespacing."
  default = "TestJenkins01"
}

# Where to place Jenkins
variable "region" {
  description = "The target AWS region"
  default = "us-east-1"
}

# An s3 prefix (Your unique stack name)
variable "s3prefix" {
  description = "A unique s3 prefix to add for our bucket names"
  default="brick-new"
}

# This is the root ssh key used for the ec2 instance
variable "ssh_key_name" {
  description = "The name of the preloaded root ssh key used to access AWS resources."
  default = "root-ssh-key-us-east-1"
}

# Your best bet to find how many AZs there are is this list https://aws.amazon.com/about-aws/global-infrastructure/
# Assume it starts with "a" times how many AZs are available
variable "availability_zones" {
  description = "List of availability zones"
}

# The instance size we will use for Jenkins (I recommend large or higher for prod)
variable "instance_type" {
  description = "AWS instance type for Jenkins"
  # original instance type was t2.medium changed to cut cost
  default = "t2.micro"
}

// Using Ubuntu 16.04
variable "aws_amis" {
  type = "map"
  default = {
    "us-east-1" = "ami-0739f8cdb239fe9ae"
  }
}
