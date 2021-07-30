#!/usr/bin/env bash
nix flake update
git add flake.lock
git commit -m "update flakes"
