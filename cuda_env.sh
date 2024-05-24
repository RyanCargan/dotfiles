#!/usr/bin/env bash

# Run hvm and similar installs like this
# steam-run cargo +nightly install hvm --verbose

# Lib exploration
# ls -lt /nix/store/*cudart*

export LD_LIBRARY_PATH=/nix/store/dn86qk9pfx56wvmlxhxv6fskkzb6a5w1-cudatoolkit-12.2.0/lib64:$LD_LIBRARY_PATH
export LIBRARY_PATH=/nix/store/bgzi3gk5m16df8gc6gxyq3r3cjwy9ap8-cuda_cudart-12.2.140/lib:$LD_LIBRARY_PATH

export C_INCLUDE_PATH=/nix/store/dn86qk9pfx56wvmlxhxv6fskkzb6a5w1-cudatoolkit-12.2.0/include:$C_INCLUDE_PATH
export CPLUS_INCLUDE_PATH=/nix/store/dn86qk9pfx56wvmlxhxv6fskkzb6a5w1-cudatoolkit-12.2.0/include:$CPLUS_INCLUDE_PATH
