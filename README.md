# terramate-bundle-stack-id-demo

Minimal repro for a Terramate **Catalyst** gap: a `define bundle stack` cannot set
(or address) a stack's **`id`**. That forces an out-of-band workaround to wire
outputs-sharing (`from_stack_id`) between sibling stacks in a bundle.

Two stacks — `producer` and `consumer` — fan out from one bundle
(`bundles/pair`). The consumer reads an apply-computed value from the producer via
Terramate's outputs-sharing. It **works** (`make demo`) — but only because of a
hand-maintained id.

## Two ways to share the producer's stack id

**Way 1 — a deterministic guid, known ahead of time (works today).**
Create a stable guid once, and use it on *both* sides:

```hcl
# bundles/pair/bundle.tm.hcl
lets {
  producer_id = tm_uuidv5("dns", "producer")   # deterministic; tm_uuid() would churn
}
# consumer wiring:
producer_stack_id = bundle.let.producer_id
```

```hcl
# stacks/producer/stack.tm.hcl  — the same guid, hand-seeded out of band
stack { id = "2e2ea0f7-596a-57d6-b233-6deecf9941d5" }
```

The catch: the guid lives in **two** places — the bundle `let` *and* the seeded
`stack.tm.hcl` — and nothing links them. If they drift, outputs-sharing silently
wires to the wrong id. `terramate generate` never mints the id you want; it only
leaves your hand-seeded file alone.

**Way 2 — lazily address the sibling's id (proposed; errors on 0.17.1).**
No guid, no out-of-band seed — the bundle resolves the producer stack's id at
generate time:

```hcl
# consumer wiring (proposed)
producer_stack_id = bundle.pair.meta.id          # bundle.<name>.meta.id
# or, matching the shape requested in terramate-io/terramate#2361:
producer_stack_id = bundle.stacks.producer.metadata.id
```

Today every form fails — the `bundle` object exposes no sibling handle:

```
partial evaluation failed: eval expression:
  This object does not have an attribute named "pair"     # bundle.pair.meta.id
  ... named "stacks"                                       # bundle.stacks.producer.metadata.id
  ... named "producer"                                     # bundle.producer.metadata.id
```

Way 2 is the ask: let a `define bundle stack` own its `id` (and expose siblings'
ids), so sharing needs neither a guid nor a hand-seeded `stack.tm.hcl`.

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
