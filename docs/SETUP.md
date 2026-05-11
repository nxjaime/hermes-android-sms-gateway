# Detailed setup

These steps assume:
- you already have Tailscale on the phone and VPS
- both devices are on the same tailnet
- you want Hermes to send SMS through your real Android number
- you installed both `Termux` and `Termux:API` from the same source

Preferred app source:
- F-Droid for both `Termux` and `Termux:API`

Do not mix sources unless you know exactly what you are doing.
The Termux maintainers note that Termux and its plugins must come from the same signing source to work together.

## 1. Phone setup

Install these Android apps on PHONE first:
- `Termux`
- `Termux:API`

If you installed `Termux` from Google Play and cannot find a matching `Termux:API`, stop and reinstall both apps from the same source, preferably F-Droid.

Samsung specific note:
- `Termux:API` is in F-Droid, not the Google Play Store
- on some Samsung phones you may need to disable Auto Blocker temporarily to sideload F-Droid
- you may also need to allow restricted settings access before Android will allow SMS permission for `Termux:API`
- make these changes at your own risk and re-enable your preferred protections after setup

Run on PHONE in Termux:

```bash
pkg update
pkg install termux-api openssh
```

Use the Tailscale Android app on the phone. Do not expect `pkg install tailscale` to work in Termux.

Android settings on PHONE:
- Settings -> Apps -> Termux:API -> Permissions -> Allow SMS
- Settings -> Apps -> Termux -> Battery -> Unrestricted

Note:
- if `Termux` only shows microphone permission, that is normal
- SMS permission belongs to the separate `Termux:API` app

Test direct SMS on PHONE:

```bash
termux-sms-send -n YOUR_NUMBER "Test from Termux"
```

If you see this error:

```text
Termux:API is not yet available on Google Play
```

then your current Termux app is the Google Play build and it is not suitable for this workflow.

Clean fix:
- back up anything you need from Termux
- uninstall `Termux`
- uninstall any Termux plugins
- reinstall both `Termux` and `Termux:API` from F-Droid
- then restart this setup from the top

Verification:
- you receive the SMS

Start SSH and collect identity data on PHONE:

```bash
whoami
ip addr show tailscale0
passwd
sshd
ss -tlnp | grep 8022
```

If `ip addr show tailscale0` returns `Permission denied` or does not work on your phone, use one of these instead:
- open the Tailscale Android app and copy the device IPv4 shown there
- from your VPS, run `tailscale status` and find the phone's `100.x.x.x` address in the peer list

If `ss -tlnp | grep 8022` returns `Cannot open netlink socket: Permission denied`, try this fallback:

```bash
netstat -tln | grep 8022
```

If `netstat` also fails or says there is no TCP support, use this instead:

```bash
ssh -p 8022 localhost
```

Verification:
- note the Termux username from `whoami`
- it will usually look something like `u0_a123`
- note the Tailscale IPv4 address
- `passwd` should prompt you to create a Termux login password for SSH
- confirm SSH is listening on port 8022 using either `ss`, `netstat`, or a successful `ssh -p 8022 localhost` login prompt
- no output from `sshd` itself is normal

## 2. VPS setup

Stop using the phone for this section and switch to your VPS.

Run on VPS:

```bash
if ! command -v git >/dev/null 2>&1; then
  if command -v sudo >/dev/null 2>&1; then
    sudo apt-get update && sudo apt-get install -y git
  else
    apt-get update && apt-get install -y git
  fi
fi
git clone https://github.com/YOUR_GITHUB_USERNAME/hermes-android-sms-gateway.git
cd hermes-android-sms-gateway
./install.sh
```

Replace `YOUR_GITHUB_USERNAME` with the account that owns the repo you are cloning.
If you are reading this on GitHub, you can also click Code and copy the HTTPS clone URL directly.

The installer writes the config to:
- `~/.config/hermes-android-sms-gateway/config.env`

It also installs two commands into `~/.local/bin`:
- `send-phone-sms`
- `phone-gateway-check`

## 3. Install the SSH key on the phone

The installer prints a public key block. Copy that output and run on PHONE in Termux:

```bash
mkdir -p ~/.ssh
nano ~/.ssh/authorized_keys
```

Paste the public key, save, then run:

```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
```

## 4. Install the phone SMS script

On PHONE in Termux:

```bash
mkdir -p ~/bin
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
chmod +x ~/bin/send_sms.sh
```

## 5. Verify connectivity from the VPS

Run on VPS:

```bash
phone-gateway-check
phone-gateway-check --ssh
```

Expected:
- TCP port check succeeds
- SSH command prints `connected`
- SSH command prints the Termux username
- SSH command prints `termux-api-ok`

Notes:
- on the first successful SSH test, the helper auto-accepts a new host key for the phone
- if you get `Host key verification failed`, remove the stale key for the phone IP from `~/.ssh/known_hosts` and run the check again
- this check does not create `~/bin/send_sms.sh` on the phone; the send command will fail until Step 4 is completed

## 6. Send a test SMS from the VPS

Run on VPS:

```bash
send-phone-sms 5551234567 "Test from VPS through my Android phone"
```

Verification:
- recipient gets the text
- sender appears as your real phone number

## 7. Use from Hermes

After verification, Hermes can send texts by running:

```bash
send-phone-sms 5551234567 "Hello from Hermes"
```
