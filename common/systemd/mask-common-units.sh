#!/usr/bin/env bash
set -Eeuo pipefail

units=(
  console-getty.service
  dev-hugepages.mount
  dev-mqueue.mount
  getty.target
  systemd-logind.service
  systemd-modules-load.service
  systemd-networkd.service
  systemd-networkd.socket
  systemd-resolved.service
  systemd-udevd-control.socket
  systemd-udevd-kernel.socket
  systemd-udevd.service
  systemd-udevd-trigger.service
  sys-fs-fuse-connections.mount
)

for unit in "${units[@]}"; do
  systemctl mask "$unit" >/dev/null 2>&1 || true
done
