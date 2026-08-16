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
- Document EasyEffects noise gate setup if recurring issue