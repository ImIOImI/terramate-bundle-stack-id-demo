# terramate-bundle-stack-id-demo

Repro for a Terramate **Catalyst** gap: a `define bundle stack` can neither **set**
its own stack `id` nor **address** a sibling's, which is what you need to wire
outputs-sharing (`from_stack_id`) between stacks in a bundle. Two bundles show the
two shapes that would close it — both error on **0.17.1**.

Each bundle fans out a `producer` and a `consumer`; the consumer wants the
producer's stack id for `from_stack_id`.

## `bundles/deterministic/` — mint the id in the bundle, set it on the producer

```hcl
define "bundle" {
  lets {
    id = tm_uuid()                       # RANDOM, minted once per `terramate generate`
  }
}
define bundle stack "producer" {
  metadata {
    path = "/stacks/deterministic/producer"
    id   = bundle.let.id                 # ← THE ASK (rejected today)
  }
}
# consumer reuses the same let (this already resolves today):
producer_stack_id = bundle.let.id
```

`bundle.let.id` is evaluated **once per build**, so every reference in that build
gets the same value — it *can* be the producer's id and the consumer's
`from_stack_id` at the same time, and they match. (Regenerate and both move
together.) The one rejected line:

```
terramate schema error: unrecognized "define.bundle.stack.<label>.metadata"
attribute: valid attributes are [after, before, description, name, path, tags,
wanted_by, wants, watch] but found "id"
```

Because you can't set it, terramate mints the producer its **own** uuid instead,
which never equals `bundle.let.id` — so the two diverge and sharing can't wire:

```
producer's actual id (minted) : 0984b2f3-4cfa-45a2-8a5c-cd0e3bf40175
consumer from_stack_id         : f0b5f7ff-42f3-374e-1e55-8b2d8d82a918   # = bundle.let.id
```

A settable `metadata.id` closes it: the producer's id becomes `bundle.let.id`,
matching the consumer. (Ideally terramate also **persists** the minted id into
`stack.tm.hcl` so it doesn't re-roll each generate.)

## `bundles/lazy/` — terramate mints the id; the consumer reads it lazily

Here the producer's `stack.tm.hcl` is left unseeded, so terramate mints it a
random UUID (id "created at build time, in stack metadata"). The consumer wants
to read that sibling's id:

```hcl
producer_stack_id = bundle.lazy.meta.id                # bundle.<name>.meta.id
producer_stack_id = bundle.stacks.producer.metadata.id # (#2361 shape)
```

Every form errors — the `bundle` object exposes no sibling handle:

```
This object does not have an attribute named "lazy" / "stacks" / "producer"
```

(The repo uses a placeholder `from_stack_id` so it still parses; it can't resolve
to the producer — that's the point.)

## The single missing capability

- **deterministic** needs a **settable `id` in `define bundle stack metadata`**.
- **lazy** needs an **addressable sibling id** (`bundle.<name>.meta.id`).

Either removes the out-of-band `stack.tm.hcl` seeding + hand-kept `from_stack_id`
literal. At scale this is a whole shell layer — see
[ImIOImI/terramate-eks-hubspoke](https://github.com/ImIOImI/terramate-eks-hubspoke)
(`make/stack-ids.sh` + `make/create-stacks.sh` + the `check-ids` gate, and the
`network_stack_id = "${bundle.environment.id}-eks-network"` reproductions in
`bundles/eks-cluster/bundle.tm.hcl`) — all of which a settable/addressable id deletes.

## Try it

```console
$ terramate generate && terramate generate
$ make show      # prints, for each bundle, the producer's id vs the consumer's from_stack_id
```

Note: `bundles/deterministic` uses `tm_uuid()`, which re-rolls every
`terramate generate` (the consumer's `from_stack_id` changes each run). That churn
is exactly why a bundle-set id should be **persisted** — it does not affect the
producer↔consumer match within a build.

## Related upstream issues

- terramate-io/terramate#2364 — Bundles should generate the stack completely (incl. `id`)
- terramate-io/terramate#2366 — Shared outputs wiring between sibling stacks in a Catalyst bundle
- terramate-io/terramate#2361 — Get access to stack metadata from a bundle
- terramate-io/terramate#2282 — Function to get stack id by path/tags
