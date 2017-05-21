-- ffmpeg -r 15 -start_number 2548 -i IMGP%d.jpg -s 1024x768 -vcodec copy tt3.mp4

local dt = require 'darktable'
local gettext = dt.gettext

dt.configuration.check_version(..., {4,0,0}, {5,0,0})
gettext.bindtextdomain('dt_timelapse', dt.configuration.config_dir..'/lua/')
local function _(msgid)
  return gettext.dgettext('dt_timelapse', msgid)
end

local resolutions = {
  ['QVGA'] = {
    ['tooltip'] = 'QVGA 320x240 (4:3)',
    ['w'] = 320,
    ['h'] = 240
  },
  ['HVGA'] = {
    ['tooltip'] = 'HVGA 480x320 (3:2)',
    ['w'] = 480,
    ['h'] = 320
  },
  ['VGA'] = {
    ['tooltip'] = 'VGA 640x480 (4:3)',
    ['w'] = 640,
    ['h'] = 480
  },
  ['HDTV 720p'] = {
    ['tooltip'] = 'HDTV 720p 1280x720 (16:9)',
    ['w'] = 1280,
    ['h'] = 720
  },
  ['HDTV 1080p'] = {
    ['tooltip'] = 'HDTV 1080p 1920x1080 (16:9)',
    ['w'] = 1920,
    ['h'] = 1080
  },
  ['Cinema TV'] = {
    ['tooltip'] = 'Cinema TV 2560x1080 (21:9)',
    ['w'] = 2560,
    ['h'] = 1080
  },
  ['2K'] = {
    ['tooltip'] = '2K 2048x1152 (16:9)',
    ['w'] = 2048,
    ['h'] = 1152
  },
  ['4K'] = {
    ['tooltip'] = '4K 4096x2304 (16:9)',
    ['w'] = 4096,
    ['h'] = 2304
  }
}

local framerates = {'15', '16', '23.98', '24', '25', '29,97', '30', '48', '50', '59,94', '60'}

local formats = {
  ['AVI'] = {
    ['extension'] = 'avi',
    ['codecs'] = {'h263', 'h264', 'mpeg4', 'mpeg2video', 'h265', 'raw', 'vp9'}
  },
  ['Matroska'] = {
    ['extension'] = 'mkv',
    ['codecs'] = {'h263', 'h264', 'mpeg4', 'mpeg2video', 'h265', 'raw', 'vp9'}
  },
  ['WebM'] = {
    ['extension'] = 'webm',
    ['codecs'] = {'h263', 'h264', 'mpeg4', 'mpeg2video', 'h265', 'raw', 'vp9'}
  },
  ['MP4'] = {
    ['extension'] = 'mp4',
    ['codecs'] = {'h263', 'h264', 'mpeg4', 'mpeg2video'}
  },
  ['QuickTime'] = {
    ['extension'] = 'mov',
    ['codecs'] = {'h263', 'h264', 'mpeg4', 'mpeg2video'}
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

local function extract_resolution(description)
  for _, v in pairs(resolutions) do
    if v['tooltip'] == description then
      return v['w']..'x'..v['h']
    end
  end
  return '100x100'
end


local function replace_cb_elements(cb, new_items, to_select)
  if to_select == nil then
    to_select = cb.value
  end

  to_select_idx = 1
  for i , name in ipairs(new_items) do
    if name == to_select then
      to_select_idx = i
      break
    end
  end

  local old_elements_count = #cb
  for i, name in ipairs(new_items) do
    cb[i] = name
  end
  if old_elements_count > #new_items then
    for j=old_elements_count, #new_items + 1, -1 do
      cb[j] = nil
    end
  end

  cb.value = to_select_idx
end

local framerates_selector = dt.new_widget('combobox')
{
  label = _('framerate'),
  tooltip = _('select framerate of output video'),
  value = 1,
  table.unpack(framerates)
}

local res_selector = dt.new_widget('combobox')
{
  label = _('resolution'),
  tooltip = _('select resolution of output video'),
  value = 1,
  table.unpack(res_list)
}

local codec_selector = dt.new_widget('combobox'){
  label = _('codec'),
  tooltip = _('select codec'),
  value = 1,
  table.unpack(codec_list)
}

local format_selector = dt.new_widget('combobox'){
  label = _('format container'),
  tooltip = _('select format of output video'),
  value = 1,
  changed_callback = function(widget) 
    codec_list = formats[widget.value]['codecs']
    table.sort(codec_list)
    replace_cb_elements(codec_selector, codec_list)
  end,
  table.unpack(format_list)
}

local destination_label = dt.new_widget('label'){
  label = _('output file destination'),
  tooltip = _('settings of output file destination and name')
}

local output_directory_chooser = dt.new_widget('file_chooser_button'){
  title = _('Select export path'),  -- The title of the window when choosing a file
  is_directory = true,             -- True if the file chooser button only allows directories to be selecte
  tooltip =_('select the target directory for the timelapse. \nthe filename is created automatically.'),
  value = os.getenv('HOME')
}

local auto_output_directory_btn = dt.new_widget('check_button') {
  label='',
  tooltip = _('if selected, output video will be placed in the same directory as first of selected images'),
  clicked_callback = function () 
    output_directory_chooser.sensitive = not output_directory_chooser.sensitive 
  end
}

local destination_box = dt.new_widget('box') {
  orientation='horizontal',
  auto_output_directory_btn,
  output_directory_chooser
}

local module_widget = dt.new_widget('box') {
  orientation = 'vertical',
  res_selector,
  framerates_selector,
  format_selector,
  codec_selector,
  destination_label,
  destination_box
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
  if auto_output_directory_btn.value then
    extra_data['out'] = images[1].path
  else
    extra_data['out'] = output_directory_chooser.value
  end
end

local function export(extra_data)
  local dir = extra_data['tmp_dir']
  local fps = extra_data['fps']
  local res = extra_data['res']
  local codec = extra_data['codec']
  local img_ext = extra_data['img_ext']
  --local path = file_chooser_button_path.value..'/out.mp4'
  local path = '"'..extra_data['out']..'/out.'..extra_data['out_ext']..'"'
  local cmd = 'ffmpeg -y -r '..fps..' -i '..dir..'/%d'..img_ext..' -s:v '..res..' -c:v '..codec..' -crf 1 -preset slow '..path
  return dt.control.execute(cmd)
end

local function finalize_export(storage, image_table, extra_data)
    local tmp_dir = extra_data['tmp_dir']
    
    dt.print(_('prepare merge process'))
    
    local result = dt.control.execute('mkdir -p '..tmp_dir)

    if result ~= 0 then dt.print(_('ERROR: cannot create temp directory')) end
    
    local images = {}
    for _, v in pairs(image_table) do table.insert(images, v) end
    table.sort(images)
    local count = 0
    for _,v in pairs(images) do
      dt.control.execute('mv '..v..' '..tmp_dir..'/'..count..extra_data['img_ext'])
      count = count + 1
    end
    dt.print('Start video building...')
    local result = export(extra_data)
    if result ~= 0 then 
      dt.print(_('ERROR: cannot build image, see console for more info')) 
    else
      dt.print(_('SUCCESS'))
    end

    dt.control.execute('rm -rf '..tmp_dir)
end

dt.register_storage(
  'module_dt_timelapse', 
  _('timelapse video'), 
  nil, 
  finalize_export,
  support_format, 
  init_export, 
  module_widget
)

