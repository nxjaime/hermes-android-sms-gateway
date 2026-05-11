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
- Termux
- Termux:API app
- Tailscale

VPS side:
- Linux machine
- SSH client
- Tailscale on the same tailnet as the phone
- bash

## Quick start

Step 1. On the phone, install the Android app `Termux:API`.

Step 2. In Termux on the phone:

```bash
pkg update
pkg install termux-api openssh tailscale
```

Step 3. On the phone, grant permissions:
- Settings -> Apps -> Termux:API -> Permissions -> Allow SMS
- Settings -> Apps -> Termux -> Battery -> Unrestricted

Step 4. Verify the phone can send SMS directly:

```bash
termux-sms-send -n YOUR_NUMBER "Test from phone"
```

Step 5. Clone this repo on your VPS and run the installer:

```bash
git clone https://github.com/YOUR_GITHUB_USERNAME/hermes-android-sms-gateway.git
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
