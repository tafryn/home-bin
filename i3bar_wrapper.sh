#!/usr/bin/env bash

# This wrapper ensures that non-posix compliant shells, like fish, don't
# screw up i3bar's formatting.

export SHELL=/usr/bin/bash

i3bar "$@"
