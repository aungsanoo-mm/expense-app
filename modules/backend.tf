terraform {
  backend "s3" {
    bucket         = "aso-my-tf-state-bucket123"
    key            = "env/dev/terraform.tfstate"
    region         = "ap-southeast-1"
    dynamodb_table = "terraform-lock"
    encrypt        = true
  }
}
