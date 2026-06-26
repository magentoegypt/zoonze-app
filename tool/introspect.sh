#!/usr/bin/env bash
#
# Introspect the live Magento GraphQL endpoint to (1) confirm store views and
# per-view config, and (2) emit a schema file for Phase 1 graphql_codegen.
#
# Run this from a network that can reach zoonze.com (the CI/build environment is
# blocked by the org egress policy).
#
# Usage:
#   bash tool/introspect.sh
#   ENDPOINT=https://zoonze.com/graphql STORE_EN=uae-en STORE_AR=uae-ar bash tool/introspect.sh
#
set -euo pipefail

ENDPOINT="${ENDPOINT:-https://zoonze.com/graphql}"
STORE_EN="${STORE_EN:-uae-en}"
STORE_AR="${STORE_AR:-uae-ar}"
UA="${USER_AGENT:-ZoonzeApp/0.1.0 (Flutter)}"
OUT_DIR="lib/core/graphql"
mkdir -p "$OUT_DIR"

post() { # $1 = Store header (empty => omit, use default store), $2 = json body
  local hdr=()
  [ -n "$1" ] && hdr=(-H "Store: $1")
  curl -sS --max-time 40 -X POST "$ENDPOINT" \
    -H "Content-Type: application/json" \
    "${hdr[@]}" \
    -H "User-Agent: $UA" \
    --data "$2"
}

# availableStores is store-agnostic. Query it with NO `Store` header so Magento
# answers from the DEFAULT view — sending an unknown code (e.g. the provisional
# uae-en) makes Magento reject the whole request with "Requested store is not
# found", which would also block discovery. The codes printed here are the
# authoritative source for STORE_EN / STORE_AR below.
echo "== availableStores (no Store header → default view) =="
echo "   >>> Read the store_code values below; they are the REAL codes. <<<"
post "" '{"query":"{ availableStores(useCurrentGroup:false){ store_code store_name locale is_default_store base_currency_code default_display_currency_code base_url secure_base_url base_media_url } }"}'
echo; echo
echo "== storeConfig (no Store header → default view, shows the default store_code) =="
post "" '{"query":"{ storeConfig { store_code store_name locale base_currency_code default_display_currency_code base_url secure_base_url base_media_url } }"}'
echo; echo
echo "Now re-run with the discovered codes for the per-view + payment sections, e.g.:"
echo "   STORE_EN=<en_code> STORE_AR=<ar_code> bash tool/introspect.sh"
echo

for store in "$STORE_EN" "$STORE_AR"; do
  echo "== storeConfig (Store: $store) =="
  post "$store" '{"query":"{ storeConfig { store_code store_name locale base_currency_code default_display_currency_code base_url secure_base_url base_media_url } }"}'
  echo; echo
done

echo "== Phase 3 payment contract — MagentoEgypt_PaymentGraphQl (no Store header) =="
# Schema introspection is store-agnostic, so it works without a valid code.
# Confirm the resolvers + args exist on the live schema and match the app's queries
# (docs/backend/payment-contract.md). paymentSession must accept
# order_number!, email, lastname, guest_token; tabbyConfig must exist.
post "" '{"query":"{ __type(name:\"Query\"){ fields(includeDeprecated:true){ name args{ name type{ kind name ofType{ kind name } } } } } }"}' \
  | tr ',' '\n' | grep -A12 -iE '"name": ?"(paymentSession|tabbyConfig)"' || \
  echo "  (paymentSession/tabbyConfig not found on Query — module not deployed?)"
echo
for t in PaymentSessionOutput TabbyConfigOutput TabbyProduct; do
  echo "-- type $t --"
  post "" "{\"query\":\"{ __type(name:\\\"$t\\\"){ name kind fields{ name type{ kind name ofType{ kind name } } } enumValues{ name } } }\"}"
  echo
done
echo "Cross-check the above field/arg/enum names against docs/backend/payment-contract.md."
echo

echo "== Full schema introspection -> $OUT_DIR/schema.graphql (SDL) or schema.json =="
# Prefer SDL via a tool if available; otherwise dump the introspection JSON.
# Store-agnostic → no header needed.
INTROSPECTION_QUERY='{"query":"query IntrospectionQuery { __schema { queryType { name } mutationType { name } subscriptionType { name } types { ...FullType } directives { name locations args { ...InputValue } } } } fragment FullType on __Type { kind name description fields(includeDeprecated:true){ name description args{ ...InputValue } type{ ...TypeRef } isDeprecated deprecationReason } inputFields{ ...InputValue } interfaces{ ...TypeRef } enumValues(includeDeprecated:true){ name description isDeprecated deprecationReason } possibleTypes{ ...TypeRef } } fragment InputValue on __InputValue { name description type{ ...TypeRef } defaultValue } fragment TypeRef on __Type { kind name ofType{ kind name ofType{ kind name ofType{ kind name ofType{ kind name ofType{ kind name ofType{ kind name ofType{ kind name } } } } } } } }"}'
post "" "$INTROSPECTION_QUERY" > "$OUT_DIR/schema.introspection.json"
echo "Wrote $OUT_DIR/schema.introspection.json"
echo "Convert to SDL with e.g.: npx graphql-json-to-sdl $OUT_DIR/schema.introspection.json > $OUT_DIR/schema.graphql"
echo
echo "Next: update docs/decisions/stores.md + config/*.json with the confirmed codes."
