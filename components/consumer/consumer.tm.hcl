generate_hcl "_tmgen-sharing-inputs.tm.hcl" {
  content {
    input "message" {
      backend       = "default"
      from_stack_id = component.input.producer_stack_id.value
      value         = outputs.message.value
      mock          = "(producer not applied yet)"
    }
  }
}
generate_hcl "_tmgen-consumer.tf" {
  content {
    output "received" {
      value = var.message
    }
  }
}
