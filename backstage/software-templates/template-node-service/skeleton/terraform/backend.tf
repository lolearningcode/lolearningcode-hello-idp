terraform {
  backend "s3" {
    bucket         = "backstage-tfstate-bucket"
    key            = "state/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "backstage-tf-locks"
    encrypt        = true
  }
}
