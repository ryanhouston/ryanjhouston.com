---
title: Tmux Cheatsheet
tags: resources
---

A quick cheatsheet for tmux things that I look up repeatedly.

## Change window order

Use `<prefix> :` to get to tmux-command prompt first.

  - `swap-window -t <num>` where `<num>` is the target window index to move the
    current window
  - `swap-window -s <source> -t <target>` where `<source>` is the window index
    to move to `<target>` index.

## Move Panes

  - `break-pane` break pane into new window
  - `swap-window -s <source> -t <target>` (pretty self explanatory)
  - `swap-window -t <target>` swaps the current pane with the target pane
  - `<prefix> }` swap with pane to the left (or counter-clockwise) direction
  - `<prefix> {` swap with pane right (or clockwise) direction
  - `<prefix> q` will show pane numbers for use in above commands
  - `<prefix> z` toggle pane zoom. Makes the current pane fullscreen.
  - `<prefix> <space>` toggles between basic layouts
