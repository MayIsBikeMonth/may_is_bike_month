# Port inventory

Read from `port-from-bike-index` when writing the end-of-port table, or before deciding a skip that a past port may already have settled.

Everything a port leaves behind gets a row: a whole skill not ported, a section dropped from a skill that was, a skipped or reverted component, a preview, a config file. Skill omissions are the easiest to forget because they're prose, not a missing file.

**Fork-axis transforms don't go here.** Stripping `tw:`, inlining `translation()`, and bike → competition examples are *how* things came over, not things left behind.

Write each row so the next port can act on it without re-deriving: name what's missing in MIBM, and what would have to change for the row to go away. Delete a row once it no longer holds.

| What you didn't pull | Why |
|---|---|
| `admin-data-api` skill | Talks to bike_index's `AdminData` production API; MIBM has no equivalent. |
| `honeybadger-debugging` skill | Built on bike_index's `bin/binx_hb` script and Honeybadger projects. |
| `production-log-inspection` skill | Reads bike_index's production log host. |
| Blocklisted `UI::` components (SKILL.md Step 3) | Each needs a model MIBM doesn't have. The model is named in the list. |
| `Atoms::*` components | Out of scope by namespace. |
| `UI::Alerts::FlashMessage`'s hash flash (`translation_key:` + `url:`) and its preview | Its only messages are bike_index's password sign-in prompts. MIBM's copy maps Devise's `:alert` to `:error` instead, since upstream's `UI::Alerts::Base` rejects `:alert`. |
| `UI::Forms::Files::Upload`'s CarrierWave branch, `BlobUrl`, the `with_existing_image` preview and the thumbnail spec | MIBM stores nothing through CarrierWave and has no model with an attachment; the attached URL is `url_for(attachment)`. |
| `period_select`, `time_range`, `drag_handle`, `alerts/*`, `forms/*`, `table/column_settings`, `definition_list/row` `.en.yml` sidecars | Inlined (fork axis). |
| `table/base` spec's `:nl` locale example | MIBM only loads `:en`; the `locale/en` assertion still covers the key. |
| `ApplicationComponent#translation` and its scope helpers | No i18n sidecars here. |
| `GraphingHelper#time_range_amounts`, `#period_in_words`, `#organization_dashboard_bikes_graph_data` | No caller here. |
| `ComponentStructs::Shapes`' menu shapes (`link`, `group`, `disabled`, `divider`), `IndexState`, the org search structs | Only `tab` and `entry` are read by `UI::` components. |
| `application.css`: Bike Index's palette, fonts and breakpoints, the `.inverted` dark variant, `search-all-checked`/`imperial`/`similar-open` variants, org-sidebar body rules, select2, `.twbootcontainer`, `legacy`/`bikebook`/`lexxy_overrides`/`legacy_dark` stylesheets | Bike Index's brand and pages. MIBM keeps its purple palette, IBM Plex fonts, and its own `twtext-color`, `.twlink`, `.twinput` colors. |
| `bike_index_components.css`: `twpagebleed`, `.only-dev-visible`, `.twalert-body`, `.form-well-label`, `.twsearchrow`, `.twhr` | Org sidebar, legacy Bootstrap cascade, legacy form well, admin search row and `<hr>` — no `UI::` component here emits them (`.twalert-body` is emitted but only fought Bootstrap's `.container`). MIBM keeps its own `.only-dev-visible`. |
| `spec/support`: request/registration helpers, and `integration_spec_helpers.rb`'s bike helpers, `fill_in_verified`, `browser_cookie_value`, `click_combobox_option` and `RequestHold` | No caller here. |

## Cautionary ledger

Ports that *looked* fine but broke a live page — none yet. Add a row (what, what the port changed, what broke) whenever one bites.
