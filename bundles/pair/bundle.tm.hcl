define "bundle" "metadata" {
  class       = "pair"
  version     = "0.1.0"
  name        = "producer/consumer pair"
  description = "Two sibling stacks sharing an apply-computed output via outputs-sharing."
}

define "bundle" {
  # THE ID, minted once, in one place. (Your `let { id = guid() }`; the real
  # spellings are `lets {}` + tm_uuidv5 — deterministic, so it doesn't churn.)
  lets {
    producer_id = tm_uuidv5("dns", "producer") # == 2e2ea0f7-596a-57d6-b233-6deecf9941d5
  }

  scaffolding {
    path = "/_scaffold-pair.tm.yml"
    name = "pair"
  }
}

define bundle stack "producer" {
  metadata {
    path = "/stacks/producer"
    name = "producer"

    # ── THE ASK (way 1) ────────────────────────────────────────────────────
    # Set the producer's stack id straight from the bundle let:
    #
    #   id = bundle.let.producer_id
    #
    # Errors on Terramate 0.17.1:
    #   terramate schema error: unrecognized
    #   "define.bundle.stack.<label>.metadata" attribute: valid attributes are
    #   [after, before, description, name, path, tags, wanted_by, wants, watch]
    #   but found "id"
    #
    # Until that exists, the id can't be pushed onto the stack from the bundle,
    # so it is hand-seeded in stacks/producer/stack.tm.hcl to equal
    # bundle.let.producer_id. That hand-seed is the ONLY workaround this repo
    # needs — everything below already works.
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
      # The consumer reuses the SAME bundle let — one source of truth. This part
      # already works today; from_stack_id resolves to bundle.let.producer_id.
      producer_stack_id = bundle.let.producer_id

      # WAY 2 (proposed): skip the shared let entirely and lazily read the
      # producer's own stack id from the consumer —
      #   producer_stack_id = bundle.pair.meta.id
      # errors today: This object does not have an attribute named "pair".
    }
  }
}
