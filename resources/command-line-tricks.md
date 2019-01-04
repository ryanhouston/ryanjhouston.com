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

## GIT Recover Deleted Stash

Find dangling commits which have not yet been cleaned up:
```
git fsck --no-reflog | awk '/dangling commit/ {print $3}' | xargs git show > dangles.txt
```

Then use `tig` to view and traverse the dangling commits with nice highlighting
and search for some identifier in what you are looking for:
```
cat dangles.txt | tig
```

Grab the commit sha and `git stash apply <sha>`.

Credit to [this post](https://community.atlassian.com/t5/Sourcetree-questions/Retrieve-a-deleted-stash/qaq-p/162673)
for the `git fsck` tip.

