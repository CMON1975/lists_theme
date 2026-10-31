# lists_theme

The look of the CMON1975 mailing list at [lists.cmon1975.com](https://lists.cmon1975.com), which runs [listmonk](https://listmonk.app). This repo holds the replacement page templates, stylesheet and email templates. They match the subscription pages and the opt-in email to [cmon1975.com](https://cmon1975.com).

Most of these files are modified copies of listmonk's own templates. Like listmonk, they're licensed under the GNU Affero General Public License v3 (see `LICENSE`). This public repo is the source the pages' footer links to.

## How listmonk loads it

listmonk is started with `--static-dir` pointing at `static/`. Any file found there replaces listmonk's built-in copy of the same name, and every other file keeps listmonk's default. listmonk reads these files only at startup, so a change shows after a restart or an app reload.

- `static/public/templates/`: the public pages (signup form, opt-in confirmation, unsubscribe and preferences, messages) and the layout they share.
- `static/public/static/`: the stylesheet and anything it loads.
- `static/email-templates/`: the opt-in email and the frame around listmonk's system emails.

## Upstream originals

`upstream/<version>/` holds listmonk's original copies of the files a theme can replace, as shipped in that release. `LISTMONK_VERSION` names the release the theme is written against.

To move to a new listmonk release:

1. Import its originals with `bin/import-upstream NEW_VERSION path/to/listmonk`.
2. Read `diff -r upstream/OLD upstream/NEW` and carry each change over to the matching file in `static/`.
3. Update `LISTMONK_VERSION`.

## Tests

```
bats tests
```
