# GDClaw

Recreation of [Claw (1997)](https://en.wikipedia.org/wiki/Claw_(video_game)) in [Godot Engine](https://godotengine.org/) (for learning purposes).


## Godot 3 branch

This branch is meant to hold a version of the project where the features that were implemented prior to the update to godot 4 work properly.

## Status 

Development paused in the process of migrating from Godot 3 to Godot 4.

Current focus is to refactor the godot 3 version's project organization, and to fix bugs introduced in 3.x updates before switching focus to the main branch (godot 4).

Project mostly in hiatus.

## Latest update 

Added a 'godot3' branch that is mostly playable (aside from some bugs introduced when updating to Godot 3.x versions) until the main branch (Godot 4) is playable.

## How to run

Just clone the repo and it *should* work out of the box. (Still testing)

If there are any sound looping bugs, open the godot editor and go to Project -> Project Settings -> Import Defaults -> OGGVorbis and set Loop to false, then reimport the sound assets. (Or manually set the loop flag for each problematic sound file by selecting it on the FileSystem tab and changing the import options on the Import tab)

## Bugs in Godot 3 version

-Enemies fly away when defeated instead of bouncing and falling off.
