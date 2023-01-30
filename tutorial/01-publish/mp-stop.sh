#!/bin/sh

set -x

multipass delete k3s
multipass delete pub1
multipass purge
rm -f k3s.yaml
