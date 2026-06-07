# Proposal: Remove dead wg_client_count and wg_port Packer variables

Status: proposed
Author: agent
Date: 2026-06-07

## Problem or opportunity

`main.pkr.hcl` declares two variables that have no effect on the build:

```hcl
variable "wg_client_count" {
  type    = number
  default = 1
}

variable "wg_port" {
  type    = number
  default = 51820
}
```

Neither `var.wg_client_count` nor `var.wg_port` is referenced in any provisioner block, `environment_vars`, or `inline` command in the file. Confirmed by grepping all `.hcl`, `.sh`, `.tf`, `.json`, `.yaml`, and `.yml` files in the repo — zero references.

The `WG_PORT` variable used in `wg-setup.sh` and `add-vpn-peer.sh` is an independent shell-level variable with its own `${WG_PORT:-51820}` default. It reads from the process environment, not from the Packer variable. Passing `-var "wg_port=443"` to `packer build` has no effect on what port WireGuard listens on.

## Why it matters

Dead variables mislead operators. A reader of `main.pkr.hcl` would reasonably assume these control the build. An operator specifying `-var "wg_client_count=3"` or `-var "wg_port=443"` would see no effect and have no indication why.

## Rough approach

Delete the two variable blocks (8 lines) from `main.pkr.hcl`. No other file needs to change.

If per-build customization of client count or listen port is wanted in the future, that is a separate feature requiring `environment_vars` plumbing in the provisioner blocks and should start as a new proposal at that point.

## Rough effort

small — 8-line deletion, no logic change.

## Invariants touched

None. No secrets, no security impact.

## Decision (human fills this in)

- [ ] promote to spec
- [ ] defer
- [ ] decline

Notes:
