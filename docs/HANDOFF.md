# Handoff — next round of work

Working notes for whoever picks this up next (human or agent). User-facing status
lives in [`README.md`](../README.md); this file covers how to work on the theme
and what is queued, without repeating it.

There is also a longer planning document kept **outside** the repo (architecture,
the Millennium mechanics verified against Millennium's own source, milestones
M0–M7). If you don't have it, the README plus this file are enough to continue.

State: M0/M1 complete, M2 partly complete. Goal is eventual transfer to the
`catppuccin` org as `catppuccin/millennium`.

---

## Environment — get this working before anything else

Install the theme by **junctioning** (or symlinking) this checkout into
`<Steam>/millennium/themes/Catppuccin`, so edits are live with no copy step.
On Windows a junction needs no admin rights:

```powershell
New-Item -ItemType Junction -Path "$steam\millennium\themes\Catppuccin" -Target <repo>
```

1. Steam must run with `-dev`, which exposes CDP on `http://127.0.0.1:8080`.
   Check `curl -s http://127.0.0.1:8080/json/version` before anything else.
2. **To apply a CSS edit:** evaluate `SteamClient.Browser.RestartJSContext()` in
   the `SharedJSContext` target. **Never `location.reload()`** — Millennium
   injects only on window *creation*, so a reload returns the window completely
   unthemed and looks like your CSS broke.
3. `skin.json` changes need a full Steam restart.

### CDP driver

A ~60-line Node script (Node 21+ has a built-in `WebSocket`) that runs
`Runtime.evaluate` against a named target is enough. Non-obvious details, each
learned the hard way:

- Match targets by **exact title** (`Steam`, `SharedJSContext`), not by URL
  substring — the string `Steam` appears inside unrelated target URLs.
- After a JS-context restart Steam leaves **detached documents** behind that
  accept a socket and then never reply. Try candidates newest-first with a short
  (~4s) timeout and move on to the next.
- Always close the socket in a `finally`, or the process hangs after a failed
  candidate.
- `Page.captureScreenshot` **does not work** on Steam's CEF targets. You cannot
  see the UI. Ask the user for screenshots, and don't claim a visual result you
  haven't had confirmed.

### Recon scripts

The workflow that actually worked: scan the live DOM for what still looks like
Steam, fix it, restart the JS context, scan again. Five scans carried the work:

| Scan | What it does | Why |
| --- | --- | --- |
| painted surfaces | every element with area > 12000 that paints a background, largest first | finds what dominates the screen |
| solid accents | `color` / `backgroundColor` / `border*` / `fill` / `stroke` that is blue-ish or green-ish | Steam's hardcoded brand colours |
| gradients | same, against `background-image` | install button, titlebar highlight and detail cards are gradients; a solid scan misses them entirely |
| light text | elements with a direct text node whose colour luminance > 0.6 | the Latte checker |
| contrast | WCAG ratio against the first opaque ancestor background, report < 4.5:1 | catches unreadable combinations |

The contrast scan cannot see background *images*, so text over artwork yields
false positives — one account label reporting 1.59:1 is believed to be exactly
this. Confirm visually before chasing.

---

## Queued work, highest value first

### 1. Verify the store/community pass on Latte
`src/webkit/store.css` was written against the live store markup, but its
**colours have never been verified** because of the bug in item 2. It also never
received the text remapping `src/core/text.css` does for the client, so expect
the same white-on-light failures Latte had.

Fully restart Steam, open the Store tab, then run the light-text and contrast
scans against the `store.steampowered.com` target.

### 2. Millennium bug: flavor changes don't reach web views
Confirmed live — the client rendered Latte while the store webview was still
loading `src/flavors/mocha.css`. `Core_ChangeCondition` writes config with
`skipPropagation=true`, so `theme_cfg.cc::on_config_change_hdlr` never re-runs
`add_conditional_data` and the webkit hooks keep whichever flavor was active at
startup. Client windows re-evaluate conditions on every window creation, so they
update immediately.

Worth an upstream issue on `SteamClientHomebrew/Millennium`. Until it is fixed,
**always restart Steam fully before judging a web view.**

### 3. Unthemed areas
Friends list and chat (`friends.custom.css` is tokens-only), notification toasts,
context menus, downloads page, game properties dialog. Each needs the user to
open that surface so it exists as a DOM target to inspect.

### 4. Latte contrast outside the library
Same method as `src/core/text.css`. Steam hardcodes near-white text assuming a
dark surface behind it; the dark flavors hide this, Latte exposes it. Known
remaining: active nav tab at 4.09:1 and the URL bar at 4.13:1 — both clear the
3:1 large-text bar but sit under the 4.5:1 body-text bar.

### 5. Assets and release
`assets/` contains only `.gitkeep`, yet `skin.json` already points
`header_image` / `splash_image` at `assets/preview.webp` and
`assets/mocha.webp` — **both currently 404**. Needs real screenshots plus a
[catwalk](https://github.com/catppuccin/catwalk) four-flavor composite before any
submission to Millennium or the Catppuccin org.

### 6. Extras tweaks
Opt-in checkboxes: accent play button, rounded corners, coloured game-state text,
hide What's New shelf. Not started — there is no `src/tweaks/` yet. Note that
condition **names are the storage key**: renaming one resets every user to the
default, so freeze the names before v1.0.0.

### 7. Small known holdouts
An SVG icon still at `#09b9ff` whose fill comes from markup rather than a class,
so it needs a different hook; and one shelf badge.

---

## Conventions that must not be broken

1. Only `src/flavors/` and `src/accents/` may **define** `--ctp-*` palette
   variables. Everything else consumes them as `var(--ctp-x, #fallback)`.
   Millennium injects condition CSS *before* patch CSS, so a redefinition
   anywhere else silently overrides the flavor dropdown. Grep before committing.
2. Steam pairs a generated class with each readable one, so a plain selector
   loses on specificity regardless of load order. **Repeat the class name**
   (`.Foo.Foo`, or `.Foo.Foo.Foo` where a parent state class is involved) rather
   than reaching for `!important`.
3. Rules that target generated class names record the colour they replace in a
   comment. Keep doing this — it is what makes a re-map after a Steam client
   update mechanical rather than a hunt.
4. `metadata.json` is written by Millennium into the installed theme folder and
   is gitignored. Don't commit it.

## Two mistakes already made — don't repeat them

- A class was labelled "selected game row" and painted with the accent. Steam
  also reuses it for **notification toasts**, so the toast became dark text on a
  dark accent at 1.47:1. Before assuming what a generated class is for, check
  every element carrying it.
- Accenting *every* navigation tab flattened the active/inactive distinction
  Steam encodes with colour. Preserve the information design; don't just
  recolour what you find.

## Working style

Verify with measurements rather than assumptions — every claim made so far was
backed by a computed-style read over CDP. State plainly what is unverified. The
user reviews by screenshot, so ask for one after visible changes; "that's
expected" is not an acceptable answer when nothing visibly changed.
