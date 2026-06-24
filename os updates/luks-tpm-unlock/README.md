# luks-tpm-unlock - TPM2 auto-unlock for LUKS2

Enrolls the root LUKS2 volume with **TPM2** via `systemd-cryptenroll` so cold
boot unlocks without a passphrase when the TPM PCR policy matches. The install
passphrase remains a **fallback** if TPM unlock fails (PCR drift after firmware
updates, TPM cleared, etc.).

## Install-time behaviour

The HyperWebster installer prompts for LUKS encryption, then asks whether to
enroll TPM2 when `/dev/tpmrm0` or `/dev/tpm0` is present. Enrollment uses PCR
**7** (Secure Boot state) by default.

`mkinitcpio` uses the **`sd-encrypt`** hook (systemd in initramfs) instead of
the legacy `encrypt` hook so `systemd-cryptsetup` can read TPM tokens from the
LUKS2 header. Limine kernel cmdline uses **`rd.luks.name=LUKS-UUID=mappername`**
(not legacy `cryptdevice=`) with `root=UUID=…` for the btrfs `@` subvolume.

## Manual enrollment (post-install)

```sh
sudo hyperwebster-luks-tpm-enroll /dev/disk/by-partuuid/YOUR-LUKS-PARTUUID
```

Initramfs rebuild runs automatically after enrollment.

## Boot flow

Limine → UKI initramfs (`sd-encrypt`) → TPM unlock (or Plymouth passphrase) →
btrfs `@` → Plymouth splash → SDDM.

## Troubleshooting

| Symptom | Check / fix |
|---------|-------------|
| Passphrase prompt every boot | `sudo systemd-cryptenroll --list /dev/disk/by-partuuid/…` — no TPM token? Re-run `hyperwebster-luks-tpm-enroll`. |
| Enrollment fails in installer | Live ISO chroot may lack TPM access — enroll after first boot (same command). |
| Worked once, fails after BIOS update | PCR drift — passphrase fallback should still work; re-enroll (try `--pcrs 7+11`). |
| `sd-encrypt` missing | `grep sd-encrypt /etc/mkinitcpio.conf` — run `install-luks-tpm-unlock.sh` or `hyperwebster-update`. |
| Secure Boot off | PCR 7 alone may be insufficient — enroll with `--pcrs 7+11`. |

Verify TPM: `systemd-cryptenroll --tpm2-device=list` and `tpm2_pcrread sha256:7` (needs `tpm2-tools`).

After any enrollment or hook change, `hyperwebster-luks-tpm-enroll` rebuilds the initramfs and runs `limine-update` when available.

## Hardware testing

- Cold boot without controller/keyboard: should reach SDDM without passphrase
- After a BIOS/Secure Boot change: passphrase fallback should still work; re-enroll TPM

## Files

| File | Role |
|------|------|
| `hyperwebster-luks-tpm-enroll` | CLI wrapper around `systemd-cryptenroll` |
| `install-luks-tpm-unlock.sh` | Idempotent installer |
