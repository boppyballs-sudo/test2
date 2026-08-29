local Players = game:GetService("Players")

do
	local _ENV_SKIP_IDS = {
		[292439477]       = true,
		[113491250]       = true,
		[7264587281]      = true,
		[109397169461300] = true,
		[6035872082]	  = true,
		[17625359962]	  = true,
	}
	if game and (_ENV_SKIP_IDS[game.PlaceId] or _ENV_SKIP_IDS[game.GameId]) then
		if getgenv then getgenv().XYLOS_SKIP_ENV_DETECT = true end
	end
end

local uis = game:GetService("UserInputService")
local players = Players
local ws = game:GetService("Workspace")
local http_service = game:GetService("HttpService")
local gui_service = game:GetService("GuiService")

local coregui = game.CoreGui
local tween_service = game:GetService("TweenService")
local run_service = game:GetService("RunService")

local vec2 = Vector2.new
local vec3 = Vector3.new
local dim2 = UDim2.new
local dim = UDim.new
local rect = Rect.new
local cfr = CFrame.new

local color = Color3.new
local rgb = Color3.fromRGB
local hex = Color3.fromHex
local hsv = Color3.fromHSV
local rgbseq = ColorSequence.new
local rgbkey = ColorSequenceKeypoint.new

local camera = ws.CurrentCamera
local lp = players.LocalPlayer
local mouse = lp:GetMouse()
local gui_offset = gui_service:GetGuiInset().Y

local max = math.max
local floor = math.floor
local min = math.min
local abs = math.abs
local clamp = math.clamp
local sin_wave = math.sin
local cos_wave = math.cos
local clock = os.clock

-- Background effects are decorative; keeping their simulation at a bounded
-- cadence avoids competing with the game's render/update work while keeping
-- their existing motion and controls intact.
local BG_UPDATE_INTERVAL = 1 / 30

local library = {
	flags = {},
	config_flags = {},
	connections = {},
	notifications = {},
	instances = {},
	main_frame = {},
	curve_boxes = {},
	config_holder = nil,
	theme_config_holder = nil,
	current_tab = nil,
	current_element_open = nil,
	dock_button_holder = nil,
	gui = nil,
	sin = 0,
	keybind_path  = nil,
	panel_open = false,
	active_colorpicker = nil,
	active_drag = nil,
	active_resize = nil,

	directory = "VNEO",
	folders = {
		"/fonts",
		"/configs",
		"/themes",
	},
	font = nil,

	bg_theme = nil,
	bg_theme_connection = nil,
	bg_canvas = nil,
	bg_blur = nil,
	-- Keep the frosted styling lightweight by default. A global BlurEffect is
	-- opt-in through the background-blur slider and is disabled while Roblox
	-- is unfocused so it cannot leave a stale/white frame behind.
	bg_blur_amount = 0,
	-- Build every surface in the frosted state.  The old default left the
	-- window shell translucent while controls created during startup retained
	-- opaque backgrounds until a theme dropdown/config callback ran.
	ui_theme = "Frosted Glass",
	frost_blur = nil,
	_styled_gui = setmetatable({}, { __mode = "k" }),
	_theme_alpha_defaults = setmetatable({}, { __mode = "k" }),

	nav_elements = {},
	nav_tabs     = {},
}

local flags = library.flags
local config_flags = library.config_flags

local themes = {
	preset = {
		["outline"] = rgb(45, 45, 54),
		["inline"] = rgb(23, 23, 29),
		["accent"] = rgb(160, 156, 252),
		["contrast"] = rgb(15, 15, 20),
		["text"] = rgb(232, 232, 242),
		["unselected_text"] = rgb(168, 166, 182),
		["text_outline"] = rgb(0, 0, 0),
		["glow"] = rgb(160, 156, 252),
	},

	registered = {
		outline  = {},
		inline   = {},
		contrast = {},
		text     = {},
	},

	utility = {
		["outline"] = {
			["BackgroundColor3"] = {},
			["Color"] = {},
		},
		["inline"] = {
			["BackgroundColor3"] = {},
		},
		["accent"] = {
			["BackgroundColor3"] = {},
			["TextColor3"] = {},
			["ImageColor3"] = {},
			["BorderColor3"] = {},
			["Color"] = {},
			["ScrollBarImageColor3"] = {},
		},
		["contrast"] = {
			["Color"] = {},
			["BackgroundColor3"] = {},
		},
		["text"] = {
			["TextColor3"] = {},
		},
		["text_outline"] = {
			["Color"] = {},
		},
		["glow"] = {
			["ImageColor3"] = {},
		},
	},
}

local keys = {
	[Enum.KeyCode.LeftShift] = "LS",
	[Enum.KeyCode.RightShift] = "RS",
	[Enum.KeyCode.LeftControl] = "LC",
	[Enum.KeyCode.RightControl] = "RC",
	[Enum.KeyCode.Insert] = "INS",
	[Enum.KeyCode.Backspace] = "BS",
	[Enum.KeyCode.Return] = "Ent",
	[Enum.KeyCode.LeftAlt] = "LA",
	[Enum.KeyCode.RightAlt] = "RA",
	[Enum.KeyCode.CapsLock] = "CAPS",
	[Enum.KeyCode.One] = "1",
	[Enum.KeyCode.Two] = "2",
	[Enum.KeyCode.Three] = "3",
	[Enum.KeyCode.Four] = "4",
	[Enum.KeyCode.Five] = "5",
	[Enum.KeyCode.Six] = "6",
	[Enum.KeyCode.Seven] = "7",
	[Enum.KeyCode.Eight] = "8",
	[Enum.KeyCode.Nine] = "9",
	[Enum.KeyCode.Zero] = "0",
	[Enum.KeyCode.KeypadOne] = "Num1",
	[Enum.KeyCode.KeypadTwo] = "Num2",
	[Enum.KeyCode.KeypadThree] = "Num3",
	[Enum.KeyCode.KeypadFour] = "Num4",
	[Enum.KeyCode.KeypadFive] = "Num5",
	[Enum.KeyCode.KeypadSix] = "Num6",
	[Enum.KeyCode.KeypadSeven] = "Num7",
	[Enum.KeyCode.KeypadEight] = "Num8",
	[Enum.KeyCode.KeypadNine] = "Num9",
	[Enum.KeyCode.KeypadZero] = "Num0",
	[Enum.KeyCode.Minus] = "-",
	[Enum.KeyCode.Equals] = "=",
	[Enum.KeyCode.Tilde] = "~",
	[Enum.KeyCode.LeftBracket] = "[",
	[Enum.KeyCode.RightBracket] = "]",
	[Enum.KeyCode.RightParenthesis] = ")",
	[Enum.KeyCode.LeftParenthesis] = "(",
	[Enum.KeyCode.Semicolon] = ";",
	[Enum.KeyCode.Quote] = "'",
	[Enum.KeyCode.BackSlash] = "\\",
	[Enum.KeyCode.Comma] = ",",
	[Enum.KeyCode.Period] = ".",
	[Enum.KeyCode.Slash] = "/",
	[Enum.KeyCode.Asterisk] = "*",
	[Enum.KeyCode.Plus] = "+",
	[Enum.KeyCode.Backquote] = "`",
	[Enum.UserInputType.MouseButton1] = "MB1",
	[Enum.UserInputType.MouseButton2] = "MB2",
	[Enum.UserInputType.MouseButton3] = "MB3",
	[Enum.KeyCode.Escape] = "ESC",
	[Enum.KeyCode.Space] = "SPC",

	[Enum.KeyCode.A] = "A", [Enum.KeyCode.B] = "B", [Enum.KeyCode.C] = "C",
	[Enum.KeyCode.D] = "D", [Enum.KeyCode.E] = "E", [Enum.KeyCode.F] = "F",
	[Enum.KeyCode.G] = "G", [Enum.KeyCode.H] = "H", [Enum.KeyCode.I] = "I",
	[Enum.KeyCode.J] = "J", [Enum.KeyCode.K] = "K", [Enum.KeyCode.L] = "L",
	[Enum.KeyCode.M] = "M", [Enum.KeyCode.N] = "N", [Enum.KeyCode.O] = "O",
	[Enum.KeyCode.P] = "P", [Enum.KeyCode.Q] = "Q", [Enum.KeyCode.R] = "R",
	[Enum.KeyCode.S] = "S", [Enum.KeyCode.T] = "T", [Enum.KeyCode.U] = "U",
	[Enum.KeyCode.V] = "V", [Enum.KeyCode.W] = "W", [Enum.KeyCode.X] = "X",
	[Enum.KeyCode.Y] = "Y", [Enum.KeyCode.Z] = "Z",

	[Enum.KeyCode.F1]  = "F1",  [Enum.KeyCode.F2]  = "F2",  [Enum.KeyCode.F3]  = "F3",
	[Enum.KeyCode.F4]  = "F4",  [Enum.KeyCode.F5]  = "F5",  [Enum.KeyCode.F6]  = "F6",
	[Enum.KeyCode.F7]  = "F7",  [Enum.KeyCode.F8]  = "F8",  [Enum.KeyCode.F9]  = "F9",
	[Enum.KeyCode.F10] = "F10", [Enum.KeyCode.F11] = "F11", [Enum.KeyCode.F12] = "F12",
	[Enum.KeyCode.F13] = "F13", [Enum.KeyCode.F14] = "F14", [Enum.KeyCode.F15] = "F15",

	[Enum.KeyCode.Tab]        = "Tab",
	[Enum.KeyCode.Delete]     = "Del",
	[Enum.KeyCode.Home]       = "Home",
	[Enum.KeyCode.End]        = "End",
	[Enum.KeyCode.PageUp]     = "PgUp",
	[Enum.KeyCode.PageDown]   = "PgDn",
	[Enum.KeyCode.Up]         = "Up",
	[Enum.KeyCode.Down]       = "Dn",
	[Enum.KeyCode.Left]       = "Left",
	[Enum.KeyCode.Right]      = "Right",

	[Enum.KeyCode.KeypadPeriod]  = "Num.",
	[Enum.KeyCode.KeypadDivide]  = "Num/",
	[Enum.KeyCode.KeypadMultiply]= "Num*",
	[Enum.KeyCode.KeypadMinus]   = "Num-",
	[Enum.KeyCode.KeypadPlus]    = "Num+",
	[Enum.KeyCode.KeypadEnter]   = "NumEnt",

	[Enum.KeyCode.Print]       = "PrtSc",
	[Enum.KeyCode.ScrollLock]  = "ScrLk",
	[Enum.KeyCode.Pause]       = "Pause",
	[Enum.KeyCode.NumLock]     = "NmLk",
	[Enum.KeyCode.LeftSuper] = "LWin",
	[Enum.KeyCode.RightSuper]= "RWin",
	[Enum.KeyCode.Menu] = "Menu",
	[Enum.KeyCode.World0]      = "W0",
	[Enum.KeyCode.World1]      = "W1",

	[Enum.KeyCode.ButtonA]            = "A",
	[Enum.KeyCode.ButtonB]            = "B",
	[Enum.KeyCode.ButtonX]            = "X",
	[Enum.KeyCode.ButtonY]            = "Y",
	[Enum.KeyCode.ButtonL1]           = "LB",
	[Enum.KeyCode.ButtonR1]           = "RB",
	[Enum.KeyCode.ButtonL2]           = "LT",
	[Enum.KeyCode.ButtonR2]           = "RT",
	[Enum.KeyCode.ButtonL3]           = "LS",
	[Enum.KeyCode.ButtonR3]           = "RS",
	[Enum.KeyCode.ButtonStart]        = "Start",
	[Enum.KeyCode.ButtonSelect]       = "Select",
	[Enum.KeyCode.DPadUp]             = "D-Up",
	[Enum.KeyCode.DPadDown]           = "D-Dn",
	[Enum.KeyCode.DPadLeft]           = "D-Lt",
	[Enum.KeyCode.DPadRight]          = "D-Rt",
	[Enum.KeyCode.Thumbstick1]        = "LS-Mv",
	[Enum.KeyCode.Thumbstick2]        = "RS-Mv",

	[Enum.UserInputType.Gamepad1]     = "GP1",
	[Enum.UserInputType.Gamepad2]     = "GP2",
	[Enum.UserInputType.Gamepad3]     = "GP3",
	[Enum.UserInputType.Gamepad4]     = "GP4",
}

library.__index = library

if not isfolder(library.directory) then
	makefolder(library.directory)
end
for _, path in next, library.folders do
	if not isfolder(library.directory .. path) then
		makefolder(library.directory .. path)
	end
end

if not isfile(library.directory .. "/fonts/main.ttf") then
	-- Local-only build: do not fetch assets from a remote host.
end

local tahoma = {
	name = "SmallestPixel7",
	faces = {
		{
			name = "Regular",
			weight = 400,
			style = "normal",
			assetId = isfile(library.directory .. "/fonts/main.ttf") and getcustomasset(library.directory .. "/fonts/main.ttf") or nil,
		},
	},
}

if not isfile(library.directory .. "/fonts/main_encoded.ttf") then
	writefile(library.directory .. "/fonts/main_encoded.ttf", http_service:JSONEncode(tahoma))
end

if tahoma.faces[1].assetId then
	 library.font = Font.new(getcustomasset(library.directory .. "/fonts/main_encoded.ttf"), Enum.FontWeight.Regular)
else
	 library.font = Font.fromEnum(Enum.Font.Code)
end

function library.to_screen_point(position)
	return camera:WorldToViewportPoint(position)
end

function library:unload()
	library.gui:Destroy()

	for _, connection in library.connections do
		connection:Disconnect()
	end

	for _, item in library.instances do
		item:Destroy()
	end

	if library.bg_blur then
		library.bg_blur:Destroy()
		library.bg_blur = nil
	end

	if library.bg_canvas then
		library.bg_canvas:Destroy()
		library.bg_canvas = nil
	end

	if library.frost_blur then
		library.frost_blur:Destroy()
		library.frost_blur = nil
	end

	getgenv().library = nil
end

function library:convert_string_rgb(str)
	local values = {}

	for value in string.gmatch(str, "[^,]+") do
		table.insert(values, tonumber(value))
	end

	if #values == 4 then
		local r, g, b, a = values[1], values[2], values[3], values[4]
		return r, g, b, a
	else
		library:notification({ text = "Input a correct RGBA value (in the format 255, 255, 255, 0.5)" })
	end
end

function library:connection(signal, callback)
	local connection = signal:Connect(callback)
	table.insert(library.connections, connection)
	return connection
end

function library:make_resizable(frame, options)
	options = options or {}
	local Frame = Instance.new("TextButton")
	Frame.Position = dim2(1, -10, 1, -10)
	Frame.BorderColor3 = rgb(0, 0, 0)
	Frame.Size = dim2(0, 10, 0, 10)
	Frame.BorderSizePixel = 0
	Frame.BackgroundColor3 = rgb(255, 255, 255)
	Frame.Parent = frame
	Frame.BackgroundTransparency = 1
	Frame.Text = ""

	local start_size
	local start
	local og_size = frame.Size

	Frame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			start = input.Position
			start_size = frame.Size
			library.active_resize = {
				frame = frame,
				start = start,
				start_size = start_size,
				og_size = og_size,
				on_move = options.on_move,
				on_end = options.on_end,
			}
			if options.on_start then pcall(options.on_start, frame) end
		end
	end)
end

function library:make_draggable(frame, options)
	options = options or {}
	local drag_start
	local start_position

	frame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			drag_start = input.Position
			start_position = frame.Position
			library.active_drag = {
				frame = frame,
				drag_start = drag_start,
				start_position = start_position,
				on_move = options.on_move,
				on_end = options.on_end,
			}
			if options.on_start then pcall(options.on_start, frame) end
		end
	end)
end

function library:new_item(class, properties)
	local ins = Instance.new(class)

	for _, v in next, properties do
		ins[_] = v
	end

	table.insert(library.instances, ins)
	return ins
end

function library:animation(text)
	local pattern = {}
	for i = 1, tonumber(text:len()) do
		table.insert(pattern, string.sub(text, 1, i))
	end
	for i = tonumber(text:len()) - 1, 0, -1 do
		table.insert(pattern, string.sub(text, 1, i))
	end
	return pattern
end

function library:convert_enum(enum)
	local enum_parts = {}

	for part in string.gmatch(enum, "[%w_]+") do
		table.insert(enum_parts, part)
	end

	local enum_table = Enum
	for i = 2, #enum_parts do
		local enum_item = enum_table[enum_parts[i]]
		enum_table = enum_item
	end

	return enum_table
end

function library:config_list_update()
	local list = {}
	local seen = {}
	local searchDirs = { library.config_dir or (library.directory .. "/configs/Universal/"), library.directory .. "/configs/" }
	for _, searchDir in ipairs(searchDirs) do
		if isfolder(searchDir) then
			local ok, files = pcall(listfiles, searchDir)
			if ok and type(files) == "table" then
				for _, file in ipairs(files) do
					local normalized = tostring(file):gsub("\\", "/")
					local filename = normalized:match("([^/]+)$") or normalized
					if filename:lower():sub(-4) == ".cfg" then
						local name = filename:sub(1, -5)
						if name ~= "" and name:lower() ~= "autoload" and not seen[name:lower()] then
							seen[name:lower()] = true
							list[#list + 1] = name
						end
					end
				end
			end
		end
	end
	table.sort(list, function(a, b) return a:lower() < b:lower() end)
	if library.config_holder and library.config_holder.refresh_options then library.config_holder:refresh_options(list) end
	if library.autoload_holder and library.autoload_holder.refresh_options then library.autoload_holder:refresh_options(list) end
	return list
end

function library:get_config_table()
	local Config = {}

	for _, v in flags do
		if type(v) == "table" and v.key then
			Config[_] = { active = v.active, mode = v.mode, key = tostring(v.key) }
		elseif type(v) == "table" and v["Transparency"] and v["Color"] then
			local colorValue = v["Color"]
			if typeof(colorValue) == "Color3" then
				colorValue = colorValue:ToHex()
			end
			if type(colorValue) == "string" then
				Config[_] = { Transparency = v["Transparency"], Color = colorValue }
			else
				Config[_] = v
			end
		else
			Config[_] = v
		end
	end

	return Config
end

function library:get_config()
	return http_service:JSONEncode(self:get_config_table())
end

function library:load_config(config_json)
	local was_suppressed = self._suppress_ui == true
	if self.set_transient_suppressed then
		self:set_transient_suppressed(true)
	end

	local decoded, config = pcall(http_service.JSONDecode, http_service, config_json)
	if not decoded or type(config) ~= "table" then
		if self.set_transient_suppressed then
			self:set_transient_suppressed(was_suppressed)
		end
		return false
	end

	local load_count = 0
	for _, v in next, config do
		local function_set = library.config_flags[_]

		if function_set then
			if type(v) == "table" and v["Transparency"] and v["Color"] then
				local colorValue = v["Color"]
				if typeof(colorValue) ~= "Color3" then
					local ok, parsed = pcall(hex, tostring(colorValue))
					if ok then
						colorValue = parsed
					end
				end
				function_set(colorValue, v["Transparency"])
			elseif type(v) == "table" and v["active"] then
				function_set(v)
			else
				function_set(v)
			end
		end

		load_count = load_count + 1
		if load_count % 20 == 0 then
			task.wait()
		end
	end

	if self.set_transient_suppressed then
		self:set_transient_suppressed(was_suppressed)
	end
	return true
end

function library:round(number, float)
	local multiplier = 1 / (float or 1)
	return math.floor(number * multiplier + 0.5) / multiplier
end

function library:apply_theme(instance, theme, property)
	table.insert(themes.utility[theme][property], instance)
	if property == "BackgroundColor3" and self._styled_gui and self._styled_gui[instance] then
		self._styled_gui[instance].themeRole = theme
		self._styled_gui[instance].defaultColor = themes.preset[theme]
	end

	-- Rounded controls use UIStroke instead of Roblox's square legacy border.
	-- Keep those strokes attached to the same theme role as the original border.
	if property == "BorderColor3" then
		local outline = instance:FindFirstChild("VNEOOutline")
		local colorBucket = themes.utility[theme].Color
		if outline and outline:IsA("UIStroke") and colorBucket then
			table.insert(colorBucket, outline)
		end
	end
end

function library:register_theme_element(instance, role, property)
	if not themes.registered[role] then return end
	table.insert(themes.registered[role], { instance = instance, property = property })
end

local _theme_to_frame_role = {
	contrast = "background",
	inline    = "main",
	outline   = "outline",
}

function library:update_theme(theme, color)
	for _, property in next, themes.utility[theme] do
		for m, object in next, property do
			local ok, match = pcall(function() return object[_] == themes.preset[theme] end)
			if ok and match then
				pcall(function() object[_] = color end)
			end
		end
	end

	themes.preset[theme] = color
	for instance, state in pairs(self._styled_gui) do
		if instance and instance.Parent and state and state.themeRole == theme then
			state.defaultColor = color
		end
	end

	if themes.registered[theme] then
		for _, entry in next, themes.registered[theme] do
			local inst = entry.instance
			local ok, hasParent = pcall(function() return inst and inst.Parent end)
			if ok and hasParent then
				pcall(function() inst[entry.property] = color end)
			end
		end
	end

	local frameRole = _theme_to_frame_role[theme]
	if frameRole then
		library:update_theme_frame(frameRole, color)
	end
end

function library:update_theme_alpha(theme, alpha)
	if theme ~= "accent" then return end
	alpha = math.clamp(tonumber(alpha) or 1, 0, 1)
	local buckets = themes.utility[theme]
	if not buckets then return end
	local mappings = {
		BackgroundColor3 = "BackgroundTransparency",
		ImageColor3 = "ImageTransparency",
		TextColor3 = "TextTransparency",
	}
	for colorProperty, transparencyProperty in pairs(mappings) do
		for _, object in ipairs(buckets[colorProperty] or {}) do
			local ok, current = pcall(function() return object[transparencyProperty] end)
			if ok and type(current) == "number" then
				local defaults = self._theme_alpha_defaults[object]
				if not defaults then
					defaults = {}
					self._theme_alpha_defaults[object] = defaults
				end
				if defaults[transparencyProperty] == nil then
					local styled = self._styled_gui[object]
					defaults[transparencyProperty] = transparencyProperty == "BackgroundTransparency" and styled and styled.defaultTransparency or current
				end
				local baseline = defaults[transparencyProperty]
				if self.ui_theme == "Frosted Glass" and transparencyProperty == "BackgroundTransparency" then
					baseline = math.max(baseline, 0.34)
				end
				pcall(function() object[transparencyProperty] = 1 - alpha * (1 - baseline) end)
			end
		end
	end
end

function library:register_window_theme_frames()
	library._theme_frames = {
		background = {},
		main       = {},
		outline    = {},
	}

	for _, frame in next, library.main_frame do

		table.insert(library._theme_frames.background, { instance = frame, property = "BackgroundColor3" })

		table.insert(library._theme_frames.outline, { instance = frame, property = "BorderColor3" })

		for _, child in next, frame:GetChildren() do

			if child:IsA("UIStroke") then
				table.insert(library._theme_frames.outline, { instance = child, property = "Color" })

			elseif child:IsA("Frame") and math.abs(child.Size.Y.Offset) > 2 then
				table.insert(library._theme_frames.main, { instance = child, property = "BackgroundColor3" })
				for _, grandchild in next, child:GetChildren() do
					if grandchild:IsA("Frame") then
						table.insert(library._theme_frames.main, { instance = grandchild, property = "BackgroundColor3" })
					end
				end
			end
		end
	end

	local main_color = themes.preset.inline
	if library.gui then
		local tracked = {}
		for _, entry in next, library._theme_frames.main do
			tracked[entry.instance] = true
		end
		for _, desc in next, library.gui:GetDescendants() do
			if desc:IsA("Frame") and desc.BackgroundColor3 == main_color and not tracked[desc] then
				table.insert(library._theme_frames.main, { instance = desc, property = "BackgroundColor3" })
				tracked[desc] = true
			end
		end
	end
end

function library:update_theme_frame(role, color)
	if not library._theme_frames or not library._theme_frames[role] then
		return
	end
	local entries = library._theme_frames[role]
	for _, entry in next, entries do
		local inst = entry.instance
		if inst and inst.Parent then
			inst[entry.property] = color
		end
	end
end

local function get_gui_depth(instance)
	local depth = 0
	local parent = instance and instance.Parent
	while parent and depth < 8 do
		if parent:IsA("GuiObject") then
			depth = depth + 1
		end
		parent = parent.Parent
	end
	return depth
end

local FROSTED_GLASS_COLORS = {
	Color3.fromRGB(34, 35, 44),
	Color3.fromRGB(30, 31, 39),
	Color3.fromRGB(27, 28, 35),
	Color3.fromRGB(24, 25, 32),
	Color3.fromRGB(21, 22, 28),
}

local FROSTED_TEXT_PRIMARY = Color3.fromRGB(232, 232, 242)
local FROSTED_TEXT_SECONDARY = Color3.fromRGB(198, 197, 211)
local FROSTED_TEXT_MUTED = Color3.fromRGB(168, 166, 182)

local function is_text_gui(instance)
	return instance:IsA("TextLabel") or instance:IsA("TextButton") or instance:IsA("TextBox")
end

local function frosted_text_color(instance, state)
	local base = state.defaultTextColor or instance.TextColor3
	local r, g, b = base.R, base.G, base.B
	local brightest = math.max(r, g, b)
	local darkest = math.min(r, g, b)
	-- Preserve meaningful accent/status colors; only neutral grays need the
	-- readability lift.
	if brightest - darkest > 0.18 then return base end
	local luminance = r * 0.2126 + g * 0.7152 + b * 0.0722
	if luminance < 0.42 then return FROSTED_TEXT_MUTED end
	if luminance < 0.78 then return FROSTED_TEXT_SECONDARY end
	return FROSTED_TEXT_PRIMARY
end

local function is_theme_ignored(instance)
	local current = instance
	while current do
		if current:GetAttribute("VNEOThemeIgnore") == true then return true end
		if current == library.gui then break end
		current = current.Parent
	end
	return false
end

-- Roblox only exposes BlurEffect for the rendered 3D scene, not for each
-- GuiObject.  Creating a BlurEffect per control is both ineffective and very
-- expensive.  Frosted depth is therefore built from the one shared scene
-- blur plus one lightweight depth stroke per real surface.  The stroke gives
-- nested panels, popups, buttons, and overlays a separate glass edge without
-- multiplying post-processing passes.
function library:_update_frost_depth(instance, state)
	if not instance or not state then return end
	local depthStroke = instance:FindFirstChild("VNEOFrostedDepth")
	local frosted = self.ui_theme == "Frosted Glass" and not is_theme_ignored(instance)
	local isSurface = instance:IsA("Frame") or instance:IsA("TextButton") or instance:IsA("TextBox") or instance:IsA("ImageButton")
	local hasThemeSurface = state.frostedTransparency ~= nil
		or state.themeRole == "inline"
		or state.themeRole == "contrast"
		or (state.defaultTransparency and state.defaultTransparency < 0.5 and instance:IsA("Frame"))
	if not frosted or not isSurface or not hasThemeSurface then
		if depthStroke and depthStroke:GetAttribute("VNEOCreated") == true then depthStroke:Destroy() end
		return
	end

	if not depthStroke then
		depthStroke = Instance.new("UIStroke")
		depthStroke.Name = "VNEOFrostedDepth"
		depthStroke:SetAttribute("VNEOCreated", true)
		depthStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		depthStroke.LineJoinMode = Enum.LineJoinMode.Round
		depthStroke.Thickness = 1
		depthStroke.Parent = instance
	end
	local depth = math.min(tonumber(state.themeDepth) or get_gui_depth(instance), 8)
	-- Outer surfaces get a clearer edge; nested surfaces recede progressively.
	depthStroke.Color = depth <= 2 and Color3.fromRGB(236, 235, 255) or Color3.fromRGB(178, 176, 205)
	depthStroke.Transparency = math.clamp(0.76 + depth * 0.025, 0.76, 0.94)
end

function library:_apply_ui_theme_object(instance, state)
	state = state or self._styled_gui[instance]
	if not state or not instance or not instance.Parent then return end
	if is_theme_ignored(instance) then
		if state.defaultColor then instance.BackgroundColor3 = state.defaultColor end
		instance.BackgroundTransparency = state.defaultTransparency
		if is_text_gui(instance) then
			if state.defaultTextColor then instance.TextColor3 = state.defaultTextColor end
			if state.defaultTextTransparency ~= nil then instance.TextTransparency = state.defaultTextTransparency end
			if state.defaultTextStrokeTransparency ~= nil then instance.TextStrokeTransparency = state.defaultTextStrokeTransparency end
		end
		return
	end

	local frosted = self.ui_theme == "Frosted Glass"
	-- An explicit FrostedTransparency is an intentional surface override.  Do
	-- not discard it just because the original object was created with a fully
	-- transparent background (this is common for nested popup/layout frames).
	-- Without this exception, those surfaces only became transparent when the
	-- theme happened to be applied before they were created.
	if frosted and (state.defaultTransparency < 1 or state.frostedTransparency ~= nil) then
		local depth = tonumber(state.themeDepth) or get_gui_depth(instance)
		-- The window has several structural surfaces stacked on top of each
		-- other. Keep wrappers highly translucent so their combined opacity does
		-- not make the final section/container look solid.
		local transparency = math.max(0.76, 0.92 - math.min(depth, 8) * 0.02)
		if state.themeRole == "accent" then
			instance.BackgroundColor3 = themes.preset.accent
			transparency = math.min(transparency, 0.34)
		else
			instance.BackgroundColor3 = FROSTED_GLASS_COLORS[math.min(depth + 1, #FROSTED_GLASS_COLORS)]
			if state.themeRole == "outline" then
				transparency = math.max(transparency, 0.88)
			elseif state.themeRole == "inline" then
				transparency = math.max(transparency, 0.82)
			elseif state.themeRole == "contrast" then
				transparency = 0.72
			end
		end
		if instance:IsA("TextButton") or instance:IsA("TextBox") or instance:IsA("ImageButton") then
			transparency = math.max(0.68, transparency - 0.07)
		end
		if state.frostedTransparency ~= nil then
			transparency = math.clamp(tonumber(state.frostedTransparency) or transparency, 0, 1)
		end
		instance.BackgroundTransparency = transparency
	else
		if state.defaultColor then
			instance.BackgroundColor3 = state.defaultColor
		end
		instance.BackgroundTransparency = state.defaultTransparency
	end

	if is_text_gui(instance) then
		if frosted then
			instance.TextColor3 = frosted_text_color(instance, state)
			instance.TextTransparency = math.min(state.defaultTextTransparency or 0, 0.04)
			instance.TextStrokeTransparency = math.min(state.defaultTextStrokeTransparency or 0.5, 0.28)
		else
			if state.defaultTextColor then instance.TextColor3 = state.defaultTextColor end
			if state.defaultTextTransparency ~= nil then instance.TextTransparency = state.defaultTextTransparency end
			if state.defaultTextStrokeTransparency ~= nil then instance.TextStrokeTransparency = state.defaultTextStrokeTransparency end
		end
	end

	local outline = instance:FindFirstChild("VNEOOutline") or instance:FindFirstChildOfClass("UIStroke")
	if outline and outline:IsA("UIStroke") then
		outline.Transparency = frosted and math.min(state.defaultStrokeTransparency or 0, 0.14) or state.defaultStrokeTransparency
	end
	self:_update_frost_depth(instance, state)
end

function library:_update_frost_blur()
	-- Frosted Glass must still blur the game when the decorative background is
	-- disabled.  The decorative background owns bg_blur; Frosted Glass uses a
	-- fallback effect only when there is no background effect to reuse.
	local wants_frost_blur = self.ui_theme == "Frosted Glass"
		and self.panel_open
		and self._suppress_ui ~= true
		and self._window_focused ~= false
		and not self.bg_blur
	if wants_frost_blur then
		if not self.frost_blur or not self.frost_blur.Parent then
			local blur = Instance.new("BlurEffect")
			blur.Name = "VNEOFrostedGlassBlur"
			blur.Parent = game:GetService("Lighting")
			self.frost_blur = blur
		end
		self.frost_blur.Enabled = true
		self.frost_blur.Size = math.max(tonumber(self.bg_blur_amount) or 16, 16)
	elseif self.frost_blur then
		local blur = self.frost_blur
		self.frost_blur = nil
		if blur.Parent then blur:Destroy() end
	end

	if self.bg_blur then
		self.bg_blur.Enabled = self._window_focused ~= false
		self.bg_blur.Size = (self.panel_open and self._suppress_ui ~= true and self._window_focused ~= false) and (self.bg_blur_amount or 0) or 0
	end
end

function library:set_window_focus(focused)
	self._window_focused = focused == true
	if not self._window_focused then
		-- Do not disable 3D rendering on focus loss. Only suspend effects owned by
		-- this UI so Roblox can resume the normal frame immediately on refocus.
		if self.bg_blur then
			self.bg_blur.Enabled = false
			self.bg_blur.Size = 0
		end
		if self.frost_blur then self.frost_blur.Enabled = false end
		if self.bg_canvas then self.bg_canvas.Visible = false end
		return
	end
	if self.bg_blur then self.bg_blur.Enabled = true end
	if self.frost_blur then self.frost_blur.Enabled = true end
	self:_update_frost_blur()
	if self.bg_canvas and self.panel_open and self._suppress_ui ~= true then
		self.bg_canvas.Visible = true
	end
end

function library:set_ui_theme(themeName)
	local normalized = tostring(themeName or "Default")
	if normalized ~= "Frosted Glass" then normalized = "Default" end
	self.ui_theme = normalized
	if normalized == "Frosted Glass" and (tonumber(self.bg_blur_amount) or 0) <= 0 then
		-- Frosted Glass is a surface style; do not silently enable a global
		-- post-processing effect when the user selected no background blur.
		self.bg_blur_amount = 0
		flags["bg_blur"] = 0
		local config = getgenv and getgenv().Config
		if config and config.UI then config.UI.BackgroundBlur = 0 end
	end
	if self.gui then
		for _, descendant in ipairs(self.gui:GetDescendants()) do
			if descendant:IsA("GuiObject") and not is_theme_ignored(descendant) and not self._styled_gui[descendant] then
				local outline = descendant:FindFirstChild("VNEOOutline") or descendant:FindFirstChildOfClass("UIStroke")
				self._styled_gui[descendant] = {
					defaultColor = descendant.BackgroundColor3,
					defaultTransparency = descendant.BackgroundTransparency,
					defaultStrokeTransparency = outline and outline.Transparency or 0,
					defaultTextColor = is_text_gui(descendant) and descendant.TextColor3 or nil,
					defaultTextTransparency = is_text_gui(descendant) and descendant.TextTransparency or nil,
					defaultTextStrokeTransparency = is_text_gui(descendant) and descendant.TextStrokeTransparency or nil,
				}
			end
		end
	end

	for instance, state in pairs(self._styled_gui) do
		if instance and instance.Parent then
			self:_apply_ui_theme_object(instance, state)
		else
			self._styled_gui[instance] = nil
		end
	end
	-- Reapply stateful selections after a theme pass so hidden options stay
	-- hidden instead of all looking selected.
	for _, entry in ipairs(self.nav_elements) do
		local element = entry and entry.cfg
		if element and element._refresh_theme then
			pcall(element._refresh_theme)
		end
	end
	self:_update_frost_blur()
end

function library:create(instance, options)
	local ins = Instance.new(instance)

	for prop, value in next, options do
		local isPseudoProperty = prop == "Square" or prop == "ThemeDepth" or prop == "ThemeIgnore" or prop == "FrostedTransparency" or (prop == "CornerRadius" and not ins:IsA("UICorner"))
		if not isPseudoProperty then
			ins[prop] = value
		end
	end
	if options.ThemeIgnore == true then
		ins:SetAttribute("VNEOThemeIgnore", true)
	end

	if options.Square ~= true and ins:IsA("GuiObject") then
		local size = options.Size
		local thin = typeof(size) == "UDim2" and (
			(size.X.Scale == 0 and size.X.Offset > 0 and size.X.Offset <= 2)
			or (size.Y.Scale == 0 and size.Y.Offset > 0 and size.Y.Offset <= 2)
		)

		if not thin then
			local configuredRadius = options.CornerRadius
			local radiusOffset
			if typeof(configuredRadius) == "UDim" then
				radiusOffset = configuredRadius.Offset
			elseif configuredRadius ~= nil then
				radiusOffset = tonumber(configuredRadius)
			end

			local backgroundTransparency = options.BackgroundTransparency
			if backgroundTransparency == nil then
				backgroundTransparency = ins.BackgroundTransparency
			end
			local hasVisibleSurface = backgroundTransparency < 1

			if configuredRadius == nil then
				if ins:IsA("TextButton") or ins:IsA("TextBox") or ins:IsA("ImageButton") then
					radiusOffset = 3
				elseif hasVisibleSurface then
					radiusOffset = 4
				end
			end

			if radiusOffset and radiusOffset > 0 then
				-- Small fields such as sliders should be pills, not over-rounded boxes.
				if typeof(size) == "UDim2" then
					local fixedWidth = size.X.Scale == 0 and size.X.Offset > 0 and size.X.Offset or nil
					local fixedHeight = size.Y.Scale == 0 and size.Y.Offset > 0 and size.Y.Offset or nil
					local fixedMinimum = fixedWidth and fixedHeight and math.min(fixedWidth, fixedHeight) or fixedHeight or fixedWidth
					if fixedMinimum then
						if fixedMinimum <= 12 then
							radiusOffset = math.min(radiusOffset, 2)
						else
							radiusOffset = math.min(radiusOffset, math.max(2, math.floor(fixedMinimum / 2)))
						end
					end
				end

				local corner = ins:FindFirstChildOfClass("UICorner") or Instance.new("UICorner")
				corner.Name = "VNEOCorner"
				corner.CornerRadius = typeof(configuredRadius) == "UDim" and configuredRadius or UDim.new(0, radiusOffset)
				corner.Parent = ins

				-- BorderSizePixel does not follow UICorner reliably. Replace visible
				-- legacy borders with a rounded stroke while retaining their color.
				local borderSize = ins.BorderSizePixel
				if borderSize > 0 and (hasVisibleSurface or options.BorderColor3 ~= nil) then
					local outline = ins:FindFirstChild("VNEOOutline") or Instance.new("UIStroke")
					outline.Name = "VNEOOutline"
					outline.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
					outline.LineJoinMode = Enum.LineJoinMode.Round
					outline.Thickness = borderSize
					outline.Color = ins.BorderColor3
					outline.Parent = ins
					ins.BorderSizePixel = 0
				end
			end
		end
	end

	if ins:IsA("GuiObject") then
		local outline = ins:FindFirstChild("VNEOOutline")
		local state = {
			defaultColor = ins.BackgroundColor3,
			defaultTransparency = ins.BackgroundTransparency,
			defaultStrokeTransparency = outline and outline:IsA("UIStroke") and outline.Transparency or 0,
			defaultTextColor = is_text_gui(ins) and ins.TextColor3 or nil,
			defaultTextTransparency = is_text_gui(ins) and ins.TextTransparency or nil,
			defaultTextStrokeTransparency = is_text_gui(ins) and ins.TextStrokeTransparency or nil,
			themeDepth = options.ThemeDepth,
			frostedTransparency = options.FrostedTransparency,
		}
		self._styled_gui[ins] = state
		self:_apply_ui_theme_object(ins, state)
	end

	if self._build_yield_enabled then
		self._build_yield_count = (self._build_yield_count or 0) + 1
		if self._build_yield_count >= (self._build_yield_every or 96) then
			self._build_yield_count = 0
			task.wait()
		end
	end

	return ins
end

function library:create_curve_box()
	local curve_box = library:create("Frame", {
		Parent = library.gui,
		Name = "CurveBox",
		Active = true,
		Draggable = false,
		AnchorPoint = Vector2.new(0, 0),
		Position = UDim2.new(0, 10, 0, 10),
		BorderColor3 = Color3.new(0.0314, 0.0314, 0.0314),
		Size = UDim2.new(0, 358, 0, 328),
		BackgroundColor3 = Color3.new(0.2196, 0.2196, 0.2196),
		ZIndex = 4,
	})

	library:make_draggable(curve_box)
	library:make_resizable(curve_box)
	table.insert(library.main_frame, curve_box)

	library.curve_box = curve_box

	local curve_accent = library:create("Frame", {
		Parent = curve_box,
		BorderColor3 = Color3.new(0.1333, 0.1333, 0.1333),
		Size = UDim2.new(1, 0, 0, 2),
		BorderSizePixel = 0,
		BackgroundColor3 = themes.preset.accent,
	})
	library:apply_theme(curve_accent, "accent", "BackgroundColor3")

	library:create("Frame", {
		Parent = curve_box,
		BackgroundTransparency = 0.5,
		Position = UDim2.new(0, 0, 0, 1),
		BorderColor3 = Color3.new(0.0000, 0.0000, 0.0000),
		Size = UDim2.new(1, 0, 0, 1),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.new(0.0000, 0.0000, 0.0000),
	})

	local curve_glow = library:create("ImageLabel", {
		Parent = curve_box,
		ImageColor3 = themes.preset.accent,
		ScaleType = Enum.ScaleType.Slice,
		ImageTransparency = 0.9,
		BorderColor3 = Color3.new(0.0000, 0.0000, 0.0000),
		BackgroundColor3 = Color3.new(1.0000, 1.0000, 1.0000),
		Image = "http://www.roblox.com/asset/?id=18245826428",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, -20, 0, -20),
		Size = UDim2.new(1, 40, 0, 42),
		ZIndex = 2,
		BorderSizePixel = 0,
		SliceCenter = Rect.new(Vector2.new(21, 21), Vector2.new(79, 79)),
	})
	library:apply_theme(curve_glow, "accent", "ImageColor3")

	local resetBtn = library:create("TextButton", {
		Parent = curve_box,
		Name = "ResetButton",
		Text = "Reset Curve",
		Size = UDim2.new(0, 100, 0, 30),
		Position = UDim2.new(0, 10, 1, -40),
		BackgroundColor3 = Color3.new(0.7843, 0.1961, 0.1961),
		TextColor3 = Color3.new(1.0000, 1.0000, 1.0000),
		ZIndex = 5,
		AutoButtonColor = true,
	})
	resetBtn.MouseButton1Click:Connect(function()

		if Config and Config.Combat then
			if Config.Combat.Aimbot then Config.Combat.Aimbot.CurvePoints = {} end
			if Config.Combat.SilentAim then Config.Combat.SilentAim.CurvePoints = {} end
		end
	end)

	return curve_box
end

local BG_THEMES = {}

local function on_click(callback)
	return uis.InputBegan:Connect(function(input, gp)
		if gp then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			local mp = uis:GetMouseLocation()
			callback(mp.X, mp.Y - gui_offset)
		end
	end)
end

local function make_handle(...)
	local conns = { ... }
	return {
		Disconnect = function()
			for _, c in ipairs(conns) do
				if c and c.Disconnect then c:Disconnect() end
			end
		end
	}
end

local function make_canvas(gui)
	local canvas = Instance.new("Frame")
	canvas.Name             = "bg_canvas"
	canvas.Size             = UDim2.new(1, 0, 1, gui_offset)
	canvas.Position         = UDim2.new(0, 0, 0, -gui_offset)
	canvas.BackgroundColor3 = rgb(0, 0, 0)
	canvas.BackgroundTransparency = 0.50
	canvas.BorderSizePixel  = 0
	canvas.ZIndex           = 1
	canvas.ClipsDescendants = false
	canvas.Parent           = gui
	return canvas
end

local function make_blur()
	local blur = Instance.new("BlurEffect")
	blur.Size   = 0
	blur.Parent = game:GetService("Lighting")
	return blur
end

function library:create_bg_effects()
	if library.bg_theme == "none" or not library.bg_theme then return end
	local theme = library.bg_theme
	if not BG_THEMES[theme] then return end

	library:destroy_bg_effects()

	library.bg_blur   = make_blur()
	library.bg_canvas = make_canvas(library.gui)

	for _, f in ipairs(library.main_frame) do
		f.ZIndex = 3
	end

	library.bg_theme_connection = BG_THEMES[theme](library.bg_canvas, library.gui)

	library.bg_blur.Size      = 0
	library.bg_canvas.Visible = false
end

function library:destroy_bg_effects()
	if library.bg_theme_connection then
		if type(library.bg_theme_connection) == "table" then
			library.bg_theme_connection:Disconnect()
		else
			library.bg_theme_connection:Disconnect()
		end
		library.bg_theme_connection = nil
	end
	if library.bg_blur then
		library.bg_blur:Destroy()
		library.bg_blur = nil
	end
	if library.bg_canvas then
		library.bg_canvas:Destroy()
		library.bg_canvas = nil
	end
end

BG_THEMES["stars"] = function(canvas, gui)
	local vp = camera.ViewportSize
	local h  = vp.Y + gui_offset

	local LAYERS = {
		{ count=50,  sz_min=1, sz_max=1, a_min=0.55, a_max=0.82, speed=0.3 },
		{ count=35,  sz_min=1, sz_max=2, a_min=0.35, a_max=0.65, speed=0.7 },
		{ count=15,  sz_min=2, sz_max=3, a_min=0.15, a_max=0.40, speed=1.2 },
	}
	local REPEL_R, REPEL_F  = 140, 240
	local RETURN_S          = 3.0
	local PARALLAX          = 0.006
	local AURA_R            = 90

	local STAR_COLS = {
		rgb(255,255,255), rgb(210,220,255), rgb(190,210,255),
		rgb(255,240,200), rgb(200,185,255), rgb(170,230,255),
	}

	local stars = {}

	local function new_star(layer_idx, layer)
		local sz  = math.random(layer.sz_min, layer.sz_max)
		local bx  = math.random(0, math.floor(vp.X))
		local by  = math.random(0, math.floor(h))
		local col = STAR_COLS[math.random(1,#STAR_COLS)]
		local base_a = math.random(math.floor(layer.a_min*100), math.floor(layer.a_max*100)) / 100

		local f = Instance.new("Frame")
		f.BorderSizePixel = 0
		f.BackgroundColor3 = col
		f.BackgroundTransparency = base_a
		f.Size = dim2(0,sz,0,sz)
		f.Position = dim2(0,bx,0,by)
		f.ZIndex = 2
		f.Parent = canvas

		local corner = Instance.new("UICorner")
		corner.CornerRadius = dim(0.5,0)
		corner.Parent = f

		local glow = Instance.new("UIStroke")
		glow.Color = col
		glow.Transparency = 0.92
		glow.Thickness = 2.5
		glow.ZIndex = 2
		glow.Parent = f

		table.insert(stars, {
			frame = f, glow = glow,
			base_x=bx, base_y=by, x=bx, y=by,
			vx=0, vy=0,
			drift_x = math.random(-8,8)/10,
			drift_y = math.random(-6,6)/10,
			twk_speed  = math.random(40,240)/100,
			twk_offset = math.random(0,628)/100,
			base_a = base_a, col = col, sz = sz,
			layer_speed = layer.speed,
		})
	end

	for li, layer in ipairs(LAYERS) do
		for i = 1, layer.count do new_star(li, layer) end
	end

	local SHOOT_MAX = 2
	local shoots = {}
	for i = 1, SHOOT_MAX do
		local sf = Instance.new("Frame")
		sf.BorderSizePixel=0; sf.BackgroundColor3=rgb(255,255,255)
		sf.BackgroundTransparency=1; sf.Size=dim2(0,60,0,1)
		sf.AnchorPoint=vec2(0,0.5); sf.ZIndex=3; sf.Visible=false
		sf.Parent=canvas
		table.insert(shoots, {frame=sf, active=false, x=0, y=0, angle=0, life=0, max_life=0, vx=0, vy=0})
	end

	local function spawn_shoot()
		for _, s in ipairs(shoots) do
			if not s.active then
				local ang = math.random(-25,-10) * math.pi/180
				local edge_x = math.random(0, math.floor(vp.X))
				s.active=true; s.x=edge_x; s.y=math.random(10,math.floor(h*0.45))
				s.vx=math.cos(ang)*380; s.vy=math.sin(ang)*380
				s.life=0; s.max_life=0.6+math.random(0,30)/100
				s.frame.Visible=true; s.frame.Rotation=math.deg(ang)
				s.frame.BackgroundTransparency=0.05
				break
			end
		end
	end

	local novas = {}

	local last_mx, last_my = mouse.X, mouse.Y
	local vel_x, vel_y = 0, 0
	local shoot_timer = math.random(30,60)/10
	local update_elapsed = 0

	local hb = run_service.Heartbeat:Connect(function(dt)
		if not canvas or not canvas.Visible then return end
		update_elapsed = update_elapsed + dt
		if update_elapsed < BG_UPDATE_INTERVAL then return end
		dt = update_elapsed
		update_elapsed = 0
		local now = clock()
		local mx, my = mouse.X, mouse.Y

		local rvx = (mx-last_mx)/(dt+0.001)
		local rvy = (my-last_my)/(dt+0.001)
		vel_x = vel_x*0.88 + rvx*0.12
		vel_y = vel_y*0.88 + rvy*0.12
		last_mx, last_my = mx, my
		local par_x = clamp(vel_x*PARALLAX,-4,4)
		local par_y = clamp(vel_y*PARALLAX,-4,4)

		shoot_timer = shoot_timer - dt
		if shoot_timer <= 0 then
			shoot_timer = math.random(35,80)/10
			spawn_shoot()
		end

		for _, s in ipairs(shoots) do
			if not s.active then continue end
			s.life = life + dt
			local t = s.life/s.max_life
			s.x = x + s.vx*dt; s.y = y + s.vy*dt
			s.frame.Position = dim2(0,s.x,0,s.y)
			s.frame.BackgroundTransparency = clamp(t*t,0.02,0.98)
			if t>=1 then s.active=false; s.frame.Visible=false end
		end

		for i=#novas,1,-1 do
			local nv = novas[i]
			nv.r = r + 280*dt
			nv.life = life + dt
			if nv.life > 0.7 then table.remove(novas,i) end
		end

		for _, s in ipairs(stars) do
			if not s.frame or not s.frame.Parent then continue end

			s.base_x = base_x + s.drift_x*dt*s.layer_speed
			s.base_y = base_y + s.drift_y*dt*s.layer_speed
			if s.base_x>vp.X+4 then s.base_x=-4 end
			if s.base_x<-4    then s.base_x=vp.X+4 end
			if s.base_y>h+4   then s.base_y=-4 end
			if s.base_y<-4    then s.base_y=h+4 end

			s.vx = vx + par_x*dt*60*s.layer_speed
			s.vy = vy + par_y*dt*60*s.layer_speed

			local dx, dy = s.x-mx, s.y-my
			local dist = math.sqrt(dx*dx+dy*dy)
			if dist < REPEL_R and dist > 1 then
				local force = (1-dist/REPEL_R)*REPEL_F
				s.vx += (dx/dist)*force*dt
				s.vy += (dy/dist)*force*dt
			end

			for _, nv in ipairs(novas) do
				local nx, ny = s.x-nv.cx, s.y-nv.cy
				local nd = math.sqrt(nx*nx+ny*ny)
				if nd > nv.r-18 and nd < nv.r+18 and nd>1 then
					local push = (1-abs(nd-nv.r)/18)*420*(1-nv.life/0.7)
					s.vx += (nx/nd)*push*dt
					s.vy += (ny/nd)*push*dt
				end
			end

			s.vx = s.vx*0.93; s.vy = s.vy*0.93
			s.x = x + s.vx*dt + (s.base_x-s.x)*RETURN_S*dt
			s.y = y + s.vy*dt + (s.base_y-s.y)*RETURN_S*dt

			local aura = clamp(1-dist/AURA_R,0,1)
			local twk = sin_wave(now*s.twk_speed+s.twk_offset)*0.18
			local alpha = clamp(s.base_a+twk-aura*0.30,0.01,0.97)
			s.frame.BackgroundTransparency = alpha
			if s.glow then s.glow.Transparency = clamp(0.92-aura*0.45,0.4,0.97) end
			s.frame.Position = dim2(0,s.x,0,s.y)
		end
	end)

	local click_conn = on_click(function(cx,cy)
		table.insert(novas, {cx=cx,cy=cy,r=0,life=0})
	end)

	return make_handle(hb, click_conn)
end

BG_THEMES["aurora"] = function(canvas, gui)
	local vp = camera.ViewportSize
	local h  = vp.Y + gui_offset

	canvas.BackgroundColor3       = rgb(3, 4, 14)
	canvas.BackgroundTransparency = 0.02

	local SEGMENTS = 100
	local SEG_W    = math.ceil((vp.X + 80) / SEGMENTS)

	local CURTAIN_COUNT = 10
	local curtains = {}
	local curtain_hues = {0.33, 0.38, 0.28, 0.42, 0.35, 0.30, 0.45, 0.25, 0.40, 0.32}
	for ci = 1, CURTAIN_COUNT do
		local hue = curtain_hues[ci]
		local base_y = math.floor(h * (0.03 + (ci - 1) * 0.09))
		local amp = 40 + math.random(0, 60)
		local freq = 0.5 + math.random(0, 12) / 10
		local speed = 0.05 + math.random(0, 14) / 100
		local thickness = 80 + math.random(0, 100)

		local core_segs = {}
		local glow_segs = {}
		local outer_segs = {}

		for s = 1, SEGMENTS do
			local core = Instance.new("Frame")
			core.BorderSizePixel = 0
			core.BackgroundColor3 = Color3.fromHSV(hue, 0.55, 0.75)
			core.BackgroundTransparency = 0.45
			core.Size = dim2(0, SEG_W + 2, 0, thickness * 0.25)
			core.ZIndex = 3
			core.Parent = canvas
			table.insert(core_segs, core)

			local glow = Instance.new("Frame")
			glow.BorderSizePixel = 0
			glow.BackgroundColor3 = Color3.fromHSV(hue, 0.45, 0.55)
			glow.BackgroundTransparency = 0.60
			glow.Size = dim2(0, SEG_W + 2, 0, thickness)
			glow.ZIndex = 2
			glow.Parent = canvas
			table.insert(glow_segs, glow)

			local outer = Instance.new("Frame")
			outer.BorderSizePixel = 0
			outer.BackgroundColor3 = Color3.fromHSV(hue, 0.30, 0.30)
			outer.BackgroundTransparency = 0.82
			outer.Size = dim2(0, SEG_W + 2, 0, thickness * 2.5)
			outer.ZIndex = 1
			outer.Parent = canvas
			table.insert(outer_segs, outer)
		end

		table.insert(curtains, {
			core_segs = core_segs, glow_segs = glow_segs, outer_segs = outer_segs,
			hue = hue, base_y = base_y, amp = amp, freq = freq,
			speed = speed, thickness = thickness,
			phase = math.random(0, 628) / 100, hue_shift = 0,
		})
	end

	local STAR_COUNT = 100
	local stars = {}
	for i = 1, STAR_COUNT do
		local sz = math.random(1, 2)
		local brightness = math.random(180, 255)
		local f = Instance.new("Frame")
		f.BorderSizePixel = 0
		f.BackgroundColor3 = rgb(brightness, brightness, math.min(255, brightness + math.random(10, 40)))
		f.BackgroundTransparency = math.random(30, 70) / 100
		f.Size = dim2(0, sz, 0, sz)
		f.Position = dim2(0, math.random(0, math.floor(vp.X)), math.random(0, math.floor(h)))
		f.ZIndex = 2
		f.Parent = canvas
		local c = Instance.new("UICorner")
		c.CornerRadius = dim(0.5, 0)
		c.Parent = f
		local glow = nil
		if sz >= 2 then
			glow = Instance.new("Frame")
			glow.BorderSizePixel = 0
			glow.BackgroundColor3 = rgb(brightness, brightness, math.min(255, brightness + 20))
			glow.BackgroundTransparency = 0.92
			glow.Size = dim2(0, 6, 0, 6)
			glow.AnchorPoint = vec2(0.5, 0.5)
			glow.Position = dim2(0.5, 0, 0.5, 0)
			glow.ZIndex = 1
			glow.Parent = f
			local gc = Instance.new("UICorner")
			gc.CornerRadius = dim(0.5, 0)
			gc.Parent = glow
		end
		table.insert(stars, {
			frame = f, glow = glow,
			twk_speed = math.random(25, 130) / 100,
			twk_offset = math.random(0, 628) / 100,
			base_a = f.BackgroundTransparency,
		})
	end

	local SHOOT_COUNT = 2
	local shoots = {}
	for i = 1, SHOOT_COUNT do
		local sf = Instance.new("Frame")
		sf.BorderSizePixel = 0
		sf.BackgroundColor3 = rgb(220, 240, 255)
		sf.BackgroundTransparency = 1
		sf.Size = dim2(0, 45, 0, 1)
		sf.AnchorPoint = vec2(0, 0.5)
		sf.ZIndex = 4
		sf.Visible = false
		sf.Parent = canvas
		table.insert(shoots, {frame = sf, active = false, x = 0, y = 0, vx = 0, vy = 0, life = 0, max_life = 0})
	end

	local shoot_timer = math.random(50, 100) / 10
	local update_elapsed = 0

	local hb = run_service.Heartbeat:Connect(function(dt)
		if not canvas or not canvas.Visible then return end
		update_elapsed = update_elapsed + dt
		if update_elapsed < BG_UPDATE_INTERVAL then return end
		dt = update_elapsed
		update_elapsed = 0
		local now = clock()

		shoot_timer = shoot_timer - dt
		if shoot_timer <= 0 then
			shoot_timer = math.random(60, 130) / 10
			for _, s in ipairs(shoots) do
				if not s.active then
					local ang = math.random(-25, -10) * math.pi / 180
					s.active = true
					s.x = math.random(0, math.floor(vp.X))
					s.y = math.random(10, math.floor(h * 0.3))
					s.vx = math.cos(ang) * 320
					s.vy = math.sin(ang) * 320
					s.life = 0
					s.max_life = 0.45 + math.random(0, 25) / 100
					s.frame.Visible = true
					s.frame.Rotation = math.deg(ang)
					s.frame.BackgroundTransparency = 0.03
					break
				end
			end
		end

		for _, s in ipairs(shoots) do
			if not s.active then continue end
			s.life = life + dt
			local t = s.life / s.max_life
			s.x = x + s.vx * dt
			s.y = y + s.vy * dt
			s.frame.Position = dim2(0, s.x, 0, s.y)
			s.frame.BackgroundTransparency = clamp(t * t, 0.02, 0.98)
			if t >= 1 then s.active = false; s.frame.Visible = false end
		end

		for _, cur in ipairs(curtains) do
			cur.phase = phase + cur.speed * dt
			cur.hue_shift = (cur.hue_shift + 0.002 * dt) % 1
			local current_hue = (cur.hue + cur.hue_shift) % 1
			local core_color = Color3.fromHSV(current_hue, 0.55, 0.75)
			local glow_color = Color3.fromHSV(current_hue, 0.45, 0.55)
			local outer_color = Color3.fromHSV(current_hue, 0.30, 0.30)

			for si = 1, SEGMENTS do
				local core = cur.core_segs[si]
				local glow = cur.glow_segs[si]
				local outer = cur.outer_segs[si]
				if not core or not core.Parent then continue end

				local x = (si - 1) * SEG_W
				local norm_x = x / vp.X

				local wave1 = sin_wave(norm_x * cur.freq * math.pi * 2 + cur.phase) * cur.amp
				local wave2 = sin_wave(norm_x * cur.freq * 1.8 * math.pi * 2 + cur.phase * 0.55 + 1.2) * cur.amp * 0.30
				local wave3 = sin_wave(norm_x * cur.freq * 3.2 * math.pi * 2 + cur.phase * 1.4 + 2.8) * cur.amp * 0.12
				local y = cur.base_y + wave1 + wave2 + wave3

				local shimmer = sin_wave(now * 0.5 + si * 0.1) * 0.06

				core.Position = dim2(0, x, 0, y)
				core.BackgroundColor3 = core_color
				core.BackgroundTransparency = clamp(0.40 + shimmer, 0.28, 0.65)
				core.Size = dim2(0, SEG_W + 2, 0, cur.thickness * 0.25 + sin_wave(now * 0.35 + si * 0.12) * 5)

				glow.Position = dim2(0, x, 0, y - cur.thickness * 0.3)
				glow.BackgroundColor3 = glow_color
				glow.BackgroundTransparency = clamp(0.55 + shimmer * 1.2, 0.42, 0.75)
				glow.Size = dim2(0, SEG_W + 2, 0, cur.thickness + sin_wave(now * 0.28 + si * 0.09) * 8)

				outer.Position = dim2(0, x, 0, y - cur.thickness * 0.7)
				outer.BackgroundColor3 = outer_color
				outer.BackgroundTransparency = clamp(0.78 + shimmer * 0.8, 0.68, 0.92)
				outer.Size = dim2(0, SEG_W + 2, 0, cur.thickness * 2.5 + sin_wave(now * 0.2 + si * 0.07) * 12)
			end
		end

		for _, s in ipairs(stars) do
			if not s.frame or not s.frame.Parent then continue end
			local twk = sin_wave(now * s.twk_speed + s.twk_offset) * 0.20
			s.frame.BackgroundTransparency = clamp(s.base_a + twk, 0.10, 0.90)
		end
	end)

	return make_handle(hb)
end

BG_THEMES["snow"] = function(canvas, gui)
	local vp = camera.ViewportSize
	local h  = vp.Y + gui_offset
	local LAYERS = {
		{count=60, sz_min=1,sz_max=1, a_min=0.55,a_max=0.78, spd_min=18,spd_max=50,  layer=0.3},
		{count=35, sz_min=1,sz_max=2, a_min=0.35,a_max=0.60, spd_min=40,spd_max=80,  layer=0.65},
		{count=15, sz_min=2,sz_max=4, a_min=0.15,a_max=0.40, spd_min=65,spd_max=130, layer=1.0},
	}
	local MELT_R = 55

	local flakes = {}
	local gusts  = {}

	local function new_flake(layer_cfg, start_y)
		local sz  = math.random(layer_cfg.sz_min, layer_cfg.sz_max)
		local cx  = math.random(0,math.floor(vp.X))
		local y   = start_y or math.random(-10,math.floor(h))
		local f   = Instance.new("Frame")
		f.BorderSizePixel=0; f.BackgroundColor3=rgb(220,235,255)
		f.BackgroundTransparency=math.random(math.floor(layer_cfg.a_min*100),math.floor(layer_cfg.a_max*100))/100
		f.Size=dim2(0,sz,0,sz); f.Position=dim2(0,cx,0,y); f.ZIndex=2; f.Parent=canvas
		local c=Instance.new("UICorner"); c.CornerRadius=dim(0.5,0); c.Parent=f
		table.insert(flakes,{
			frame=f, x=cx, y=y, sz=sz,
			speed=math.random(layer_cfg.spd_min,layer_cfg.spd_max),
			drift=math.random(-20,20)/10,
			layer=layer_cfg.layer,
			sparkle_t=math.random(0,200)+50,
			base_a=math.random(math.floor(layer_cfg.a_min*100),math.floor(layer_cfg.a_max*100))/100,
		})
	end

	for _,lc in ipairs(LAYERS) do
		for i=1,lc.count do new_flake(lc,nil) end
	end

	local function respawn_flake(flk)
		local layer_cfg = LAYERS[math.random(1,#LAYERS)]
		flk.sz    = math.random(layer_cfg.sz_min, layer_cfg.sz_max)
		flk.speed = math.random(layer_cfg.spd_min, layer_cfg.spd_max)
		flk.drift = math.random(-20,20)/10
		flk.layer = layer_cfg.layer
		flk.base_a = math.random(math.floor(layer_cfg.a_min*100),math.floor(layer_cfg.a_max*100))/100
		flk.x     = math.random(0,math.floor(vp.X))
		flk.y     = -flk.sz-2
		flk.frame.BackgroundTransparency = flk.base_a
		flk.frame.Size = dim2(0,flk.sz,0,flk.sz)
	end

	local last_mx = mouse.X
	local wind_vel = 0
	local update_elapsed = 0

	local hb = run_service.Heartbeat:Connect(function(dt)
		if not canvas or not canvas.Visible then return end
		update_elapsed = update_elapsed + dt
		if update_elapsed < BG_UPDATE_INTERVAL then return end
		dt = update_elapsed
		update_elapsed = 0
		local now = clock()
		local mx = mouse.X
		wind_vel = wind_vel*0.92 + ((mx-last_mx)/dt)*0.08*0.012
		wind_vel = clamp(wind_vel,-10,10)
		last_mx  = mx
		local my = mouse.Y

		for i=#gusts,1,-1 do
			gusts[i].life = life + dt
			if gusts[i].life>1.0 then table.remove(gusts,i) end
		end

		for i=#flakes,1,-1 do
			local fk=flakes[i]
			if not fk.frame or not fk.frame.Parent then
				table.remove(flakes,i); continue
			end

			local gust_vy=0
			for _,g in ipairs(gusts) do
				local gdx=fk.x-g.cx; local gdy=fk.y-g.cy
				local gd=math.sqrt(gdx*gdx+gdy*gdy)
				if gd<120 then
					local power=(1-gd/120)*(1-g.life/1.0)*200
					gust_vy = gust_vy - power*dt
				end
			end

			local cdx=fk.x-mx; local cdy=fk.y-my
			local cd=math.sqrt(cdx*cdx+cdy*cdy)
			local melt_drift=0
			if cd<MELT_R and cd>1 then
				melt_drift = (cdx/cd)*(1-cd/MELT_R)*30
			end

			fk.y += (fk.speed*fk.layer + gust_vy) * dt
			fk.x += (fk.drift*fk.layer + wind_vel*fk.layer + melt_drift) * dt

			fk.sparkle_t = sparkle_t - 1
			local alpha = fk.base_a
			if fk.sparkle_t <= 0 then
				fk.sparkle_t = math.random(180,400)
				alpha = 0.02
			end
			fk.frame.BackgroundTransparency = alpha
			fk.frame.Position = dim2(0,fk.x,0,fk.y)

			if fk.y > h+10 then respawn_flake(fk) end
		end
	end)

	local click_conn = on_click(function(cx,cy)
		table.insert(gusts,{cx=cx,cy=cy,life=0})
	end)

	return make_handle(hb, click_conn)
end

BG_THEMES["cyber_city"] = function(canvas, gui)
	local vp = camera.ViewportSize
	local h  = vp.Y + gui_offset

	canvas.BackgroundColor3       = rgb(5, 7, 16)
	canvas.BackgroundTransparency = 0.02

	local horizon = Instance.new("Frame")
	horizon.BorderSizePixel = 0
	horizon.BackgroundColor3 = rgb(18, 12, 35)
	horizon.BackgroundTransparency = 0.75
	horizon.Size = dim2(1, 0, 0, h * 0.45)
	horizon.Position = dim2(0, 0, 0, 0)
	horizon.ZIndex = 1
	horizon.Parent = canvas

	local ground = Instance.new("Frame")
	ground.BorderSizePixel = 0
	ground.BackgroundColor3 = rgb(10, 8, 18)
	ground.BackgroundTransparency = 0.50
	ground.Size = dim2(1, 0, 0, h * 0.12)
	ground.Position = dim2(0, 0, 1, -h * 0.12)
	ground.ZIndex = 1
	ground.Parent = canvas

	local GROUND_Y = h * 0.88

	local FAR_COUNT = 50
	local far_buildings = {}
	local far_x = -20
	for i = 1, FAR_COUNT do
		local bw = math.random(20, 55)
		local bh = math.random(50, 180)
		local bx = far_x
		far_x = bx + bw
		if far_x > vp.X + 60 then break end
		local by = math.floor(GROUND_Y - bh)

		local f = Instance.new("Frame")
		f.BorderSizePixel = 0
		f.BackgroundColor3 = rgb(8, 10, 20)
		f.BackgroundTransparency = 0.30
		f.Size = dim2(0, bw, 0, bh)
		f.Position = dim2(0, bx, 0, by)
		f.ZIndex = 2
		f.Parent = canvas

		local windows = {}
		local win_cols = math.floor(bw / 8)
		local win_rows = math.floor(bh / 10)
		for wy = 1, win_rows do
			for wx = 1, win_cols do
				if math.random(1, 100) <= 35 then
					local neon_cols = {
						rgb(50, 140, 255), rgb(255, 50, 140), rgb(50, 255, 140),
						rgb(255, 160, 50), rgb(140, 50, 255), rgb(255, 255, 100),
					}
					local w = Instance.new("Frame")
					w.BorderSizePixel = 0
					w.BackgroundColor3 = neon_cols[math.random(1, #neon_cols)]
					w.BackgroundTransparency = math.random(40, 75) / 100
					w.Size = dim2(0, math.random(2, 5), 0, math.random(2, 5))
					w.Position = dim2(0, 2 + (wx - 1) * 7, 0, 3 + (wy - 1) * 8)
					w.ZIndex = 3
					w.Parent = f
					table.insert(windows, {
						frame = w, base_a = w.BackgroundTransparency,
						flicker_spd = math.random(5, 40) / 10,
						flicker_off = math.random(0, 628) / 100,
					})
				end
			end
		end
		table.insert(far_buildings, {frame = f, windows = windows})
	end

	local MID_COUNT = 35
	local mid_buildings = {}
	local mid_x = -15
	for i = 1, MID_COUNT do
		local bw = math.random(30, 85)
		local bh = math.random(80, 280)
		local bx = mid_x
		mid_x = bx + bw
		if mid_x > vp.X + 50 then break end
		local by = math.floor(GROUND_Y - bh)

		local f = Instance.new("Frame")
		f.BorderSizePixel = 0
		f.BackgroundColor3 = rgb(12, 14, 26)
		f.BackgroundTransparency = 0.15
		f.Size = dim2(0, bw, 0, bh)
		f.Position = dim2(0, bx, 0, by)
		f.ZIndex = 3
		f.Parent = canvas

		local edge = Instance.new("Frame")
		edge.BorderSizePixel = 0
		edge.BackgroundColor3 = rgb(35, 45, 70)
		edge.BackgroundTransparency = 0.72
		edge.Size = dim2(0, 1, 1, 0)
		edge.Position = dim2(1, -1, 0, 0)
		edge.ZIndex = 4
		edge.Parent = f

		local top_edge = Instance.new("Frame")
		top_edge.BorderSizePixel = 0
		top_edge.BackgroundColor3 = rgb(35, 45, 70)
		top_edge.BackgroundTransparency = 0.75
		top_edge.Size = dim2(1, 0, 0, 1)
		top_edge.Position = dim2(0, 0, 0, 0)
		top_edge.ZIndex = 4
		top_edge.Parent = f

		local windows = {}
		local win_cols = math.floor(bw / 11)
		local win_rows = math.floor(bh / 13)
		for wy = 1, win_rows do
			for wx = 1, win_cols do
				if math.random(1, 100) <= 50 then
					local neon_cols = {
						rgb(70, 170, 255), rgb(255, 70, 170), rgb(70, 255, 170),
						rgb(255, 190, 70), rgb(170, 70, 255), rgb(255, 130, 50),
						rgb(200, 200, 255), rgb(255, 255, 180),
					}
					local w = Instance.new("Frame")
					w.BorderSizePixel = 0
					w.BackgroundColor3 = neon_cols[math.random(1, #neon_cols)]
					w.BackgroundTransparency = math.random(25, 55) / 100
					w.Size = dim2(0, math.random(4, 8), 0, math.random(4, 8))
					w.Position = dim2(0, 3 + (wx - 1) * 10, 0, 4 + (wy - 1) * 11)
					w.ZIndex = 4
					w.Parent = f
					table.insert(windows, {
						frame = w, base_a = w.BackgroundTransparency,
						flicker_spd = math.random(5, 40) / 10,
						flicker_off = math.random(0, 628) / 100,
					})
				end
			end
		end

		local antenna = nil
		local ant_light = nil
		if math.random(1, 100) <= 45 then
			antenna = Instance.new("Frame")
			antenna.BorderSizePixel = 0
			antenna.BackgroundColor3 = rgb(25, 30, 50)
			antenna.BackgroundTransparency = 0.40
			antenna.Size = dim2(0, 1, 0, math.random(10, 25))
			antenna.Position = dim2(0, math.floor(bw / 2), 0, -antenna.Size.Y.Offset)
			antenna.ZIndex = 4
			antenna.Parent = f

			ant_light = Instance.new("Frame")
			ant_light.BorderSizePixel = 0
			ant_light.BackgroundColor3 = rgb(255, 40, 40)
			ant_light.BackgroundTransparency = 0.25
			ant_light.Size = dim2(0, 2, 0, 2)
			ant_light.Position = dim2(0, math.floor(bw / 2) - 1, 0, -antenna.Size.Y.Offset - 3)
			ant_light.ZIndex = 5
			ant_light.Parent = f
		end

		table.insert(mid_buildings, {
			frame = f, windows = windows,
			antenna = antenna, ant_light = ant_light,
			blink_spd = math.random(8, 25) / 10, blink_off = math.random(0, 628) / 100,
		})
	end

	local NEAR_COUNT = 20
	local near_buildings = {}
	local near_x = -10
	for i = 1, NEAR_COUNT do
		local bw = math.random(50, 130)
		local bh = math.random(120, 350)
		local bx = near_x
		near_x = bx + bw
		if near_x > vp.X + 40 then break end
		local by = math.floor(GROUND_Y - bh)

		local f = Instance.new("Frame")
		f.BorderSizePixel = 0
		f.BackgroundColor3 = rgb(16, 18, 32)
		f.BackgroundTransparency = 0.08
		f.Size = dim2(0, bw, 0, bh)
		f.Position = dim2(0, bx, 0, by)
		f.ZIndex = 4
		f.Parent = canvas

		local windows = {}
		local win_cols = math.floor(bw / 13)
		local win_rows = math.floor(bh / 15)
		for wy = 1, win_rows do
			for wx = 1, win_cols do
				if math.random(1, 100) <= 60 then
					local neon_cols = {
						rgb(80, 180, 255), rgb(255, 80, 180), rgb(80, 255, 180),
						rgb(255, 200, 80), rgb(180, 80, 255), rgb(255, 140, 60),
						rgb(220, 220, 255), rgb(255, 255, 200),
					}
					local w = Instance.new("Frame")
					w.BorderSizePixel = 0
					w.BackgroundColor3 = neon_cols[math.random(1, #neon_cols)]
					w.BackgroundTransparency = math.random(20, 50) / 100
					w.Size = dim2(0, math.random(5, 10), 0, math.random(5, 10))
					w.Position = dim2(0, 4 + (wx - 1) * 12, 0, 5 + (wy - 1) * 13)
					w.ZIndex = 5
					w.Parent = f
					table.insert(windows, {
						frame = w, base_a = w.BackgroundTransparency,
						flicker_spd = math.random(5, 35) / 10,
						flicker_off = math.random(0, 628) / 100,
					})
				end
			end
		end

		local sign = nil
		local sign_glow = nil
		if math.random(1, 100) <= 55 then
			local sign_cols = {rgb(255, 40, 100), rgb(40, 200, 255), rgb(255, 100, 40), rgb(100, 255, 100), rgb(255, 40, 255)}
			local sc = sign_cols[math.random(1, #sign_cols)]
			local sw = math.random(20, 50)
			local sh = math.random(4, 10)
			sign = Instance.new("Frame")
			sign.BorderSizePixel = 0
			sign.BackgroundColor3 = sc
			sign.BackgroundTransparency = 0.40
			sign.Size = dim2(0, sw, 0, sh)
			sign.Position = dim2(0, math.floor((bw - sw) / 2), 0, math.floor(bh * math.random(20, 50) / 100))
			sign.ZIndex = 6
			sign.Parent = f

			sign_glow = Instance.new("Frame")
			sign_glow.BorderSizePixel = 0
			sign_glow.BackgroundColor3 = sc
			sign_glow.BackgroundTransparency = 0.88
			sign_glow.Size = dim2(0, sw + 14, 0, sh + 14)
			sign_glow.AnchorPoint = vec2(0.5, 0.5)
			sign_glow.Position = dim2(0.5, 0, 0.5, 0)
			sign_glow.ZIndex = 5
			sign_glow.Parent = sign
		end

		table.insert(near_buildings, {
			frame = f, windows = windows,
			sign = sign, sign_glow = sign_glow,
			sign_pulse = math.random(8, 20) / 10, sign_off = math.random(0, 628) / 100,
		})
	end

	local FOG_LAYERS = 6
	local fog_y_positions = {0.25, 0.40, 0.55, 0.65, 0.75, 0.85}
	local fogs = {}
	for i = 1, FOG_LAYERS do
		local f = Instance.new("Frame")
		f.BorderSizePixel = 0
		f.BackgroundColor3 = rgb(15, 18, 35)
		f.BackgroundTransparency = math.random(82, 92) / 100
		f.Size = dim2(0, math.random(400, 800), 0, math.random(60, 140))
		f.Position = dim2(0, math.random(-200, math.floor(vp.X)), math.floor(h * fog_y_positions[i]))
		f.ZIndex = 2
		f.Parent = canvas
		table.insert(fogs, {
			frame = f, x = f.Position.X.Offset, y = f.Position.Y.Offset,
			drift = math.random(3, 10) / 10,
			base_a = f.BackgroundTransparency,
		})
	end

	local RAIN_COUNT = 40
	local rain = {}
	for i = 1, RAIN_COUNT do
		local f = Instance.new("Frame")
		f.BorderSizePixel = 0
		f.BackgroundColor3 = rgb(140, 170, 220)
		f.BackgroundTransparency = math.random(72, 88) / 100
		f.Size = dim2(0, 1, 0, math.random(10, 22))
		f.ZIndex = 2
		f.Parent = canvas
		local rx = math.random(0, math.floor(vp.X))
		local ry = math.random(0, math.floor(h))
		f.Position = dim2(0, rx, 0, ry)
		table.insert(rain, {
			frame = f, x = rx, y = ry,
			speed = math.random(280, 500),
			drift = math.random(-12, -4) / 10,
		})
	end

	local STARS_COUNT = 25
	local city_stars = {}
	for i = 1, STARS_COUNT do
		local sz = math.random(1, 2)
		local f = Instance.new("Frame")
		f.BorderSizePixel = 0
		f.BackgroundColor3 = rgb(200, 210, 240)
		f.BackgroundTransparency = math.random(55, 80) / 100
		f.Size = dim2(0, sz, 0, sz)
		f.Position = dim2(0, math.random(0, math.floor(vp.X)), math.random(0, math.floor(h * 0.3)))
		f.ZIndex = 2
		f.Parent = canvas
		local c = Instance.new("UICorner")
		c.CornerRadius = dim(0.5, 0)
		c.Parent = f
		table.insert(city_stars, {
			frame = f,
			twk_speed = math.random(30, 120) / 100,
			twk_off = math.random(0, 628) / 100,
			base_a = f.BackgroundTransparency,
		})
	end

	local update_elapsed = 0
	local hb = run_service.Heartbeat:Connect(function(dt)
		if not canvas or not canvas.Visible then return end
		update_elapsed = update_elapsed + dt
		if update_elapsed < BG_UPDATE_INTERVAL then return end
		dt = update_elapsed
		update_elapsed = 0
		local now = clock()

		for _, bld in ipairs(far_buildings) do
			for _, win in ipairs(bld.windows) do
				if not win.frame or not win.frame.Parent then continue end
				local flicker = sin_wave(now * win.flicker_spd + win.flicker_off)
				win.frame.BackgroundTransparency = clamp(win.base_a + flicker * 0.12, 0.20, 0.85)
			end
		end

		for _, bld in ipairs(mid_buildings) do
			for _, win in ipairs(bld.windows) do
				if not win.frame or not win.frame.Parent then continue end
				local flicker = sin_wave(now * win.flicker_spd + win.flicker_off)
				win.frame.BackgroundTransparency = clamp(win.base_a + flicker * 0.14, 0.15, 0.80)
			end
			if bld.ant_light and bld.ant_light.Parent then
				local blink = sin_wave(now * bld.blink_spd + bld.blink_off)
				bld.ant_light.BackgroundTransparency = blink > 0.3 and 0.20 or 0.85
			end
		end

		for _, bld in ipairs(near_buildings) do
			for _, win in ipairs(bld.windows) do
				if not win.frame or not win.frame.Parent then continue end
				local flicker = sin_wave(now * win.flicker_spd + win.flicker_off)
				win.frame.BackgroundTransparency = clamp(win.base_a + flicker * 0.15, 0.12, 0.75)
			end
			if bld.sign and bld.sign.Parent then
				local pulse = sin_wave(now * bld.sign_pulse + bld.sign_off)
				bld.sign.BackgroundTransparency = clamp(0.40 + pulse * 0.10, 0.25, 0.65)
				if bld.sign_glow then
					bld.sign_glow.BackgroundTransparency = clamp(0.88 + pulse * 0.05, 0.80, 0.95)
				end
			end
		end

		for _, fg in ipairs(fogs) do
			if not fg.frame or not fg.frame.Parent then continue end
			fg.x = fg.x + fg.drift * dt
			if fg.x > vp.X + 200 then fg.x = -fg.frame.Size.X.Offset - 100 end
			fg.frame.Position = dim2(0, fg.x, 0, fg.y)
			fg.frame.BackgroundTransparency = fg.base_a + sin_wave(now * 0.10 + fg.y * 0.006) * 0.025
		end

		for _, r in ipairs(rain) do
			if not r.frame or not r.frame.Parent then continue end
			r.y = r.y + r.speed * dt
			r.x = r.x + r.drift * dt
			if r.y > h + 25 then r.y = -25; r.x = math.random(0, math.floor(vp.X)) end
			r.frame.Position = dim2(0, r.x, 0, r.y)
		end

		for _, s in ipairs(city_stars) do
			if not s.frame or not s.frame.Parent then continue end
			local twk = sin_wave(now * s.twk_speed + s.twk_off) * 0.18
			s.frame.BackgroundTransparency = clamp(s.base_a + twk, 0.20, 0.90)
		end
	end)

	return make_handle(hb)
end

BG_THEMES["deep_ocean"] = function(canvas, gui)
	local vp = camera.ViewportSize
	local h  = vp.Y + gui_offset

	canvas.BackgroundColor3       = rgb(3, 8, 18)
	canvas.BackgroundTransparency = 0.02

	local depth_gradient = Instance.new("Frame")
	depth_gradient.BorderSizePixel = 0
	depth_gradient.BackgroundColor3 = rgb(2, 4, 12)
	depth_gradient.BackgroundTransparency = 0.55
	depth_gradient.Size = dim2(1, 0, 0, h * 0.35)
	depth_gradient.Position = dim2(0, 0, 1, -h * 0.35)
	depth_gradient.ZIndex = 1
	depth_gradient.Parent = canvas

	local surface_glow = Instance.new("Frame")
	surface_glow.BorderSizePixel = 0
	surface_glow.BackgroundColor3 = rgb(25, 60, 90)
	surface_glow.BackgroundTransparency = 0.90
	surface_glow.Size = dim2(1, 0, 0, h * 0.10)
	surface_glow.Position = dim2(0, 0, 0, 0)
	surface_glow.ZIndex = 1
	surface_glow.Parent = canvas

	local FISH_COUNT = 10
	local fish = {}
	local fish_cols = {
		{body=rgb(60, 140, 200), fin=rgb(40, 100, 160)},
		{body=rgb(200, 120, 60), fin=rgb(160, 90, 40)},
		{body=rgb(100, 200, 150), fin=rgb(70, 160, 120)},
		{body=rgb(200, 80, 80), fin=rgb(160, 50, 50)},
		{body=rgb(180, 180, 60), fin=rgb(140, 140, 40)},
		{body=rgb(140, 80, 200), fin=rgb(100, 50, 160)},
		{body=rgb(80, 180, 200), fin=rgb(50, 140, 160)},
	}
	for i = 1, FISH_COUNT do
		local col = fish_cols[math.random(1, #fish_cols)]
		local fw = math.random(18, 35)
		local fh = math.random(8, 15)
		local going_right = math.random(1, 2) == 1
		local fx = math.random(0, math.floor(vp.X))
		local fy = math.random(math.floor(h * 0.15), math.floor(h * 0.85))
		local speed = math.random(30, 80)

		local body = Instance.new("Frame")
		body.BorderSizePixel = 0
		body.BackgroundColor3 = col.body
		body.BackgroundTransparency = 0.35
		body.Size = dim2(0, fw, 0, fh)
		body.Position = dim2(0, fx, 0, fy)
		body.ZIndex = 3
		body.Parent = canvas
		local bc = Instance.new("UICorner")
		bc.CornerRadius = dim(0.5, 0)
		bc.Parent = body

		local tail = Instance.new("Frame")
		tail.BorderSizePixel = 0
		tail.BackgroundColor3 = col.fin
		tail.BackgroundTransparency = 0.40
		tail.Size = dim2(0, math.floor(fw * 0.4), 0, math.floor(fh * 0.7))
		tail.ZIndex = 2
		tail.Parent = body
		local tc = Instance.new("UICorner")
		tc.CornerRadius = dim(0.3, 0)
		tc.Parent = tail
		if going_right then
			tail.Position = dim2(0, -tail.Size.X.Offset, 0, math.floor(fh * 0.15))
		else
			tail.Position = dim2(1, 0, 0, math.floor(fh * 0.15))
		end

		local eye = Instance.new("Frame")
		eye.BorderSizePixel = 0
		eye.BackgroundColor3 = rgb(255, 255, 255)
		eye.BackgroundTransparency = 0.20
		eye.Size = dim2(0, max(2, math.floor(fh * 0.25)), 0, max(2, math.floor(fh * 0.25)))
		eye.ZIndex = 4
		eye.Parent = body
		local ec = Instance.new("UICorner")
		ec.CornerRadius = dim(0.5, 0)
		ec.Parent = eye
		if going_right then
			eye.Position = dim2(1, -eye.Size.X.Offset - 2, 0.25, 0)
		else
			eye.Position = dim2(0, 2, 0.25, 0)
		end

		local fin = Instance.new("Frame")
		fin.BorderSizePixel = 0
		fin.BackgroundColor3 = col.fin
		fin.BackgroundTransparency = 0.45
		fin.Size = dim2(0, max(2, math.floor(fw * 0.2)), 0, max(3, math.floor(fh * 0.5)))
		fin.Position = dim2(0.35, 0, 0, -fin.Size.Y.Offset + 1)
		fin.ZIndex = 2
		fin.Parent = body
		local fc = Instance.new("UICorner")
		fc.CornerRadius = dim(0.3, 0)
		fc.Parent = fin

		table.insert(fish, {
			body = body, tail = tail, eye = eye, fin = fin,
			x = fx, y = fy, w = fw, h = fh,
			speed = speed, dir = going_right and 1 or -1,
			wobble_spd = math.random(10, 25) / 10,
			wobble_amp = math.random(3, 10),
			wobble_off = math.random(0, 628) / 100,
			tail_spd = math.random(8, 20) / 10,
			col = col,
		})
	end

	local BIO_COUNT = 25
	local bio = {}
	for i = 1, BIO_COUNT do
		local sz = math.random(2, 5)
		local bio_cols = {
			rgb(80, 220, 255), rgb(100, 255, 200), rgb(60, 200, 180),
			rgb(120, 255, 255), rgb(80, 180, 255),
		}
		local col = bio_cols[math.random(1, #bio_cols)]
		local f = Instance.new("Frame")
		f.BorderSizePixel = 0
		f.BackgroundColor3 = col
		f.BackgroundTransparency = math.random(40, 65) / 100
		f.Size = dim2(0, sz, 0, sz)
		local px = math.random(0, math.floor(vp.X))
		local py = math.random(0, math.floor(h))
		f.Position = dim2(0, px, 0, py)
		f.ZIndex = 3
		f.Parent = canvas
		local c = Instance.new("UICorner")
		c.CornerRadius = dim(0.5, 0)
		c.Parent = f
		local glow = Instance.new("Frame")
		glow.BorderSizePixel = 0
		glow.BackgroundColor3 = col
		glow.BackgroundTransparency = 0.90
		glow.Size = dim2(0, sz * 4, 0, sz * 4)
		glow.AnchorPoint = vec2(0.5, 0.5)
		glow.Position = dim2(0.5, 0, 0.5, 0)
		glow.ZIndex = 2
		glow.Parent = f
		local gc = Instance.new("UICorner")
		gc.CornerRadius = dim(0.5, 0)
		gc.Parent = glow
		table.insert(bio, {
			frame = f, glow = glow, x = px, y = py, sz = sz,
			drift_x = math.random(-10, 10) / 10,
			drift_y = math.random(-15, -5) / 10,
			base_a = f.BackgroundTransparency,
			pulse_spd = math.random(15, 45) / 10,
			pulse_off = math.random(0, 628) / 100,
		})
	end

	local DUST_COUNT = 40
	local dust = {}
	for i = 1, DUST_COUNT do
		local sz = math.random(1, 3)
		local f = Instance.new("Frame")
		f.BorderSizePixel = 0
		f.BackgroundColor3 = rgb(150, 200, 230)
		f.BackgroundTransparency = math.random(60, 85) / 100
		f.Size = dim2(0, sz, 0, sz)
		local px = math.random(0, math.floor(vp.X))
		local py = math.random(0, math.floor(h))
		f.Position = dim2(0, px, 0, py)
		f.ZIndex = 2
		f.Parent = canvas
		local c = Instance.new("UICorner")
		c.CornerRadius = dim(0.5, 0)
		c.Parent = f
		table.insert(dust, {
			frame = f, x = px, y = py, sz = sz,
			drift_x = math.random(-6, 6) / 10,
			drift_y = math.random(-10, -3) / 10,
			base_a = f.BackgroundTransparency,
			twk_speed = math.random(20, 80) / 100,
			twk_off = math.random(0, 628) / 100,
		})
	end

	local BUBBLE_COUNT = 15
	local bubbles = {}
	for i = 1, BUBBLE_COUNT do
		local sz = math.random(2, 6)
		local f = Instance.new("Frame")
		f.BorderSizePixel = 0
		f.BackgroundColor3 = rgb(180, 220, 255)
		f.BackgroundTransparency = math.random(70, 88) / 100
		f.Size = dim2(0, sz, 0, sz)
		local px = math.random(0, math.floor(vp.X))
		local py = math.random(0, math.floor(h))
		f.Position = dim2(0, px, 0, py)
		f.ZIndex = 2
		f.Parent = canvas
		local c = Instance.new("UICorner")
		c.CornerRadius = dim(0.5, 0)
		c.Parent = f
		local shimmer = Instance.new("Frame")
		shimmer.BorderSizePixel = 0
		shimmer.BackgroundColor3 = rgb(255, 255, 255)
		shimmer.BackgroundTransparency = 0.65
		shimmer.Size = dim2(0, max(1, math.floor(sz * 0.3)), 0, max(1, math.floor(sz * 0.3)))
		shimmer.Position = dim2(0.15, 0, 0.12, 0)
		shimmer.ZIndex = 3
		shimmer.Parent = f
		local sc = Instance.new("UICorner")
		sc.CornerRadius = dim(0.5, 0)
		sc.Parent = shimmer
		table.insert(bubbles, {
			frame = f, x = px, y = py, sz = sz,
			rise = math.random(15, 45),
			drift = math.random(-12, 12) / 10,
			wobble_spd = math.random(6, 18) / 10,
			wobble_amp = math.random(4, 15),
			wobble_off = math.random(0, 628) / 100,
			base_x = px, base_a = f.BackgroundTransparency,
		})
	end

	local RAY_COUNT = 4
	local rays = {}
	for i = 1, RAY_COUNT do
		local rw = math.random(20, 55)
		local f = Instance.new("Frame")
		f.BorderSizePixel = 0
		f.BackgroundColor3 = rgb(80, 150, 200)
		f.BackgroundTransparency = 0.94
		f.Size = dim2(0, rw, 0, h)
		f.Position = dim2(0, math.random(0, math.floor(vp.X)), 0)
		f.ZIndex = 2
		f.Parent = canvas
		table.insert(rays, {
			frame = f, x = f.Position.X.Offset,
			drift = math.random(2, 6) / 10,
			base_a = 0.94,
			pulse_spd = math.random(10, 25) / 100,
			pulse_off = math.random(0, 628) / 100,
		})
	end

	local JELLY_COUNT = 3
	local jellies = {}
	for i = 1, JELLY_COUNT do
		local jw = math.random(20, 40)
		local jh = math.random(25, 50)
		local jelly_cols = {rgb(100, 60, 180), rgb(60, 100, 180), rgb(180, 60, 120)}
		local col = jelly_cols[math.random(1, #jelly_cols)]
		local body = Instance.new("Frame")
		body.BorderSizePixel = 0
		body.BackgroundColor3 = col
		body.BackgroundTransparency = 0.55
		body.Size = dim2(0, jw, 0, jh)
		body.Position = dim2(0, math.random(0, math.floor(vp.X)), math.random(math.floor(h * 0.2), math.floor(h * 0.8)))
		body.ZIndex = 3
		body.Parent = canvas
		local bc = Instance.new("UICorner")
		bc.CornerRadius = dim(0.5, 0)
		bc.Parent = body
		local body_glow = Instance.new("Frame")
		body_glow.BorderSizePixel = 0
		body_glow.BackgroundColor3 = col
		body_glow.BackgroundTransparency = 0.90
		body_glow.Size = dim2(0, jw + 14, 0, jh + 14)
		body_glow.AnchorPoint = vec2(0.5, 0.5)
		body_glow.Position = dim2(0.5, 0, 0.5, 0)
		body_glow.ZIndex = 2
		body_glow.Parent = body
		local bgc = Instance.new("UICorner")
		bgc.CornerRadius = dim(0.5, 0)
		bgc.Parent = body_glow
		local tentacles = {}
		for t = 1, math.random(3, 5) do
			local tr = Instance.new("Frame")
			tr.BorderSizePixel = 0
			tr.BackgroundColor3 = col
			tr.BackgroundTransparency = 0.65
			tr.Size = dim2(0, 1, 0, math.random(15, 30))
			tr.Position = dim2(0, math.floor(jw * (t / (math.random(3, 5) + 1))), 0, jh)
			tr.ZIndex = 3
			tr.Parent = body
			table.insert(tentacles, {frame = tr, sway_spd = math.random(8, 20) / 10, sway_off = math.random(0, 628) / 100})
		end
		table.insert(jellies, {
			body = body, glow = body_glow, tentacles = tentacles,
			x = body.Position.X.Offset, y = body.Position.Y.Offset,
			base_x = body.Position.X.Offset, base_y = body.Position.Y.Offset,
			rise = math.random(6, 15),
			drift = math.random(-6, 6) / 10,
			pulse_spd = math.random(8, 18) / 10,
			pulse_off = math.random(0, 628) / 100,
			col = col, w = jw, h = jh,
		})
	end

	local KELP_COUNT = 4
	local kelp = {}
	for i = 1, KELP_COUNT do
		local kx = math.random(30, math.floor(vp.X - 30))
		local segments = {}
		local seg_count = math.random(5, 10)
		for s = 1, seg_count do
			local seg = Instance.new("Frame")
			seg.BorderSizePixel = 0
			seg.BackgroundColor3 = rgb(20, 70, 40)
			seg.BackgroundTransparency = math.random(45, 65) / 100
			seg.Size = dim2(0, math.random(3, 6), 0, math.random(15, 30))
			seg.ZIndex = 2
			seg.Parent = canvas
			table.insert(segments, {frame = seg})
		end
		table.insert(kelp, {
			segments = segments, x = kx,
			base_y = h - 20,
			sway_spd = math.random(5, 15) / 10,
			sway_off = math.random(0, 628) / 100,
			sway_amp = math.random(8, 20),
		})
	end

	local SILHOUETTE_COUNT = 4
	local silhouettes = {}
	for i = 1, SILHOUETTE_COUNT do
		local sw = math.random(80, 180)
		local sh = math.random(40, 90)
		local f = Instance.new("Frame")
		f.BorderSizePixel = 0
		f.BackgroundColor3 = rgb(6, 14, 28)
		f.BackgroundTransparency = math.random(72, 88) / 100
		f.Size = dim2(0, sw, 0, sh)
		f.Position = dim2(0, math.random(0, math.floor(vp.X)), math.random(math.floor(h * 0.5), math.floor(h * 0.9)))
		f.ZIndex = 2
		f.Parent = canvas
		local c = Instance.new("UICorner")
		c.CornerRadius = dim(0.3, 0)
		c.Parent = f
		table.insert(silhouettes, {
			frame = f, x = f.Position.X.Offset, y = f.Position.Y.Offset,
			drift = math.random(1, 5) / 10,
			base_a = f.BackgroundTransparency,
		})
	end

	local HAZE_COUNT = 8
	local hazes = {}
	for i = 1, HAZE_COUNT do
		local f = Instance.new("Frame")
		f.BorderSizePixel = 0
		f.BackgroundColor3 = rgb(12, 30, 50)
		f.BackgroundTransparency = math.random(82, 94) / 100
		f.Size = dim2(0, math.random(250, 600), 0, math.random(80, 200))
		f.Position = dim2(0, math.random(-150, math.floor(vp.X)), math.random(0, math.floor(h)))
		f.ZIndex = 2
		f.Parent = canvas
		table.insert(hazes, {
			frame = f, x = f.Position.X.Offset, y = f.Position.Y.Offset,
			drift = math.random(2, 8) / 10,
			base_a = f.BackgroundTransparency,
		})
	end

	local update_elapsed = 0
	local hb = run_service.Heartbeat:Connect(function(dt)
		if not canvas or not canvas.Visible then return end
		update_elapsed = update_elapsed + dt
		if update_elapsed < BG_UPDATE_INTERVAL then return end
		dt = update_elapsed
		update_elapsed = 0
		local now = clock()

		for _, f in ipairs(fish) do
			if not f.body or not f.body.Parent then continue end
			f.x = f.x + f.speed * f.dir * dt
			local wobble = sin_wave(now * f.wobble_spd + f.wobble_off) * f.wobble_amp
			f.y = f.y + wobble * dt * 2

			if f.dir > 0 and f.x > vp.X + 50 then
				f.x = -f.w - 20
				f.y = math.random(math.floor(h * 0.15), math.floor(h * 0.85))
			elseif f.dir < 0 and f.x < -f.w - 50 then
				f.x = vp.X + 20
				f.y = math.random(math.floor(h * 0.15), math.floor(h * 0.85))
			end

			f.body.Position = dim2(0, f.x, 0, f.y)
			f.tail.Rotation = sin_wave(now * f.tail_spd) * 15
			f.fin.Rotation = sin_wave(now * f.tail_spd * 1.3 + 1) * 10
		end

		for _, p in ipairs(bio) do
			if not p.frame or not p.frame.Parent then continue end
			p.x = p.x + p.drift_x * dt
			p.y = p.y + p.drift_y * dt
			if p.y < -15 then p.y = h + 15; p.x = math.random(0, math.floor(vp.X)) end
			if p.x > vp.X + 15 then p.x = -15 end
			if p.x < -15 then p.x = vp.X + 15 end
			local pulse = sin_wave(now * p.pulse_spd + p.pulse_off) * 0.18
			p.frame.BackgroundTransparency = clamp(p.base_a + pulse, 0.25, 0.80)
			p.frame.Position = dim2(0, p.x, 0, p.y)
			if p.glow then p.glow.BackgroundTransparency = clamp(0.90 + pulse * 0.5, 0.85, 0.97) end
		end

		for _, d in ipairs(dust) do
			if not d.frame or not d.frame.Parent then continue end
			d.x = d.x + d.drift_x * dt
			d.y = d.y + d.drift_y * dt
			if d.y < -10 then d.y = h + 10; d.x = math.random(0, math.floor(vp.X)) end
			if d.x > vp.X + 10 then d.x = -10 end
			if d.x < -10 then d.x = vp.X + 10 end
			local twk = sin_wave(now * d.twk_speed + d.twk_off) * 0.10
			d.frame.BackgroundTransparency = clamp(d.base_a + twk, 0.35, 0.92)
			d.frame.Position = dim2(0, d.x, 0, d.y)
		end

		for _, b in ipairs(bubbles) do
			if not b.frame or not b.frame.Parent then continue end
			b.y = b.y - b.rise * dt
			local wx = b.base_x + sin_wave(now * b.wobble_spd + b.wobble_off) * b.wobble_amp
			b.x = wx
			b.frame.Position = dim2(0, wx, 0, b.y)
			if b.y < -b.sz - 10 then
				b.y = h + math.random(10, 40)
				b.base_x = math.random(0, math.floor(vp.X))
			end
		end

		for _, r in ipairs(rays) do
			if not r.frame or not r.frame.Parent then continue end
			r.x = r.x + r.drift * dt
			if r.x > vp.X + 100 then r.x = -r.frame.Size.X.Offset - 50 end
			r.frame.Position = dim2(0, r.x, 0, 0)
			local pulse = sin_wave(now * r.pulse_spd + r.pulse_off) * 0.025
			r.frame.BackgroundTransparency = clamp(r.base_a + pulse, 0.90, 0.97)
		end

		for _, j in ipairs(jellies) do
			if not j.body or not j.body.Parent then continue end
			j.y = j.y - j.rise * dt
			local wx = j.base_x + sin_wave(now * 0.3 + j.pulse_off) * 20 + j.drift * dt * 15
			j.x = j.x + (wx - j.x) * 2 * dt
			j.body.Position = dim2(0, j.x, 0, j.y)
			local pulse = sin_wave(now * j.pulse_spd + j.pulse_off) * 0.08
			j.body.BackgroundTransparency = clamp(0.55 + pulse, 0.40, 0.72)
			if j.glow then j.glow.BackgroundTransparency = clamp(0.90 + pulse * 0.5, 0.85, 0.97) end
			for _, t in ipairs(j.tentacles) do
				if t.frame and t.frame.Parent then t.frame.Rotation = sin_wave(now * t.sway_spd + t.sway_off) * 10 end
			end
			if j.y < -j.h - 20 then
				j.y = h + math.random(20, 60)
				j.base_x = math.random(0, math.floor(vp.X))
				j.x = j.base_x
			end
		end

		for _, k in ipairs(kelp) do
			local total_h = 0
			for si, seg in ipairs(k.segments) do
				if not seg.frame or not seg.frame.Parent then continue end
				local sway = sin_wave(now * k.sway_spd + k.sway_off + si * 0.3) * k.sway_amp * (si / #k.segments)
				local seg_h = seg.frame.Size.Y.Offset
				local sy = k.base_y - total_h
				seg.frame.Position = dim2(0, k.x + sway, 0, sy)
				total_h = total_h + seg_h - 2
			end
		end

		for _, sl in ipairs(silhouettes) do
			if not sl.frame or not sl.frame.Parent then continue end
			sl.x = sl.x + sl.drift * dt
			if sl.x > vp.X + 120 then sl.x = -sl.frame.Size.X.Offset - 60 end
			sl.frame.Position = dim2(0, sl.x, 0, sl.y)
		end

		for _, hz in ipairs(hazes) do
			if not hz.frame or not hz.frame.Parent then continue end
			hz.x = hz.x + hz.drift * dt
			if hz.x > vp.X + 150 then hz.x = -hz.frame.Size.X.Offset - 80 end
			hz.frame.Position = dim2(0, hz.x, 0, hz.y)
			hz.frame.BackgroundTransparency = hz.base_a + sin_wave(now * 0.08 + hz.y * 0.004) * 0.02
		end
	end)

	return make_handle(hb)
end

function library:set_bg_theme(theme_name)
	if library.bg_theme_connection then
		if type(library.bg_theme_connection) == "table" then
			library.bg_theme_connection:Disconnect()
		else
			library.bg_theme_connection:Disconnect()
		end
		library.bg_theme_connection = nil
	end

	if library.bg_canvas then
		library.bg_canvas:Destroy()
		library.bg_canvas = nil
	end

	if library.bg_blur then
		library.bg_blur:Destroy()
		library.bg_blur = nil
	end

	if theme_name == "none" or not BG_THEMES[theme_name] then
		library.bg_theme = nil
		return
	end

	library.bg_theme  = theme_name
	library.bg_blur   = make_blur()
	library.bg_canvas = make_canvas(library.gui)

	library.bg_blur.Size      = 0
	library.bg_canvas.Visible = false

	for _, f in ipairs(library.main_frame) do
		f.ZIndex = 3
	end

	library.bg_theme_connection = BG_THEMES[theme_name](library.bg_canvas, library.gui)
end

function library:set_bg_visible(visible)
	library._bg_visibility_token = (library._bg_visibility_token or 0) + 1
	local visibility_token = library._bg_visibility_token
	visible = visible == true and library.panel_open == true and library._suppress_ui ~= true

	if visible then
		if library.bg_theme and library.bg_theme ~= "none" then
			if not library.bg_blur then
				library:create_bg_effects()
			end
			if library.bg_blur then
				tween_service:Create(
					library.bg_blur,
					TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
					{ Size = library.bg_blur_amount or 0 }
				):Play()
			end
			if library.bg_canvas then
				library.bg_canvas.Visible = true
			end
		end
	else
		if library._suppress_ui then
			-- Config/autoload is a silent path. Destroy immediately so a previously
			-- queued open tween cannot finish later and leave Lighting blurred.
			library:destroy_bg_effects()
			library:_update_frost_blur()
			return
		end
		if library.bg_blur then
			local tween = tween_service:Create(
				library.bg_blur,
				TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
				{ Size = 0 }
			)
			tween:Play()
			tween.Completed:Connect(function()
				if library._bg_visibility_token == visibility_token and not library.panel_open then
					library:destroy_bg_effects()
				end
			end)
		else
			library:destroy_bg_effects()
		end
		if library.bg_canvas then
			library.bg_canvas.Visible = false
		end
	end
	library:_update_frost_blur()
end

function library:bg_blur_slider(properties)
	properties = properties or {}
	properties.name     = properties.name or "Background Blur"
	properties.flag     = properties.flag or "__bg_blur__"
	properties.min      = properties.min  or 0
	properties.max      = properties.max  or 40
	properties.default  = properties.default ~= nil and properties.default or 0
	properties.float    = properties.float or 1
	-- slider:set intentionally skips callbacks during construction; keep the
	-- runtime blur value in sync with the visible default as well.
	if tonumber(properties.default) then
		library.bg_blur_amount = tonumber(properties.default)
	end
	properties.callback = function(value)
		library.bg_blur_amount = value
		if library.bg_blur and library.panel_open then
			library.bg_blur.Size = value
		end
	end
	return library.slider(self, properties)
end

function library:bg_dropdown(properties)
	properties = properties or {}
	properties.name     = properties.name or "Background"
	properties.flag     = properties.flag or "__bg_theme__"
	properties.default  = properties.default or "stars"
	properties.items    = { "stars", "snow" }
	properties.callback = function(value)
		library:set_bg_theme(value)
		if value ~= "none" and library.panel_open and not library._suppress_ui then
			library:set_bg_visible(true)
		end
	end
	return library.dropdown(self, properties)
end

library.gui = library:create("ScreenGui", {
	Enabled = false,
	Parent = coregui,
	Name = "",
	DisplayOrder = 2,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
})

library._suppress_ui = false

function library:close_transient_elements()
	if self.current_element_open then
		local current = self.current_element_open
		self.current_element_open = nil
		pcall(function()
			current.open = false
			if current.set_visible then current.set_visible(false) end
		end)
	end

	if type(self.nav_elements) == "table" then
		for _, entry in ipairs(self.nav_elements) do
			local cfg = entry and entry.cfg
			if cfg then
				cfg.open = false
				if cfg.stop_dragging then pcall(cfg.stop_dragging) end
				if cfg.set_visible then pcall(cfg.set_visible, false) end
			end
		end
	end

	self.active_colorpicker = nil
	self.active_drag = nil
	self.active_resize = nil
end

function library:set_transient_suppressed(state)
	self._suppress_ui = state == true
	if self._suppress_ui then
		self:close_transient_elements()
	end
	self:_update_frost_blur()
end

function library:set_loading(state, keep_suppressed)
	self._loading = state == true
	self:set_transient_suppressed(state == true or keep_suppressed == true)
	if state == true then
		self.panel_open = false
		self:set_bg_visible(false)
	end
	if self.gui then
		self.gui.Enabled = not state
	end
end

library:connection(uis.InputChanged, function(input)
	if input.UserInputType ~= Enum.UserInputType.MouseMovement then
		return
	end
	library._pointer_position = input.Position
	library._pointer_dirty = true
end)

local function apply_pointer_update()
	local inputPosition = library._pointer_position
	if not inputPosition then return end
	local active_drag = library.active_drag
	if active_drag then
		local delta = inputPosition - active_drag.drag_start
		active_drag.frame.Position = dim2(
			active_drag.start_position.X.Scale,
			active_drag.start_position.X.Offset + delta.X,
			active_drag.start_position.Y.Scale,
			active_drag.start_position.Y.Offset + delta.Y
		)
		if active_drag.on_move then pcall(active_drag.on_move, active_drag.frame) end
	end

	local active_resize = library.active_resize
	if active_resize then
		local viewport_x = camera.ViewportSize.X
		local viewport_y = camera.ViewportSize.Y

		active_resize.frame.Size = dim2(
			active_resize.start_size.X.Scale,
			clamp(
				active_resize.start_size.X.Offset + (inputPosition.X - active_resize.start.X),
				active_resize.og_size.X.Offset,
				viewport_x
			),
			active_resize.start_size.Y.Scale,
			clamp(
				active_resize.start_size.Y.Offset + (inputPosition.Y - active_resize.start.Y),
				active_resize.og_size.Y.Offset,
				viewport_y
			)
		)
		if active_resize.on_move then pcall(active_resize.on_move, active_resize.frame) end
	end

	local active_colorpicker = library.active_colorpicker
	if active_colorpicker then
		active_colorpicker:update_color()
	end
end

local last_pointer_apply = 0
library:connection(run_service.RenderStepped, function()
	if not library._pointer_dirty then return end
	local now = clock()
	if now - last_pointer_apply < (1 / 60) then return end
	library._pointer_dirty = false
	last_pointer_apply = now
	apply_pointer_update()
end)

library:connection(uis.InputEnded, function(input)
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
		return
	end

	if library._pointer_dirty then
		library._pointer_dirty = false
		apply_pointer_update()
	end
	local active_drag = library.active_drag
	local active_resize = library.active_resize
	library.active_drag = nil
	library.active_resize = nil
	if active_drag and active_drag.on_end then pcall(active_drag.on_end, active_drag.frame) end
	if active_resize and active_resize.on_end then pcall(active_resize.on_end, active_resize.frame) end

	local active_colorpicker = library.active_colorpicker
	if active_colorpicker then
		active_colorpicker.stop_dragging()
		library.active_colorpicker = nil
	end
end)

local _KL_REF = nil
local _FP_REF = nil

function library:window(properties)
	local cfg = {
		name = properties.Name or properties.name or properties.Title or properties.title or "sp4m.wtf",
		size = properties.Size or properties.size or dim2(0, 500, 0, 650),
	}

	local animated_text = library:animation(cfg.name)
	local function persist_overlay_position(frame, xKey, yKey, state)
		if not frame then return end
		if state then
			state.position = Vector2.new(frame.Position.X.Offset, frame.Position.Y.Offset)
		end
		local config = getgenv().Config
		if config then
			config.Overlays = config.Overlays or {}
			config.Overlays[xKey] = frame.Position.X.Offset
			config.Overlays[yKey] = frame.Position.Y.Offset
		end
	end

	local __holder = library:create("Frame", {
		Parent = library.gui,
		Name = "",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 20, 0, 20),
		BorderColor3 = Color3.new(0.0745, 0.0745, 0.0745),
		ZIndex = 4,
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = Color3.new(0.1569, 0.1569, 0.1569),
		Visible = false,
	})

	local WM_PADDING = 30

	local wm_inline1 = library:create("Frame", {
		Parent = __holder,
		Name = "",
		Active = true,
		Draggable = false,
		BorderColor3 = Color3.new(0.0000, 0.0000, 0.0000),
		Size = UDim2.new(0, math.max(#cfg.name * 8 + WM_PADDING, 120), 0, 40),
		BackgroundColor3 = Color3.new(0.1569, 0.1569, 0.1569),
		ClipsDescendants = false,
		FrostedTransparency = 0.90,
	})
	library:make_draggable(wm_inline1, {
		on_move = function(frame) persist_overlay_position(frame, "WatermarkX", "WatermarkY") end,
		on_end = function(frame) persist_overlay_position(frame, "WatermarkX", "WatermarkY") end,
	})

	local wm_accent_line = library:create("Frame", {
		Parent = wm_inline1,
		Name = "",
		BorderColor3 = Color3.new(0.1333, 0.1333, 0.1333),
		Size = UDim2.new(1, 0, 0, 2),
		BorderSizePixel = 0,
		BackgroundColor3 = themes.preset.accent,
	})
	library:apply_theme(wm_accent_line, "accent", "BackgroundColor3")

	library:create("Frame", {
		Parent = wm_inline1,
		Name = "",
		BackgroundTransparency = 0.5,
		Position = UDim2.new(0, 0, 0, 1),
		BorderColor3 = Color3.new(0.0000, 0.0000, 0.0000),
		Size = UDim2.new(1, 0, 0, 1),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.new(0.0000, 0.0000, 0.0000),
	})

	local wm_inline2 = library:create("Frame", {
		Parent = wm_inline1,
		Name = "",
		Position = UDim2.new(0, 2, 0, 2),
		BorderColor3 = Color3.new(0.0000, 0.0000, 0.0000),
		Size = UDim2.new(1, -4, 1, -4),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.new(0.1020, 0.1020, 0.1020),
		FrostedTransparency = 0.99,
	})

	local wm_main = library:create("Frame", {
		Parent = wm_inline2,
		Name = "",
		Position = UDim2.new(0, 2, 0, 2),
		BorderColor3 = Color3.new(0.2235, 0.2235, 0.2235),
		Size = UDim2.new(1, -4, 1, -4),
		BackgroundColor3 = Color3.new(0.1020, 0.1020, 0.1020),
		FrostedTransparency = 0.97,
	})

	local wm_tab_inline = library:create("Frame", {
		Parent = wm_main,
		Name = "",
		Position = UDim2.new(0, 6, 0, 6),
		BorderColor3 = Color3.new(0.0745, 0.0745, 0.0745),
		Size = UDim2.new(1, -12, 1, -12),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.new(0.0745, 0.0745, 0.0745),
		FrostedTransparency = 0.99,
	})

	local wm_tabs = library:create("Frame", {
		Parent = wm_tab_inline,
		Name = "",
		Position = UDim2.new(0, 2, 0, 2),
		BorderColor3 = Color3.new(0.2196, 0.2196, 0.2196),
		Size = UDim2.new(1, -4, 1, -4),
		BackgroundColor3 = Color3.new(0.0863, 0.0863, 0.0863),
		FrostedTransparency = 0.92,
	})

	local wm_name = library:create("TextLabel", {
		Parent = wm_tabs,
		Name = "",
		FontFace = library.font,
		TextColor3 = Color3.new(0.6667, 0.6667, 0.6667),
		BorderColor3 = Color3.new(0.0000, 0.0000, 0.0000),
		Text = "ledger.live",
		TextStrokeTransparency = 0.5,
		Size = UDim2.new(1, -16, 1, 0),
		Position = UDim2.new(0, 8, 0, 0),
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = false,
		TextTruncate = Enum.TextTruncate.AtEnd,
		BorderSizePixel = 0,
		AutomaticSize = Enum.AutomaticSize.None,
		TextSize = 12,
		BackgroundColor3 = Color3.new(1.0000, 1.0000, 1.0000),
	})

	local TEXT_ANIMATION_GRADIENT = library:create("UIGradient", {
		Parent = wm_name,
		Name = "",
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.new(1.0000, 1.0000, 1.0000)),
			ColorSequenceKeypoint.new(0.01, themes.preset.accent),
			ColorSequenceKeypoint.new(1, Color3.new(1.0000, 1.0000, 1.0000)),
		}),
	})

	library:create("UIPadding", {
		Parent = wm_tabs,
		Name = "",
		PaddingRight = UDim.new(0, 21),
	})

	local wm_glow = library:create("ImageLabel", {
		Parent = wm_accent_line,
		Name = "",
		ImageColor3 = themes.preset.accent,
		ScaleType = Enum.ScaleType.Slice,
		ImageTransparency = 0.9,
		BorderColor3 = Color3.new(0.0000, 0.0000, 0.0000),
		BackgroundColor3 = Color3.new(1.0000, 1.0000, 1.0000),
		Image = "http://www.roblox.com/asset/?id=18245826428",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, -20, 0, -20),
		Size = UDim2.new(1, 40, 0, 42),
		ZIndex = 2,
		BorderSizePixel = 0,
		SliceCenter = Rect.new(Vector2.new(21, 21), Vector2.new(79, 79)),
	})
	library:apply_theme(wm_glow, "accent", "ImageColor3")

	local watermark_index   = 1
	local watermark_elapsed = 0
	local wm_anim_style     = "type"
	local wm_reveal_progress = 0
	local WM_CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789@#$%&*?!"
	local function wm_rand_char()
		local i = math.random(1, #WM_CHARS)
		return WM_CHARS:sub(i, i)
	end
	local function set_watermark_gradient_enabled(enabled)
		-- UIGradient support differs between Roblox clients.  Keep the text
		-- animation alive even when the optional Enabled property is unavailable.
		pcall(function()
			TEXT_ANIMATION_GRADIENT.Enabled = enabled == true
		end)
	end
	local function fit_watermark()
		if not (wm_inline1 and wm_inline1.Parent) then return end
		local textWidth = #cfg.name * 8
		local ok, bounds = pcall(function()
			return game:GetService("TextService"):GetTextSize(
				cfg.name,
				wm_name.TextSize,
				wm_name.Font,
				Vector2.new(10000, 40)
			)
		end)
		if ok and bounds then textWidth = bounds.X end
		local fullWidth = math.max(math.ceil(textWidth) + WM_PADDING + 8, 120)
		wm_inline1.Size = UDim2.fromOffset(fullWidth, 40)
	end

	task.defer(function()
		wm_name.Text = cfg.name
		fit_watermark()
	end)

	task.wait()

	local inline1 = library:create("Frame", {
		Parent = library.gui,
		Name = "",
		Active = true,
		Draggable = false,
		Position = UDim2.new(0.5, -cfg.size.X.Offset / 2, 0.5, -cfg.size.Y.Offset / 2),
		BorderColor3 = Color3.new(0.0314, 0.0314, 0.0314),
		ZIndex = 4,
		Size = cfg.size,
		BackgroundColor3 = Color3.new(0.1569, 0.1569, 0.1569),
		FrostedTransparency = 0.92,
	})
	table.insert(library.main_frame, inline1)
	local WINDOW_PATH = inline1
	library:make_draggable(inline1)
	library:make_resizable(inline1)

	local inline2 = library:create("Frame", {
		Parent = inline1,
		Name = "",
		Position = UDim2.new(0, 2, 0, 2),
		BorderColor3 = Color3.new(0.0000, 0.0000, 0.0000),
		Size = UDim2.new(1, -4, 1, -4),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.new(0.1020, 0.1020, 0.1020),
		FrostedTransparency = 0.98,
	})

	local main = library:create("Frame", {
		Parent = inline2,
		Name = "",
		Position = UDim2.new(0, 2, 0, 2),
		BorderColor3 = Color3.new(0.2235, 0.2235, 0.2235),
		Size = UDim2.new(1, -4, 1, -4),
		BackgroundColor3 = Color3.new(0.1020, 0.1020, 0.1020),
		FrostedTransparency = 0.94,
	})

	local tab_buttons = library:create("Frame", {
		Parent = main,
		Name = "",
		BorderColor3 = Color3.new(0.0000, 0.0000, 0.0000),
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 16, 0, 4),
		Size = UDim2.new(1, -32, 0, 0),
		ZIndex = 2,
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.new(1.0000, 1.0000, 1.0000),
	})

	cfg["tab_holder"] = tab_buttons

	library:create("UIListLayout", {
		Parent = tab_buttons,
		Name = "",
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		HorizontalFlex = Enum.UIFlexAlignment.Fill,
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})

	local tab_inline = library:create("Frame", {
		Parent = main,
		Name = "",
		Position = UDim2.new(0, 15, 0, 33),
		BorderColor3 = Color3.new(0.0745, 0.0745, 0.0745),
		Size = UDim2.new(1, -30, 1, -48),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.new(0.0745, 0.0745, 0.0745),
		FrostedTransparency = 0.98,
	})

	local tabs = library:create("Frame", {
		Parent = tab_inline,
		Name = "",
		Position = UDim2.new(0, 2, 0, 2),
		BorderColor3 = Color3.new(0.2196, 0.2196, 0.2196),
		Size = UDim2.new(1, -4, 1, -4),
		BackgroundColor3 = Color3.new(0.0863, 0.0863, 0.0863),
		FrostedTransparency = 0.90,
	})

	cfg["tab_instance_holder"] = tabs

	local accent_line = library:create("Frame", {
		Parent = inline1,
		Name = "",
		BorderColor3 = Color3.new(0.1333, 0.1333, 0.1333),
		Size = UDim2.new(1, 0, 0, 2),
		BorderSizePixel = 0,
		BackgroundColor3 = themes.preset.accent,
	})
	library:apply_theme(accent_line, "accent", "BackgroundColor3")

	library:create("TextLabel", {
		Parent = inline1,
		Name = "",
		FontFace = library.font,
		TextColor3 = Color3.new(0.6667, 0.6667, 0.6667),
		BorderColor3 = Color3.new(0.0000, 0.0000, 0.0000),
		Text = cfg.name,
		TextStrokeTransparency = 0.5,
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, -1),
		Size = UDim2.new(1, 0, 0, 1),
		ZIndex = 2,
		TextSize = 12,
		BackgroundColor3 = Color3.new(1.0000, 1.0000, 1.0000),
	})

	local win_glow = library:create("ImageLabel", {
		Parent = inline1,
		Name = "",
		ImageColor3 = themes.preset.accent,
		ScaleType = Enum.ScaleType.Slice,
		ImageTransparency = 0.9,
		BorderColor3 = Color3.new(0.0000, 0.0000, 0.0000),
		BackgroundColor3 = Color3.new(1.0000, 1.0000, 1.0000),
		Image = "http://www.roblox.com/asset/?id=18245826428",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, -20, 0, -20),
		Size = UDim2.new(1, 40, 0, 42),
		ZIndex = 2,
		BorderSizePixel = 0,
		SliceCenter = Rect.new(Vector2.new(21, 21), Vector2.new(79, 79)),
	})
	library:apply_theme(win_glow, "accent", "ImageColor3")

	library:create("Frame", {
		Parent = inline1,
		Name = "",
		BackgroundTransparency = 0.5,
		Position = UDim2.new(0, 0, 0, 1),
		BorderColor3 = Color3.new(0.0000, 0.0000, 0.0000),
		Size = UDim2.new(1, 0, 0, 1),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.new(0.0000, 0.0000, 0.0000),
	})

	library:create("Frame", {
		Parent = inline1,
		Name = "",
		BackgroundTransparency = 1,
		Position = UDim2.new(1, 20, 0, 0),
		BorderColor3 = Color3.new(0.0745, 0.0745, 0.0745),
		ZIndex = 2,
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundColor3 = Color3.new(0.1569, 0.1569, 0.1569),
	})

	local header_gradient_elapsed = 0
	library:connection(run_service.RenderStepped, function(dt)
		if not __holder.Visible then return end
		local anim_speed = tonumber(flags["color_picker_anim_speed"]) or 1
		header_gradient_elapsed = header_gradient_elapsed + dt
		if header_gradient_elapsed < (1 / 30) then return end
		local step = header_gradient_elapsed
		header_gradient_elapsed = 0
		local now = clock()
		library.sin = abs(sin_wave(now * anim_speed))
		watermark_elapsed = watermark_elapsed + step * math.max(anim_speed, 0.1)
		local style = string.lower(tostring(wm_anim_style or "type"))
		wm_name.TextTransparency = 0
		wm_name.TextStrokeTransparency = 0.28
		set_watermark_gradient_enabled(style == "wave")

		if style == "type" then
			local count = #cfg.name + 5
			local reveal = math.floor(watermark_elapsed * 10) % math.max(count, 1)
			wm_name.Text = cfg.name:sub(1, math.min(reveal, #cfg.name))
		elseif style == "fade" then
			wm_name.Text = cfg.name
			wm_name.TextTransparency = 0.08 + abs(sin_wave(watermark_elapsed * 2.2)) * 0.26
		elseif style == "array" then
			local offset = math.floor(watermark_elapsed * 5) % math.max(#cfg.name, 1)
			wm_name.Text = cfg.name:sub(offset + 1) .. cfg.name:sub(1, offset)
		elseif style == "matrix" then
			local settled = math.floor(watermark_elapsed * 7) % (#cfg.name + 8)
			local chars = table.create(#cfg.name)
			for i = 1, #cfg.name do
				chars[i] = i <= settled and cfg.name:sub(i, i) or wm_rand_char()
			end
			wm_name.Text = table.concat(chars)
		elseif style == "wave" then
			wm_name.Text = cfg.name
			pcall(function()
				TEXT_ANIMATION_GRADIENT.Offset = Vector2.new(sin_wave(watermark_elapsed * 1.8) * 0.75, 0)
			end)
			TEXT_ANIMATION_GRADIENT.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
				ColorSequenceKeypoint.new(0.5, themes.preset.accent),
				ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1)),
			})
		else
			wm_name.Text = cfg.name
		end
		fit_watermark()
	end)

	task.wait()

	local esp_preview = library:create("Frame", {
		Parent = library.gui,
		Name = "",
		Visible = false,
		Active = true,
		Draggable = false,
		Position = UDim2.new(
			0,
			inline1.AbsolutePosition.X + inline1.AbsoluteSize.X + 8,
			0,
			inline1.AbsolutePosition.Y + 1
		),
		BorderColor3 = Color3.new(0.0314, 0.0314, 0.0314),
		Size = UDim2.new(0, 328, 0, 376),
		BackgroundColor3 = Color3.new(0.2196, 0.2196, 0.2196),
		ZIndex = 4,
		FrostedTransparency = 0.88,
	})
	library:make_draggable(esp_preview, {
		on_move = function(frame) persist_overlay_position(frame, "ESPPreviewX", "ESPPreviewY") end,
		on_end = function(frame) persist_overlay_position(frame, "ESPPreviewX", "ESPPreviewY") end,
	})
	library:make_resizable(esp_preview)

	library:create("TextLabel", {
		Parent = esp_preview,
		Name = "",
		FontFace = library.font,
		TextColor3 = Color3.new(0.6667, 0.6667, 0.6667),
		BorderColor3 = Color3.new(0.0000, 0.0000, 0.0000),
		Text = "esp preview",
		TextStrokeTransparency = 0.5,
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, -1),
		Size = UDim2.new(1, 0, 0, 1),
		ZIndex = 2,
		TextSize = 12,
		BackgroundColor3 = Color3.new(1.0000, 1.0000, 1.0000),
	})

	local esp_main = library:create("Frame", {
		Parent = esp_preview,
		Name = "",
		Position = UDim2.new(0, 4, 0, 4),
		BorderColor3 = Color3.new(0.1020, 0.1020, 0.1020),
		Size = UDim2.new(1, -8, 1, -8),
		BorderSizePixel = 2,
		BackgroundColor3 = Color3.new(0.1020, 0.1020, 0.1020),
		FrostedTransparency = 0.97,
	})

	library:create("UIStroke", {
		Parent = esp_main,
		Color = Color3.new(0.2235, 0.2235, 0.2235),
		LineJoinMode = Enum.LineJoinMode.Miter,
	})

	local esp_tabs = library:create("Frame", {
		Parent = esp_main,
		Name = "",
		Position = UDim2.new(0, 8, 0, 8),
		BorderColor3 = Color3.new(0.0314, 0.0314, 0.0314),
		Size = UDim2.new(1, -16, 1, -16),
		BorderSizePixel = 2,
		BackgroundColor3 = Color3.new(0.0863, 0.0863, 0.0863),
		FrostedTransparency = 0.90,
	})

	library:create("UIStroke", {
		Parent = esp_tabs,
		Color = Color3.new(0.2235, 0.2235, 0.2235),
		LineJoinMode = Enum.LineJoinMode.Miter,
	})

	local esp_vpf = library:create("ViewportFrame", {
		Parent = esp_tabs,
		Position = UDim2.new(0, 4, 0, 4),
		Size = UDim2.new(1, -8, 1, -8),
		BackgroundTransparency = 1,
		Visible = false,
		ZIndex = 5,
		LightColor = Color3.new(1.0000, 1.0000, 1.0000),
		LightDirection = Vector3.new(-0.3, -1, -0.3),
		Ambient = Color3.new(1.0000, 1.0000, 1.0000),
	})

	local esp_overlay = library:create("Frame", {
		Parent = esp_tabs,
		Position = UDim2.new(0, 4, 0, 4),
		Size = UDim2.new(1, -8, 1, -8),
		BackgroundTransparency = 1,
		ZIndex = 10,
		ClipsDescendants = true,
	})

	local BOX_W, BOX_H = 100, 160
	local BOX_CX, BOX_CY = 0.50, 0.50

	local esp_chams_frame = library:create("Frame", {
		Parent = esp_overlay,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(BOX_CX, 0, BOX_CY, 0),
		Size = UDim2.new(0, BOX_W + 8, 0, BOX_H + 8),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 10,
		Visible = false,
	})

	local esp_chams_parts = {}
	for _, bodyDef in ipairs({
		{0.50, 0.11, 18, 18, 9},
		{0.50, 0.35, 34, 52, 4},
		{0.27, 0.37, 12, 58, -8},
		{0.73, 0.37, 12, 58, 8},
		{0.40, 0.73, 14, 58, 3},
		{0.60, 0.73, 14, 58, -3},
	}) do
		local bodyPart = library:create("Frame", {
			Parent = esp_chams_frame,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(bodyDef[1], 0, bodyDef[2], 0),
			Size = UDim2.fromOffset(bodyDef[3], bodyDef[4]),
			Rotation = bodyDef[5],
			BackgroundColor3 = themes.preset.accent,
			BackgroundTransparency = 0.25,
			BorderSizePixel = 0,
			ZIndex = 10,
		})
		library:create("UICorner", { Parent = bodyPart, CornerRadius = UDim.new(0, bodyDef[3] >= 18 and 5 or 3) })
		esp_chams_parts[#esp_chams_parts + 1] = bodyPart
	end

	local esp_box_fill = library:create("Frame", {
		Parent = esp_overlay,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(BOX_CX, 0, BOX_CY, 0),
		Size = UDim2.new(0, BOX_W, 0, BOX_H),
		BackgroundTransparency = 0.5,
		BorderSizePixel = 0,
		ZIndex = 11,
		Visible = false,
	})

	local esp_box = library:create("Frame", {
		Parent = esp_overlay,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(BOX_CX, 0, BOX_CY, 0),
		Size = UDim2.new(0, BOX_W, 0, BOX_H),
		BackgroundTransparency = 1,
		ZIndex = 12,
	})
	local esp_box_outline = library:create("UIStroke", {
		Parent = esp_box,
		Color = Color3.new(0.0000, 0.0000, 0.0000),
		LineJoinMode = Enum.LineJoinMode.Miter,
		Thickness = 3,
		Transparency = 0.4,
	})
	local esp_box_stroke = library:create("UIStroke", {
		Parent = esp_box,
		Color = themes.preset.accent,
		LineJoinMode = Enum.LineJoinMode.Miter,
		Thickness = 1,
	})

	local esp_skeleton = {}
	local bone_defs = {
		{0.50, 0.12, 0.50, 0.18},
		{0.50, 0.18, 0.50, 0.28},
		{0.50, 0.28, 0.50, 0.45},
		{0.50, 0.45, 0.50, 0.55},
		{0.50, 0.28, 0.30, 0.34},
		{0.50, 0.28, 0.70, 0.34},
		{0.30, 0.34, 0.18, 0.50},
		{0.70, 0.34, 0.82, 0.50},
		{0.50, 0.55, 0.38, 0.72},
		{0.50, 0.55, 0.62, 0.72},
		{0.38, 0.72, 0.35, 0.90},
		{0.62, 0.72, 0.65, 0.90},
	}
	for _, bd in ipairs(bone_defs) do
		local dx = (bd[3] - bd[1]) * BOX_W
		local dy = (bd[4] - bd[2]) * BOX_H
		local len = math.sqrt(dx * dx + dy * dy)
		local ang = math.deg(math.atan2(dy, dx))
		local bx = BOX_CX + (bd[1] - 0.5) * BOX_W
		local by = BOX_CY + (bd[2] - 0.5) * BOX_H
		local bone = library:create("Frame", {
			Parent = esp_overlay,
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(bx, 0, by, 0),
			Size = UDim2.new(0, len, 0, 1.5),
			BackgroundColor3 = themes.preset.accent,
			BorderSizePixel = 0,
			Rotation = ang,
			ZIndex = 13,
			Visible = false,
		})
		esp_skeleton[#esp_skeleton + 1] = bone
	end

	local esp_name = library:create("TextLabel", {
		Parent = esp_overlay,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(BOX_CX, 0, BOX_CY, -BOX_H / 2 - 4),
		BackgroundTransparency = 1,
		FontFace = library.font,
		Text = lp and lp.Name or "Player",
		TextColor3 = themes.preset.accent,
		TextStrokeTransparency = 0.3,
		TextSize = 12,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.new(0, 0, 0, 16),
		ZIndex = 14,
	})
	library:create("UIStroke", { Parent = esp_name, LineJoinMode = Enum.LineJoinMode.Miter })

	local esp_health_bg = library:create("Frame", {
		Parent = esp_overlay,
		Position = UDim2.new(BOX_CX, -BOX_W / 2 - 6, BOX_CY, -BOX_H / 2),
		Size = UDim2.new(0, 3, 0, BOX_H),
		BackgroundColor3 = Color3.new(0.0000, 0.0000, 0.0000),
		BorderSizePixel = 0,
		ZIndex = 11,
	})
	local esp_health = library:create("Frame", {
		Parent = esp_health_bg,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, 0),
		Size = UDim2.new(1, 0, 0.75, 0),
		BackgroundColor3 = Color3.new(0.0000, 0.7843, 0.3137),
		BorderSizePixel = 0,
		ZIndex = 12,
	})
	local esp_health_text = library:create("TextLabel", {
		Parent = esp_overlay,
		Position = UDim2.new(BOX_CX, -BOX_W / 2 - 34, BOX_CY, -8),
		Size = UDim2.fromOffset(28, 16),
		BackgroundTransparency = 1,
		FontFace = library.font,
		Text = "75 HP",
		TextColor3 = Color3.new(0.0000, 0.7843, 0.3137),
		TextStrokeTransparency = 0.3,
		TextSize = 11,
		ZIndex = 14,
		Visible = false,
	})

	local esp_armor_bg = library:create("Frame", {
		Parent = esp_overlay,
		Position = UDim2.new(BOX_CX, BOX_W / 2 + 3, BOX_CY, -BOX_H / 2),
		Size = UDim2.new(0, 3, 0, BOX_H),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BorderSizePixel = 0,
		ZIndex = 11,
		Visible = false,
	})
	local esp_armor = library:create("Frame", {
		Parent = esp_armor_bg,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, 0),
		Size = UDim2.new(1, 0, 0.6, 0),
		BackgroundColor3 = Color3.fromRGB(160, 156, 252),
		BorderSizePixel = 0,
		ZIndex = 12,
	})

	local esp_distance = library:create("TextLabel", {
		Parent = esp_overlay,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(BOX_CX, 0, BOX_CY, BOX_H / 2 + 4),
		BackgroundTransparency = 1,
		FontFace = library.font,
		Text = "42m",
		TextColor3 = themes.preset.accent,
		TextStrokeTransparency = 0.3,
		TextSize = 12,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.new(0, 0, 0, 16),
		ZIndex = 14,
	})
	library:create("UIStroke", { Parent = esp_distance, LineJoinMode = Enum.LineJoinMode.Miter })
	local esp_tool = library:create("TextLabel", {
		Parent = esp_overlay,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(BOX_CX, 0, BOX_CY, BOX_H / 2 + 18),
		BackgroundTransparency = 1,
		FontFace = library.font,
		Text = "[Equipped Tool]",
		TextColor3 = themes.preset.accent,
		TextStrokeTransparency = 0.3,
		TextSize = 12,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.new(0, 0, 0, 16),
		ZIndex = 14,
		Visible = false,
	})
	library:create("UIStroke", { Parent = esp_tool, LineJoinMode = Enum.LineJoinMode.Miter })

	local esp_tracer = library:create("Frame", {
		Parent = esp_overlay,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(BOX_CX, 0, 0.82, 0),
		Size = UDim2.new(0, 1, 0, 28),
		BackgroundColor3 = themes.preset.accent,
		BorderSizePixel = 0,
		ZIndex = 11,
	})

	local esp_preview_gradients = {
		box = library:create("UIGradient", { Parent = esp_box_stroke, Enabled = false }),
		fill = library:create("UIGradient", { Parent = esp_box_fill, Enabled = false }),
		name = library:create("UIGradient", { Parent = esp_name, Enabled = false }),
		distance = library:create("UIGradient", { Parent = esp_distance, Enabled = false }),
		tool = library:create("UIGradient", { Parent = esp_tool, Enabled = false }),
		healthText = library:create("UIGradient", { Parent = esp_health_text, Enabled = false }),
		tracer = library:create("UIGradient", { Parent = esp_tracer, Enabled = false }),
		chams = {},
		skeleton = {},
	}
	local esp_preview_gradient_cache = setmetatable({}, { __mode = "k" })
	for _, bodyPart in ipairs(esp_chams_parts) do
		esp_preview_gradients.chams[#esp_preview_gradients.chams + 1] = library:create("UIGradient", { Parent = bodyPart, Enabled = false })
	end
	for _, bone in ipairs(esp_skeleton) do
		esp_preview_gradients.skeleton[#esp_preview_gradients.skeleton + 1] = library:create("UIGradient", { Parent = bone, Enabled = false })
	end

	local function update_preview_gradient(gradient, enabled, c1, c2, c3, angle)
		gradient.Enabled = enabled == true
		if not gradient.Enabled then return end
		local cache = esp_preview_gradient_cache[gradient]
		if not cache then
			cache = {}
			esp_preview_gradient_cache[gradient] = cache
		end
		if cache.c1 ~= c1 or cache.c2 ~= c2 or cache.c3 ~= c3 then
			gradient.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, c1),
				ColorSequenceKeypoint.new(0.5, c2),
				ColorSequenceKeypoint.new(1, c3),
			})
			cache.c1, cache.c2, cache.c3 = c1, c2, c3
		end
		if cache.angle == nil or math.abs(cache.angle - angle) >= 0.5 then
			gradient.Rotation = angle
			cache.angle = angle
		end
	end

	function cfg.update_esp_preview()
		if not esp_preview.Visible then return end
		if not (Config and Config.ESP) then return end
		local esp = Config.ESP
		local cols = esp.Colors or {}
		local accent = themes.preset.accent
		local enabled = esp.Enabled == true
		local box = enabled and esp.BoxESP == true
		local box_outline = box and esp.BoxOutline ~= false
		local box_fill = box and esp.BoxFilled == true
		local chams = enabled and esp.ChamsEnabled == true
		local name = enabled and esp.NameESP == true
		local health = enabled and esp.HealthESP == true
		local distance = enabled and esp.ShowDistance == true
		local tracer = enabled and esp.TracerESP == true
		local skeleton = enabled and esp.SkeletonESP == true
		local armor = enabled and esp.ArmorESP == true
		local tool = enabled and esp.ToolESP == true
		local health_style = tostring(esp.HealthStyle or "Bar")
		local health_bar = health and health_style ~= "Text"
		local health_text = health and health_style ~= "Bar"
		local box_color = cols.Box or accent
		local box_fill_color = cols.BoxFill or Color3.new(0.3922, 0.3922, 0.3922)
		local box_outline_color = cols.BoxOutline or Color3.new(0.0000, 0.0000, 0.0000)
		local text_color = cols.Text or accent
		local health_color = cols.HealthHigh or Color3.new(0.0000, 0.7843, 0.3137)
		local distance_color = cols.Distance or accent
		local tracer_color = cols.Tracer or accent
		local chams_color = cols.Chams or accent
		local skeleton_color = cols.Skeleton or accent
		local box_thickness = esp.BoxThickness or 1
		local box_outline_thickness = esp.BoxOutlineThickness or 3

		esp_box.Visible = box
		esp_box_outline.Enabled = box_outline
		esp_box_fill.Visible = box_fill
		esp_chams_frame.Visible = chams
		esp_name.Visible = name
		esp_name.Text = (lp and lp.DisplayName) or "Player"
		esp_health_bg.Visible = health_bar
		esp_health_text.Visible = health_text
		esp_armor_bg.Visible = armor
		esp_distance.Visible = distance
		esp_tool.Visible = tool
		esp_tracer.Visible = tracer
		for _, b in ipairs(esp_skeleton) do
			b.Visible = skeleton
		end

		esp_box_stroke.Color = box_color
		esp_box_fill.BackgroundColor3 = box_fill_color
		esp_box_outline.Color = box_outline_color
		esp_name.TextColor3 = text_color
		esp_health.BackgroundColor3 = health_color
		esp_health_text.TextColor3 = health_color
		esp_armor.BackgroundColor3 = esp.ArmorColor or Color3.fromRGB(160, 156, 252)
		esp_distance.TextColor3 = distance_color
		esp_tool.TextColor3 = cols.Text or accent
		esp_tracer.BackgroundColor3 = tracer_color
		for _, bodyPart in ipairs(esp_chams_parts) do
			bodyPart.BackgroundColor3 = chams_color
			bodyPart.BackgroundTransparency = math.clamp(tonumber(esp.ChamsTransparency) or 0.25, 0, 1)
		end
		for _, b in ipairs(esp_skeleton) do
			b.BackgroundColor3 = skeleton_color
		end

		esp_box_stroke.Thickness = box_thickness
		esp_box_outline.Thickness = box_outline_thickness

		local gradientAngle = tonumber(esp.GradientAngle) or 45
		if esp.GradientRotateEnabled then
			gradientAngle = (gradientAngle + os.clock() * (tonumber(esp.GradientRotateSpeed) or 30)) % 360
		end
		local gradientMaster = esp.GradientEnabled == true
		local ga, gb, gc = esp.GradientA or accent, esp.GradientB or accent, esp.GradientC or esp.GradientB or accent
		update_preview_gradient(esp_preview_gradients.box, gradientMaster or esp.BoxGradientEnabled, esp.BoxGradientColor1 or ga, esp.BoxGradientColor2 or gb, esp.BoxGradientColor3 or gc, gradientAngle)
		update_preview_gradient(esp_preview_gradients.fill, gradientMaster or esp.BoxFillGradientEnabled, esp.BoxFillGradientColor1 or ga, esp.BoxFillGradientColor2 or gb, esp.BoxFillGradientColor3 or gc, gradientAngle)
		update_preview_gradient(esp_preview_gradients.name, gradientMaster or esp.NamesGradientEnabled, esp.NamesGradientColor1 or ga, esp.NamesGradientColor2 or gb, esp.NamesGradientColor3 or gc, gradientAngle)
		update_preview_gradient(esp_preview_gradients.distance, gradientMaster or esp.DistanceGradientEnabled, esp.DistanceGradientColor1 or ga, esp.DistanceGradientColor2 or gb, esp.DistanceGradientColor3 or gc, gradientAngle)
		update_preview_gradient(esp_preview_gradients.tool, gradientMaster or esp.ToolsGradientEnabled, esp.ToolsGradientColor1 or ga, esp.ToolsGradientColor2 or gb, esp.ToolsGradientColor3 or gc, gradientAngle)
		update_preview_gradient(esp_preview_gradients.healthText, gradientMaster or esp.HealthTextGradientEnabled, esp.HealthTextGradientColor1 or ga, esp.HealthTextGradientColor2 or gb, esp.HealthTextGradientColor3 or gc, gradientAngle)
		update_preview_gradient(esp_preview_gradients.tracer, gradientMaster or esp.TracerGradientEnabled, esp.TracerGradientColor1 or ga, esp.TracerGradientColor2 or gb, esp.TracerGradientColor3 or gc, gradientAngle)
		for _, gradient in ipairs(esp_preview_gradients.chams) do
			update_preview_gradient(gradient, gradientMaster or esp.ChamsGradientEnabled, esp.ChamsGradientColor1 or ga, esp.ChamsGradientColor2 or gb, esp.ChamsGradientColor3 or gc, gradientAngle)
		end
		for _, gradient in ipairs(esp_preview_gradients.skeleton) do
			update_preview_gradient(gradient, gradientMaster or esp.SkeletonGradientEnabled, esp.SkeletonGradientColor1 or ga, esp.SkeletonGradientColor2 or gb, esp.SkeletonGradientColor3 or gc, gradientAngle)
		end
	end

	local _esp_update_elapsed = 0
	library:connection(run_service.Heartbeat, function(dt)
		if esp_preview.Visible then
			_esp_update_elapsed = _esp_update_elapsed + dt
			if _esp_update_elapsed >= (1/12) then
				_esp_update_elapsed = 0
				cfg.update_esp_preview()
			end
		end
	end)

	local esp_accent = library:create("Frame", {
		Parent = esp_preview,
		BorderColor3 = Color3.new(0.1333, 0.1333, 0.1333),
		Size = UDim2.new(1, 0, 0, 2),
		BorderSizePixel = 0,
		BackgroundColor3 = themes.preset.accent,
	})
	library:apply_theme(esp_accent, "accent", "BackgroundColor3")

	library:create("Frame", {
		Parent = esp_preview,
		BackgroundTransparency = 0.5,
		Position = UDim2.new(0, 0, 0, 1),
		BorderColor3 = Color3.new(0.0000, 0.0000, 0.0000),
		Size = UDim2.new(1, 0, 0, 1),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.new(0.0000, 0.0000, 0.0000),
	})

	local esp_glow = library:create("ImageLabel", {
		Parent = esp_preview,
		ImageColor3 = themes.preset.accent,
		ScaleType = Enum.ScaleType.Slice,
		ImageTransparency = 0.9,
		BorderColor3 = Color3.new(0.0000, 0.0000, 0.0000),
		BackgroundColor3 = Color3.new(1.0000, 1.0000, 1.0000),
		Image = "http://www.roblox.com/asset/?id=18245826428",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, -20, 0, -20),
		Size = UDim2.new(1, 40, 0, 42),
		ZIndex = 2,
		BorderSizePixel = 0,
		SliceCenter = Rect.new(Vector2.new(21, 21), Vector2.new(79, 79)),
	})
	library:apply_theme(esp_glow, "accent", "ImageColor3")

	task.wait()

	local selected_button
	local selected_player
	local player_buttons = {}

	function library.get_priority(player)
		return player_buttons[player.Name] and player_buttons[player.Name].priority.Text or "Neutral"
	end

	local playerlist = library:create("Frame", {
		Parent = library.gui,
		Name = "",
		Active = true,
		Draggable = false,
		AnchorPoint = Vector2.new(0, 0),
		Position = UDim2.new(0, inline1.AbsolutePosition.X - 358 - 8, 0, inline1.AbsolutePosition.Y + 1),
		BorderColor3 = Color3.new(0.0314, 0.0314, 0.0314),
		Size = UDim2.new(0, 358, 0, 328),
		BackgroundColor3 = Color3.new(0.2196, 0.2196, 0.2196),
		ZIndex = 4,
		FrostedTransparency = 0.88,
	})
	library:make_draggable(playerlist, {
		on_move = function(frame) persist_overlay_position(frame, "PlayerListX", "PlayerListY") end,
		on_end = function(frame) persist_overlay_position(frame, "PlayerListX", "PlayerListY") end,
	})
	library:make_resizable(playerlist)
	table.insert(library.main_frame, playerlist)

	library:create("TextLabel", {
		Parent = playerlist,
		FontFace = library.font,
		TextColor3 = Color3.new(0.6667, 0.6667, 0.6667),
		BorderColor3 = Color3.new(0.0000, 0.0000, 0.0000),
		Text = "playerlist",
		TextStrokeTransparency = 0.5,
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, -1),
		Size = UDim2.new(1, 0, 0, 1),
		ZIndex = 2,
		TextSize = 12,
		BackgroundColor3 = Color3.new(1.0000, 1.0000, 1.0000),
	})

	local pl_main = library:create("Frame", {
		Parent = playerlist,
		Position = UDim2.new(0, 4, 0, 4),
		BorderColor3 = Color3.new(0.1020, 0.1020, 0.1020),
		Size = UDim2.new(1, -8, 1, -8),
		BorderSizePixel = 2,
		BackgroundColor3 = Color3.new(0.1020, 0.1020, 0.1020),
		FrostedTransparency = 0.97,
	})

	library:create("UIStroke", { Parent = pl_main, Color = Color3.new(0.2235, 0.2235, 0.2235), LineJoinMode = Enum.LineJoinMode.Miter })

	local pl_tabs = library:create("Frame", {
		Parent = pl_main,
		Position = UDim2.new(0, 8, 0, 8),
		BorderColor3 = Color3.new(0.0314, 0.0314, 0.0314),
		Size = UDim2.new(1, -16, 1, -16),
		BorderSizePixel = 2,
		BackgroundColor3 = Color3.new(0.0863, 0.0863, 0.0863),
		FrostedTransparency = 0.92,
	})

	library:create("UIStroke", { Parent = pl_tabs, Color = Color3.new(0.2235, 0.2235, 0.2235), LineJoinMode = Enum.LineJoinMode.Miter })

	local pl_list = library:create("Frame", {
		Parent = pl_tabs,
		Position = UDim2.new(0, 14, 0, 14),
		BorderColor3 = Color3.new(0.0000, 0.0000, 0.0000),
		Size = UDim2.new(1, -28, 0.75, -28),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.new(0.0314, 0.0314, 0.0314),
		FrostedTransparency = 0.98,
	})

	local pl_inline = library:create("Frame", { Parent = pl_list, Position = UDim2.new(0,1,0,1), BorderSizePixel=0, Size=UDim2.new(1,-2,1,-2), BackgroundColor3=Color3.new(0.2235, 0.2235, 0.2235), FrostedTransparency=0.99 })
	local pl_bg = library:create("Frame", { Parent = pl_inline, Position = UDim2.new(0,1,0,1), BorderSizePixel=0, Size=UDim2.new(1,-2,1,-2), BackgroundColor3=Color3.new(0.0863, 0.0863, 0.0863), FrostedTransparency=0.98 })
	library:create("UIGradient", { Parent = pl_bg, Rotation=90, Color=ColorSequence.new({ ColorSequenceKeypoint.new(0,Color3.new(1.0000, 1.0000, 1.0000)), ColorSequenceKeypoint.new(1,Color3.new(0.6549, 0.6549, 0.6549)) }) })
	local pl_contrast = library:create("Frame", { Parent = pl_bg, BorderSizePixel=0, Size=UDim2.new(1,0,1,0), BackgroundColor3=Color3.new(0.0863, 0.0863, 0.0863), FrostedTransparency=0.94 })

	local __ScrollingFrame = library:create("ScrollingFrame", {
		Parent = pl_contrast,
		ScrollBarImageColor3 = themes.preset.accent,
		MidImage = "rbxassetid://18406573371",
		Active = true,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 2,
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Color3.new(1.0000, 1.0000, 1.0000),
		TopImage = "rbxassetid://18406573371",
		BorderColor3 = Color3.new(0.0000, 0.0000, 0.0000),
		BackgroundTransparency = 1,
		BottomImage = "rbxassetid://18406573371",
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(0, 0, 0, 0),
	})
	library:apply_theme(__ScrollingFrame, "accent", "ScrollBarImageColor3")

	library:create("UIPadding", { Parent = __ScrollingFrame, PaddingTop=UDim.new(0,4), PaddingBottom=UDim.new(0,4), PaddingRight=UDim.new(0,4), PaddingLeft=UDim.new(0,4) })
	library:create("UIListLayout", { Parent = __ScrollingFrame, Padding=UDim.new(0,4), SortOrder=Enum.SortOrder.LayoutOrder })

	local info_frame = library:create("Frame", {
		Parent = pl_tabs,
		Position = UDim2.new(0, 14, 0.75, -5),
		BorderColor3 = Color3.new(0.0000, 0.0000, 0.0000),
		Size = UDim2.new(1, -28, 0.3, -23),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.new(0.0314, 0.0314, 0.0314),
		FrostedTransparency = 0.96,
	})

	local info_inline = library:create("Frame", { Parent=info_frame, Position=UDim2.new(0,1,0,1), BorderSizePixel=0, Size=UDim2.new(1,-2,1,-2), BackgroundColor3=Color3.new(0.2235, 0.2235, 0.2235), FrostedTransparency=0.99 })
	local info_bg = library:create("Frame", { Parent=info_inline, Position=UDim2.new(0,1,0,1), BorderSizePixel=0, Size=UDim2.new(1,-2,1,-2), BackgroundColor3=Color3.new(0.0863, 0.0863, 0.0863), FrostedTransparency=0.98 })
	library:create("UIGradient", { Parent=info_bg, Rotation=90, Color=ColorSequence.new({ ColorSequenceKeypoint.new(0,Color3.new(1.0000, 1.0000, 1.0000)), ColorSequenceKeypoint.new(1,Color3.new(0.6549, 0.6549, 0.6549)) }) })
	local info_contrast = library:create("Frame", { Parent=info_bg, BorderSizePixel=0, Size=UDim2.new(1,0,1,0), BackgroundColor3=Color3.new(0.0863, 0.0863, 0.0863), FrostedTransparency=0.94 })

	local InfoScrollingFrame = library:create("ScrollingFrame", {
		Parent = info_contrast,
		ScrollBarImageColor3 = Color3.new(0.6078, 0.4902, 0.6863),
		Active = true,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 3,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(0, 0, 0, 0),
	})

	library:create("UIPadding", { Parent=InfoScrollingFrame, PaddingTop=UDim.new(0,7), PaddingBottom=UDim.new(0,4), PaddingRight=UDim.new(0,4), PaddingLeft=UDim.new(0,10) })
	library:create("UIListLayout", { Parent=InfoScrollingFrame, Padding=UDim.new(0,4), SortOrder=Enum.SortOrder.LayoutOrder })

	local function make_info_label(text)
		local lbl = library:create("TextLabel", {
			Parent = InfoScrollingFrame,
			FontFace = library.font,
			TextColor3 = Color3.new(0.7059, 0.7059, 0.7059),
			Text = text,
			BorderSizePixel = 0,
			BackgroundTransparency = 1,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			AutomaticSize = Enum.AutomaticSize.XY,
			TextSize = 12,
			BackgroundColor3 = Color3.new(1.0000, 1.0000, 1.0000),
		})
		library:create("UIStroke", { Parent = lbl })
		return lbl
	end

	local display_name_label = make_info_label("Display Name: ...")
	local name_label         = make_info_label("Name: ...")
	local priority_label     = make_info_label("Priority: Friendly")

	local btn_frame = library:create("Frame", {
		Parent = info_contrast,
		AnchorPoint = Vector2.new(1, 0),
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -10, 0, 0),
		BorderSizePixel = 0,
		Size = UDim2.new(1, -200, 1, 0),
		BackgroundColor3 = Color3.new(1.0000, 1.0000, 1.0000),
	})

	library:create("UIListLayout", { Parent=btn_frame, VerticalAlignment=Enum.VerticalAlignment.Center, SortOrder=Enum.SortOrder.LayoutOrder, HorizontalAlignment=Enum.HorizontalAlignment.Center, HorizontalFlex=Enum.UIFlexAlignment.Fill, Padding=UDim.new(0,4) })

	local function make_priority_btn(label, on_click)
		local bi = library:create("Frame", { Parent=btn_frame, Position=UDim2.new(0,-15,0,2), BorderColor3=Color3.new(0.0745, 0.0745, 0.0745), Size=UDim2.new(1,-26,0,16), BorderSizePixel=0, BackgroundColor3=Color3.new(0.0314, 0.0314, 0.0314), FrostedTransparency=0.97 })
		local b  = library:create("TextButton", { Parent=bi, FontFace=library.font, TextColor3=Color3.new(0.6667, 0.6667, 0.6667), BorderColor3=Color3.new(0.2196, 0.2196, 0.2196), Text=label, TextStrokeTransparency=0.5, Position=UDim2.new(0,2,0,2), Size=UDim2.new(1,-4,1,-4), TextSize=12, BackgroundColor3=Color3.new(0.1490, 0.1490, 0.1490), FrostedTransparency=0.86 })
		b.MouseButton1Click:Connect(on_click)
		return b
	end

	make_priority_btn("Neutral", function()
		if not selected_player then return end
		player_buttons[selected_player.Name].priority.Text = "Neutral"
		player_buttons[selected_player.Name].priority.TextColor3 = rgb(180,180,180)
		priority_label.Text = "Priority: Neutral"
	end)

	make_priority_btn("Friendly", function()
		if not selected_player then return end
		player_buttons[selected_player.Name].priority.Text = "Friendly"
		player_buttons[selected_player.Name].priority.TextColor3 = rgb(15,179,255)
		priority_label.Text = "Priority: Friendly"
	end)

	make_priority_btn("Enemy", function()
		if not selected_player then return end
		player_buttons[selected_player.Name].priority.Text = "Enemy"
		player_buttons[selected_player.Name].priority.TextColor3 = rgb(255,44,44)
		priority_label.Text = "Priority: Enemy"
	end)

	local pl_accent = library:create("Frame", { Parent=playerlist, BorderColor3=Color3.new(0.1333, 0.1333, 0.1333), Size=UDim2.new(1,0,0,2), BorderSizePixel=0, BackgroundColor3=themes.preset.accent })
	library:apply_theme(pl_accent, "accent", "BackgroundColor3")

	library:create("Frame", { Parent=playerlist, BackgroundTransparency=0.5, Position=UDim2.new(0,0,0,1), BorderColor3=Color3.new(0.0000, 0.0000, 0.0000), Size=UDim2.new(1,0,0,1), BorderSizePixel=0, BackgroundColor3=Color3.new(0.0000, 0.0000, 0.0000) })

	local pl_glow = library:create("ImageLabel", { Parent=playerlist, ImageColor3=themes.preset.accent, ScaleType=Enum.ScaleType.Slice, ImageTransparency=0.9, BorderSizePixel=0, BackgroundColor3=Color3.new(1.0000, 1.0000, 1.0000), Image="http://www.roblox.com/asset/?id=18245826428", BackgroundTransparency=1, Position=UDim2.new(0,-20,0,-20), Size=UDim2.new(1,40,0,42), ZIndex=2, SliceCenter=Rect.new(Vector2.new(21,21),Vector2.new(79,79)) })
	library:apply_theme(pl_glow, "accent", "ImageColor3")

	local function create_player(player)
		local TextButton = library:create("TextButton", {
			Parent = __ScrollingFrame,
			FontFace = library.font,
			TextColor3 = Color3.new(0.7059, 0.7059, 0.7059),
			Text = "",
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 0),
			BorderSizePixel = 0,
			AutomaticSize = Enum.AutomaticSize.Y,
			TextSize = 12,
			BackgroundColor3 = Color3.new(1.0000, 1.0000, 1.0000),
		})

		player_buttons[player.Name] = { instance = TextButton }

		local function make_col_label(text, align)
			local lbl = library:create("TextLabel", {
				Parent = TextButton,
				FontFace = library.font,
				TextColor3 = Color3.new(0.7059, 0.7059, 0.7059),
				Text = text,
				BorderSizePixel = 0,
				BackgroundTransparency = 1,
				TextXAlignment = align or Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				AutomaticSize = Enum.AutomaticSize.Y,
				TextSize = 12,
				BackgroundColor3 = Color3.new(1.0000, 1.0000, 1.0000),
			})
			library:create("UIStroke", { Parent = lbl })
			return lbl
		end

		make_col_label(player.DisplayName)

		local team_lbl = make_col_label(player.Team and tostring(player.Team) or "None")
		library:create("Frame", { Parent=team_lbl, Position=UDim2.new(0,-10,0,0), BorderSizePixel=0, Size=UDim2.new(0,1,0,12), BackgroundColor3=Color3.new(0.1255, 0.1255, 0.1490) })

		local prio_lbl = make_col_label("Neutral")
		player_buttons[player.Name].priority = prio_lbl
		library:create("Frame", { Parent=prio_lbl, Position=UDim2.new(0,-10,0,0), BorderSizePixel=0, Size=UDim2.new(0,1,0,12), BackgroundColor3=Color3.new(0.1255, 0.1255, 0.1490) })

		library:create("UIListLayout", { Parent=TextButton, FillDirection=Enum.FillDirection.Horizontal, HorizontalFlex=Enum.UIFlexAlignment.Fill, SortOrder=Enum.SortOrder.LayoutOrder, VerticalFlex=Enum.UIFlexAlignment.Fill })
		library:create("UIPadding", { Parent=TextButton, PaddingRight=UDim.new(0,2), PaddingLeft=UDim.new(0,2) })

		TextButton.MouseButton1Click:Connect(function()
			if selected_button then
				selected_button.BackgroundTransparency = 1
			end

			selected_button = TextButton
			selected_player = player
			TextButton.BackgroundColor3 = Color3.fromRGB(38, 40, 52)
			TextButton.BackgroundTransparency = 0.88

			priority_label.Text   = "Priority: " .. library.get_priority(player)
			name_label.Text        = "Name: " .. player.Name
			display_name_label.Text = "Display: " .. player.DisplayName
		end)
	end

	for _, player in next, players:GetPlayers() do
		create_player(player)
	end

	library:connection(players.PlayerAdded, function(player)
		create_player(player)
	end)

	library:connection(players.PlayerRemoving, function(player)
		if player_buttons[player.Name] then
			player_buttons[player.Name].instance:Destroy()
			player_buttons[player.Name] = nil
		end
		if selected_player == player then
			selected_player = nil
			selected_button = nil
		end
	end)

	task.wait()

	local old_kblist = library:create("Frame", {
		Parent = library.gui,
		BorderColor3 = Color3.new(0.0745, 0.0745, 0.0745),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 20, 0.5, 0),
		ZIndex = 4,
		Active = true,
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundColor3 = Color3.new(0.1569, 0.1569, 0.1569),
	})
	library:make_draggable(old_kblist)

	local kb_glow = library:create("ImageLabel", { Parent=old_kblist, ImageColor3=themes.preset.accent, ScaleType=Enum.ScaleType.Slice, ImageTransparency=0.9, BorderSizePixel=0, BackgroundColor3=Color3.new(1.0000, 1.0000, 1.0000), Image="http://www.roblox.com/asset/?id=18245826428", BackgroundTransparency=1, Position=UDim2.new(0,-20,0,-20), Size=UDim2.new(1,40,0,42), ZIndex=2, SliceCenter=Rect.new(Vector2.new(21,21),Vector2.new(79,79)) })
	library:apply_theme(kb_glow, "accent", "ImageColor3")

	local kb_inline1 = library:create("Frame", { Parent=old_kblist, BorderColor3=Color3.new(0.0000, 0.0000, 0.0000), AutomaticSize=Enum.AutomaticSize.XY, BackgroundColor3=Color3.new(0.1569, 0.1569, 0.1569) })
	local kb_accent  = library:create("Frame", { Parent=kb_inline1, BorderColor3=Color3.new(0.1333, 0.1333, 0.1333), Size=UDim2.new(1,0,0,2), BorderSizePixel=0, BackgroundColor3=themes.preset.accent })
	library:apply_theme(kb_accent, "accent", "BackgroundColor3")

	library:create("TextLabel", { Parent=kb_inline1, FontFace=library.font, TextColor3=Color3.new(0.6667, 0.6667, 0.6667), Text="keybinds", TextStrokeTransparency=0.5, BorderSizePixel=0, BackgroundTransparency=1, Position=UDim2.new(0,0,0,-1), Size=UDim2.new(1,0,0,1), ZIndex=2, TextSize=12, BackgroundColor3=Color3.new(1.0000, 1.0000, 1.0000) })

	local kb_inline2 = library:create("Frame", { Parent=kb_inline1, Position=UDim2.new(0,2,0,2), BorderSizePixel=0, Size=UDim2.new(1,-4,1,-4), BackgroundColor3=Color3.new(0.1020, 0.1020, 0.1020) })
	local kb_main    = library:create("Frame", { Parent=kb_inline2, Position=UDim2.new(0,2,0,2), BorderColor3=Color3.new(0.2235, 0.2235, 0.2235), Size=UDim2.new(1,-4,1,-4), BackgroundColor3=Color3.new(0.1020, 0.1020, 0.1020) })
	local kb_ti      = library:create("Frame", { Parent=kb_main, Position=UDim2.new(0,6,0,6), BorderColor3=Color3.new(0.0745, 0.0745, 0.0745), Size=UDim2.new(1,-12,1,-12), BorderSizePixel=0, BackgroundColor3=Color3.new(0.0745, 0.0745, 0.0745) })
	local kb_tabs    = library:create("Frame", { Parent=kb_ti, Position=UDim2.new(0,2,0,2), BorderColor3=Color3.new(0.2196, 0.2196, 0.2196), Size=UDim2.new(1,-4,1,-4), BackgroundColor3=Color3.new(0.0863, 0.0863, 0.0863) })

	library:create("UIPadding", { Parent=kb_tabs, PaddingBottom=UDim.new(0,22), PaddingRight=UDim.new(0,20), PaddingLeft=UDim.new(0,20) })
	library:create("UIListLayout", { Parent=kb_tabs, SortOrder=Enum.SortOrder.LayoutOrder, HorizontalAlignment=Enum.HorizontalAlignment.Center, Padding=UDim.new(0,3) })
	library:create("UIStroke", { Parent=kb_tabs, Color=Color3.new(0.2235, 0.2235, 0.2235), LineJoinMode=Enum.LineJoinMode.Miter })
	library:create("Frame", { Parent=kb_inline1, BorderColor3=Color3.new(0.0000, 0.0000, 0.0000), BackgroundTransparency=0.5, Position=UDim2.new(0,0,0,1), Size=UDim2.new(1,0,0,1), ZIndex=2, BorderSizePixel=0, BackgroundColor3=Color3.new(0.0000, 0.0000, 0.0000) })

	library.keybind_path = kb_tabs

	function cfg.toggle_list(bool)
		old_kblist.Visible = bool
	end

	function cfg.toggle_playerlist(bool)
		playerlist.Visible = bool
	end

	function cfg.toggle_watermark(bool)
		__holder.Visible = bool
	end

	function cfg.toggle_esp_preview(bool)
		esp_preview.Visible = bool
		if bool then task.defer(cfg.update_esp_preview) end
	end

	function cfg.get_esp_preview_frame()
		return esp_preview
	end

	function cfg.set_esp_preview_font(fontName)
		local choices = {
			UI = Enum.Font.SourceSans,
			System = Enum.Font.Gotham,
			Plex = Enum.Font.RobotoMono,
			Monospace = Enum.Font.RobotoMono,
			Code = Enum.Font.Code,
			Roboto = Enum.Font.Roboto,
			Gotham = Enum.Font.Gotham,
			Arial = Enum.Font.Arial,
			Verdana = Enum.Font.Legacy,
		}
		local ok, face = pcall(Font.fromEnum, choices[tostring(fontName)] or Enum.Font.SourceSans)
		if not ok then face = library.font end
		for _, descendant in ipairs(esp_preview:GetDescendants()) do
			if descendant:IsA("TextLabel") or descendant:IsA("TextButton") or descendant:IsA("TextBox") then
				descendant.FontFace = face
			end
		end
	end

	function cfg.capture_overlay_positions(target)
		target = target or {}
		local function capture(frame, xKey, yKey)
			if frame then
				target[xKey] = frame.Position.X.Offset
				target[yKey] = frame.Position.Y.Offset
			end
		end
		capture(wm_inline1, "WatermarkX", "WatermarkY")
		capture(esp_preview, "ESPPreviewX", "ESPPreviewY")
		capture(playerlist, "PlayerListX", "PlayerListY")
		local keyLogger = _KL_REF
		local fpsPing = _FP_REF
		if keyLogger and keyLogger.holder then capture(keyLogger.holder, "KeyloggerX", "KeyloggerY") end
		if fpsPing and fpsPing.holder then capture(fpsPing.holder, "FPSPingX", "FPSPingY") end
		return target
	end

	function cfg.apply_overlay_positions(source)
		if type(source) ~= "table" then return end
		local function apply(frame, xKey, yKey)
			local x, y = tonumber(source[xKey]), tonumber(source[yKey])
			if frame and x and y then frame.Position = UDim2.fromOffset(x, y) end
		end
		apply(wm_inline1, "WatermarkX", "WatermarkY")
		apply(esp_preview, "ESPPreviewX", "ESPPreviewY")
		apply(playerlist, "PlayerListX", "PlayerListY")
		local keyLogger = _KL_REF
		local fpsPing = _FP_REF
		if keyLogger and keyLogger.holder then apply(keyLogger.holder, "KeyloggerX", "KeyloggerY") end
		if fpsPing and fpsPing.holder then apply(fpsPing.holder, "FPSPingX", "FPSPingY") end
		if keyLogger and source.KeyloggerX and source.KeyloggerY then
			keyLogger.position = Vector2.new(source.KeyloggerX, source.KeyloggerY)
		end
		if fpsPing and source.FPSPingX and source.FPSPingY then
			fpsPing.position = Vector2.new(source.FPSPingX, source.FPSPingY)
		end
	end

	function cfg.toggle_inventory(bool)
		if library._inventory_viewer then
			library._inventory_viewer.set_visible(bool)
		end
	end

	function cfg.set_wm_animation(style)
		wm_anim_style     = style or "type"
		watermark_elapsed = 0
		watermark_index   = 1
		wm_reveal_progress = 0
		wm_name.TextTransparency = 0
		wm_name.TextStrokeTransparency = 0.28
		set_watermark_gradient_enabled(string.lower(tostring(wm_anim_style)) == "wave")
		wm_name.Text = cfg.name
		fit_watermark()
	end

	function cfg.set_menu_visibility(bool)
		if library._suppress_ui then
			bool = false
		end
		if not bool and library.current_element_open then
			library.current_element_open.set_visible(false)
			library.current_element_open.open = false
			library.current_element_open = nil
		end
		WINDOW_PATH.Visible = bool
		playerlist.Visible  = flags["player_list"] and bool or false
		esp_preview.Visible = flags["ui_esp_preview"] and bool or false
		if library._inventory_viewer then
			library._inventory_viewer.set_visible(flags["ui_inventory"] or false)
		end
		library.panel_open  = bool
		library:set_bg_visible(bool)

		for _, entry in ipairs(library.curve_boxes) do
			local outer = entry.outer
			local enabled = entry.enabled_flag
			if outer then

				outer.Visible = bool and (enabled == nil or flags[enabled] == true)
			end
		end
	end

	local KEY_SIZE = 30
	local KEY_SPACING = 6
	local C_KEY_OFF   = Color3.new(0.1098, 0.1098, 0.1098)
	local C_KEY_OFF_B = Color3.new(0.1490, 0.1490, 0.1490)
	local OV_BG_OUTER  = Color3.new(0.1569, 0.1569, 0.1569)
	local OV_BG_INNER1 = Color3.new(0.1020, 0.1020, 0.1020)
	local OV_BG_INNER2 = Color3.new(0.0863, 0.0863, 0.0863)
	local KEYSTROKE_FONT = Font.fromEnum(Enum.Font.GothamMedium)

	local KL = {
		enabled     = false,
		initialized = false,
		visible     = false,
		position    = Vector2.new(20, 400),
		keys        = {},
		cps         = { M1 = {}, M2 = {} },
		keycode_to_key = {
			[Enum.KeyCode.W]     = "W",
			[Enum.KeyCode.A]     = "A",
			[Enum.KeyCode.S]     = "S",
			[Enum.KeyCode.D]     = "D",
			[Enum.KeyCode.Space] = "SPC",
		},
		frames      = {},
		holder      = nil,
		accent_bar  = nil,
	}
	_KL_REF = KL
	getgenv().KeyLogger = KL

	local function make_key_cell(parent, label, col, row)
		local x = col * (KEY_SIZE + KEY_SPACING)
		local y = row * (KEY_SIZE + KEY_SPACING)

		local cell_outer = library:create("Frame", {
			Parent = parent, Name = label .. "_outer",
			Position = UDim2.fromOffset(x, y),
			Size     = UDim2.fromOffset(KEY_SIZE, KEY_SIZE),
			BackgroundColor3 = C_KEY_OFF, BorderSizePixel = 0,
			FrostedTransparency = 0.92, CornerRadius = 3,
		})
		local cell_inner = library:create("Frame", {
			Parent = cell_outer, Name = label .. "_inner",
			Position = UDim2.new(0, 2, 0, 2),
			Size     = UDim2.new(1, -4, 1, -4),
			BackgroundColor3 = C_KEY_OFF_B, BorderSizePixel = 0,
			FrostedTransparency = 0.86, CornerRadius = 2,
		})

		local cell_bar = library:create("Frame", {
			Parent = cell_inner, Name = label .. "_bar",
			Size = UDim2.new(1, 0, 0, 1),
			BackgroundColor3 = themes.preset.accent, BorderSizePixel = 0,
		})
		library:apply_theme(cell_bar, "accent", "BackgroundColor3")
		local cell_lbl = library:create("TextLabel", {
			Parent = cell_inner, Name = label .. "_lbl",
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			FontFace = library.font,
			Text = label, TextSize = 12,
			TextColor3 = Color3.new(0.6667, 0.6667, 0.6667),
			TextStrokeTransparency = 0.5,
			BorderSizePixel = 0,
		})
		return { outer = cell_outer, inner = cell_inner, bar = cell_bar, lbl = cell_lbl }
	end

	local _kl_built = false
	local function build_keystroke_ui()
		if _kl_built then return end
		_kl_built = true

		local cfg_g = getgenv().Config
		if cfg_g and cfg_g.Overlays then
			local sx = tonumber(cfg_g.Overlays.KeyloggerX)
			local sy = tonumber(cfg_g.Overlays.KeyloggerY)
			if sx and sy then KL.position = Vector2.new(sx, sy) end
		end

		local SPC_W = KEY_SIZE * 3.25 + KEY_SPACING
		local CPS_H = 10
		local ROWS  = 4
		local GRID_W = KEY_SIZE * 3 + KEY_SPACING * 2
		local GRID_H = KEY_SIZE * ROWS + KEY_SPACING * (ROWS - 1) + CPS_H + KEY_SPACING
		local PANEL_W = GRID_W + 16 + 8
		local PANEL_H = GRID_H + 16 + 10

		local kl_outer = library:create("Frame", {
			Parent   = library.gui,
			Position = UDim2.fromOffset(KL.position.X, KL.position.Y),
			Size     = UDim2.fromOffset(PANEL_W, PANEL_H),
			BackgroundTransparency = 1,
			BorderSizePixel  = 0, ZIndex = 4, Visible = false,
		})
		library:make_draggable(kl_outer)

		local kl_inline1 = library:create("Frame", {
			Parent = kl_outer, Position = UDim2.new(0, 2, 0, 2),
			Size = UDim2.new(1, -4, 1, -4),
			BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 5,
		})
	local kl_inline2 = library:create("Frame", {
		Parent = kl_inline1, Position = UDim2.new(0, 2, 0, 2),
		Size = UDim2.new(1, -4, 1, -4),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		BorderColor3 = Color3.new(0.2235, 0.2235, 0.2235), ZIndex = 6,
	})

		local kl_canvas = library:create("Frame", {
			Parent = kl_inline2, Position = UDim2.new(0, 8, 0, 8),
			Size = UDim2.new(1, -16, 1, -16),
			BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 7,
		})

		KL.frames = {}

		KL.frames["W"]   = make_key_cell(kl_canvas, "W",   1, 0)

		KL.frames["A"]   = make_key_cell(kl_canvas, "A",   0, 1)
		KL.frames["S"]   = make_key_cell(kl_canvas, "S",   1, 1)
		KL.frames["D"]   = make_key_cell(kl_canvas, "D",   2, 1)

		local spc_x = math.floor((GRID_W - SPC_W) / 2)
		local spc_y = 2 * (KEY_SIZE + KEY_SPACING)
		local spc_outer = library:create("Frame", {
			Parent = kl_canvas, Name = "SPC_outer",
			Position = UDim2.fromOffset(spc_x, spc_y),
			Size     = UDim2.fromOffset(SPC_W, KEY_SIZE),
			BackgroundColor3 = C_KEY_OFF, BorderSizePixel = 0,
			FrostedTransparency = 0.92, CornerRadius = 3,
		})
		local spc_inner = library:create("Frame", {
			Parent = spc_outer, Name = "SPC_inner",
			Position = UDim2.new(0, 2, 0, 2),
			Size     = UDim2.new(1, -4, 1, -4),
			BackgroundColor3 = C_KEY_OFF_B, BorderSizePixel = 0,
			FrostedTransparency = 0.86, CornerRadius = 2,
		})
		local spc_bar = library:create("Frame", {
			Parent = spc_inner, Name = "SPC_bar",
			Size = UDim2.new(1, 0, 0, 1),
			BackgroundColor3 = themes.preset.accent, BorderSizePixel = 0,
		})
		library:apply_theme(spc_bar, "accent", "BackgroundColor3")

		library:create("Frame", {
			Parent = spc_inner, Name = "SPC_midline",
			Position = UDim2.new(0.1, 0, 0.5, -1),
			Size = UDim2.new(0.8, 0, 0, 1),
			BackgroundColor3 = Color3.new(0.2353, 0.2353, 0.2353), BorderSizePixel = 0,
		})
		local spc_lbl = library:create("TextLabel", {
			Parent = spc_inner, Name = "SPC_lbl",
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			FontFace = library.font,
			Text = "", TextSize = 12,
			TextColor3 = Color3.new(0.6667, 0.6667, 0.6667),
			TextStrokeTransparency = 0.5,
			BorderSizePixel = 0,
		})
		KL.frames["SPC"] = { outer = spc_outer, inner = spc_inner, bar = spc_bar, lbl = spc_lbl }

		local m_row_y = 3 * (KEY_SIZE + KEY_SPACING)

		local m1_x = 0
		local m1_outer = library:create("Frame", {
			Parent = kl_canvas, Name = "M1_outer",
			Position = UDim2.fromOffset(m1_x, m_row_y),
			Size     = UDim2.fromOffset(KEY_SIZE, KEY_SIZE),
			BackgroundColor3 = C_KEY_OFF, BorderSizePixel = 0,
			FrostedTransparency = 0.92, CornerRadius = 3,
		})
		local m1_inner = library:create("Frame", {
			Parent = m1_outer, Name = "M1_inner",
			Position = UDim2.new(0, 2, 0, 2),
			Size     = UDim2.new(1, -4, 1, -4),
			BackgroundColor3 = C_KEY_OFF_B, BorderSizePixel = 0,
			FrostedTransparency = 0.86, CornerRadius = 2,
		})
		local m1_bar = library:create("Frame", {
			Parent = m1_inner, Name = "M1_bar",
			Size = UDim2.new(1, 0, 0, 1),
			BackgroundColor3 = themes.preset.accent, BorderSizePixel = 0,
		})
		library:apply_theme(m1_bar, "accent", "BackgroundColor3")
		local m1_lbl = library:create("TextLabel", {
			Parent = m1_inner, Name = "M1_lbl",
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			FontFace = library.font,
			Text = "M1", TextSize = 12,
			TextColor3 = Color3.new(0.6667, 0.6667, 0.6667),
			TextStrokeTransparency = 0.5,
			BorderSizePixel = 0,
		})
		KL.frames["M1"] = { outer = m1_outer, inner = m1_inner, bar = m1_bar, lbl = m1_lbl }

		local m1_cps_lbl = library:create("TextLabel", {
			Parent = kl_canvas, Name = "M1_cps",
			Position = UDim2.fromOffset(m1_x, m_row_y + KEY_SIZE + 2),
			Size     = UDim2.fromOffset(KEY_SIZE, CPS_H),
			BackgroundTransparency = 1,
			FontFace = library.font,
			Text = "0 cps", TextSize = 10,
			TextColor3 = Color3.new(0.4706, 0.4706, 0.4706),
			TextStrokeTransparency = 0.5,
			BorderSizePixel = 0,
		})
		KL.frames["M1_cps"] = m1_cps_lbl

		local m2_x = GRID_W - KEY_SIZE
		local m2_outer = library:create("Frame", {
			Parent = kl_canvas, Name = "M2_outer",
			Position = UDim2.fromOffset(m2_x, m_row_y),
			Size     = UDim2.fromOffset(KEY_SIZE, KEY_SIZE),
			BackgroundColor3 = C_KEY_OFF, BorderSizePixel = 0,
			FrostedTransparency = 0.92, CornerRadius = 3,
		})
		local m2_inner = library:create("Frame", {
			Parent = m2_outer, Name = "M2_inner",
			Position = UDim2.new(0, 2, 0, 2),
			Size     = UDim2.new(1, -4, 1, -4),
			BackgroundColor3 = C_KEY_OFF_B, BorderSizePixel = 0,
			FrostedTransparency = 0.86, CornerRadius = 2,
		})
		local m2_bar = library:create("Frame", {
			Parent = m2_inner, Name = "M2_bar",
			Size = UDim2.new(1, 0, 0, 1),
			BackgroundColor3 = themes.preset.accent, BorderSizePixel = 0,
		})
		library:apply_theme(m2_bar, "accent", "BackgroundColor3")
		local m2_lbl = library:create("TextLabel", {
			Parent = m2_inner, Name = "M2_lbl",
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			FontFace = library.font,
			Text = "M2", TextSize = 12,
			TextColor3 = Color3.new(0.6667, 0.6667, 0.6667),
			TextStrokeTransparency = 0.5,
			BorderSizePixel = 0,
		})
		KL.frames["M2"] = { outer = m2_outer, inner = m2_inner, bar = m2_bar, lbl = m2_lbl }

		local m2_cps_lbl = library:create("TextLabel", {
			Parent = kl_canvas, Name = "M2_cps",
			Position = UDim2.fromOffset(m2_x, m_row_y + KEY_SIZE + 2),
			Size     = UDim2.fromOffset(KEY_SIZE, CPS_H),
			BackgroundTransparency = 1,
			FontFace = library.font,
			Text = "0 cps", TextSize = 10,
			TextColor3 = Color3.new(0.4706, 0.4706, 0.4706),
			TextStrokeTransparency = 0.5,
			BorderSizePixel = 0,
		})
		KL.frames["M2_cps"] = m2_cps_lbl

		local _cps_elapsed = 0
		library:connection(run_service.Heartbeat, function(dt)
			if not KL.visible then return end
			_cps_elapsed = _cps_elapsed + dt
			if _cps_elapsed < 0.25 then return end
			_cps_elapsed = 0
			local now = tick()
			local window = 1

			for _, btn in ipairs({"M1", "M2"}) do
				local t = KL.cps[btn]
				local i = 1
				while i <= #t do
					if now - t[i] > window then
						table.remove(t, i)
					else
						i = i + 1
					end
				end
				local cps_lbl = KL.frames[btn .. "_cps"]
				if cps_lbl and cps_lbl.Parent then
					cps_lbl.Text = #t .. " cps"
				end
			end
		end)

		KL.holder      = kl_outer
		KL.initialized = true
	end

	local KEYBOARD_ROWS = {
		{{"Escape", "ESC", 1.25}, {"F1", "F1"}, {"F2", "F2"}, {"F3", "F3"}, {"F4", "F4"}, {"F5", "F5"}, {"F6", "F6"}, {"F7", "F7"}, {"F8", "F8"}, {"F9", "F9"}, {"F10", "F10"}, {"F11", "F11"}, {"F12", "F12"}},
		{{"Backquote", "`"}, {"One", "1"}, {"Two", "2"}, {"Three", "3"}, {"Four", "4"}, {"Five", "5"}, {"Six", "6"}, {"Seven", "7"}, {"Eight", "8"}, {"Nine", "9"}, {"Zero", "0"}, {"Minus", "-"}, {"Equals", "="}, {"Backspace", "BS", 2}},
		{{"Tab", "TAB", 1.5}, {"Q", "Q"}, {"W", "W"}, {"E", "E"}, {"R", "R"}, {"T", "T"}, {"Y", "Y"}, {"U", "U"}, {"I", "I"}, {"O", "O"}, {"P", "P"}, {"LeftBracket", "["}, {"RightBracket", "]"}, {"BackSlash", "\\", 1.5}},
		{{"CapsLock", "CAPS", 1.8}, {"A", "A"}, {"S", "S"}, {"D", "D"}, {"F", "F"}, {"G", "G"}, {"H", "H"}, {"J", "J"}, {"K", "K"}, {"L", "L"}, {"Semicolon", ";"}, {"Quote", "'"}, {"Return", "ENTER", 2.2}},
		{{"LeftShift", "SHIFT", 2.3}, {"Z", "Z"}, {"X", "X"}, {"C", "C"}, {"V", "V"}, {"B", "B"}, {"N", "N"}, {"M", "M"}, {"Comma", ","}, {"Period", "."}, {"Slash", "/"}, {"RightShift", "SHIFT", 2.7}},
		{{"LeftControl", "CTRL", 1.5}, {"LeftSuper", "WIN", 1.3}, {"LeftAlt", "ALT", 1.3}, {"Space", "SPACE", 6}, {"RightAlt", "ALT", 1.3}, {"RightSuper", "WIN", 1.3}, {"Menu", "MENU", 1.3}, {"RightControl", "CTRL", 1.5}},
	}
	local MEDAL_KEYBOARD_ROWS = {
		{{"Escape", 1.05}, {"One", 1}, {"Two", 1}, {"Three", 1}, {"Four", 1}, {"Five", 1}},
		{{"Tab", 1.25}, {"Q", 1}, {"W", 1}, {"E", 1}, {"R", 1}, {"T", 1}},
		{{"CapsLock", 1.45}, {"A", 1}, {"S", 1}, {"D", 1}, {"F", 1}, {"G", 1}},
		{{"LeftShift", 1.65}, {"Z", 1}, {"X", 1}, {"C", 1}, {"V", 1}, {"B", 1}},
		{{"LeftControl", 1.35}, {"LeftAlt", 1.2}, {"Space", 3.9}},
	}
	local KEYBOARD_DEFAULTS = {
		Escape=true, One=true, Two=true, Three=true, Four=true, Five=true,
		Tab=true, Q=true, W=true, E=true, R=true, T=true,
		CapsLock=true, A=true, S=true, D=true, F=true, G=true,
		LeftShift=true, Z=true, X=true, C=true, V=true, B=true,
		LeftControl=true, LeftAlt=true, Space=true, M1=true, M2=true,
	}
	local _keyboard_built = false
	local _key_selector = nil
	local refresh_keystroke_layout = nil

	local function selected_key_map()
		local selected = {}
		local config = getgenv().Config
		local saved = config and config.Overlays and config.Overlays.KeyloggerKeys
		if type(saved) == "table" and #saved > 0 then
			for _, id in ipairs(saved) do selected[tostring(id)] = true end
		else
			for id in pairs(KEYBOARD_DEFAULTS) do selected[id] = true end
		end
		return selected
	end

	local function save_selected_keys()
		local config = getgenv().Config
		if not config then return end
		config.Overlays = config.Overlays or {}
		local saved = {}
		for id, enabled in pairs(KL.selected or {}) do if enabled then saved[#saved + 1] = id end end
		table.sort(saved)
		config.Overlays.KeyloggerKeys = saved
	end

	local function set_key_selected(id, enabled)
		KL.selected = KL.selected or {}
		if enabled then
			local count = 0
			for _, active in pairs(KL.selected) do if active then count = count + 1 end end
			if count >= 60 and not KL.selected[id] then return false end
			KL.selected[id] = true
		else
			KL.selected[id] = nil
		end
		if refresh_keystroke_layout then refresh_keystroke_layout() end
		save_selected_keys()
		return true
	end

	local function build_keyboard_keystroke_ui()
		if _keyboard_built then return end
		_keyboard_built = true
		if KL.holder and KL.holder.Parent then KL.holder:Destroy() end
		KL.frames = {}
		KL.keycode_to_key = {}
		KL.selected = selected_key_map()

		local unit, gap, keyHeight = 27, 4, 25
		local maxUnits = 0
		for _, row in ipairs(KEYBOARD_ROWS) do
			local units = 0
			for _, entry in ipairs(row) do units = units + (entry[3] or 1) end
			maxUnits = math.max(maxUnits, units)
		end
		local panelWidth = math.floor(maxUnits * unit + 18 * gap + 20)
		local panelHeight = #KEYBOARD_ROWS * (keyHeight + gap) + keyHeight + 22
		local config = getgenv().Config
		local ox = config and config.Overlays and tonumber(config.Overlays.KeyloggerX) or KL.position.X
		local oy = config and config.Overlays and tonumber(config.Overlays.KeyloggerY) or KL.position.Y
		local holder = library:create("Frame", {
			Parent=library.gui, Position=UDim2.fromOffset(ox, oy), Size=UDim2.fromOffset(panelWidth, panelHeight),
			BackgroundTransparency=1, BorderSizePixel=0, ZIndex=20, Visible=false, Active=true, Square=true,
		})
		-- Keep the medal layout inside its own translucent glass stack.  The
		-- holder stays invisible for dragging, while each panel layer adds depth.
		local panel_outer = library:create("Frame", {
			Parent=holder, Position=UDim2.fromOffset(0, 0), Size=UDim2.new(1, 0, 1, 0),
			BackgroundColor3=OV_BG_OUTER, BorderSizePixel=0, ZIndex=20,
			CornerRadius=5, FrostedTransparency=0.94,
		})
		local panel_inner = library:create("Frame", {
			Parent=panel_outer, Position=UDim2.fromOffset(2, 2), Size=UDim2.new(1, -4, 1, -4),
			BackgroundColor3=OV_BG_INNER1, BorderSizePixel=0, ZIndex=21,
			CornerRadius=4, FrostedTransparency=0.98,
		})
		local panel_surface = library:create("Frame", {
			Parent=panel_inner, Position=UDim2.fromOffset(2, 2), Size=UDim2.new(1, -4, 1, -4),
			BackgroundColor3=OV_BG_INNER2, BorderSizePixel=0, ZIndex=22,
			CornerRadius=3, FrostedTransparency=0.99,
		})
		local function save_keystroke_position(frame)
			KL.position = Vector2.new(frame.Position.X.Offset, frame.Position.Y.Offset)
			local cfgGlobal = getgenv().Config
			if cfgGlobal then cfgGlobal.Overlays = cfgGlobal.Overlays or {}; cfgGlobal.Overlays.KeyloggerX = frame.Position.X.Offset; cfgGlobal.Overlays.KeyloggerY = frame.Position.Y.Offset end
		end
		library:make_draggable(holder, { on_move = save_keystroke_position, on_end = save_keystroke_position })
		local canvas = library:create("Frame", {Parent=panel_surface, Position=UDim2.fromOffset(6,6), Size=UDim2.new(1,-12,1,-12), BackgroundTransparency=1, BorderSizePixel=0, ZIndex=23, Square=true})
		local y = 7
		for _, row in ipairs(KEYBOARD_ROWS) do
			local x = 7
			for _, entry in ipairs(row) do
				local id, label, width = entry[1], entry[2], entry[3] or 1
				local keyWidth = math.floor(unit * width + gap * math.max(width - 1, 0))
				local outer = library:create("Frame", {Parent=canvas, Position=UDim2.fromOffset(x,y), Size=UDim2.fromOffset(keyWidth,keyHeight), BackgroundColor3=C_KEY_OFF, BorderSizePixel=0, ZIndex=24, Visible=KL.selected[id] == true, CornerRadius=3, FrostedTransparency=0.92})
				library:create("UIStroke", {Parent=outer, ApplyStrokeMode=Enum.ApplyStrokeMode.Border, LineJoinMode=Enum.LineJoinMode.Round, Thickness=1, Color=rgb(88,88,104), Transparency=0.15})
				local inner = library:create("Frame", {Parent=outer, Position=UDim2.fromOffset(2,2), Size=UDim2.new(1,-4,1,-4), BackgroundColor3=C_KEY_OFF_B, BorderSizePixel=0, ZIndex=25, CornerRadius=2, FrostedTransparency=0.86})
				local bar = library:create("Frame", {Parent=inner, Size=UDim2.new(1,0,0,1), BackgroundColor3=themes.preset.accent, BorderSizePixel=0, BackgroundTransparency=1, ZIndex=26, Square=true})
				library:apply_theme(bar, "accent", "BackgroundColor3")
				local textSize = #label > 5 and 9 or (#label > 3 and 10 or 12)
				local textLabel = library:create("TextLabel", {Parent=inner, Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, FontFace=KEYSTROKE_FONT, Text=label, TextSize=textSize, TextColor3=rgb(214,208,205), TextStrokeTransparency=1, BorderSizePixel=0, ZIndex=26})
				KL.frames[id] = {outer=outer, inner=inner, bar=bar, lbl=textLabel}
				local enumItem = Enum.KeyCode[id]
				if enumItem then KL.keycode_to_key[enumItem] = id end
				x = x + keyWidth + gap
			end
			y = y + keyHeight + gap
		end
		for index, id in ipairs({"M1", "M2"}) do
			local x = 7 + (index - 1) * (unit * 2 + gap)
			local outer = library:create("Frame", {Parent=canvas, Position=UDim2.fromOffset(x,y), Size=UDim2.fromOffset(unit*2,keyHeight), BackgroundColor3=C_KEY_OFF, BorderSizePixel=0, ZIndex=24, Visible=KL.selected[id] == true, CornerRadius=3, FrostedTransparency=0.92})
			library:create("UIStroke", {Parent=outer, ApplyStrokeMode=Enum.ApplyStrokeMode.Border, LineJoinMode=Enum.LineJoinMode.Round, Thickness=1, Color=rgb(88,88,104), Transparency=0.15})
			local inner = library:create("Frame", {Parent=outer, Position=UDim2.fromOffset(2,2), Size=UDim2.new(1,-4,1,-4), BackgroundColor3=C_KEY_OFF_B, BorderSizePixel=0, ZIndex=25, CornerRadius=2, FrostedTransparency=0.86})
			local textLabel = library:create("TextLabel", {Parent=inner, Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, FontFace=KEYSTROKE_FONT, Text=id, TextSize=11, TextColor3=rgb(214,208,205), TextStrokeTransparency=1, BorderSizePixel=0, ZIndex=26})
			KL.frames[id] = {outer=outer,inner=inner,lbl=textLabel}
		end
		refresh_keystroke_layout = function()
			for _, frame in pairs(KL.frames) do frame.outer.Visible = false end
			local unit, keyHeight, gap, padding = 29, 27, 4, 7
			local coreKeys, coreWidth, y = {}, 0, 0
			for _, row in ipairs(MEDAL_KEYBOARD_ROWS) do
				local x = 0
				for _, entry in ipairs(row) do
					local id, widthUnits = entry[1], entry[2]
					coreKeys[id] = true
					if KL.selected[id] then
						local frame = KL.frames[id]
						if frame and frame.outer then
							local keyWidth = math.floor(unit * widthUnits)
							frame.outer.Position = UDim2.fromOffset(x, y)
							frame.outer.Size = UDim2.fromOffset(keyWidth, keyHeight)
							frame.outer.Visible = true
							x = x + keyWidth + gap
						end
					end
				end
				coreWidth = math.max(coreWidth, math.max(0, x - gap))
				y = y + keyHeight + gap
			end

			local mouseX = coreWidth + 10
			local mouseWidth = 48
			for index, id in ipairs({"M1", "M2"}) do
				local frame = KL.frames[id]
				if KL.selected[id] and frame and frame.outer then
					frame.outer.Position = UDim2.fromOffset(mouseX, (index - 1) * (keyHeight + gap))
					frame.outer.Size = UDim2.fromOffset(mouseWidth, keyHeight)
					frame.outer.Visible = true
				end
			end

			local extras = {}
			for _, row in ipairs(KEYBOARD_ROWS) do
				for _, entry in ipairs(row) do
					local id = entry[1]
					if KL.selected[id] and not coreKeys[id] then extras[#extras + 1] = id end
				end
			end
			local extraColumns, extraWidth = 6, 42
			if #extras > 0 then
				y = y + 3
				for index, id in ipairs(extras) do
					local frame = KL.frames[id]
					if frame and frame.outer then
						local column = (index - 1) % extraColumns
						local row = math.floor((index - 1) / extraColumns)
						frame.outer.Position = UDim2.fromOffset(column * (extraWidth + gap), y + row * (keyHeight + gap))
						frame.outer.Size = UDim2.fromOffset(extraWidth, keyHeight)
						frame.outer.Visible = true
					end
				end
				y = y + math.ceil(#extras / extraColumns) * (keyHeight + gap)
			end
			local totalWidth = math.max(coreWidth, #extras > 0 and extraColumns * extraWidth + (extraColumns - 1) * gap or 0)
			if KL.selected.M1 or KL.selected.M2 then totalWidth = math.max(totalWidth, mouseX + mouseWidth) end
			holder.Size = UDim2.fromOffset(padding * 2 + totalWidth, padding * 2 + math.max(y - gap, keyHeight))
		end
		refresh_keystroke_layout()
		getgenv().VNEO_REFRESH_KEYSTROKES = function()
			KL.selected = selected_key_map()
			refresh_keystroke_layout()
		end
		KL.holder, KL.initialized = holder, true
	end

	function cfg.open_keystroke_selector()
		build_keyboard_keystroke_ui()
		if not _key_selector or not _key_selector.Parent then
			local popup = library:create("Frame", {Parent=library.gui, AnchorPoint=Vector2.new(0.5,0.5), Position=UDim2.fromScale(0.5,0.5), Size=UDim2.fromOffset(520,360), BackgroundColor3=OV_BG_OUTER, BorderSizePixel=0, ZIndex=150, Active=true, CornerRadius=5, FrostedTransparency=0.90})
			library:create("TextLabel", {Parent=popup, Position=UDim2.fromOffset(14,8), Size=UDim2.new(1,-55,0,24), BackgroundTransparency=1, FontFace=library.font, Text="keystroke keys · select up to 60", TextColor3=rgb(205,203,220), TextSize=11, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=151})
			local close = library:create("TextButton", {Parent=popup, Position=UDim2.new(1,-35,0,7), Size=UDim2.fromOffset(27,24), BackgroundColor3=OV_BG_INNER1, BorderSizePixel=0, Text="×", TextColor3=rgb(170,168,180), TextSize=15, ZIndex=151, FrostedTransparency=0.84, AutoButtonColor=false})
			local scroll = library:create("ScrollingFrame", {Parent=popup, Position=UDim2.fromOffset(10,39), Size=UDim2.new(1,-20,1,-49), BackgroundColor3=OV_BG_INNER2, BorderSizePixel=0, ScrollBarThickness=3, AutomaticCanvasSize=Enum.AutomaticSize.Y, CanvasSize=UDim2.new(), ZIndex=151, CornerRadius=5, FrostedTransparency=0.92})
			library:create("UIGridLayout", {Parent=scroll, CellPadding=UDim2.fromOffset(5,5), CellSize=UDim2.fromOffset(92,27), SortOrder=Enum.SortOrder.LayoutOrder})
			local order = 0
			for _, row in ipairs(KEYBOARD_ROWS) do for _, entry in ipairs(row) do
				order = order + 1; local id, label = entry[1], entry[2]
				local button = library:create("TextButton", {Parent=scroll, LayoutOrder=order, BackgroundColor3=KL.selected[id] and themes.preset.accent or C_KEY_OFF_B, BorderSizePixel=0, Text=label, TextColor3=KL.selected[id] and rgb(18,17,24) or rgb(170,170,180), TextSize=9, ZIndex=152, FrostedTransparency=0.84, AutoButtonColor=false})
				button.MouseButton1Click:Connect(function() local enabled = not KL.selected[id]; if set_key_selected(id, enabled) then button.BackgroundColor3 = enabled and themes.preset.accent or C_KEY_OFF_B; button.TextColor3 = enabled and rgb(18,17,24) or rgb(170,170,180) end end)
			end end
			for _, id in ipairs({"M1","M2"}) do
				order = order + 1; local button = library:create("TextButton", {Parent=scroll, LayoutOrder=order, BackgroundColor3=KL.selected[id] and themes.preset.accent or C_KEY_OFF_B, BorderSizePixel=0, Text=id, TextColor3=KL.selected[id] and rgb(18,17,24) or rgb(170,170,180), TextSize=9, ZIndex=152, FrostedTransparency=0.84, AutoButtonColor=false})
				button.MouseButton1Click:Connect(function() local enabled = not KL.selected[id]; if set_key_selected(id, enabled) then button.BackgroundColor3 = enabled and themes.preset.accent or C_KEY_OFF_B; button.TextColor3 = enabled and rgb(18,17,24) or rgb(170,170,180) end end)
			end
			close.MouseButton1Click:Connect(function() popup.Visible = false end)
			library:make_draggable(popup)
			_key_selector = popup
		else
			_key_selector.Visible = true
		end
	end

	function cfg.toggle_keystroke(bool)
		if bool then
			build_keyboard_keystroke_ui()
		end
		KL.visible = bool
		if KL.holder then KL.holder.Visible = bool end
	end

	local FP = {
		enabled     = false,
		initialized = false,
		position    = Vector2.new(20, 20),
		fps         = 0,
		ping        = 0,
		holder      = nil,
		fps_lbl     = nil,
		ping_lbl    = nil,
		accent_bar  = nil,
	}
	_FP_REF = FP
	getgenv().FPSPing = FP

	local _fp_built = false
	local function build_fps_ping_ui()
		if _fp_built then return end
		_fp_built = true

		local cfg_g = getgenv().Config
		if cfg_g and cfg_g.Overlays then
			local sx = tonumber(cfg_g.Overlays.FPSPingX)
			local sy = tonumber(cfg_g.Overlays.FPSPingY)
			if sx and sy then FP.position = Vector2.new(sx, sy) end
		end

		local FP_W, FP_H = 130, 40

		local fp_outer = library:create("Frame", {
			Parent   = library.gui,
			Position = UDim2.fromOffset(FP.position.X, FP.position.Y),
			Size     = UDim2.fromOffset(FP_W, FP_H),
			BackgroundColor3 = OV_BG_OUTER,
			BorderSizePixel  = 0, ZIndex = 4,
		})
		local function save_fps_position(frame)
			persist_overlay_position(frame, "FPSPingX", "FPSPingY", FP)
		end
		library:make_draggable(fp_outer, { on_move = save_fps_position, on_end = save_fps_position })

		local fp_accent = library:create("Frame", {
			Parent = fp_outer, BackgroundColor3 = themes.preset.accent,
			Size = UDim2.new(1, 0, 0, 2), BorderSizePixel = 0, ZIndex = 5,
		})
		library:apply_theme(fp_accent, "accent", "BackgroundColor3")

		library:create("Frame", {
			Parent = fp_outer, BackgroundTransparency = 0.5,
			Position = UDim2.new(0, 0, 0, 1), Size = UDim2.new(1, 0, 0, 1),
			BorderSizePixel = 0, BackgroundColor3 = Color3.new(0.0000, 0.0000, 0.0000), ZIndex = 5,
		})

		local fp_glow = library:create("ImageLabel", {
			Parent = fp_accent, ImageColor3 = themes.preset.accent,
			ScaleType = Enum.ScaleType.Slice, ImageTransparency = 0.9,
			BorderSizePixel = 0, BackgroundTransparency = 1,
			BackgroundColor3 = Color3.new(1.0000, 1.0000, 1.0000),
			Image = "http://www.roblox.com/asset/?id=18245826428",
			Position = UDim2.new(0, -20, 0, -20), Size = UDim2.new(1, 40, 0, 42),
			ZIndex = 6, SliceCenter = Rect.new(Vector2.new(21, 21), Vector2.new(79, 79)),
		})
		library:apply_theme(fp_glow, "accent", "ImageColor3")

		local fp_inline1 = library:create("Frame", {
			Parent = fp_outer, Position = UDim2.new(0, 2, 0, 2),
			Size = UDim2.new(1, -4, 1, -4),
			BackgroundColor3 = OV_BG_INNER1, BorderSizePixel = 0, ZIndex = 5,
		})

		local fp_inline2 = library:create("Frame", {
			Parent = fp_inline1, Position = UDim2.new(0, 2, 0, 2),
			Size = UDim2.new(1, -4, 1, -4),
			BackgroundColor3 = OV_BG_INNER2,
			BorderColor3 = Color3.new(0.2235, 0.2235, 0.2235), ZIndex = 6,
		})

		local fp_content = library:create("Frame", {
			Parent = fp_inline2, Position = UDim2.new(0, 6, 0, 6),
			Size = UDim2.new(1, -12, 1, -12),
			BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 7,
		})

		local fps_lbl = library:create("TextLabel", {
			Parent = fp_content,
			Size = UDim2.new(0.5, -2, 1, 0), Position = UDim2.new(0, 0, 0, 0),
			BackgroundTransparency = 1, FontFace = library.font,
			Text = "fps: --", TextSize = 12,
			TextColor3 = Color3.new(0.6667, 0.6667, 0.6667),
			TextStrokeTransparency = 0.5,
			TextXAlignment = Enum.TextXAlignment.Left,
			BorderSizePixel = 0, ZIndex = 8,
		})

		library:create("Frame", {
			Parent = fp_content, Position = UDim2.new(0.5, -1, 0, 2),
			Size = UDim2.new(0, 1, 1, -4),
			BackgroundColor3 = Color3.new(0.1961, 0.1961, 0.1961),
			BorderSizePixel = 0, ZIndex = 8,
		})

		local ping_lbl = library:create("TextLabel", {
			Parent = fp_content,
			Size = UDim2.new(0.5, -2, 1, 0), Position = UDim2.new(0.5, 2, 0, 0),
			BackgroundTransparency = 1, FontFace = library.font,
			Text = "ping: --", TextSize = 12,
			TextColor3 = Color3.new(0.6667, 0.6667, 0.6667),
			TextStrokeTransparency = 0.5,
			TextXAlignment = Enum.TextXAlignment.Left,
			BorderSizePixel = 0, ZIndex = 8,
		})

		FP.holder      = fp_outer
		FP.fps_lbl     = fps_lbl
		FP.ping_lbl    = ping_lbl
		FP.accent_bar  = fp_accent
		FP.initialized = true
		FP._last_fps   = nil
		FP._last_ping  = nil
	end

	function cfg.toggle_fps_ping(bool)
		FP.enabled = bool
		if bool then
			build_fps_ping_ui()
		end
		if FP.holder then FP.holder.Visible = bool end
	end

	library:register_window_theme_frames()

	return setmetatable(cfg, library)
end

function library:new_keybind(properties)
	local cfg = {
		text = properties.name or properties.text or "aimbot",
		key = properties.key or nil,
		mode = properties.mode or "hold",
	}

	local keybind_text = library:create("TextLabel", {
		Parent = library.keybind_path,
		FontFace = library.font,
		LineHeight = 1.2,
		TextStrokeTransparency = 0.5,
		AnchorPoint = Vector2.new(0.5, 0),
		TextSize = 12,
		Size = UDim2.new(0, 0, 0, 11),
		TextColor3 = Color3.new(0.6667, 0.6667, 0.6667),
		Text = "",
		BackgroundTransparency = 1,
		Position = UDim2.new(0.5, 0, 0, 8),
		BorderSizePixel = 0,
		Visible = true,
		TextYAlignment = Enum.TextYAlignment.Top,
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = Color3.new(1.0000, 1.0000, 1.0000),
	})

	library:create("UIPadding", { Parent = keybind_text, PaddingTop = UDim.new(0, 6) })

	function cfg.set_visible(bool)
		keybind_text.Visible = bool
	end

	function cfg.change_text(text)
		keybind_text.Text = text
	end

	local function keyName(key)
		local text = tostring(key) ~= "Enums" and (keys[key] or tostring(key):gsub("Enum.", "")) or nil
		local __text = text and (tostring(text):gsub("KeyCode.", ""):gsub("UserInputType.", ""))
		return __text or "..."
	end

	function cfg.update(n_properties)
		cfg.change_text(
			"[" .. tostring(keyName(n_properties.key)) .. "] "
				.. tostring(n_properties.text) .. " ("
				.. tostring(n_properties.mode) .. ")"
		)
	end

	cfg.change_text(
		"[" .. tostring(keyName(cfg.key)) .. "] " .. tostring(cfg.text) .. " (" .. tostring(cfg.mode) .. ")"
	)

	return cfg
end

function library:notification(properties)
	local cfg = {
		time = properties.time or 5,
		text = properties.text or properties.name or "ledger.live is pasted",
	}

	function cfg:refresh_notifications()
		for idx, notif in next, library.notifications do
			tween_service:Create(
				notif,
				TweenInfo.new(0.3, Enum.EasingStyle.Exponential, Enum.EasingDirection.InOut),
				{ Position = dim2(0, 20, 0, 72 + (idx * 28)) }
			):Play()
		end
	end

	local holder = library:create("Frame", {
		Parent = library.gui,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 20, 0, 72 + (#library.notifications * 28)),
		ZIndex = 10,
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = Color3.new(0.1569, 0.1569, 0.1569),
		AnchorPoint = Vector2.new(1, 0),
	})

	local nt_inline1 = library:create("Frame", { Parent=holder, BorderColor3=Color3.new(0.0000, 0.0000, 0.0000), Size=UDim2.new(0,0,0,24), AutomaticSize=Enum.AutomaticSize.X, BackgroundColor3=Color3.new(0.1569, 0.1569, 0.1569) })
	local nt_inline2 = library:create("Frame", { Parent=nt_inline1, Position=UDim2.new(0,0,0,2), BorderSizePixel=0, Size=UDim2.new(1,-4,1,-4), BackgroundColor3=Color3.new(0.1020, 0.1020, 0.1020) })
	local nt_main    = library:create("Frame", { Parent=nt_inline2, Position=UDim2.new(0,2,0,2), BorderColor3=Color3.new(0.2235, 0.2235, 0.2235), Size=UDim2.new(1,-4,1,-4), BackgroundColor3=Color3.new(0.1020, 0.1020, 0.1020) })
	local nt_ti      = library:create("Frame", { Parent=nt_main, Position=UDim2.new(0,2,0,2), BorderColor3=Color3.new(0.0745, 0.0745, 0.0745), Size=UDim2.new(1,-4,1,-4), BorderSizePixel=0, BackgroundColor3=Color3.new(0.0745, 0.0745, 0.0745) })

	local nt_name = library:create("TextLabel", {
		Parent = nt_ti,
		FontFace = library.font,
		TextColor3 = Color3.new(0.6667, 0.6667, 0.6667),
		Text = cfg.text,
		TextStrokeTransparency = 0.5,
		Size = UDim2.new(0, 0, 1, 0),
		Position = UDim2.new(0, 8, 0, 0),
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left,
		BorderSizePixel = 0,
		AutomaticSize = Enum.AutomaticSize.X,
		TextSize = 12,
		BackgroundColor3 = Color3.new(1.0000, 1.0000, 1.0000),
	})
	library:create("UIPadding", { Parent=nt_ti, PaddingRight=UDim.new(0,14) })

	local nt_depth  = library:create("Frame", { Parent=nt_inline1, BorderSizePixel=0, BackgroundTransparency=0.5, Position=UDim2.new(0,1,0,0), Size=UDim2.new(0,1,1,0), ZIndex=2, BackgroundColor3=Color3.new(0.0000, 0.0000, 0.0000) })
	local nt_accent = library:create("Frame", { Parent=nt_inline1, BorderColor3=Color3.new(0.1333, 0.1333, 0.1333), Size=UDim2.new(0,2,1,0), BorderSizePixel=0, BackgroundColor3=themes.preset.accent })
	library:apply_theme(nt_accent, "accent", "BackgroundColor3")

	local nt_glow = library:create("ImageLabel", { Parent=holder, ImageColor3=themes.preset.accent, ScaleType=Enum.ScaleType.Slice, ImageTransparency=0.9, BorderSizePixel=0, BackgroundColor3=Color3.new(1.0000, 1.0000, 1.0000), Image="http://www.roblox.com/asset/?id=18245826428", BackgroundTransparency=1, Position=UDim2.new(0,-20,0,0), Size=UDim2.new(0,42,1,40), ZIndex=2, SliceCenter=Rect.new(Vector2.new(21,21),Vector2.new(79,79)) })
	library:apply_theme(nt_glow, "accent", "ImageColor3")

	local fade_targets = {
		{ instance = nt_name,    property = "TextTransparency",       value = 1 },
		{ instance = nt_inline1, property = "BackgroundTransparency", value = 1 },
		{ instance = nt_inline2, property = "BackgroundTransparency", value = 1 },
		{ instance = nt_main,    property = "BackgroundTransparency", value = 1 },
		{ instance = nt_ti,      property = "BackgroundTransparency", value = 1 },
		{ instance = nt_depth,   property = "BackgroundTransparency", value = 1 },
		{ instance = nt_accent,  property = "BackgroundTransparency", value = 1 },
		{ instance = nt_glow,    property = "ImageTransparency",      value = 1 },
	}

	task.spawn(function()
		tween_service:Create(holder, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), { AnchorPoint = Vector2.new(0, 0) }):Play()
		task.wait(cfg.time)
		tween_service:Create(holder, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), { AnchorPoint = Vector2.new(1, 0) }):Play()
		for _, target in ipairs(fade_targets) do
			tween_service:Create(target.instance, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), { [target.property] = target.value }):Play()
		end
	end)

	task.delay(cfg.time + 1.1, function()
		local idx = table.find(library.notifications, holder)
		if idx then table.remove(library.notifications, idx) end
		cfg:refresh_notifications()
		task.wait(0.1)
		if holder and holder.Parent then holder:Destroy() end
	end)

	table.insert(library.notifications, holder)
end

function library:tab(properties)
	local cfg = {
		name = properties.name or "tab",
		enabled = false,
		_web_tab = properties.name or "tab",
	}

	local TAB_BUTTON = library:create("TextButton", {
		Parent = self.tab_holder,
		FontFace = library.font,
		TextColor3 = themes.preset.unselected_text,
		Text = cfg.name,
		TextStrokeTransparency = 0.5,
		BackgroundTransparency = 1,
		Size = UDim2.new(0.333, -4, 0, 22),
		BorderSizePixel = 0,
		TextSize = 12,
		BackgroundColor3 = Color3.new(1.0000, 1.0000, 1.0000),
		AutoButtonColor = false,
	})

	local line = library:create("Frame", {
		Parent = TAB_BUTTON,
		Position = UDim2.new(0, 0, 1, 0),
		BorderColor3 = Color3.new(0.0000, 0.0000, 0.0000),
		Size = UDim2.new(1, 0, 0, 2),
		BorderSizePixel = 0,
		BackgroundColor3 = rgb(57, 57, 57),
		Visible = false,
	})
	library:apply_theme(line, "accent", "BackgroundColor3")

	local tab_glow = library:create("ImageLabel", {
		Parent = line,
		ImageColor3 = themes.preset.accent,
		ScaleType = Enum.ScaleType.Slice,
		ImageTransparency = 0.9,
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.new(1.0000, 1.0000, 1.0000),
		Image = "http://www.roblox.com/asset/?id=18245826428",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, -20, 0, -20),
		Size = UDim2.new(1, 40, 1, 40),
		ZIndex = 2,
		Visible = false,
		SliceCenter = Rect.new(Vector2.new(21, 21), Vector2.new(79, 79)),
	})
	library:apply_theme(tab_glow, "accent", "ImageColor3")

	library:create("Frame", {
		Parent = line,
		BackgroundTransparency = 0.5,
		Position = UDim2.new(0, 0, 0, 1),
		BorderColor3 = Color3.new(0.0000, 0.0000, 0.0000),
		Size = UDim2.new(1, 0, 0, 1),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.new(0.0000, 0.0000, 0.0000),
	})

	local TAB = library:create("Frame", {
		Parent = self.tab_instance_holder,
		Visible = false,
		BorderColor3 = Color3.new(0.0000, 0.0000, 0.0000),
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.new(1.0000, 1.0000, 1.0000),
	})

	local scrolling_columns = library:create("Frame", {
		Parent = TAB,
		ClipsDescendants = true,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 6, 0, 6),
		Size = UDim2.new(1, -12, 1, -12),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.new(1.0000, 1.0000, 1.0000),
	})

	cfg["column_holder"] = scrolling_columns

	library:create("UIListLayout", {
		Parent = scrolling_columns,
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalFlex = Enum.UIFlexAlignment.Fill,
		Padding = UDim.new(0, 5),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})

	local function make_column()
		local col = library:create("ScrollingFrame", {
			Parent = scrolling_columns,
			ScrollBarImageColor3 = Color3.new(0.0000, 0.0000, 0.0000),
			Active = true,
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollBarThickness = 0,
			Size = UDim2.new(0.5, 0, 1, 0),
			ClipsDescendants = false,
			BackgroundTransparency = 1,
			BackgroundColor3 = Color3.new(1.0000, 1.0000, 1.0000),
			BorderSizePixel = 0,
			CanvasSize = UDim2.new(0, 0, 0, 0),
		})

		col:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
			if library.current_element_open then
				library.current_element_open.set_visible(false)
				library.current_element_open.open = false
				library.current_element_open = nil
			end
		end)

		library:create("UIListLayout", { Parent=col, Padding=UDim.new(0,6), SortOrder=Enum.SortOrder.LayoutOrder })
		library:create("UIPadding", { Parent=col, PaddingBottom=UDim.new(0,15) })
		return col
	end

	cfg["left"]  = make_column()
	cfg["right"] = make_column()

	local function hide_tab()
		line.Visible = false
		tab_glow.Visible = false
		TAB_BUTTON.TextColor3 = themes.preset.unselected_text
		TAB.Visible = false
	end

	cfg._hide_tab = hide_tab

	function cfg.open_tab()
		-- Do not rely only on current_tab.  If a tab was shown during startup or
		-- after a config reload, every other tab still needs to be reset here.
		for _, entry in ipairs(library.nav_tabs) do
			if entry.cfg and entry.cfg._hide_tab then
				entry.cfg._hide_tab()
			end
		end

		library.current_tab = { TAB_BUTTON, TAB }

		line.BackgroundColor3 = themes.preset.accent
		line.Visible = true
		tab_glow.Visible = true
		TAB_BUTTON.TextColor3 = themes.preset.text
		TAB.Visible = true

		if library.current_element_open and library.current_element_open ~= cfg then
			library.current_element_open.set_visible(false)
			library.current_element_open.open = false
			library.current_element_open = nil
		end
	end

	TAB_BUTTON.MouseButton1Click:Connect(cfg.open_tab)

	function cfg:destroy()
		if TAB_BUTTON and TAB_BUTTON.Parent then TAB_BUTTON:Destroy() end
		if TAB and TAB.Parent then TAB:Destroy() end
		if library.current_tab and library.current_tab[1] == TAB_BUTTON then
			library.current_tab = nil
		end
	end

	cfg._nav_btn = TAB_BUTTON
	table.insert(library.nav_tabs, { cfg = cfg, btn = TAB_BUTTON })

	return setmetatable(cfg, library)
end

function library:section(properties)
	local sectionName = tostring(properties.name or properties.Name or "Section")
	local cfg = {
		name = string.upper(sectionName),
		side = properties.side or properties.Side or "left",
		_web_tab = self._web_tab or self.name or "General",
		_web_section = sectionName,
	}

	local parent = self[cfg.side] or self.holder

	local section_outer = library:create("Frame", {
		Parent = parent,
		BorderColor3 = Color3.new(0.0000, 0.0000, 0.0000),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 0),
		ZIndex = 2,
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Color3.new(1.0000, 1.0000, 1.0000),
	})

	local section_inline = library:create("Frame", {
		Parent = section_outer,
		Position = UDim2.new(0, 0, 0, 4),
		BorderColor3 = Color3.new(0.0745, 0.0745, 0.0745),
		Size = UDim2.new(1, 0, 1, -4),
		BorderSizePixel = 0,
		BackgroundColor3 = themes.preset.inline,
		FrostedTransparency = 0.98,
	})
	library:apply_theme(section_inline, "inline", "BackgroundColor3")

	library:create("TextLabel", {
		Parent = section_inline,
		FontFace = library.font,
		TextColor3 = Color3.new(0.6667, 0.6667, 0.6667),
		Text = cfg.name,
		TextStrokeTransparency = 0.5,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 8, 0, 0),
		ZIndex = 2,
		TextSize = 12,
		BackgroundColor3 = Color3.new(1.0000, 1.0000, 1.0000),
	})

	local sec_inner = library:create("Frame", {
		Parent = section_inline,
		Position = UDim2.new(0, 2, 0, 2),
		BorderColor3 = Color3.new(0.2196, 0.2196, 0.2196),
		Size = UDim2.new(1, -4, 1, -4),
		BackgroundColor3 = themes.preset.contrast,
		FrostedTransparency = 0.92,
	})
	library:apply_theme(sec_inner, "contrast", "BackgroundColor3")

	local elements = library:create("Frame", {
		Parent = sec_inner,
		Position = UDim2.new(0, 12, 0, 12),
		BorderColor3 = Color3.new(0.0000, 0.0000, 0.0000),
		Size = UDim2.new(1, -24, 0, 0),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.new(1.0000, 1.0000, 1.0000),
		FrostedTransparency = 0.98,
	})

	library:create("UIListLayout", { Parent=elements, SortOrder=Enum.SortOrder.LayoutOrder, HorizontalAlignment=Enum.HorizontalAlignment.Center, Padding=UDim.new(0,3) })
	library:create("UIPadding", { Parent=sec_inner, PaddingBottom=UDim.new(0,13) })

	cfg["holder"] = elements
	cfg["_outer"] = section_outer

	function cfg:destroy()
		if self._outer and self._outer.Parent then
			self._outer:Destroy()
		end
		self._outer = nil
		self.holder = nil
	end

	function cfg:AddGroupbox(Info)
		Info = Info or {}
		local Groupbox = {
			Name = Info.Name or "Groupbox",
			IsCurveBox = Info.CurveBox or false,
			Flag = Info.flag or Info.Flag or nil,
		}

		local grp_outer = library:create("Frame", {
			Parent = library.gui,
			Name = Info.Name or "CurveGroupbox",
			Active = true,
			Draggable = false,
			AnchorPoint = Vector2.new(0, 0),
			Position = Info.Position or UDim2.fromOffset(600, 120),
			Size = UDim2.fromOffset(280, 230),
			BackgroundColor3 = Color3.new(0.1569, 0.1569, 0.1569),
			BorderColor3 = Color3.new(0.0314, 0.0314, 0.0314),
			ZIndex = 10,
		})
		library:make_draggable(grp_outer)

		local grp_accent = library:create("Frame", {
			Parent = grp_outer,
			BorderColor3 = Color3.new(0.1333, 0.1333, 0.1333),
			Size = UDim2.new(1, 0, 0, 2),
			BorderSizePixel = 0,
			BackgroundColor3 = themes.preset.accent,
			ZIndex = 11,
		})
		library:apply_theme(grp_accent, "accent", "BackgroundColor3")

		library:create("Frame", {
			Parent = grp_outer,
			BackgroundTransparency = 0.5,
			Position = UDim2.new(0, 0, 0, 1),
			BorderColor3 = Color3.new(0.0000, 0.0000, 0.0000),
			Size = UDim2.new(1, 0, 0, 1),
			BorderSizePixel = 0,
			BackgroundColor3 = Color3.new(0.0000, 0.0000, 0.0000),
			ZIndex = 11,
		})

		local grp_glow = library:create("ImageLabel", {
			Parent = grp_outer,
			ImageColor3 = themes.preset.accent,
			ScaleType = Enum.ScaleType.Slice,
			ImageTransparency = 0.9,
			BorderColor3 = Color3.new(0.0000, 0.0000, 0.0000),
			BackgroundColor3 = Color3.new(1.0000, 1.0000, 1.0000),
			Image = "http://www.roblox.com/asset/?id=18245826428",
			BackgroundTransparency = 1,
			Position = UDim2.new(0, -20, 0, -20),
			Size = UDim2.new(1, 40, 0, 42),
			ZIndex = 11,
			BorderSizePixel = 0,
			SliceCenter = Rect.new(Vector2.new(21, 21), Vector2.new(79, 79)),
		})
		library:apply_theme(grp_glow, "accent", "ImageColor3")

		local grp_inline1 = library:create("Frame", {
			Parent = grp_outer,
			Position = UDim2.new(0, 2, 0, 2),
			BorderColor3 = Color3.new(0.0000, 0.0000, 0.0000),
			Size = UDim2.new(1, -4, 1, -4),
			BorderSizePixel = 0,
			BackgroundColor3 = Color3.new(0.1020, 0.1020, 0.1020),
			ZIndex = 11,
		})

		local grp_frame = library:create("Frame", {
			Parent = grp_inline1,
			Position = UDim2.new(0, 2, 0, 2),
			BorderColor3 = Color3.new(0.2235, 0.2235, 0.2235),
			Size = UDim2.new(1, -4, 1, -4),
			BackgroundColor3 = Color3.new(0.1020, 0.1020, 0.1020),
			ZIndex = 12,
		})

		local grp_tab = library:create("Frame", {
			Parent = grp_frame,
			Position = UDim2.new(0, 6, 0, 6),
			BorderColor3 = Color3.new(0.0745, 0.0745, 0.0745),
			Size = UDim2.new(1, -12, 1, -12),
			BorderSizePixel = 0,
			BackgroundColor3 = Color3.new(0.0745, 0.0745, 0.0745),
			ZIndex = 12,
		})

		local grp_inner = library:create("Frame", {
			Parent = grp_tab,
			Position = UDim2.new(0, 2, 0, 2),
			BorderColor3 = Color3.new(0.2196, 0.2196, 0.2196),
			Size = UDim2.new(1, -4, 1, -4),
			BackgroundColor3 = Color3.new(0.0863, 0.0863, 0.0863),
			ZIndex = 13,
		})

		library:create("TextLabel", {
			Parent = grp_inner,
			FontFace = library.font,
			TextColor3 = Color3.new(0.6667, 0.6667, 0.6667),
			Text = Info.Name or "",
			TextStrokeTransparency = 0.5,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 12),
			BackgroundTransparency = 1,
			TextXAlignment = Enum.TextXAlignment.Left,
			Position = UDim2.new(0, 8, 0, 2),
			ZIndex = 14,
			TextSize = 12,
			BackgroundColor3 = Color3.new(1.0000, 1.0000, 1.0000),
		})

		Groupbox.BoxOuter = grp_outer
		Groupbox.BoxInner = grp_inner

		if Info.CurveBox then
			table.insert(library.curve_boxes, {
				outer        = grp_outer,
				enabled_flag = Info.enabled_flag or nil,
			})
		end

		if Info.CurveBox then

			local canvas_outer = library:create("Frame", {
				Parent = grp_inner,
				Position = UDim2.new(0, 6, 0, 16),
				BorderColor3 = Color3.new(0.2196, 0.2196, 0.2196),
				Size = UDim2.new(1, -12, 0, 160),
				BackgroundColor3 = Color3.new(0.0745, 0.0745, 0.0745),
				ZIndex = 14,
			})

			local canvas_inner = library:create("Frame", {
				Parent = canvas_outer,
				Position = UDim2.new(0, 1, 0, 1),
				Size = UDim2.new(1, -2, 1, -2),
				BackgroundColor3 = Color3.new(0.0588, 0.0588, 0.0588),
				BorderSizePixel = 0,
			})

			local CurveCanvas = library:create("Frame", {
				Parent = canvas_inner,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 1, 0),
				ZIndex = 104,
				BorderSizePixel = 0,
			})

			local GridSize = 8
			for i = 1, GridSize - 1 do
				library:create("Frame", {
					Parent = CurveCanvas,
					BackgroundColor3 = Color3.new(0.1490, 0.1490, 0.1490),
					BorderSizePixel = 0,
					Position = UDim2.new(i / GridSize, 0, 0, 0),
					Size = UDim2.new(0, 1, 1, 0),
					ZIndex = 105,
				})
				library:create("Frame", {
					Parent = CurveCanvas,
					BackgroundColor3 = Color3.new(0.1490, 0.1490, 0.1490),
					BorderSizePixel = 0,
					Position = UDim2.new(0, 0, i / GridSize, 0),
					Size = UDim2.new(1, 0, 0, 1),
					ZIndex = 105,
				})
			end

			local CurvePoints  = {}
			local CurvePixels  = {}
			local PointCount   = GridSize + 1
			local PixelsPerSeg = 10

			for _ = 1, (PointCount - 1) * PixelsPerSeg do
				local px = library:create("Frame", {
					Parent = CurveCanvas,
					BackgroundColor3 = themes.preset.accent,
					BorderSizePixel = 0,
					Size = UDim2.fromOffset(2, 2),
					AnchorPoint = Vector2.new(0.5, 0.5),
					ZIndex = 106,
				})
				library:apply_theme(px, "accent", "BackgroundColor3")
				table.insert(CurvePixels, px)
			end

			local function UpdateCurve()
				local idx = 1
				for i = 1, PointCount - 1 do
					local p1 = CurvePoints[i]
					local p2 = CurvePoints[i + 1]
					if p1 and p2 then
						for j = 0, PixelsPerSeg - 1 do
							local t = j / PixelsPerSeg
							local x = p1.X + (p2.X - p1.X) * t
							local y = p1.Y + (p2.Y - p1.Y) * t
							if CurvePixels[idx] then
								CurvePixels[idx].Position = UDim2.new(x, 0, y, 0)
								idx = idx + 1
							end
						end
					end
				end
			end

			for i = 1, PointCount do
				local xPos = (i - 1) / GridSize
				local yPos = 0.5

				local PointFrame = library:create("Frame", {
					Parent = CurveCanvas,
					BackgroundColor3 = themes.preset.accent,
					BorderColor3 = Color3.new(0.0000, 0.0000, 0.0000),
					BorderSizePixel = 1,
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.new(xPos, 0, yPos, 0),
					Size = UDim2.fromOffset(7, 7),
					ZIndex = 107,
				})
				library:apply_theme(PointFrame, "accent", "BackgroundColor3")

				local Point = { Frame = PointFrame, X = xPos, Y = yPos, Index = i }

				PointFrame.InputBegan:Connect(function(Input)
					if Input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end

					library.active_drag = nil
					while uis:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do

						library.active_drag = nil
						local cp = CurveCanvas.AbsolutePosition
						local cs = CurveCanvas.AbsoluteSize
						local my = uis:GetMouseLocation().Y - gui_offset
						local relY = math.clamp((my - cp.Y) / cs.Y, 0, 1)
						Point.Y = relY
						PointFrame.Position = UDim2.new(Point.X, 0, Point.Y, 0)
						UpdateCurve()
						run_service.RenderStepped:Wait()
					end

					local pts = Groupbox:GetPoints()
					if Groupbox.Flag then
						flags[Groupbox.Flag] = pts
					end
					if Groupbox.OnChanged then
						Groupbox.OnChanged(pts)
					end
				end)

				table.insert(CurvePoints, Point)
			end

			UpdateCurve()
			CurveCanvas:GetPropertyChangedSignal("AbsoluteSize"):Connect(UpdateCurve)

			local btn_row = library:create("Frame", {
				Parent = grp_inner,
				Position = UDim2.new(0, 6, 0, 182),
				Size = UDim2.new(1, -12, 0, 18),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				BackgroundColor3 = Color3.new(1.0000, 1.0000, 1.0000),
				ZIndex = 14,
			})

			local reset_inline = library:create("Frame", {
				Parent = btn_row,
				BorderColor3 = Color3.new(0.0745, 0.0745, 0.0745),
				Size = UDim2.new(1, 0, 1, 0),
				BorderSizePixel = 0,
				BackgroundColor3 = Color3.new(0.0314, 0.0314, 0.0314),
				ZIndex = 14,
			})

			local reset_btn = library:create("TextButton", {
				Parent = reset_inline,
				FontFace = library.font,
				TextColor3 = Color3.new(0.6667, 0.6667, 0.6667),
				Text = "reset curve",
				TextStrokeTransparency = 0.5,
				Position = UDim2.new(0, 2, 0, 2),
				Size = UDim2.new(1, -4, 1, -4),
				TextSize = 12,
				BackgroundColor3 = Color3.new(0.1490, 0.1490, 0.1490),
				BorderColor3 = Color3.new(0.2196, 0.2196, 0.2196),
				ZIndex = 15,
			})

			reset_btn.MouseButton1Click:Connect(function()
				for _, pt in ipairs(CurvePoints) do
					pt.Y = 0.5
					pt.Frame.Position = UDim2.new(pt.X, 0, 0.5, 0)
				end
				UpdateCurve()
				local pts = Groupbox:GetPoints()
				if Groupbox.Flag then
					flags[Groupbox.Flag] = pts
				end
				if Groupbox.OnChanged then
					Groupbox.OnChanged(pts)
				end
			end)

			function Groupbox:GetPoints()
				local out = {}
				for _, pt in ipairs(CurvePoints) do
					table.insert(out, { x = pt.X, y = pt.Y })
				end
				return out
			end

			function Groupbox:SetCurvePoints(NewPoints)
				if type(NewPoints) ~= "table" then return end
				for i, pt in ipairs(CurvePoints) do
					if NewPoints[i] then
						pt.Y = tonumber(NewPoints[i].y or NewPoints[i].Y) or pt.Y
						pt.Frame.Position = UDim2.new(pt.X, 0, pt.Y, 0)
					end
				end
				UpdateCurve()
			end

			Groupbox.CurvePoints  = CurvePoints
			Groupbox.CurveCanvas  = CurveCanvas
			Groupbox.UpdateCurve  = UpdateCurve
		end

		return Groupbox
	end

	return setmetatable(cfg, library)
end

function library:hitpart_picker(properties)
	local cfg = {
		name     = properties.name or properties.Name or "Hitpart",
		side     = properties.side or properties.Side or "left",
		flag     = properties.flag or "Hitpart",
		default  = properties.default or { "Head" },
		type_char = properties.type or "R6",
		multi    = properties.multi or false,
		callback = properties.callback or function() end,
		alpha_callback = properties.alpha_callback,
	}

	flags[cfg.flag] = {}

	local bodyparts = {}
	local bools = {}

	local hp_holder = library:create("Frame", {
		Parent = self[cfg.side],
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 272),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.new(1.0000, 1.0000, 1.0000),
	})

	local hp_inline = library:create("Frame", {
		Parent = hp_holder,
		Position = UDim2.new(0, 0, 0, 4),
		BorderColor3 = Color3.new(0.0745, 0.0745, 0.0745),
		Size = UDim2.new(1, 0, 1, -4),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.new(0.0314, 0.0314, 0.0314),
	})

	local hp_frame = library:create("Frame", {
		Parent = hp_inline,
		Position = UDim2.new(0, 2, 0, 2),
		BorderColor3 = Color3.new(0.2196, 0.2196, 0.2196),
		Size = UDim2.new(1, -4, 1, -4),
		BackgroundColor3 = Color3.new(0.0863, 0.0863, 0.0863),
	})

	if cfg.type_char == "R15" then
		bodyparts.Head         = library:create("TextButton", { Text="", Parent=hp_frame, Position=UDim2.new(0.5,-25,0,16),  Size=UDim2.new(0,50,0,44),  BorderSizePixel=0, BackgroundColor3=Color3.new(0.1490, 0.1490, 0.1490) })
		bodyparts.UpperTorso   = library:create("TextButton", { Text="", Parent=hp_frame, Position=UDim2.new(0.5,-42,0,64),  Size=UDim2.new(0,84,0,76),  BorderSizePixel=0, BackgroundColor3=Color3.new(0.1490, 0.1490, 0.1490) })
		bodyparts.LeftUpperArm = library:create("TextButton", { Text="", Parent=hp_frame, Position=UDim2.new(0.5,-86,0,64),  Size=UDim2.new(0,40,0,34),  BorderSizePixel=0, BackgroundColor3=Color3.new(0.1490, 0.1490, 0.1490) })
		bodyparts.RightUpperArm= library:create("TextButton", { Text="", Parent=hp_frame, Position=UDim2.new(0.5, 46,0,64),  Size=UDim2.new(0,40,0,34),  BorderSizePixel=0, BackgroundColor3=Color3.new(0.1490, 0.1490, 0.1490) })
		bodyparts.LeftUpperLeg = library:create("TextButton", { Text="", Parent=hp_frame, Position=UDim2.new(0.5,-42,0,158), Size=UDim2.new(0,40,0,34),  BorderSizePixel=0, BackgroundColor3=Color3.new(0.1490, 0.1490, 0.1490) })
		bodyparts.LeftLowerLeg = library:create("TextButton", { Text="", Parent=hp_frame, Position=UDim2.new(0.5,-42,0,196), Size=UDim2.new(0,40,0,42),  BorderSizePixel=0, BackgroundColor3=Color3.new(0.1490, 0.1490, 0.1490) })
		bodyparts.RightFoot    = library:create("TextButton", { Text="", Parent=hp_frame, Position=UDim2.new(0.5,  2,0,242), Size=UDim2.new(0,40,0,6),   BorderSizePixel=0, BackgroundColor3=Color3.new(0.1490, 0.1490, 0.1490) })
		bodyparts.LeftFoot     = library:create("TextButton", { Text="", Parent=hp_frame, Position=UDim2.new(0.5,-42,0,242), Size=UDim2.new(0,40,0,6),   BorderSizePixel=0, BackgroundColor3=Color3.new(0.1490, 0.1490, 0.1490) })
		bodyparts.RightLowerLeg= library:create("TextButton", { Text="", Parent=hp_frame, Position=UDim2.new(0.5,  2,0,196), Size=UDim2.new(0,40,0,42),  BorderSizePixel=0, BackgroundColor3=Color3.new(0.1490, 0.1490, 0.1490) })
		bodyparts.RightUpperLeg= library:create("TextButton", { Text="", Parent=hp_frame, Position=UDim2.new(0.5,  2,0,158), Size=UDim2.new(0,40,0,34),  BorderSizePixel=0, BackgroundColor3=Color3.new(0.1490, 0.1490, 0.1490) })
		bodyparts.LeftHand     = library:create("TextButton", { Text="", Parent=hp_frame, Position=UDim2.new(0.5,-86,0,148), Size=UDim2.new(0,40,0,6),   BorderSizePixel=0, BackgroundColor3=Color3.new(0.1490, 0.1490, 0.1490) })
		bodyparts.RightHand    = library:create("TextButton", { Text="", Parent=hp_frame, Position=UDim2.new(0.5, 46,0,148), Size=UDim2.new(0,40,0,6),   BorderSizePixel=0, BackgroundColor3=Color3.new(0.1490, 0.1490, 0.1490) })
		bodyparts.LowerTorso   = library:create("TextButton", { Text="", Parent=hp_frame, Position=UDim2.new(0.5,-42,0,144), Size=UDim2.new(0,84,0,10),  BorderSizePixel=0, BackgroundColor3=Color3.new(0.1490, 0.1490, 0.1490) })
		bodyparts.RightLowerArm= library:create("TextButton", { Text="", Parent=hp_frame, Position=UDim2.new(0.5, 46,0,102), Size=UDim2.new(0,40,0,42),  BorderSizePixel=0, BackgroundColor3=Color3.new(0.1490, 0.1490, 0.1490) })
		bodyparts.LeftLowerArm = library:create("TextButton", { Text="", Parent=hp_frame, Position=UDim2.new(0.5,-86,0,102), Size=UDim2.new(0,40,0,42),  BorderSizePixel=0, BackgroundColor3=Color3.new(0.1490, 0.1490, 0.1490) })

		local hrp_outline = library:create("TextButton", { Text="", Parent=hp_frame, Position=UDim2.new(0.5,-10,0,96), BorderSizePixel=0, Size=UDim2.new(0,20,0,20), BackgroundColor3=Color3.new(0.0863, 0.0863, 0.0863) })
		bodyparts.HumanoidRootPart = library:create("TextButton", { Text="", Parent=hrp_outline, Position=UDim2.new(0,4,0,4), BorderSizePixel=0, Size=UDim2.new(1,-8,1,-8), BackgroundColor3=Color3.new(0.1490, 0.1490, 0.1490) })
	else
		bodyparts.Head     = library:create("TextButton", { Parent=hp_frame, Text="", Position=UDim2.new(0.5,-25,0,16),  Size=UDim2.new(0,50,0,44),  BorderSizePixel=0, BackgroundColor3=Color3.new(0.1490, 0.1490, 0.1490) })
		bodyparts.Torso    = library:create("TextButton", { Parent=hp_frame, Text="", Position=UDim2.new(0.5,-42,0,64),  Size=UDim2.new(0,84,0,90),  BorderSizePixel=0, BackgroundColor3=Color3.new(0.1490, 0.1490, 0.1490) })
		bodyparts.LeftArm  = library:create("TextButton", { Parent=hp_frame, Text="", Position=UDim2.new(0.5,-86,0,64),  Size=UDim2.new(0,40,0,90),  BorderSizePixel=0, BackgroundColor3=Color3.new(0.1490, 0.1490, 0.1490) })
		bodyparts.RightArm = library:create("TextButton", { Parent=hp_frame, Text="", Position=UDim2.new(0.5, 46,0,64),  Size=UDim2.new(0,40,0,90),  BorderSizePixel=0, BackgroundColor3=Color3.new(0.1490, 0.1490, 0.1490) })
		bodyparts.RightLeg = library:create("TextButton", { Parent=hp_frame, Text="", Position=UDim2.new(0.5,  2,0,158), Size=UDim2.new(0,40,0,90),  BorderSizePixel=0, BackgroundColor3=Color3.new(0.1490, 0.1490, 0.1490) })
		bodyparts.LeftLeg  = library:create("TextButton", { Parent=hp_frame, Text="", Position=UDim2.new(0.5,-42,0,158), Size=UDim2.new(0,40,0,90),  BorderSizePixel=0, BackgroundColor3=Color3.new(0.1490, 0.1490, 0.1490) })

		local hrp_out = library:create("TextButton", { Parent=hp_frame, Text="", Position=UDim2.new(0.5,-10,0,99), BorderSizePixel=0, Size=UDim2.new(0,20,0,20), BackgroundColor3=Color3.new(0.0863, 0.0863, 0.0863) })
		bodyparts.HumanoidRootPart = library:create("TextButton", { Parent=hrp_out, Text="", Position=UDim2.new(0,4,0,4), BorderSizePixel=0, Size=UDim2.new(1,-8,1,-8), BackgroundColor3=Color3.new(0.1490, 0.1490, 0.1490) })
	end

	library:create("TextLabel", {
		Parent = hp_inline,
		FontFace = library.font,
		TextColor3 = Color3.new(0.6667, 0.6667, 0.6667),
		Text = cfg.name,
		TextStrokeTransparency = 0.5,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 8, 0, 0),
		ZIndex = 2,
		TextSize = 12,
		BackgroundColor3 = Color3.new(1.0000, 1.0000, 1.0000),
	})

	function cfg.set(parts)
		flags[cfg.flag] = {}
		for name_part, button in pairs(bodyparts) do
			bools[name_part] = false
			local g = button:FindFirstChildOfClass("ImageLabel")
			if g then g.Visible = false end
			button.BackgroundColor3 = Color3.fromRGB(24, 24, 31)
		end

		for _, part in pairs(parts) do
			if bodyparts[part] then
				bools[part] = true
				table.insert(flags[cfg.flag], part)
				local g = bodyparts[part]:FindFirstChildOfClass("ImageLabel")
				if g then g.Visible = true end
				bodyparts[part].BackgroundColor3 = themes.preset.accent
			end
		end

		cfg.callback(flags[cfg.flag])
	end

	for name_part, button in next, bodyparts do
		bools[name_part] = false
		library:apply_theme(button, "accent", "BackgroundColor3")

		local glow_img = library:create("ImageLabel", {
			Parent = button,
			Visible = false,
			ImageColor3 = themes.preset.accent,
			ScaleType = Enum.ScaleType.Slice,
			ImageTransparency = 0.9,
			BorderSizePixel = 0,
			BackgroundColor3 = Color3.new(1.0000, 1.0000, 1.0000),
			Image = "http://www.roblox.com/asset/?id=18245826428",
			BackgroundTransparency = 1,
			Position = UDim2.new(0, -20, 0, -20),
			Size = UDim2.new(1, 40, 1, 40),
			ZIndex = 2,
			SliceCenter = Rect.new(Vector2.new(21, 21), Vector2.new(79, 79)),
		})
		library:apply_theme(glow_img, "accent", "ImageColor3")

		library:connection(button.MouseButton1Click, function()
			if not cfg.multi then
				cfg.set({ name_part })
			else
				bools[name_part] = not bools[name_part]

				if bools[name_part] then
					table.insert(flags[cfg.flag], name_part)
				else
					local idx = table.find(flags[cfg.flag], name_part)
					if idx then table.remove(flags[cfg.flag], idx) end
				end

				glow_img.Visible = bools[name_part]
				button.BackgroundColor3 = bools[name_part] and themes.preset.accent or Color3.new(0.1490, 0.1490, 0.1490)
				cfg.callback(flags[cfg.flag])
			end
		end)
	end

	if #cfg.default > 1 and not cfg.multi then
		cfg.default = { cfg.default[1] }
	end

	cfg.set(cfg.default)
	config_flags[cfg.flag] = cfg.set

	return setmetatable(cfg, library)
end

function library:toggle(properties)
	local cfg = {
		enabled  = properties.enabled or nil,
		name     = properties.name or "Toggle",
		flag     = properties.flag or tostring(math.random(1, 9999999)),
		callback = properties.callback or function() end,
		default  = properties.default or false,
	}

	local object = library:create("TextButton", {
		Parent = self.holder,
		FontFace = library.font,
		TextColor3 = Color3.new(0.6667, 0.6667, 0.6667),
		Text = cfg.name,
		TextStrokeTransparency = 0.5,
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, -26, 0, 12),
		ZIndex = 1,
		TextSize = 12,
		BackgroundColor3 = Color3.new(1.0000, 1.0000, 1.0000),
	})

	local right_components = library:create("Frame", {
		Parent = object,
		Position = UDim2.new(1, 15, 0, 1),
		BorderSizePixel = 0,
		Size = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = Color3.new(1.0000, 1.0000, 1.0000),
	})

	library:create("UIListLayout", { Parent=right_components, FillDirection=Enum.FillDirection.Horizontal, HorizontalAlignment=Enum.HorizontalAlignment.Right, Padding=UDim.new(0,3), SortOrder=Enum.SortOrder.LayoutOrder })

	local icon_inline = library:create("TextButton", {
		Parent = object,
		Position = UDim2.new(0, -15, 0, 1),
		BorderColor3 = Color3.new(0.0745, 0.0745, 0.0745),
		Size = UDim2.new(0, 10, 0, 10),
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = Color3.new(0.0314, 0.0314, 0.0314),
		FrostedTransparency = 0.86,
	})
	library:create("UIStroke", {
		Parent = icon_inline,
		Name = "VNEOToggleOutline",
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		LineJoinMode = Enum.LineJoinMode.Round,
		Thickness = 1,
		Color = Color3.fromRGB(112, 112, 132),
		Transparency = 0.08,
	})

	local icon = library:create("Frame", {
		Parent = icon_inline,
		Position = UDim2.new(0, 2, 0, 2),
		BorderColor3 = Color3.new(0.2196, 0.2196, 0.2196),
		Size = UDim2.new(1, -4, 1, -4),
		BackgroundColor3 = Color3.new(0.0863, 0.0863, 0.0863),
	})

	local icon_2 = library:create("Frame", {
		Parent = icon,
		BorderColor3 = Color3.new(0.2196, 0.2196, 0.2196),
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = themes.preset.accent,
	})
	library:apply_theme(icon_2, "accent", "BackgroundColor3")

	local toggle_glow = library:create("ImageLabel", {
		Parent = icon_inline,
		Visible = false,
		ImageColor3 = themes.preset.accent,
		ScaleType = Enum.ScaleType.Slice,
		ImageTransparency = 0.75,
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.new(1.0000, 1.0000, 1.0000),
		Image = "http://www.roblox.com/asset/?id=18245826428",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, -12, 0, -12),
		Size = UDim2.new(1, 24, 1, 24),
		ZIndex = 2,
		SliceCenter = Rect.new(Vector2.new(21, 21), Vector2.new(79, 79)),
	})
	library:apply_theme(toggle_glow, "accent", "ImageColor3")

	local bottom_components = library:create("Frame", {
		Parent = object,
		Visible = true,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 0, 13),
		Size = UDim2.new(1, 26, 0, 0),
		ZIndex = 2,
		BackgroundColor3 = Color3.new(1.0000, 1.0000, 1.0000),
	})

	library:create("UIListLayout", { Parent=bottom_components, Padding=UDim.new(0,4), SortOrder=Enum.SortOrder.LayoutOrder })

	function cfg.set(bool)
		icon_2.Visible = bool
		toggle_glow.Visible = bool
		flags[cfg.flag] = bool
		cfg.callback(bool)
	end

	library:connection(object.MouseButton1Click, function()
		if (mouse.Y - object.AbsolutePosition.Y) > 12 then return end
		cfg.enabled = not cfg.enabled
		cfg.set(cfg.enabled)
	end)

	library:connection(icon_inline.MouseButton1Click, function()
		cfg.enabled = not cfg.enabled
		cfg.set(cfg.enabled)
	end)

	cfg.set(cfg.default)

	self.previous_holder  = self.holder
	self.bottom_holder    = bottom_components
	self.right_holder     = right_components

	config_flags[cfg.flag] = cfg.set

	table.insert(library.nav_elements, { cfg = cfg, type = "toggle", root = object, extend_left = 20, tab = self._web_tab or "General", section = self._web_section or self.name or "Controls" })

	return setmetatable(cfg, library)
end

function library:slider(properties)
	local cfg = {
		name      = properties.name or nil,
		suffix    = properties.suffix or "",
		flag      = properties.flag or tostring(2 ^ 789),
		callback  = properties.callback or function() end,
		min       = properties.min or properties.minimum or 0,
		max       = properties.max or properties.maximum or 100,
		intervals = properties.interval or properties.decimal or 1,
		default   = properties.default or 10,
		dragging  = false,
		value     = properties.default or 10,
	}

	local object
	local bottom_components

	if cfg.name then
		object = library:create("TextLabel", {
			Parent = self.holder,
			FontFace = library.font,
			TextColor3 = Color3.new(0.6667, 0.6667, 0.6667),
			Text = cfg.name,
			TextStrokeTransparency = 0.5,
			Size = UDim2.new(1, -26, 0, 12),
			BorderSizePixel = 0,
			BackgroundTransparency = 1,
			TextXAlignment = Enum.TextXAlignment.Left,
			AutomaticSize = Enum.AutomaticSize.Y,
			TextYAlignment = Enum.TextYAlignment.Top,
			TextSize = 12,
			BackgroundColor3 = Color3.new(1.0000, 1.0000, 1.0000),
		})

		bottom_components = library:create("Frame", {
			Parent = object,
			Visible = true,
			Position = UDim2.new(0, 0, 0, 13),
			BorderSizePixel = 0,
			Size = UDim2.new(1, 26, 0, 0),
			BackgroundColor3 = Color3.new(1.0000, 1.0000, 1.0000),
		})

		library:create("UIListLayout", { Parent=bottom_components, Padding=UDim.new(0,4), SortOrder=Enum.SortOrder.LayoutOrder })
	else
		if self.bottom_holder then
			self.bottom_holder.Parent.AutomaticSize = Enum.AutomaticSize.Y
			self.bottom_holder.Parent.TextYAlignment = Enum.TextYAlignment.Top
		end
	end

	local slider_holder = library:create("Frame", {
		Parent = cfg.name and bottom_components or self.bottom_holder,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		BorderSizePixel = 0,
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Color3.new(1.0000, 1.0000, 1.0000),
	})

	local slider_inline = library:create("TextButton", {
		Parent = slider_holder,
		Position = UDim2.new(0, 0, 0, 1),
		BorderColor3 = Color3.new(0.0745, 0.0745, 0.0745),
		Size = UDim2.new(1, -26, 0, 8),
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = Color3.new(0.0314, 0.0314, 0.0314),
	})

	local fill_inline = library:create("Frame", {
		Parent = slider_inline,
		Size = UDim2.new(0.5, 0, 1, 0),
		BorderColor3 = Color3.new(0.0745, 0.0745, 0.0745),
		ZIndex = 2,
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.new(0.0745, 0.0745, 0.0745),
	})

	local fill = library:create("Frame", {
		Parent = fill_inline,
		Position = UDim2.new(0, 2, 0, 2),
		Size = UDim2.new(1, 0, 1, -4),
		BackgroundColor3 = themes.preset.accent,
	})
	library:apply_theme(fill, "accent", "BackgroundColor3")
	library:apply_theme(fill, "accent", "BorderColor3")

	local VALUE_TEXT = library:create("TextLabel", {
		Parent = fill_inline,
		RichText = true,
		TextColor3 = Color3.new(0.6667, 0.6667, 0.6667),
		TextStrokeTransparency = 0.5,
		Size = UDim2.new(0, 1, 0, 11),
		BackgroundTransparency = 1,
		Position = UDim2.new(1, 0, 0, 1),
		BorderSizePixel = 0,
		FontFace = library.font,
		TextSize = 12,
		BackgroundColor3 = Color3.new(1.0000, 1.0000, 1.0000),
	})

	local sl_glow = library:create("ImageLabel", {
		Parent = fill_inline,
		ImageColor3 = themes.preset.accent,
		ScaleType = Enum.ScaleType.Slice,
		ImageTransparency = 0.9,
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.new(1.0000, 1.0000, 1.0000),
		Image = "http://www.roblox.com/asset/?id=18245826428",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, -18, 0, -18),
		Size = UDim2.new(1, 36, 1, 36),
		ZIndex = 2,
		SliceCenter = Rect.new(Vector2.new(21, 21), Vector2.new(79, 79)),
	})
	library:apply_theme(sl_glow, "accent", "ImageColor3")

	local add = library:create("TextButton", {
		Parent = slider_inline,
		TextWrapped = true,
		TextColor3 = Color3.new(0.6667, 0.6667, 0.6667),
		Text = "+",
		TextStrokeTransparency = 0.5,
		BackgroundTransparency = 1,
		Position = UDim2.new(1, 5, 0, -1),
		Size = UDim2.new(0, 8, 0, 8),
		FontFace = library.font,
		TextSize = 8,
		BackgroundColor3 = Color3.new(0.1490, 0.1490, 0.1490),
	})

	local sub_btn = library:create("TextButton", {
		Parent = slider_inline,
		TextWrapped = true,
		TextColor3 = Color3.new(0.6667, 0.6667, 0.6667),
		Text = "-",
		TextStrokeTransparency = 0.5,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, -15, 0, -1),
		Size = UDim2.new(0, 8, 0, 8),
		FontFace = library.font,
		TextSize = 12,
		BackgroundColor3 = Color3.new(0.1490, 0.1490, 0.1490),
	})

	local slider = library:create("Frame", {
		Parent = slider_inline,
		Position = UDim2.new(0, 2, 0, 2),
		BorderColor3 = Color3.new(0.2196, 0.2196, 0.2196),
		Size = UDim2.new(1, -4, 1, -4),
		BackgroundColor3 = Color3.new(0.0863, 0.0863, 0.0863),
	})

	library:create("UIPadding", { Parent=slider_holder, PaddingBottom=UDim.new(0,-17) })

	cfg._init = true

	function cfg.set(value)
		if type(value) ~= "number" then return end
		cfg.value = math.clamp(library:round(value, cfg.intervals), cfg.min, cfg.max)
		fill_inline.Size = dim2((cfg.value - cfg.min) / (cfg.max - cfg.min), 0, 1, 0)
		VALUE_TEXT.Text = tostring(cfg.value) .. cfg.suffix
		flags[cfg.flag] = cfg.value
		if not cfg._init then
			cfg.callback(flags[cfg.flag])
		end
	end

	cfg.set(cfg.default)
	cfg._init = false
	config_flags[cfg.flag] = cfg.set
	library.config_flags[cfg.flag] = cfg.set

	library:connection(uis.InputChanged, function(input)
		if cfg.dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local size_x = (input.Position.X - slider.AbsolutePosition.X) / slider.AbsoluteSize.X
			cfg.set(((cfg.max - cfg.min) * size_x) + cfg.min)
		end
	end)

	library:connection(uis.InputEnded, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			cfg.dragging = false
		end
	end)

	slider_inline.MouseButton1Down:Connect(function()
		cfg.dragging = true
		local size_x = (mouse.X - slider.AbsolutePosition.X) / slider.AbsoluteSize.X
		cfg.set(((cfg.max - cfg.min) * size_x) + cfg.min)
	end)

	add.MouseButton1Down:Connect(function()
		cfg.set(cfg.value + cfg.intervals)
	end)

	sub_btn.MouseButton1Down:Connect(function()
		cfg.set(cfg.value - cfg.intervals)
	end)

	table.insert(library.nav_elements, { cfg = cfg, type = "slider", root = slider_inline, tab = self._web_tab or "General", section = self._web_section or self.name or "Controls" })

	return setmetatable(cfg, library)
end

function library:dropdown(properties)
	local cfg = {
		name     = properties.name or nil,
		flag     = properties.flag or tostring(math.random(1, 9999999)),
		items    = properties.items or { "1", "2", "3" },
		callback = properties.callback or function() end,
		multi    = properties.multi or false,
		open     = false,
		option_instances = {},
		multi_items = {},
		format_player = properties.format_player or nil,
	}
	cfg.default = properties.default or (cfg.multi and { cfg.items[1] }) or cfg.items[1] or nil

	if properties.players then
		local _pSvc = Players
		local _lp = _pSvc.LocalPlayer
		local _format = cfg.format_player or function(plr)
			return string.format("%s (@%s)", plr.DisplayName, plr.Name)
		end

		function cfg.get_players_list()
			local list = {}
			for _, plr in ipairs(_pSvc:GetPlayers()) do
				if plr ~= _lp then
					list[#list + 1] = _format(plr)
				end
			end
			table.sort(list)
			return list
		end

		function cfg.refresh_players()
			local list = cfg.get_players_list()
			cfg.items = list
			cfg:refresh_options(list)
			return list
		end

		cfg.items = cfg.get_players_list()

		library:connection(_pSvc.PlayerAdded, function()
			cfg.refresh_players()
		end)
		library:connection(_pSvc.PlayerRemoving, function()
			task.defer(function()
				cfg.refresh_players()
			end)
		end)
	end

	local function getDropdownHeight(itemCount)
		local itemHeight = 16
		local maxVisible = 5
		return itemHeight * math.min(itemCount, maxVisible)
	end

	local object
	local bottom_components

	if cfg.name then
		object = library:create("TextLabel", {
			Parent = self.holder,
			FontFace = library.font,
			TextColor3 = Color3.new(0.6667, 0.6667, 0.6667),
			Text = cfg.name,
			TextStrokeTransparency = 0.5,
			Size = UDim2.new(1, -26, 0, 12),
			BorderSizePixel = 0,
			ZIndex = 2,
			BackgroundTransparency = 1,
			TextXAlignment = Enum.TextXAlignment.Left,
			AutomaticSize = Enum.AutomaticSize.Y,
			TextYAlignment = Enum.TextYAlignment.Top,
			TextSize = 12,
			BackgroundColor3 = Color3.new(1.0000, 1.0000, 1.0000),
		})

		bottom_components = library:create("Frame", {
			Parent = object,
			Visible = true,
			Position = UDim2.new(0, 0, 0, 13),
			BorderSizePixel = 0,
			Size = UDim2.new(1, 26, 0, 0),
			BackgroundColor3 = Color3.new(1.0000, 1.0000, 1.0000),
		})

		library:create("UIListLayout", { Parent=bottom_components, Padding=UDim.new(0,4), SortOrder=Enum.SortOrder.LayoutOrder })
	else
		if self.bottom_holder then
			self.bottom_holder.Parent.AutomaticSize = Enum.AutomaticSize.Y
			self.bottom_holder.Parent.TextYAlignment = Enum.TextYAlignment.Top
		end
	end

	local dropdown_inline = library:create("Frame", {
		Parent = cfg.name and bottom_components or self.bottom_holder,
		Position = UDim2.new(0, -15, 0, 2),
		BorderColor3 = Color3.new(0.0745, 0.0745, 0.0745),
		Size = UDim2.new(1, -26, 0, 16),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.new(0.0314, 0.0314, 0.0314),
		FrostedTransparency = 0.97,
	})

	local dropdown = library:create("TextButton", {
		Parent = dropdown_inline,
		FontFace = library.font,
		TextColor3 = Color3.new(0.6667, 0.6667, 0.6667),
		Text = "",
		TextStrokeTransparency = 0.5,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, -4, 1, -4),
		Position = UDim2.new(0, 2, 0, 2),
		TextSize = 12,
		BackgroundColor3 = Color3.new(0.1490, 0.1490, 0.1490),
		FrostedTransparency = 0.86,
	})

	library:create("UIPadding", { Parent=dropdown, PaddingLeft=UDim.new(0,5) })

	local icon = library:create("TextLabel", {
		Parent = dropdown,
		FontFace = library.font,
		TextColor3 = Color3.new(0.6667, 0.6667, 0.6667),
		Text = "+",
		TextStrokeTransparency = 0.5,
		Size = UDim2.new(0, 1, 1, 0),
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Right,
		Position = UDim2.new(1, -6, 0, -1),
		BorderSizePixel = 0,
		TextSize = 8,
		BackgroundColor3 = Color3.new(1.0000, 1.0000, 1.0000),
	})

	local optionsHeight = getDropdownHeight(#cfg.items)

	local content_inline = library:create("Frame", {
		Parent = library.gui,
		BorderColor3 = Color3.new(0.0745, 0.0745, 0.0745),
		BorderSizePixel = 0,
		ZIndex = 9999,
		Visible = false,
		Size = UDim2.new(0, dropdown_inline.AbsoluteSize.X, 0, optionsHeight + 4),
		Position = UDim2.new(0, dropdown_inline.AbsolutePosition.X, 0, dropdown_inline.AbsolutePosition.Y + dropdown_inline.AbsoluteSize.Y + 2),
		BackgroundColor3 = Color3.new(0.0314, 0.0314, 0.0314),
		FrostedTransparency = 0.95,
	})

	dropdown_inline:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
		content_inline.Position = UDim2.new(0, dropdown_inline.AbsolutePosition.X, 0, dropdown_inline.AbsolutePosition.Y + dropdown_inline.AbsoluteSize.Y + 2)
	end)

	dropdown_inline:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		local absW = dropdown_inline.AbsoluteSize.X
		if absW > 0 then
			content_inline.Size = UDim2.new(0, absW, 0, optionsHeight + 4)
		end
	end)

	local content = library:create("Frame", {
		Parent = content_inline,
		Position = UDim2.new(0, 2, 0, 2),
		BorderColor3 = Color3.new(0.2196, 0.2196, 0.2196),
		Size = UDim2.new(1, -4, 1, -4),
		BackgroundColor3 = Color3.new(0.1490, 0.1490, 0.1490),
		FrostedTransparency = 0.90,
	})

	local options_scroll = library:create("ScrollingFrame", {
		Parent = content,
		Active = true,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = Color3.new(0.3529, 0.3529, 0.3529),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 2, 0, 2),
		Size = UDim2.new(1, -4, 0, optionsHeight),
		CanvasSize = UDim2.new(0, 0, 0, 0),
	})

	local opt_layout = library:create("UIListLayout", { Parent=options_scroll, Padding=UDim.new(0,2), SortOrder=Enum.SortOrder.LayoutOrder })
	library:create("UIPadding", { Parent=options_scroll, PaddingBottom=UDim.new(0,4) })

	opt_layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		options_scroll.CanvasSize = UDim2.new(0, 0, 0, opt_layout.AbsoluteContentSize.Y + 6)
	end)

	function cfg.set_visible(bool)
		content_inline.Visible = bool
		icon.Text = bool and "-" or "+"
		icon.TextSize = bool and 12 or 8

		if bool then
			local function reposition()
				if not content_inline.Visible then return end
				local absX = dropdown_inline.AbsoluteSize.X
				if absX <= 0 then absX = 200 end
				content_inline.Position = UDim2.new(0, dropdown_inline.AbsolutePosition.X, 0, dropdown_inline.AbsolutePosition.Y + dropdown_inline.AbsoluteSize.Y + 2)
				content_inline.Size = UDim2.new(0, absX, 0, optionsHeight + 4)
			end
			reposition()
			task.defer(reposition)

			if cfg.name and object then
				object.ZIndex = 9999
			end

			if library.current_element_open and library.current_element_open ~= cfg then
				library.current_element_open.set_visible(false)
				library.current_element_open.open = false
			end
			library.current_element_open = cfg
		else
			if cfg.name and object then
				object.ZIndex = 3
			end
		end
	end

	function cfg.set(value)
		local selected = {}
		local is_table = type(value) == "table"

		for _, v in next, cfg.option_instances do
			if v.Text == value or (is_table and table.find(value, v.Text)) then
				table.insert(selected, v.Text)
				v.BackgroundTransparency = library.ui_theme == "Frosted Glass" and 0.84 or 0
			else
				v.BackgroundTransparency = 1
			end
		end

		cfg.multi_items = selected
		dropdown.Text = is_table and table.concat(selected, ",  ") or selected[1] or ""
		flags[cfg.flag] = is_table and selected or selected[1]
		cfg.callback(flags[cfg.flag])
	end

	function cfg._refresh_theme()
		local current = flags[cfg.flag]
		local is_table = type(current) == "table"
		for _, option in next, cfg.option_instances or {} do
			local selected = option.Text == current or (is_table and table.find(current, option.Text))
			option.BackgroundTransparency = selected and (library.ui_theme == "Frosted Glass" and 0.84 or 0) or 1
		end
	end

	function cfg:refresh_options(refreshed_list)
		refreshed_list = type(refreshed_list) == "table" and refreshed_list or {}
		cfg.items = {}
		for i, item in ipairs(refreshed_list) do
			cfg.items[i] = item
		end
		for _, v in next, cfg.option_instances do
			v:Destroy()
		end
		cfg.option_instances = {}

		for _, v in next, refreshed_list do
			local op = library:create("TextButton", {
				Parent = options_scroll,
				FontFace = library.font,
				TextColor3 = Color3.new(0.6667, 0.6667, 0.6667),
				Text = v,
				BackgroundTransparency = 1,
				TextStrokeTransparency = 0.5,
				Size = UDim2.new(1, 0, 0, 14),
				TextXAlignment = Enum.TextXAlignment.Left,
				BorderSizePixel = 0,
				TextSize = 12,
				BackgroundColor3 = Color3.fromRGB(42, 44, 56),
			})
			library:create("UIPadding", { Parent=op, PaddingLeft=UDim.new(0,5) })
			table.insert(cfg.option_instances, op)

			op.MouseButton1Down:Connect(function()
				if cfg.multi then
					local sel_idx = table.find(cfg.multi_items, op.Text)
					if sel_idx then
						table.remove(cfg.multi_items, sel_idx)
					else
						table.insert(cfg.multi_items, op.Text)
					end
					cfg.set(cfg.multi_items)
				else
					cfg.set_visible(false)
					cfg.open = false
					cfg.set(op.Text)
				end
			end)
		end

		local itemCount = #refreshed_list
		local newHeight = 16 * math.min(itemCount, 5)
		optionsHeight = newHeight
		options_scroll.Size = UDim2.new(1, -4, 0, newHeight)
		local absW = dropdown_inline.AbsoluteSize.X
		if absW <= 0 then absW = 200 end
		content_inline.Size = UDim2.new(0, absW, 0, newHeight + 4)
		local current = flags[cfg.flag]
		if not cfg.multi and current and table.find(cfg.items, current) then
			dropdown.Text = tostring(current)
		elseif not cfg.multi then
			dropdown.Text = ""
		end
	end

	dropdown.MouseButton1Click:Connect(function()
		cfg.open = not cfg.open
		cfg.set_visible(cfg.open)
	end)

	cfg.object = object

	function cfg:set_row_visible(bool)
		if object then
			object.Visible = bool
		end
		if not bool then
			content_inline.Visible = false
			cfg.open = false
			icon.Text = "+"
			icon.TextSize = 8
		end
	end

	cfg:refresh_options(cfg.items)
	cfg.set(cfg.default)
	library.config_flags[cfg.flag] = cfg.set

	table.insert(library.nav_elements, { cfg = cfg, type = "dropdown", root = dropdown_inline, tab = self._web_tab or "General", section = self._web_section or self.name or "Controls" })

	return setmetatable(cfg, library)
end

function library:colorpicker(properties)
	local cfg = {
		name     = properties.name or nil,
		flag     = properties.flag or tostring(2 ^ 789),
		color    = properties.color or properties.default or Color3.new(1, 1, 1),
		alpha    = properties.alpha or 1,
		callback = properties.callback or function() end,
		animation = "normal",
		saved_color = nil,
		right_holder = self.right_holder or nil,
		holder       = self.holder or nil,
	}

	flags[cfg.flag] = {}

	local dragging_sat   = false
	local dragging_hue   = false
	local dragging_alpha = false

	local h, s, v = cfg.color:ToHSV()
	local a = cfg.alpha
	local base_h, base_s, base_v = h, s, v

	local right_components
	if cfg.name then
		local obj = library:create("TextLabel", {
			Parent = self.holder,
			FontFace = library.font,
			TextColor3 = Color3.new(0.6667, 0.6667, 0.6667),
			Text = cfg.name,
			TextStrokeTransparency = 0.5,
			Size = UDim2.new(1, -26, 0, 12),
			BorderSizePixel = 0,
			BackgroundTransparency = 1,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			TextSize = 12,
			BackgroundColor3 = Color3.new(1.0000, 1.0000, 1.0000),
		})

		right_components = library:create("Frame", {
			Parent = obj,
			Position = UDim2.new(1, 15, 0, 1),
			BorderSizePixel = 0,
			Size = UDim2.new(0, 0, 1, 0),
			BackgroundColor3 = Color3.new(1.0000, 1.0000, 1.0000),
		})

		library:create("UIListLayout", { Parent=right_components, FillDirection=Enum.FillDirection.Horizontal, HorizontalAlignment=Enum.HorizontalAlignment.Right, Padding=UDim.new(0,3), SortOrder=Enum.SortOrder.LayoutOrder })
	end

	local icon_inline = library:create("TextButton", {
		Parent = cfg.name and right_components or self.right_holder,
		Text = "",
		Size = UDim2.new(0, 16, 0, 10),
		Position = UDim2.new(0, -15, 0, 1),
		BorderColor3 = Color3.new(0.0745, 0.0745, 0.0745),
		ZIndex = 3,
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(18, 18, 24),
		ThemeIgnore = true,
	})

	local icon = library:create("Frame", {
		Parent = icon_inline,
		Position = UDim2.new(0, 2, 0, 2),
		BorderColor3 = Color3.fromRGB(119, 114, 214),
		ZIndex = 2,
		Size = UDim2.new(1, -4, 1, -4),
		BackgroundColor3 = cfg.color,
	})

	local cp_glow = library:create("ImageLabel", {
		Parent = icon_inline,
		ImageColor3 = cfg.color,
		ScaleType = Enum.ScaleType.Slice,
		ImageTransparency = 0.9,
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.new(1.0000, 1.0000, 1.0000),
		Image = "http://www.roblox.com/asset/?id=18245826428",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, -20, 0, -20),
		Size = UDim2.new(1, 40, 1, 40),
		ZIndex = 2,
		SliceCenter = Rect.new(Vector2.new(21, 21), Vector2.new(79, 79)),
	})

	local picker_inline = library:create("Frame", {
		Parent = library.gui,
		Size = UDim2.new(0, 142, 0, 146),
		Position = UDim2.fromOffset(-9999, -9999),
		BorderColor3 = Color3.new(0.0745, 0.0745, 0.0745),
		ZIndex = 9999,
		BorderSizePixel = 0,
		Visible = false,
		BackgroundColor3 = Color3.new(0.0314, 0.0314, 0.0314),
		ThemeIgnore = true,
	})

	local picker = library:create("Frame", {
		Parent = picker_inline,
		Position = UDim2.new(0, 2, 0, 2),
		BorderColor3 = Color3.new(0.2196, 0.2196, 0.2196),
		Size = UDim2.new(1, -4, 1, -4),
		BackgroundColor3 = Color3.new(0.1490, 0.1490, 0.1490),
	})

	local sat_inline = library:create("TextButton", {
		Parent = picker,
		Text = "",
		Position = UDim2.new(0, 4, 0, 4),
		BorderColor3 = Color3.new(0.0745, 0.0745, 0.0745),
		Size = UDim2.new(1, -8, 1, -50),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.new(0.0314, 0.0314, 0.0314),
	})

	local sat = library:create("Frame", {
		Parent = sat_inline,
		Position = UDim2.new(0, 2, 0, 2),
		BorderColor3 = Color3.new(0.2196, 0.2196, 0.2196),
		Size = UDim2.new(1, -4, 1, -4),
		BackgroundColor3 = Color3.new(1.0000, 0.0000, 0.0000),
	})

	local sat_white = library:create("Frame", {
		Parent = sat,
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = 2,
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.new(1.0000, 1.0000, 1.0000),
	})

	library:create("UIGradient", { Parent=sat_white, Transparency=NumberSequence.new({ NumberSequenceKeypoint.new(0,0), NumberSequenceKeypoint.new(1,1) }) })

	local sat_black = library:create("Frame", {
		Parent = sat_white,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Color3.new(1.0000, 1.0000, 1.0000),
	})

	library:create("UIGradient", { Parent=sat_black, Rotation=90, Transparency=NumberSequence.new({ NumberSequenceKeypoint.new(0,1), NumberSequenceKeypoint.new(1,0) }), Color=ColorSequence.new({ ColorSequenceKeypoint.new(0,Color3.new(0.0000, 0.0000, 0.0000)), ColorSequenceKeypoint.new(1,Color3.new(0.0000, 0.0000, 0.0000)) }) })

	local sat_black_cursor = library:create("Frame", {
		Parent = sat_black,
		Position = UDim2.new(0.8, 0, 0.2, 0),
		BorderColor3 = Color3.new(0.4235, 0.0863, 0.0863),
		Size = UDim2.new(0, 1, 0, 1),
		BackgroundColor3 = Color3.new(0.8000, 0.1608, 0.1608),
	})

	local preview_inline = library:create("Frame", {
		Parent = picker,
		Position = UDim2.new(1, -20, 1, -20),
		BorderColor3 = Color3.new(0.0745, 0.0745, 0.0745),
		Size = UDim2.new(0, 16, 0, 16),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.new(0.1373, 0.1373, 0.1373),
	})

	local preview = library:create("Frame", {
		Parent = preview_inline,
		BackgroundTransparency = 0,
		Position = UDim2.new(0, 2, 0, 2),
		ZIndex = 2,
		Size = UDim2.new(1, -4, 1, -4),
		BackgroundColor3 = Color3.new(0.8000, 0.1608, 0.1608),
	})

	library:create("ImageLabel", {
		Parent = preview_inline,
		ScaleType = Enum.ScaleType.Tile,
		Image = "http://www.roblox.com/asset/?id=18274452449",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 2, 0, 2),
		Size = UDim2.new(1, -4, 1, -4),
		TileSize = UDim2.new(0, 6, 0, 6),
		BorderSizePixel = 0,
		ZIndex = 3,
		BackgroundColor3 = Color3.new(1.0000, 1.0000, 1.0000),
	})

	local hue_inline = library:create("TextButton", {
		Parent = picker,
		Text = "",
		Position = UDim2.new(0, 4, 1, -44),
		BorderColor3 = Color3.new(0.0745, 0.0745, 0.0745),
		Size = UDim2.new(1, -8, 0, 10),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.new(0.0314, 0.0314, 0.0314),
	})

	local hue_border = library:create("Frame", {
		Parent = hue_inline,
		Position = UDim2.new(0, 2, 0, 2),
		BorderColor3 = Color3.new(0.2196, 0.2196, 0.2196),
		Size = UDim2.new(1, -4, 1, -4),
		BackgroundColor3 = Color3.new(1.0000, 1.0000, 1.0000),
	})

	local hue = library:create("Frame", {
		Parent = hue_border,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Color3.new(1.0000, 1.0000, 1.0000),
	})

	library:create("UIGradient", { Parent=hue, Color=ColorSequence.new({
		ColorSequenceKeypoint.new(0,     Color3.new(1.0000, 0.0000, 0.0000)),
		ColorSequenceKeypoint.new(0.167, Color3.new(1.0000, 1.0000, 0.0000)),
		ColorSequenceKeypoint.new(0.333, Color3.new(0.0000, 1.0000, 0.0000)),
		ColorSequenceKeypoint.new(0.5,   Color3.new(0.0000, 1.0000, 1.0000)),
		ColorSequenceKeypoint.new(0.667, Color3.new(0.0000, 0.0000, 1.0000)),
		ColorSequenceKeypoint.new(0.833, Color3.new(1.0000, 0.0000, 1.0000)),
		ColorSequenceKeypoint.new(1,     Color3.new(1.0000, 0.0000, 0.0000)),
	}) })

	local hue_cursor = library:create("Frame", {
		Parent = hue,
		BorderColor3 = Color3.new(0.4235, 0.0863, 0.0863),
		Size = UDim2.new(0, 1, 1, 0),
		BackgroundColor3 = Color3.new(0.8000, 0.1608, 0.1608),
	})

	local input_inline = library:create("Frame", {
		Parent = picker,
		Position = UDim2.new(0, 4, 1, -20),
		BorderColor3 = Color3.new(0.0745, 0.0745, 0.0745),
		Size = UDim2.new(1, -26, 0, 16),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.new(0.0314, 0.0314, 0.0314),
	})

	local __input = library:create("TextBox", {
		Parent = input_inline,
		FontFace = library.font,
		TextColor3 = Color3.new(0.6667, 0.6667, 0.6667),
		Text = "204, 41, 41, 0.5",
		TextStrokeTransparency = 0.5,
		Size = UDim2.new(1, -4, 1, -4),
		PlaceholderColor3 = Color3.new(0.3529, 0.3529, 0.3529),
		Position = UDim2.new(0, 2, 0, 2),
		PlaceholderText = "r, g, b, a",
		TextSize = 12,
		ClearTextOnFocus = false,
		BackgroundColor3 = Color3.new(0.1490, 0.1490, 0.1490),
	})

	local alpha_inline = library:create("TextButton", {
		Parent = picker,
		Text = "",
		Position = UDim2.new(0, 4, 1, -32),
		BorderColor3 = Color3.new(0.0745, 0.0745, 0.0745),
		Size = UDim2.new(1, -8, 0, 10),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.new(0.0314, 0.0314, 0.0314),
	})

	local alpha_frame = library:create("Frame", {
		Parent = alpha_inline,
		Position = UDim2.new(0, 2, 0, 2),
		BorderColor3 = Color3.new(0.2196, 0.2196, 0.2196),
		Size = UDim2.new(1, -4, 1, -4),
		BackgroundColor3 = Color3.new(0.8000, 0.1608, 0.1608),
	})

	local alpha_image = library:create("ImageLabel", {
		Parent = alpha_frame,
		ScaleType = Enum.ScaleType.Tile,
		Image = "http://www.roblox.com/asset/?id=18343135386",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		TileSize = UDim2.new(0, 6, 0, 6),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.new(1.0000, 1.0000, 1.0000),
	})

	library:create("UIGradient", { Parent=alpha_image, Transparency=NumberSequence.new({ NumberSequenceKeypoint.new(0,1), NumberSequenceKeypoint.new(1,0) }) })

	local alpha_cursor = library:create("Frame", {
		Parent = alpha_image,
		Position = UDim2.new(0.5, 0, 0, 0),
		BorderColor3 = Color3.new(0.4235, 0.0863, 0.0863),
		Size = UDim2.new(0, 1, 1, 0),
		BackgroundColor3 = Color3.new(0.8000, 0.1608, 0.1608),
	})

	local anim_inline = library:create("Frame", {
		Parent = library.gui,
		BorderColor3 = Color3.new(0.0745, 0.0745, 0.0745),
		Size = UDim2.new(0, 73, 0, 0),
		Position = UDim2.fromOffset(-9999, -9999),
		BorderSizePixel = 0,
		ZIndex = 9999,
		Visible = false,
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Color3.new(0.0314, 0.0314, 0.0314),
		ThemeIgnore = true,
	})

	local anim_content = library:create("Frame", {
		Parent = anim_inline,
		Position = UDim2.new(0, 2, 0, 2),
		BorderColor3 = Color3.new(0.2196, 0.2196, 0.2196),
		Size = UDim2.new(1, -4, 1, -4),
		BackgroundColor3 = Color3.new(0.1490, 0.1490, 0.1490),
	})

	local anim_options = library:create("Frame", {
		Parent = anim_content,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 2, 0, 2),
		BorderSizePixel = 0,
		Size = UDim2.new(1, -4, 1, -4),
		BackgroundColor3 = Color3.new(0.1961, 0.1961, 0.1961),
	})

	library:create("UIListLayout", { Parent=anim_options, Padding=UDim.new(0,2), SortOrder=Enum.SortOrder.LayoutOrder })

	local function make_anim_btn(label)
		local b = library:create("TextButton", {
			Parent = anim_options,
			FontFace = library.font,
			TextColor3 = Color3.new(0.6667, 0.6667, 0.6667),
			Text = label,
			TextStrokeTransparency = 0.5,
			Size = UDim2.new(1, 0, 0, 12),
			BackgroundTransparency = 1,
			TextXAlignment = Enum.TextXAlignment.Left,
			BorderSizePixel = 0,
			TextSize = 12,
			BackgroundColor3 = Color3.new(0.2549, 0.2549, 0.2549),
		})
		library:create("UIPadding", { Parent=b, PaddingBottom=UDim.new(0,1), PaddingLeft=UDim.new(0,5) })
		return b
	end

	local btn_normal     = make_anim_btn("normal")
	local btn_rainbow    = make_anim_btn("rainbow")
	local btn_fade       = make_anim_btn("fade")
	local btn_fade_alpha = make_anim_btn("fade alpha")

	library:create("UIPadding", { Parent=anim_options, PaddingBottom=UDim.new(0,4) })

	function cfg.set_visible(bool)
		if library._suppress_ui then
			bool = false
			cfg.open = false
		end
		if bool then
			local base_pos = icon_inline.AbsolutePosition
			picker_inline.Position = UDim2.fromOffset(base_pos.X + 1, base_pos.Y + 17)
			anim_inline.Position = dim2(0, icon_inline.AbsolutePosition.X + 20, 0, icon_inline.AbsolutePosition.Y)
			picker_inline.Visible = true
			anim_inline.Visible = false

			if library.current_element_open and library.current_element_open ~= cfg then
				library.current_element_open.set_visible(false)
				library.current_element_open.open = false
			end
			library.current_element_open = cfg
		else
			picker_inline.Visible = false
			anim_inline.Visible = false
			picker_inline.Position = UDim2.fromOffset(-9999, -9999)
			anim_inline.Position = UDim2.fromOffset(-9999, -9999)
		end
	end

	icon_inline.MouseButton1Click:Connect(function()
		if library._suppress_ui then
			cfg.open = false
			cfg.set_visible(false)
			return
		end
		cfg.open = not cfg.open
		cfg.set_visible(cfg.open)
	end)

	icon_inline.MouseButton2Click:Connect(function()
		if library._suppress_ui then
			cfg.open = false
			cfg.set_visible(false)
			return
		end
		if cfg.open then
			cfg.open = false
			cfg.set_visible(false)
		end
		local base_pos = icon_inline.AbsolutePosition
		local show_anim = not anim_inline.Visible
		if show_anim then
			anim_inline.Position = dim2(0, icon_inline.AbsolutePosition.X + 20, 0, icon_inline.AbsolutePosition.Y)
			picker_inline.Position = UDim2.fromOffset(base_pos.X + 1, base_pos.Y + 17)
			anim_inline.Visible = true
		else
			anim_inline.Visible = false
			anim_inline.Position = UDim2.fromOffset(-9999, -9999)
		end
	end)

	function cfg.set(c, alpha_val)
		if c then
			h, s, v = c:ToHSV()
			cfg.saved_color = c
			base_h, base_s, base_v = h, s, v
		end

		if alpha_val ~= nil then
			a = clamp(tonumber(alpha_val) or a, 0, 1)
		end

		local Color = Color3.fromHSV(h, s, v)

		cfg.color = Color
		cfg.alpha = a
		flags[cfg.flag] = { Color = Color, Transparency = a }

		hue_cursor.Position    = UDim2.new(h, -1, 0, 0)
		alpha_cursor.Position  = UDim2.new(a, -1, 0, 0)
		sat_black_cursor.Position = UDim2.new(s, -0.5, 1 - v, -0.5)

		icon_inline.BackgroundColor3 = Color3.fromRGB(Color.R * 255 * 0.25, Color.G * 255 * 0.25, Color.B * 255 * 0.25)
		icon.BackgroundColor3 = Color
		icon.BackgroundTransparency = 1 - a
		cp_glow.ImageColor3 = Color
		cp_glow.ImageTransparency = 1 - (0.1 * a)
		preview.BackgroundColor3 = Color
		preview.BackgroundTransparency = 1 - a
		alpha_frame.BackgroundColor3 = Color
		sat.BackgroundColor3  = Color3.fromHSV(h, 1, 1)

		__input.Text = string.format("%d, %d, %d, %.2f", Color.R * 255, Color.G * 255, Color.B * 255, a)

		cfg.callback(Color, a)
		if type(cfg.alpha_callback) == "function" then
			cfg.alpha_callback(a, Color)
		end
	end

	__input.FocusLost:Connect(function()
		local r, g, b, al = library:convert_string_rgb(__input.Text)
		if r and g and b then
			cfg.set(rgb(r, g, b), al ~= nil and al or a)
		end
	end)

	function cfg.update_color()
		local mpos = uis:GetMouseLocation()
		mpos = Vector2.new(mpos.X, mpos.Y - gui_offset)

		if dragging_sat then
			local rel = mpos - sat_white.AbsolutePosition
			s = clamp(rel.X / sat_white.AbsoluteSize.X, 0, 1)
			v = 1 - clamp(rel.Y / sat_white.AbsoluteSize.Y, 0, 1)
		end
		if dragging_hue then
			h = clamp((mpos.X - hue.AbsolutePosition.X) / hue.AbsoluteSize.X, 0, 1)
		end
		if dragging_alpha then
			a = clamp((mpos.X - alpha_frame.AbsolutePosition.X) / alpha_frame.AbsoluteSize.X, 0, 1)
		end

		cfg.set(nil, nil)
	end

	function cfg.stop_dragging()
		dragging_sat   = false
		dragging_hue   = false
		dragging_alpha = false
	end

	alpha_inline.MouseButton1Down:Connect(function() dragging_alpha = true; library.active_colorpicker = cfg; cfg.update_color() end)
	hue_inline.MouseButton1Down:Connect(function()   dragging_hue   = true; library.active_colorpicker = cfg; cfg.update_color() end)
	sat_inline.MouseButton1Down:Connect(function()   dragging_sat   = true; library.active_colorpicker = cfg; cfg.update_color() end)

	cfg.saved_color = Color3.fromHSV(h, s, v)

	local selectedButton = btn_normal
	local selectedMode   = "normal"
	flags[cfg.flag]["animation"] = "normal"

	local function selectMode(button, mode)
		if selectedButton then selectedButton.BackgroundTransparency = 1 end
		selectedButton = button
		selectedMode = mode
		if button then button.BackgroundTransparency = library.ui_theme == "Frosted Glass" and 0.84 or 0 end
		flags[cfg.flag]["animation"] = mode
	end

	btn_normal.MouseButton1Down:Connect(function()
		selectMode(btn_normal, "normal")
		cfg.set(cfg.saved_color or Color3.fromHSV(base_h, base_s, base_v), a)
	end)

	btn_rainbow.MouseButton1Down:Connect(function()    selectMode(btn_rainbow,    "rainbow")    end)
	btn_fade.MouseButton1Down:Connect(function()       selectMode(btn_fade,       "fade")       end)
	btn_fade_alpha.MouseButton1Down:Connect(function() selectMode(btn_fade_alpha, "fade_alpha") end)

	cfg.set(cfg.color, cfg.alpha)
	library.config_flags[cfg.flag] = cfg.set

	local _cp_root = (cfg.name and right_components and right_components.Parent) or icon_inline
	cfg.object = _cp_root
	function cfg:set_row_visible(bool)
		if _cp_root then _cp_root.Visible = bool == true end
		if not bool then
			cfg.open = false
			cfg.set_visible(false)
		end
	end
	cfg._cp_icon = icon_inline
	cfg._cp_picker = picker_inline
	table.insert(library.nav_elements, { cfg = cfg, type = "colorpicker", root = _cp_root, tab = self._web_tab or "General", section = self._web_section or self.name or "Controls" })

	local cp_elapsed = 0
	library:connection(run_service.Heartbeat, function(dt)
		if selectedMode == "normal" then return end

		cp_elapsed = cp_elapsed + dt
		if cp_elapsed < (1 / 30) then return end
		cp_elapsed = 0

		local now = clock()
		if selectedMode == "rainbow" then
			cfg.set(Color3.fromHSV((now % 5) / 5, 1, 1), a)
		elseif selectedMode == "fade" then
			cfg.set(Color3.fromHSV(base_h, base_s, (sin_wave(now) + 1) / 2), a)
		elseif selectedMode == "fade_alpha" then
			cfg.set(cfg.color, (sin_wave(now) + 1) / 2)
		end
	end)

	return setmetatable(cfg, library)
end

function library:keybind(properties)
	local cfg = {
		flag         = properties.flag or tostring(2 ^ math.random(1, 30) * 3),
		keybind_name = properties.keybind_name or nil,
		callback     = properties.callback or function() end,
		open         = false,
		binding      = nil,
		name         = properties.name or nil,
		key          = properties.default or properties.key or nil,
		mode         = properties.mode or "toggle",
		active       = properties.default or false,
		display      = properties.displayName or properties.display or properties.name or nil,
	}

	flags[cfg.flag] = {}

	local key_display = library:new_keybind({
		text = cfg.display,
		key  = cfg.key,
		mode = cfg.mode,
	})

	local right_components
	if cfg.name then
		local obj = library:create("TextLabel", {
			Parent = self.holder,
			FontFace = library.font,
			TextColor3 = Color3.new(0.6667, 0.6667, 0.6667),
			Text = cfg.name,
			TextStrokeTransparency = 0.5,
			Size = UDim2.new(1, -26, 0, 12),
			BorderSizePixel = 0,
			BackgroundTransparency = 1,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			TextSize = 12,
			BackgroundColor3 = Color3.new(1.0000, 1.0000, 1.0000),
		})

		right_components = library:create("Frame", {
			Parent = obj,
			Position = UDim2.new(1, 15, 0, 1),
			BorderSizePixel = 0,
			Size = UDim2.new(0, 0, 1, 0),
			BackgroundColor3 = Color3.new(1.0000, 1.0000, 1.0000),
		})

		library:create("UIListLayout", { Parent=right_components, FillDirection=Enum.FillDirection.Horizontal, HorizontalAlignment=Enum.HorizontalAlignment.Right, Padding=UDim.new(0,3), SortOrder=Enum.SortOrder.LayoutOrder })
	end

	local keybind = library:create("TextButton", {
		Parent = cfg.name and right_components or self.right_holder,
		FontFace = library.font,
		TextColor3 = Color3.new(0.6667, 0.6667, 0.6667),
		Text = "[...]",
		TextStrokeTransparency = 0.5,
		Size = UDim2.new(0, 16, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		TextSize = 12,
		BackgroundColor3 = Color3.new(1.0000, 1.0000, 1.0000),
	})

	local mode_inline = library:create("Frame", {
		Parent = library.gui,
		BorderColor3 = Color3.new(0.0745, 0.0745, 0.0745),
		Size = UDim2.new(0, 57, 0, 0),
		Position = dim2(0, keybind.AbsolutePosition.X, 0, keybind.AbsolutePosition.Y - 5),
		BorderSizePixel = 0,
		ZIndex = 9999,
		AutomaticSize = Enum.AutomaticSize.Y,
		Visible = false,
		BackgroundColor3 = Color3.new(0.0314, 0.0314, 0.0314),
		FrostedTransparency = 0.95,
	})

	keybind:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
		if not mode_inline.Visible then return end
		mode_inline.Position = UDim2.new(0, keybind.AbsolutePosition.X, 0, keybind.AbsolutePosition.Y + 15)
	end)

	local mode_content = library:create("Frame", {
		Parent = mode_inline,
		Position = UDim2.new(0, 2, 0, 2),
		BorderColor3 = Color3.new(0.2196, 0.2196, 0.2196),
		Size = UDim2.new(1, -4, 1, -4),
		BackgroundColor3 = Color3.new(0.1490, 0.1490, 0.1490),
		FrostedTransparency = 0.90,
	})

	local mode_opts = library:create("Frame", {
		Parent = mode_content,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 2, 0, 2),
		BorderSizePixel = 0,
		Size = UDim2.new(1, -4, 1, -4),
		BackgroundColor3 = Color3.new(0.1961, 0.1961, 0.1961),
	})

	library:create("UIListLayout", { Parent=mode_opts, Padding=UDim.new(0,2), SortOrder=Enum.SortOrder.LayoutOrder })

	local function make_mode_btn(label)
		local b = library:create("TextButton", {
			Parent = mode_opts,
			FontFace = library.font,
			TextColor3 = Color3.new(0.6667, 0.6667, 0.6667),
			Text = label,
			TextStrokeTransparency = 0.5,
			Size = UDim2.new(1, 0, 0, 12),
			BackgroundTransparency = 1,
			TextXAlignment = Enum.TextXAlignment.Left,
			BorderSizePixel = 0,
			TextSize = 12,
			BackgroundColor3 = Color3.new(0.2549, 0.2549, 0.2549),
		})
		library:create("UIPadding", { Parent=b, PaddingBottom=UDim.new(0,1), PaddingLeft=UDim.new(0,5) })
		return b
	end

	local btn_press  = make_mode_btn("press")
	local btn_hold   = make_mode_btn("hold")
	local btn_always = make_mode_btn("always")
	library:create("UIPadding", { Parent=mode_opts, PaddingBottom=UDim.new(0,4) })

	function cfg.set_visible(bool)
		mode_inline.Visible = bool

		if bool then
			if library.current_element_open and library.current_element_open ~= cfg then
				library.current_element_open.set_visible(false)
				library.current_element_open.open = false
			end
			library.current_element_open = cfg
		end
	end

	local function highlight_current_mode()
		btn_press.BackgroundTransparency  = 1
		btn_hold.BackgroundTransparency   = 1
		btn_always.BackgroundTransparency = 1

		if cfg.mode == "toggle" then
			btn_press.BackgroundTransparency = library.ui_theme == "Frosted Glass" and 0.84 or 0
		elseif cfg.mode == "hold" then
			btn_hold.BackgroundTransparency = library.ui_theme == "Frosted Glass" and 0.84 or 0
		elseif cfg.mode == "always" then
			btn_always.BackgroundTransparency = library.ui_theme == "Frosted Glass" and 0.84 or 0
		end
	end
	cfg._refresh_theme = highlight_current_mode

	function cfg.set_mode(mode)
		cfg.mode = mode
		if mode == "always" then
			cfg.set(true)
		elseif mode == "hold" then
			cfg.set(false)
		end
		flags[cfg.flag] = { mode = cfg.mode, key = cfg.key, active = cfg.active }
	end

	function cfg.set(input)
		if type(input) == "boolean" then
			local val = (cfg.mode == "always") and true or input
			cfg.active = val
			flags[cfg.flag] = { mode = cfg.mode, key = cfg.key, active = val }
			cfg.callback(val)

		elseif tostring(input):find("Enum") then
			if input.Name == "Escape" then input = "..." end
			cfg.key = input

			local _text = keys[cfg.key] or tostring(cfg.key):gsub("Enum.", "")
			local _text2 = (tostring(_text):gsub("KeyCode.", ""):gsub("UserInputType.", "")) or "..."
			cfg.key_name = _text2
			keybind.Text = "[" .. string.lower(_text2) .. "]"
			flags[cfg.flag] = { mode = cfg.mode, key = cfg.key, active = cfg.active }
			cfg.callback(cfg.active or false)

		elseif table.find({ "toggle", "hold", "always" }, input) then
			cfg.set_mode(input)
			cfg.callback(cfg.active or false)

		elseif type(input) == "table" then
			if type(input.key) == "string" and input.key ~= "..." then
				input.key = library:convert_enum(input.key)
			end
			if input.key == Enum.KeyCode.Escape then input.key = "..." end

			if input.key ~= nil then cfg.key = input.key end

			cfg.mode = input.mode or cfg.mode or "toggle"
			if input.active ~= nil then cfg.active = input.active end

			flags[cfg.flag] = { mode = cfg.mode, key = cfg.key, active = cfg.active }

			local text = tostring(cfg.key) ~= "Enums" and (keys[cfg.key] or tostring(cfg.key):gsub("Enum.", "")) or nil
			local __text = text and (tostring(text):gsub("KeyCode.", ""):gsub("UserInputType.", "")) or "..."
			keybind.Text = "[" .. string.lower(__text) .. "]"
			cfg.key_name = __text
		end

		if cfg.keybind_name and flags[cfg.flag] then
			key_display.change_text(keybind.Text .. " " .. cfg.keybind_name .. " (" .. tostring(flags[cfg.flag].mode) .. ")")
			key_display.set_visible(cfg.active)
		end
	end

	local toggled = cfg.active or false

	btn_hold.MouseButton1Click:Connect(function()
		cfg.set_mode("hold")
		highlight_current_mode()
		cfg.set_visible(false)
		cfg.open = false
		key_display.update({ text = cfg.display, key = cfg.key, mode = cfg.mode })
	end)

	btn_press.MouseButton1Click:Connect(function()
		cfg.set_mode("toggle")
		highlight_current_mode()
		cfg.set_visible(false)
		cfg.open = false
		key_display.update({ text = cfg.display, key = cfg.key, mode = cfg.mode })
	end)

	btn_always.MouseButton1Click:Connect(function()
		cfg.set_mode("always")
		highlight_current_mode()
		cfg.set_visible(false)
		cfg.open = false
		key_display.update({ text = cfg.display, key = cfg.key, mode = cfg.mode })
	end)

	keybind.MouseButton2Click:Connect(function()
		cfg.open = not cfg.open
		if cfg.open then highlight_current_mode() end
		cfg.set_visible(cfg.open)
	end)

	keybind.MouseButton1Down:Connect(function()
		task.wait()
		keybind.Text = "..."

		if cfg.binding then
			cfg.binding:Disconnect()
			cfg.binding = nil
		end

		cfg.binding = library:connection(uis.InputBegan, function(input, game_event)
			if game_event then return end

			if input.UserInputType == Enum.UserInputType.Keyboard then
				cfg.set(input.KeyCode)
			elseif input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.MouseButton2
				or input.UserInputType == Enum.UserInputType.MouseButton3 then
				cfg.set(input.UserInputType)
			elseif input.UserInputType == Enum.UserInputType.Gamepad1
				or input.UserInputType == Enum.UserInputType.Gamepad2
				or input.UserInputType == Enum.UserInputType.Gamepad3
				or input.UserInputType == Enum.UserInputType.Gamepad4 then

				if input.KeyCode ~= Enum.KeyCode.Unknown
					and input.KeyCode ~= Enum.KeyCode.Thumbstick1
					and input.KeyCode ~= Enum.KeyCode.Thumbstick2 then
					cfg.set(input.KeyCode)
				end
			end

			key_display.update({ text = cfg.display, key = cfg.key, mode = cfg.mode })

			if cfg.binding then
				cfg.binding:Disconnect()
				cfg.binding = nil
			end
		end)
	end)

	library:connection(uis.InputBegan, function(input, game_event)
		if game_event then return end
		if cfg.binding then return end

		local function resolve_key(inp)
			if inp.UserInputType == Enum.UserInputType.Keyboard then
				return inp.KeyCode
			elseif inp.UserInputType == Enum.UserInputType.Gamepad1
				or inp.UserInputType == Enum.UserInputType.Gamepad2
				or inp.UserInputType == Enum.UserInputType.Gamepad3
				or inp.UserInputType == Enum.UserInputType.Gamepad4 then
				if inp.KeyCode ~= Enum.KeyCode.Unknown
					and inp.KeyCode ~= Enum.KeyCode.Thumbstick1
					and inp.KeyCode ~= Enum.KeyCode.Thumbstick2 then
					return inp.KeyCode
				end
			else
				return inp.UserInputType
			end
			return nil
		end

		local matched_key = resolve_key(input)
		if matched_key == cfg.key then
			if cfg.mode == "toggle" then
				toggled = not toggled
				cfg.set(toggled)
			elseif cfg.mode == "hold" then
				cfg.set(true)
			end
		end
	end)

	library:connection(uis.InputEnded, function(input, game_event)
		if game_event then return end
		local function resolve_key_end(inp)
			if inp.UserInputType == Enum.UserInputType.Keyboard then
				return inp.KeyCode
			elseif inp.UserInputType == Enum.UserInputType.Gamepad1
				or inp.UserInputType == Enum.UserInputType.Gamepad2
				or inp.UserInputType == Enum.UserInputType.Gamepad3
				or inp.UserInputType == Enum.UserInputType.Gamepad4 then
				if inp.KeyCode ~= Enum.KeyCode.Unknown
					and inp.KeyCode ~= Enum.KeyCode.Thumbstick1
					and inp.KeyCode ~= Enum.KeyCode.Thumbstick2 then
					return inp.KeyCode
				end
			else
				return inp.UserInputType
			end
			return nil
		end
		local matched_key = resolve_key_end(input)
		if matched_key == cfg.key and cfg.mode == "hold" then
			cfg.set(false)
		end
	end)

	cfg.set({ mode = cfg.mode, active = cfg.active, key = cfg.key })
	key_display.update({ text = cfg.display, key = cfg.key, mode = cfg.mode })

	library.config_flags[cfg.flag] = cfg.set

	local _kb_root
	if cfg.name then
		_kb_root = right_components and right_components.Parent or keybind
	else
		_kb_root = (self.right_holder and self.right_holder.Parent) or keybind
	end
	cfg._keybind_button = keybind
	table.insert(library.nav_elements, { cfg = cfg, type = "keybind", root = _kb_root, tab = self._web_tab or "General", section = self._web_section or self.name or "Controls" })

	return setmetatable(cfg, library)
end

function library:button(properties)
	local cfg = {
		callback = properties.callback or function() end,
		name = properties.text or properties.name or "Button",
		double_click = properties.DoubleClick or properties.double_click or false,
		tooltip = properties.Tooltip or properties.tooltip or nil,
	}

	local button_inline = library:create("Frame", {
		Parent = self.holder,
		Position = UDim2.new(0, -15, 0, 2),
		BorderColor3 = Color3.new(0.0745, 0.0745, 0.0745),
		Size = UDim2.new(1, -26, 0, 16),
		BorderSizePixel = 0,
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Color3.new(0.0314, 0.0314, 0.0314),
		FrostedTransparency = 0.97,
	})

	library:create("UIListLayout", {
		Parent = button_inline,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 2),
	})

	local main_button = library:create("TextButton", {
		Parent = button_inline,
		FontFace = library.font,
		TextColor3 = Color3.new(0.6667, 0.6667, 0.6667),
		BorderColor3 = Color3.new(0.2196, 0.2196, 0.2196),
		Text = cfg.name,
		TextStrokeTransparency = 0.5,
		Size = UDim2.new(1, -4, 0, 12),
		TextSize = 12,
		BackgroundColor3 = Color3.new(0.1490, 0.1490, 0.1490),
		FrostedTransparency = 0.86,
	})

	if cfg.double_click then
		local confirmed = false
		main_button.MouseButton1Click:Connect(function()
			if confirmed then
				confirmed = false
				main_button.Text = cfg.name
				cfg.callback()
			else
				confirmed = true
				main_button.Text = "Are you sure?"
				task.delay(2, function()
					if confirmed then
						confirmed = false
						main_button.Text = cfg.name
					end
				end)
			end
		end)
	else
		main_button.MouseButton1Click:Connect(function()
			cfg.callback()
		end)
	end

	local btn_api = {
		callback = cfg.callback,
		name = cfg.name,
	}

	function btn_api:AddButton(sub_properties)
		local sub_cfg = {
			callback = sub_properties.callback or function() end,
			name = sub_properties.text or sub_properties.name or "Sub Button",
			double_click = sub_properties.DoubleClick or sub_properties.double_click or true,
			tooltip = sub_properties.Tooltip or sub_properties.tooltip or nil,
		}

		local sub_btn = library:create("TextButton", {
			Parent = button_inline,
			FontFace = library.font,
			TextColor3 = Color3.new(0.6667, 0.6667, 0.6667),
			BorderColor3 = Color3.new(0.2196, 0.2196, 0.2196),
			Text = sub_cfg.name,
			TextStrokeTransparency = 0.5,
			Size = UDim2.new(1, -4, 0, 12),
			TextSize = 12,
			BackgroundColor3 = Color3.new(0.1490, 0.1490, 0.1490),
			FrostedTransparency = 0.86,
		})

		if sub_cfg.double_click then
			local confirmed = false
			sub_btn.MouseButton1Click:Connect(function()
				if confirmed then
					confirmed = false
					sub_btn.Text = sub_cfg.name
					sub_cfg.callback()
				else
					confirmed = true
					sub_btn.Text = "Are you sure?"
					task.delay(2, function()
						if confirmed then
							confirmed = false
							sub_btn.Text = sub_cfg.name
						end
					end)
				end
			end)
		else
			sub_btn.MouseButton1Click:Connect(function()
				sub_cfg.callback()
			end)
		end

		table.insert(library.nav_elements, { cfg = sub_cfg, type = "button", root = sub_btn, tab = self._web_tab or "General", section = self._web_section or self.name or "Controls" })

		return btn_api
	end

	table.insert(library.nav_elements, { cfg = cfg, type = "button", root = main_button, tab = self._web_tab or "General", section = self._web_section or self.name or "Controls" })

	return setmetatable(btn_api, library)
end

function library:AddGroupbox(Info)
	Info = Info or {}
	local Groupbox = {
		Name = Info.Name or "Groupbox",
		IsCurveBox = Info.CurveBox or false,
		Flag = Info.flag or Info.Flag or nil,
	}

	local grp_outer = library:create("Frame", {
		Parent = library.gui,
		Name = Info.Name or "CurveGroupbox",
		Active = true,
		Draggable = false,
		AnchorPoint = Vector2.new(0, 0),
		Position = Info.Position or UDim2.fromOffset(600, 120),
		Size = UDim2.fromOffset(280, 230),
		BackgroundColor3 = Color3.new(0.1569, 0.1569, 0.1569),
		BorderColor3 = Color3.new(0.0314, 0.0314, 0.0314),
		ZIndex = 10,
		FrostedTransparency = 0.94,
	})
	library:make_draggable(grp_outer)

	local grp_accent = library:create("Frame", {
		Parent = grp_outer,
		BorderColor3 = Color3.new(0.1333, 0.1333, 0.1333),
		Size = UDim2.new(1, 0, 0, 2),
		BorderSizePixel = 0,
		BackgroundColor3 = themes.preset.accent,
		ZIndex = 11,
	})
	library:apply_theme(grp_accent, "accent", "BackgroundColor3")

	library:create("Frame", {
		Parent = grp_outer,
		BackgroundTransparency = 0.5,
		Position = UDim2.new(0, 0, 0, 1),
		BorderColor3 = Color3.new(0.0000, 0.0000, 0.0000),
		Size = UDim2.new(1, 0, 0, 1),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.new(0.0000, 0.0000, 0.0000),
		ZIndex = 11,
	})

	local grp_glow = library:create("ImageLabel", {
		Parent = grp_outer,
		ImageColor3 = themes.preset.accent,
		ScaleType = Enum.ScaleType.Slice,
		ImageTransparency = 0.9,
		BorderColor3 = Color3.new(0.0000, 0.0000, 0.0000),
		BackgroundColor3 = Color3.new(1.0000, 1.0000, 1.0000),
		Image = "http://www.roblox.com/asset/?id=18245826428",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, -20, 0, -20),
		Size = UDim2.new(1, 40, 0, 42),
		ZIndex = 11,
		BorderSizePixel = 0,
		SliceCenter = Rect.new(Vector2.new(21, 21), Vector2.new(79, 79)),
	})
	library:apply_theme(grp_glow, "accent", "ImageColor3")

	local grp_inline1 = library:create("Frame", {
		Parent = grp_outer,
		Position = UDim2.new(0, 2, 0, 2),
		BorderColor3 = Color3.new(0.0000, 0.0000, 0.0000),
		Size = UDim2.new(1, -4, 1, -4),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.new(0.1020, 0.1020, 0.1020),
		ZIndex = 11,
		FrostedTransparency = 0.97,
	})

	local grp_frame = library:create("Frame", {
		Parent = grp_inline1,
		Position = UDim2.new(0, 2, 0, 2),
		BorderColor3 = Color3.new(0.2235, 0.2235, 0.2235),
		Size = UDim2.new(1, -4, 1, -4),
		BackgroundColor3 = Color3.new(0.1020, 0.1020, 0.1020),
		ZIndex = 12,
		FrostedTransparency = 0.98,
	})

	local grp_tab = library:create("Frame", {
		Parent = grp_frame,
		Position = UDim2.new(0, 6, 0, 6),
		BorderColor3 = Color3.new(0.0745, 0.0745, 0.0745),
		Size = UDim2.new(1, -12, 1, -12),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.new(0.0745, 0.0745, 0.0745),
		ZIndex = 12,
		FrostedTransparency = 0.99,
	})

	local grp_inner = library:create("Frame", {
		Parent = grp_tab,
		Position = UDim2.new(0, 2, 0, 2),
		BorderColor3 = Color3.new(0.2196, 0.2196, 0.2196),
		Size = UDim2.new(1, -4, 1, -4),
		BackgroundColor3 = Color3.new(0.0863, 0.0863, 0.0863),
		ZIndex = 13,
		FrostedTransparency = 0.90,
	})

	library:create("TextLabel", {
		Parent = grp_inner,
		FontFace = library.font,
		TextColor3 = Color3.new(0.6667, 0.6667, 0.6667),
		Text = Info.Name or "",
		TextStrokeTransparency = 0.5,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 12),
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 8, 0, 2),
		ZIndex = 14,
		TextSize = 12,
		BackgroundColor3 = Color3.new(1.0000, 1.0000, 1.0000),
	})

	Groupbox.BoxOuter = grp_outer
	Groupbox.BoxInner = grp_inner

	if Info.CurveBox then
		table.insert(library.curve_boxes, {
			outer        = grp_outer,
			enabled_flag = Info.enabled_flag or nil,
		})
	end

	if Info.CurveBox then
		local canvas_outer = library:create("Frame", {
			Parent = grp_inner,
			Position = UDim2.new(0, 6, 0, 16),
			BorderColor3 = Color3.new(0.2196, 0.2196, 0.2196),
			Size = UDim2.new(1, -12, 0, 160),
			BackgroundColor3 = Color3.new(0.0745, 0.0745, 0.0745),
			ZIndex = 14,
		})

		local canvas_inner = library:create("Frame", {
			Parent = canvas_outer,
			Position = UDim2.new(0, 1, 0, 1),
			Size = UDim2.new(1, -2, 1, -2),
			BackgroundColor3 = Color3.new(0.0588, 0.0588, 0.0588),
			BorderSizePixel = 0,
		})

		local CurveCanvas = library:create("Frame", {
			Parent = canvas_inner,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 1, 0),
			ZIndex = 104,
			BorderSizePixel = 0,
		})

		local GridSize = 8
		for i = 1, GridSize - 1 do
			library:create("Frame", {
				Parent = CurveCanvas,
				BackgroundColor3 = Color3.new(0.1490, 0.1490, 0.1490),
				BorderSizePixel = 0,
				Position = UDim2.new(i / GridSize, 0, 0, 0),
				Size = UDim2.new(0, 1, 1, 0),
				ZIndex = 105,
			})
			library:create("Frame", {
				Parent = CurveCanvas,
				BackgroundColor3 = Color3.new(0.1490, 0.1490, 0.1490),
				BorderSizePixel = 0,
				Position = UDim2.new(0, 0, i / GridSize, 0),
				Size = UDim2.new(1, 0, 0, 1),
				ZIndex = 105,
			})
		end

		local CurvePoints  = {}
		local CurvePixels  = {}
		local PointCount   = GridSize + 1
		local PixelsPerSeg = 10

		for _ = 1, (PointCount - 1) * PixelsPerSeg do
			local px = library:create("Frame", {
				Parent = CurveCanvas,
				BackgroundColor3 = themes.preset.accent,
				BorderSizePixel = 0,
				Size = UDim2.fromOffset(2, 2),
				AnchorPoint = Vector2.new(0.5, 0.5),
				ZIndex = 106,
			})
			library:apply_theme(px, "accent", "BackgroundColor3")
			table.insert(CurvePixels, px)
		end

		local function UpdateCurve()
			local idx = 1
			for i = 1, PointCount - 1 do
				local p1 = CurvePoints[i]
				local p2 = CurvePoints[i + 1]
				if p1 and p2 then
					for j = 0, PixelsPerSeg - 1 do
						local t = j / PixelsPerSeg
						local x = p1.X + (p2.X - p1.X) * t
						local y = p1.Y + (p2.Y - p1.Y) * t
						if CurvePixels[idx] then
							CurvePixels[idx].Position = UDim2.new(x, 0, y, 0)
							idx = idx + 1
						end
					end
				end
			end
		end

		for i = 1, PointCount do
			local xPos = (i - 1) / GridSize
			local yPos = 0.5

			local PointFrame = library:create("Frame", {
				Parent = CurveCanvas,
				BackgroundColor3 = themes.preset.accent,
				BorderColor3 = Color3.new(0.0000, 0.0000, 0.0000),
				BorderSizePixel = 1,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(xPos, 0, yPos, 0),
				Size = UDim2.fromOffset(7, 7),
				ZIndex = 107,
			})
			library:apply_theme(PointFrame, "accent", "BackgroundColor3")

			local Point = { Frame = PointFrame, X = xPos, Y = yPos, Index = i }

			PointFrame.InputBegan:Connect(function(Input)
				if Input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
				library.active_drag = nil
				while uis:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
					library.active_drag = nil
					local cp = CurveCanvas.AbsolutePosition
					local cs = CurveCanvas.AbsoluteSize
					local my = uis:GetMouseLocation().Y - gui_offset
					local relY = math.clamp((my - cp.Y) / cs.Y, 0, 1)
					Point.Y = relY
					PointFrame.Position = UDim2.new(Point.X, 0, Point.Y, 0)
					UpdateCurve()
					run_service.RenderStepped:Wait()
				end
				local pts = Groupbox:GetPoints()
				if Groupbox.Flag then
					flags[Groupbox.Flag] = pts
				end
				if Groupbox.OnChanged then
					Groupbox.OnChanged(pts)
				end
			end)

			table.insert(CurvePoints, Point)
		end

		UpdateCurve()
		CurveCanvas:GetPropertyChangedSignal("AbsoluteSize"):Connect(UpdateCurve)

		local btn_row = library:create("Frame", {
			Parent = grp_inner,
			Position = UDim2.new(0, 6, 0, 182),
			Size = UDim2.new(1, -12, 0, 18),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			BackgroundColor3 = Color3.new(1.0000, 1.0000, 1.0000),
			ZIndex = 14,
		})

		local reset_inline = library:create("Frame", {
			Parent = btn_row,
			BorderColor3 = Color3.new(0.0745, 0.0745, 0.0745),
			Size = UDim2.new(1, 0, 1, 0),
			BorderSizePixel = 0,
			BackgroundColor3 = Color3.new(0.0314, 0.0314, 0.0314),
			ZIndex = 14,
		})

		local reset_btn = library:create("TextButton", {
			Parent = reset_inline,
			FontFace = library.font,
			TextColor3 = Color3.new(0.6667, 0.6667, 0.6667),
			Text = "reset curve",
			TextStrokeTransparency = 0.5,
			Position = UDim2.new(0, 2, 0, 2),
			Size = UDim2.new(1, -4, 1, -4),
			TextSize = 12,
			BackgroundColor3 = Color3.new(0.1490, 0.1490, 0.1490),
			BorderColor3 = Color3.new(0.2196, 0.2196, 0.2196),
			ZIndex = 15,
		})

		reset_btn.MouseButton1Click:Connect(function()
			for _, pt in ipairs(CurvePoints) do
				pt.Y = 0.5
				pt.Frame.Position = UDim2.new(pt.X, 0, 0.5, 0)
			end
			UpdateCurve()
			local pts = Groupbox:GetPoints()
			if Groupbox.Flag then
				flags[Groupbox.Flag] = pts
			end
			if Groupbox.OnChanged then
				Groupbox.OnChanged(pts)
			end
		end)

		function Groupbox:GetPoints()
			local out = {}
			for _, pt in ipairs(CurvePoints) do
				table.insert(out, { x = pt.X, y = pt.Y })
			end
			return out
		end

		function Groupbox:SetCurvePoints(NewPoints)
			if type(NewPoints) ~= "table" then return end
			for i, pt in ipairs(CurvePoints) do
				if NewPoints[i] then
					pt.Y = tonumber(NewPoints[i].y or NewPoints[i].Y) or pt.Y
					pt.Frame.Position = UDim2.new(pt.X, 0, pt.Y, 0)
				end
			end
			UpdateCurve()
		end

		Groupbox.CurvePoints  = CurvePoints
		Groupbox.CurveCanvas  = CurveCanvas
		Groupbox.UpdateCurve  = UpdateCurve
	end

	return Groupbox
end

function library:tabbox(properties)
	local cfg = {
		name = properties.name or properties.Name or "",
		tabs = {},
		default_tab = properties.default or properties.Default or nil,
		active_tab = nil,
		_web_tab = self._web_tab or self.name or "General",
		_web_section = properties.name or properties.Name or "Tabbox",
	}

	if self.holder then
		local pad = self.holder:FindFirstChildOfClass("UIPadding")
		if pad then
			pad.PaddingTop = UDim.new(0, 0)
			pad.PaddingBottom = UDim.new(0, 2)
		end
	end

	local box_outer = library:create("Frame", {
		Parent = self.holder,
		Size = UDim2.new(1, 0, 0, 0),
		BorderSizePixel = 0,
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Color3.new(0.2196, 0.2196, 0.2196),
		FrostedTransparency = 0.96,
	})

	local spacer = library:create("Frame", {
		Parent = box_outer,
		Size = UDim2.new(1, 0, 0, 6),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	})

	local box_inner = library:create("Frame", {
		Parent = box_outer,
		Position = UDim2.new(0, 1, 0, 1),
		Size = UDim2.new(1, -2, 0, 0),
		BorderSizePixel = 0,
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Color3.new(0.0863, 0.0863, 0.0863),
		FrostedTransparency = 0.90,
	})

	local tab_buttons = library:create("Frame", {
		Parent = box_inner,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 18),
		BorderSizePixel = 0,
	})

	library:create("UIListLayout", {
		Parent = tab_buttons,
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Left,
		HorizontalFlex = Enum.UIFlexAlignment.Fill,
		SortOrder = Enum.SortOrder.LayoutOrder,
	})

	library:create("Frame", {
		Parent = box_inner,
		Position = UDim2.new(0, 0, 0, 18),
		Size = UDim2.new(1, 0, 0, 1),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.new(0.2196, 0.2196, 0.2196),
	})

	local content_area = library:create("Frame", {
		Parent = box_inner,
		Position = UDim2.new(0, 0, 0, 19),
		Size = UDim2.new(1, 0, 0, 10),
		BorderSizePixel = 0,
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
	})

	library:create("Frame", {
		Parent = box_outer,
		Size = UDim2.new(1, 0, 0, 1),
		Position = UDim2.new(0, 0, 1, -1),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.new(0.2196, 0.2196, 0.2196),
	})

	function cfg:AddTab(tab_name)
		local tab = {}

	local tab_btn = library:create("TextButton", {
			Parent = tab_buttons,
			FontFace = library.font,
			TextColor3 = Color3.new(0.3529, 0.3529, 0.3529),
			Text = tab_name,
			TextStrokeTransparency = 0.5,
			Size = UDim2.new(1, 0, 1, 0),
			TextSize = 12,
			BackgroundColor3 = Color3.new(0.0863, 0.0863, 0.0863),
		BorderSizePixel = 0,
		FrostedTransparency = 0.86,
		AutoButtonColor = false,
	})

		local tab_btn_accent = library:create("Frame", {
			Parent = tab_btn,
			Size = UDim2.new(1, 0, 0, 1),
			Position = UDim2.new(0, 0, 1, -1),
			BorderSizePixel = 0,
			BackgroundColor3 = themes.preset.accent,
			Visible = false,
		})
		library:apply_theme(tab_btn_accent, "accent", "BackgroundColor3")

		local container = library:create("Frame", {
			Parent = content_area,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Visible = false,
			BorderSizePixel = 0,
			ClipsDescendants = false,
		})

		library:create("UIListLayout", {
			Parent = container,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 3),
		})

		library:create("UIPadding", {
			Parent = container,
			PaddingLeft = UDim.new(0, 15),
			PaddingRight = UDim.new(0, 26),
			PaddingBottom = UDim.new(0, 15),
		})

		tab.holder = container
		tab.name = tab_name
		tab._web_tab = cfg._web_tab or "General"
		tab._web_section = (cfg._web_section and (cfg._web_section .. " / ") or "") .. tab_name

		function tab:Show()
			-- Showing a tab is also the single source of truth for the underline.
			-- This keeps stale accent frames from surviving a tab switch.
			for _, t in next, cfg.tabs do
				t:Hide()
			end

			cfg.active_tab = tab_name
			container.Visible = true
			tab_btn_accent.Visible = true
			tab_btn.TextColor3 = themes.preset.text
			tab_btn.BackgroundColor3 = Color3.fromRGB(31, 31, 40)

			if box_inner then
				box_inner.AutomaticSize = Enum.AutomaticSize.None
				task.defer(function()
					box_inner.AutomaticSize = Enum.AutomaticSize.Y
				end)
			end
		end

		function tab:Hide()
			container.Visible = false
			tab_btn_accent.Visible = false
			tab_btn.TextColor3 = themes.preset.unselected_text
			tab_btn.BackgroundColor3 = Color3.fromRGB(22, 22, 29)
		end

		tab_btn.MouseButton1Click:Connect(function()
			tab:Show()
		end)

		cfg.tabs[tab_name] = tab

		setmetatable(tab, library)

		local is_default = false
		if cfg.default_tab then
			is_default = (tab_name == cfg.default_tab)
		else
			local tab_count = 0
			for _ in next, cfg.tabs do tab_count = tab_count + 1 end
			is_default = (tab_count == 1)
		end

		if is_default then
			cfg._default_tab_name = tab_name
		end

		-- Defer showing the default tab until after all tabs are added
		if cfg._show_deferred then
			-- Already scheduled, skip
		else
			cfg._show_deferred = true
			task.defer(function()
				cfg._show_deferred = nil
				local target_name = cfg._default_tab_name
				if target_name and cfg.tabs[target_name] then
					-- Hide all tabs first
					for _, t in next, cfg.tabs do
						t:Hide()
					end
					-- Show the target tab directly
					local target = cfg.tabs[target_name]
					if target then
						-- Access the container and button from the tab closure
						-- by calling Show which now properly hides all first
						target:Show()
					end
				end

				if box_outer.Parent then
					box_outer.AutomaticSize = Enum.AutomaticSize.None
					task.defer(function()
						box_outer.AutomaticSize = Enum.AutomaticSize.Y
					end)
				end
			end)
		end

		return tab
	end

	function cfg:ShowTab(tab_name)
		local target = self.tabs[tab_name or self._default_tab_name]
		if target then
			target:Show()
			return true
		end
		return false
	end

	function cfg:GetActiveTab()
		return self.active_tab
	end

	function cfg:AddLeftTab(tab_name)
		return cfg:AddTab(tab_name)
	end

	function cfg:AddRightTab(tab_name)
		return cfg:AddTab(tab_name)
	end

	return cfg
end

function library:add_left_tabbox(properties)
	return self:tabbox(properties)
end

function library:add_right_tabbox(properties)
	return self:tabbox(properties)
end

local function create_inventory_viewer()
	local function get_tool_icon(tool)
		local thumb = ""
		local handle = tool:FindFirstChild("Handle")
		if handle and handle:IsA("BasePart") then
			local mesh = handle:FindFirstChildOfClass("SpecialMesh")
			if mesh and mesh.TextureId ~= "" then
				thumb = mesh.TextureId
			end
		end
		if thumb == "" then
			thumb = tool.TextureId
		end
		if thumb == "" then
			thumb = "rbxassetid://18245826428"
		end
		return thumb
	end

	local function get_player_items()
		local items = {}
		local lp = players.LocalPlayer
		local char = lp.Character
		if char then
			for _, tool in ipairs(char:GetChildren()) do
				if tool:IsA("Tool") then
					table.insert(items, 1, {
						name  = tool.Name .. " (equipped)",
						image = get_tool_icon(tool),
					})
				end
			end
		end
		local backpack = lp:FindFirstChild("Backpack")
		if backpack then
			for _, tool in ipairs(backpack:GetChildren()) do
				if tool:IsA("Tool") then
					table.insert(items, {
						name  = tool.Name,
						image = get_tool_icon(tool),
					})
				end
			end
		end
		return items
	end

	local Sorting = {
		['Enabled'] = true,
		['Slot 1'] = "",
		['Slot 2'] = "",
		['Slot 3'] = "",
		['Slot 4'] = "",
		['Slot 5'] = "",
		['Slot 6'] = "",
		['Slot 7'] = "",
		['Slot 8'] = "",
		['Slot 9'] = "",
		['Slot 0'] = "",
	}

	local slot_assignments = {}
	local sorting_busy = false

	local function get_next_empty_slot()
		for i = 1, 10 do
			local slot_key = 'Slot ' .. tostring(i % 10)
			if Sorting[slot_key] == "" then
				return i
			end
		end
		return nil
	end

	local function clear_all_assignments()
		for k in pairs(Sorting) do
			if k:match("^Slot") then Sorting[k] = "" end
		end
		slot_assignments = {}
	end

	local function rebuild_assignments()
		slot_assignments = {}
		for k, v in pairs(Sorting) do
			if k:match("^Slot") and v ~= "" then
				local num = tonumber(k:match("%d+"))
				slot_assignments[v] = num
			end
		end
	end

	local function sortInventory()
		if not Sorting.Enabled then return end
		if sorting_busy then return end

		local has_any = false
		for k, v in pairs(Sorting) do
			if k:match("^Slot") and v ~= "" then has_any = true; break end
		end
		if not has_any then return end

		local player = players.LocalPlayer
		local backpack = player:FindFirstChildOfClass("Backpack")
		if not backpack then return end

		local children = backpack:GetChildren()
		if #children == 0 then return end

		local by_name = {}
		for _, tool in ipairs(children) do
			by_name[tool.Name] = tool
		end

		local removed = {}
		for i = 1, 10 do
			local slot = 'Slot ' .. tostring(i % 10)
			local name = Sorting[slot]
			if name and name ~= "" and by_name[name] then
				table.insert(removed, by_name[name])
			end
		end
		if #removed == 0 then return end

		sorting_busy = true

		for _, tool in ipairs(removed) do
			tool.Parent = nil
		end

		for i = 1, 10 do
			local slot = 'Slot ' .. tostring(i % 10)
			local desiredItemName = Sorting[slot]
			if desiredItemName and desiredItemName ~= "" and by_name[desiredItemName] then
				by_name[desiredItemName].Parent = backpack
				by_name[desiredItemName] = nil
			end
		end

		for _, tool in ipairs(removed) do
			if tool and not tool.Parent then
				tool.Parent = backpack
			end
		end

		sorting_busy = false
	end

	local tooltip = library:create("TextLabel", {
		Parent               = library.gui,
		Name                 = "InvTooltip",
		FontFace             = library.font,
		TextColor3           = Color3.new(0.7843, 0.7843, 0.7843),
		TextStrokeTransparency = 0.5,
		Text                 = "",
		TextSize             = 10,
		AutomaticSize        = Enum.AutomaticSize.XY,
		BackgroundTransparency = 0,
		BackgroundColor3     = Color3.new(0.0706, 0.0706, 0.0706),
		BorderColor3         = Color3.new(0.2196, 0.2196, 0.2196),
		BorderSizePixel      = 1,
		ZIndex               = 50,
		Visible              = false,
	})
	library:create("UIPadding", {
		Parent       = tooltip,
		PaddingTop   = UDim.new(0, 3),
		PaddingBottom= UDim.new(0, 3),
		PaddingLeft  = UDim.new(0, 6),
		PaddingRight = UDim.new(0, 6),
	})

	local strip_outer = library:create("Frame", {
		Parent           = library.gui,
		Name             = "InventoryStrip",
		Active           = true,
		AnchorPoint      = Vector2.new(0.5, 1),
		Position         = UDim2.new(0.5, 0, 1, -10),
		Size             = UDim2.new(0, 64, 0, 44),
		BackgroundColor3 = Color3.new(0.1569, 0.1569, 0.1569),
		BorderColor3     = Color3.new(0.0314, 0.0314, 0.0314),
		ClipsDescendants = true,
		ZIndex           = 4,
		Visible          = false,
	})
	library:make_draggable(strip_outer)

	local inv_accent = library:create("Frame", {
		Parent           = strip_outer,
		Size             = UDim2.new(1, 0, 0, 2),
		BorderSizePixel  = 0,
		BackgroundColor3 = themes.preset.accent,
	})
	library:apply_theme(inv_accent, "accent", "BackgroundColor3")
	library:create("Frame", {
		Parent               = strip_outer,
		BackgroundTransparency = 0.5,
		Position             = UDim2.new(0, 0, 0, 1),
		Size                 = UDim2.new(1, 0, 0, 1),
		BorderSizePixel      = 0,
		BackgroundColor3     = Color3.new(0.0000, 0.0000, 0.0000),
	})

	local inv_glow = library:create("ImageLabel", {
		Parent               = strip_outer,
		ImageColor3          = themes.preset.accent,
		ScaleType            = Enum.ScaleType.Slice,
		ImageTransparency    = 0.9,
		BackgroundColor3     = Color3.new(1.0000, 1.0000, 1.0000),
		Image                = "http://www.roblox.com/asset/?id=18245826428",
		BackgroundTransparency = 1,
		Position             = UDim2.new(0, -20, 0, -20),
		Size                 = UDim2.new(1, 40, 0, 84),
		ZIndex               = 2,
		BorderSizePixel      = 0,
		SliceCenter          = Rect.new(Vector2.new(21, 21), Vector2.new(79, 79)),
	})
	library:apply_theme(inv_glow, "accent", "ImageColor3")

	local strip_inline = library:create("Frame", {
		Parent           = strip_outer,
		Position         = UDim2.new(0, 2, 0, 2),
		Size             = UDim2.new(1, -4, 1, -4),
		BorderSizePixel  = 0,
		ClipsDescendants = true,
		BackgroundColor3 = Color3.new(0.1020, 0.1020, 0.1020),
	})

	local strip_main = library:create("Frame", {
		Parent           = strip_inline,
		Position         = UDim2.new(0, 1, 0, 1),
		Size             = UDim2.new(1, -2, 1, -2),
		BorderSizePixel  = 0,
		ClipsDescendants = true,
		BackgroundColor3 = Color3.new(0.0863, 0.0863, 0.0863),
	})

	local icon_scroll = library:create("ScrollingFrame", {
		Parent                = strip_main,
		Position             = UDim2.new(0, 4, 0, 0),
		Size                 = UDim2.new(1, -8, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel      = 0,
		ScrollBarThickness   = 0,
		AutomaticCanvasSize  = Enum.AutomaticSize.X,
		CanvasSize           = UDim2.new(0, 0, 0, 0),
		ScrollingDirection   = Enum.ScrollingDirection.X,
		VerticalScrollBarInset = Enum.ScrollBarInset.None,
		ZIndex               = 5,
	})

	library:create("UIPadding", {
		Parent       = icon_scroll,
		PaddingTop   = UDim.new(0, 4),
		PaddingBottom= UDim.new(0, 4),
		PaddingLeft  = UDim.new(0, 2),
		PaddingRight = UDim.new(0, 4),
	})

	local icon_layout = library:create("UIListLayout", {
		Parent         = icon_scroll,
		FillDirection  = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Left,
		VerticalAlignment   = Enum.VerticalAlignment.Center,
		SortOrder      = Enum.SortOrder.LayoutOrder,
		Padding        = UDim.new(0, 3),
	})

	local icon_frames = {}

	local function clear_icons()
		for _, f in ipairs(icon_frames) do
			if f and f.Parent then f:Destroy() end
		end
		icon_frames = {}
	end

	local function build_icons()
		clear_icons()
		local items = get_player_items()

		local ICON_SIZE = 32
		local ICON_PAD = 3
		local SCROLL_PAD_L = 2
		local SCROLL_PAD_R = 4
		local STRIP_MARGIN = 8

		if #items == 0 then
			strip_outer.Size = UDim2.new(0, STRIP_MARGIN, 0, 44)
			return
		end

		local content_w = #items * (ICON_SIZE + ICON_PAD) - ICON_PAD
		local total_w = content_w + SCROLL_PAD_L + SCROLL_PAD_R + STRIP_MARGIN
		strip_outer.Size = UDim2.new(0, total_w, 0, 44)

		for i, item in ipairs(items) do
			local slot = library:create("Frame", {
				Parent           = icon_scroll,
				Size             = UDim2.new(0, 32, 0, 32),
				BackgroundTransparency = 1,
				BorderSizePixel  = 0,
				LayoutOrder      = i,
			})
			table.insert(icon_frames, slot)

			local icon_bg = library:create("Frame", {
				Parent           = slot,
				Size             = UDim2.new(1, 0, 1, 0),
				BackgroundColor3 = Color3.new(0.0745, 0.0745, 0.0745),
				BorderSizePixel  = 0,
			})

			library:create("UIStroke", {
				Parent       = icon_bg,
				Color        = Color3.new(0.2196, 0.2196, 0.2196),
				Thickness    = 1,
				LineJoinMode = Enum.LineJoinMode.Miter,
			})

			local icon_img = library:create("ImageLabel", {
				Parent               = icon_bg,
				Position             = UDim2.new(0, 2, 0, 2),
				Size                 = UDim2.new(1, -4, 1, -4),
				BackgroundTransparency = 1,
				BorderSizePixel      = 0,
				Image                = item.image,
				ScaleType            = Enum.ScaleType.Fit,
				BackgroundColor3     = Color3.new(1.0000, 1.0000, 1.0000),
			})

		local hover_btn = library:create("TextButton", {
			Parent               = slot,
			Size                 = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			Text                 = "",
			ZIndex               = 10,
		})

		local tool_name = item.name:gsub(" %(equipped%)$", "")
		local assigned_slot = slot_assignments[tool_name]
		local save_btn = library:create("TextButton", {
			Parent               = slot,
			Size                 = UDim2.new(0, 12, 0, 12),
			Position             = UDim2.new(1, -13, 0, 1),
			BackgroundColor3     = Color3.new(0.0588, 0.0588, 0.0588),
			BorderSizePixel      = 0,
			Text                 = assigned_slot and tostring(assigned_slot % 10) or "S",
			TextColor3           = assigned_slot and themes.preset.accent or Color3.new(1.0000, 1.0000, 1.0000),
			FontFace             = library.font,
			TextSize             = 8,
			ZIndex               = 15,
		})

		library:create("UICorner", {
			Parent       = save_btn,
			CornerRadius = UDim.new(0, 2),
		})

		save_btn.MouseButton1Click:Connect(function()
			if slot_assignments[tool_name] then
				local old_slot = slot_assignments[tool_name]
				local old_slot_key = 'Slot ' .. tostring(old_slot % 10)
				Sorting[old_slot_key] = ""
				slot_assignments[tool_name] = nil
			else
				local new_slot = get_next_empty_slot()
				if new_slot then
					local slot_key = 'Slot ' .. tostring(new_slot % 10)
					Sorting[slot_key] = tool_name
					slot_assignments[tool_name] = new_slot
				end
			end
			sortInventory()
			build_icons()
		end)

		hover_btn.MouseEnter:Connect(function()
			tooltip.Text = item.name
			tooltip.Visible = true
			local abs_pos = slot.AbsolutePosition
			tooltip.Position = UDim2.new(0, abs_pos.X + 16, 0, abs_pos.Y - 24)
		end)

		hover_btn.MouseLeave:Connect(function()
			tooltip.Visible = false
		end)
		end
	end

	library:connection(players.LocalPlayer.CharacterAdded, function()
		task.wait(0.5)
		build_icons()
	end)

	local function watch_backpack(bp)
		if not bp then return end
		library:connection(bp.ChildAdded, function()
			if sorting_busy then return end
			task.defer(function()
				if sorting_busy then return end
				sortInventory()
				build_icons()
			end)
		end)
		library:connection(bp.ChildRemoved, function()
			if sorting_busy then return end
			build_icons()
		end)
	end

	watch_backpack(players.LocalPlayer:FindFirstChild("Backpack"))
	library:connection(players.LocalPlayer.CharacterAdded, function()
		local new_bp = players.LocalPlayer:WaitForChild("Backpack", 5)
		watch_backpack(new_bp)
	end)

	local inv = {}

	function inv.set_visible(bool)
		strip_outer.Visible = bool
		if not bool then tooltip.Visible = false end
		if bool then build_icons() end
	end

	function inv.toggle()
		inv.set_visible(not strip_outer.Visible)
	end

	function inv.refresh()
		build_icons()
	end

	function inv.get_layout()
		local saved = { Enabled = Sorting.Enabled == true }
		for i = 1, 10 do
			local key = "Slot " .. tostring(i % 10)
			saved[key] = tostring(Sorting[key] or "")
		end
		return saved
	end

	function inv.apply_layout(saved, savedPosition, x, y)
		if type(saved) == "table" then
			Sorting.Enabled = saved.Enabled ~= false
			for i = 1, 10 do
				local key = "Slot " .. tostring(i % 10)
				Sorting[key] = type(saved[key]) == "string" and saved[key] or ""
			end
			rebuild_assignments()
		end

		if typeof(savedPosition) == "UDim2" then
			strip_outer.Position = savedPosition
		elseif tonumber(x) and tonumber(y) then
			strip_outer.Position = UDim2.new(0, tonumber(x), 0, tonumber(y))
		end

		-- The saved names intentionally remain assigned when a weapon is absent.
		-- Backpack watchers apply the order as soon as those tools arrive.
		task.defer(function()
			sortInventory()
			build_icons()
		end)
	end

	inv.frame = strip_outer
	inv.sort = sortInventory
	inv.sorting = Sorting
	inv.clear_sort = clear_all_assignments
	inv.rebuild_assignments = rebuild_assignments

	build_icons()

	return inv
end

library.create_inventory_viewer = create_inventory_viewer

function library:textbox(properties)
	local cfg = {
		placeholder    = properties.placeholder or properties.placeholdertext or properties.holder or properties.holdertext or "type here...",
		default        = properties.default,
		clear_on_focus = properties.clearonfocus or false,
		flag           = properties.flag or "...",
		callback       = properties.callback or function() end,
	}

	local textbox_inline = library:create("Frame", {
		Parent = self.holder,
		Position = UDim2.new(0, -15, 0, 2),
		BorderColor3 = Color3.new(0.0745, 0.0745, 0.0745),
		Size = UDim2.new(1, -26, 0, 16),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.new(0.0314, 0.0314, 0.0314),
		FrostedTransparency = 0.97,
	})

	local textbox = library:create("TextBox", {
		Parent = textbox_inline,
		FontFace = library.font,
		TextColor3 = Color3.new(0.6667, 0.6667, 0.6667),
		Text = "",
		TextStrokeTransparency = 0.5,
		Position = UDim2.new(0, 2, 0, 2),
		Size = UDim2.new(1, -4, 1, -4),
		ClearTextOnFocus = cfg.clear_on_focus,
		PlaceholderColor3 = Color3.new(0.3529, 0.3529, 0.3529),
		CursorPosition = -1,
		PlaceholderText = cfg.placeholder,
		TextSize = 12,
		BackgroundColor3 = Color3.new(0.1490, 0.1490, 0.1490),
		FrostedTransparency = 0.86,
	})

	textbox:GetPropertyChangedSignal("Text"):Connect(function()
		flags[cfg.flag] = textbox.Text
		cfg.callback(textbox.Text)
	end)

	function cfg.set(text)
		flags[cfg.flag] = text
		textbox.Text = text
		cfg.callback(text)
	end

	if cfg.default then
		cfg.set(cfg.default)
	end

	library.config_flags[cfg.flag] = cfg.set

	table.insert(library.nav_elements, { cfg = cfg, type = "textbox", root = textbox_inline, textbox = textbox, tab = self._web_tab or "General", section = self._web_section or self.name or "Controls" })

	return setmetatable(cfg, library)
end

function library:panel(properties)
	if library.__panel == true then return end
	library.__panel = true

	local cfg = {
		name    = properties.name or "Are you sure?",
		options = properties.options or { "Confirm", "Discard" },
		callback = properties.callback or function() end,
	}

	local panel_bg = library:create("Frame", {
		Parent = library.gui,
		BackgroundTransparency = 0.4,
		Size = UDim2.new(1, 0, 1, 0),
		BorderSizePixel = 0,
		ZIndex = 20,
		BackgroundColor3 = Color3.new(0.0000, 0.0000, 0.0000),
	})

	local panel_holder = library:create("Frame", {
		Parent = panel_bg,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Position = UDim2.new(0.5, 0, 0.5, 0),
		ZIndex = 21,
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundColor3 = Color3.new(0.1569, 0.1569, 0.1569),
	})

	local p_inline = library:create("Frame", { Parent=panel_holder, BorderColor3=Color3.new(0.0314, 0.0314, 0.0314), AutomaticSize=Enum.AutomaticSize.XY, BackgroundColor3=Color3.new(0.2196, 0.2196, 0.2196) })
	local p_main   = library:create("Frame", { Parent=p_inline, Position=UDim2.new(0,4,0,4), BorderColor3=Color3.new(0.1020, 0.1020, 0.1020), Size=UDim2.new(1,-8,1,-8), BorderSizePixel=2, BackgroundColor3=Color3.new(0.1020, 0.1020, 0.1020) })
	library:create("UIStroke", { Parent=p_main, Color=Color3.new(0.2235, 0.2235, 0.2235), LineJoinMode=Enum.LineJoinMode.Miter })

	local p_tabs = library:create("Frame", { Parent=p_main, Position=UDim2.new(0,8,0,8), BorderColor3=Color3.new(0.0314, 0.0314, 0.0314), Size=UDim2.new(1,-16,1,-16), BorderSizePixel=2, BackgroundColor3=Color3.new(0.0863, 0.0863, 0.0863) })
	library:create("UIStroke", { Parent=p_tabs, Color=Color3.new(0.2235, 0.2235, 0.2235), LineJoinMode=Enum.LineJoinMode.Miter })

	library:create("UIPadding", { Parent=p_tabs, PaddingTop=UDim.new(0,5), PaddingBottom=UDim.new(0,22), PaddingRight=UDim.new(0,20), PaddingLeft=UDim.new(0,20) })

	local p_title = library:create("TextLabel", {
		Parent = p_tabs,
		FontFace = library.font,
		LineHeight = 1.2,
		TextStrokeTransparency = 0.5,
		AnchorPoint = Vector2.new(0.5, 0),
		TextSize = 12,
		Size = UDim2.new(0, 0, 0, 11),
		TextColor3 = Color3.new(0.6667, 0.6667, 0.6667),
		Text = cfg.name,
		BackgroundTransparency = 1,
		Position = UDim2.new(0.5, 0, 0, 8),
		BorderSizePixel = 0,
		TextYAlignment = Enum.TextYAlignment.Top,
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundColor3 = Color3.new(1.0000, 1.0000, 1.0000),
	})
	library:create("UIPadding", { Parent=p_title, PaddingTop=UDim.new(0,6) })

	library:create("UIListLayout", { Parent=p_tabs, SortOrder=Enum.SortOrder.LayoutOrder, HorizontalAlignment=Enum.HorizontalAlignment.Center, Padding=UDim.new(0,4) })

	local p_frame = library:create("Frame", { Parent=p_tabs, BorderSizePixel=0, AutomaticSize=Enum.AutomaticSize.Y, BackgroundColor3=Color3.new(1.0000, 1.0000, 1.0000) })
	library:create("UIListLayout", { Parent=p_frame, SortOrder=Enum.SortOrder.LayoutOrder, HorizontalAlignment=Enum.HorizontalAlignment.Center, Padding=UDim.new(0,3) })

	for _, v in next, cfg.options do
		local bi = library:create("Frame", { Parent=p_frame, Position=UDim2.new(0,0,0,4), BorderColor3=Color3.new(0.0745, 0.0745, 0.0745), Size=UDim2.new(0,130,0,16), BorderSizePixel=0, BackgroundColor3=Color3.new(0.0314, 0.0314, 0.0314) })
		local b  = library:create("TextButton", { Parent=bi, FontFace=library.font, TextColor3=Color3.new(0.6667, 0.6667, 0.6667), Text=v, TextStrokeTransparency=0.5, Position=UDim2.new(0,2,0,2), Size=UDim2.new(1,-4,1,-4), TextSize=12, BackgroundColor3=Color3.new(0.1490, 0.1490, 0.1490) })
		b.MouseButton1Click:Connect(function()
			cfg.callback(v)
			panel_bg:Destroy()
			library.__panel = false
		end)
	end
end

local function fps_color(v)
	if v >= 55 then return Color3.new(0.3922, 0.8627, 0.5490) end
	if v >= 30 then return Color3.new(0.8627, 0.7451, 0.3137)  end
	return Color3.new(0.8627, 0.3137, 0.3137)
end
local function ping_color(v)
	if v <= 80  then return Color3.new(0.3922, 0.8627, 0.5490) end
	if v <= 150 then return Color3.new(0.8627, 0.7451, 0.3137)  end
	return Color3.new(0.8627, 0.3137, 0.3137)
end

getgenv().set_keylogger_state = function(keyName, active)
	local KL = _KL_REF
	if not KL or not KL.initialized then return end
	KL.keys[keyName] = active or nil
	local C_KEY_OFF_B = Color3.new(0.1490, 0.1490, 0.1490)
	local f = KL.frames and KL.frames[keyName]
	if not f then return end
	if active then
		f.inner.BackgroundColor3 = themes.preset.accent
		f.lbl.TextColor3         = Color3.new(0.0863, 0.0863, 0.0863)
	else
		f.inner.BackgroundColor3 = C_KEY_OFF_B
		f.lbl.TextColor3         = Color3.new(0.6667, 0.6667, 0.6667)
	end
end

getgenv().set_keylogger_visibility = function(bool)
	local KL = _KL_REF
	if not KL then return end
	KL.visible = bool
	if KL.holder then KL.holder.Visible = bool end
end

getgenv().set_keylogger_slider_visibility = function(_bool)

end

getgenv().destroy_keylogger_drawings = function()
	local KL = _KL_REF
	if not KL then return end
	if KL.holder and KL.holder.Parent then KL.holder:Destroy() end
	KL.holder = nil; KL.initialized = false; KL.frames = {}
end

getgenv().set_fps_ping_enabled = function(bool)
	local FP = _FP_REF
	if not FP then return end
	FP.enabled = bool
	if FP.holder then FP.holder.Visible = bool end
end

getgenv().set_fps_ping_visibility = function(bool)
	local FP = _FP_REF
	if not FP then return end
	if FP.holder then FP.holder.Visible = bool end
end

getgenv().destroy_fps_ping_drawings = function()
	local FP = _FP_REF
	if not FP then return end
	if FP.holder and FP.holder.Parent then FP.holder:Destroy() end
	FP.holder = nil; FP.fps_lbl = nil; FP.ping_lbl = nil; FP.initialized = false
end

getgenv().init_overlay_input = function(uis_service, _getMousePos_fn, _Camera)
	local KL = _KL_REF

	library:connection(uis_service.InputBegan, function(input, _gp)
		if not KL then KL = _KL_REF end
		local now = tick()

		if input.UserInputType == Enum.UserInputType.Keyboard then
			local keyName = KL and KL.keycode_to_key and KL.keycode_to_key[input.KeyCode]
			if keyName then getgenv().set_keylogger_state(keyName, true) end
		end

		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			if KL then
				getgenv().set_keylogger_state("M1", true)
				table.insert(KL.cps.M1, now)
			end
		elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
			if KL then
				getgenv().set_keylogger_state("M2", true)
				table.insert(KL.cps.M2, now)
			end
		end
	end)

	library:connection(uis_service.InputEnded, function(input)
		if not KL then KL = _KL_REF end
		if input.UserInputType == Enum.UserInputType.Keyboard then
			local keyName = KL and KL.keycode_to_key and KL.keycode_to_key[input.KeyCode]
			if keyName then getgenv().set_keylogger_state(keyName, false) end
		end
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			if KL then getgenv().set_keylogger_state("M1", false) end
		elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
			if KL then getgenv().set_keylogger_state("M2", false) end
		end
	end)
end

do
	local _fps_elapsed  = 0
	local _fps_frames   = 0
	local _ping_elapsed = 0
	local _stats_ok, _stats_service = pcall(function() return game:GetService("Stats") end)
	if not _stats_ok then _stats_service = nil end
	local _pos_elapsed = 0

	library:connection(run_service.Heartbeat, function(dt)
		local FP = _FP_REF
		local KL = _KL_REF

		if FP and FP.initialized and FP.holder then
			if FP.holder.Visible then
				_fps_frames  = _fps_frames + 1
				_fps_elapsed = _fps_elapsed + dt
				if _fps_elapsed >= 0.5 then
					FP.fps       = math.floor(_fps_frames / _fps_elapsed + 0.5)
					_fps_frames  = 0
					_fps_elapsed = 0
				end

				_ping_elapsed = _ping_elapsed + dt
				if _ping_elapsed >= 2 then
					_ping_elapsed = 0
					if _stats_service then
						local ok, v = pcall(function()
							return math.floor(_stats_service.Network.ServerStatsItem["Data Ping"]:GetValue() + 0.5)
						end)
						if ok and type(v) == "number" then FP.ping = v end
					end
				end

				if FP._last_fps ~= FP.fps then
					FP._last_fps = FP.fps
					if FP.fps_lbl then
						FP.fps_lbl.Text = "fps: " .. FP.fps
						FP.fps_lbl.TextColor3 = fps_color(FP.fps)
					end
				end
				if FP._last_ping ~= FP.ping then
					FP._last_ping = FP.ping
					if FP.ping_lbl then
						FP.ping_lbl.Text = "ping: " .. FP.ping
						FP.ping_lbl.TextColor3 = ping_color(FP.ping)
					end
				end
			end

			_pos_elapsed = _pos_elapsed + dt
			if _pos_elapsed >= 0.5 then
				local cfg_g = getgenv().Config
				if cfg_g and cfg_g.Overlays then
					local pos = FP.holder.Position
					cfg_g.Overlays.FPSPingX = pos.X.Offset
					cfg_g.Overlays.FPSPingY = pos.Y.Offset
				end
			end
		end

		if KL and KL.initialized and KL.holder then
			if _pos_elapsed >= 0.5 then
				local cfg_g = getgenv().Config
				if cfg_g and cfg_g.Overlays then
					local pos = KL.holder.Position
					cfg_g.Overlays.KeyloggerX = pos.X.Offset
					cfg_g.Overlays.KeyloggerY = pos.Y.Offset
				end
			end
		end

		if _pos_elapsed >= 0.5 then _pos_elapsed = 0 end
	end)

end

do

	local HOLD_INITIAL = 0.38
	local HOLD_REPEAT  = 0.12

	local nav = {
		idx           = 0,
		tab_idx       = 0,
		list          = {},
		slider_active = false,
		dd_opt        = 0,
		highlight     = nil,
		held          = {},
		hold_start    = {},
		last_repeat   = 0,
		cp_active     = false,
		_hl_width     = nil,
		_hl_height    = nil,
		_hl_x         = nil,
		_hl_y         = nil,
		_hl_transparency = nil,
	}

	local function ensure_highlight()
		if nav.highlight then return end
		if not library.gui then return end
		local hl                       = Instance.new("Frame")
		hl.Name                        = "_ctrl_nav_highlight"
		hl.BackgroundColor3            = themes.preset.accent
		hl.BackgroundTransparency      = 0.72
		hl.BorderSizePixel             = 0
		hl.ZIndex                      = 120
		hl.Visible                     = false
		local corner                   = Instance.new("UICorner")
		corner.CornerRadius            = UDim.new(0, 3)
		corner.Parent                  = hl
		hl.Parent                      = library.gui
		library:apply_theme(hl, "accent", "BackgroundColor3")
		nav.highlight = hl
	end

	local function hide_hl()
		ensure_highlight()
		if nav.highlight and nav.highlight.Visible then nav.highlight.Visible = false end
	end

	local function show_hl(e, bright)
		ensure_highlight()
		if not nav.highlight then return end
		local root = e.root
		if not root or not root.Parent then hide_hl(); return end
		local ap  = root.AbsolutePosition
		local as  = root.AbsoluteSize
		local ext = e.extend_left or 0
		local width = as.X + 8 + ext
		local height = as.Y + 6
		local x = ap.X - 4 - ext
		local y = ap.Y + gui_offset - 60
		local transparency = bright and 0.42 or 0.72

		if nav._hl_width ~= width or nav._hl_height ~= height then
			nav.highlight.Size = UDim2.fromOffset(width, height)
			nav._hl_width, nav._hl_height = width, height
		end
		if nav._hl_x ~= x or nav._hl_y ~= y then
			nav.highlight.Position = UDim2.fromOffset(x, y)
			nav._hl_x, nav._hl_y = x, y
		end
		if nav._hl_transparency ~= transparency then
			nav.highlight.BackgroundTransparency = transparency
			nav._hl_transparency = transparency
		end
		if not nav.highlight.Visible then nav.highlight.Visible = true end
	end

	local function refresh_hl()
		if nav.idx <= 0 or nav.idx > #nav.list then hide_hl(); return end
		local e = nav.list[nav.idx]
		if e then show_hl(e, nav.slider_active) end
	end

	local _nav_hl_elapsed = 0
	library:connection(run_service.Heartbeat, function(dt)
		if not library.panel_open then return end
		_nav_hl_elapsed = _nav_hl_elapsed + dt
		if _nav_hl_elapsed < (1/30) then return end
		_nav_hl_elapsed = 0
		if nav.highlight and nav.highlight.Visible then refresh_hl() end
	end)

	local function is_elem_visible(inst)
		if not inst or not inst.Parent then return false end
		if inst.AbsoluteSize.Y <= 0 then return false end
		local p = inst
		while p and p ~= game do

			local ok, visible = pcall(function() return p.Visible end)
			if not ok then break end
			if not visible then return false end
			p = p.Parent
		end
		return true
	end

	local function build_list()
		local result = {}
		for _, e in ipairs(library.nav_elements) do
			if is_elem_visible(e.root) then
				table.insert(result, e)
			end
		end

		table.sort(result, function(a, b)
			local ay = a.root.AbsolutePosition.Y
			local by = b.root.AbsolutePosition.Y
			if math.abs(ay - by) > 4 then return ay < by end
			return a.root.AbsolutePosition.X < b.root.AbsolutePosition.X
		end)
		nav.list = result
	end

	local function set_idx(i)
		local n = #nav.list
		if n == 0 then nav.idx = 0; hide_hl(); return end
		nav.idx = ((i - 1) % n) + 1
		refresh_hl()
	end

	local function focused()
		if nav.idx <= 0 or nav.idx > #nav.list then return nil end
		return nav.list[nav.idx]
	end

	local function sync_tab_idx()
		if nav.tab_idx > 0 then return end
		for i, t in ipairs(library.nav_tabs) do
			if library.current_tab and library.current_tab[1] == t.btn then
				nav.tab_idx = i; return
			end
		end
		nav.tab_idx = 1
	end

	local function switch_tab(delta)
		local tc = #library.nav_tabs
		if tc == 0 then return end
		sync_tab_idx()
		nav.tab_idx       = ((nav.tab_idx - 1 + delta) % tc) + 1
		nav.slider_active = false
		nav.dd_opt        = 0
		local t = library.nav_tabs[nav.tab_idx]
		if t and t.cfg and t.cfg.open_tab then
			t.cfg.open_tab()
			task.defer(function()
				build_list()
				nav.idx = math.min(1, #nav.list)
				refresh_hl()
			end)
		end
	end

	local function dd_set_option_colors(e)
		for i, op in ipairs(e.cfg.option_instances) do
			if i == nav.dd_opt then
				op.BackgroundTransparency = 0.72
				op.BackgroundColor3       = themes.preset.accent
				op.TextColor3             = themes.preset.text
			else
				op.BackgroundTransparency = 1
				op.BackgroundColor3       = FROSTED_GLASS_COLORS[3]
				op.TextColor3             = Color3.new(0.6667, 0.6667, 0.6667)
			end
		end
	end

	local function dd_reset_option_colors(e)
		for _, op in ipairs(e.cfg.option_instances) do
			op.BackgroundTransparency = 1
			op.BackgroundColor3       = FROSTED_GLASS_COLORS[3]
			op.TextColor3             = Color3.new(0.6667, 0.6667, 0.6667)
		end
	end

	local function dropdown_scroll(delta)
		local e = focused()
		if not e or e.type ~= "dropdown" or not e.cfg.open then return false end
		local n = #e.cfg.items
		if n == 0 then return true end
		nav.dd_opt = math.clamp(nav.dd_opt + delta, 1, n)
		dd_set_option_colors(e)
		return true
	end

	local function activate()
		local e = focused()
		if not e then return end

		if e.type == "toggle" then
			e.cfg.enabled = not e.cfg.enabled
			e.cfg.set(e.cfg.enabled)

		elseif e.type == "slider" then

			nav.slider_active = not nav.slider_active
			refresh_hl()

		elseif e.type == "button" then
			e.cfg.callback()

		elseif e.type == "dropdown" then
			if not e.cfg.open then

				if library.current_element_open and library.current_element_open ~= e.cfg then
					library.current_element_open.set_visible(false)
					library.current_element_open.open = false
				end
				e.cfg.open = true
				e.cfg.set_visible(true)
				library.current_element_open = e.cfg
				nav.dd_opt = 1
				dd_set_option_colors(e)
			else

				local opts = e.cfg.items
				if nav.dd_opt >= 1 and nav.dd_opt <= #opts then
					if e.cfg.multi then

						local sel_idx = table.find(e.cfg.multi_items, opts[nav.dd_opt])
						if sel_idx then
							table.remove(e.cfg.multi_items, sel_idx)
						else
							table.insert(e.cfg.multi_items, opts[nav.dd_opt])
						end
						e.cfg.set(e.cfg.multi_items)
						dd_set_option_colors(e)
					else

						e.cfg.set_visible(false)
						e.cfg.open = false
						if library.current_element_open == e.cfg then
							library.current_element_open = nil
						end
						e.cfg.set(opts[nav.dd_opt])
					end
				end
			end

		elseif e.type == "colorpicker" then

			e.cfg.open = not e.cfg.open
			e.cfg.set_visible(e.cfg.open)

		elseif e.type == "keybind" then

			local kb_btn = e.cfg._keybind_button
			if kb_btn then
				kb_btn.Text = "..."
				if e.cfg.binding then
					e.cfg.binding:Disconnect()
					e.cfg.binding = nil
				end
				task.delay(0.05, function()
					if e.cfg.binding then return end

					local conn
					conn = library:connection(uis.InputBegan, function(input)
						local accepted = false
						if input.UserInputType == Enum.UserInputType.Keyboard then
							e.cfg.set(input.KeyCode)
							accepted = true
						elseif input.UserInputType == Enum.UserInputType.Gamepad1
							or input.UserInputType == Enum.UserInputType.Gamepad2
							or input.UserInputType == Enum.UserInputType.Gamepad3
							or input.UserInputType == Enum.UserInputType.Gamepad4 then
							if input.KeyCode ~= Enum.KeyCode.Unknown
								and input.KeyCode ~= Enum.KeyCode.Thumbstick1
								and input.KeyCode ~= Enum.KeyCode.Thumbstick2
								and not NAV_KEYS[input.KeyCode] then
								e.cfg.set(input.KeyCode)
								accepted = true
							end
						end
						if accepted then
							conn:Disconnect()
							e.cfg.binding = nil
						end
					end)
					e.cfg.binding = conn
				end)
			end

		elseif e.type == "textbox" and e.textbox then
			e.textbox:CaptureFocus()
		end
	end

	local function go_back()
		local e = focused()
		if nav.slider_active then
			nav.slider_active = false
			refresh_hl()
		elseif e and e.type == "dropdown" and e.cfg.open then
			e.cfg.set_visible(false)
			e.cfg.open = false
			if library.current_element_open == e.cfg then
				library.current_element_open = nil
			end
			dd_reset_option_colors(e)
		else

			nav.idx           = 0
			nav.slider_active = false
			hide_hl()
		end
	end

	local function fire(kc)
		if kc == Enum.KeyCode.DPadUp then
			if nav.slider_active then return end
			local e = focused()
			if e and e.type == "dropdown" and e.cfg.open then
				dropdown_scroll(-1); return
			end
			build_list()
			if #nav.list > 0 then
				set_idx(nav.idx <= 0 and #nav.list or nav.idx - 1)
			end

		elseif kc == Enum.KeyCode.DPadDown then
			if nav.slider_active then return end
			local e = focused()
			if e and e.type == "dropdown" and e.cfg.open then
				dropdown_scroll(1); return
			end
			build_list()
			if #nav.list > 0 then
				set_idx(nav.idx <= 0 and 1 or nav.idx + 1)
			end

		elseif kc == Enum.KeyCode.DPadLeft then
			local e = focused()
			if e and e.type == "slider" and nav.slider_active then
				e.cfg.set(e.cfg.value - e.cfg.intervals)
			elseif e and e.type == "dropdown" and e.cfg.open then
				dropdown_scroll(-1)
			elseif e and e.type == "colorpicker" and e.cfg.open then

			elseif not nav.slider_active then
				switch_tab(-1)
			end

		elseif kc == Enum.KeyCode.DPadRight then
			local e = focused()
			if e and e.type == "slider" and nav.slider_active then
				e.cfg.set(e.cfg.value + e.cfg.intervals)
			elseif e and e.type == "dropdown" and e.cfg.open then
				dropdown_scroll(1)
			elseif e and e.type == "colorpicker" and e.cfg.open then

			elseif not nav.slider_active then
				switch_tab(1)
			end

		elseif kc == Enum.KeyCode.ButtonA then
			activate()

		elseif kc == Enum.KeyCode.ButtonB then
			go_back()
		end
	end

	local NAV_KEYS = {
		[Enum.KeyCode.DPadUp]    = true,
		[Enum.KeyCode.DPadDown]  = true,
		[Enum.KeyCode.DPadLeft]  = true,
		[Enum.KeyCode.DPadRight] = true,
		[Enum.KeyCode.ButtonA]   = true,
		[Enum.KeyCode.ButtonB]   = true,
	}

	library:connection(uis.InputBegan, function(input, gpe)
		if not library.panel_open then return end
		local itype = input.UserInputType
		local kc    = input.KeyCode

		if itype == Enum.UserInputType.Keyboard then
			if nav.highlight and nav.highlight.Visible then
				nav.idx           = 0
				nav.slider_active = false
				for k in pairs(nav.held)       do nav.held[k]       = false end
				for k in pairs(nav.hold_start) do nav.hold_start[k] = nil   end
				hide_hl()
			end
			return
		end

		if not NAV_KEYS[kc] then return end
		nav.held[kc]       = true
		nav.hold_start[kc] = clock()
		nav.last_repeat    = clock()
		ensure_highlight()
		fire(kc)
	end)

	library:connection(uis.InputEnded, function(input)
		local kc = input.KeyCode
		if NAV_KEYS[kc] then
			nav.held[kc]       = false
			nav.hold_start[kc] = nil
		end
	end)

	library:connection(run_service.Heartbeat, function()
		if not library.panel_open then return end
		local now = clock()
		for kc, held in pairs(nav.held) do
			if held and nav.hold_start[kc] then
				if now - nav.hold_start[kc] >= HOLD_INITIAL then
					if now - nav.last_repeat >= HOLD_REPEAT then
						nav.last_repeat = now
						fire(kc)
					end
				end
			end
		end
	end)

	library:connection(run_service.Heartbeat, function(dt)
		if not library.panel_open then return end
		local e = focused()
		if not e or e.type ~= "colorpicker" or not e.cfg.open then
			nav.cp_active = false
			return
		end
		nav.cp_active = true

		local ok, states = pcall(function()
			return uis:GetGamepadState(Enum.UserInputType.Gamepad1)
		end)
		if not ok or not states then return end

		local lx, ly, rx = 0, 0, 0
		for _, state in ipairs(states) do
			if state.KeyCode == Enum.KeyCode.Thumbstick1 then
				lx = state.Position.X
				ly = -state.Position.Y
			elseif state.KeyCode == Enum.KeyCode.Thumbstick2 then
				rx = state.Position.X
			end
		end

		local DEAD   = 0.12
		local SPEED  = 0.6

		local cfg = e.cfg
		local h2, s2, v2 = cfg.color:ToHSV()
		local a2 = cfg.alpha
		local changed = false

		if math.abs(lx) > DEAD or math.abs(ly) > DEAD then
			s2 = math.clamp(s2 + lx * SPEED * dt, 0, 1)
			v2 = math.clamp(v2 - ly * SPEED * dt, 0, 1)
			changed = true
		end

		if math.abs(rx) > DEAD then
			h2 = math.clamp(h2 + rx * SPEED * dt, 0, 1)
			changed = true
		end

		if changed then
			cfg.set(Color3.fromHSV(h2, s2, v2), a2)
		end
	end)

	library:connection(run_service.Heartbeat, function()
		if not library.panel_open then
			local any = false
			for _, v in pairs(nav.held) do if v then any = true; break end end
			if any then
				for kc in pairs(nav.held)       do nav.held[kc]       = false end
				for kc in pairs(nav.hold_start) do nav.hold_start[kc] = nil   end
				hide_hl()
			end
		end
	end)

	library._ctrl_nav = nav
end

function library:show_welcome(properties)
	local VERSION = properties.version or "1.0.0"
	local TITLE = properties.name or "VNEO"
	local CHANGELOG_URL = ""

	local welcomed_path = library.directory .. "/.welcomed"
	if isfile(welcomed_path) then return end

	local welcome_gui = library:create("ScreenGui", {
		Name = "WelcomeScreenGui",
		IgnoreGuiInset = true,
		DisplayOrder = 100,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = coregui,
	})

	local overlay = library:create("Frame", {
		Parent = welcome_gui,
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Color3.fromRGB(5, 5, 8),
		BackgroundTransparency = 0.35,
		BorderSizePixel = 0,
		ZIndex = 100,
	})

	local panel = library:create("Frame", {
		Parent = overlay,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, 420, 0, 340),
		BackgroundColor3 = Color3.new(0.0863, 0.0863, 0.0863),
		BorderColor3 = Color3.new(0.0314, 0.0314, 0.0314),
		ZIndex = 101,
	})

	local accent_bar = library:create("Frame", {
		Parent = panel,
		Size = UDim2.new(1, 0, 0, 2),
		BorderSizePixel = 0,
		BackgroundColor3 = themes.preset.accent,
		ZIndex = 102,
	})
	library:apply_theme(accent_bar, "accent", "BackgroundColor3")

	library:create("TextLabel", {
		Parent = panel,
		FontFace = library.font,
		TextColor3 = Color3.new(0.7843, 0.7843, 0.7843),
		Text = TITLE,
		TextStrokeTransparency = 0.5,
		Size = UDim2.new(1, 0, 0, 24),
		Position = UDim2.new(0, 0, 0, 10),
		BackgroundTransparency = 1,
		TextSize = 14,
		ZIndex = 102,
		BorderSizePixel = 0,
	})

	library:create("TextLabel", {
		Parent = panel,
		FontFace = library.font,
		TextColor3 = Color3.new(0.4706, 0.4706, 0.4706),
		Text = "v" .. VERSION,
		TextStrokeTransparency = 0.5,
		Size = UDim2.new(1, 0, 0, 14),
		Position = UDim2.new(0, 0, 0, 32),
		BackgroundTransparency = 1,
		TextSize = 11,
		ZIndex = 102,
		BorderSizePixel = 0,
	})

	library:create("TextLabel", {
		Parent = panel,
		FontFace = library.font,
		TextColor3 = Color3.new(0.6667, 0.6667, 0.6667),
		Text = "changelog",
		TextStrokeTransparency = 0.5,
		Size = UDim2.new(1, 0, 0, 14),
		Position = UDim2.new(0, 16, 0, 54),
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextSize = 12,
		ZIndex = 102,
		BorderSizePixel = 0,
	})

	local changelog_outer = library:create("Frame", {
		Parent = panel,
		Position = UDim2.new(0, 16, 0, 72),
		Size = UDim2.new(1, -32, 0, 200),
		BackgroundColor3 = Color3.new(0.0314, 0.0314, 0.0314),
		BorderColor3 = Color3.new(0.0745, 0.0745, 0.0745),
		BorderSizePixel = 0,
		ZIndex = 102,
	})

	local changelog_inner = library:create("Frame", {
		Parent = changelog_outer,
		Position = UDim2.new(0, 2, 0, 2),
		Size = UDim2.new(1, -4, 1, -4),
		BackgroundColor3 = Color3.new(0.0588, 0.0588, 0.0588),
		BorderSizePixel = 0,
		ZIndex = 102,
	})

	local changelog_scroll = library:create("ScrollingFrame", {
		Parent = changelog_inner,
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = themes.preset.accent,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		ZIndex = 103,
	})
	library:apply_theme(changelog_scroll, "accent", "ScrollBarImageColor3")

	library:create("UIPadding", {
		Parent = changelog_scroll,
		PaddingTop = UDim.new(0, 6),
		PaddingBottom = UDim.new(0, 6),
		PaddingLeft = UDim.new(0, 8),
		PaddingRight = UDim.new(0, 8),
	})

	local changelog_text = library:create("TextLabel", {
		Parent = changelog_scroll,
		FontFace = library.font,
		TextColor3 = Color3.new(0.5882, 0.5882, 0.5882),
		Text = "loading...",
		TextStrokeTransparency = 0.5,
		TextWrapped = true,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextSize = 11,
		ZIndex = 103,
		BorderSizePixel = 0,
	})

	local btn_outer = library:create("Frame", {
		Parent = panel,
		Position = UDim2.new(0, 16, 1, -42),
		Size = UDim2.new(1, -32, 0, 24),
		BackgroundColor3 = Color3.new(0.0314, 0.0314, 0.0314),
		BorderColor3 = Color3.new(0.0745, 0.0745, 0.0745),
		BorderSizePixel = 0,
		ZIndex = 102,
	})

	local continue_btn = library:create("TextButton", {
		Parent = btn_outer,
		FontFace = library.font,
		TextColor3 = Color3.new(0.6667, 0.6667, 0.6667),
		Text = "continue",
		TextStrokeTransparency = 0.5,
		Position = UDim2.new(0, 2, 0, 2),
		Size = UDim2.new(1, -4, 1, -4),
		TextSize = 12,
		BackgroundColor3 = Color3.new(0.1490, 0.1490, 0.1490),
		BorderColor3 = Color3.new(0.2196, 0.2196, 0.2196),
		ZIndex = 103,
	})

	continue_btn.MouseButton1Click:Connect(function()
		writefile(welcomed_path, "1")
		welcome_gui:Destroy()
		if properties.on_continue then
			properties.on_continue()
		end
	end)

	changelog_text.Text = "Local-only build: changelog disabled."
end

return library
