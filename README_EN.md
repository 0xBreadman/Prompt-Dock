# Prompt Dock

<p align="center">
  <a href="README.md">简体中文</a> · <strong>English</strong>
</p>

<p align="center">
  <img src="Docs/Brand/AppIcon-master-v3-selected.png" width="112" alt="Prompt Dock icon">
</p>

<p align="center">
  <strong>Turn a thousand-word prompt into one click or one gesture.</strong><br>
  A local-first, always-on-top AI workflow launcher for macOS.
</p>

<p align="center">
  SwiftUI · macOS Native · Local First · MIT
</p>

Prompt Dock is not a notes app. The management workspace stores your complete prompt library and work presets, while the launcher only shows what you need right now. It is designed for people who move constantly between ChatGPT, Gemini, Grok, image models, and video models.

## Three levels of speed

The same prompt collection can appear in three interfaces. Browse the complete set when needed, or reduce your most frequent actions to a single gesture.

<table>
  <tr>
    <td align="center" width="33%"><img src="Docs/Screenshots/floating-panel.png" height="300" alt="Floating prompt panel"></td>
    <td align="center" width="33%"><img src="Docs/Screenshots/radial-menu.png" height="300" alt="Radial prompt menu"></td>
    <td align="center" width="33%"><img src="Docs/Screenshots/edge-shelf.png" height="300" alt="Edge prompt shelf"></td>
  </tr>
  <tr>
    <td align="center"><strong>Floating panel</strong><br>Always on top, with search, categories, and your complete active workspace. Click a card to copy.</td>
    <td align="center"><strong>Radial menu</strong><br>Hold <code>·</code>, move to a prompt, and release. Selection and copying happen in one gesture.</td>
    <td align="center"><strong>Edge shelf</strong><br>Hidden until you touch the screen edge, keeping the rest of your workspace unobstructed.</td>
  </tr>
</table>

## A workspace behind the launcher

The library and the quick-access interfaces are separate: save the complete content once, then decide what appears during each stage of your work. You are not locked into a fixed “recent” or “favorites” view—each workflow can have its own setup.

### 1. Edit complete prompts

Manage titles, full content, tags, and compatible models through a Category → Prompt structure. A prompt can be thousands of words long while its launcher card remains compact.

<p align="center">
  <img src="Docs/Screenshots/prompt-editor.png" width="920" alt="Prompt library and editor">
</p>

### 2. Configure work presets

Create presets for “AI Content,” “Shopify Operations,” or any other stage of your work. Choose separate prompt sets for the floating panel, radial menu, and edge shelf. Switching presets never duplicates the underlying prompt content.

<p align="center">
  <img src="Docs/Screenshots/work-presets.png" width="920" alt="Work preset configuration">
</p>

### 3. Import, export, and back up locally

Export the complete library as JSON, including categories, prompts, work presets, and radial-menu slots. Restore it from JSON at any time. Prompt Dock also keeps a local daily snapshot before the first change of the day.

<p align="center">
  <img src="Docs/Screenshots/data-backup.png" width="920" alt="Local data backup, import and export">
</p>

> README screenshots use an isolated built-in demo library. They contain no private prompts from the developer or any user.

## Current features

- Resizable, draggable, always-on-top glass panel
- Categories, tags, and full-text search
- Create, edit, delete, and categorize prompts
- Multiple work presets with separate panel, 4/6/8-slot radial menu, and edge-shelf selections
- Per-prompt model icons and compatible-model metadata
- One-click copy with success feedback
- Hold `·`, move, and release to copy; return to the center to cancel
- Left- or right-side screen edge shelf
- Global `Command + Shift + P` panel shortcut
- Menu bar presence, opacity controls, and Dark Mode
- Local JSON storage, daily snapshots, import, and export
- No account, ads, analytics SDK, or server dependency

## Why it exists

Long prompts tend to disappear inside notes and documents. Copying is not the slow part—the repeated searching, expanding, selecting, and switching back to an AI tool is. Prompt Dock explores three questions:

- Can an always-on-top workspace reduce application switching?
- Do custom work presets fit changing tasks better than fixed recent and favorites lists?
- Can a hold, move, and release radial menu reduce frequent prompt copying to one action?

If this resembles your workflow, share your use case through GitHub Issues. Please do not paste private prompts, API keys, or customer data into issues, screenshots, or logs.

## Requirements

- macOS 14 or later
- Xcode 16 or later (currently verified with Xcode 26.6)

## Run locally

1. Clone or download this repository.
2. Open `AIPromptDock.xcodeproj` in Xcode.
3. Select `My Mac` and click Run.
4. To use the single-key `·` radial menu, grant access under System Settings → Privacy & Security → Accessibility when prompted.

Prompt Dock is a menu bar app and does not remain in the Dock. Closing the panel only hides it; reopen it from the menu bar icon or with `Command + Shift + P`.

## Local data

Data for an App Store sandbox build is stored at:

```text
~/Library/Containers/com.ayu.AIPromptDock/Data/Library/Application Support/AIPromptDock/library.json
```

Prompt content, categories, and work presets stay on the local Mac by default. The repository contains only generic example prompts, never the developer's personal library.

## Architecture

- SwiftUI: floating panel, management workspace, radial menu, and edge shelf
- AppKit: floating windows, menu bar integration, and screen levels
- Codable JSON: local library, migration, and backups
- Carbon / CGEvent: modifier shortcuts and authorized single-key monitoring

See [Technical Architecture](Docs/ARCHITECTURE.md), [Data Model](Docs/DATA_MODEL.md), and [Project Structure](Docs/PROJECT_STRUCTURE.md) for more details.

## Current limitations

- No iCloud or multi-device sync yet
- No team sharing or prompt marketplace yet
- Categories and prompts cannot be reordered by drag and drop yet
- macOS may request Accessibility permission again after a local development-signing change
- No notarized installer is available yet; build locally with Xcode
- For regular local updates, run `Scripts/install-local.sh`; it uses a stable local signature to avoid invalidating the single-key radial-menu permission on every update

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for issues and code contributions. See [SECURITY.md](SECURITY.md) for security reports.

## License

[MIT License](LICENSE)
