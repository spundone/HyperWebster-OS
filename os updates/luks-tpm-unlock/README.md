# luks-tpm-unlock — TPM2 auto-unlock for LUKS2

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
LUKS2 header.

## Manual enrollment (post-install)

```sh
sudo hyperwebster-luks-tpm-enroll /dev/disk/by-partuuid/YOUR-LUKS-PARTUUID
```

Rebuild initramfs after hook migration:

```sh
sudo mkinitcpio -P
```

## Hardware testing

- Verify TPM is visible: `systemd-cryptenroll --tpm2-device=list`
- Cold boot without controller/keyboard: should reach SDDM without passphrase
- After a BIOS/Secure Boot change: passphrase fallback should still work; re-enroll TPM

## Files

| File | Role |
|------|------|
| `hyperwebster-luks-tpm-enroll` | CLI wrapper around `systemd-cryptenroll` |
| `install-luks-tpm-unlock.sh` | Idempotent installer |
