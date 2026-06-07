# Proposal: Wire wg_client_count and wg_port through Packer build

Status: proposed
Author: agent
Date: 2026-06-07

## Problem or opportunity

`main.pkr.hcl` defines two variables that are never used in the build:

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

Neither `var.wg_client_count` nor `var.wg_port` appears in any provisioner block. A user running `packer build -var "wg_client_count=3"` or `-var "wg_port=443"` would see no effect. The variables are either dead code or should be wired through to the cloud-init scripts.

## Why it matters

Dead variables mislead operators who read the Packer file and expect these to control the built image. If `wg_client_count` is meant to pre-generate multiple QR codes in the MOTD, that is useful functionality that is currently inert.

## Validation result (2026-06-07)

Confirmed dead. A grep across all `.hcl`, `.sh`, `.tf`, `.json`, `.yaml`, and `.yml` files finds zero references to `var.wg_client_count` or `var.wg_port` in any provisioner block or environment_vars declaration. The `WG_PORT` variable in `wg-setup.sh` and `add-vpn-peer.sh` is a separate shell-level variable with its own `${WG_PORT:-51820}` default, read from the process environment — it is not connected to the Packer variable. Removing the two declarations has no effect on the build.

## Rough approach

Option A (wire up): Pass the variables as environment variables to the cloud-init provisioner scripts. For `wg_client_count`, use an `environment_vars` block or `inline` command that writes `WG_PORT=<port>` and the count into the per-instance script wrapper. Then in the 02-setup-wireguard.sh launcher, forward them to `wg-setup.sh`.

Option B (remove): Delete the two variable declarations if they are not intended for this release. Document the intent in a proposal or roadmap entry and implement when the wiring is ready.

Option B is simpler and keeps the Packer file truthful about what the build controls. If per-build customization is wanted, promote Option A to a spec.

## Rough effort

small (Option B: remove two blocks) or medium (Option A: requires environment_vars plumbing and per-instance script changes).

## Invariants touched

None directly. No hardcoded secrets.

## Decision (human fills this in)

- [ ] promote to spec
- [ ] defer
- [x] decline

Notes: Option B (remove) is confirmed safe and correct. See proposal 006 for the implementation. Option A (wire them up) is a separate feature; if per-build customization of client count or port is wanted, it should start as a new proposal when the need arises.
