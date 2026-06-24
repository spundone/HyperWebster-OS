# tv-gaming-display - 4K HDR TV profile (144 Hz VRR)

Ships a **hyprmoncfg** profile for 4K high-refresh HDR TVs and Hyprland environment
hints for amdgpu HDR/VRR on Wayland.

## Apply the profile

```sh
hyprmoncfg apply tv-gaming-4k
# or edit output name first:
nano ~/.config/hyprmoncfg/profiles/tv-gaming-4k
```

Find your connector name with `hyprctl monitors` (often `HDMI-A-1` or `HDMI-A-2`).

## Gaming session (gamescope)

HDR/VRR in full-screen gaming is handled by **gamescope** inside the Chimera
session. See `chimera-deckify-gaming/gamescope-hdr.env`. Validate HDR and VRR
on your display - amdgpu HDR on Wayland is still maturing on some builds.

## Hardware testing checklist

- [ ] `hyprctl monitors` shows `vrr: true` and HDR-capable output
- [ ] Desktop HDR test pattern (if supported by Hyprland build)
- [ ] gamescope session with `ENABLE_HDR_WSI=1` on the TV
- [ ] VRR active in games (MangoHud / gamescope logs)
