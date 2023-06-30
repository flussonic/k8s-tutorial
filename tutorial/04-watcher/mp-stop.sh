#!/bin/sh

set -x

multipass delete manage
multipass delete streamer1
multipass delete streamer2
multipass purge
rm -f k3s.yaml
