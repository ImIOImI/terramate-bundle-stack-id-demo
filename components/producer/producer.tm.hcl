generate_hcl "_tmgen-producer.tf" {
  content {
    resource "terraform_data" "message" {
      input = "hello from the producer stack"
    }
  }
}
generate_hcl "_tmgen-sharing-outputs.tm.hcl" {
  content {
    output "message" {
      backend = "default"
      value   = terraform_data.message.output
    }
  }
}
