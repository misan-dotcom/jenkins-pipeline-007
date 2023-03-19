terraform {
  backend "s3" {
    bucket = "misank8s-bucket"
    region = "us-east-1"
    key    = "jenkins-server/terraform.tfstate"
  }
}