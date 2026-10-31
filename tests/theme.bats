#!/usr/bin/env bats
# Tests for the theme's own files under static/. These pin the decisions
# a file encodes and the contracts listmonk holds it to; the look itself
# is checked by eye on local listmonk (cmon1975dotcom's bin/listmonk-dev).

setup() {
  ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  STATIC="$ROOT/static"
  UPSTREAM="$ROOT/upstream/$(cat "$ROOT/LISTMONK_VERSION")"
}

# The templates and stylesheet the theme replaces, relative to static/.
# Fonts are the theme's own additions, not replacements.
replaced() {
  (cd "$STATIC" && find . -type f ! -path './public/static/fonts/*' | sed 's|^\./||' | sort)
}

# The names a template file defines with {{ define "..." }}, one per line.
defines() {
  grep -o '{{ *define "[^"]*"' "$1" | sed 's/.*"\(.*\)"/\1/' | sort
}

@test "every file the theme replaces has listmonk's original under upstream/<pinned version>" {
  files="$(replaced)"
  [ -n "$files" ]
  while read -r f; do
    [ -f "$UPSTREAM/$f" ] || { echo "no upstream original for $f"; return 1; }
  done <<<"$files"
}

@test "each replaced template defines the same templates as listmonk's original" {
  # listmonk looks pages and emails up by these names; a missing one is a
  # template error at startup, and listmonk won't start.
  templates="$(replaced | grep '\.html$')"
  [ -n "$templates" ]
  while read -r f; do
    [ "$(defines "$STATIC/$f")" = "$(defines "$UPSTREAM/$f")" ] || { echo "defines differ in $f"; return 1; }
  done <<<"$templates"
}

@test "the layout's footer credits listmonk and links this theme's source, which the AGPL asks for" {
  footer="$(sed -n '/define "footer"/,/end/p' "$STATIC/public/templates/index.html")"
  [[ "$footer" == *'href="https://listmonk.app"'* ]]
  [[ "$footer" == *'href="https://github.com/CMON1975/lists_theme"'* ]]
  ! grep -rq 'public.poweredBy' "$STATIC"
}

@test "the stylesheet's colors all come from its --book-* tokens" {
  # The site's palette (cmon1975.com site/book.css): a color written
  # anywhere but the token rule drifts from it.
  run python3 -I - "$STATIC/public/static/style.css" <<'PY'
import re, sys
css = re.sub(r"/\*.*?\*/", "", open(sys.argv[1]).read(), flags=re.S)
bad = []
for sel, body in re.findall(r"([^{}]+)\{([^{}]*)\}", css):
    if sel.strip() == ":root":
        continue
    for prop, val in re.findall(r"(?<![\w-])((?:background|border|outline|text-decoration)(?:-[a-z]+)*|color|accent-color|caret-color)\s*:\s*([^;]+);", body):
        if re.search(r"#[0-9a-fA-F]{3,8}\b|rgb|hsl|\b(white|black)\b", val):
            bad.append(f"{sel.strip()} {prop}: {val.strip()}")
print("\n".join(bad))
sys.exit(1 if bad else 0)
PY
  [ "$status" -eq 0 ]
}

@test "every font the stylesheet loads is in the theme, with its license" {
  css="$STATIC/public/static/style.css"
  fonts="$(grep -o "url('fonts/[^'?]*" "$css" | sed "s|url('||" | sort -u)"
  [ -n "$fonts" ]
  while read -r f; do
    [ -f "$STATIC/public/static/$f" ] || { echo "missing $f"; return 1; }
  done <<<"$fonts"
  [ -f "$STATIC/public/static/fonts/OFL-ebgaramond.txt" ]
}
