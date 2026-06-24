# luks-tpm-unlock - TPM2 auto-unlock for LUKS2

Enrolls the root LUKS2 volume with **TPM2** via `systemd-cryptenroll` so cold
boot unlocks without a passphrase when the TPM PCR policy matches. The install
passphrase remains a **fallback** if TPM unlock fails (PCR drift after firmware
updates, TPM cleared, etc.).

## Install-time behaviour

The HyperWebster installer prompts for LUKS encryption, then asks whether to
enroll TPM2 when `/dev/tpmrm0` or `/dev/tpm0` is present. Enrollment uses PCR
**7** (Secure Boot state) by default and **auto-retries with 7+11** if PCR 7
alone fails.

You can reuse your **login password** as the LUKS fallback passphrase so you only
remember one secret when TPM unlock is unavailable.

`mkinitcpio` uses the **`sd-encrypt`** hook (systemd in initramfs) with
**`plymouth`** before it so the HyperWebster splash shows a graphical passphrase
prompt instead of dropping to a TTY. Limine kernel cmdline uses
**`rd.luks.name=LUKS-UUID=mappername`**, **`rd.luks.options=timeout=0`**, and
**`rootflags=subvol=@,x-systemd.device-timeout=0`** so the prompt does not time
out after ~90 seconds on couch/TV setups.

## Manual enrollment (post-install)

```sh
sudo hyperwebster-luks-tpm-enroll /dev/disk/by-partuuid/YOUR-LUKS-PARTUUID
```

Initramfs rebuild runs automatically after enrollment.

## Diagnostics

```sh
sudo hyperwebster-luks-tpm-status
# or with an explicit device:
sudo hyperwebster-luks-tpm-status /dev/disk/by-partuuid/YOUR-LUKS-PARTUUID
```

Reports TPM hardware, LUKS tokens, `sd-encrypt` / Plymouth hooks, kernel
cmdline, and PCR hints.

## Boot flow

Limine → UKI initramfs (`plymouth` + `sd-encrypt`) → TPM unlock attempt →
Plymouth graphical passphrase (if needed) → btrfs `@` → Plymouth splash → SDDM.

## Controller / TV note

A **USB keyboard** is required when TPM auto-unlock fails — game controllers
cannot type the LUKS passphrase. TPM working is what enables controller-only
cold boot to SDDM.

## Troubleshooting

| Symptom | Check / fix |
|---------|-------------|
| Passphrase prompt every boot | `hyperwebster-luks-tpm-status` — no TPM2 token? Re-run `hyperwebster-luks-tpm-enroll`. |
| Black screen, no prompt | Press **Esc** once for TTY fallback; then run `hyperwebster-update` to refresh Plymouth hook + theme. |
| Prompt disappears after ~90s | Add `rd.luks.options=timeout=0` and `x-systemd.device-timeout=0` on the Limine cmdline; `limine-update` after `hyperwebster-update`. |
| Enrollment fails in installer | Live ISO chroot may lack TPM access — enroll after first boot (same command). |
| Worked once, fails after BIOS update | PCR drift — passphrase fallback should still work; re-enroll (`--pcrs 7+11` is the default retry). |
| `sd-encrypt` missing | `grep sd-encrypt /etc/mkinitcpio.conf` — run `install-luks-tpm-unlock.sh` or `hyperwebster-update`. |
| Secure Boot off | Try `sudo hyperwebster-luks-tpm-enroll --pcrs 7+11 /dev/disk/by-partuuid/…`. |

Verify TPM: `systemd-cryptenroll --tpm2-device=list` and `tpm2_pcrread sha256:7` (needs `tpm2-tools`).

### Why no ESP keyfile?

Storing a LUKS keyfile on the unencrypted EFI partition would let anyone with
physical access decrypt the disk without a passphrase. HyperWebster does not
ship that option. TPM2 + passphrase fallback is the supported model.

After any enrollment or hook change, `hyperwebster-luks-tpm-enroll` rebuilds the initramfs and runs `limine-update` when available.

## Hardware testing

- Cold boot without controller/keyboard: should reach SDDM without passphrase (when TPM enrolled)
- After a BIOS/Secure Boot change: passphrase fallback on Plymouth splash; re-enroll TPM
- TPM failure path: Plymouth shows Starman + passphrase field (USB keyboard)

## Files

| File | Role |
|------|------|
| `hyperwebster-luks-tpm-enroll` | CLI wrapper around `systemd-cryptenroll` |
| `hyperwebster-luks-tpm-status` | Boot-chain diagnostics |
| `install-luks-tpm-unlock.sh` | Idempotent installer + Plymouth/hook fixes |
| `plymouth/hyperwebster.script` | Graphical LUKS passphrase on the Starman splash |
