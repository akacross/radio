 script_name("Radio")
script_author("akacross")
script_url("http://akacross.net/")

local script_version = 1.2
local script_version_text = '1.2'

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
local fa = require 'fAwesome5'
local wm  = require('lib.windows.message')
local as_action = require('moonloader').audiostream_state
local as_status = require('moonloader').audiostream_status
local dlstatus = require('moonloader').download_status
local https = require 'ssl.https'
local path = getWorkingDirectory() .. '/config/' 
local cfg = path .. 'radio.ini' 
local audiopath = getGameDirectory() .. "/moonloader/resource/audio/radio/pls/"
local script_path = thisScript().path
local script_url = "https://raw.githubusercontent.com/akacross/radio/main/radio.lua"
local update_url = "https://raw.githubusercontent.com/akacross/radio/main/radio.txt"

local function loadIconicFont(fromfile, fontSize, min, max, fontdata)
    local config = imgui.ImFontConfig()
    config.MergeMode = true
    config.PixelSnapH = true
    local iconRanges = new.ImWchar[3](min, max, 0)
	if fromfile then
		imgui.GetIO().Fonts:AddFontFromFileTTF(fontdata, fontSize, config, iconRanges)
	else
		imgui.GetIO().Fonts:AddFontFromMemoryCompressedBase85TTF(fontdata, fontSize, config, iconRanges)
	end
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
	folders = {
		{
			name = 'default location',
			folder = getGameDirectory() .. "\\moonloader\\resource\\audio\\radio"
		}
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
			station = "https://akacross.net/akacross.pls",
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
		autoplay = false,
		pause_play = false,
		stop = false,
		volume = 1.0
	},
}

local radioplayer = false
local musicplayer = false
local stations_menu = new.bool(false)
local mainc = imgui.ImVec4(0.92, 0.27, 0.92, 1.0)
local mnames = {'Radio', 'Music', 'Queue', 'Folders'}
local fileformats = {'.mp3','.mp4','.wav','.m4a','.flac','.m4r','.ogg','.mp2','.amr','.wma','.aac','.aiff'}
local move = false
local update = false
local inuse = false
local selected = false
local play_inuse = false
local temp_pos = {x = 0, y = 0}
local paths = {}
local debug_messages = true

function main()
	blank = table.deepcopy(radio)
	if not doesDirectoryExist(path) then createDirectory(path) end
	if not doesDirectoryExist(audiopath) then createDirectory(audiopath) end
	if doesFileExist(cfg) then loadIni() else blankIni() end

    repeat wait(0) until isSampAvailable()

	if radio.autoupdate then
		update_script()
	end

	sampRegisterChatCommand("stations", menu_command)
	sampRegisterChatCommand("radio", menu_command)
	sampRegisterChatCommand("music", menu_command)
	
	if radio.player.pause_play then
		playAudio()
	end
	
	if radio.player.autoplay then
		if radio.player.music_player == 1 then
			--radio.stationid = 1
			playAudio()
		end
		if radio.player.music_player >= 2 or radio.player.music_player <= 4 then
			--radio.musicid = 1
			playAudio()
		end
	end
	
	for k, v in ipairs(radio.folders) do
		paths = scanGameFolder(v.folder, paths)
	end
	
	lua_thread.create(function()
		while true do wait(2000) 
			if not radio.player.stop then
				if radio.player.music_player == 1 then	
					if not musicplayer then
						if radio.stationid == 0 then
							radio.stationid = 1
							playAudio()
						end	
						if radio.player.autoplay and not radio.player.stop and not play_inuse then
							if radio_play ~= nil then
								if getAudioStreamState(radio_play) == as_status.STOPPED then
									print('loop pass stationid + 1')
									radio.stationid = radio.stationid + 1
									playAudio()
								end
							end
						end
						if radio.stationid >= table.maxn(radio.stations) + 1 then
							if next(radio.stations) then
								radio.stationid = 1
								playAudio()
							end
						end	
					end
				end
				if radio.player.music_player >= 2 and radio.player.music_player <= 4 then
					if not radioplayer then
						if radio.musicid == 0 then
							print('if radio.musicid == 0 then loop pass musicid + 1')
							radio.musicid = 1
							playAudio()
						end	
						if radio.player.autoplay and not radio.player.stop then
							if radio_play ~= nil then
								if getAudioStreamState(radio_play) == as_status.STOPPED then
									print('loop pass musicid + 1')
									radio.musicid = radio.musicid + 1 
									playAudio()
								end
							end
						end
					
						if radio.musicid >= table.maxn(radio.music) + 1 then
							if next(radio.music) then
								print('radio.musicid >= table.maxn(radio.music) + 1 loop pass musicid + 1')
								radio.musicid = 1
								playAudio()
							end
						end
					end
				end
			end
		end
	end)
	
	while true do wait(0)
	
		if radio_play ~= nil then
			if getAudioStreamState(radio_play) == as_status.STOPPED --[[or getAudioStreamState(radio_play) == as_status.PAUSED]] then
				radioplayer = false
				musicplayer = false
			end
		end
	
		if move then	
			x, y = getCursorPos()
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
				blankIni()
				update = false
			end)
		end
	end
end

function menu_command()
	if not update then
		stations_menu[0] = not stations_menu[0] 
	else
		sampAddChatMessage(string.format("{ABB2B9}[%s]{FFFFFF} The update is in progress.. Please wait..", script.this.name), -1)
	end
end

imgui.OnInitialize(function()
	apply_custom_style()

	loadIconicFont(false, 14.0, faicons.min_range, faicons.max_range, faicons.get_font_data_base85())
	loadIconicFont(true, 14.0, fa.min_range, fa.max_range, 'moonloader/resource/fonts/fa-solid-900.ttf')
	loadIconicFont(false, 14.0, ti.min_range, ti.max_range, ti.get_font_data_base85())

	imgui.GetIO().ConfigWindowsMoveFromTitleBarOnly = true
	imgui.GetIO().IniFilename = nil
end)

imgui.OnFrame(function() return radio.toggle and not isGamePaused() end,
function()
	imgui.SetNextWindowPos(imgui.ImVec2(radio.imgui.pos[1], radio.imgui.pos[2]))
	--imgui.SetNextWindowSize(imgui.ImVec2(radio.imgui.size[1], radio.imgui.size[2]))
	
	local r, g, b, a = hex2rgba(radio.imgui.color[1])
	imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(r, g, b, a))
	
	imgui.Begin('radio', nil, imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoSavedSettings + imgui.WindowFlags.AlwaysAutoResize + imgui.WindowFlags.NoBackground)
		radio_player()
	imgui.End()
	imgui.PopStyleColor()
end).HideCursor = true

imgui.OnFrame(function() return stations_menu[0] end,
function()

	local width, height = getScreenResolution()
	imgui.SetNextWindowPos(imgui.ImVec2(width / 2, height / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))

    imgui.Begin(faicons.ICON_PLAY .. string.format(" %s Settings %s - Verison: %s", script.this.name, ti.ICON_SETTINGS, script_version_text), stations_menu, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoSavedSettings + imgui.WindowFlags.AlwaysAutoResize) 		
		imgui.BeginChild("##1", imgui.ImVec2(85, 392), true)
			
			imgui.SetCursorPos(imgui.ImVec2(5, 5))
      
			if imgui.CustomButton(
				faicons.ICON_POWER_OFF, 
				radio.toggle and imgui.ImVec4(0.15, 0.59, 0.18, 0.7) or imgui.ImVec4(1, 0.19, 0.19, 0.5), 
				radio.toggle and imgui.ImVec4(0.15, 0.59, 0.18, 0.5) or imgui.ImVec4(1, 0.19, 0.19, 0.3), 
				radio.toggle and imgui.ImVec4(0.15, 0.59, 0.18, 0.4) or imgui.ImVec4(1, 0.19, 0.19, 0.2), 
				imgui.ImVec2(75, 75)) then
				radio.toggle = not radio.toggle
			end
			if imgui.IsItemHovered() then
				imgui.SetTooltip('Toggles Radio Buttons')
			end
		
			imgui.SetCursorPos(imgui.ImVec2(5, 81))

			if imgui.CustomButton(
				faicons.ICON_FLOPPY_O,
				imgui.ImVec4(0.16, 0.16, 0.16, 0.9), 
				imgui.ImVec4(0.40, 0.12, 0.12, 1), 
				imgui.ImVec4(0.30, 0.08, 0.08, 1), 
				imgui.ImVec2(75, 75)) then
				saveIni()
			end
			if imgui.IsItemHovered() then
				imgui.SetTooltip('Save the Script')
			end
      
			imgui.SetCursorPos(imgui.ImVec2(5, 157))

			if imgui.CustomButton(
				faicons.ICON_REPEAT, 
				imgui.ImVec4(0.16, 0.16, 0.16, 0.9), 
				imgui.ImVec4(0.40, 0.12, 0.12, 1), 
				imgui.ImVec4(0.30, 0.08, 0.08, 1), 
				imgui.ImVec2(75, 75)) then
				loadIni()
				playAudio()
			end
			if imgui.IsItemHovered() then
				imgui.SetTooltip('Reload the Script')
			end

			imgui.SetCursorPos(imgui.ImVec2(5, 233))

			if imgui.CustomButton(
				faicons.ICON_ERASER, 
				imgui.ImVec4(0.16, 0.16, 0.16, 0.9), 
				imgui.ImVec4(0.40, 0.12, 0.12, 1), 
				imgui.ImVec4(0.30, 0.08, 0.08, 1), 
				imgui.ImVec2(75, 75)) then
				blankIni()
				playAudio()
			end
			if imgui.IsItemHovered() then
				imgui.SetTooltip('Reset the Script to default settings')
			end

			imgui.SetCursorPos(imgui.ImVec2(5, 309))

			if imgui.CustomButton(
				faicons.ICON_RETWEET .. ' Update',
				imgui.ImVec4(0.16, 0.16, 0.16, 0.9), 
				imgui.ImVec4(0.40, 0.12, 0.12, 1), 
				imgui.ImVec4(0.30, 0.08, 0.08, 1),  
				imgui.ImVec2(75, 75)) then
				update_script()
			end
			if imgui.IsItemHovered() then
				imgui.SetTooltip('Update the script')
			end
      
		imgui.EndChild()
		
		imgui.SetCursorPos(imgui.ImVec2(92, 28))

		imgui.BeginChild("##2", imgui.ImVec2(510, 88), true)
      
			imgui.SetCursorPos(imgui.ImVec2(5,5))
			if imgui.CustomButton(faicons.ICON_MUSIC .. '  Radio',
				radio.player.music_player == 1 and imgui.ImVec4(0.56, 0.16, 0.16, 1) or imgui.ImVec4(0.16, 0.16, 0.16, 0.9),
				imgui.ImVec4(0.40, 0.12, 0.12, 1), 
				imgui.ImVec4(0.30, 0.08, 0.08, 1), 
				imgui.ImVec2(125, 75)) then
				radio.player.music_player = 1
			end

			imgui.SetCursorPos(imgui.ImVec2(131, 5))
			  
			if imgui.CustomButton(faicons.ICON_FOLDER_OPEN .. '  Queue',
				radio.player.music_player == 2 and imgui.ImVec4(0.56, 0.16, 0.16, 1) or imgui.ImVec4(0.16, 0.16, 0.16, 0.9),
				imgui.ImVec4(0.40, 0.12, 0.12, 1), 
				imgui.ImVec4(0.30, 0.08, 0.08, 1), 
				imgui.ImVec2(125, 75)) then
			  
				radio.player.music_player = 2
			end

			imgui.SetCursorPos(imgui.ImVec2(257, 5))

			if imgui.CustomButton(faicons.ICON_MUSIC .. '  Music',
				radio.player.music_player == 3 and imgui.ImVec4(0.56, 0.16, 0.16, 1) or imgui.ImVec4(0.16, 0.16, 0.16, 0.9),
				imgui.ImVec4(0.40, 0.12, 0.12, 1), 
				imgui.ImVec4(0.30, 0.08, 0.08, 1), 
				imgui.ImVec2(125, 75)) then
			  
				radio.player.music_player = 3
			end

			imgui.SetCursorPos(imgui.ImVec2(383, 5))

			if imgui.CustomButton(faicons.ICON_FOLDER .. '  Folders',
				radio.player.music_player == 4 and imgui.ImVec4(0.56, 0.16, 0.16, 1) or imgui.ImVec4(0.16, 0.16, 0.16, 0.9),
				imgui.ImVec4(0.40, 0.12, 0.12, 1), 
				imgui.ImVec4(0.30, 0.08, 0.08, 1), 
				imgui.ImVec2(125, 75)) then
			  
				radio.player.music_player = 4
			end
		imgui.EndChild()
		
		imgui.SetCursorPos(imgui.ImVec2(92, 112))
		imgui.BeginChild("##3", imgui.ImVec2(510, 276), true)
		
			if radio.player.music_player == 1 then
				
				radio_player()
				imgui.SameLine()
				
				if imgui.Checkbox('##autoplay', new.bool(radio.player.autoplay)) then 
					radio.player.autoplay = not radio.player.autoplay
					if radio.player.autoplay then
						if not radioplayer then 
							if not musicplayer then
								radio.stationid = 1
								playAudio()
							end
						end
					end
				end 
				if imgui.IsItemHovered() then
					imgui.SetTooltip('Autoplay')
				end
				imgui.SameLine()
				if radio.stations[radio.stationid] ~= nil then
					imgui.Text(string.format(" %s[%d]", radio.stations[radio.stationid].name, radio.stationid))
				else
					imgui.Text(string.format(" Empty[%d]", radio.stationid))
				end
			
				for k, v in ipairs(radio.stations) do
					
					text = new.char[256](v.station)
					imgui.PushItemWidth(320)
					if imgui.InputText('##station'..k, text, sizeof(text), imgui.InputTextFlags.EnterReturnsTrue) then
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
						play_inuse = true
						radio.stationid = k
						playAudio()
						musicplayer = false
						lua_thread.create(function()
							wait(5000)
							play_inuse = false
						end)
					end
				
					imgui.SameLine()
					if k ~= 1 then
						if imgui.Button(u8"x##"..k) then
							table.remove(radio.stations, k)
							radio.stationid = 1
							os.remove(audiopath..'\\playlist'..k)
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
					for id, filetype in pairs(fileformats) do
						if k:match(".+%"..filetype) then
							for x, a in pairs(fileformats) do
								if string.find(k, a) then
									name = split(k, a)
									imgui.Text(name[1])
								end
							end
							imgui.SameLine()
							if imgui.Button('Add to Queue##'..k) then 
								radio.music[#radio.music + 1] = {
									file = v,
									name = k,
								}
							end	
						end 
					end
				end
			end
			if radio.player.music_player == 3 then
				radio_player()
				imgui.SameLine()			
				if imgui.Checkbox('##autoplay', new.bool(radio.player.autoplay)) then 
					radio.player.autoplay = not radio.player.autoplay
					if radio.player.autoplay then
						if not musicplayer then 
							if not radioplayer then
								radio.musicid = 0
							end
						end
					end
				end 
				if imgui.IsItemHovered() then
					imgui.SetTooltip('Autoplay')
				end
				imgui.SameLine()
				if radio.music[radio.musicid] ~= nil then
				
					for x, a in pairs(fileformats) do
						if string.find(radio.music[radio.musicid].name, a) then
							name = split(radio.music[radio.musicid].name, a)
							imgui.Text(string.format(" %s[%d]", name[1], radio.musicid))
						end
					end
					
				else
					imgui.Text(string.format(" Empty[%d]", radio.musicid))
				end
				
				for k, v in ipairs(radio.music) do
					for x, a in pairs(fileformats) do
						if string.find(v.name, a) then
							name = split(v.name, a)
							imgui.Text(name[1])
						end
					end
					
					imgui.SameLine(440)
					if imgui.Button('Play##'..k) then 
						radio.musicid = k
						playAudio()
						radioplayer = false
					end
					
					imgui.SameLine()
					if imgui.Button(u8"x##"..k) then
						table.remove(radio.music, k)
					end
				end
			end
			if radio.player.music_player == 4 then
			
				if imgui.Button(u8"Sync") then
					local new = {}
					for k, v in ipairs(radio.folders) do
						paths = scanGameFolder(v.folder, new)
					end
				end
				imgui.SameLine()
				if imgui.Button(u8"Reset") then
					for k,v in pairs(paths) do
						paths[k] = nil
					end
				end
				imgui.SameLine()
				if imgui.Button(u8"Merge") then
					for k, v in ipairs(radio.folders) do
						paths = scanGameFolder(v.folder, paths)
					end
				end
			
				for k, v in ipairs(radio.folders) do
					imgui.PushItemWidth(360)
					text = new.char[256](v.folder)
					if imgui.InputText('##name21'..k, text, sizeof(text), imgui.InputTextFlags.EnterReturnsTrue) then
						v.folder = u8:decode(str(text))
					end
					imgui.PopItemWidth()
					
					imgui.SameLine()
					
					imgui.PushItemWidth(100)
					text = new.char[256](v.name)
					if imgui.InputText('##name11'..k, text, sizeof(text), imgui.InputTextFlags.EnterReturnsTrue) then
						v.name = u8:decode(str(text))
					end
					imgui.PopItemWidth()
					
					imgui.SameLine()
					if k ~= 1 then
						if imgui.Button(u8"x##"..k) then
							table.remove(radio.folders, k)
						end
					else
						if imgui.Button(u8"+") then
							radio.folders[#radio.folders + 1] = {
								folder = 'path here',
								name = 'name of path',
							}
						end
					end
				end
			end
		imgui.EndChild()
		imgui.SetCursorPos(imgui.ImVec2(92, 384))
		
		imgui.BeginChild("##5", imgui.ImVec2(510, 36), true)
		
			if imgui.Checkbox('Autosave', new.bool(radio.autosave)) then 
				radio.autosave = not radio.autosave 
				saveIni() 
			end
			if imgui.IsItemHovered() then
				imgui.SetTooltip('Autosave')
			end
			imgui.SameLine()
			if imgui.Checkbox('Auto-Update', new.bool(radio.autoupdate)) then 
				radio.autoupdate = not radio.autoupdate 
			end
			if imgui.IsItemHovered() then
				imgui.SetTooltip('Auto-Update')
			end
			
			imgui.SameLine()
			
			imgui.PushItemWidth(150)
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
		imgui.EndChild()
    imgui.End()
end)

function onWindowMessage(msg, wparam, lparam)
	if msg == wm.WM_KILLFOCUS then
		if radio.player.pause_play then
			if radio.player.music_player == 1 then
				if not musicplayer then
					if radio_play ~= nil then
						play_inuse = true
						setAudioStreamState(radio_play, as_action.STOP)
						if debug_messages then
							print('Radio WM_KILLFOCUS')
						end
						lua_thread.create(function()
							wait(5000)
							play_inuse = false
						end)
					else
						if radio_play ~= nil then
							play_inuse = true
							setAudioStreamState(radio_play, as_action.PAUSE)
							if debug_messages then
								print('Music WM_KILLFOCUS')
							end
							lua_thread.create(function()
								wait(5000)
								play_inuse = false
							end)
						end
					end
				end
			end
			if radio.player.music_player >= 2 and radio.player.music_player <= 4 then
				if radio_play ~= nil then
					play_inuse = true
					setAudioStreamState(radio_play, as_action.PAUSE)
					if debug_messages then
						print('Music WM_KILLFOCUS')
					end
					lua_thread.create(function()
						wait(5000)
						play_inuse = false
					end)
				end
			end
		else
			if radio_play ~= nil then
				releaseAudioStream(radio_play)
			end
		end
	elseif msg == wm.WM_SETFOCUS then
		if radio.player.pause_play then
			if radio.player.music_player == 1 then
				if not musicplayer then
					playAudio()
					lua_thread.create(function()
						wait(5000)
						play_inuse = false
					end)
					if debug_messages then
						print('radio WM_SETFOCUS')
					end
				else
					if radio_play ~= nil then
						radio.player.pause_play = true
						radio.player.stop = false
						setAudioStreamState(radio_play, as_action.RESUME)
						lua_thread.create(function()
							wait(5000)
							play_inuse = false
						end)
						if debug_messages then
							print('music WM_SETFOCUS')
						end
					end
				end
			end
			if radio.player.music_player >= 2 and radio.player.music_player <= 4 then
				if radio_play ~= nil then
					radio.player.pause_play = true
					radio.player.stop = false
					setAudioStreamState(radio_play, as_action.RESUME)
					lua_thread.create(function()
						wait(5000)
						play_inuse = false
					end)
					if debug_messages then
						print('music WM_SETFOCUS')
					end
				end
			end
		else
			if radio_play ~= nil then
				releaseAudioStream(radio_play)
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

function sampev.onPlayAudioStream(url, position, radius, usePosition)
	--print(url)
	if not radio.player.stop then
		return false
	end
end

function update_script()
	downloadUrlToFile(update_url, getWorkingDirectory()..'/'..string.lower(script.this.name)..'.txt', function(id, status)
		if status == dlstatus.STATUS_ENDDOWNLOADDATA then
			update_text = https.request(update_url)
			update_version = update_text:match("version: (.+)")
			
			--local split1 = split(script_path, 'moonloader\\')
			--local split2 = split(split1[2], ".")
			--if split2[2] ~= nil then
				--if split2[2] ~= 'lua' then
					if tonumber(update_version) > script_version then
						sampAddChatMessage(string.format("{ABB2B9}[%s]{FFFFFF} New version found! The update is in progress..", script.this.name), -1)
						downloadUrlToFile(script_url, script_path, function(id, status)
							if status == dlstatus.STATUS_ENDDOWNLOADDATA then
								sampAddChatMessage(string.format("{ABB2B9}[%s]{FFFFFF} The update was successful!", script.this.name), -1)
								update = true
							end
						end)
					end
				--end
			--end
		end
	end)
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

function playAudio()
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
		if radio.player.music_player == 1 then
			if radio.stations[radio.stationid] ~= nil then
				if not radio.player.stop then
					downloadUrlToFile(radio.stations[radio.stationid].station, audiopath..string.lower(script.this.name)..radio.stationid..'.pls', function(id, status)
						if status == dlstatus.STATUS_ENDDOWNLOADDATA then
							if debug_messages then
								print('play_radio() radio.player.music_player == 1 station = ' .. radio.stations[radio.stationid].station)
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
							radioplayer = true
						end
					end)
				end
			end
		end
		if radio.player.music_player >= 2 and radio.player.music_player <= 4 then
			if not radio.player.stop then
				if radio.music[radio.musicid] ~= nil then
					if doesFileExist(radio.music[radio.musicid].file) then		
					
						if debug_messages then
							print('play_radio() music' .. radio.music[radio.musicid].file)
						end
						
						if radio_play ~= nil then
							releaseAudioStream(radio_play)
						end
						radio_play = loadAudioStream(radio.music[radio.musicid].file)
						if radio_play ~= nil then
							setAudioStreamVolume(radio_play, radio.player.volume)
						end
							
						if radio.player.pause_play then
							if radio_play ~= nil then
								setAudioStreamState(radio_play, as_action.RESUME)
							end
						else
							if radio_play ~= nil then
								setAudioStreamState(radio_play, as_action.PAUSE)
							end
						end
						musicplayer = true
					else
						sampAddChatMessage(string.format("{ABB2B9}[%s]{FFFFFF} Bad audio file detected!", script.this.name), -1)
					end
				end
			end
		end
	end
end

function radio_player()
	if imgui.Button(faicons.ICON_STEP_BACKWARD) then
		if radio.player.music_player == 1 then
			if radio.stationid >= 1 and radio.stationid <= table.maxn(radio.stations) + 1 then
				radio.stationid = radio.stationid - 1
				if debug_messages then
					print('ICON_STEP_BACKWARD stationid = '..radio.stationid)
				end
				playAudio()
			end
				
			if radio.stationid == 0 then
				radio.stationid = table.maxn(radio.stations)
				if debug_messages then
					print('ICON_STEP_BACKWARD: stationid = '..radio.stationid)
				end
				playAudio()
			end
		end
		if radio.player.music_player >= 2 and radio.player.music_player <= 4 then
			if radio.musicid >= 1 and radio.musicid <= table.maxn(radio.music) then
				radio.musicid = radio.musicid - 1
				if debug_messages then
					print('ICON_STEP_BACKWARD: musicid = '..radio.musicid)
				end
				playAudio()
			end

			if radio.musicid == 0 then
				radio.musicid = table.maxn(radio.music)
				if debug_messages then
					print('ICON_STEP_BACKWARD: musicid = '..radio.musicid)
				end
				playAudio()
			end
		end
	end
	imgui.SameLine(26) 
	if imgui.Button(not radio.player.stop and (radio.player.pause_play and faicons.ICON_PAUSE .. '##Pause' or faicons.ICON_PLAY .. '##Play') or faicons.ICON_PLAY) then
		if radio.player.music_player == 1 then
			if not radio.player.stop then
				radio.player.pause_play = not radio.player.pause_play
				print(radio.player.pause_play)
				if radio.player.pause_play then
					radio.player.pause_play = true
					if radio_play ~= nil then
						setAudioStreamState(radio_play, as_action.PLAY)
					end
					playAudio()
				else
					radio.player.pause_play = false
					if radio_play ~= nil then
						setAudioStreamState(radio_play, as_action.PAUSE)
					end
				end
			end
		end
			
		if radio.player.music_player >= 2 and radio.player.music_player <= 4 then
			if not radio.player.stop then
				radio.player.pause_play = not radio.player.pause_play
				print(radio.player.pause_play)
				if radio.player.pause_play then
					radio.player.pause_play = true
					if radio_play ~= nil then
						setAudioStreamState(radio_play, as_action.RESUME)
					end
					if not musicplayer then
						playAudio()
					end
				else		
					radio.player.pause_play = false
					if radio_play ~= nil then
						setAudioStreamState(radio_play, as_action.PAUSE)
					end
				end
			end
		end
	end 
	imgui.SameLine(48) 
	if imgui.Button(radio.player.stop and faicons.ICON_PLAY_CIRCLE or faicons.ICON_STOP) then
		if radio.player.music_player == 1 then
			radio.player.stop = not radio.player.stop
			playAudio()
		end
		if radio.player.music_player >= 2 and radio.player.music_player <= 4 then
			radio.player.stop = not radio.player.stop
			playAudio()
		end
	end
	imgui.SameLine(70) 
	if imgui.Button(faicons.ICON_STEP_FORWARD) then
		if radio.player.music_player == 1 then
			if radio.stationid >= 1 and radio.stationid <= table.maxn(radio.stations) then
				radio.stationid = radio.stationid + 1
				if debug_messages then
					print('ICON_STEP_FORWARD: stationid = '..radio.stationid)
				end
					
				playAudio()
			end
			if radio.stationid == table.maxn(radio.stations) + 1 then
				radio.stationid = 1
				if debug_messages then
					print('ICON_STEP_FORWARD: stationid = '..radio.stationid)
				end
				playAudio()
			end
		end
		if radio.player.music_player >= 2 and radio.player.music_player <= 4 then
			if radio.musicid >= 1 and radio.musicid <= table.maxn(radio.music) then
				radio.musicid = radio.musicid + 1
				if debug_messages then
					print('ICON_STEP_FORWARD: musicid = '..radio.musicid)
				end
					
				playAudio()
			end
			if radio.musicid == table.maxn(radio.music) + 1 then
				radio.musicid = 1
				if debug_messages then
					print('ICON_STEP_FORWARD: musicid = '..radio.musicid)
				end
				playAudio()
			end
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
			f:write(encodeJson(radio, false)) 
			f:close() 
		end 
	end 
end

function httpRequest(request, body, handler) -- copas.http
    -- start polling task
    if not copas.running then
        copas.running = true
        lua_thread.create(function()
            wait(0)
            while not copas.finished() do
                local ok, err = copas.step(0)
                if ok == nil then error(err) end
                wait(0)
            end
            copas.running = false
        end)
    end
    -- do request
    if handler then
        return copas.addthread(function(r, b, h)
            copas.setErrorHandler(function(err) h(nil, err) end)
            h(http.request(r, b))
        end, request, body, handler)
    else
        local results
        local thread = copas.addthread(function(r, b)
            copas.setErrorHandler(function(err) results = {nil, err} end)
            results = table.pack(http.request(r, b))
        end, request, body)
        while coroutine.status(thread) ~= 'dead' do wait(0) end
        return table.unpack(results)
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

-- IMGUI_API bool          CustomButton(const char* label, const ImVec4& col, const ImVec4& col_focus, const ImVec4& col_click, const ImVec2& size = ImVec2(0,0));
function imgui.CustomButton(name, color, colorHovered, colorActive, size)
    local clr = imgui.Col
    imgui.PushStyleColor(clr.Button, color)
    imgui.PushStyleColor(clr.ButtonHovered, colorHovered)
    imgui.PushStyleColor(clr.ButtonActive, colorActive)
    if not size then size = imgui.ImVec2(0, 0) end
    local result = imgui.Button(name, size)
    imgui.PopStyleColor(3)
    return result
end

function apply_custom_style()
	imgui.SwitchContext()
	local ImVec4 = imgui.ImVec4
	local ImVec2 = imgui.ImVec2
	local style = imgui.GetStyle()
	style.WindowRounding = 0
	style.WindowPadding = ImVec2(8, 8)
	style.WindowTitleAlign = ImVec2(0.5, 0.5)
	--style.ChildWindowRounding = 0
	style.FrameRounding = 0
	style.ItemSpacing = ImVec2(8, 4)
	style.ScrollbarSize = 10
	style.ScrollbarRounding = 3
	style.GrabMinSize = 10
	style.GrabRounding = 0
	style.Alpha = 1
	style.FramePadding = ImVec2(4, 3)
	style.ItemInnerSpacing = ImVec2(4, 4)
	style.TouchExtraPadding = ImVec2(0, 0)
	style.IndentSpacing = 21
	style.ColumnsMinSpacing = 6
	style.ButtonTextAlign = ImVec2(0.5, 0.5)
	style.DisplayWindowPadding = ImVec2(22, 22)
	style.DisplaySafeAreaPadding = ImVec2(4, 4)
	style.AntiAliasedLines = true
	--style.AntiAliasedShapes = true
	style.CurveTessellationTol = 1.25
	local colors = style.Colors
	local clr = imgui.Col
	colors[clr.FrameBg]                = ImVec4(0.48, 0.16, 0.16, 0.54)
	colors[clr.FrameBgHovered]         = ImVec4(0.98, 0.26, 0.26, 0.40)
	colors[clr.FrameBgActive]          = ImVec4(0.98, 0.26, 0.26, 0.67)
	colors[clr.TitleBg]                = ImVec4(0.04, 0.04, 0.04, 1.00)
	colors[clr.TitleBgActive]          = ImVec4(0.48, 0.16, 0.16, 1.00)
	colors[clr.TitleBgCollapsed]       = ImVec4(0.00, 0.00, 0.00, 0.51)
	colors[clr.CheckMark]              = ImVec4(0.98, 0.26, 0.26, 1.00)
	colors[clr.SliderGrab]             = ImVec4(0.88, 0.26, 0.24, 1.00)
	colors[clr.SliderGrabActive]       = ImVec4(0.98, 0.26, 0.26, 1.00)
	colors[clr.Button]                 = ImVec4(0.98, 0.26, 0.26, 0.40)
	colors[clr.ButtonHovered]          = ImVec4(0.98, 0.26, 0.26, 1.00)
	colors[clr.ButtonActive]           = ImVec4(0.98, 0.06, 0.06, 1.00)
	colors[clr.Header]                 = ImVec4(0.98, 0.26, 0.26, 0.31)
	colors[clr.HeaderHovered]          = ImVec4(0.98, 0.26, 0.26, 0.80)
	colors[clr.HeaderActive]           = ImVec4(0.98, 0.26, 0.26, 1.00)
	colors[clr.Separator]              = colors[clr.Border]
	colors[clr.SeparatorHovered]       = ImVec4(0.75, 0.10, 0.10, 0.78)
	colors[clr.SeparatorActive]        = ImVec4(0.75, 0.10, 0.10, 1.00)
	colors[clr.ResizeGrip]             = ImVec4(0.98, 0.26, 0.26, 0.25)
	colors[clr.ResizeGripHovered]      = ImVec4(0.98, 0.26, 0.26, 0.67)
	colors[clr.ResizeGripActive]       = ImVec4(0.98, 0.26, 0.26, 0.95)
	colors[clr.TextSelectedBg]         = ImVec4(0.98, 0.26, 0.26, 0.35)
	colors[clr.Text]                   = ImVec4(1.00, 1.00, 1.00, 1.00)
	colors[clr.TextDisabled]           = ImVec4(0.50, 0.50, 0.50, 1.00)
	colors[clr.WindowBg]               = ImVec4(0.06, 0.06, 0.06, 0.94)
	--colors[clr.ChildWindowBg]          = ImVec4(1.00, 1.00, 1.00, 0.00)
	colors[clr.PopupBg]                = ImVec4(0.08, 0.08, 0.08, 0.94)
	--colors[clr.ComboBg]                = colors[clr.PopupBg]
	colors[clr.Border]                 = ImVec4(0.43, 0.43, 0.50, 0.50)
	colors[clr.BorderShadow]           = ImVec4(0.00, 0.00, 0.00, 0.00)
	colors[clr.MenuBarBg]              = ImVec4(0.14, 0.14, 0.14, 1.00)
	colors[clr.ScrollbarBg]            = ImVec4(0.02, 0.02, 0.02, 0.53)
	colors[clr.ScrollbarGrab]          = ImVec4(0.31, 0.31, 0.31, 1.00)
	colors[clr.ScrollbarGrabHovered]   = ImVec4(0.41, 0.41, 0.41, 1.00)
	colors[clr.ScrollbarGrabActive]    = ImVec4(0.51, 0.51, 0.51, 1.00)
	--colors[clr.CloseButton]            = ImVec4(0.41, 0.41, 0.41, 0.50)
	--colors[clr.CloseButtonHovered]     = ImVec4(0.98, 0.39, 0.36, 1.00)
	--colors[clr.CloseButtonActive]      = ImVec4(0.98, 0.39, 0.36, 1.00)
	colors[clr.PlotLines]              = ImVec4(0.61, 0.61, 0.61, 1.00)
	colors[clr.PlotLinesHovered]       = ImVec4(1.00, 0.43, 0.35, 1.00)
	colors[clr.PlotHistogram]          = ImVec4(0.90, 0.70, 0.00, 1.00)
	colors[clr.PlotHistogramHovered]   = ImVec4(1.00, 0.60, 0.00, 1.00)
	--colors[clr.ModalWindowDarkening]   = ImVec4(0.80, 0.80, 0.80, 0.35)
end