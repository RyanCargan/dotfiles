# Quick Reference — NixOS Audio Setup

Run once after install/rebuild to get mic working:

```bash
# 1. Set WirePlumber profile (done in config, but re-apply if needed):
pw-cli set-param 49 Profile '"{ \"index\": 1, \"name\": \"output:analog-stereo+input:analog-stereo\" }"'

# 2. Lower ALSA gains (reduce static):
amixer -c 2 cset numid=27 1       # Rear Mic Boost = 10 dB
amixer -c 2 cset numid=23 38      # Capture Volume = ~22 dB

# 3. Set default PipeWire source to physical mic:
wpctl set-default 70               # Starship/Matisse HD Audio Controller

# 4. Persist ALSA state:
alsactl store -f ./nixos/asound.state

# 5. Rebuild NixOS:
nixos-rebuild switch
```

---

## Persistence Checklist

| What | Where it's stored | How to re-apply |
|------|-------------------|-----------------|
| WirePlumber profile rule | `nixos/configuration.nix` | Rebuild: `nixos-rebuild switch` |
| ALSA mixer gains (boost/volume) | `nixos/asound.state` → deployed to `/etc/asound.state` | `alsactl store -f ./nixos/asound.state` + rebuild |
| PipeWire default source | WirePlumber runtime state (`~/.local/state/wireplumber/`) | `wpctl set-default 70` + restart EE |

---

## EasyEffects — If Input Tab is Empty

1. Quit EE: `easyeffects -q`
2. Start recording in OBS (or any audio app)
3. Reopen EE → Input tab → OBS stream should appear
4. Add **Gate** (threshold ≈ -40 dB) and **RNNoise** (AI denoise)

If still no devices in EE:
- Ensure `pipewire-pulse` is installed
- Restart WirePlumber: `systemctl --user restart wireplumber`
- Clear state: `rm -rf ~/.local/state/wireplumber/`

---

## Commands Summary

```bash
# Check current ALSA gains
amixer -c 2 cget numid=27   # Rear Mic Boost
amixer -c 2 cget numid=23   # Capture Volume

# Check default source
wpctl status | grep -A3 "Default Configured"

# Set default source to physical mic
wpctl set-default 70

# Save ALSA state persistently
alsactl store -f ./nixos/asound.state

# Push config to /etc/nixos (sync-dotfiles)
./sync-dotfiles.zsh push
```