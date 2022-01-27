script_name("Radio")
script_author("akacross")
script_url("http://akacross.net/")

local script_version = 0.8

if getMoonloaderVersion() >= 27 then
	require 'libstd.deps' {
	   'fyp:mimgui',
	   'fyp:samp-lua', 
	   'fyp:fa-icons-4',
	   'donhomka:extensions-lite'
	}
end

require"lib.moonloader"
require"lib.sampfuncs"
require 'extensions-lite'

local imgui, ffi = require 'mimgui', require 'ffi'
local new, str, sizeof = imgui.new, ffi.string, ffi.sizeof
local ped, h = playerPed, playerHandle
local vk = require 'vkeys'
local sampev = require 'lib.samp.events'
local encoding = require 'encoding'
encoding.default = 'CP1251'
local u8 = encoding.UTF8
local lfs = require 'lfs'
local faicons = require 'fa-icons'
local ti = require 'tabler_icons'
local wm  = require('lib.windows.message')
local as_action = require('moonloader').audiostream_state
local as_status = require('moonloader').audiostream_status
local dlstatus = require('moonloader').download_status
local https = require 'ssl.https'
local path = getWorkingDirectory() .. '\\config\\' 
local cfg = path .. 'radio.ini' 
local audiopath = getGameDirectory() .. "\\moonloader\\resource\\audio\\radio"
local audiopath2 = getGameDirectory() .. "\\moonloader\\resource\\audio\\radio\\pls"
local script_path = thisScript().path
local script_url = "https://raw.githubusercontent.com/akacross/radio/main/radio.lua"
local update_url = "https://raw.githubusercontent.com/akacross/radio/main/radio.txt"

local function loadIconicFont(fontSize)
    local config = imgui.ImFontConfig()
    config.MergeMode = true
    config.PixelSnapH = true
    local iconRanges = imgui.new.ImWchar[3](ti.min_range, ti.max_range, 0)
    imgui.GetIO().Fonts:AddFontFromMemoryCompressedBase85TTF(ti.get_font_data_base85(), fontSize, config, iconRanges)
end

local blank = {}
local radio = {
	toggle = true,
	autosave = false,
	autoupdate = false,
	imgui = {
		pos = {500,200},
		size = {84.0,25.0},
		color = {000000},
	},
	musicid = 1,
	music = {},
	stationid = 1,
	stations = {
		{ 
			station = "https://hzgaming.net/horizonfm/radio.pls",
			name = 'HZG radio'
		},
		{ 
			station = "https://radio.akacross.net/listen.pls",
			name = 'akacross radio'
		},
		{ 
			station = "http://pulseedm.cdnstream1.com:8124/1373_128",
			name = 'PulseDEM'
		},
		{ 
			station = "http://stream.dancewave.online:8080/dance.mp3.m3u",
			name = 'Dance Wave'
		},
	},
	player = {
		music_player = 1,
		pause_play = false,
		stop = false,
		volume = 1.0,
	},
}

local stations_menu = new.bool(false)
local mainc = imgui.ImVec4(0.92, 0.27, 0.92, 1.0)
local move = false
local update = false
local temp_pos = {x = 0, y = 0}
local paths = {}
local debug_messages = true

function apply_custom_style()
   local style = imgui.GetStyle()
   local colors = style.Colors
   local clr = imgui.Col
   local ImVec4 = imgui.ImVec4
   style.WindowRounding = 1.5
   style.WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
   style.FrameRounding = 1.0
   style.ItemSpacing = imgui.ImVec2(4.0, 4.0)
   style.ScrollbarSize = 13.0
   style.ScrollbarRounding = 0
   style.GrabMinSize = 8.0
   style.GrabRounding = 1.0
   style.WindowBorderSize = 0.0
   style.WindowPadding = imgui.ImVec2(4.0, 4.0)
   style.FramePadding = imgui.ImVec2(2.5, 3.5)
   style.ButtonTextAlign = imgui.ImVec2(0.5, 0.35)
 
   colors[clr.Text]                   = ImVec4(1.00, 1.00, 1.00, 1.00)
   colors[clr.TextDisabled]           = ImVec4(0.7, 0.7, 0.7, 1.0)
   colors[clr.WindowBg]               = ImVec4(0.07, 0.07, 0.07, 1.0)
   colors[clr.PopupBg]                = ImVec4(0.08, 0.08, 0.08, 0.94)
   colors[clr.Border]                 = ImVec4(mainc.x, mainc.y, mainc.z, 0.4)
   colors[clr.BorderShadow]           = ImVec4(0.00, 0.00, 0.00, 0.00)
   colors[clr.FrameBg]                = ImVec4(mainc.x, mainc.y, mainc.z, 0.7)
   colors[clr.FrameBgHovered]         = ImVec4(mainc.x, mainc.y, mainc.z, 0.4)
   colors[clr.FrameBgActive]          = ImVec4(mainc.x, mainc.y, mainc.z, 0.9)
   colors[clr.TitleBg]                = ImVec4(mainc.x, mainc.y, mainc.z, 1.0)
   colors[clr.TitleBgActive]          = ImVec4(mainc.x, mainc.y, mainc.z, 1.0)
   colors[clr.TitleBgCollapsed]       = ImVec4(mainc.x, mainc.y, mainc.z, 0.79)
   colors[clr.MenuBarBg]              = ImVec4(0.14, 0.14, 0.14, 1.00)
   colors[clr.ScrollbarBg]            = ImVec4(0.02, 0.02, 0.02, 0.53)
   colors[clr.ScrollbarGrab]          = ImVec4(mainc.x, mainc.y, mainc.z, 0.8)
   colors[clr.ScrollbarGrabHovered]   = ImVec4(0.41, 0.41, 0.41, 1.00)
   colors[clr.ScrollbarGrabActive]    = ImVec4(0.51, 0.51, 0.51, 1.00)
   colors[clr.CheckMark]              = ImVec4(mainc.x + 0.13, mainc.y + 0.13, mainc.z + 0.13, 1.00)
   colors[clr.SliderGrab]             = ImVec4(0.28, 0.28, 0.28, 1.00)
   colors[clr.SliderGrabActive]       = ImVec4(0.35, 0.35, 0.35, 1.00)
   colors[clr.Button]                 = ImVec4(mainc.x, mainc.y, mainc.z, 0.8)
   colors[clr.ButtonHovered]          = ImVec4(mainc.x, mainc.y, mainc.z, 0.63)
   colors[clr.ButtonActive]           = ImVec4(mainc.x, mainc.y, mainc.z, 1.0)
   colors[clr.Header]                 = ImVec4(mainc.x, mainc.y, mainc.z, 0.6)
   colors[clr.HeaderHovered]          = ImVec4(mainc.x, mainc.y, mainc.z, 0.43)
   colors[clr.HeaderActive]           = ImVec4(mainc.x, mainc.y, mainc.z, 0.8)
   colors[clr.Separator]              = colors[clr.Border]
   colors[clr.SeparatorHovered]       = ImVec4(0.26, 0.59, 0.98, 0.78)
   colors[clr.SeparatorActive]        = ImVec4(0.26, 0.59, 0.98, 1.00)
   colors[clr.ResizeGrip]             = ImVec4(mainc.x, mainc.y, mainc.z, 0.8)
   colors[clr.ResizeGripHovered]      = ImVec4(mainc.x, mainc.y, mainc.z, 0.63)
   colors[clr.ResizeGripActive]       = ImVec4(mainc.x, mainc.y, mainc.z, 1.0)
   colors[clr.PlotLines]              = ImVec4(0.61, 0.61, 0.61, 1.00)
   colors[clr.PlotLinesHovered]       = ImVec4(1.00, 0.43, 0.35, 1.00)
   colors[clr.PlotHistogram]          = ImVec4(0.90, 0.70, 0.00, 1.00)
   colors[clr.PlotHistogramHovered]   = ImVec4(1.00, 0.60, 0.00, 1.00)
   colors[clr.TextSelectedBg]         = ImVec4(0.26, 0.59, 0.98, 0.35)
end

function main()
	blank = table.deepcopy(radio)
	if not doesDirectoryExist(path) then createDirectory(path) end
	if not doesDirectoryExist(audiopath) then createDirectory(audiopath) end
	if not doesDirectoryExist(audiopath2) then createDirectory(audiopath2) end
	if doesFileExist(cfg) then loadIni() else blankIni() end

    repeat wait(0) until isSampAvailable()
	repeat wait(0) until sampGetGamestate() == 3

	if radio.autoupdate then
		update_script()
	end

	sampRegisterChatCommand("stations", function() 
		if not update then
			stations_menu[0] = not stations_menu[0] 
		else
			sampAddChatMessage(string.format("{ABB2B9}[%s]{FFFFFF} The update is in progress.. Please wait..", script.this.name), -1)
		end
	end)
	sampRegisterChatCommand("radio", function() 
		if not update then
			stations_menu[0] = not stations_menu[0] 
		else
			sampAddChatMessage(string.format("{ABB2B9}[%s]{FFFFFF} The update is in progress.. Please wait..", script.this.name), -1)
		end
	end)
	
	play_radio()
	if radio_play ~= nil then
		radio.player.pause_play = true
		setAudioStreamState(radio_play, as_action.PLAY)
	end
	
	paths = scanGameFolder(audiopath, paths)
	
	
	lua_thread.create(function() 
		while true do wait(2000) 
			if radio_play ~= nil then
			
				if getAudioStreamState(radio_play) == as_status.STOPPED then
				
					if radio.player.music_player == 1 then
						if radio_play ~= nil then
							radio.player.pause_play = false
							setAudioStreamState(radio_play, as_action.STOP)
						end
							
						if radio.player.stop then
							if radio_play ~= nil then
								radio.player.pause_play = false
								setAudioStreamState(radio_play, as_action.STOP)
							end
						else
							radio.player.pause_play = true
							radio.player.stop = false
							play_radio()
						end
					end
					if radio.player.music_player == 2 or radio.player.music_player == 3 then
						print('radio.musicid' .. radio.musicid)
						radio.musicid = radio.musicid + 1 
						
						if radio_play ~= nil then
							radio.player.pause_play = false
							setAudioStreamState(radio_play, as_action.STOP)
						end
						
							
						if radio.player.stop then
							if radio_play ~= nil then
								radio.player.pause_play = false
								setAudioStreamState(radio_play, as_action.STOP)
							end
						else
							radio.player.pause_play = true
							radio.player.stop = false
							play_radio()
						end
						
						if radio.musicid >= table.maxn(radio.music) + 1 then
							radio.musicid = 1
							
							if radio_play ~= nil then
								radio.player.pause_play = false
								setAudioStreamState(radio_play, as_action.STOP)
							end
								
							if radio.player.stop then
								if radio_play ~= nil then
									radio.player.pause_play = false
									setAudioStreamState(radio_play, as_action.STOP)
								end
							else
								radio.player.pause_play = true
								radio.player.stop = false
								play_radio()
							end
						end
					end
				end
			end
		end 
	end)
	
	while true do wait(0)
	
		x, y = getCursorPos()
		if move then	
			if isKeyJustPressed(VK_LBUTTON) then 
				move = false
			elseif isKeyJustPressed(VK_ESCAPE) then
				move = false
			else 
				radio.imgui.pos[1] = x + 1
				radio.imgui.pos[2] = y + 1
			end
		end
		if update then
			stations_menu[0] = false
			lua_thread.create(function() 
				wait(20000) 
				thisScript():reload()
				update = false
			end)
		end
	end
end

-- imgui.OnInitialize() called only once, before the first render
imgui.OnInitialize(function()
	apply_custom_style() -- apply custom style
	local defGlyph = imgui.GetIO().Fonts.ConfigData.Data[0].GlyphRanges
	imgui.GetIO().Fonts:Clear() -- clear the fonts
	local font_config = imgui.ImFontConfig() -- each font has its own config
	font_config.SizePixels = 14.0;
	font_config.GlyphExtraSpacing.x = 0.1
	-- main font
	local def = imgui.GetIO().Fonts:AddFontFromFileTTF(getFolderPath(0x14) .. '\\arialbd.ttf', font_config.SizePixels, font_config, defGlyph)
   
	local config = imgui.ImFontConfig()
	config.MergeMode = true
	config.PixelSnapH = true
	config.FontDataOwnedByAtlas = false
	config.GlyphOffset.y = 1.0 -- offset 1 pixel from down
	local fa_glyph_ranges = new.ImWchar[3]({ faicons.min_range, faicons.max_range, 0 })
	-- icons
	local faicon = imgui.GetIO().Fonts:AddFontFromMemoryCompressedBase85TTF(faicons.get_font_data_base85(), font_config.SizePixels, config, fa_glyph_ranges)

	loadIconicFont(14)

	imgui.GetIO().ConfigWindowsMoveFromTitleBarOnly = true
	imgui.GetIO().IniFilename = nil
end)

imgui.OnFrame(function() return radio.toggle and not isGamePaused() end,
function()
	imgui.SetNextWindowPos(imgui.ImVec2(radio.imgui.pos[1], radio.imgui.pos[2]))
	imgui.SetNextWindowSize(imgui.ImVec2(radio.imgui.size[1], radio.imgui.size[2]))
	
	local r, g, b, a = hex2rgba(radio.imgui.color[1])
	imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(r, g, b, a))
	
	imgui.Begin('radio', nil, imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoSavedSettings)
	
		radio_player()
		
	imgui.End()
	imgui.PopStyleColor()
end).HideCursor = true

local mnames = {'Radio', 'Music', 'Queue'}
local string = ''

imgui.OnFrame(function() return stations_menu[0] end,
function()
	local width, height = getScreenResolution()
	imgui.SetNextWindowPos(imgui.ImVec2(width / 2, height / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
	imgui.SetNextWindowSize(imgui.ImVec2(500, 360), imgui.Cond.FirstUseEver)

    imgui.Begin(faicons.ICON_PLAY .. string.format(" %s Settings %s - %s[%d] - Verison: %s", script.this.name, ti.ICON_SETTINGS, mnames[radio.player.music_player], radio.player.music_player, script_version), stations_menu, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoSavedSettings + imgui.WindowFlags.MenuBar) 
		
		imgui.BeginMenuBar()
			for i = 1, 3 do 
				if imgui.MenuItemBool(u8(mnames[i])) then
					radio.player.music_player = i
					if i == 1 then
						print(radio.player.stop)
						if not radio.player.pause_play and not radio.player.stop then
							play_radio()
							if radio_play ~= nil then
								radio.player.pause_play = true
								setAudioStreamState(radio_play, as_action.PLAY)
							end
						end
					end
					if i == 3 then
						print(radio.player.stop)
						if not radio.player.pause_play and not radio.player.stop then
							if radio_play ~= nil then
								radio.player.pause_play = false
								setAudioStreamState(radio_play, as_action.STOP)
							end
								
							if radio.player.stop then
								if radio_play ~= nil then
									radio.player.pause_play = false
									setAudioStreamState(radio_play, as_action.STOP)
								end
							else
								radio.player.pause_play = true
								radio.player.stop = false
								play_radio()
							end
						end
					end
				end
			end
		imgui.EndMenuBar()
		
		if imgui.Checkbox(radio.toggle and 'ON' or 'OFF', new.bool(radio.toggle)) then 
			radio.toggle = not radio.toggle
		end 
		imgui.SameLine() 
		if imgui.Button(ti.ICON_DEVICE_FLOPPY.. 'Save') then
			saveIni()
		end 
		if imgui.IsItemHovered() then
			imgui.SetTooltip('Save the Script')
		end
		imgui.SameLine()
		if imgui.Checkbox('##autosave', new.bool(radio.autosave)) then 
			radio.autosave = not radio.autosave 
			saveIni() 
		end
		if imgui.IsItemHovered() then
			imgui.SetTooltip('Autosave')
		end
		imgui.SameLine()
		if imgui.Button(ti.ICON_FILE_UPLOAD.. 'Load') then
			loadIni()
		end 
		if imgui.IsItemHovered() then
			imgui.SetTooltip('Reload the Script')
		end
		imgui.SameLine()
		if imgui.Button(ti.ICON_ERASER .. 'Reset') then
			blankIni()
		end 
		if imgui.IsItemHovered() then
			imgui.SetTooltip('Reset the Script to default settings')
		end
		imgui.SameLine()
		if imgui.Button(ti.ICON_REFRESH .. 'Update') then
			update_script()
		end 
		if imgui.IsItemHovered() then
			imgui.SetTooltip('Update the script')
		end
		imgui.SameLine()
		if imgui.Checkbox('##autoupdate', new.bool(radio.autoupdate)) then 
			radio.autoupdate = not radio.autoupdate 
		end
		if imgui.IsItemHovered() then
			imgui.SetTooltip('Auto-Update')
		end
		
		imgui.SameLine()
		
		imgui.PushItemWidth(100)
		local volume = new.float[1](radio.player.volume)
		if imgui.SliderFloat(u8'##Volume', volume, 0, 1) then
			radio.player.volume = volume[0]
			if radio_play ~= nil then
				setAudioStreamVolume(radio_play, radio.player.volume)
			end
		end
		imgui.PopItemWidth()
		
		if imgui.IsItemHovered() then
			imgui.SetTooltip('Volume Control')
		end
		
		imgui.SameLine()
		
		if imgui.Button(move and u8"Undo##" or u8"Move##") then
			move = not move
			if move then
				sampAddChatMessage(string.format('%s: Press {FF0000}%s {FFFFFF}to save the pos.', script.this.name, vk.id_to_name(VK_LBUTTON)), -1) 
				temp_pos.x = radio.imgui.pos[1]
				temp_pos.y = radio.imgui.pos[2]
				move = true
			else
				radio.imgui.pos[1] = temp_pos.x
				radio.imgui.pos[2] = temp_pos.y
				move = false
			end
		end
		
		
		
		if radio.player.music_player == 1 then
			radio_player()
			imgui.SameLine()
			imgui.Text(string.format(" %s[%d]", radio.stations[radio.stationid].name, radio.stationid))
		
			for k, v in ipairs(radio.stations) do
				
				text = new.char[256](v.station)
				imgui.PushItemWidth(325)
				if imgui.InputText('##font'..k, text, sizeof(text), imgui.InputTextFlags.EnterReturnsTrue) then
					v.station = u8:decode(str(text))
				end
				imgui.PopItemWidth()
				
				imgui.SameLine()
				
				imgui.PushItemWidth(95)
				text = new.char[256](v.name)
				if imgui.InputText('##name'..k, text, sizeof(text), imgui.InputTextFlags.EnterReturnsTrue) then
					v.name = u8:decode(str(text))
				end
				imgui.PopItemWidth()
				
				imgui.SameLine()
				if imgui.Button('Play##'..k) then 
					if radio_play ~= nil then
						setAudioStreamState(radio_play, as_action.STOP)
					end
					radio.player.pause_play = true
					radio.player.stop = false
					radio.stationid = k
					play_radio()
				end
			
				imgui.SameLine()
				if k ~= 1 then
					if imgui.Button(u8"x##"..k) then
						table.remove(radio.stations, k)
					end
				else
					if imgui.Button(u8"+") then
						radio.stations[#radio.stations + 1] = {
							station = 'url here',
							name = 'name of radio',
						}
						for k, v in ipairs(radio.stations) do
							local id = table.maxn(radio.stations)
							if k == id then
								if debug_messages then
									print(k..' - '..table.maxn(radio.stations))
								end
							end
						end
					end
				end
			end
		end
		if radio.player.music_player == 2 then
			for k, v in pairs(paths) do
				k = tostring(k)
				if k:match(".+%.mp3") or k:match(".+%.mp4") or k:match(".+%.wav") or k:match(".+%.m4a") or k:match(".+%.flac") or k:match(".+%.m4r") or k:match(".+%.ogg") or k:match(".+%.mp2") or
					k:match(".+%.amr") or k:match(".+%.wma") or k:match(".+%.aac") or k:match(".+%.aiff") then
					
					imgui.Text(u8(k))
					imgui.SameLine()
					
					if imgui.Button('Add to Queue##'..k) then 
						radio.music[#radio.music + 1] = {
							file = v,
							name = k,
						}
						for k, v in ipairs(radio.music) do
							local id = table.maxn(radio.music)
							if k == id then
								if debug_messages then
									print(k..' - '..table.maxn(radio.music))
								end
							end
						end
					end	
				end 
			end
		end
		if radio.player.music_player == 3 then
			
			radio_player()
			imgui.SameLine()			
			
			if radio.music[radio.musicid] ~= nil then
				imgui.Text(string.format(" %s[%d]", radio.music[radio.musicid].name, radio.musicid))
			else
				imgui.Text('Empty[1]')
			end
			
			for k, v in ipairs(radio.music) do
				imgui.PushItemWidth(200)
				text = new.char[256](v.name)
				if imgui.InputText('##name'..k, text, sizeof(text), imgui.InputTextFlags.EnterReturnsTrue) then
					v.name = u8:decode(str(text))
				end
				imgui.PopItemWidth()
				
				imgui.SameLine()
				if imgui.Button('Play##'..k) then 
					if radio_play ~= nil then
						setAudioStreamState(radio_play, as_action.STOP)
					end
					radio.player.pause_play = true
					radio.player.stop = false
					radio.musicid = k

					play_radio()
				end
				
				imgui.SameLine()
				if imgui.Button(u8"x##"..k) then
					table.remove(radio.music, k)
				end
			end
		end
		
    imgui.End()
end)

function radio_player()
	if imgui.Button(faicons.ICON_STEP_BACKWARD) then
		if radio.player.music_player == 1 then
			if radio.stationid >= 1 and radio.stationid <= table.maxn(radio.stations) then
				radio.stationid = radio.stationid - 1
				if debug_messages then
					print(radio.stationid)
				end
				if radio_play ~= nil then
					radio.player.pause_play = false
					setAudioStreamState(radio_play, as_action.STOP)
				end
					
				if radio.player.stop then
					if radio_play ~= nil then
						radio.player.pause_play = false
						setAudioStreamState(radio_play, as_action.STOP)
					end
				else
					radio.player.pause_play = true
					radio.player.stop = false
					play_radio()
				end
			end
				
			if radio.stationid == 0 then
				radio.stationid = table.maxn(radio.stations)
				if debug_messages then
					print(radio.stationid)
				end
				if radio_play ~= nil then
					radio.player.pause_play = false
					setAudioStreamState(radio_play, as_action.STOP)
				end
						
				if radio.player.stop then
					if radio_play ~= nil then
						radio.player.pause_play = false
						setAudioStreamState(radio_play, as_action.STOP)
					end
				else
					radio.player.pause_play = true
					radio.player.stop = false
					play_radio()
				end
			end
		end
		if radio.player.music_player == 2 or radio.player.music_player == 3 then
			if radio.musicid >= 1 and radio.musicid <= table.maxn(radio.music) then
				radio.musicid = radio.musicid - 1
				if debug_messages then
					print(radio.musicid)
				end
				if radio_play ~= nil then
					radio.player.pause_play = false
					setAudioStreamState(radio_play, as_action.STOP)
				end
						
				if radio.player.stop then
					if radio_play ~= nil then
						radio.player.pause_play = false
						setAudioStreamState(radio_play, as_action.STOP)
					end
				else
					radio.player.pause_play = true
					radio.player.stop = false
					play_radio()
				end
			end

			if radio.musicid == 0 then
				radio.musicid = table.maxn(radio.music)
				if debug_messages then
					print(radio.musicid)
				end
				if radio_play ~= nil then
					radio.player.pause_play = false
					setAudioStreamState(radio_play, as_action.STOP)
				end
						
				if radio.player.stop then
					if radio_play ~= nil then
						radio.player.pause_play = false
						setAudioStreamState(radio_play, as_action.STOP)
					end
				else
					radio.player.pause_play = true
					radio.player.stop = false
					play_radio()
				end
			end
		end
	end
	imgui.SameLine() 
	if imgui.Button(not radio.player.stop and (radio.player.pause_play and faicons.ICON_PAUSE .. '##Pause' or faicons.ICON_PLAY .. '##Play') or faicons.ICON_PLAY) then
		if radio.player.music_player == 1 then
			if not radio.player.stop then
				radio.player.pause_play = not radio.player.pause_play
				if radio.player.pause_play then
					if radio_play ~= nil then
						radio.player.pause_play = true
						setAudioStreamState(radio_play, as_action.PLAY)
					end
				else
					if radio_play ~= nil then
						radio.player.pause_play = false
						setAudioStreamState(radio_play, as_action.PAUSE)
					end
				end
			end
		end
			
		if radio.player.music_player == 2 or radio.player.music_player == 3 then
			if not radio.player.stop then
				radio.player.pause_play = not radio.player.pause_play
				if radio.player.pause_play then
					if radio_play ~= nil then
						radio.player.pause_play = true
						setAudioStreamState(radio_play, as_action.RESUME)
					end
				else
					if radio_play ~= nil then
						radio.player.pause_play = false
						setAudioStreamState(radio_play, as_action.PAUSE)
					end
				end
			end
		end
	end 
	imgui.SameLine() 
	if imgui.Button(radio.player.stop and faicons.ICON_PLAY_CIRCLE or faicons.ICON_STOP) then
		if radio.player.music_player == 1 then
			radio.player.stop = not radio.player.stop
			if radio.player.stop then
				if radio_play ~= nil then
					radio.player.pause_play = false
					setAudioStreamState(radio_play, as_action.STOP)
				end
			else
				radio.player.pause_play = true
				play_radio()
			end
		end
		if radio.player.music_player == 2 or radio.player.music_player == 3 then
			radio.player.stop = not radio.player.stop
			if radio.player.stop then
				if radio_play ~= nil then
					radio.player.pause_play = false
					setAudioStreamState(radio_play, as_action.STOP)
				end
			else
				radio.player.pause_play = true
				play_radio()
			end
		end
	end
	imgui.SameLine() 
	if imgui.Button(faicons.ICON_STEP_FORWARD) then
		if radio.player.music_player == 1 then
			if radio.stationid >= 1 and radio.stationid <= table.maxn(radio.stations) then
				radio.stationid = radio.stationid + 1
				if debug_messages then
					print(radio.stationid)
				end
					
				if radio_play ~= nil then
					radio.player.pause_play = false
					setAudioStreamState(radio_play, as_action.STOP)
				end
						
				if radio.player.stop then
					if radio_play ~= nil then
						radio.player.pause_play = false
						setAudioStreamState(radio_play, as_action.STOP)
					end
				else
					radio.player.pause_play = true
					radio.player.stop = false
					play_radio()
				end
			end
			if radio.stationid == table.maxn(radio.stations) then
				radio.stationid = 1
				if debug_messages then
					print(radio.stationid)
				end
				if radio_play ~= nil then
					radio.player.pause_play = false
					setAudioStreamState(radio_play, as_action.STOP)
				end
						
				if radio.player.stop then
					if radio_play ~= nil then
						radio.player.pause_play = false
						setAudioStreamState(radio_play, as_action.STOP)
					end
				else
					radio.player.pause_play = true
					radio.player.stop = false
					play_radio()
				end
			end
		end
		if radio.player.music_player == 2 or radio.player.music_player == 3 then
			if radio.musicid >= 1 and radio.musicid <= table.maxn(radio.music) then
				radio.musicid = radio.musicid + 1
				if debug_messages then
					print(radio.musicid)
				end
					
				if radio_play ~= nil then
					radio.player.pause_play = false
					setAudioStreamState(radio_play, as_action.STOP)
				end
						
				if radio.player.stop then
					if radio_play ~= nil then
						radio.player.pause_play = false
						setAudioStreamState(radio_play, as_action.STOP)
					end
				else
					radio.player.pause_play = true
					radio.player.stop = false
					play_radio()
				end
			end
			if radio.musicid == table.maxn(radio.music) + 1 then
				radio.musicid = 1
				if debug_messages then
					print(radio.musicid)
				end
				if radio_play ~= nil then
					radio.player.pause_play = false
					setAudioStreamState(radio_play, as_action.STOP)
				end
						
				if radio.player.stop then
					if radio_play ~= nil then
						radio.player.pause_play = false
						setAudioStreamState(radio_play, as_action.STOP)
					end
				else
					radio.player.pause_play = true
					radio.player.stop = false
					play_radio()
				end
			end
		end
	end
end

function onWindowMessage(msg, wparam, lparam)
	if msg == wm.WM_KILLFOCUS then
		if radio.player.pause_play then
			if radio_play ~= nil then
				radio.player.pause_play = false
				radio.player.stop = true
				setAudioStreamState(radio_play, as_action.PAUSE)
			end
		end
	elseif msg == wm.WM_SETFOCUS then
		if radio.player.pause_play then
			if radio_play ~= nil then
				radio.player.pause_play = true
				radio.player.stop = false
				setAudioStreamState(radio_play, as_action.RESUME)
			end
		end
	end
	
	if wparam == VK_ESCAPE and stations_menu[0] then
        if msg == wm.WM_KEYDOWN then
            consumeWindowMessage(true, false)
        end
        if msg == wm.WM_KEYUP then
            stations_menu[0] = false
        end
    end
end

function sampev.onPlayAudioStream(url, position, radius, usePosition)
	if not radio.player.stop then
		return false
	end
end

function update_script()
	update_text = https.request(update_url)
	update_version = update_text:match("version: (.+)")
	if tonumber(update_version) > script_version then
		sampAddChatMessage(string.format("{ABB2B9}[%s]{FFFFFF} New version found! The update is in progress..", script.this.name), -1)
		downloadUrlToFile(script_url, script_path, function(id, status)
			if status == dlstatus.STATUS_ENDDOWNLOADDATA then
				sampAddChatMessage(string.format("{ABB2B9}[%s]{FFFFFF} The update was successful!", script.this.name), -1)
				blankIni()
				update = true
			end
		end)
	end
end

function scanGameFolder(path, tables)
    for file in lfs.dir(path) do
        if file ~= "." and file ~= ".." then
            local f = path..'\\'..file
			local file_extension = string.match(file, "([^\\%.]+)$")
            if file_extension:match("mp3") or file_extension:match("mp4") or file_extension:match("wav") or file_extension:match("m4a") or file_extension:match("flac") or file_extension:match("m4r") or file_extension:match("ogg")
			or file_extension:match("mp2") or file_extension:match("amr") or file_extension:match("wma") or file_extension:match("aac") or file_extension:match("aiff") then
				table.insert(tables, file)
                tables[file] = f
            end 
            if lfs.attributes(f, "mode") == "directory" then
                tables = scanGameFolder(f, tables)
            end 
        end
    end
    return tables
end

function play_radio()
	if radio.player.music_player == 1 then
		if radio.stations[radio.stationid] ~= nil then
			if not radio.player.stop then
			
				downloadUrlToFile(radio.stations[radio.stationid].station, audiopath2..'\\playlist'..radio.stationid, function(id, status)
					--print(status)
					if status == dlstatus.STATUS_BEGINDOWNLOADDATA then
						if debug_messages then
							print(radio.stations[radio.stationid].station)
						end
						if radio_play ~= nil then
							releaseAudioStream(radio_play)
						end
						radio_play = loadAudioStream(radio.stations[radio.stationid].station)
						if radio_play ~= nil then
							setAudioStreamVolume(radio_play, radio.player.volume)
						end
							
						if radio.player.pause_play then
							if radio_play ~= nil then
								setAudioStreamState(radio_play, as_action.PLAY)
							end
						else
							if radio_play ~= nil then
								setAudioStreamState(radio_play, as_action.PAUSE)
							end
						end
					end
				end)
					--sampAddChatMessage(string.format("{ABB2B9}[%s]{FFFFFF} Bad audio url detected!", script.this.name), -1)
			end
		end
	end
	if radio.player.music_player == 2 or radio.player.music_player == 3 then
		if not radio.player.stop then
			if radio.music[radio.musicid] ~= nil then
				if doesFileExist(radio.music[radio.musicid].file) then
				
						if radio_play ~= nil then
							releaseAudioStream(radio_play)
						end
						radio_play = loadAudioStream(radio.music[radio.musicid].file)
						setAudioStreamVolume(radio_play, radio.player.volume)
						
					if radio.player.pause_play then
						if radio_play ~= nil then
							setAudioStreamState(radio_play, as_action.RESUME)
						end
					else
						if radio_play ~= nil then
							setAudioStreamState(radio_play, as_action.PAUSE)
						end
					end
				else
					sampAddChatMessage(string.format("{ABB2B9}[%s]{FFFFFF} Bad audio file detected!", script.this.name), -1)
				end
			end
		end
	end
end

function onScriptTerminate(scr, quitGame) 
	if scr == script.this then 
		if radio.autosave then 
			if radio_play ~= nil then
				releaseAudioStream(radio_play)
			end
			saveIni() 
		end 
	end
end

function blankIni()
	radio = table.deepcopy(blank)
	saveIni()
	loadIni()
end

function loadIni() 
	local f = io.open(cfg, "r") 
	if f then 
		radio = decodeJson(f:read("*all")) 
		f:close() 
	end
end

function saveIni()
	if type(radio) == "table" then 
		local f = io.open(cfg, "w") 
		f:close() 
		if f then 
			local f = io.open(cfg, "r+") 
			f:write(encodeJson(radio,true)) 
			f:close() 
		end 
	end 
end

function hex2rgba(rgba)
	local a = bit.band(bit.rshift(rgba, 24),	0xFF)
	local r = bit.band(bit.rshift(rgba, 16),	0xFF)
	local g = bit.band(bit.rshift(rgba, 8),		0xFF)
	local b = bit.band(rgba, 0xFF)
	return r / 255, g / 255, b / 255, a / 255
end

function hex2rgba_int(rgba)
	local a = bit.band(bit.rshift(rgba, 24),	0xFF)
	local r = bit.band(bit.rshift(rgba, 16),	0xFF)
	local g = bit.band(bit.rshift(rgba, 8),		0xFF)
	local b = bit.band(rgba, 0xFF)
	return r, g, b, a
end

function hex2rgb(rgba)
	local a = bit.band(bit.rshift(rgba, 24),	0xFF)
	local r = bit.band(bit.rshift(rgba, 16),	0xFF)
	local g = bit.band(bit.rshift(rgba, 8),		0xFF)
	local b = bit.band(rgba, 0xFF)
	return r / 255, g / 255, b / 255
end

function hex2rgb_int(rgba)
	local a = bit.band(bit.rshift(rgba, 24),	0xFF)
	local r = bit.band(bit.rshift(rgba, 16),	0xFF)
	local g = bit.band(bit.rshift(rgba, 8),		0xFF)
	local b = bit.band(rgba, 0xFF)
	return r, g, b
end

function argb2hex(a, r, g, b)
	local argb = b
	argb = bit.bor(argb, bit.lshift(g, 8))
	argb = bit.bor(argb, bit.lshift(r, 16))
	argb = bit.bor(argb, bit.lshift(a, 24))
	return argb
end
