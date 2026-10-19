# Maverickgram

Maverickgram is an independent fork of
[Telegraphica](https://github.com/MiChiRose/telegraphica) for Intel Macs running
OS X 10.8 through macOS 10.13, with OS X 10.9.5 Mavericks as the primary target.
It keeps the native Objective-C/AppKit and TDLib architecture while using its
own application identity, local-data directories, Keychain namespace and
release channel.

The fork is under active development. Until Maverickgram publishes its own
signed release artifacts, build from `develop`; do not install Telegraphica
updates over a Maverickgram application bundle.

The original implementation and product groundwork are © Yura Menschikov and
the Telegraphica contributors. Maverickgram preserves the upstream licensing
and third-party notices.

## Upstream documentation

## Telegraphica upstream documentation snapshot

<div align="center">
  <img src="readme-assets/app-icon.png" alt="Telegraphica app icon" width="120" />
  <p><b>For the Intel Macs that still have plenty of life left in them.</b></p>
  <p>OS X 10.8–macOS 10.13 · Objective-C · Cocoa/AppKit · TDLib</p>
  <p>
    <img src="https://img.shields.io/badge/version-v0.6.1-blue" alt="version v0.6.1" />
    <img src="https://img.shields.io/badge/status-open%20beta-brightgreen" alt="open beta" />
    <img src="https://img.shields.io/badge/architecture-Intel%20x86__64-lightgrey" alt="Intel x86_64" />
    <img src="https://img.shields.io/badge/no-Electron-success" alt="no Electron" />
  </p>
  <p>
    <a href="https://github.com/MiChiRose/telegraphica/releases/latest"><b>Download Telegraphica</b></a>
    · <a href="https://t.me/macos_telegraphica">Development news on Telegram</a>
    · <a href="https://github.com/MiChiRose/telegraphica/issues">Report an issue</a>
  </p>
</div>

Telegraphica is an unofficial Telegram client built for **OS X 10.8 Mountain
Lion through macOS 10.13 High Sierra on Intel Macs**. It uses native AppKit
windows and TDLib, with no Electron or embedded browser.

You can read and send messages, use folders and forum topics, browse media,
handle downloads and keep a Telegram session on an older Mac. It is an open
beta: useful for everyday conversations, with rough edges still being worked
on. It is not affiliated with Telegram.

## New in 0.6.1: refining Aqua

This update follows the first Aqua release with fixes from everyday use on an
older Mac. I worked through the smaller windows as well as the main conversation
view, making controls, spacing and navigation more consistent.

- Return reliably from folders and forum topics to All Chats; mark individual
  topics as read and show administrative actions only when permitted.
- Cleaner message footers: aligned times and read receipts, pin placement and
  available view counts. Pin and mute markers keep fixed columns in chat lists.
- Chat search stays attached to the toolbar, with a compact results list.
- A simpler attachment preview gives multiline captions a scrollable editor.
- Refined folders, notifications, profile editing, privacy/storage, location,
  people lists, contacts, calls, sessions, bot dialogs and downloads.
- Media thumbnails have less surrounding chrome; profile categories switch to
  a dropdown when the tabs would not fit. Shared actions use consistent icons.
- Fixes for the history spinner, narrow-window layouts and temporary button
  states. Saved Messages no longer offers calls to yourself.

[Full 0.6.1 release notes](docs/releases/v0.6.1.md)

## Aqua, introduced in 0.6.0

I spent a long time rethinking Telegraphica's interface for this update.
Reading magazines, watching old films and visiting a museum of art and
architecture made me pay more attention to materials, light and small details.
I kept coming back to the interfaces I loved on older Apple devices: Mac OS X
10.7–10.9, the iPod Classic and early iPhones.

Aqua grew out of that: textured metal, glossy blue controls, inset panels and
an interface that feels at home on an older Mac. I am proud of how far its
visual design has come, and I want to keep refining it.

Aqua includes:

- A top navigation toolbar, account menu and chat search.
- An animated folder drawer beside the main window, with an internal list
  when there is not enough screen space.
- Local chat backgrounds: colors, textures, five bundled wallpapers or your
  own image, cropped to fill without stretching. No Premium is required.
- Compact sticker and download panels beside the conversation.
- A dark photo viewer with gallery navigation, zoom and reset controls.
- Refined audio playback, profiles, media browsing, recording windows and
  scheduling dialogs.

### How to enable Aqua

1. Install **Telegraphica 0.6.0** or newer.
2. Open **Settings → Appearance**.
3. Choose **Aqua** in the **Interface** dropdown.
4. Confirm the change. Telegraphica closes and reopens automatically.

In Russian: **Настройки → Оформление → Интерфейс → Aqua**.

Choose **Classic** in the same dropdown to return to the previous interface.
Classic themes and Workshop remain available, and your Classic theme is kept.
Aqua is optional; an installation without a saved choice starts in Classic.

The update also improves theme contrast, read receipts, reaction placement,
muted-chat notifications and button states. Reactions stay below message text.
Scheduling is available by **right-clicking Send → Send on schedule…**; the
same menu opens that chat's scheduled messages.

[Full 0.6.0 release notes](docs/releases/v0.6.0.md)

## Download and install

One application covers the complete supported range: **OS X 10.8–macOS 10.13,
Intel `x86_64`**. There are no separate Mountain Lion and Mavericks downloads.

| Download | Use it for |
| --- | --- |
| [0.6.1 DMG installer](https://github.com/MiChiRose/telegraphica/releases/download/v0.6.1/Telegraphica-v0.6.1-macos10.8-10.13-x86_64.dmg) | Normal installation: drag Telegraphica into Applications. |
| [0.6.1 application ZIP](https://github.com/MiChiRose/telegraphica/releases/download/v0.6.1/Telegraphica-v0.6.1-macos10.8-10.13-x86_64.app.zip) | Manual transfer of the same application bundle. |
| [All releases and SHA-256 files](https://github.com/MiChiRose/telegraphica/releases) | Earlier versions, release notes and checksum verification. |

**Updating:** quit Telegraphica before replacing the application. Keep its
Application Support folder; you do not need to delete your session or settings.
Copy any important unsent text before restarting: draft restoration across an
application restart remains a known issue in 0.6.1.

**First installation:** open the DMG, drag Telegraphica into Applications and
launch it. The public build includes the connection bootstrap, so you do not
need to obtain Telegram API credentials. Follow the phone/code/2FA flow, or use
QR login where the loaded TDLib supports it.

The application is distributed directly and is not notarized. If macOS blocks
first launch, Control-click the app and choose **Open**.

### Finding the next update

While running, Telegraphica checks the update server once an hour. A new
version adds an update indicator in Settings; background checks do not open a
popup or install anything automatically. Use **Settings → Check for updates**
to check immediately and see the download prompt.

The update manifest and download proxy are served through the project's
Cloudflare Worker; release packages are published on GitHub Releases.

## What you can do

### Conversations

- Private chats, groups, channels, secret chats and forum topics.
- Text and multiline messages, formatting, replies, forwarding and reactions.
- Silent, scheduled and send-when-online messages where supported by TDLib.
- Chat search and message search, with sender/date filters and result navigation.
- Pinned chats, archives, typing indicators, unread markers and read receipts.
- Telegram chat folders, editing and ordering; shared-folder and invite-link
  workflows on capable TDLib runtimes.

### Media and downloads

- Photos with preview/captions, albums, image zoom and gallery navigation.
- Voice-message recording, preview, sending and playback; video notes and video
  playback in native windows.
- Audio/video playback speeds and optional sequential voice playback.
- WEBP, TGS and WEBM/VP9 stickers, GIFs and received link previews, subject to
  runtime capabilities.
- A download manager with progress, pause/resume, retry, cancel, Save As and
  Finder reveal; interrupted downloads restore after sign-in.
- Separate auto-download settings and media/chat-specific cache cleanup.

### Accounts and chat tools

- Contacts, profiles, presence, usernames, biographies and avatars.
- Chat/member administration, invite links, roles and restrictions.
- Privacy rules, blocked users, active sessions and auto-delete controls.
- Bot commands, inline results, callback buttons, reply keyboards and confirmed
  Login URLs.
- Contacts, locations, venues, dice, polls and quizzes where supported.
- One-to-one audio and experimental video calls on OS X 10.9 and newer.

### On your Mac

- Notification Center integration, Dock unread badges and click-through to chats.
- Muted chats keep a local gray unread marker, without banners, sound or a
  contribution to the overall unread/Dock count.
- Classic themes, optional Aqua, Russian/Belarusian/English localization and
  animation/economy settings.
- Optional **Workshop** modules, including Retro Console for your own compatible
  game files and cores, installed separately from the base app.

Feature availability depends on the loaded TDLib and the operating system.
See the [capability guide](docs/tdlib-capabilities.md) for the boundaries.

## Compatibility and current limits

| System | Status |
| --- | --- |
| OS X 10.8 Mountain Lion | Supported target; runtime-selected TDLib fallback and focused compatibility helpers. Calls and native MapKit picking are unavailable. |
| OS X 10.9 Mavericks | Main development and hands-on testing platform. |
| OS X 10.10–macOS 10.13 | Supported targets using the same Intel application. |
| Newer macOS / Apple Silicon | Unofficial and outside regular testing. No native `arm64` build. |

The **0.6.1** release was built and tested on real **OS X 10.9.5** using
**Xcode 5.1.1**, with a shared **10.8 deployment target**. Automated checks cover
Classic/Aqua, runtime capabilities, layouts, resource packaging and asynchronous
ownership. Both TDLib runtimes ship in the same bundle.

Physical execution of this release on 10.8 and 10.10–10.13 was unavailable.
Binary/deployment checks and fallback tests are supporting evidence; they do not
replace running the app on those systems. Compatibility reports are welcome.

Known limits:

- **A draft may not return to the composer after restarting.** Keep important
  unsent text separately before updating or switching interfaces.
- Some animated stickers and GIFs still have edge cases worth reporting.
- Group calls and screen sharing are not included. Calls are unavailable on 10.8.
- Text address search in the MapKit location picker is disabled after a legacy
  lifecycle crash. On 10.9 and newer, map/pin/zoom/current-location picking remains.
- Telegram purchases, Stars, subscriptions, gifts, paid media and other payment
  flows are intentionally absent. Use the official Telegram application to
  manage paid-only capabilities.

[Compatibility matrix](docs/compatibility-matrix.md) ·
[Release verification and limits](docs/releases/v0.6.1.md)

## Why I started this

I originally built Telegraphica for myself. While talking to a friend through
Telegram Web on my old Mavericks MacBook, I noticed how hot and slow the machine
became under the browser workload. A small native client seemed worth trying.

After the first working version, encouragement from friends pushed me to make
it public. I still do most of the development and hands-on testing on Mavericks.
I like these machines, I like the systems they run, and I want them to remain
useful for more than nostalgia.

The goal is a practical messaging client with modest overhead. I do not claim
measured CPU, temperature or battery improvements for 0.6.0.

## Building from source

| Component | Target |
| --- | --- |
| Platform | One application for OS X 10.8–macOS 10.13 |
| Architecture | Intel `x86_64` |
| UI / language | Cocoa/AppKit, Objective-C, manual reference counting |
| Toolchain | Xcode 5.1.1; source also kept compatible with Xcode 6.2 |
| Telegram core | TDLib JSON API, with bundled 10.8 and 10.9+ runtimes |

Build with the two existing TDLib libraries:

```sh
TELEGRAPHICA_TDJSON_PATH=/path/to/modern/libtdjson.dylib \
TELEGRAPHICA_TDJSON_MOUNTAIN_LION_PATH=/path/to/fallback/libtdjson.dylib \
./build_legacy.sh
```

A developer build needs its own local or remote app-configuration bootstrap.
Public release downloads already include one. See the
[bootstrap guide](docs/remote-tdlib-config.md) and
[local configuration example](docs/local-tdlib-config.example.plist).

For a complete public package, supply the verified call transport too:

```sh
TELEGRAPHICA_MODERN_CALL_TRANSPORT_PATH=/path/to/TelegraphicaCallTransport.dylib \
./scripts/package_legacy_release_artifacts.sh \
  --tdjson /path/to/modern/libtdjson.dylib \
  --mountain-lion-tdjson /path/to/fallback/libtdjson.dylib
```

The pipeline creates one HFS+ DMG, the matching app ZIP and SHA-256 files in
`dist/`. It checks both TDLib runtimes and refuses a public installer without
them or a connection bootstrap. See the [release checklist](docs/release-checklist.md)
and [old-Mac build guide](docs/mavericks-transfer.md) for the complete workflow.

For source changes, run:

```sh
./scripts/run_tests.sh
python3 scripts/check_legacy_compat.py
```

Ordinary feature work does not require rebuilding TDLib. Runtime updates follow
the [TDLib update and rollback guide](docs/tdlib-update-and-rollback.md).

## Local data and security

Sessions, databases and local settings belong in Application Support; secrets
use the application's local configuration and Keychain helpers. They do not
belong in this repository or in a release source archive.

Never commit or include in an issue report:

- Telegram `api_id` / `api_hash`, phone numbers, login codes or 2FA passwords;
- session files, TDLib databases or Keychain encryption keys;
- raw authorization responses or private conversation screenshots.

Use the redacted diagnostics where possible, and review logs before sharing.
Telegraphica is independent of Telegram and does not ship official Telegram
logos or artwork. Third-party materials are documented in
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

## Development and feedback

The next priorities include draft restoration across restart, further Aqua
polish, animated-media edge cases and broader testing on supported systems.

Useful references:

- [Product direction](PRODUCT.md)
- [Architecture and modernization baseline](docs/technical-modernization-baseline.md)
- [TDLib capabilities](docs/tdlib-capabilities.md)
- [Security notes](docs/security.md)
- [Source and release history](https://github.com/MiChiRose/telegraphica/releases)

If something goes wrong, [open an issue](https://github.com/MiChiRose/telegraphica/issues)
with the app version, macOS version, what happened and how to reproduce it.
For news, follow [the Telegram channel](https://t.me/macos_telegraphica).

Made for the stubbornly useful old Macs that still deserve good software.
