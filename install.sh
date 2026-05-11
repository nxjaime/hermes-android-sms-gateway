#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$HOME/.local/bin"
CONFIG_PATH="$ROOT_DIR/.env"
KEY_PATH_DEFAULT="$HOME/.ssh/phone_sms"

mkdir -p "$BIN_DIR"
mkdir -p "$HOME/.ssh"

prompt() {
  local var_name="$1"
  local prompt_text="$2"
  local default_value="${3:-}"
  local value
  if [ -n "$default_value" ]; then
    read -r -p "$prompt_text [$default_value]: " value
    value="${value:-$default_value}"
  else
    read -r -p "$prompt_text: " value
  fi
  printf -v "$var_name" '%s' "$value"
}

echo
echo "Hermes Android SMS Gateway installer"
echo

prompt PHONE_USER "Phone Termux username"
prompt PHONE_IP "Phone Tailscale IPv4"
prompt PHONE_PORT "Phone SSH port" "8022"
prompt PHONE_KEY_PATH "SSH private key path on this VPS" "$KEY_PATH_DEFAULT"

cat > "$CONFIG_PATH" <<EOF
PHONE_USER=$PHONE_USER
PHONE_IP=$PHONE_IP
PHONE_PORT=$PHONE_PORT
PHONE_KEY_PATH=$PHONE_KEY_PATH
EOF

if [ ! -f "$PHONE_KEY_PATH" ]; then
  echo
  echo "Generating SSH key at $PHONE_KEY_PATH"
  ssh-keygen -t ed25519 -f "$PHONE_KEY_PATH" -N "" >/dev/null
fi

install -m 0755 "$ROOT_DIR/bin/send-phone-sms" "$BIN_DIR/send-phone-sms"
install -m 0755 "$ROOT_DIR/bin/phone-gateway-check" "$BIN_DIR/phone-gateway-check"

echo
echo "Saved config to $CONFIG_PATH"
echo "Installed commands:"
echo "  $BIN_DIR/send-phone-sms"
echo "  $BIN_DIR/phone-gateway-check"
echo
echo "Next: run these commands in Termux on your phone"
echo
echo "mkdir -p ~/.ssh ~/bin"
echo "cat >> ~/.ssh/authorized_keys <<'EOF'"
cat "$PHONE_KEY_PATH.pub"
echo "EOF"
echo "chmod 700 ~/.ssh"
echo "chmod 600 ~/.ssh/authorized_keys"
echo "pkg update"
echo "pkg install termux-api openssh"
echo "# Tailscale should already be installed as the Android app"
echo "sshd"
echo
echo "Then copy this repo's phone scripts to your phone or paste the contents from docs/SETUP.md."
echo
echo "After the phone is ready, test with:"
echo "  phone-gateway-check --ssh"
echo '  send-phone-sms 5551234567 "hello from my phone"'
