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
