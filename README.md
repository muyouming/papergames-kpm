# PaperGames for Kindle (KPM)

Offline [PaperGames](https://yourchaoschris.github.io/PaperGames/) as a Kindle package:
103 classic board, card and puzzle games, served from a tiny local HTTP server and
opened in the stock Kindle browser.

No internet connection is needed after installation.

## Requirements

- A jailbroken Kindle on the **hdnext / KMC** stack with **KPM** installed
- A `kindlehf` device with the Chromium-based browser (firmware 5.16.4+)
- ~25 MB free space on the user partition

Tested on a Kindle Scribe (2022, firmware 5.20.1).

## Install

```sh
kpm add-repo https://muyouming.github.io/papergames-kpm/manifest.v2.json
kpm update
kpm install papergames
```

Then open **PaperGames** from your library.

## How it works

- The package installs the site to `/mnt/us/PaperGames`
- A bundled LuaJIT + LuaSocket server listens on `127.0.0.1:8080`
- The library tile starts the server and navigates the stock browser to it
- The server is started on demand, not at boot

Pressing Back in the browser returns to the Kindle UI; the local server stays
running in the background (a few MB of RAM) and is reused on the next launch.

## Uninstall

```sh
kpm uninstall papergames
```

This removes `/mnt/us/PaperGames`, the library tile, and stops the local server.

## Package contents

| Path | Purpose |
|---|---|
| `site/` | PaperGames site (HTML/CSS/JS, 103 games) |
| `runtime/` | LuaJIT 2.1 + LuaSocket 3.1 + libstdc++ |
| `server.lua` | Minimal static HTTP server |
| `scriptlets/PaperGames.sh` | Library launcher (with cover icon) |
| `install.sh` / `uninstall.sh` / `launch.sh` | KPM hooks |

## Local changes vs upstream

- `confirm-actions.js`: `window.confirm()` is not implemented in the Kindle
  browser (it returns `false` without showing a dialog), which silently blocked
  "Two players, one device" and "New game" while a game was running. The prompts
  now use an in-page modal.
- `sw-register.js`: service worker registration is disabled. The site is served
  locally and SW precaching caused request stampedes on a single-threaded server.

## Credits & licenses

- PaperGames by Chris — <https://yourchaoschris.github.io/PaperGames/>,
  PolyForm Noncommercial 1.0.0 (see `site/LICENSE` in the package).
- LuaJIT — Mike Pall, MIT.
- LuaSocket — Diego Nehab, MIT.
- libstdc++ runtime — GPLv3 + GCC Runtime Library Exception.
- Package hooks and server — MIT.

This is an unofficial repackage for personal offline use; not affiliated with
Amazon or the PaperGames author.
