# Spec: Remove dead Packer variables

Status: done
Owner: you
Related: proposals/006-remove-dead-packer-vars.md

## Context

`main.pkr.hcl` declares two variables, `wg_client_count` and `wg_port`, that have no effect on the build. Neither `var.wg_client_count` nor `var.wg_port` appears in any provisioner block, `environment_vars`, or `inline` command. Confirmed by grepping all HCL, shell, Terraform, and config files — zero references outside the declarations. The `WG_PORT` variable in `wg-setup.sh` and `add-vpn-peer.sh` is a separate shell-level variable with its own `${WG_PORT:-51820}` default, unconnected to the Packer variable. An operator passing `-var "wg_port=443"` to `packer build` would see no effect.

## Goal

Remove the two dead variable declarations and leave a short TODO comment so a future reader knows the feature was considered and where to take it.

## Scope

In scope:
- Delete the `variable "wg_client_count"` block and its comment
- Delete the `variable "wg_port"` block and its comment
- Add a one-line TODO comment at the deletion site

Out of scope (do not build):
- Wiring `WG_PORT` or `wg_client_count` through `environment_vars` to the provisioner scripts (separate feature; start a new proposal if wanted)
- Any change to `wg-setup.sh`, `add-vpn-peer.sh`, or any shell script

## Design

Delete 10 lines from `main.pkr.hcl` (the two comment lines and two 4-line variable blocks). Replace with a single TODO comment immediately before the `source "digitalocean" "bookworm"` block:

```hcl
# TODO: per-build WG_PORT and client-count customization requires environment_vars
# plumbing in the provisioner blocks. See proposals/ to promote when needed.
source "digitalocean" "bookworm" {
```

This keeps the Packer file honest about what it actually controls while preserving the intent for future work.

Invariants this must not break:
- No hardcoded secrets: no secrets involved.
- shellcheck clean: HCL, not shell. No shell scripts change.
- All other invariants: unchanged.

## Files to change

| File | Change |
| --- | --- |
| `main.pkr.hcl` | Delete the two variable blocks (10 lines); add a 2-line TODO comment before the source block |

New files: none.

## Validation

The change is done when `./validate.sh` exits 0 AND the checks below pass.

Feature-specific checks:
- [ ] No variable declarations for the removed names remain:
  ```
  grep 'variable "wg_client_count"\|variable "wg_port"' main.pkr.hcl
  # expect: no output
  ```
- [ ] The TODO comment is present:
  ```
  grep 'TODO.*WG_PORT' main.pkr.hcl
  # expect: one matching line
  ```

## Failure modes to handle

- `packer validate` run with `DO_PAT` set: the removed variables were unused, so removing them does not break validation. Packer does not error on undefined variables that are never referenced.

## Acceptance criteria

- [ ] `variable "wg_client_count"` block is absent from `main.pkr.hcl`
- [ ] `variable "wg_port"` block is absent from `main.pkr.hcl`
- [ ] A TODO comment at the deletion site references `environment_vars` plumbing and `proposals/`
- [ ] `./validate.sh` exits 0
- [ ] No shell scripts changed

## Task checklist

All changes are in `main.pkr.hcl`. Steps 1-3 are sequential in the same file; combine into one edit to avoid offset drift between passes.

1. [ ] `main.pkr.hcl` lines 15-19: delete the `# Number of WireGuard client configs...` comment and the entire `variable "wg_client_count"` block (5 lines including the blank line before the next block)
2. [ ] `main.pkr.hcl` lines 21-25 (after step 1 renumbers them): delete the `# WireGuard listen port...` comment and the entire `variable "wg_port"` block
3. [ ] `main.pkr.hcl`: in place of the deleted blocks, add the 2-line TODO comment immediately before `source "digitalocean" "bookworm" {`:
   ```hcl
   # TODO: per-build WG_PORT and client-count customization requires environment_vars
   # plumbing in the provisioner blocks. See proposals/ to promote when needed.
   source "digitalocean" "bookworm" {
   ```
4. [ ] Run `./validate.sh`, reach exit 0
5. [ ] Feature checks:
   - `grep 'variable "wg_client_count"\|variable "wg_port"' main.pkr.hcl` → no output
   - `grep 'TODO.*WG_PORT' main.pkr.hcl` → one matching line
