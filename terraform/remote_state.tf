terraform {
  backend "s3" {
    bucket         = "colearn-tf"
    key            = "app/production/terraform.tfstate"
    region         = "us-west-1"
    dynamodb_table = "terraform-lock"
  }
}

data "terraform_remote_state" "infra" {
  backend = "s3"

  config = {
    bucket         = "colearn-tf"
    key            = "infra/production/terraform.tfstate"
    region         = "us-west-1"
    dynamodb_table = "terraform-lock"
  }
}

