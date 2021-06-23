module "sg-app" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.0.0"

  name   = "Allow LB connection to the app - ${var.environment}"
  vpc_id = data.terraform_remote_state.infra.outputs.vpc_id
  create = true

  ingress_with_cidr_blocks = [
    {
      from_port       = var.host_port
      to_port         = var.host_port
      protocol        = "tcp"
      description     = "Container Host Port"
      cidr_blocks     = "0.0.0.0/0"
      security_groups = data.terraform_remote_state.infra.outputs.http_sg_id
    }
  ]

  egress_rules       = ["all-all", ]
  egress_cidr_blocks = ["0.0.0.0/0", ]
}
