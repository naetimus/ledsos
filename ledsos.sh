#!/usr/bin/env bash

# Copyright 2025 by Nate Carmody
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, version 3 of the License.

# Usage:
# ledsos.sh /dev/sdX
# Flash a disk's LED in Morse SOS (··· --- ···) until spacebar is pressed.

set -u

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 /dev/sdX"
  exit 1
fi

DEV="$1"

if [[ ! -b "$DEV" ]]; then
  echo "Error: $DEV is not a block device."
  exit 1
fi

# Tweak these for slower/faster SOS.
SHORT_ON=0.3   # seconds LED activity for a short flash
LONG_ON=0.9    # seconds LED activity for a long flash
BETWEEN=0.2    # seconds between flashes within SOS
PAUSE=1.0      # pause between full SOS patterns

# Small read that should trigger the disk LED.
# Using iflag=direct to avoid cache hiding activity (if supported).
do_flash() {
  local duration="$1"

  # Trigger some I/O on the disk to light the LED.
  dd if="$DEV" of=/dev/null bs=4K count=16 iflag=direct \
    >/dev/null 2>&1

  # Keep the timing roughly consistent with the desired flash length.
  sleep "$duration"
}

# Non-blocking check for spacebar.
check_space() {
  local key
  # -r: raw, -s: silent, -n1: one char, -t0.01: 10ms timeout
  if read -rsn1 -t 0.01 key; then
    if [[ "$key" == " " ]]; then
      echo
      echo "Spacebar pressed, stopping SOS."
      exit 0
    fi
  fi
}

echo "Flashing SOS on $DEV (··· --- ···). Press SPACE to stop."

while :; do
  # Three short flashes
  for i in 1 2 3; do
    check_space
    do_flash "$SHORT_ON"
    check_space
    sleep "$BETWEEN"
  done

  # Three long flashes
  for i in 1 2 3; do
    check_space
    do_flash "$LONG_ON"
    check_space
    sleep "$BETWEEN"
  done

  # Three short flashes
  for i in 1 2 3; do
    check_space
    do_flash "$SHORT_ON"
    check_space
    sleep "$BETWEEN"
  done

  # Pause before repeating the SOS pattern.
  for i in 1 2 3 4 5; do
    check_space
    sleep "$(awk "BEGIN {print $PAUSE/5}")"
  done
done
