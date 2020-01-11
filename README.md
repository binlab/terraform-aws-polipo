# Terraform module to running HTTP/HTTPS Proxy service based on Polipo proxy

*This proxy can help in cases when you need to obtain access to the internal network (with internal domain name resolving), wrap network of the service to predictable NAT external IP calls or just a simple proxy for general use. An instance provisioning going with AMI (`Flatcar/CoreOS`) and applying in time of start using `user_data` (JSON) provisioning by `CoreOS` Ignitions*

* __Don't use `dev`, `master` or other branches for production use. Always to fix a codebase of a module by tag version - `v1.0.0`. e.g. `git@github.com:binlab/terraform-aws-polipo.git?ref=v1.0.0`__

* __Example of use may `NOT BE` 100% working (may contain errors), designed for people with good knowledge and understanding of Terraform and showing a basic example of `HOW TO USE`__

* __Main references and documentation about input parameters should be looking for in the next links:__
  * https://www.terraform.io/docs/providers/aws/r/instance.html

## Examples:

* **Example of use Polipo proxy paired with NLB (Network Load Balancer) + TLS/SSL wrapper + Base HTTP Auth**

  ```hcl
  module "vpc" {
    source  = "terraform-aws-modules/vpc/aws"
    version = "2.21.0"
    ...
    name = "vpc"
    cidr = "10.0.0.0/16"

    public_subnets = ["10.0.10.0/24", "10.0.20.0/24", "10.0.30.0/24"]

    enable_nat_gateway   = true
    single_nat_gateway   = true
    enable_dns_hostnames = true
    enable_dns_support   = true
    ...
  }

  ### Creating Route53 External Zone

  resource "aws_route53_zone" "demo_io" {
    name         = "demo.io."
    private_zone = false

    vpc {
      vpc_id = module.vpc.vpc_id
    }
  }

  ### Creating ACM Certificate for Domain and NLB

  resource "aws_acm_certificate" "demo_io" {
    domain_name = "demo.io"

    subject_alternative_names = [
      "*.demo.io",
    ]

    validation_method = "DNS"
  }

  ### Generating random password for Polipo HTTP Auth

  resource "random_password" "polipo" {
    length  = 20
    special = false
  }

  ### Creating SSH Public/Private pair for user "core"

  resource "tls_private_key" "ssh" {
    algorithm = "RSA"
    rsa_bits  = "2048"
  }

  ### Creating CA Public/Private for signing user public SSH key

  resource "tls_private_key" "ca" {
    algorithm = "RSA"
    rsa_bits  = "2048"
  }

  ### Adding SSH Public key to AWS Console

  resource "aws_key_pair" "polipo" {
    key_name   = "polipo-key"
    public_key = tls_private_key.ssh.public_key_openssh
  }

  ### Creating EC2 Instance for Polipo Proxy Service

  module "polipo" {
    source = "git@github.com:binlab/terraform-aws-polipo.git?ref=dev"

    key_name = aws_key_pair.polipo.key_name

    proxy_port = 8123
    proxy_user = "Username"
    proxy_pass = random_password.polipo.result

    root_ssh_public_key = tls_private_key.ssh.public_key_openssh
    ca_ssh_public_key   = tls_private_key.ca.public_key_openssh

    vps_security_group_ids = [
      module.vpc.default_security_group_id,
      aws_security_group.polipo.id,
    ]

    vps_subnet_id = element(module.vpc.public_subnets, 0)
  }

  ### Creating a Security Group for accessing from outside

  resource "aws_security_group" "polipo" {
    name   = "polipo"
    vpc_id = module.vpc.vpc_id

    ingress {
      description = "Allow Public SSH Connection to Proxy Instance"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
      description = "Allow Public Clients Connection to Proxy"
      from_port   = 8123
      to_port     = 8123
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
      description = "Allow Health Check from NLB"
      from_port   = 8123
      to_port     = 8123
      protocol    = "tcp"
      cidr_blocks = [module.vpc.vpc_cidr_block]
    }
  }

  ### Creating Network Load Balancer (NLB) with ACM Certificate and TLS

  resource "aws_lb" "polipo" {
    name               = "polipo"
    internal           = false
    load_balancer_type = "network"

    dynamic "subnet_mapping" {
      for_each = module.vpc.public_subnets
      content {
        subnet_id = subnet_mapping.value
      }
    }
  }

  resource "aws_lb_listener" "polipo" {
    load_balancer_arn = aws_lb.polipo.arn
    port              = 443
    protocol          = "TLS"
    ssl_policy        = "ELBSecurityPolicy-2016-08"
    certificate_arn   = aws_acm_certificate.demo_io.arn

    default_action {
      type             = "forward"
      target_group_arn = aws_lb_target_group.polipo.arn
    }
  }

  resource "aws_lb_target_group" "polipo" {
    name     = "polipo"
    port     = 8123
    protocol = "TCP"
    vpc_id   = module.vpc.vpc_id

    health_check {
      protocol            = "TCP"
      port                = 8123
      healthy_threshold   = 3
      unhealthy_threshold = 3
    }
  }

  resource "aws_lb_target_group_attachment" "polipo" {
    target_group_arn = aws_lb_target_group.polipo.arn
    target_id        = module.polipo.id
    port             = 8123
  }

  ### Add CNAME for NLB DNS name

  resource "aws_route53_record" "polipo" {
    zone_id = aws_route53_zone.demo_io.zone_id
    name    = "polipo.demo.io"
    type    = "CNAME"
    ttl     = "300"

    records = [
      aws_lb.polipo.dns_name,
    ]
  }

  ### Debugging output of data (for testing and connection)

  resource "local_file" "ssh" {
    sensitive_content = tls_private_key.ssh.private_key_pem
    file_permission   = "0600"
    filename          = "${path.module}/.ssh_rsa"
  }

  output "public_ip" {
    value = module.polipo.public_ip
  }

  output "public_dns" {
    value = module.polipo.public_dns
  }

  output "polipo_uri" {
    value = "https://Username:${random_password.polipo.result}@polipo.demo.io:443"
  }
  ```

* After `terraform apply` output should be like this:

  ```shell
  ...
  Outputs:

  polipo_uri = https://Username:HJZyhOio6Nob4YZySyIQ@polipo.demo.io:443
  public_dns = ec2-54-xxx-xxx-123.eu-west-1.compute.amazonaws.com
  public_ip = 54.xxx.xxx.123
  ```

* To testing SSH connection to EC2 Instance you can run:

  ```shell
  $ ssh -i .ssh_rsa -p 22 core@54.xxx.xxx.123
  ```

* Final testing of Proxy work can be reached by this:

  ```shell
  $ HTTPS_PROXY=https://Username:HJZyhOio6Nob4YZySyIQ@polipo.demo.io:443 curl -v https://httpbin.org/ip
  ```
