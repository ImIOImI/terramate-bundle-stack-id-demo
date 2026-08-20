define "bundle" "metadata" {
  class       = "pair"
  version     = "0.1.0"
  name        = "producer/consumer pair"
  description = "Two sibling stacks sharing an apply-computed output via outputs-sharing."
}

define "bundle" {
  lets {
    # WAY 1 — a deterministic guid, "created" once (name-based so it is stable
    # across `terramate generate`; tm_uuid() would churn). Used on BOTH sides.
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
      # A deterministic guid known ahead of time. Defined once in bundle.let
      # AND hand-seeded as the producer's id in stacks/producer/stack.tm.hcl —
      # the two must be kept in sync by hand (nothing links them).
      producer_stack_id = bundle.let.producer_id

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
