# Steve's Talking Clock for the Mac

PLEASE NOTE: THIS PROJECT WAS GENERATED WITH THE HELP OF ARTIFICIAL INTELLIGENCE (DEEPSEEK OR DSEEK).

A customisable talking clock for macOS. Announces the time on the quarter-hour,
half-hour, three-quarter-hour, and top of the hour; supports per-slot voices,
an alarm, quiet mode, configurable hotkeys and full VoiceOver accessibility.

A macOS port of [Steve's Talking Clock 2.06](http://clock.steve-audio.net) by
Stephen Clower. Built with assistance from AI tools — see [Development
notes](#development-notes) for details.

![macOS 13+](https://img.shields.io/badge/macOS-13.0%2B-blue)
![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)

---

## Features

- **Ten voice formats** — full support for every concatenation method in the
  original specification, from simple word files to Danish "one and twenty"
  numbering.
- **System voices too** — every installed macOS TTS voice (Alex, Samantha, Daniel,
  etc.) appears in the picker. A dedicated **System Voice** entry uses
  the VoiceOver voice when VoiceOver is running.
- **Per-slot voices** — pick a different voice for the main announcement,
  quarter-hour, half-hour, three-quarter-hour, the hour and the alarm.
- **Output device picker** — route announcements to any connected sound
  device, and the choice is remembered across reboots.
- **Working alarm** — set a time in 12- or 24-hour format, fires once a day.
- **Quiet mode** — suppress automatic announcements during a configurable
  window.
- **Full VoiceOver support** — every control labelled; state changes announced.
- **Predictable keyboard navigation** — Tab moves down each column; Space
  activates the focused control.

---

## Requirements

- macOS **13.0 Ventura** or newer
- No Apple Developer account required

---

## Installation

### Download (recommended)

1. Download `Steve's-Talking-Clock-2.0.dmg` from
   [Releases](https://github.com/olivfry/Steves-Talking-Clock-for-the-Mac-/releases).
2. Open the DMG and drag **Steve's Talking Clock** to `/Applications`.
3. **First launch**: right-click the app → **Open**. The app is ad-hoc signed
   (no Apple Developer certificate), so Gatekeeper will warn once. Subsequent
   launches work normally.

### Build from source

Requires **Xcode 15** or newer.

```bash
git clone https://github.com/olivfry/Steves-Talking-Clock-for-the-Mac-.git
cd Steves-Talking-Clock-for-the-Mac-
./install.sh
```
## Development notes

This app was designed, tested and integrated by Oliver Fry. AI tools
(primarily DeepSeek/DSeek) were used as a coding assistant throughout development:
suggesting fixes for specific technical problems, drafting implementations
that were then reviewed and adapted and helping work through macOS APIs like
`AVAudioEngine`, `AVSpeechSynthesizer`, and `SMAppService`. All architectural
decisions, feature scope, UI design, testing and accessibility validation
were done by the author.

The project is released openly so that anyone can audit the code, understand
what it does, and verify its behaviour — regardless of how it was written.
