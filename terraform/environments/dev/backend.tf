terraform {
  backend "s3" {
    bucket                      = "terraform-state"
    key                         = "vm-configs/terraform.tfstate"
    region                      = "us-east-1"  # Region is required but doesn't matter for MinIO
    endpoint                    = "http://minio.local"
    force_path_style            = true
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
  }
}