<div align="center">

# 📣 Banner

**Advertise your raid to chat channels.**

![Version](https://img.shields.io/badge/version-1.3.2-blue)
![Game](https://img.shields.io/badge/WoW_WotLK-3.3.5a-8a2be2)
![Lua](https://img.shields.io/badge/Lua-5.1-2C2D72?logo=lua&logoColor=white)
![Dependencies](https://img.shields.io/badge/dependencies-none-3fb950)

</div>

Banner is a recruitment ("LFM") broadcasting addon for **World of Warcraft: Wrath of the Lich King 3.3.5a**. Configure your raid once — instance, specs you need, minimum GearScore, reserves — and Banner posts a tidy, length-aware message to your chat channels on a fixed interval, then stops by itself once your group is full.

## Features

- **Every raid built in** — Classic, Burning Crusade and Wrath of the Lich King, from Molten Core to Ruby Sanctum, with the right sizes (and heroic variants where they exist)
- **Single instance + custom text** — pick one raid and add any text after its name (e.g. `ICC25 8/12 fresh`)
- **Class & spec picker** — 31 specs across 10 classes, with role quick-select (Tanks, Healers, Melee, Ranged) and per-class toggles
- **Any target** — broadcast to every joined chat channel, plus Say and Yell
- **GearScore filter** — advertise a minimum GS with one field
- **Reserves** — a comma-separated list; pasted `[Name]` links are cleaned up for you
- **Auto-stop** — broadcasting ends the moment your group reaches a chosen size
- **Throttled queue** — messages are sent one at a time with a short delay to stay under server limits
- **Live preview** — see exactly what will be posted, before you post it
- **ElvUI skin** — optionally blends into your ElvUI theme

## Installation

1. Copy the `Banner` folder into your client's addon directory:
   - Windows: `World of Warcraft\Interface\AddOns\`
   - macOS: `World of Warcraft/Interface/AddOns/`
2. Make sure `Interface/AddOns/Banner/Banner.toc` exists.
3. Start the game — or `/reload` if it was already running.

> [!IMPORTANT]
> Banner targets the WotLK **3.3.5a** client only (Interface 30300). It is built on the classic 3.3.5 API and will not load on retail or modern clients. It has no external library dependencies.

## Getting started

1. Type `/banner` to open the config window.
2. Pick an **instance**, the **specs** you need, and your target **channels**.
3. Fill in the optional fields: instance text, minimum GearScore, reserves, extra note.
4. Hit **Start** — or **Send once** for a single round.

> [!TIP]
> Join the LFM channel first (`/join LookingForGroup`) so it appears in the channel picker.

### Configuring the message

| Field | What it does |
| --- | --- |
| **Instances** | Nested dropdown menus — e.g. *ICC → 25-man Heroic*. Only one instance can be selected. |
| **Text** | Free-form text appended right after the instance name, e.g. `ICC25 8/12 fresh`. |
| **Specs** | Side panel with one row per class and one checkbox per spec. Ticking a class selects all of its specs; quick buttons for All / None / Tanks / Healers / Melee / Ranged. |
| **Channels** | Side panel listing every channel you've joined, plus Say and Yell. Channels you've since left stay remembered, greyed out. |
| **Min GS** | Adds a `GS 5500+` section to the message. |
| **Stop at size** | Stop broadcasting when your group reaches this size (`0` = off). |
| **Reserves** | Comma-separated names — a long list wraps onto the next message line. |
| **Extra note** | Free-form text appended at the end. |
| **Interval** | Slider, 10–300 seconds between rounds (default 60). |
| **Preview** | Live preview of the exact message(s). |

### What gets posted

A short selection fits on one line:

```
LFM ICC25H 8/12 fresh - Need: Prot Warr, Holy Pally, BM Hunter - GS 5500+ - Reserves: Frag, Frost - \w Ashvane
```

With more specs and reserves, the message wraps onto extra lines at item boundaries:

```
LFM ICC25H 8/12 fresh - Need: Prot Warr, Holy Pally, Prot Pally, BM Hunter, MM Hunter, Disc Priest, Blood DK, Ele Shaman, Arcane Mage, Fire Mage, Aff Lock, Destro Lock, Balance Druid, Resto Druid - GS 5500+ - Reserves: Frag, Frost
Blackice - \w Ashvane
```

A few things to know about the output:

- Fully selected classes collapse to `Any Warrior`, and everything selected to a single `All classes/specs`.
- The trailing `\w <name>` contact line (whisper shorthand) is always appended with your character name.

> [!NOTE]
> Chat messages are limited to 255 bytes. Banner packs the content into lines of at most 250 bytes and never splits a single item across lines, so nothing gets garbled mid-word.

## Slash commands

| Command | Action |
| --- | --- |
| `/banner` (or `show`, `config`) | Toggle the config window |
| `/banner start` / `stop` | Start / stop broadcasting |
| `/banner toggle` | Switch between started and stopped |
| `/banner now` | Send one round immediately, without touching the schedule |
| `/banner preview` | Print the current message(s) to your chat |
| `/banner skin` | Toggle the ElvUI skin (apply with `/reload`) |

## Broadcasting engine

- One **round** posts the same message to every selected target.
- Individual chat messages are queued and sent **1.5 seconds apart** so the server doesn't throttle them.
- Rounds repeat on your chosen interval — never faster than every 10 seconds.
- The **Stop at size** threshold is checked on live roster updates; once your group is full, Banner stops by itself and tells you.
- If none of the selected channels are joined, you get a hint (`/join LookingForGroup`) and broadcasting stops.

## ElvUI skin

When ElvUI is loaded, the window and panels are skinned automatically — transparent template, matched buttons, checkboxes and sliders. If you'd rather keep the default Blizzard look, type `/banner skin` then `/reload`. Every skin call is guarded, so a differing ElvUI build can never break the addon.

## Settings

Options are saved in the `BannerDB` SavedVariable and shared by all characters on the account. Defaults are filled in automatically on load, so a fresh install just works.

## Project layout

```
Banner/
├── Banner.toc        Addon manifest
├── Data.lua          Static raid, class and spec data
├── Core.lua          Message building, scheduling, slash commands
├── UI.lua            Config window
├── SpecGrid.lua      Classes & specs side panel
├── ChannelGrid.lua   Channels side panel
└── Skin.lua          Optional ElvUI skin
```