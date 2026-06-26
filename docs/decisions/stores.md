# Decision — Store views & dynamic resolution

_Last updated: Phase 0 foundation._

## Approach: resolve, don't hardcode
Per owner: the app **does not hardcode** store codes. It bootstraps with a
default code (`BOOTSTRAP_STORE_CODE`, provisional `uae-en`), queries
`availableStores(useCurrentGroup: false)` at runtime, and derives the
authoritative `locale → store_code` map, **default view**, and **currency** from
the response (`StoreController`, `lib/core/store/`). The result is cached in Hive
for subsequent launches; the provisional codes in `config/*.json` are only a
first-launch fallback.

The active store code drives the GraphQL `Store` header on every request
(`StoreHeaderLink`). A language switch is atomic: persist locale → reset the
GraphQL client/cache → rebuild Directionality + theme.

## ⚠️ Unconfirmed values (origin blocked in CI)
`zoonze.com` is unreachable from the build environment (egress policy), so the
real store codes / default / currency **could not be verified here**. They are
resolved dynamically at runtime, so this does not block Phase 0 — but confirm
them from a network that can reach the origin:

```bash
bash tool/introspect.sh
```

This prints `availableStores` + per-view `storeConfig` and writes
`lib/core/graphql/schema.graphql` (for Phase 1 codegen). After running it:
- Record the real `store_code` values, the default view, and the currency here.
- Update `config/*.json` `BOOTSTRAP_STORE_CODE` / `STORE_CODE_*` if they differ
  from the provisional `uae-en` / `uae-ar`.

| Value | Provisional (unconfirmed) | Confirmed |
|---|---|---|
| English store_code | `uae-en` | _TBD_ |
| Arabic store_code | `uae-ar` | _TBD_ |
| Default view | _TBD_ | _TBD_ |
| Currency | `AED` | _TBD_ |
