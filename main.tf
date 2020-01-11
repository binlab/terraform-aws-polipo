terraform {
  required_providers {
    ignition = "~> 1.2.1"
  }
}

resource "aws_instance" "polipo" {
  ami                    = var.ami_vendor == "flatcar" ? data.aws_ami.flatcar.image_id : data.aws_ami.coreos.image_id
  instance_type          = var.instance_type
  monitoring             = var.monitoring
  key_name               = var.key_name
  subnet_id              = var.vps_subnet_id
  vpc_security_group_ids = var.vps_security_group_ids
  tags                   = var.tags
  volume_tags            = var.tags

  credit_specification {
    cpu_credits = var.cpu_credits
  }

  user_data = data.ignition_config.polipo.rendered

  lifecycle {
    ignore_changes = [
      ami,
    ]
  }

  root_block_device {
    volume_size           = var.volume_size
    volume_type           = var.volume_type
    delete_on_termination = var.delete_on_termination
  }
}

data "aws_ami" "coreos" {
  most_recent = true
  owners      = ["595879546273"]

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "name"
    values = ["CoreOS-${var.ami_channel != "" ? var.ami_channel : "stable"}-*"]
  }
}

data "aws_ami" "flatcar" {
  most_recent = true
  owners      = ["075585003325"]

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "name"
    values = ["Flatcar-${var.ami_channel != "" ? var.ami_channel : "stable"}-*"]
  }
}
