#!/usr/bin/env bats
# Tests for bin/import-upstream. A fake listmonk binary: a few bytes of
# "executable" with a zip of static files appended, the way stuffbin embeds
# them, so unzip warns about the leading bytes as it does on the real one.

setup() {
  TMP="$(mktemp -d)"
  export THEME_ROOT="$TMP/theme"
  mkdir -p "$THEME_ROOT"
  src="$TMP/src"
  mkdir -p "$src/public/templates" "$src/public/static" "$src/static/email-templates"
  echo '{{ define "header" }}' > "$src/public/templates/index.html"
  echo '{{ define "optin" }}' > "$src/public/templates/optin.html"
  echo 'body {}' > "$src/public/static/style.css"
  printf 'PNG' > "$src/public/static/logo.png"
  echo 'js' > "$src/public/static/script.js"
  echo '{{ define "subscriber-optin" }}' > "$src/static/email-templates/subscriber-optin.html"
  echo '{{ define "content" }}' > "$src/static/email-templates/default.tpl"
  echo '{}' > "$src/static/email-templates/default-visual.json"
  mkdir -p "$src/admin"
  echo 'admin' > "$src/admin/index.html"
  # The real binary stores absolute names (/public/templates/index.html);
  # ZipFile.write would strip the slash, a bare ZipInfo keeps it.
  python3 -I - "$src" "$TMP/static.zip" <<'PY'
import os, sys, zipfile
src, out = sys.argv[1], sys.argv[2]
with zipfile.ZipFile(out, "w") as z:
    for d, _, files in os.walk(src):
        for f in files:
            p = os.path.join(d, f)
            with open(p, "rb") as fh:
                z.writestr(zipfile.ZipInfo("/" + os.path.relpath(p, src)), fh.read())
PY
  { printf '\177ELF fake binary'; cat "$TMP/static.zip"; } > "$TMP/listmonk"
}

teardown() {
  rm -rf "$TMP"
}

@test "copies listmonk's page templates, stylesheet and email templates into upstream/<version> in --static-dir's layout" {
  run "$BATS_TEST_DIRNAME/../bin/import-upstream" 9.9.9 "$TMP/listmonk"
  [ "$status" -eq 0 ]
  up="$THEME_ROOT/upstream/9.9.9"
  [ "$(cat "$up/public/templates/index.html")" = '{{ define "header" }}' ]
  [ -f "$up/public/templates/optin.html" ]
  [ "$(cat "$up/public/static/style.css")" = 'body {}' ]
  [ "$(cat "$up/email-templates/subscriber-optin.html")" = '{{ define "subscriber-optin" }}' ]
  [ -f "$up/email-templates/default.tpl" ]
  [ -f "$up/email-templates/default-visual.json" ]
}

@test "leaves out images, scripts and the admin app, which the theme doesn't override" {
  run "$BATS_TEST_DIRNAME/../bin/import-upstream" 9.9.9 "$TMP/listmonk"
  [ "$status" -eq 0 ]
  up="$THEME_ROOT/upstream/9.9.9"
  [ ! -e "$up/public/static/logo.png" ]
  [ ! -e "$up/public/static/script.js" ]
  [ ! -e "$up/admin" ]
  [ ! -e "$up/static" ]
}

@test "refuses to overwrite a version already imported" {
  mkdir -p "$THEME_ROOT/upstream/9.9.9/public/templates"
  echo kept > "$THEME_ROOT/upstream/9.9.9/public/templates/index.html"
  run "$BATS_TEST_DIRNAME/../bin/import-upstream" 9.9.9 "$TMP/listmonk"
  [ "$status" -eq 1 ]
  [[ "$output" == *"already"* ]]
  [ "$(cat "$THEME_ROOT/upstream/9.9.9/public/templates/index.html")" = kept ]
}

@test "fails, leaving nothing behind, on a file with no embedded templates" {
  printf '\177ELF not listmonk' > "$TMP/other"
  run "$BATS_TEST_DIRNAME/../bin/import-upstream" 9.9.9 "$TMP/other"
  [ "$status" -eq 1 ]
  [ ! -e "$THEME_ROOT/upstream/9.9.9" ]
}

@test "prints usage and exits 2 without a version and a binary" {
  run "$BATS_TEST_DIRNAME/../bin/import-upstream" 9.9.9
  [ "$status" -eq 2 ]
  [[ "$output" == *"Usage"* ]]
}
