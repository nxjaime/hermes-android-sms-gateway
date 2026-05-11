# Detailed setup

These steps assume:
- you already have Tailscale on the phone and VPS
- both devices are on the same tailnet
- you want Hermes to send SMS through your real Android number

## 1. Phone setup

Run on PHONE in Termux:

```bash
pkg update
pkg install termux-api openssh tailscale
```

Android settings on PHONE:
- Settings -> Apps -> Termux:API -> Permissions -> Allow SMS
- Settings -> Apps -> Termux -> Battery -> Unrestricted

Test direct SMS on PHONE:

```bash
termux-sms-send -n YOUR_NUMBER "Test from Termux"
```

Verification:
- you receive the SMS

Start SSH and collect identity data on PHONE:

```bash
whoami
tailscale ip -4
sshd
ss -tlnp | grep 8022
```

Verification:
- note the Termux username from `whoami`
- note the Tailscale IPv4 address
- confirm `sshd` is listening on port 8022
- no output from `sshd` itself is normal

## 2. VPS setup

Run on VPS:

```bash
git clone https://github.com/YOUR_GITHUB_USERNAME/hermes-android-sms-gateway.git
cd hermes-android-sms-gateway
./install.sh
```

The installer writes `.env` and installs two commands into `~/.local/bin`:
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
