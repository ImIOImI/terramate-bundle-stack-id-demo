# terramate-bundle-stack-id-demo

Minimal repro for a Terramate **Catalyst** gap: a `define bundle stack` cannot set
(or address) a stack's **`id`**. That forces an out-of-band workaround to wire
outputs-sharing (`from_stack_id`) between sibling stacks in a bundle.

Two stacks — `producer` and `consumer` — fan out from one bundle
(`bundles/pair`). The consumer reads an apply-computed value from the producer via
Terramate's outputs-sharing. It **works** (`make demo`) — but only because of a
hand-maintained id.

## The gap

Outputs-sharing wires a consumer to a producer by the producer's **stack id**:

```hcl
# generated into the consumer stack
input "message" {
  backend       = "default"
  from_stack_id = "producer"            # <-- must be the producer's literal stack id
  value         = outputs.message.value
}
```

But a `define bundle stack` has no way to set or read a stack id. Verified on
Terramate **0.17.1**:

```console
# id inside metadata:
terramate schema error: unrecognized "define.bundle.stack.<label>.metadata" attribute:
  valid attributes are [after, before, description, name, path, tags, wanted_by, wants, watch] but found "id"

# id as a stack attribute:
terramate schema error: unrecognized "define.bundle.stack" attribute:
  valid attributes are [condition] but found "id"
```

Terramate only mints a stack `id` (a UUID) into `stack.tm.hcl` when that file does
**not already exist**. So the only way to get a *deterministic, knowable* id is to
write `stack.tm.hcl` yourself, out of band, before `terramate generate`:

```hcl
# stacks/producer/stack.tm.hcl  — hand-seeded; the workaround
stack { id = "producer" }
```

…then repeat that same literal (`"producer"`) in the bundle's consumer wiring
(`bundles/pair/bundle.tm.hcl` → `producer_stack_id = "producer"`), and keep the two
in sync by hand. Nothing in the bundle owns the id, and nothing can read a
sibling's id.

## The proposal

Let a `define bundle stack` set its own `id`:

```hcl
define bundle stack "producer" {
  metadata {
    path = "/stacks/producer"
    id   = "producer"        # <-- proposed
  }
}
```

The bundle then owns the id authoritatively — no out-of-band `stack.tm.hcl`
seeding, and (paired with an addressable handle for sibling stacks) the consumer
can wire `from_stack_id` without a hardcoded literal that silently drifts.

## Run it

```console
$ make demo
...
consumer received: hello from the producer stack
```

No cloud provider needed — the producer is a `terraform_data` resource on local
state, so the whole thing applies offline.

## Layout

```
bundles/pair/bundle.tm.hcl          # 2 `define bundle stack`s: producer, consumer
components/producer/                # emits a value + a sharing `output`
components/consumer/                # a sharing `input` (from_stack_id) + a tofu output
stacks/producer/stack.tm.hcl        # hand-seeded id = "producer"  ← the workaround
stacks/consumer/stack.tm.hcl        # hand-seeded id = "consumer"
```

## Real-world context

At scale (a hub/spoke EKS platform) this gap drives an entire
`make/stack-ids.sh` + `make/create-stacks.sh` + inline id-formula machinery whose
only job is to work around the missing settable id — see
[ImIOImI/terramate-eks-hubspoke](https://github.com/ImIOImI/terramate-eks-hubspoke)
(`make/stack-ids.sh`, and the `network_stack_id = "${bundle.environment.id}-eks-network"`
reproductions in `bundles/eks-cluster/bundle.tm.hcl`).

## Related upstream issues

- terramate-io/terramate#2364 — Bundles should generate the stack completely (incl. `id`)
- terramate-io/terramate#2366 — Shared outputs wiring between sibling stacks in a Catalyst bundle
- terramate-io/terramate#2361 — Get access to stack metadata from a bundle
- terramate-io/terramate#2282 — Function to get stack id by path/tags
