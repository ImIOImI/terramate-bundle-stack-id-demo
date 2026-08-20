# LAZY bundle — let terramate mint the producer's (random) id, read it lazily.
#
# No bundle let: the producer's stack.tm.hcl is unseeded, so terramate mints a
# random UUID for it (the "random id, created at build time, in stack metadata").
# The consumer then wants to READ that sibling's id — which has no handle today.
define "bundle" "metadata" {
  class       = "lazy"
  version     = "0.1.0"
  name        = "lazy"
  description = "Producer id is terramate-minted; consumer reads it lazily from the sibling's metadata."
}

define "bundle" {
  scaffolding {
    path = "/_scaffold-lazy.tm.yml"
    name = "lazy"
  }
}

define bundle stack "producer" {
  metadata {
    path = "/stacks/lazy/producer"
    name = "producer"
  }
  component "producer" {
    source = "/components/producer"
  }
}

define bundle stack "consumer" {
  metadata {
    path  = "/stacks/lazy/consumer"
    name  = "consumer"
    after = ["/stacks/lazy/producer"]
  }
  component "consumer" {
    source = "/components/consumer"
    # ── THE ASK ─────────────────────────────────────────────────────────────
    # Lazily read the producer sibling's minted id:
    #     producer_stack_id = bundle.lazy.meta.id                  # bundle.<name>.meta.id
    #     producer_stack_id = bundle.stacks.producer.metadata.id   # (#2361 shape)
    # Errors on 0.17.1: This object does not have an attribute named
    # "lazy" / "stacks" / "producer".
    # Placeholder just lets `terramate generate` parse; it does NOT resolve to
    # the producer — there is no way to name it. That is the gap.
    inputs {
      producer_stack_id = "PLACEHOLDER-no-sibling-handle-see-README"
    }
  }
}
