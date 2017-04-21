---
title: Command Line Tricks
tags: resources
---

In which I have a place to record the magical incantations that I can never
remember and repeatedly Google.

## Search and Replace
Search and replace strings recursively in a directory. For some reason I can
never remember how to use sed even though it's simple after I look it up.
```
find <directory> -type f -exec sed -i 's/<original string>/<replacement string>/g' {} +
```
