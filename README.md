# This repo is now *deprecated*! Please go to the main darktable lua-scripts repository for new version. Plugin is named video_ffmpeg (https://github.com/darktable-org/lua-scripts/blob/master/contrib/video_ffmpeg.lua) 

---

## [Darktable](darktable.org) plugin (lua script) for creating timelapse video

This plugin allow to export selected images as a timelapse video thanks to `ffmpeg` tool. `ffmpeg` is required for export. Some of video codecs and formats may be inaccessible on some platforms.

## CURRENT VERSION REQUIRE SOME ADDITIONAL CHANGES IN DARKTABLE CODEBASE, I HOPE IT WILL BE AVAILABLE IN MASTER BRANCH SOON

### TODO
 - [x] allow to simple export for specified location
 - [ ] review of specified formats/codecs/framerates
 - [ ] automatic detect available formats/codecs and shrink predefined list
 - [ ] persist previous selected parameters
 - [ ] allow to add music to video
 - [ ] add translations

### Install (Manual)
- copy `timelapse.lua` to your darktable config directory under lua folder (by default `~/.config/darktable/lua`) 
- edit your `luarc` (by default `~/.config/darktable/luarc`)
- put `require 'timelapse'`
- save file, open Darktable, select images and go to export module - timelapse should be available as an option

### Install (Plugin manager)

...plugin manager is under preparation... soon :)
