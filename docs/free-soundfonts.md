# Free Commercially Usable SoundFonts & Sound Sources

A curated list of free sound sources compatible with AVAudioUnitSampler (.sf2, .dls, .aupreset) for use in MusicKeyBoard.

## General MIDI SoundFonts

### 1. FluidR3_GM (Recommended Alternative)
- **Size**: ~148MB
- **License**: MIT License
- **Quality**: High quality, widely used in Linux audio (FluidSynth default)
- **Source**: https://member.keymusician.com/Member/FluidR3_GM/index.html
- **Notes**: Full GM/GS compatible, great all-around quality. One of the most popular free SoundFonts.

### 2. GeneralUser GS (Current)
- **Size**: ~31MB
- **License**: Custom free license (allows redistribution and commercial use with credit)
- **Source**: https://schristiancollins.com/generaluser.php
- **Notes**: Currently bundled with MusicKeyBoard. Good balance of quality and size. Credit required.

### 3. Timbres of Heaven
- **Size**: ~380MB
- **License**: Free for any use (commercial included)
- **Source**: https://midkar.com/soundfonts/
- **Notes**: Very high quality, large file size. Best for desktop-only use.

### 4. Arachno SoundFont
- **Size**: ~148MB
- **License**: Free for non-commercial and commercial use
- **Source**: https://www.arachnosoft.com/main/soundfont.php
- **Notes**: Good quality, well-maintained. Check license page for latest terms.

### 5. MuseScore General
- **Size**: ~36MB (HQ version ~200MB)
- **License**: MIT License
- **Source**: https://github.com/musescore/MuseScore/tree/master/share/sound
- **Notes**: Used by MuseScore. MIT licensed, safe for commercial use.

## High-Quality Individual Instrument SoundFonts

### Piano
| Name | Size | License | Source |
|------|------|---------|--------|
| Salamander Grand Piano | ~440MB (SF2) | CC-BY 3.0 | https://freepats.zenvoid.org/Piano/ |
| VSCO2 Piano | ~50MB | CC0 (Public Domain) | https://vis.versilstudios.com/vsco-community.html |
| Steinway Model B | ~200MB | Free/CC | Various SoundFont sites |

### Strings
| Name | Size | License | Source |
|------|------|---------|--------|
| VSCO2 Strings | ~100MB | CC0 (Public Domain) | https://vis.versilstudios.com/vsco-community.html |
| SSO (Sonatina Symphonic Orchestra) | ~400MB total | CC Sampling+ | https://github.com/peastman/sso |

### Other Instruments
| Name | Size | License | Source |
|------|------|---------|--------|
| FreePats Project (various) | Varies | GPL / CC0 | https://freepats.zenvoid.org/ |
| VSCO2 Community Edition | ~2GB total | CC0 (Public Domain) | https://vis.versilstudios.com/vsco-community.html |

## Where to Find SoundFonts

### Curated Collections
- **FreePats** - https://freepats.zenvoid.org/ - Focused on free/open licensed samples
- **Musical Artifacts** - https://musical-artifacts.com/artifacts?formats=sf2 - Community-curated, filter by license
- **Polyphone SoundFont Editor** - https://www.polyphone-soundfonts.com/en/soundfonts - Large collection with license info

### GitHub Repositories
- `musescore/MuseScore` - MuseScore General SoundFont (MIT)
- `FluidSynth/fluidsynth` - Links to FluidR3_GM
- `peastman/sso` - Sonatina Symphonic Orchestra

### General Resources
- **Woolyss** - https://woolyss.com/chipmusic-soundfonts.php - Retro/chiptune SoundFonts
- **Hammersound** - https://www.hammersound.net/ - Large legacy collection (check individual licenses)

## AVAudioUnitSampler Supported Formats

| Format | Extension | Notes |
|--------|-----------|-------|
| SoundFont 2 | .sf2 | Primary format, best compatibility |
| DLS (Downloadable Sounds) | .dls | Apple's native format, used in GarageBand |
| AU Preset | .aupreset | Audio Unit presets, can reference samples |
| EXS24 | .exs | Logic Pro format, works with AUSampler |

## Recommendations for MusicKeyBoard

### Keep Current (GeneralUser GS)
- Pros: Small (31MB), good quality, already integrated
- Cons: Custom license requires credit

### Upgrade Option 1: MuseScore General (MIT)
- Pros: MIT license (simplest), similar size (~36MB), good quality
- Cons: Slightly larger

### Upgrade Option 2: Dual SoundFont Approach
- Bundle a small GM SoundFont (~30MB) for all instruments
- Offer optional download of high-quality individual instruments (Salamander Piano, VSCO2 Strings)
- Best quality per instrument, but more complex implementation

### Future: Apple DLS
- macOS ships with a built-in DLS SoundFont at `/Library/Audio/Sounds/Banks/`
- Can be used as zero-bundle-size fallback, but quality is basic

## License Summary

| SoundFont | Commercial Use | Credit Required | License |
|-----------|---------------|-----------------|---------|
| GeneralUser GS | Yes | Yes | Custom |
| FluidR3_GM | Yes | No (MIT) | MIT |
| MuseScore General | Yes | No (MIT) | MIT |
| Timbres of Heaven | Yes | Check latest | Custom Free |
| VSCO2 | Yes | No | CC0 |
| Salamander Piano | Yes | Yes | CC-BY 3.0 |
| FreePats | Yes | Varies | GPL/CC0 |
