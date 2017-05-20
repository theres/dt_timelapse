# [Darktable](darktable.org) plugin (lua script) for creating timelapse video

This plugin allow to export selected images as a timelapse video thanks to `ffmpeg` tool. `ffmpeg` is required for export. Some of video codecs and formats may be inaccessible on some platforms.

# THIS PLUGIN IS STILL `WORK IN PROGRESS`

## TODO
 - [x] allow to simple export for specified location
 - [ ] review of specified formats/codecs/framerates
 - [ ] automatic detect available formats/codecs and shrink predefined list
 - [ ] persist previous selected parameters
 - [ ] allow to reset destination
 - [ ] allow to add music to video
 - [ ] add translations

## Install (Manual)
- copy `timelapse.lua` to your darktable config directory under lua folder (by default `~/.config/darktable/lua`) 
- edit your `luarc` (by default `~/.config/darktable/luarc`)
- put `require 'timelapse'`
- save file, open Darktable, select images and go to export module - timelapse should be available as an option

## Install (Plugin manager)

...plugin manager is under preparation... soon :)
