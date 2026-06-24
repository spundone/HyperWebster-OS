# tcl-t89c-display — TCL T89C TV (4K 144 Hz HDR VRR)

Ships a **hyprmoncfg** profile for the primary gaming TV and Hyprland environment
hints for amdgpu HDR/VRR on Wayland.

## Apply the profile

```sh
hyprmoncfg apply tcl-t89c-tv
# or edit output name first:
nano ~/.config/hyprmoncfg/profiles/tcl-t89c-tv
```

Find your connector name with `hyprctl monitors` (often `HDMI-A-1` or `HDMI-A-2`).

## Gaming session (gamescope)

HDR/VRR in full-screen gaming is handled by **gamescope** inside the Chimera
session. See `chimera-deckify-gaming/gamescope-hdr.env`. Real hardware validation
on the TCL T89C is required — amdgpu HDR on Wayland is still maturing.

## Hardware testing checklist

- [ ] `hyprctl monitors` shows `vrr: true` and HDR-capable output
- [ ] Desktop HDR test pattern (if supported by Hyprland build)
- [ ] gamescope session with `ENABLE_HDR_WSI=1` on the TV
- [ ] VRR active in games (MangoHud / gamescope logs)
