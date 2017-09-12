---
title: Vim Notes
tags: resources
---

Some running notes of Vim things I want to remember.

## Replace all instances of current highlighted word

  - Search as normal using `/<search string` or find word and press `*` to
    highlight all instances.
  - Then `:%s//<new string>/g` leaving the first field empty will use the last
    searched pattern.
