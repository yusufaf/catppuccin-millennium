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

1. **To apply a CSS edit:** evaluate `SteamClient.Browser.RestartJSContext()` in
   the `SharedJSContext` target — *if you have CDP*, which you probably do not;
   see below. **Never `location.reload()`** — Millennium injects only on window
   *creation*, so a reload returns the window completely unthemed and looks like
   your CSS broke. Without CDP, restart Steam.
2. `skin.json` changes need a full Steam restart.

### CDP is gone as of the August 2026 client — read this first

The recon workflow below was built against a Steam client whose CEF was
Chrome 126 and which served DevTools over TCP on `http://127.0.0.1:8080`.
**That endpoint no longer exists.** Verified on 2026-08-08 against client
buildid 1785799196 (CEF **Chrome 146**):

- `steamwebhelper` is launched with **both** `--remote-debugging-pipe` and
  `--remote-debugging-port=8080`. Modern Chromium serves DevTools over the pipe
  and never binds the TCP listener.
- Nothing listens on 8080 (`netstat`), and a sweep of every localhost listener
  found no Steam CDP endpoint at all.
- Creating the `.cef-enable-remote-debugging` marker in the Steam root *does*
  work — the flag appears in the command line — but has no effect, because the
  pipe wins.
- Launching with `-dev` does not change this.
- Millennium is unaffected: it injects in-process via `millennium.dll`, which
  is why the theme still renders normally.

So the five scans below cannot be run. **Do not spend time trying to get 8080
to answer.** If a future Steam or Millennium build restores a TCP endpoint,
the scans are still the better method and this section should be revisited.

### Working without CDP: Steam ships its CSS on disk

Steam's real stylesheets live in `<Steam>/steamui/css/`, chiefly a ~4.7 MB
`chunk~2dcc5aaf7.css` plus `library.css`. They contain every class name the
client uses **and the colour each one sets**, which is a better source for
building a durable class→colour map than scraping the DOM ever was. What it
cannot give you: which classes are actually present in a given window, and any
live contrast measurement. Those now depend on the user's screenshots.

The files are minified onto a handful of enormous lines, so ripgrep alone is
useless — you need something that walks brace depth to recover whole rules.
Note that Steam's bundle genuinely repeats identical rules (one was emitted 11
times), so dedupe before reading, and filter out the `GamepadMode` /
`SteamDeck` / `QuickAccess-Menu` variants, which are Big Picture.

Useful check that replaces "does this selector exist": extract every class from
a rule file and grep each against the bundle. All 58 in `src/client/friends.css`
were confirmed this way, as were every hashed class in `src/core/text.css` —
the Chrome 146 update did **not** regenerate Steam's hashed names.

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

## Queued work

Tracked as GitHub issues and milestones, not here — the milestones are
`v0.2.0` (remaining client surfaces), `v0.3.0` (Latte parity), `v1.0.0` (org
submission), `Big Picture Mode`, and `Housekeeping`. Check
`gh issue list --milestone <name>` or the repo's Issues tab rather than this
file for what's next and its current status.

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
