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

# The declarations the stylesheet gives a selector (in a rule's selector
# list, comments ignored), one "property: value" per line.
css_decls() {
  python3 -I - "$STATIC/public/static/style.css" "$1" <<'PY'
import re, sys
css = re.sub(r"/\*.*?\*/", "", open(sys.argv[1]).read(), flags=re.S)
for sel, body in re.findall(r"([^{}]+)\{([^{}]*)\}", css):
    if sys.argv[2] in [s.strip() for s in sel.split(",")]:
        for prop, val in re.findall(r"([\w-]+)\s*:\s*([^;]+);", body):
            print(f"{prop}: {val.strip()}")
PY
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

@test "the captcha box is centered over the Subscribe button, at the widget's own width" {
  # listmonk 6.2.0's Altcha widget (its altcha.umd.js) draws its box as
  # .altcha, a block at most 260px wide, at the column's left, while
  # .actions centers the button. Auto side margins center the box; the
  # width stays the widget's. Recheck the class on a listmonk bump.
  box="$(css_decls '.captcha .altcha')"
  grep -qxE 'margin: [^ ]+ auto( [^ ]+)?|margin-inline: auto' <<<"$box" ||
    [ "$(grep -cxE 'margin-(left|right): auto' <<<"$box")" -eq 2 ]
  ! grep -qE '^[a-z-]*width:|^flex' <<<"$box"
}

@test "the captcha box is drawn like the theme's fields: ruled, square, its error like .error" {
  # Altcha's own look is a grey rounded border, an ink focus border and red
  # error text. Its --altcha-* properties take the fields' rule and focus
  # colors and square corners; its error line (.altcha-error, the widget's
  # own class: recheck on a listmonk bump) reads as the theme's .error.
  captcha="$(css_decls '.captcha')"
  grep -qxF -- '--altcha-color-border: var(--book-rule)' <<<"$captcha"
  grep -qxF -- '--altcha-color-border-focus: var(--book-muted)' <<<"$captcha"
  grep -qxF -- '--altcha-border-radius: 0' <<<"$captcha"
  grep -qxF -- '--altcha-color-error-text: var(--book-ink-strong)' <<<"$captcha"
  grep -qxF 'font-style: italic' <<<"$(css_decls '.captcha .altcha-error')"
}

# The form fields listmonk's handlers read (cmd/public.go): a page that
# stops posting one breaks signing up, confirming or unsubscribing.

@test "the signup form posts email, name, the lists and the nonce honeypot back to itself" {
  f="$STATIC/public/templates/subscription-form.html"
  grep -q '<form method="post" action=""' "$f"
  for field in email name l nonce; do
    grep -q "name=\"$field\"" "$f" || { echo "no $field field"; return 1; }
  done
  grep -q 'name="nonce" class="nonce"' "$f"
}

@test "the opt-in page posts each list back with confirm=true" {
  f="$STATIC/public/templates/optin.html"
  grep -q '<form method="post"' "$f"
  grep -q 'name="l" value="{{ $l.UUID }}"' "$f"
  grep -q 'name="confirm" value="true"' "$f"
}

@test "the opt-in page asks for the click in the owner's words, naming the list itself" {
  # The owner's wording (2026-11-22), in place of listmonk's "You have been
  # added to the following lists:" and the names under it: the reader isn't
  # on the list until this page's button confirms, and the sentence names
  # the one list. The lists still post back hidden.
  f="$STATIC/public/templates/optin.html"
  grep -qF '>Click the button below to join the CMON1975 mailing list:</p>' "$f"
  ! grep -qE 'public\.confirmSubInfo|subPrivateList|\$l\.Name' "$f"
}

@test "the unsubscribe page posts its form, and the preferences page manage=true, the name and the lists kept" {
  f="$STATIC/public/templates/subscription.html"
  [ "$(grep -c '<form method="post"' "$f")" -ge 2 ]
  grep -q 'name="manage" value="true"' "$f"
  grep -q 'name="name" value="{{ .Data.Subscriber.Name }}"' "$f"
  grep -q 'name="l" value="{{ $l.UUID }}"' "$f"
}

@test "the preferences page words its one list in the singular" {
  # The owner's wording (2026-11-22), in place of listmonk's "Lists" and
  # "Uncheck lists to unsubscribe from them.": there is only ever one list,
  # and unchecking it does nothing until Save.
  f="$STATIC/public/templates/subscription.html"
  grep -qF '<h3>Mailing list</h3>' "$f"
  grep -qF '>Uncheck the box below and press the save button to unsubscribe.</p>' "$f"
  ! grep -qE 'globals\.terms\.lists|public\.managePrefsUnsub' "$f"
}

@test "the email frame opens with <!doctype html> in its first 256 bytes, so listmonk sends its emails as HTML" {
  # listmonk (cmd/init.go, initNotifs) sniffs base.html's first 256 bytes
  # for "<!doctype html" and otherwise sends every system email, the
  # opt-in email included, as text/plain: the markup shows as text.
  head -c 256 "$STATIC/email-templates/base.html" | grep -qi '<!doctype html'
}

@test "the opt-in email's button opens the opt-in page, and it offers no unsubscribing" {
  # Not yet subscribed, so an unsubscribe link only muddles the one ask;
  # ignoring the email is the way out (decision 2026-10-31).
  f="$STATIC/email-templates/subscriber-optin.html"
  grep -q 'href="{{ .OptinURL }}"' "$f"
  ! grep -qE 'UnsubURL|email\.unsub' "$f"
}

@test "the opt-in email asks in the owner's words" {
  # The owner's wording (2026-10-31), in place of listmonk's welcome, list
  # of lists and help line.
  f="$STATIC/email-templates/subscriber-optin.html"
  grep -qF '>Please confirm your subscription to the CMON1975 mailing list by clicking the button below.</p>' "$f"
  ! grep -qE 'confirmSubTitle|<h1|confirmSubWelcome|confirmSubInfo|confirmSubHelp|range \$i, \$l := \.Lists' "$f"
}

@test "the opt-in email greets by the address alone, up to any +tag" {
  # This email goes to an address before anyone has confirmed owning it, so
  # it prints nothing the signup's sender chose: no stored name, no +tag.
  f="$STATIC/email-templates/subscriber-optin.html"
  grep -qF '>Hello {{ regexFind "^[^@+]+" .Subscriber.Email }},</p>' "$f"
  ! grep -qE 'Subscriber\.(Name|FirstName|LastName)' "$f"
}

@test "a signup's result reads the same for every address, and other messages stay listmonk's" {
  # listmonk words the result by the address's state; one reply keeps that
  # state private. "public.subTitle" is the title of that page alone.
  f="$STATIC/public/templates/message.html"
  grep -qF '{{ if eq .Data.Title (L.T "public.subTitle") }}Thank you. If this address still needs confirming, an email is on its way.{{ else }}{{ .Data.Message }}{{ end }}' "$f"
  [ "$(grep -c '\.Data\.Message' "$f")" -eq 1 ]
}

@test "the emails' colors are the site's paper palette, written out" {
  # Mail clients don't support CSS variables, so the light theme's tokens
  # (cmon1975.com site/book.css, body.theme-light) appear as hex: paper,
  # ink, ink-strong, muted, rule. Light, because a dark email turns
  # unreadable in clients that invert colors for their dark mode.
  colors="$(grep -ohi '#[0-9a-f]\{6\}\b' "$STATIC"/email-templates/*.html | tr 'A-F' 'a-f' | sort -u)"
  [ -n "$colors" ]
  while read -r c; do
    case "$c" in
      '#f9f6f0'|'#2b2723'|'#15130f'|'#6e665a'|'#cdc4b4') ;;
      *) echo "off-palette $c"; return 1 ;;
    esac
  done <<<"$colors"
}
