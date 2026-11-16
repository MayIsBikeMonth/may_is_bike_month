# Port inventory

Read from `port-from-bike-index` when writing the end-of-port table, or before deciding a skip that a past port may already have settled.

Everything a port leaves behind gets a row: a whole skill not ported, a section dropped from a skill that was, a skipped or reverted component, a preview, a config file. Skill omissions are the easiest to forget because they're prose, not a missing file.

**Fork-axis transforms don't go here.** Stripping `tw:`, inlining `translation()`, `UI::Forms::` → `Form::`, and bike → competition examples are *how* things came over, not things left behind.

Write each row so the next port can act on it without re-deriving: name what's missing in MIBM, and what would have to change for the row to go away. Delete a row once it no longer holds.

| What you didn't pull | Why |
|---|---|
| `admin-data-api` skill | Talks to bike_index's `AdminData` production API; MIBM has no equivalent. |
| `honeybadger-debugging` skill | Built on bike_index's `bin/binx_hb` script and Honeybadger projects. |
| `production-log-inspection` skill | Reads bike_index's production log host. |
| Blocklisted `UI::` components (SKILL.md Step 3) | Each needs a model MIBM doesn't have. The model is named in the list. |
| `Atoms::*` components | Out of scope by namespace. |

## Cautionary ledger

Ports that *looked* fine but broke a live page — none yet. Add a row (what, what the port changed, what broke) whenever one bites.
