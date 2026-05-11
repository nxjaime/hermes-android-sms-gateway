#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

mkdir -p "$HOME/bin" "$HOME/.ssh"
pkg update
pkg install -y termux-api openssh

cat > "$HOME/bin/send_sms.sh" <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
if [ "$#" -lt 2 ]; then
  echo "Usage: send_sms.sh <number> <message>" >&2
  exit 1
fi
number="$1"
shift
message="$*"
termux-sms-send -n "$number" "$message"
EOF
chmod +x "$HOME/bin/send_sms.sh"

echo
echo "Grant SMS permission to Termux:API in Android Settings if you have not already."
echo "Set Termux battery mode to Unrestricted."
echo
echo "Starting sshd"
sshd
echo "Verification"
whoami
ip addr show tailscale0 || true
ss -tlnp | grep 8022 || true
