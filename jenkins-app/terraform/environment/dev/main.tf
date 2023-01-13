module "main" {
  source                  = "../../modules/main"
  environment             = "dev"
  force_delete_repository = true
  image_tag_mutability    = "MUTABLE"
}
