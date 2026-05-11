# Hermes Android SMS Gateway

Send SMS from your real Android phone number through Hermes, Termux, and Tailscale.

This project turns an Android phone into a private SMS gateway. Hermes runs on a VPS or Linux machine, SSHes into your phone over Tailscale, and asks Termux:API to send the text through your phone's normal SMS stack.

## Architecture

```text
Hermes / VPS -> Tailscale -> SSH -> Termux -> Termux:API -> Android SMS -> carrier
```

## Good fit

- personal ops
- alerts
- low to moderate volume texting
- sending from your real phone number
- Hermes-driven workflows on a VPS

## Not a good fit

- bulk marketing
- mass texting
- compliance-heavy messaging
- high-volume outbound campaigns

## What you need

Phone side:
- Android phone with active SMS service
- Termux
- Termux:API
- Tailscale Android app

VPS side:
- Linux machine
- SSH client
- Tailscale on the same tailnet as the phone
- bash

Important:
- Termux and Termux:API are separate apps
- install both from the same source
- preferred source is F-Droid for both
- do not mix a Play Store Termux install with an F-Droid Termux:API install

## Quick start

### 1. On PHONE, install the Android apps

Install:
- `Termux`
- `Termux:API`
- `Tailscale`

Use the same source for `Termux` and `Termux:API`.
Preferred: F-Droid for both.

Samsung notes:
- `Termux:API` is available in F-Droid, not the Google Play Store
- on some Samsung phones you may need to disable Auto Blocker temporarily to sideload F-Droid
- you may also need to allow restricted settings before Android will let you grant SMS permission to `Termux:API`

Why this matters:
- `Termux` itself may only show microphone permission
- SMS permission belongs to the separate `Termux:API` app
- mixed install sources can break plugin access

### 2. On PHONE in Termux, install packages

```bash
pkg update
pkg install termux-api openssh
```

Do not try `pkg install tailscale` in Termux for this workflow. Use the Android Tailscale app.

In Android settings:
- Apps -> Termux:API -> Permissions -> Allow SMS
- Apps -> Termux -> Battery -> Unrestricted

### 3. On PHONE, verify direct SMS works

```bash
termux-sms-send -n YOUR_NUMBER "Test from phone"
```

If you see:

```text
Termux:API is not yet available on Google Play
```

then your current Termux install is the Google Play build. Clean fix:
- back up anything you need from Termux
- uninstall `Termux`
- uninstall any Termux plugins
- reinstall both `Termux` and `Termux:API` from F-Droid
- restart the setup

### 4. On PHONE, start SSH and collect details

First set a Termux password once:

```bash
passwd
```

Then run:

```bash
whoami
ip addr show tailscale0
sshd
ss -tlnp | grep 8022
```

Expected:
- `whoami` gives the Termux username, often something like `u0_a123`
- `sshd` may print nothing
- `ss` should show SSH listening on port `8022`

If `ss` fails with `Cannot open netlink socket: Permission denied`, try:

```bash
netstat -tln | grep 8022
```

If that also fails, use this practical check:

```bash
ssh -p 8022 localhost
```

If `ip addr show tailscale0` fails, get the phone IP from:
- the Tailscale Android app
- or `tailscale status` on the VPS

### 5. Stop using the phone and switch to the VPS

This is the handoff point. The next commands run on the VPS, not on the phone.

If `git` is not installed on the VPS:

```bash
if ! command -v git >/dev/null 2>&1; then
  if command -v sudo >/dev/null 2>&1; then
    sudo apt-get update && sudo apt-get install -y git
  else
    apt-get update && apt-get install -y git
  fi
fi
```

Then clone this repo. Best option: click GitHub's Code button and copy the HTTPS URL.

```bash
git clone <PASTE_THE_HTTPS_CLONE_URL_FROM_GITHUB>
cd hermes-android-sms-gateway
./install.sh
```

Notes:
- many VPS sessions run as `root` and do not have `sudo`
- do not type a literal placeholder GitHub username
- if you already have the repo, use `git pull` instead of cloning again

### 6. On the VPS, follow the installer prompts

The installer will:
- collect your phone username and Tailscale IP
- write config to `~/.config/hermes-android-sms-gateway/config.env`
- install `send-phone-sms` and `phone-gateway-check` into `~/.local/bin`
- generate an SSH key if needed
- print the public key you must add on the phone

### 7. Back on PHONE, finish the phone-side setup

Add the printed public key to `~/.ssh/authorized_keys` in Termux.

Then create the phone-side send script:

```bash
mkdir -p ~/.ssh ~/bin
nano ~/bin/send_sms.sh
```

Paste:

```bash
#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
number="$1"
shift
message="$*"
termux-sms-send -n "$number" "$message"
```

Then run:

```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
chmod +x ~/bin/send_sms.sh
```

Important:
- `phone-gateway-check --ssh` only proves SSH access and that `termux-sms-send` exists
- `send-phone-sms` also requires `~/bin/send_sms.sh` to exist on the phone
- if you skip this step, send will fail with `~/bin/send_sms.sh: No such file or directory`

You can also copy and run `phone/bootstrap-phone.sh` from this repo inside Termux.

### 8. Back on VPS, verify SSH before the first SMS

```bash
phone-gateway-check --ssh
```

Expected output includes:
- `connected`
- the Termux username
- `termux-api-ok`

Notes:
- on first connect, the helper auto-accepts a brand new host key for the phone
- if the phone was reinstalled or the SSH host key changed, remove the stale key from `~/.ssh/known_hosts`

Example:

```bash
ssh-keygen -R PHONE_IP
```

### 9. Send a test SMS from the VPS

```bash
send-phone-sms 5551234567 "Test from my phone through Hermes"
```

## Main commands

Send a text from the VPS:

```bash
send-phone-sms 5551234567 "Hello from Hermes"
```

Check reachability from the VPS:

```bash
phone-gateway-check
phone-gateway-check --ssh
```

Rule of thumb:
- PHONE / Termux: `termux-sms-send`, `sshd`, `~/bin/send_sms.sh`
- VPS: `phone-gateway-check`, `send-phone-sms`

## Using this from Hermes

This works best as a Hermes skill so the agent knows the correct command and health check for this environment.

Example local skill behavior:
- verify the gateway with `phone-gateway-check --ssh` when needed
- send the message with `send-phone-sms PHONE_NUMBER "message"`

If you want contact lookup before texting, pair this gateway with a Google Workspace integration.
That lets Hermes pull numbers from Google Contacts first, then send the SMS through this gateway.

Recommended flow:
1. look up the contact in Google Contacts
2. confirm the right number if needed
3. run `send-phone-sms`

## Files

- `install.sh` - guided installer for the VPS
- `bin/send-phone-sms` - wrapper command installed on the VPS
- `bin/phone-gateway-check` - health check for the phone gateway
- `phone/bootstrap-phone.sh` - helper bootstrap script for Termux
- `phone/send_sms.sh` - phone-side script the VPS calls
- `.env.example` - VPS configuration template
- `docs/SETUP.md` - detailed setup guide
- `docs/TROUBLESHOOTING.md` - common fixes
- `Handoff.md` - project state and next improvements

## Common failure patterns

- `sudo: command not found`
  - common on root-run VPS sessions; use `apt-get` directly

- `Repository not found` during clone
  - you used a literal placeholder URL instead of the real GitHub clone URL

- `Config not found`
  - rerun `./install.sh` from the repo on the VPS
  - config lives at `~/.config/hermes-android-sms-gateway/config.env`

- `Host key verification failed`
  - remove the stale host key from `~/.ssh/known_hosts`

- `~/bin/send_sms.sh: No such file or directory`
  - create the phone-side script in Termux and make it executable

- `phone-gateway-check: command not found`
  - you ran a VPS command on the phone

- SSH timeout
  - confirm Tailscale IP, `sshd`, and port `8022` on the phone

## Security notes

- Use Tailscale or another private network. Do not expose raw SSH or an SMS API to the public internet.
- Prefer SSH keys over passwords.
- Keep the phone physically secured because it becomes a trusted SMS sender.
- Be mindful of carrier policies and message volume.

## License

MIT
