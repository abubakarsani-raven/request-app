#!/usr/bin/env bash
# Run the app against your local backend (localhost:4000).
# For iOS Simulator / Android Emulator: backend on host is reachable as localhost.
# For a physical device: pass your machine's IP, e.g.:
#   ./run_dev.sh --dart-define=API_BASE_URL=http://192.168.1.100:4000

set -e
cd "$(dirname "$0")"
flutter run --dart-define=ENV=development "$@"
