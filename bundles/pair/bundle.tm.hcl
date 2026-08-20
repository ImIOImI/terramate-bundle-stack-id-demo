define "bundle" "metadata" {
  class       = "pair"
  version     = "0.1.0"
  name        = "producer/consumer pair"
  description = "Two sibling stacks sharing an apply-computed output via outputs-sharing."
}

define "bundle" {
  scaffolding {
    path = "/_scaffold-pair.tm.yml"
    name = "pair"
  }
}

define bundle stack "producer" {
  metadata {
    path = "/stacks/producer"
    name = "producer"
  }
  component "producer" {
    source = "/components/producer"
  }
}

define bundle stack "consumer" {
  metadata {
    path  = "/stacks/consumer"
    name  = "consumer"
    after = ["/stacks/producer"]
  }
  component "consumer" {
    source = "/components/consumer"
    inputs {
      # The consumer must name the producer's stack id as a STATIC LITERAL for
      # outputs-sharing's from_stack_id. The bundle cannot read or set the
      # producer's id, so this literal must be kept in sync BY HAND with the
      # pre-seeded stacks/producer/stack.tm.hcl. THIS is what the FR removes.
      producer_stack_id = "producer"
    }
  }
}
