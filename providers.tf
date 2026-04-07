terraform {
  required_version = ">= 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # Configure your remote state backend before running terraform init.
  # Run terraform init with -backend-config flags:
  #
  #   terraform init \
  #     -backend-config="bucket=your-tfstate-bucket" \
  #     -backend-config="key=databridge/terraform.tfstate" \
  #     -backend-config="region=us-east-1"
  #
  # Or uncomment and fill in the block below:
  #
  # backend "s3" {
  #   bucket = "your-tfstate-bucket"
  #   key    = "databridge/terraform.tfstate"
  #   region = "us-east-1"
  # }
}

provider "aws" {
  region = var.aws_region
}
