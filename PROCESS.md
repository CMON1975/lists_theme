# PROCESS.md
Running log of work done with Claude Code.

---
## 2026-11-21 — Center the Altcha box over the Subscribe button
**What:** `.captcha .altcha { margin: 0 auto; }` centers listmonk's Altcha widget box over the signup form's button at its own width (8feb501, test tidied in 3e884a9). The user approved Edge shots at 1280 and 375px; cmon1975dotcom deployed it 2026-11-22.
**Why:** cmon1975dotcom turned on Altcha against a signup bot, and the box sat at the column's left under a centered button.
**Notes:**
- listmonk 6.2.0's Altcha widget uses no shadow DOM: `<altcha-widget>` is inline, and `.altcha` inside it is a flex block with `max-width: 260px`. Flex or `text-align` on `.captcha` would shrink the box or center its label, so the margins go on `.altcha` itself. That class is the widget's own: recheck it on a listmonk bump.
- Measured from the shots, the box went from 129px (1280) and 34.5px (375) left of the button's center to 0 and +0.5, at 256px both times.
- Shots: headless Edge on windows-11 won't size a window under 500px, so the 375 shot is the page in a 375px iframe, cropped. The recipe is in cmon1975dotcom's `HANDOFF.md` reference section and its PROCESS.md.
- Not changed: the widget's own grey border and red error text, off the `--book-*` palette. Raised with the user.

---
## 2026-11-22 — Opt-in page asks for the click
**What:** The opt-in page's "You have been added to the following lists:" is now the owner's "Click the button below to be added to the following list:" (e55ce98). Shots at 1280 and 375px are `E:\claude_review\lists_theme-optin-wording.png` and `lists_theme-optin-wording-375.png`, waiting for the user's OK.
**Why:** The user signed up on prod on 2026-11-21. The page said they were already added, though nothing happens until its button confirms.
**Notes:**
- Shot against local subscriber 8 (`preview@example.invalid`), by GET only. The subscriber stays unconfirmed, so the page can be shot again.
- Other plural "list" wording a one-list reader can meet, reported to the user and left as it is:
  - preferences: the "Lists" heading and "Uncheck lists to unsubscribe from them.";
  - "Your subscriptions and all associated data has been removed.", after a data wipe;
  - "No valid lists selected to subscribe.", an error.
- The signup reply (the theme's own sentence), "Subscribed successfully." and the unsubscribe page are singular already.

---
## 2026-11-22 — Opt-in page names the list
**What:** The user reworded the line to "Click the button below to join the CMON1975 mailing list:" and chose to drop the list's name under it, since the sentence names the list (6377a86). The lists still post back hidden. Shots: `E:\claude_review\lists_theme-optin-wording-2.png` and `lists_theme-optin-wording-375-2.png`, waiting for the user's OK.
**Why:** With the list named in the sentence, the separate "CMON1975" line said the name twice.

---
## 2026-11-22 — Preferences page in the singular; Altcha box in the theme's look
**What:**
- The preferences page's "Lists" / "Uncheck lists to unsubscribe from them." now reads "Mailing list" / "Uncheck the box below to unsubscribe from the CMON1975 mailing list." (8cb5a5a).
- The Altcha box is now drawn like the fields, through Altcha's own `--altcha-*` properties on `.captcha` (5069e07): the `--book-rule` border, a `--book-muted` focus border, square corners, and its error line in `--book-ink-strong` italic like `.error`.
- A `css_decls` helper in theme.bats now serves both captcha tests (6405de2).
- Shots in `E:\claude_review\`: `lists_theme-altcha-themed{,-375,-error}.png` and `lists_theme-prefs-wording{,-375}.png`. They wait for the user's OK.
**Why:** The user asked to fix the plural wording and to bring the widget into the theme ("do what's necessary to sync theme").
**Notes:**
- Left out: "Your subscriptions and all associated data has been removed." Prod's settings.json turns off wipe and export, so that form and its message never show.
- Only three of Altcha's colors can show in listmonk's inline widget: border, focus border and error text. The rest follow currentColor or belong to modes listmonk doesn't use (floating, overlay, code challenge).
- The error-state shot came from a scratch copy of `static/` with `mockerror auto="onload"` on the widget, served through listmonk-dev's `LISTMONK_STATIC_DIR`.
- Bash `-e` gotcha in bats: in `a || { b && c; }`, a failing `b` doesn't fail the test. The refactor's mutation check caught this, and the test now uses a single `[ … ]` after the `||`.

---
## 2026-11-22 — Preferences line in the owner's words
**What:** The preferences page's line is now the user's "Uncheck the box below and press the save button to unsubscribe." Shots: `E:\claude_review\lists_theme-prefs-wording-2.png` and `lists_theme-prefs-wording-375-2.png`, waiting for the user's OK alongside the Altcha ones.
**Why:** The earlier line left "list." alone on a second line at desktop width, and it didn't say that unchecking needs Save.
