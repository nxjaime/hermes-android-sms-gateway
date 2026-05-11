# Troubleshooting

## `termux-sms-send: command not found`

Fix on PHONE:

```bash
pkg install termux-api
```

Also make sure the Android app `Termux:API` is installed.

## SSH times out

Check on PHONE:

```bash
whoami
ip addr show tailscale0
pgrep -a sshd
ss -tlnp | grep 8022
```

Common causes:
- wrong Tailscale IP
- sshd not running
- phone not on the same tailnet
- Android killed Termux in the background

## `unable to locate package tailscale`

That is expected on many Termux installs.

Use:

```bash
pkg install termux-api openssh
```

Then use the Tailscale Android app for connectivity. To inspect the phone's Tailscale address from Termux, try:

```bash
ip addr show tailscale0
```

## SSH says permission denied

Common causes:
- wrong username
- public key was not added correctly to `~/.ssh/authorized_keys`
- file permissions are too open

Fix on PHONE:

```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
```

## SMS command runs but no text arrives

Check on PHONE:
- SMS permission is granted to Termux:API
- phone has carrier service
- Android is not blocking the app
- message volume is not triggering carrier restrictions

Manual verification on PHONE:

```bash
termux-sms-send -n YOUR_NUMBER "manual test"
```

## `phone-gateway-check` says config not found

Run on VPS:

```bash
./install.sh
```

## `send-phone-sms` works manually but not from Hermes

Check:
- the command is in the PATH Hermes sees
- the `.env` file exists in the repo root
- `HERMES_ANDROID_SMS_CONFIG` is set if you moved the config file
