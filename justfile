# https://github.com/casey/just
set shell := ["bash", "-euo", "pipefail", "-c"]

_:
  @just --list

release:
  rm -rf release
  git worktree add --force release release
  nix-shell -p hugo go --run hugo
  cp -rT docs/ release/
  git -C release add .
  git -C release commit --amend
  git -C release push --force --set-upstream origin release
