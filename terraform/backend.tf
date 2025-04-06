terraform {
  backend "s3" {
    bucket                      = "terraform-state"
    key                         = "monad/terraform.tfstate"
    region                      = "us-east-1"  # Required but can be any value for MinIO
    endpoint                    = "http://localhost:9000"  # MinIO endpoint via port-forwarding
    force_path_style            = true
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
  }
}
