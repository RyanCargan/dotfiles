# NixOS Audio Fixes — Ryan's Configuration

This document summarizes the audio configuration changes made to get the microphone working on NixOS with PipeWire + WirePlumber, and the persistent configuration stored in the dotfiles repo.

---

## Issues Fixed

### 1. Microphone not detected / no input source in apps

**Root cause:** WirePlumber (PipeWire session manager) selected the output-only profile `output:analog-stereo` for the ALC892 codec instead of the duplex profile `output:analog-stereo+input:analog-stereo`.

**Fix:** Added a WirePlumber rule in `nixos/configuration.nix` (lines 286-307) that forces the duplex profile for the specific codec card:

```nix
wireplumber = {
  enable = true;
  config = {
    wireplumber.conf = {
      properties = {
        "alsa.rules" = [
          {
            matches = [
              {
                "device.name" = "alsa_card.pci-0000_28_00.4"
              }
            ];
            actions = {
              update-props = {
                "api.alsa.profile" = "output:analog-stereo+input:analog-stereo"
              };
            };
          }
        ];
      };
    };
  };
};
```

Also persisted ALSA mixer state (`alsactl store`) to `nixos/asound.state`, which is deployed via `environment.etc."asound.state"` in the same config file.

### 2. High static/noise from microphone

**Root cause:** ALSA mixer controls were maxed out:
- `Front Mic Boost Volume` = 30 dB (step 3/3) — amplifying codec noise floor
- `Capture Volume` = 46 (max) — clipping

**Fix:** Lowered gains to sensible values:
```bash
amixer -c 2 cset numid=27 1   # Rear Mic Boost = 10 dB
amixer -c 2 cset numid=23 38  # Capture Volume = ~22 dB
```

These values were saved to `nixos/asound.state` and deployed on rebuild.

### 3. EasyEffects couldn't "see" the microphone

**Root cause:** PipeWire's default audio source was set to `virtual_mic` (EasyEffects' virtual source), not the physical ALC892 input. EasyEffects by default processes the system default input, which was wrong.

**Fix:** Changed the PipeWire default source to the physical card:
```bash
wpctl set-default 70   # Starship/Matisse HD Audio Controller Analog Stereo
```

This makes EasyEffects process the rear mic input. After this change, the microphone appears in EasyEffects' Input tab once an app (e.g., OBS) is actively recording.

**In EasyEffects GUI after fix:**
- PipeWire tab → Input section → Disable "Use default input" (or leave on if default is now correct)
- Input tab → Start recording in OBS → OBS stream appears → add Gate + RNNoise effects

### 4. Speaker line-out echo (temporary, self-resolved)

**Observation:** At one point, the rear line-out speakers had echo. This issue resolved itself without explicit changes — likely a loose cable connection that made contact again, or WirePlumber re-negotiated the profile after the other fixes were applied.

### 5. Persistence across reboots

**How the fixes persist:**

| Fix | Persistence mechanism |
|-----|----------------------|
| WirePlumber profile rule | Declared in `nixos/configuration.nix` — survives `nixos-rebuild switch` |
| ALSA mixer gains | Saved to `nixos/asound.state` via `alsactl store`; deployed via `environment.etc."asound.state"` |
| PipeWire default source | Stored in WirePlumber state (~/.local/state/wireplumber/) — survives reboot; also reflected in `asound.state` |

To re-apply after a fresh install:
```bash
# 1. Re-apply WirePlumber rule (in config)
# 2. Tune ALSA gains
amixer -c 2 cset numid=27 1
amixer -c 2 cset numid=23 38
# 3. Persist
alsactl store -f ./nixos/asound.state
# 4. Rebuild
nixos-rebuild switch
# 5. Set default source
wpctl set-default 70
```

---

## File Layout

```
nixos/
├── configuration.nix   # WirePlumber rule + asound.state source directive
└── asound.state        # Saved ALSA mixer state (boost, capture volume, input source)

sync-dotfiles.zsh       # 'push' now includes /etc/nixos/asound.state → repo
```

---

## Current Status (as of 2026-08-16)

- ✅ Microphone detected and working in OBS
- ✅ Static reduced to tolerable levels (mild background noise)
- ✅ EasyEffects now processes the physical mic (after setting default source)
- ✅ All changes persisted in repo for future rebuilds
- ⚠️ Fine-tuning possible: adjust EasyEffects Gate/RNNoise thresholds, or move mic to front panel if bias voltage needed

---

## Next Steps (deferred)

- Tweak EasyEffects Gate/RNNoise parameters for specific microphone
- Test front-panel mic with plug-in power enabled (if applicable)
- Explore USB audio interface for cleanest signal chain
- ~~Document EasyEffects noise gate setup if recurring issue~~ → done, see below

---

## EasyEffects State (as of 2026-08-22)

EasyEffects 8.2.4, autostart on login (`autostartOnLogin=true`), always running —
which is what provides the `Easy Effects Source` virtual mic used by the ASR
hold hotkey (`Super+Alt+R`).

No saved presets (`.config/easyeffects/{input,output}/` empty). All tuned state
lives in `db/*.rc` — EE 8's per-effect database. Those files are the source of
truth and are versioned here; `sync-dotfiles.zsh` now syncs the whole tree.

### Input chain (physical mic → apps/ASR)

| Effect | Params | Inference |
|---|---|---|
| DeepFilterNet#0 | attenuationLimit=65, postFilterBeta=0.05 | ML speech denoise, aggressive ceiling. Primary static/fan/hiss killer for voice + ASR feed. |
| Gate#0 | bypass=true | Noise gate tried and disabled — DeepFilterNet made it redundant. |

### Output chain (apps → speakers), order: compressor → filter#0 → filter#1 → deepfilternet → limiter

| Effect | Params | Inference |
|---|---|---|
| Compressor#0 | threshold=-20, attack=5, release=75 | Gentle glue: evens out quiet/loud swings from uneven source audio. |
| Filter#0 | frequency=10000, slope=1 (type unset = default low-pass) | 12 dB/oct roll-off above ~10 kHz: trims top-end hiss/sibilance harshness from bad recordings. |
| Filter#1 | frequency=120, slope=1, type=1 (high-pass) | Removes rumble/hum below 120 Hz. |
| DeepFilterNet#0 | attenuationLimit=35, maxDfProcessingThreshold=15, postFilterBeta=0.03 | ML denoise on playback — conservative vs input chain so music doesn't get artifacts. |
| Limiter#0 | threshold=-1 | Peak safety ceiling. |

Overall design: band-limit 120 Hz–10 kHz + dynamics glue + ML denoise in both
directions. Input tuned hard (65 dB) for close-mic static on a cheap analog
mic; output soft (35 dB) to stay transparent on music.

### Legacy dconf archive

`docs/easyeffects-dconf-legacy.dump` is a full `dconf dump` of the pre-8.x
gsettings state (13-band equalizer + dual-compressor experiment era,
`snd_aloop` virtual input experiments). EE 8.2.4 does not read it — kept only
so old trial-and-error values are recoverable:

```
dconf load /com/github/wwmm/easyeffects/ < docs/easyeffects-dconf-legacy.dump
```

### Restore procedure (fresh system)

1. `sync-dotfiles.zsh push` (or manual copy of `.config/easyeffects/db/`)
2. Start EasyEffects — chains load from `db/*.rc`
3. Set default source if needed: `wpctl set-default <id>`