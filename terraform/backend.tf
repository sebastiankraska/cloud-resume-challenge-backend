terraform {
  backend "s3" {
    bucket       = "crc-terraform-state-sk"
    key          = "terraform.tfstate"
    region       = "eu-central-1"
    encrypt      = true
    use_lockfile = true
  }
}