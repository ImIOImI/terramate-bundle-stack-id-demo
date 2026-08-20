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
      # ── WAY 1 (works today) ─────────────────────────────────────────────
      # The producer's stack id is a guid you create ahead of time and write as
      # the producer's stack metadata (stacks/producer/stack.tm.hcl -> id = ...).
      # You then repeat that SAME literal here for from_stack_id. Two hand-written
      # copies of one guid; nothing links them, so drift silently mis-wires.
      producer_stack_id = "2e2ea0f7-596a-57d6-b233-6deecf9941d5"

      # ── WAY 2 (proposed; errors on Terramate 0.17.1) ────────────────────
      # Lazily read the sibling stack's id — no guid, no out-of-band seed; the
      # bundle resolves the producer stack's id at generate time:
      #
      #   producer_stack_id = bundle.pair.meta.id
      #
      # Today that fails with:
      #   partial evaluation failed: eval expression:
      #   This object does not have an attribute named "pair".
      # (also tried: bundle.stacks.producer.metadata.id -> named "stacks";
      #              bundle.producer.metadata.id         -> named "producer")
    }
  }
}
