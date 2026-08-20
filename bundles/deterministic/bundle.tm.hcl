# DETERMINISTIC bundle — mint the id in the bundle and set it on the producer.
#
# The id is minted ONCE per `terramate generate` (tm_uuid(), random) and every
# reference in that build gets the SAME value — so it can be the producer's id
# AND be handed to the consumer, and they match. (Regenerate: both move together.)
define "bundle" "metadata" {
  class       = "deterministic"
  version     = "0.1.0"
  name        = "deterministic"
  description = "Mint a random id in a bundle let, set it on the producer, reuse it in the consumer."
}

define "bundle" {
  lets {
    id = tm_uuid() # RANDOM, minted once per build; same value everywhere in this build
  }
  scaffolding {
    path = "/_scaffold-deterministic.tm.yml"
    name = "deterministic"
  }
}

define bundle stack "producer" {
  metadata {
    path = "/stacks/deterministic/producer"
    name = "producer"

    # ── THE ASK ─────────────────────────────────────────────────────────────
    # Set the producer's id to the minted value:
    #     id = bundle.let.id
    # Errors on 0.17.1: unrecognized "define.bundle.stack.<label>.metadata"
    # attribute ... valid attributes are [after, before, description, name,
    # path, tags, wanted_by, wants, watch] but found "id".
    # Because we can't set it, terramate mints the producer its OWN uuid — which
    # never equals bundle.let.id — so sharing can't wire. That mismatch is the gap.
  }
  component "producer" {
    source = "/components/producer"
  }
}

define bundle stack "consumer" {
  metadata {
    path  = "/stacks/deterministic/consumer"
    name  = "consumer"
    after = ["/stacks/deterministic/producer"]
  }
  component "consumer" {
    source = "/components/consumer"
    # The consumer can already take the minted id — this resolves fine today:
    inputs {
      producer_stack_id = bundle.let.id
    }
  }
}
