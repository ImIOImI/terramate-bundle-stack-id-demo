define "component" "metadata" {
  class   = "components/consumer"
  version = "0.1.0"
  name    = "consumer"
}
define "component" {
  input "producer_stack_id" {
    type        = string
    description = "the producer stack's id (from_stack_id for outputs-sharing)"
  }
}
