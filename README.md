# ragtag
a command-line tool for editing iTunes tags

## What on earth is this?
It's a command-line tool for running find-and-replace operations on your iTunes tags. 
You select a set of files in iTunes, tab to Terminal, and run some ragtag commands
and ragtag matches the regex and updates the track name appropriately.
It also strips whitespace and can fix track numbering issues. You can think of it as
a sort of `sed` and `awk` for iTunes.

## That's the stupidest thing I've ever heard.
Believe it or not, I've wanted this for years. I finally got tired of fixing iTunes 
tags by hand, and I wanted to write at least something in Swift. So, here we are. 

## How do you use it? 

```bash
# deletes all "(Prod ...)" parentheticals
./ragtag --replace "\\(Prod .*\\)" "" --strip

# renumbers the selected items
./ragtag --renumber

# change a tag other than the name
./ragtag --tag artist --replace "Prince" "The Artist"
```

## Are you going to add to this in the future? 

Sadly enough, yes. I still want to implement proper song-title capitalization 
heuristics. The algorithm for doing so is quite subtle.
