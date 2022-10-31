#!/bin/sh

set -x

multipass delete k3s
multipass delete pub1
multipass delete pub2
multipass delete tc1
multipass delete tc2
multipass delete rs1
multipass delete rs2
multipass purge
rm -f k3s.yaml
