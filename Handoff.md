# Handoff

Sprint: 0
State: scaffolded

Goal:
Create a reusable open source starter that lets Hermes send SMS from a real Android number using Termux, Termux:API, SSH, and Tailscale.

What exists:
- guided VPS installer
- VPS wrapper for sending SMS
- health check command
- phone bootstrap script
- detailed setup and troubleshooting docs

Suggested next sprint:
1. Add inbound SMS polling or webhook style reply syncing
2. Add optional Tasker integration for richer automation
3. Add optional QR code setup helper for Tailscale and SSH key install
4. Add automated test harness around config and wrapper scripts

Known limitations:
- outbound SMS only
- depends on phone power, connectivity, and Android permission state
- assumes Tailscale connectivity between phone and VPS
