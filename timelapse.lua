-- ffmpeg -r 15 -start_number 2548 -i IMGP%d.jpg -s 1024x768 -vcodec copy tt3.mp4

local dt = require "darktable"
local gettext = dt.gettext

dt.configuration.check_version(..., {4,0,0}, {5,0,0})
gettext.bindtextdomain("dt_timelapse", dt.configuration.config_dir.."/lua/")
local function _(msgid)
	return gettext.dgettext("dt_timelapse", msgid)
end

local pc_standard = _("PC standard")
local pro_standard = _("PRO standard")
local analog_tv_standard = _("Analog TV standard")
local digital_tv_standard = _("Digital TV standard")

local resolutions = {
	["QVGA"] = {
		["tooltip"] = "QVGA 320x240 (4:3)",
		["w"] = 320,
		["h"] = 240,
		["category"] = pc_standard
	},
	["HVGA"] = {
		["tooltip"] = "HVGA 480x320 (3:2)",
		["w"] = 480,
		["h"] = 320,
		["category"] = pc_standard
	},
	["VGA"] = {
		["tooltip"] = "VGA 640x480 (4:3)",
		["w"] = 640,
		["h"] = 480,
		["category"] = pc_standard
	},
	["HDTV 720p"] = {
		["tooltip"] = "HDTV 720p 1280x720 (16:9)",
		["w"] = 1280,
		["h"] = 720,
		["category"] = pc_standard
	},
	["HDTV 1080p"] = {
		["tooltip"] = "HDTV 1080p 1920x1080 (16:9)",
		["w"] = 1920,
		["h"] = 1080,
		["category"] = pc_standard
	},
	["Cinema TV"] = {
		["tooltip"] = "Cinema TV 2560x1080 (21:9)",
		["w"] = 2560,
		["h"] = 1080,
		["category"] = pc_standard
	},
	["2K"] = {
		["tooltip"] = "2K 2048x1152 (16:9)",
		["w"] = 2048,
		["h"] = 1152,
		["category"] = pro_standard
	},
	["4K"] = {
		["tooltip"] = "4K 4096x2304 (16:9)",
		["w"] = 4096,
		["h"] = 2304,
		["category"] = pro_standard
	}
}

local framerates = {"15", "16", "23.98", "24", "25", "29,97", "30", "48", "50", "59,94", "60"}

local formats = {
	["AVI"] = {
		["extension"] = "avi",
		["codecs"] = {"h263", "h264", "mpeg4", "mpeg2video", "h265", "raw", "vp9"}
	},
	["Matroska"] = {
		["extension"] = "mkv",
		["codecs"] = {"h263", "h264", "mpeg4", "mpeg2video", "h265", "raw", "vp9"}
	},
	["WebM"] = {
		["extension"] = "webm",
		["codecs"] = {"h263", "h264", "mpeg4", "mpeg2video", "h265", "raw", "vp9"}
	},
	["MP4"] = {
		["extension"] = "mp4",
		["codecs"] = {"h263", "h264", "mpeg4", "mpeg2video"}
	},
	["QuickTime"] = {
		["extension"] = "mov",
		["codecs"] = {"h263", "h264", "mpeg4", "mpeg2video"}
	}
}

res_list = {}
for i, v in pairs(resolutions) do
  table.insert(res_list, v['tooltip'])
end

table.sort(res_list)

format_list = {}
for i,v in pairs(formats) do
  table.insert(format_list, i)
end

table.sort(format_list)

codec_list = formats['AVI']['codecs']
table.sort(codec_list)

-- libx265 libx264
--
local function extract_resolution(description)
  for _, v in pairs(resolutions) do
    if v['tooltip'] == description then
      return v['w']..'x'..v['h']
    end
  end
  return "100x100"
end

local framerates_selector = dt.new_widget("combobox")
{
  label = _("framerate"),
  tooltip = _("select framerate of output video"),
  value = 1,
  changed_callback = function(val) end,
  reset_callback = function(val) end,
  table.unpack(framerates)
}

local res_selector = dt.new_widget("combobox")
{
  label = _("resolution"),
  tooltip = _("select resolution of output video"),
  value = 1,
  changed_callback = function(val) end,
  reset_callback = function(val) end,
  table.unpack(res_list)
}

local codec_selector = dt.new_widget("combobox"){
  label = _("codec"),
  tooltip = _("select codec"),
  value = 1,
  changed_callback = function(val) end,
  reset_callback = function(val) end,
  table.unpack(codec_list)
}

local format_selector = dt.new_widget("combobox"){
  label = _("format container"),
  tooltip = _("select format of output video"),
  value = 1,
  changed_callback = function(val) 
    local items = #codec_selector
    codec_list = formats[val.value]['codecs']
    table.sort(codec_list)
    local choices = #codec_list
    for i, name in ipairs(codec_list) do
      codec_selector[i]=name
    end
    if choices < items then
      for j=items, choices+1, -1 do
        codec_selector[j] = nil
      end
    end
  end,
  reset_callback = function(val) end,
  table.unpack(format_list)
}

local output_directory = nil

file_chooser_button_path = dt.new_widget("file_chooser_button")
{
    title = _('Select export path'),  -- The title of the window when choosing a file
    is_directory = true,             -- True if the file chooser button only allows directories to be selecte
    tooltip =_('select the target directory for the timelapse. \nthe filename is created automatically.'),
    changed_callback = function(w)
      output_directory = w.value
    end
}

local module_widget = dt.new_widget("box") {
  orientation = "vertical",
  res_selector,
  framerates_selector,
  format_selector,
  codec_selector,
  file_chooser_button_path
}

local function support_format(storage, format)
  return true
end

local function init_export(storage, format, images, high_quality, extra_data)
  extra_data['tmp_dir'] = dt.configuration.tmp_dir .. '/dt_timelapse_' .. os.time()
  extra_data['fps'] = framerates_selector.value
  extra_data['res'] = extract_resolution(res_selector.value)
  extra_data['codec'] = codec_selector.value
  extra_data['img_ext'] = '.'..format.extension
  extra_data['out_ext'] = formats[format_selector.value]['extension']
  if output_directory == nil then
    extra_data['out'] = images[1].path --string.match(images[1], "(.*)/.+")
  else
    extra_data['out'] = output_directory
  end
end

local function export(extra_data)
  local dir = extra_data['tmp_dir']
  local fps = extra_data['fps']
  local res = extra_data['res']
  local codec = extra_data['codec']
  local img_ext = extra_data['img_ext']
  --local path = file_chooser_button_path.value.."/out.mp4"
  local path = '"'..extra_data['out']..'/out.'..extra_data['out_ext']..'"'
  local cmd = "ffmpeg -y -r "..fps.." -i "..dir.."/%d"..img_ext.." -s "..res.." -vcodec "..codec.." "..path
  return dt.control.execute(cmd)
end

local function finalize_export(storage, image_table, extra_data)
    local tmp_dir = extra_data['tmp_dir']
    
    dt.print(_('prepare merge process'))
    
    local result = dt.control.execute('mkdir -p '..tmp_dir)

    if result ~= 0 then dt.print(_("ERROR: cannot create temp directory")) end
    
    local images = {}
    for _, v in pairs(image_table) do table.insert(images, v) end
    table.sort(images)
    local count = 0
    for _,v in pairs(images) do
      dt.control.execute('mv '..v..' '..tmp_dir..'/'..count..extra_data['img_ext'])
      count = count + 1
    end
    dt.print("Start video building...")
    local result = export(extra_data)
    if result ~= 0 then 
      dt.print(_("ERROR: cannot build image, see console for more info")) 
    else
      dt.print("SUCCESS")
    end

    dt.control.execute('rm -rf '..tmp_dir)
end

dt.register_storage(
  "module_dt_timelapse", 
  _("timelapse video"), 
  nil, 
  finalize_export,
  support_format, 
  init_export, 
  module_widget
)

