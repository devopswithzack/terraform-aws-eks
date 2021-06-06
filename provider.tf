terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
  required_version = "~>0.14"
}

provider "aws" {
  region = var.region
  #shared_credentials_file = ""
  profile                 = "dev-account" #change as per yours

}