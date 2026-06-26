# Decision — Store views & dynamic resolution

_Last updated: store codes confirmed against the live endpoint (CI introspection run)._

## ✅ Confirmed values (live `availableStores`, 2026-06-26)

Discovered via the **Introspect Live GraphQL** GitHub Actions workflow
(`tool/introspect.sh`, header-less `availableStores`):

| Value | Confirmed |
|---|---|
| English store_code | **`eg_en`** (locale `en_US`, **default view**) |
| Arabic store_code | **`eg_ar`** (locale `ar_SA`) |
| Default view | **`eg_en`** → first launch is **English** |
| Currency | **AED** (base + display, both views) |
| Base URL | `https://zoonze.com/` (secure); media `https://zoonze.com/media/` |

> The codes are `eg_en` / `eg_ar` (a store-group naming artifact) — **not**
> `uae-*`. Sending an unknown code makes Magento reject the whole request
> (`Requested store is not found`), so `availableStores` must be queried with
> **no `Store` header** (default view) for discovery. `config/*.json`,
> `AppConfig` defaults, and the tool scripts are set to these values.

## Approach: resolve, don't hardcode
Per owner: the app **does not hardcode** store codes. It bootstraps with a
default code (`BOOTSTRAP_STORE_CODE` = `eg_en`), queries
`availableStores(useCurrentGroup: false)` at runtime, and derives the
authoritative `locale → store_code` map, **default view**, and **currency** from
the response (`StoreController`, `lib/core/store/`). The result is cached in Hive
for subsequent launches; the provisional codes in `config/*.json` are only a
first-launch fallback.

The active store code drives the GraphQL `Store` header on every request
(`StoreHeaderLink`). A language switch is atomic: persist locale → reset the
GraphQL client/cache → rebuild Directionality + theme.

## How discovery is run
`zoonze.com` is unreachable from the agent sandbox (egress policy), but the
**GitHub Actions runner can reach it**. The `Introspect Live GraphQL` workflow
(`.github/workflows/introspect.yml`) runs `tool/introspect.sh` against the live
endpoint and uploads the output + `schema.introspection.json`. Re-run it (or
`bash tool/introspect.sh` on any networked machine) to refresh these values or
to regenerate the schema for Phase 1 codegen.
