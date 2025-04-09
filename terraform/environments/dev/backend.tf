terraform {
  backend "s3" {
    bucket                      = "terraform-state"
    key                         = "vm-configs/terraform.tfstate"
    region                      = "us-east-1"  # Region is required but doesn't matter for MinIO

    # Use the updated endpoints parameter
    endpoints = {
      s3 = "http://minio.local"
    }

    # Authentication - not defined here, passed via environment variables
    # AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY

    # Required settings for MinIO
    force_path_style            = true
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true  # Added this setting
  }
}