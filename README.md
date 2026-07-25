<h3 align="center">
	<img src="https://raw.githubusercontent.com/catppuccin/catppuccin/main/assets/logos/exports/1544x1544_circle.png" width="100" alt="Logo"/><br/>
	<img src="https://raw.githubusercontent.com/catppuccin/catppuccin/main/assets/misc/transparent.png" height="30" width="0px"/>
	Catppuccin for <a href="https://steambrew.app/">Millennium</a>
	<img src="https://raw.githubusercontent.com/catppuccin/catppuccin/main/assets/misc/transparent.png" height="30" width="0px"/>
</h3>

<p align="center">
	<a href="https://github.com/yusufaf/catppuccin-millennium/stargazers"><img src="https://img.shields.io/github/stars/yusufaf/catppuccin-millennium?colorA=363a4f&colorB=b7bdf8&style=for-the-badge"></a>
	<a href="https://github.com/yusufaf/catppuccin-millennium/issues"><img src="https://img.shields.io/github/issues/yusufaf/catppuccin-millennium?colorA=363a4f&colorB=f5a97f&style=for-the-badge"></a>
	<a href="https://github.com/yusufaf/catppuccin-millennium/contributors"><img src="https://img.shields.io/github/contributors/yusufaf/catppuccin-millennium?colorA=363a4f&colorB=a6da95&style=for-the-badge"></a>
</p>

Soothing pastel theme for the **Steam desktop client**, built for the
[Millennium](https://steambrew.app/) modding framework. All four flavors and
all fourteen accents, switchable from Steam's own settings.

> [!WARNING]
> **Early work in progress.** The library, window shell, dialogs and controls
> are themed. Context menus, the friends list and chat, notification toasts,
> the downloads page and Big Picture Mode are **not** themed yet. Screenshots
> are pending. See [Status](#status).

## Requirements

- [Millennium](https://steambrew.app/) installed
- Steam on Windows or Linux

## Installation

There is no published release yet. To try the current state:

```bash
# Windows
git clone https://github.com/yusufaf/catppuccin-millennium "$(gp 'HKLM:\SOFTWARE\Wow6432Node\Valve\Steam' | % InstallPath)\millennium\themes\Catppuccin"

# Linux
git clone https://github.com/yusufaf/catppuccin-millennium ~/.steam/steam/millennium/themes/Catppuccin
```

Then pick **Catppuccin** in Steam → Settings → Themes.

## Usage

Under **Settings → Themes → Catppuccin**, the *Appearance* tab exposes:

- **Flavor** — Latte, Frappé, Macchiato, Mocha (default: Mocha)
- **Accent** — all fourteen accent colors (default: Mauve)

Steam's green stays green where it carries meaning: installed and ready to
play, positive review sentiment, discounts. The accent is used for selection,
links, focus and primary actions.

## Status

| Area | State |
| --- | --- |
| Window shell, titlebar, window controls | themed |
| Library: sidebar, shelves, game pages, selection | themed |
| Dialogs, buttons, inputs, dropdowns | themed |
| Store & Community web views | first pass, needs verification |
| Context menus, modals | partial |
| Friends list, chat, notification toasts | not started |
| Downloads page, game properties | not started |
| Big Picture Mode | not started (tokens only) |

## Known issues

- **Changing flavor does not update the Store and Community pages until Steam
  is fully restarted.** Millennium registers its web-view hooks once and
  `Core_ChangeCondition` writes config without propagating the change, so those
  views keep the flavor that was active at startup. The client itself updates
  immediately.
- Latte needs more contrast work outside the library — Steam hardcodes
  near-white text in many places, which only breaks visibly on a light flavor.
- Rules that target Steam's generated class names will break when Steam
  regenerates them. Each such rule records the color it replaces, so re-mapping
  after a Steam update is mechanical. Verified against the July 2026 client
  (Chrome 126).

## Development

Palette CSS is generated from the official palette with
[whiskers](https://github.com/catppuccin/whiskers); do not edit
`src/flavors/` or `src/accents/` by hand.

```bash
just build      # regenerate flavor + accent CSS
```

Everything else is hand-written vanilla CSS. Layout:

```
libraryroot.custom.css   entrypoint: main window, menus, modals, toasts
friends.custom.css       entrypoint: friends list and chat
webkit.css               entrypoint: store and community web views
bigpicture.custom.css    entrypoint: Big Picture (tokens only for now)
src/core/                tokens, base, surfaces, controls, text, Steam color remap
src/client/              shell, library
src/webkit/              store and community
```

Two rules keep flavor switching working:

1. Only `src/flavors/` and `src/accents/` may **define** `--ctp-*` palette
   variables. Everything else consumes them as `var(--ctp-x, #fallback)`.
   Millennium injects condition CSS *before* patch CSS, so a redefinition
   elsewhere would silently override the flavor dropdown.
2. Steam pairs a generated class with each readable one, so plain selectors
   lose on specificity. Repeat the class name instead of reaching for
   `!important`.

To iterate: launch Steam with `-dev`, then after each CSS edit run
`SteamClient.Browser.RestartJSContext()` from the `SharedJSContext` target at
`http://127.0.0.1:8080`. A plain `location.reload()` brings the window back
**unthemed** — Millennium only injects on window creation.

## 💝 Thanks to

- [tkashkin](https://github.com/tkashkin) for
  [Adwaita-for-Steam](https://github.com/tkashkin/Adwaita-for-Steam), the
  clearest reference for how a Millennium theme is structured
- The [Millennium](https://github.com/SteamClientHomebrew/Millennium) team

&nbsp;

<p align="center">
	<img src="https://raw.githubusercontent.com/catppuccin/catppuccin/main/assets/footers/gray0_ctp_on_line.svg?sanitize=true" />
</p>

<p align="center">
	Copyright &copy; 2021-present <a href="https://github.com/catppuccin" target="_blank">Catppuccin Org</a>
</p>

<p align="center">
	<a href="https://github.com/catppuccin/catppuccin/blob/main/LICENSE"><img src="https://img.shields.io/static/v1.svg?style=for-the-badge&label=License&message=MIT&logoColor=d9e0ee&colorA=363a4f&colorB=b7bdf8"/></a>
</p>
