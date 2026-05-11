# Troubleshooting

## `termux-sms-send: command not found`

Fix on PHONE:

```bash
pkg install termux-api
```

Also make sure the Android app `Termux:API` is installed.

Important:
- `Termux` and `Termux:API` are different apps
- `Termux` itself may not show SMS permission
- SMS permission belongs to `Termux:API`

## `Termux:API is not yet available on Google Play`

If `termux-sms-send` returns this message, your current `Termux` app is the Google Play build.
That build is not suitable for this workflow.

Clean fix:
- back up anything you need from Termux
- uninstall `Termux`
- uninstall any Termux plugins
- reinstall both `Termux` and `Termux:API` from F-Droid
- restart the setup from the beginning

## `ssh -p 8022 localhost` asks for a password

That is normal.
Termux SSH uses the Termux account password unless you later switch to SSH keys.

If you have not set one yet, create it in Termux:

```bash
passwd
```

Then use that password for the localhost SSH test and for initial VPS to phone SSH login.
Later in the setup, the repo switches you to SSH keys so you do not need to keep using the password.

## SSH times out

Check on PHONE:

```bash
whoami
ip addr show tailscale0
pgrep -a sshd
ss -tlnp | grep 8022
```

If the `ss` command returns `Cannot open netlink socket: Permission denied`, try:

```bash
netstat -tln | grep 8022
```

If `netstat` also fails or reports no TCP support, try:

```bash
ssh -p 8022 localhost
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

Then use the Tailscale Android app for connectivity. To inspect the phone's Tailscale address, try one of these:

```bash
ip addr show tailscale0
```

If that returns `Permission denied`, use one of these fallback methods instead:
- open the Tailscale Android app and copy the device IPv4
- from your VPS, run `tailscale status` and find the phone's `100.x.x.x` peer address

## `Permission denied` when checking `tailscale0`

Some Android and Samsung setups do not allow the Termux shell to read the interface details cleanly.
That does not necessarily mean Tailscale is broken.

Use one of these instead:
- in the Tailscale Android app, open the device details and copy the `100.x.x.x` address
- on the VPS, run `tailscale status` and locate the phone in the peer list

## `I only see Termux in the Play Store`

That is a common point of confusion.

`Termux` and `Termux:API` are separate apps.
You need both.

For this project, the safest path is:
- install `Termux` from F-Droid
- install `Termux:API` from F-Droid

Why:
- the Termux maintainers document that the main app and plugin apps must come from the same signing source to work together
- mixed sources can break plugin access
- Google Play Termux is described by the maintainers as an experimental branch with missing functionality compared to the stable F-Droid build
- `Termux:API` is in F-Droid, not the Google Play Store

If you already installed `Termux` from Google Play, the clean fix is usually:
- back up anything you need from Termux
- uninstall Termux and any Termux plugins
- reinstall both `Termux` and `Termux:API` from the same source, preferably F-Droid

Samsung note:
- on some Samsung phones you may need to disable Auto Blocker temporarily to sideload F-Droid
- you may also need to allow restricted settings access before Android will allow SMS permission for `Termux:API`
- do this at your own risk and re-enable your preferred protections afterward

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

## `git: not found`

If you see this while following the repo instructions, make sure you are on the VPS, not the phone.
The repository clone and installer steps are meant to run on the VPS.

On VPS:

```bash
command -v git >/dev/null 2>&1 || sudo apt-get update && sudo apt-get install -y git
```

Then continue with the clone step on the VPS.

## `send-phone-sms` works manually but not from Hermes

Check:
- the command is in the PATH Hermes sees
- the `.env` file exists in the repo root
- `HERMES_ANDROID_SMS_CONFIG` is set if you moved the config file
