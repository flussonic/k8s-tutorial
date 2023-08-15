#!/bin/sh

set -x

multipass delete watcher
multipass delete central
multipass delete streamer1
multipass delete streamer2
multipass delete manage
multipass purge
rm -f k3s.yaml
