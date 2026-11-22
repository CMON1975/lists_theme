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
