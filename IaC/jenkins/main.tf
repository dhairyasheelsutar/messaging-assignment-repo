data "aws_ami" "ami" {
  most_recent = true
  owners = ["amazon"]
  filter {
    name = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

module "jenkins-sg" {
  source = "terraform-aws-modules/security-group/aws"
  name        = "jenkins-sg"
  description = "Security group for Jenkins VM"
  vpc_id      = data.terraform_remote_state.state.outputs.vpc_id
  # ingress_rules = ["ssh-tcp"]
  egress_rules = ["all-all"]
  ingress_with_cidr_blocks = [
    {
      from_port   = 8080
      to_port     = 8080
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    }
  ]




}

module "ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"

  name = "jenkins-vm"
  instance_type          = "t3.medium"
  key_name = "new-key-pair"
  iam_instance_profile = "EC2SSMRole"
  vpc_security_group_ids = [module.jenkins-sg.security_group_id, ]
  subnet_id              = data.terraform_remote_state.state.outputs.public_subnets[0]
  associate_public_ip_address = true
  user_data = file("${path.module}/install.bash")

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }

}