# TypeNote (MusicKeyBoard) - Development Roadmap

## Phase 1: Core Skeleton ✅ MVP

**Goal**: Minimum viable prototype — press a key, hear a sound

### Milestone 1.1: Project Setup
- [x] Create Xcode project (SwiftUI, macOS 14+)
- [x] Add GeneralUser GS SoundFont to bundle

### Milestone 1.2: Audio Engine
- [x] Implement `SoundFontPlayer` (single sampler, SF2 loading, play/stop)
- [x] Implement `MultiSamplerPlayer` (multi-sampler pre-loading, zero-latency switch)
- [x] Configure low-latency buffer (256 frames)

### Milestone 1.3: Keyboard Input
- [x] Implement global keyboard monitoring (CGEventTap)
- [x] Implement DAW-standard piano key mapping
- [x] Key repeat prevention
- [x] Modifier key filtering (Cmd/Ctrl/Option)
- [x] Auto-recovery with timeout protection

### Milestone 1.4: Basic UI
- [x] Menu bar app architecture (LSUIElement)
- [x] Instrument selection dropdown
- [x] Play mode switching

---

## Phase 2: Score System ✅

**Goal**: Import and parse multiple sheet music formats

### Milestone 2.1: Unified Data Model
- [x] Define `MusicNote` struct (MIDI note, duration, velocity, rest flag)
- [x] Unified BPM detection across all formats

### Milestone 2.2: Jianpu Parser
- [x] Implement `JianpuParser` (1-7 scale, accidentals, octave, duration, ties)
- [x] Support 12 key signatures (C through B)
- [x] Jianpu text input UI

### Milestone 2.3: MusicXML Parser
- [x] Implement `MusicXMLParser` (XMLParser delegate pattern)
- [x] Parse pitch (step/octave/alter), duration, divisions, tempo
- [x] File import UI

### Milestone 2.4: MIDI File Parser
- [x] Implement native `MIDIFileParser` (AudioToolbox MusicSequence)
- [x] MIDI → MusicNote conversion with velocity preservation
- [x] Tempo extraction from tempo track
- [x] File import UI

---

## Phase 3: Enhanced Experience ✅

**Goal**: Background playback, library management, permissions, onboarding

### Milestone 3.1: Permissions & Onboarding
- [x] Input Monitoring detection and request
- [x] Accessibility permission detection and request
- [x] Onboarding wizard with permission cards and status polling
- [x] Auto-restart monitor on permission grant
- [x] Sandbox detection (hide unavailable features)

### Milestone 3.2: Score Library
- [x] 8 built-in demo scores
- [x] Library persistence (JSON index + file caching)
- [x] Grid and list view layouts with toggle
- [x] Drag-to-reorder, edit, delete actions
- [x] Score metadata editing (title, key, BPM)
- [x] Security-scoped resource access for sandbox

### Milestone 3.3: Play Modes & Smart Features
- [x] Sequential mode (next note per key press)
- [x] Single repeat mode (loop current score)
- [x] Shuffle mode (random score on completion)
- [x] Non-interrupt mode (ignore keys during note playback)
- [x] Smart Mute (play only when text field has focus, Accessibility API)
- [x] Play mode and Smart Mute state persistence

### Milestone 3.4: Instrument Library
- [x] 8 GM instrument categories (Piano, Percussion, Guitar, Bass, Strings, Brass, Woodwind, Synth)
- [x] Categorized instrument picker with icons
- [x] Dynamic on-demand instrument loading

### Milestone 3.5: State Persistence
- [x] Active score saved/restored on launch
- [x] User preferences via UserDefaults
- [x] Backward compatibility migration (legacy fields)

---

## Phase 4: Polish & Release (Future)

**Goal**: UX refinement, App Store submission

### Milestone 4.1: UI Polish
- [ ] Key press animation effects (press highlight, release restore)
- [ ] Score progress visualization (highlight current note)
- [ ] Dark/light mode adaptation

### Milestone 4.2: Advanced Features
- [ ] Auto-play mode (tempo-driven automatic playback)
- [ ] Multi-track support
- [ ] Chord mode (trigger chords with single key)

### Milestone 4.3: Release Preparation
- [ ] App icon design
- [ ] App Store review preparation
- [ ] User documentation
- [ ] Marketing screenshots and description

---

## Architecture

```
┌───────────────────────────────────────────────┐
│                  SwiftUI Views                │
│  ┌──────────┐ ┌───────────┐ ┌─────────────┐  │
│  │ MenuBar  │ │  Library   │ │ Onboarding  │  │
│  │  View    │ │   View     │ │    View     │  │
│  └──────────┘ └───────────┘ └─────────────┘  │
├───────────────────────────────────────────────┤
│              AppState (@Observable)            │
│  ┌──────────┐ ┌───────────┐ ┌─────────────┐  │
│  │ Score    │ │ Playback  │ │  Permission │  │
│  │ Library  │ │  State    │ │  Manager    │  │
│  └──────────┘ └───────────┘ └─────────────┘  │
├───────────────────────────────────────────────┤
│  ┌───────────────┐    ┌────────────────────┐  │
│  │ Audio Engine   │    │  Input Monitor     │  │
│  │ MultiSampler  │    │  GlobalKeyboard    │  │
│  │  Player       │    │  Monitor           │  │
│  └───────────────┘    └────────────────────┘  │
├───────────────────────────────────────────────┤
│  ┌──────────┐ ┌───────────┐ ┌─────────────┐  │
│  │ Jianpu   │ │ MusicXML  │ │   MIDI      │  │
│  │ Parser   │ │  Parser   │ │   Parser    │  │
│  └──────────┘ └───────────┘ └─────────────┘  │
├───────────────────────────────────────────────┤
│     AVAudioEngine + AudioToolbox + SoundFont  │
└───────────────────────────────────────────────┘
```

## File Structure

```
MusicKeyBoard/
├── Package.swift                    # SPM config (no external dependencies)
├── MusicKeyBoard/
│   ├── App/
│   │   ├── MusicKeyBoardApp.swift   # @main entry (menu bar app)
│   │   └── AppState.swift           # Core state management
│   ├── Audio/
│   │   ├── SoundFontPlayer.swift    # Single sampler player
│   │   └── MultiSamplerPlayer.swift # Multi-sampler engine
│   ├── Input/
│   │   ├── GlobalKeyboardMonitor.swift  # CGEventTap global monitoring
│   │   ├── KeyMapping.swift         # Key mapping & GM instrument definitions
│   │   ├── PermissionManager.swift  # Input Monitoring & Accessibility
│   │   └── FocusDetector.swift      # Text field focus detection (Smart Mute)
│   ├── Parser/
│   │   ├── MusicNote.swift          # Unified note model
│   │   ├── JianpuParser.swift       # Numbered notation parser
│   │   ├── MusicXMLParser.swift     # MusicXML parser
│   │   └── MIDIFileParser.swift     # MIDI file parser (AudioToolbox)
│   ├── Models/
│   │   ├── ScoreItem.swift          # Score metadata model
│   │   ├── BuiltInScores.swift      # 8 built-in demo songs
│   │   └── ScoreLibrary.swift       # Persistent library manager
│   ├── Views/
│   │   ├── MenuBarView.swift        # Menu bar popover UI
│   │   ├── LibraryView.swift        # Score library grid/list
│   │   ├── MainLibraryView.swift    # Library window container
│   │   ├── OnboardingView.swift     # Permission setup wizard
│   │   └── InstrumentLibraryView.swift # Instrument category picker
│   └── Resources/
│       └── (GeneralUser GS.sf2)     # SoundFont bundle
├── docs/
│   ├── PRD.md                       # Product requirements
│   ├── ROADMAP.md                   # Development roadmap
│   └── free-soundfonts.md           # Alternative SoundFont resources
└── README.md
```
