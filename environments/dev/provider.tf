# environments/dev/providers.tf

terraform {
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }

    
  }
}

provider "aws" {
  region =  "us-east-1"
}

# Add this block for the random provider
provider "random" {}