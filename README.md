# Hermes Android SMS Gateway

Send SMS from your real Android phone number through Hermes, Termux, and Tailscale.

This project turns an Android phone into a private SMS gateway.
Hermes runs on a VPS or Linux machine, SSHes into your phone over Tailscale, and asks Termux:API to send the text through your phone's normal SMS stack.

This is a good fit for:
- personal ops
- alerts
- low to moderate volume texting
- sending from your real number

This is not a good fit for:
- bulk marketing
- mass texting
- compliance heavy messaging

## Architecture

```
Hermes / VPS -> Tailscale -> SSH -> Termux -> Termux:API -> Android SMS -> carrier
```

## What you need

Phone side:
- Android phone with active SMS service
- Termux app
- Termux:API companion app
- Tailscale Android app

Important:
- Termux and Termux:API are separate apps
- install both from the same source
- preferred source is F-Droid
- do not mix a Play Store Termux install with an F-Droid Termux:API install

VPS side:
- Linux machine
- SSH client
- Tailscale on the same tailnet as the phone
- bash

## Quick start

Step 1. On the phone, install both Android apps:
- `Termux`
- `Termux:API`

Use the same source for both apps.
Preferred: install both from F-Droid.

Important Samsung / Android note:
- `Termux:API` is available in F-Droid, not the Google Play Store
- on some Samsung phones you may need to disable Auto Blocker temporarily to sideload F-Droid
- you may also need to explicitly allow restricted settings access before Android will let you grant SMS permission to `Termux:API`
- do this at your own risk and re-enable your preferred protections afterward

Why this matters:
- `Termux` and `Termux:API` are different apps
- `Termux` itself may not show SMS permission because the SMS access lives in `Termux:API`
- mixed install sources can fail because the apps must be signed compatibly to work together

Step 2. In Termux on the phone:

```bash
pkg update
pkg install termux-api openssh
```

Tailscale should be installed as the Android app, not with `pkg` inside Termux.

Android settings on PHONE:
- Settings -> Apps -> Termux:API -> Permissions -> Allow SMS
- Settings -> Apps -> Termux -> Battery -> Unrestricted

Note:
- if you only see microphone permission on `Termux`, that is normal
- SMS permission belongs to the separate `Termux:API` app

Step 4. Verify the phone can send SMS directly:

```bash
termux-sms-send -n YOUR_NUMBER "Test from phone"
```

If you get this error:

```text
Termux:API is not yet available on Google Play
```

that means your current Termux install is the Google Play build and it cannot use the Termux:API companion app for this workflow.

Clean fix:
- back up anything you need from Termux
- uninstall `Termux`
- uninstall any Termux plugins
- reinstall both `Termux` and `Termux:API` from F-Droid
- then repeat the setup from the README

Step 5. Stop using the phone for now and switch to your VPS.

Run on VPS:

```bash
command -v git >/dev/null 2>&1 || sudo apt-get update && sudo apt-get install -y git
git clone https://github.com/nxjaime/hermes-android-sms-gateway.git
cd hermes-android-sms-gateway
./install.sh
```

Step 6. Follow the prompts. The installer will:
- collect your phone username and Tailscale IP
- create a config file
- install a reusable wrapper command on the VPS
- generate an SSH key if needed
- print the exact next commands to run on the phone

Step 7. On the phone, run the printed bootstrap commands.

Step 8. Back on the VPS, test end to end:

```bash
send-phone-sms 5551234567 "Test from my phone through Hermes"
```

## Main commands

Send a text:

```bash
send-phone-sms 5551234567 "Hello from Hermes"
```

Check phone reachability:

```bash
phone-gateway-check
```

Dry run the SSH path without sending a text:

```bash
phone-gateway-check --ssh
```

## Google Messages Web?

It can be automated, but it is not the recommended foundation for unattended use.

Reasons:
- browser sessions expire
- QR pairing can break automation
- UI changes can break scripts
- popups and focus issues make it brittle

This repo uses the more reliable private path:

```
SSH -> Termux -> Termux:API
```

## Files

- `install.sh` - guided installer for the VPS
- `bin/send-phone-sms` - wrapper command installed on the VPS
- `bin/phone-gateway-check` - health check for the phone gateway
- `phone/bootstrap-phone.sh` - helper bootstrap script to run in Termux
- `phone/send_sms.sh` - script the VPS calls on the phone
- `.env.example` - VPS configuration template
- `docs/SETUP.md` - detailed step by step setup
- `docs/TROUBLESHOOTING.md` - common fixes
- `Handoff.md` - project state and next improvements

## Security notes

- Use Tailscale or another private network. Do not expose raw SSH or an SMS API to the public internet.
- Prefer SSH keys over passwords.
- Keep the phone physically secured because it becomes a trusted SMS sender.
- Be mindful of carrier policies and message volume.

## License

MIT
