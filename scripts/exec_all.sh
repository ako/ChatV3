#!/usr/bin/env bash
# Apply every MDL script in dependency order. (Numbers follow the brief's items; 05 runs before 02 because the agent's
# graph tool lives there, 09 before 03 because the chat shim needs the OpenRouter model, 10-12 last.)
set -euo pipefail
cd "$(dirname "$0")/../app"
for n in 01 05 02 04 06 07 08 09 03 10 11 12; do
  f=$(ls mdlsource/$n-*.mdl)
  ./mxcli exec "$f" -p BikeHelpdesk.mpr 2>&1 | grep -vE '^WARNING|^Using project|^Connected|info note' | sed "s|^|[$n] |"
done
