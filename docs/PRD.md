# TypeNote (MusicKeyBoard) - Product Requirements Document (PRD)

## 1. Product Overview

**TypeNote** is a native macOS menu bar app that replaces your keystroke sounds with musical timbres. It sits quietly in the menu bar, detects your keystrokes, and plays a sound for each one — a piano note, a guitar pluck, ocean waves, or any of 128 General MIDI timbres. Users can also load melodies (Jianpu, MusicXML, MIDI) so their keystrokes follow a sequence of notes — a quiet way to hear a song while working.

TypeNote is **not** a music practice or learning tool. It is an ambient typing experience that makes everyday keyboard use sound and feel different.

## 2. Target Users

- Everyday typists: Anyone who wants their keyboard to sound more interesting while working
- Ambience seekers: Users who enjoy background sounds, ASMR, or focus-enhancing audio
- Curious tinkerers: People who like customizing small details of their computing environment

## 3. Core Features

### 3.1 Keyboard Input

| Feature | Description | Status |
|---------|-------------|--------|
| Global keyboard monitoring | Background playback via CGEventTap (requires Input Monitoring) | ✅ Done |
| Sequential play mode | Each key press plays the next note in the score | ✅ Done |
| Single repeat mode | Loop the current score after finishing | ✅ Done |
| Shuffle mode | Advance to a random different score on completion | ✅ Done |
| Non-interrupt mode | Ignore key events while a note is still playing | ✅ Done |
| Piano key layout | DAW-standard: ASDFGHJKL = white keys, WETYU = black keys | ✅ Done |
| Key repeat prevention | Ignore system key repeat events | ✅ Done |
| Modifier filtering | Ignore Cmd/Ctrl/Option key combinations | ✅ Done |
| Auto-recovery | Timeout protection with automatic event tap re-enable | ✅ Done |

### 3.2 Audio Engine

| Feature | Description | Status |
|---------|-------------|--------|
| SoundFont playback | AVAudioUnitSampler loads SF2 sound banks | ✅ Done |
| Multi-sampler pre-loading | Parallel sampler instances, zero-latency switching | ✅ Done |
| Low-latency buffer | 256-frame buffer (~5.8ms @ 44.1kHz) | ✅ Done |
| Instrument selection | General MIDI instruments across 8 categories | ✅ Done |
| Velocity control | Note velocity support (0-127) | ✅ Done |
| Dynamic instrument loading | On-demand loading for instruments not pre-loaded | ✅ Done |
| Note lifecycle tracking | Per-note start/stop with duration-based auto-release | ✅ Done |

### 3.3 Score Parsing

| Feature | Description | Status |
|---------|-------------|--------|
| Jianpu parser | Numbered notation (1-7, accidentals, octave, duration, ties) | ✅ Done |
| Key signature support | 12 keys (C through B) | ✅ Done |
| MusicXML parser | Import from MuseScore/Sibelius/Finale exports | ✅ Done |
| MIDI file parser | Native AudioToolbox parsing (no external dependency) | ✅ Done |
| Unified note model | All formats output to `MusicNote` array with MIDI note, duration, velocity, rest flag | ✅ Done |
| BPM detection | Unified tempo extraction across all formats | ✅ Done |
| Rest support | Proper rest duration handling across all formats | ✅ Done |

### 3.4 Score Library

| Feature | Description | Status |
|---------|-------------|--------|
| Built-in demo scores | 8 pre-loaded songs (Twinkle Twinkle, Canon in D, Ode to Joy, etc.) | ✅ Done |
| Score import | File picker for Jianpu (.txt), MusicXML (.xml/.musicxml), MIDI (.mid/.midi) | ✅ Done |
| Jianpu text editor | Direct numbered notation input and editing | ✅ Done |
| Library persistence | JSON-based index with file caching in Application Support | ✅ Done |
| Grid & list views | Adaptive grid layout and alternating-row list layout | ✅ Done |
| Drag-to-reorder | Custom score ordering | ✅ Done |
| Score metadata | Editable title, key signature, BPM per score | ✅ Done |
| Security-scoped access | Sandbox-compatible file handling | ✅ Done |

### 3.5 User Interface

| Feature | Description | Status |
|---------|-------------|--------|
| Menu bar app | Lives in menu bar with piano keys icon (LSUIElement) | ✅ Done |
| Score status display | Current note / total notes with progress bar | ✅ Done |
| Play mode selector | Visual picker for Sequential / Single Repeat / Shuffle | ✅ Done |
| Global on/off toggle | Quick enable/disable keyboard monitoring | ✅ Done |
| Library window | Separate window for score management | ✅ Done |
| Instrument library | Categorized GM instruments (Piano, Percussion, Guitar, Bass, Strings, Brass, Woodwind, Synth) | ✅ Done |
| Layout toggle | Switch between grid and list in library | ✅ Done |

### 3.6 Smart Mute

| Feature | Description | Status |
|---------|-------------|--------|
| Text field detection | Only plays when a text field has focus (Accessibility API) | ✅ Done |
| Supported field types | TextField, TextArea, ComboBox, SearchField, WebArea | ✅ Done |
| Optional permission | Shown as "Optional" in onboarding; hidden in sandboxed builds | ✅ Done |
| State persistence | Smart Mute preference saved to UserDefaults | ✅ Done |

> **Note:** Smart Mute uses the Accessibility API solely to detect whether a text input field is focused. It does not read, record, or transmit any text content.

### 3.7 Permissions & Onboarding

| Feature | Description | Status |
|---------|-------------|--------|
| Input Monitoring detection | `CGPreflightListenEventAccess()` check | ✅ Done |
| Onboarding wizard | Two-step welcome + permissions flow | ✅ Done |
| Auto-restart on grant | Monitor restarts automatically when permission is granted | ✅ Done |
| Sandbox detection | Hides unavailable features in sandboxed builds | ✅ Done |
| Permission overlay | Shown in menu bar when Input Monitoring is denied | ✅ Done |

### 3.8 State Persistence

| Feature | Description | Status |
|---------|-------------|--------|
| Active score | Last selected score restored on launch | ✅ Done |
| Play mode | Selected mode saved/restored via UserDefaults | ✅ Done |
| Smart Mute preference | Toggle state persisted | ✅ Done |
| Library index | Score metadata cached as JSON | ✅ Done |
| Backward compatibility | Legacy field migration (e.g., jianpuTempo → bpm) | ✅ Done |

## 4. Technical Constraints

- **Minimum OS**: macOS 14.0 (Sonoma)
- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI
- **Audio Framework**: AVFoundation (AVAudioEngine + AVAudioUnitSampler)
- **MIDI Parsing**: AudioToolbox (MusicSequence, native)
- **Keyboard Monitoring**: CGEventTap (global)
- **State Management**: @Observable (Observation framework)
- **SoundFont**: GeneralUser GS v1.471 (SF2, ~30MB, free for commercial use)
- **Sandbox**: App Sandbox enabled with read-only user-selected file access
- **External Dependencies**: None (zero third-party SPM packages)

## 5. Non-Functional Requirements

- **Latency**: Key press to sound < 15ms
- **Memory**: Idle state < 100MB (including SoundFont)
- **Startup time**: < 2s
- **Permissions**: Global mode requires Input Monitoring; Smart Mute requires Accessibility (optional)

## 6. Product Positioning

TypeNote is an **ambient typing experience tool**, not a music instrument or practice app. The value proposition:

- You are still working — typing emails, writing code, chatting
- Every keystroke just happens to sound like something pleasant
- Melodies are a quiet, passive way to hear a song, not an active performance

This distinction matters for App Store review, marketing copy, and feature prioritization.

## 7. Out of Scope

- MIDI external device input/output
- Recording and playback
- Audio effects (reverb, delay, etc.)
- Score editor (full notation editing)
- iOS / iPadOS version
- Auto-play mode (tempo-driven automatic playback)
- Multi-track support
- Chord mode (trigger chords with single key)
- Music theory instruction or practice features
