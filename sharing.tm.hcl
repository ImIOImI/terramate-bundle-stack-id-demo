sharing_backend "default" {
  type     = terraform
  filename = "_tmgen-sharing.tf"
  command  = ["tofu", "output", "-json"]
}
