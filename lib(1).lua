--========================================================--
--  PHANTOM FORCES ENV DETECT SKIP
--  Must be at the very top so it runs before any injected
--  env-detect prefix checks the environment.
--========================================================--
do
	local _ENV_SKIP_IDS = {
		[292439477]       = true, -- Phantom Forces (PlaceId)
		[113491250]       = true, -- Phantom Forces (GameId)
		[7264587281]      = true, -- Sniper Duels
		[109397169461300] = true, -- Sniper Duels
		[6035872082]	  = true, -- Rivals (PlaceId)
		[17625359962]	  = true, -- Rivals (GameId)
	}
	if game and (_ENV_SKIP_IDS[game.PlaceId] or _ENV_SKIP_IDS[game.GameId]) then
		if getgenv then getgenv().XYLOS_SKIP_ENV_DETECT = true end
	end
end

local uis = game:GetService("UserInputService")
local players = game:GetService("Players")
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

-- library init
local library = {
	flags = {},
	config_flags = {},
	connections = {},
	notifications = {},
	instances = {},
	main_frame = {},
	curve_boxes = {},   -- tracks all floating curve editor outer frames
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

	directory = "Erme",
	folders = {
		"/fonts",
		"/configs",
		"/themes",
	},
	font = nil,

	-- background theme state
	bg_theme = nil,
	bg_theme_connection = nil,
	bg_canvas = nil,
	bg_blur = nil,
	bg_blur_amount = 14,

	-- controller d-pad navigation
	nav_elements = {},   -- all registered focusable elements
	nav_tabs     = {},   -- all registered tabs (in creation order)
}

local flags = library.flags
local config_flags = library.config_flags

local themes = {
	preset = {
		["outline"] = rgb(32, 32, 38),
		["inline"] = rgb(23, 23, 23),
		["accent"] = rgb(100, 100, 255),
		["contrast"] = rgb(19, 19, 19),
		["text"] = rgb(170, 170, 170),
		["unselected_text"] = rgb(90, 90, 90),
		["text_outline"] = rgb(0, 0, 0),
		["glow"] = rgb(100, 100, 255),
	},

	-- Targeted registration: elements explicitly registered for theme updates
	registered = {
		outline  = {},  -- { {instance, property}, ... }
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

	-- Letters A-Z
	[Enum.KeyCode.A] = "A", [Enum.KeyCode.B] = "B", [Enum.KeyCode.C] = "C",
	[Enum.KeyCode.D] = "D", [Enum.KeyCode.E] = "E", [Enum.KeyCode.F] = "F",
	[Enum.KeyCode.G] = "G", [Enum.KeyCode.H] = "H", [Enum.KeyCode.I] = "I",
	[Enum.KeyCode.J] = "J", [Enum.KeyCode.K] = "K", [Enum.KeyCode.L] = "L",
	[Enum.KeyCode.M] = "M", [Enum.KeyCode.N] = "N", [Enum.KeyCode.O] = "O",
	[Enum.KeyCode.P] = "P", [Enum.KeyCode.Q] = "Q", [Enum.KeyCode.R] = "R",
	[Enum.KeyCode.S] = "S", [Enum.KeyCode.T] = "T", [Enum.KeyCode.U] = "U",
	[Enum.KeyCode.V] = "V", [Enum.KeyCode.W] = "W", [Enum.KeyCode.X] = "X",
	[Enum.KeyCode.Y] = "Y", [Enum.KeyCode.Z] = "Z",

	-- Function keys
	[Enum.KeyCode.F1]  = "F1",  [Enum.KeyCode.F2]  = "F2",  [Enum.KeyCode.F3]  = "F3",
	[Enum.KeyCode.F4]  = "F4",  [Enum.KeyCode.F5]  = "F5",  [Enum.KeyCode.F6]  = "F6",
	[Enum.KeyCode.F7]  = "F7",  [Enum.KeyCode.F8]  = "F8",  [Enum.KeyCode.F9]  = "F9",
	[Enum.KeyCode.F10] = "F10", [Enum.KeyCode.F11] = "F11", [Enum.KeyCode.F12] = "F12",
	[Enum.KeyCode.F13] = "F13", [Enum.KeyCode.F14] = "F14", [Enum.KeyCode.F15] = "F15",

	-- Navigation / editing keys
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

	-- Numpad operators / extra
	[Enum.KeyCode.KeypadPeriod]  = "Num.",
	[Enum.KeyCode.KeypadDivide]  = "Num/",
	[Enum.KeyCode.KeypadMultiply]= "Num*",
	[Enum.KeyCode.KeypadMinus]   = "Num-",
	[Enum.KeyCode.KeypadPlus]    = "Num+",
	[Enum.KeyCode.KeypadEnter]   = "NumEnt",

	-- System keys
	[Enum.KeyCode.Print]       = "PrtSc",
	[Enum.KeyCode.ScrollLock]  = "ScrLk",
	[Enum.KeyCode.Pause]       = "Pause",
	[Enum.KeyCode.NumLock]     = "NmLk",
	[Enum.KeyCode.LeftSuper] = "LWin",
	[Enum.KeyCode.RightSuper]= "RWin",
	[Enum.KeyCode.Menu] = "Menu",
	[Enum.KeyCode.World0]      = "W0",
	[Enum.KeyCode.World1]      = "W1",

		-- Gamepad / Controller buttons (KeyCode)
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

	-- Gamepad UserInputTypes (for direct gamepad input detection)
	[Enum.UserInputType.Gamepad1]     = "GP1",
	[Enum.UserInputType.Gamepad2]     = "GP2",
	[Enum.UserInputType.Gamepad3]     = "GP3",
	[Enum.UserInputType.Gamepad4]     = "GP4",
}

library.__index = library

for _, path in next, library.folders do
	makefolder(library.directory .. path)
end

if not isfile(library.directory .. "/fonts/main.ttf") then
	local ok, fontData = pcall(function()
		return game:HttpGet("https://github.com/i77lhm/storage/raw/refs/heads/main/fonts/fs-tahoma-8px.ttf")
	end)
	if ok and fontData then
		writefile(library.directory .. "/fonts/main.ttf", fontData)
	end
end

local tahoma = {
	name = "SmallestPixel7",
	faces = {
		{
			name = "Regular",
			weight = 400,
			style = "normal",
			assetId = getcustomasset(library.directory .. "/fonts/main.ttf"),
		},
	},
}

if not isfile(library.directory .. "/fonts/main_encoded.ttf") then
	writefile(library.directory .. "/fonts/main_encoded.ttf", http_service:JSONEncode(tahoma))
end

library.font = Font.new(getcustomasset(library.directory .. "/fonts/main_encoded.ttf"), Enum.FontWeight.Regular)

-- misc functions
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

function library:make_resizable(frame)
	local Frame = Instance.new("TextButton")
	Frame.Position = dim2(1, -10, 1, -10)
	Frame.BorderColor3 = rgb(0, 0, 0)
	Frame.Size = dim2(0, 10, 0, 10)
	Frame.BorderSizePixel = 0
	Frame.BackgroundColor3 = rgb(255, 255, 255)
	Frame.Parent = frame
	Frame.BackgroundTransparency = 1
	Frame.Text = ""

	local resizing = false
	local start_size
	local start
	local og_size = frame.Size

	Frame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			resizing = true
			start = input.Position
			start_size = frame.Size
			library.active_resize = {
				frame = frame,
				start = start,
				start_size = start_size,
				og_size = og_size,
			}
		end
	end)

	library:connection(uis.InputEnded, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 and resizing then
			resizing = false
			if library.active_resize and library.active_resize.frame == frame then
				library.active_resize = nil
			end
		end
	end)
end

function library:make_draggable(frame)
	local dragging = false
	local drag_start
	local start_position

	frame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			drag_start = input.Position
			start_position = frame.Position
			library.active_drag = {
				frame = frame,
				drag_start = drag_start,
				start_position = start_position,
			}
		end
	end)

	library:connection(uis.InputEnded, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 and dragging then
			dragging = false
			if library.active_drag and library.active_drag.frame == frame then
				library.active_drag = nil
			end
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
	if not library.config_holder then
		return
	end

	local list = {}

	for idx, file in next, listfiles(library.directory .. "/configs") do
		local name = file.split(file, "/configs/")[2]
		name = name.split(name, ".cfg")[1]
		list[#list + 1] = name
	end

	library.config_holder:refresh_options(list)
end

function library:get_config()
	local Config = {}

	for _, v in flags do
		if type(v) == "table" and v.key then
			Config[_] = { active = v.active, mode = v.mode, key = tostring(v.key) }
		elseif type(v) == "table" and v["Transparency"] and v["Color"] then
			Config[_] = { Transparency = v["Transparency"], Color = v["Color"]:ToHex() }
		else
			Config[_] = v
		end
	end

	return http_service:JSONEncode(Config)
end

function library:load_config(config_json)
	local config = http_service:JSONDecode(config_json)

	for _, v in next, config do
		local function_set = library.config_flags[_]

		if function_set then
			if type(v) == "table" and v["Transparency"] and v["Color"] then
				function_set(hex(v["Color"]), v["Transparency"])
			elseif type(v) == "table" and v["active"] then
				function_set(v)
			else
				function_set(v)
			end
		end
	end
end

function library:round(number, float)
	local multiplier = 1 / (float or 1)
	return math.floor(number * multiplier + 0.5) / multiplier
end



function library:apply_theme(instance, theme, property)
	table.insert(themes.utility[theme][property], instance)
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
			local ok, match = pcall(function() return object[_] == themes.preset[theme] or object.ClassName == "UIGradient" end)
			if ok and match then
				pcall(function() object[_] = color end)
			end
		end
	end

	themes.preset[theme] = color

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

function library:register_window_theme_frames()
	library._theme_frames = {
		background = {},
		main       = {},
		outline    = {},
	}

	for _, frame in next, library.main_frame do
		-- Outer frame BackgroundColor3 = "background" (the outer panel background)
		table.insert(library._theme_frames.background, { instance = frame, property = "BackgroundColor3" })
		-- Outer frame BorderColor3 = "outline" (the dark border around the window)
		table.insert(library._theme_frames.outline, { instance = frame, property = "BorderColor3" })

		for _, child in next, frame:GetChildren() do
			-- UIStroke = "outline"
			if child:IsA("UIStroke") then
				table.insert(library._theme_frames.outline, { instance = child, property = "Color" })
			-- Main content frames: skip accent (2px), shadow (1px), glow (ImageLabel)
			-- inline2 has Size.Y.Offset = -4, so use abs() to catch it
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

	-- Find all section backgrounds (main role) by matching current inline color
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


function library:create(instance, options)
	local ins = Instance.new(instance)

	for prop, value in next, options do
		ins[prop] = value
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
		Position = UDim2.new(0, 10, 0, 10), -- default safe position
		BorderColor3 = Color3.fromRGB(8, 8, 8),
		Size = UDim2.new(0, 358, 0, 328),
		BackgroundColor3 = Color3.fromRGB(56, 56, 56),
		ZIndex = 4,
	})
	-- make draggable/resizable like other UI elements
	library:make_draggable(curve_box)
	library:make_resizable(curve_box)
	table.insert(library.main_frame, curve_box)
	-- store reference for easy access
	library.curve_box = curve_box

	-- Accent line (top)
	local curve_accent = library:create("Frame", {
		Parent = curve_box,
		BorderColor3 = Color3.fromRGB(34, 34, 34),
		Size = UDim2.new(1, 0, 0, 2),
		BorderSizePixel = 0,
		BackgroundColor3 = themes.preset.accent,
	})
	library:apply_theme(curve_accent, "accent", "BackgroundColor3")

	-- Subtle background line
	library:create("Frame", {
		Parent = curve_box,
		BackgroundTransparency = 0.5,
		Position = UDim2.new(0, 0, 0, 1),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		Size = UDim2.new(1, 0, 0, 1),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
	})

	-- Glow image (same asset as playerlist)
	local curve_glow = library:create("ImageLabel", {
		Parent = curve_box,
		ImageColor3 = themes.preset.accent,
		ScaleType = Enum.ScaleType.Slice,
		ImageTransparency = 0.9,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		Image = "http://www.roblox.com/asset/?id=18245826428",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, -20, 0, -20),
		Size = UDim2.new(1, 40, 0, 42),
		ZIndex = 2,
		BorderSizePixel = 0,
		SliceCenter = Rect.new(Vector2.new(21, 21), Vector2.new(79, 79)),
	})
	library:apply_theme(curve_glow, "accent", "ImageColor3")

	-- Reset button to clear curve points
	local resetBtn = library:create("TextButton", {
		Parent = curve_box,
		Name = "ResetButton",
		Text = "Reset Curve",
		Size = UDim2.new(0, 100, 0, 30),
		Position = UDim2.new(0, 10, 1, -40),
		BackgroundColor3 = Color3.fromRGB(200, 50, 50),
		TextColor3 = Color3.fromRGB(255, 255, 255),
		ZIndex = 5,
		AutoButtonColor = true,
	})
	resetBtn.MouseButton1Click:Connect(function()
		-- Clear stored curve points for both Aimbot and Silent Aim
		if Config and Config.Combat then
			if Config.Combat.Aimbot then Config.Combat.Aimbot.CurvePoints = {} end
			if Config.Combat.SilentAim then Config.Combat.SilentAim.CurvePoints = {} end
		end
	end)

	return curve_box
end


-- ============================================================
-- BACKGROUND THEMES
-- ============================================================

--[[
	Available themes:
		"none"        - no background effect
		"snow"        - falling snowflakes that react to cursor speed
		"shapes"      - rotating geometric shapes with pulse on mouse proximity
		"particles"   - glowing orbs that repel from the mouse cursor
		"bubbles"     - floating translucent bubbles with highlights
		"stars"       - star field that REPELS from cursor + twinkles
		"web"         - constellation web — nodes connected by lines, reacts to mouse
		"ribbons"     - flowing neon sine ribbons that drift and shift colour
]]

local BG_THEMES = {}

-- Forward-call click listener: fires callback(mx, my) on MB1 press (non-game-event).
local function on_click(callback)
	return uis.InputBegan:Connect(function(input, gp)
		if gp then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			local mp = uis:GetMouseLocation()
			callback(mp.X, mp.Y - gui_offset)
		end
	end)
end

-- Bundle multiple RBX connections into one disconnectable handle.
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

-- Helper: create the full-screen canvas that sits BEHIND everything.
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

-- Helper: add a BlurEffect for the menu blur
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

	-- destroy any existing effects first
	library:destroy_bg_effects()

	-- create fresh blur and canvas
	library.bg_blur   = make_blur()
	library.bg_canvas = make_canvas(library.gui)

	-- push all main frames to higher ZIndex so they sit above canvas
	for _, f in ipairs(library.main_frame) do
		f.ZIndex = 3
	end

	-- start the theme's animation loop
	library.bg_theme_connection = BG_THEMES[theme](library.bg_canvas, library.gui)

	-- initially hidden
	library.bg_blur.Size      = 0
	library.bg_canvas.Visible = false
end

-- NEW: destroy background effects
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

-- ================================================================
-- STARS — parallax layers · cursor repel · click nova · shooting stars
-- ================================================================
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

	local hb = run_service.Heartbeat:Connect(function(dt)
		if not canvas or not canvas.Visible then return end
		local now = clock()
		local mx, my = mouse.X, mouse.Y

		local rvx = (mx-last_mx)/(dt+0.001)
		local rvy = (my-last_my)/(dt+0.001)
		vel_x = vel_x*0.88 + rvx*0.12
		vel_y = vel_y*0.88 + rvy*0.12
		last_mx, last_my = mx, my
		local par_x = clamp(vel_x*PARALLAX,-4,4)
		local par_y = clamp(vel_y*PARALLAX,-4,4)

		shoot_timer -= dt
		if shoot_timer <= 0 then
			shoot_timer = math.random(35,80)/10
			spawn_shoot()
		end

		for _, s in ipairs(shoots) do
			if not s.active then continue end
			s.life += dt
			local t = s.life/s.max_life
			s.x += s.vx*dt; s.y += s.vy*dt
			s.frame.Position = dim2(0,s.x,0,s.y)
			s.frame.BackgroundTransparency = clamp(t*t,0.02,0.98)
			if t>=1 then s.active=false; s.frame.Visible=false end
		end

		for i=#novas,1,-1 do
			local nv = novas[i]
			nv.r += 280*dt
			nv.life += dt
			if nv.life > 0.7 then table.remove(novas,i) end
		end

		for _, s in ipairs(stars) do
			if not s.frame or not s.frame.Parent then continue end

			s.base_x += s.drift_x*dt*s.layer_speed
			s.base_y += s.drift_y*dt*s.layer_speed
			if s.base_x>vp.X+4 then s.base_x=-4 end
			if s.base_x<-4    then s.base_x=vp.X+4 end
			if s.base_y>h+4   then s.base_y=-4 end
			if s.base_y<-4    then s.base_y=h+4 end

			s.vx += par_x*dt*60*s.layer_speed
			s.vy += par_y*dt*60*s.layer_speed

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
			s.x += s.vx*dt + (s.base_x-s.x)*RETURN_S*dt
			s.y += s.vy*dt + (s.base_y-s.y)*RETURN_S*dt

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

-- ================================================================
-- WEB — starfield with mouse-proximity connections
-- ================================================================
BG_THEMES["web"] = function(canvas, gui)
	local vp = camera.ViewportSize
	local h  = vp.Y + gui_offset

	local DOT_COLS = {
		rgb(180, 190, 255), rgb(150, 165, 255), rgb(200, 205, 255),
		rgb(160, 180, 245), rgb(220, 220, 255), rgb(140, 155, 235),
	}
	local LINE_BASE_COL = rgb(140, 155, 245)

	canvas.BackgroundColor3       = rgb(7, 7, 18)
	canvas.BackgroundTransparency = 0.05

	local DOT_COUNT      = 60
	local CONNECT_RANGE  = 200
	local MAX_LINES      = 6
	local SPEED_MIN      = 12
	local SPEED_MAX      = 40

	local dots = {}
	for i = 1, DOT_COUNT do
		local x   = math.random(5, math.floor(vp.X - 5))
		local y   = math.random(5, math.floor(h - 5))
		local col = DOT_COLS[math.random(1, #DOT_COLS)]
		local sz  = math.random(2, 4)

		local angle = math.random() * math.pi * 2
		local speed = SPEED_MIN + math.random() * (SPEED_MAX - SPEED_MIN)
		local vx    = math.cos(angle) * speed
		local vy    = math.sin(angle) * speed

		local f = Instance.new("Frame")
		f.BorderSizePixel        = 0
		f.BackgroundColor3       = col
		f.BackgroundTransparency = 0.35
		f.Size                   = dim2(0, sz, 0, sz)
		f.AnchorPoint            = vec2(0.5, 0.5)
		f.Position               = dim2(0, x, 0, y)
		f.ZIndex                 = 3
		f.Parent                 = canvas

		local corner = Instance.new("UICorner")
		corner.CornerRadius = dim(0.5, 0)
		corner.Parent       = f

		table.insert(dots, {
			frame         = f,
			x             = x,
			y             = y,
			vx            = vx,
			vy            = vy,
			col           = col,
			sz            = sz,
			twk_speed     = 0.6 + math.random() * 1.4,
			twk_offset    = math.random() * math.pi * 2,
			base_alpha    = 0.25 + math.random() * 0.30,
		})
	end

	local conn_lines = {}
	for i = 1, MAX_LINES do
		local lf = Instance.new("Frame")
		lf.BorderSizePixel        = 0
		lf.BackgroundColor3       = LINE_BASE_COL
		lf.BackgroundTransparency = 1
		lf.AnchorPoint            = vec2(0, 0.5)
		lf.Size                   = dim2(0, 0, 0, 1)
		lf.ZIndex                 = 2
		lf.Parent                 = canvas
		table.insert(conn_lines, lf)
	end

	local hb = run_service.Heartbeat:Connect(function(dt)
		if not canvas or not canvas.Visible then return end
		local now = clock()

		local mx = mouse.X
		local mc_y = mouse.Y + gui_offset

		for _, dot in ipairs(dots) do
			if not dot.frame or not dot.frame.Parent then continue end

			dot.x = dot.x + dot.vx * dt
			dot.y = dot.y + dot.vy * dt

			if dot.x >  vp.X + 8 then dot.x = -8 end
			if dot.x < -8         then dot.x = vp.X + 8 end
			if dot.y >  h + 8     then dot.y = -8 end
			if dot.y < -8         then dot.y = h + 8 end

			local twk   = sin_wave(now * dot.twk_speed + dot.twk_offset) * 0.14
			local alpha = clamp(dot.base_alpha + twk, 0.05, 0.70)
			dot.frame.BackgroundTransparency = alpha
			dot.frame.Position               = dim2(0, dot.x, 0, dot.y)
		end

		local nearby = {}
		for _, dot in ipairs(dots) do
			local dx   = dot.x - mx
			local dy   = dot.y - mc_y
			local dist = math.sqrt(dx * dx + dy * dy)
			if dist < CONNECT_RANGE then
				table.insert(nearby, { dot = dot, dist = dist, dx = dx, dy = dy })
			end
		end
		table.sort(nearby, function(a, b) return a.dist < b.dist end)

		for i = 1, MAX_LINES do
			local lf    = conn_lines[i]
			local entry = nearby[i]

			if entry then
				local dx   = entry.dx
				local dy   = entry.dy
				local dist = entry.dist

				lf.Size     = dim2(0, math.floor(dist), 0, 1)
				lf.Position = dim2(0, mx, 0, mc_y)
				lf.Rotation = math.deg(math.atan2(dy, dx))

				local t = dist / CONNECT_RANGE
				lf.BackgroundTransparency = clamp(0.15 + t * 0.80, 0.15, 0.95)
				lf.BackgroundColor3       = entry.dot.col
			else
				lf.BackgroundTransparency = 1
				lf.Size                   = dim2(0, 0, 0, 1)
			end
		end
	end)

	return make_handle(hb)
end


-- ================================================================
-- RIBBONS — layered neon sine waves · dual-shadow · click turbulence
-- ================================================================
BG_THEMES["ribbons"] = function(canvas, gui)
	local vp  = camera.ViewportSize
	local h   = vp.Y + gui_offset
	local RIBBON_COUNT = 8
	local SEGMENTS     = 45
	local SEG_W        = math.ceil((vp.X + 20) / SEGMENTS)

	local turbs = {}

	local ribbons = {}
	for r=1,RIBBON_COUNT do
		local hue      = (r-1)/RIBBON_COUNT
		local amp      = math.random(28,90)
		local freq     = math.random(6,24)/10
		local speed    = math.random(20,75)/100
		local base_y   = math.random(30,math.floor(h-30))
		local thickness= math.random(2,6)
		local segs, shadow_segs = {}, {}

		for s=1,SEGMENTS do
			local seg=Instance.new("Frame")
			seg.BorderSizePixel=0; seg.BackgroundColor3=Color3.fromHSV(hue,0.80,1)
			seg.BackgroundTransparency=0.62
			seg.Size=dim2(0,SEG_W+1,0,thickness+1); seg.ZIndex=2; seg.Parent=canvas
			table.insert(segs,seg)
		end
		for s=1,SEGMENTS do
			local seg=Instance.new("Frame")
			seg.BorderSizePixel=0; seg.BackgroundColor3=Color3.fromHSV(hue,0.55,0.4)
			seg.BackgroundTransparency=0.82
			seg.Size=dim2(0,SEG_W+1,0,thickness-1); seg.ZIndex=1; seg.Parent=canvas
			table.insert(shadow_segs,seg)
		end

		table.insert(ribbons,{
			segs=segs, shadows=shadow_segs,
			hue=hue, amp=amp, freq=freq, speed=speed,
			base_y=base_y, phase=math.random(0,628)/100,
			thickness=thickness, flare=0,
		})
	end

	local hb = run_service.Heartbeat:Connect(function(dt)
		if not canvas or not canvas.Visible then return end
		local now=clock()
		local mx=mouse.X; local my=mouse.Y

		for i=#turbs,1,-1 do
			turbs[i].life+=dt
			if turbs[i].life>0.8 then table.remove(turbs,i) end
		end

		for _,rib in ipairs(ribbons) do
			rib.phase += rib.speed*dt
			rib.hue = (rib.hue + 0.03*dt) % 1
			rib.flare = max(0, rib.flare - dt*3)

			local mouse_pull = clamp((180-abs(rib.base_y-my))/180,0,1)

			for si,seg in ipairs(rib.segs) do
				if not seg or not seg.Parent then continue end
				local x = (si-1)*SEG_W
				local wave = sin_wave(x*rib.freq/vp.X*math.pi*2+rib.phase)*rib.amp
				local pull_y = (my - rib.base_y) * 0.12 * mouse_pull

				local turb_disp = 0
				for _,tr in ipairs(turbs) do
					local tdx = x - tr.cx
					local tdy = rib.base_y - tr.cy
					local td  = math.sqrt(tdx*tdx+tdy*tdy)
					local ring_r = tr.life*280
					if td < ring_r+30 and td > ring_r-30 then
						local intensity = (1-abs(td-ring_r)/30)*(1-tr.life/0.8)*40
						turb_disp = turb_disp + sin_wave(x*0.08+tr.life*15)*intensity
					end
				end

				local y = rib.base_y + wave + pull_y + turb_disp
				seg.Position = dim2(0,x,0,y)
				seg.BackgroundColor3 = Color3.fromHSV(rib.hue,0.80,1)
				seg.BackgroundTransparency = 0.62 - mouse_pull*0.15 - rib.flare*0.22

				local shd=rib.shadows[si]
				if shd and shd.Parent then
					shd.Position = dim2(0,x+2,0,y+rib.thickness+1)
					shd.BackgroundColor3 = Color3.fromHSV(rib.hue,0.55,0.3)
					shd.BackgroundTransparency = 0.82 - mouse_pull*0.08
				end
			end
		end
	end)

	local click_conn = on_click(function(cx,cy)
		table.insert(turbs,{cx=cx,cy=cy,life=0})
		for _,rib in ipairs(ribbons) do
			if abs(rib.base_y-cy)<160 then rib.flare=1 end
		end
	end)

	return make_handle(hb, click_conn)
end

-- ================================================================
-- SNOW — 3-layer parallax · click burst · cursor melt zone · sparkle
-- ================================================================
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

	local hb = run_service.Heartbeat:Connect(function(dt)
		if not canvas or not canvas.Visible then return end
		local now = clock()
		local mx = mouse.X
		wind_vel = wind_vel*0.92 + ((mx-last_mx)/dt)*0.08*0.012
		wind_vel = clamp(wind_vel,-10,10)
		last_mx  = mx
		local my = mouse.Y

		for i=#gusts,1,-1 do
			gusts[i].life+=dt
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
					gust_vy -= power*dt
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

			fk.sparkle_t -= 1
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


-- ================================================================
-- PARTICLES — orbs · velocity trails · connection lines · click explosion
-- ================================================================
BG_THEMES["particles"] = function(canvas, gui)
	local vp = camera.ViewportSize
	local h  = vp.Y + gui_offset
	local COUNT        = 50
	local REPEL_R      = 110
	local REPEL_F      = 200
	local CONNECT_DIST = 95
	local MAX_LINES    = 100
	local TRAIL_LEN    = 3

	local lines = {}
	for i=1,MAX_LINES do
		local lf=Instance.new("Frame")
		lf.BorderSizePixel=0; lf.BackgroundColor3=rgb(130,160,255)
		lf.BackgroundTransparency=0.82; lf.AnchorPoint=vec2(0,0.5)
		lf.Size=dim2(0,0,0,1); lf.ZIndex=2; lf.Visible=false; lf.Parent=canvas
		table.insert(lines,lf)
	end

	local particles = {}
	for i=1,COUNT do
		local sz  = math.random(4,14)
		local col = Color3.fromHSV(math.random(0,100)/100,0.7,1)
		local f   = Instance.new("Frame")
		f.BorderSizePixel=0; f.BackgroundColor3=col
		f.BackgroundTransparency=math.random(42,65)/100
		f.Size=dim2(0,sz,0,sz)
		local px=math.random(sz,math.floor(vp.X-sz))
		local py=math.random(sz,math.floor(h-sz))
		f.Position=dim2(0,px,0,py); f.ZIndex=3; f.Parent=canvas
		local c=Instance.new("UICorner"); c.CornerRadius=dim(0.5,0); c.Parent=f
		local glow = Instance.new("UIStroke")
		glow.Color = col
		glow.Transparency=0.80; glow.Thickness = 2.5
		glow.ZIndex=2; glow.Parent=f
		local trail={}
		for t=1,TRAIL_LEN do
			local tf=Instance.new("Frame")
			tf.BorderSizePixel=0; tf.BackgroundColor3=col
			tf.BackgroundTransparency=0.50+t*0.14
			tf.Size=dim2(0,max(1,sz-t*2),0,max(1,sz-t*2))
			tf.AnchorPoint=vec2(0.5,0.5); tf.ZIndex=2; tf.Parent=canvas
			local tc=Instance.new("UICorner"); tc.CornerRadius=dim(0.5,0); tc.Parent=tf
			table.insert(trail,{frame=tf,x=px,y=py})
		end
		table.insert(particles,{
			frame=f, glow=glow, trail=trail,
			x=px, y=py, vx=math.random(-22,22), vy=math.random(-22,22),
			size=sz, base_col=col, hue=math.random(0,100)/100,
		})
	end

	local explosions = {}

	local hb = run_service.Heartbeat:Connect(function(dt)
		if not canvas or not canvas.Visible then return end
		local mx=mouse.X; local my=mouse.Y

		for i=#explosions,1,-1 do
			explosions[i].life+=dt
			if explosions[i].life>0.6 then table.remove(explosions,i) end
		end

		for _,p in ipairs(particles) do
			if not p.frame or not p.frame.Parent then continue end

			local dx,dy=p.x-mx,p.y-my
			local dist=math.sqrt(dx*dx+dy*dy)
			if dist<REPEL_R and dist>1 then
				local force=(1-dist/REPEL_R)*REPEL_F
				p.vx+=(dx/dist)*force*dt
				p.vy+=(dy/dist)*force*dt
			end

			for _,ex in ipairs(explosions) do
				local exdx,exdy=p.x-ex.cx,p.y-ex.cy
				local exd=math.sqrt(exdx*exdx+exdy*exdy)
				if exd<180 and exd>1 then
					local push=(1-exd/180)*600*(1-ex.life/0.6)
					p.vx+=(exdx/exd)*push*dt
					p.vy+=(exdy/exd)*push*dt
				end
			end

			p.vx = p.vx*0.966 + (-dx/max(dist,1))*2*dt
			p.vy = p.vy*0.966 + (-dy/max(dist,1))*2*dt

			for t=#p.trail,1,-1 do
				local prev = t>1 and p.trail[t-1] or {x=p.x,y=p.y}
				p.trail[t].x=prev.x; p.trail[t].y=prev.y
				local tf=p.trail[t].frame
				if tf and tf.Parent then
					tf.Position=dim2(0,prev.x,0,prev.y)
				end
			end

			p.x+=p.vx*dt; p.y+=p.vy*dt
			if p.x<0 then p.x=0; p.vx=abs(p.vx) end
			if p.x>vp.X-p.size then p.x=vp.X-p.size; p.vx=-abs(p.vx) end
			if p.y<0 then p.y=0; p.vy=abs(p.vy) end
			if p.y>h-p.size then p.y=h-p.size; p.vy=-abs(p.vy) end
			p.frame.Position=dim2(0,p.x,0,p.y)

			p.hue = (p.hue + 0.08*dt) % 1
			local speed=math.sqrt(p.vx^2+p.vy^2)
			local sat=clamp(0.45+speed/120,0.45,1)
			local col=Color3.fromHSV(p.hue,sat,1)
			p.frame.BackgroundColor3=col
			if p.glow then p.glow.Color=col; p.glow.Transparency=clamp(0.78-speed/200,0.40,0.88) end
			p.frame.BackgroundTransparency=clamp(0.50-speed/300,0.15,0.65)
		end

		local li=0
		for i=1,#particles do
			local a=particles[i]
			for j=i+1,#particles do
				local b=particles[j]
				local ex,ey=b.x-a.x,b.y-a.y
				local ed=math.sqrt(ex*ex+ey*ey)
				if ed<CONNECT_DIST then
					li+=1; if li>MAX_LINES then break end
					local lf=lines[li]
					lf.Visible=true
					lf.Size=dim2(0,math.floor(ed),0,1)
					lf.Position=dim2(0,math.floor(a.x+a.size/2),0,math.floor(a.y+a.size/2))
					lf.Rotation=math.deg(math.atan2(ey,ex))
					lf.BackgroundTransparency=0.60+ed/CONNECT_DIST*0.36
					lf.BackgroundColor3=a.base_col
				end
			end
			if li>MAX_LINES then break end
		end
		for k=li+1,MAX_LINES do lines[k].Visible=false end
	end)

	local click_conn = on_click(function(cx,cy)
		table.insert(explosions,{cx=cx,cy=cy,life=0})
	end)

	return make_handle(hb, click_conn)
end

-- ================================================================
-- BUBBLES — parallax sizes · cursor flee · click pop-burst · shimmer
-- ================================================================
BG_THEMES["bubbles"] = function(canvas, gui)
	local vp = camera.ViewportSize
	local h  = vp.Y + gui_offset
	local COUNT   = 30
	local FLEE_R  = 90
	local POP_R   = 75
	local MAX_POP = 3

	local pop_snd = Instance.new("Sound")
	pop_snd.SoundId    = "rbxassetid://6534947588"
	pop_snd.Volume     = 0.55
	pop_snd.RollOffMaxDistance = 10000
	pop_snd.Parent     = canvas

	local bubbles = {}

	local function new_bubble(y_start, force_sz)
		local sz = force_sz or math.random(12,75)
		local f  = Instance.new("Frame")
		f.BorderSizePixel=0; f.BackgroundColor3=rgb(160,205,255)
		f.BackgroundTransparency=math.random(78,91)/100
		f.Size=dim2(0,sz,0,sz)
		local px=math.random(sz,math.floor(vp.X-sz))
		local py=y_start or math.random(-sz,math.floor(h))
		f.Position=dim2(0,px,0,py); f.ZIndex=2; f.Parent=canvas
		local c=Instance.new("UICorner"); c.CornerRadius=dim(0.5,0); c.Parent=f
		local shimmer=Instance.new("Frame")
		shimmer.BorderSizePixel=0; shimmer.BackgroundColor3=rgb(255,255,255)
		shimmer.BackgroundTransparency=0.60; shimmer.ZIndex=3
		local sm_sz=max(4,math.floor(sz*0.22))
		shimmer.Size=dim2(0,sm_sz,0,sm_sz)
		shimmer.Position=dim2(0.12,0,0.10,0)
		shimmer.Parent=f
		local sc=Instance.new("UICorner"); sc.CornerRadius=dim(0.5,0); sc.Parent=shimmer
		local glow = Instance.new("UIStroke")
		glow.Color = rgb(180,220,255)
		glow.Transparency=0.86; glow.Thickness = 2.5
		glow.ZIndex=2; glow.Parent=f
		return {
			frame=f, x=px, y=py or 0, sz=sz,
			base_a=math.random(78,91)/100,
			rise=math.random(16,55),
			drift=math.random(-20,20)/10,
			wobble_spd=math.random(8,22)/10,
			wobble_amp=math.random(6,22),
			wobble_off=math.random(0,628)/100,
			base_x=px, popping=false, pop_t=0,
		}
	end

	for i=1,COUNT do table.insert(bubbles, new_bubble(nil,nil)) end

	local hb = run_service.Heartbeat:Connect(function(dt)
		if not canvas or not canvas.Visible then return end
		local now=clock()
		local mx=mouse.X; local my=mouse.Y

		for i=#bubbles,1,-1 do
			local b=bubbles[i]
			if not b.frame or not b.frame.Parent then table.remove(bubbles,i); continue end

			if b.popping then
				b.pop_t+=dt
				local t=clamp(b.pop_t/0.30,0,1)
				local new_sz=math.floor(b.sz*(1+t*0.5))
				b.frame.Size=dim2(0,new_sz,0,new_sz)
				b.frame.BackgroundTransparency=clamp(b.base_a+t*0.6,0,1)
				if t>=1 then
					b.frame:Destroy()
					table.remove(bubbles,i)
					table.insert(bubbles, new_bubble(h+math.random(20,80),nil))
				end
				continue
			end

			local cdx,cdy=b.x-mx,b.y-my
			local cd=math.sqrt(cdx*cdx+cdy*cdy)
			local flee_x=0
			if cd<FLEE_R and cd>1 then
				flee_x=(cdx/cd)*(1-cd/FLEE_R)*35
			end

			b.y -= b.rise*dt
			local wx = b.base_x + sin_wave(now*b.wobble_spd+b.wobble_off)*b.wobble_amp + flee_x*dt*20
			b.x = wx
			b.frame.Position=dim2(0,wx,0,b.y)
			b.frame.BackgroundTransparency=b.base_a

			if b.y < -b.sz-10 then
				b.frame:Destroy(); table.remove(bubbles,i)
				table.insert(bubbles, new_bubble(h+math.random(10,60),nil))
			end
		end
	end)

	local click_conn = on_click(function(cx,cy)
		local popped=0
		for _,b in ipairs(bubbles) do
			if popped>=MAX_POP then break end
			if b.popping then continue end
			local dx,dy=b.x-cx,b.y-cy
			if math.sqrt(dx*dx+dy*dy)<POP_R then
				b.popping=true; b.pop_t=0
				pop_snd:Play()
				popped+=1
			end
		end
	end)

	return make_handle(hb, click_conn)
end

-- ================================================================
-- SHAPES — rotating geometry · cursor scale/brighten · click shockwave · glow
-- ================================================================
BG_THEMES["shapes"] = function(canvas, gui)
	local vp = camera.ViewportSize
	local h  = vp.Y + gui_offset
	local COUNT = 18
	local PULSE_R = 120
	local shocks = {}

	local SHAPE_COLS = {
		rgb(100,100,255), rgb(80,200,255), rgb(200,80,255),
		rgb(255,100,160), rgb(80,255,200), rgb(255,200,80),
		rgb(80,255,120),  rgb(255,140,80),
	}
	local SIZES = { 28, 42, 56, 70, 88 }

	local shapes = {}
	for i=1,COUNT do
		local c   = SHAPE_COLS[math.random(1,#SHAPE_COLS)]
		local sz  = SIZES[math.random(1,#SIZES)]
		local f   = Instance.new("Frame")
		f.BorderSizePixel=0; f.BackgroundColor3=c
		f.BackgroundTransparency=math.random(68,86)/100
		f.Size=dim2(0,sz,0,sz)
		local bx=math.random(0,math.floor(vp.X-sz))
		local by=math.random(0,math.floor(h-sz))
		f.Position=dim2(0,bx,0,by); f.ZIndex=2; f.Parent=canvas
		local shape_type=math.random(1,3)
		if shape_type>=2 then
			local corner=Instance.new("UICorner")
			corner.CornerRadius=shape_type==2 and dim(0.5,0) or dim(0.12,0)
			corner.Parent=f
		end
		local glow = Instance.new("UIStroke")
		glow.Color = c
		glow.Transparency=0.88; glow.Thickness = 2.5
		glow.ZIndex=1; glow.Parent=f
		table.insert(shapes,{
			frame=f, glow=glow, col=c,
			rot=0, rot_spd=math.random(-35,35),
			float_spd=math.random(6,20)/10,
			float_amp=math.random(12,40),
			float_off=math.random(0,628)/100,
			base_y=by, base_x=bx, sz=sz,
			vx=0, vy=0, angular_vel=0,
			base_a=math.random(68,86)/100,
		})
	end

	local hb = run_service.Heartbeat:Connect(function(dt)
		if not canvas or not canvas.Visible then return end
		local now=clock()
		local mx=mouse.X; local my=mouse.Y

		for i=#shocks,1,-1 do
			shocks[i].life+=dt
			if shocks[i].life>0.8 then table.remove(shocks,i) end
		end

		for _,sh in ipairs(shapes) do
			if not sh.frame or not sh.frame.Parent then continue end

			local fy = sh.base_y + sin_wave(now*sh.float_spd+sh.float_off)*sh.float_amp
			local fx = sh.base_x + sin_wave(now*sh.float_spd*0.7+sh.float_off+1)*sh.float_amp*0.4

			local cx,cy = fx+sh.sz/2, fy+sh.sz/2
			local dx,dy = cx-mx, cy-my
			local dist  = math.sqrt(dx*dx+dy*dy)
			local aura  = clamp(1-dist/PULSE_R,0,1)
			local scale_boost = aura*0.18

			for _,sk in ipairs(shocks) do
				local sdx,sdy=cx-sk.cx,cy-sk.cy
				local sd=math.sqrt(sdx*sdx+sdy*sdy)
				if sd<220 and sd>1 then
					local push=(1-sd/220)*500*(1-sk.life/0.8)
					sh.vx+=(sdx/sd)*push*dt
					sh.vy+=(sdy/sd)*push*dt
					sh.angular_vel += push*0.03*(math.random(0,1)==0 and 1 or -1)
				end
			end

			sh.vx=sh.vx*0.90; sh.vy=sh.vy*0.90
			sh.angular_vel=sh.angular_vel*0.92
			local final_x=fx+sh.vx*dt
			local final_y=fy+sh.vy*dt

			sh.rot = (sh.rot + (sh.rot_spd+sh.angular_vel)*dt) % 360
			sh.frame.Rotation=sh.rot

			local disp_sz=sh.sz*(1+scale_boost)
			sh.frame.Size=dim2(0,math.floor(disp_sz),0,math.floor(disp_sz))
			sh.frame.Position=dim2(0,final_x,0,final_y)
			sh.frame.BackgroundTransparency=clamp(sh.base_a-aura*0.30,0.12,0.95)
			if sh.glow then sh.glow.Transparency=clamp(0.88-aura*0.45,0.38,0.95) end
		end
	end)

	local click_conn = on_click(function(cx,cy)
		table.insert(shocks,{cx=cx,cy=cy,life=0})
	end)

	return make_handle(hb, click_conn)
end

-- ============================================================
-- Apply / remove background theme
-- ============================================================
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
	if visible then
		if library.bg_theme and library.bg_theme ~= "none" then
			if not library.bg_blur then
				library:create_bg_effects()
			end
			if library.bg_blur then
				tween_service:Create(
					library.bg_blur,
					TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
					{ Size = library.bg_blur_amount or 14 }
				):Play()
			end
			if library.bg_canvas then
				library.bg_canvas.Visible = true
			end
		end
	else
		if library.bg_blur then
			local tween = tween_service:Create(
				library.bg_blur,
				TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
				{ Size = 0 }
			)
			tween:Play()
			tween.Completed:Connect(function()
				library:destroy_bg_effects()
			end)
		else
			library:destroy_bg_effects()
		end
		if library.bg_canvas then
			library.bg_canvas.Visible = false
		end
	end
end

function library:bg_blur_slider(properties)
	properties = properties or {}
	properties.name     = properties.name or "Background Blur"
	properties.flag     = properties.flag or "__bg_blur__"
	properties.min      = properties.min  or 0
	properties.max      = properties.max  or 40
	properties.default  = properties.default ~= nil and properties.default or 14
	properties.float    = properties.float or 1
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
	properties.default  = properties.default or "none"
	properties.items    = { "none", "stars", "web", "ribbons", "snow", "particles", "bubbles", "shapes" }
	properties.callback = function(value)
		library:set_bg_theme(value)
		if value ~= "none" then
			library:set_bg_visible(true)
		end
	end
	return library.dropdown(self, properties)
end

-- ============================================================

-- ============================================================

library.gui = library:create("ScreenGui", {
	Enabled = false,
	Parent = coregui,
	Name = "",
	DisplayOrder = 2,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
})

library:connection(uis.InputChanged, function(input)
	if input.UserInputType ~= Enum.UserInputType.MouseMovement then
		return
	end

	local active_drag = library.active_drag
	if active_drag then
		local delta = input.Position - active_drag.drag_start
		active_drag.frame.Position = dim2(
			active_drag.start_position.X.Scale,
			active_drag.start_position.X.Offset + delta.X,
			active_drag.start_position.Y.Scale,
			active_drag.start_position.Y.Offset + delta.Y
		)
	end

	local active_resize = library.active_resize
	if active_resize then
		local viewport_x = camera.ViewportSize.X
		local viewport_y = camera.ViewportSize.Y

		active_resize.frame.Size = dim2(
			active_resize.start_size.X.Scale,
			clamp(
				active_resize.start_size.X.Offset + (input.Position.X - active_resize.start.X),
				active_resize.og_size.X.Offset,
				viewport_x
			),
			active_resize.start_size.Y.Scale,
			clamp(
				active_resize.start_size.Y.Offset + (input.Position.Y - active_resize.start.Y),
				active_resize.og_size.Y.Offset,
				viewport_y
			)
		)
	end

	local active_colorpicker = library.active_colorpicker
	if active_colorpicker then
		active_colorpicker:update_color()
	end
end)

library:connection(uis.InputEnded, function(input)
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
		return
	end

	library.active_drag = nil
	library.active_resize = nil

	local active_colorpicker = library.active_colorpicker
	if active_colorpicker then
		active_colorpicker.stop_dragging()
		library.active_colorpicker = nil
	end
end)

-- library functions

-- Forward refs for the keystroke / fps-ping overlay state tables.
-- Assigned inside library:window(); referenced by shims at bottom of file.
local _KL_REF = nil
local _FP_REF = nil

function library:window(properties)
	local cfg = {
		name = properties.Name or properties.name or properties.Title or properties.title or "sp4m.wtf",
		size = properties.Size or properties.size or dim2(0, 500, 0, 650),
	}

	local animated_text = library:animation(cfg.name)

	-- watermark
	local __holder = library:create("Frame", {
		Parent = library.gui,
		Name = "",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 20, 0, 20),
		BorderColor3 = Color3.fromRGB(19, 19, 19),
		ZIndex = 4,
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = Color3.fromRGB(40, 40, 40),
	})

	-- WM_PADDING = left-chain (8+2+6+2+2=20) + right-chain (21+2+6+2+2=33) = 53
	local WM_PADDING = 53
	-- generous initial estimate; locked in precisely after one layout pass below
	local wm_inline1 = library:create("Frame", {
		Parent = __holder,
		Name = "",
		Active = true,
		Draggable = false,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		Size = UDim2.new(0, math.max(#cfg.name * 8 + WM_PADDING, 120), 0, 40),
		BackgroundColor3 = Color3.fromRGB(40, 40, 40),
	})
	library:make_draggable(wm_inline1)

	local wm_accent_line = library:create("Frame", {
		Parent = wm_inline1,
		Name = "",
		BorderColor3 = Color3.fromRGB(34, 34, 34),
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
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		Size = UDim2.new(1, 0, 0, 1),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
	})

	local wm_inline2 = library:create("Frame", {
		Parent = wm_inline1,
		Name = "",
		Position = UDim2.new(0, 2, 0, 2),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		Size = UDim2.new(1, -4, 1, -4),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(26, 26, 26),
	})

	local wm_main = library:create("Frame", {
		Parent = wm_inline2,
		Name = "",
		Position = UDim2.new(0, 2, 0, 2),
		BorderColor3 = Color3.fromRGB(57, 57, 57),
		Size = UDim2.new(1, -4, 1, -4),
		BackgroundColor3 = Color3.fromRGB(26, 26, 26),
	})

	local wm_tab_inline = library:create("Frame", {
		Parent = wm_main,
		Name = "",
		Position = UDim2.new(0, 6, 0, 6),
		BorderColor3 = Color3.fromRGB(19, 19, 19),
		Size = UDim2.new(1, -12, 1, -12),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(19, 19, 19),
	})

	local wm_tabs = library:create("Frame", {
		Parent = wm_tab_inline,
		Name = "",
		Position = UDim2.new(0, 2, 0, 2),
		BorderColor3 = Color3.fromRGB(56, 56, 56),
		Size = UDim2.new(1, -4, 1, -4),
		BackgroundColor3 = Color3.fromRGB(22, 22, 22),
	})

	local wm_name = library:create("TextLabel", {
		Parent = wm_tabs,
		Name = "",
		FontFace = library.font,
		TextColor3 = Color3.fromRGB(170, 170, 170),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		Text = "ledger.live",
		TextStrokeTransparency = 0.5,
		Size = UDim2.new(0, 0, 1, 0),
		Position = UDim2.new(0, 8, 0, 0),
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left,
		BorderSizePixel = 0,
		AutomaticSize = Enum.AutomaticSize.X,
		TextSize = 12,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	})

	local TEXT_ANIMATION_GRADIENT = library:create("UIGradient", {
		Parent = wm_name,
		Name = "",
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
			ColorSequenceKeypoint.new(0.01, themes.preset.accent),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
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
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		Image = "http://www.roblox.com/asset/?id=18245826428",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, -20, 0, -20),
		Size = UDim2.new(1, 40, 0, 42),
		ZIndex = 2,
		BorderSizePixel = 0,
		SliceCenter = Rect.new(Vector2.new(21, 21), Vector2.new(79, 79)),
	})
	library:apply_theme(wm_glow, "accent", "ImageColor3")

	-- ── watermark animation state ──────────────────────────────────────────────
	local watermark_index   = 1
	local watermark_elapsed = 0
	local wm_anim_style     = "type"   -- "type" | "fade" | "array" | "matrix" | "wave" | "static"
	local wm_reveal_progress = 0
	local WM_CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789@#$%&*?!"
	local function wm_rand_char()
		local i = math.random(1, #WM_CHARS)
		return WM_CHARS:sub(i, i)
	end

	-- one-time accurate size measurement (runs after two layout passes)
	task.defer(function()
		wm_name.Text = cfg.name
		task.defer(function()
			if not (wm_inline1 and wm_inline1.Parent) then return end
			local tw = wm_name.TextBounds.X
			if tw > 0 then
				wm_inline1.Size = UDim2.new(0, tw + WM_PADDING, 0, 40)
			end
		end)
	end)

	task.wait()

	-- window
	local inline1 = library:create("Frame", {
		Parent = library.gui,
		Name = "",
		Active = true,
		Draggable = false,
		Position = UDim2.new(0.5, -cfg.size.X.Offset / 2, 0.5, -cfg.size.Y.Offset / 2),
		BorderColor3 = Color3.fromRGB(8, 8, 8),
		ZIndex = 4,
		Size = cfg.size,
		BackgroundColor3 = Color3.fromRGB(40, 40, 40),
	})
	table.insert(library.main_frame, inline1)
	local WINDOW_PATH = inline1
	library:make_draggable(inline1)
	library:make_resizable(inline1)

	local inline2 = library:create("Frame", {
		Parent = inline1,
		Name = "",
		Position = UDim2.new(0, 2, 0, 2),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		Size = UDim2.new(1, -4, 1, -4),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(26, 26, 26),
	})

	local main = library:create("Frame", {
		Parent = inline2,
		Name = "",
		Position = UDim2.new(0, 2, 0, 2),
		BorderColor3 = Color3.fromRGB(57, 57, 57),
		Size = UDim2.new(1, -4, 1, -4),
		BackgroundColor3 = Color3.fromRGB(26, 26, 26),
	})

	local tab_buttons = library:create("Frame", {
		Parent = main,
		Name = "",
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 16, 0, 4),
		Size = UDim2.new(1, -32, 0, 0),
		ZIndex = 2,
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
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
		BorderColor3 = Color3.fromRGB(19, 19, 19),
		Size = UDim2.new(1, -30, 1, -48),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(19, 19, 19),
	})

	local tabs = library:create("Frame", {
		Parent = tab_inline,
		Name = "",
		Position = UDim2.new(0, 2, 0, 2),
		BorderColor3 = Color3.fromRGB(56, 56, 56),
		Size = UDim2.new(1, -4, 1, -4),
		BackgroundColor3 = Color3.fromRGB(22, 22, 22),
	})

	cfg["tab_instance_holder"] = tabs

	local accent_line = library:create("Frame", {
		Parent = inline1,
		Name = "",
		BorderColor3 = Color3.fromRGB(34, 34, 34),
		Size = UDim2.new(1, 0, 0, 2),
		BorderSizePixel = 0,
		BackgroundColor3 = themes.preset.accent,
	})
	library:apply_theme(accent_line, "accent", "BackgroundColor3")

	library:create("TextLabel", {
		Parent = inline1,
		Name = "",
		FontFace = library.font,
		TextColor3 = Color3.fromRGB(170, 170, 170),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		Text = cfg.name,
		TextStrokeTransparency = 0.5,
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, -1),
		Size = UDim2.new(1, 0, 0, 1),
		ZIndex = 2,
		TextSize = 12,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	})

	local win_glow = library:create("ImageLabel", {
		Parent = inline1,
		Name = "",
		ImageColor3 = themes.preset.accent,
		ScaleType = Enum.ScaleType.Slice,
		ImageTransparency = 0.9,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
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
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		Size = UDim2.new(1, 0, 0, 1),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
	})

	library:create("Frame", {
		Parent = inline1,
		Name = "",
		BackgroundTransparency = 1,
		Position = UDim2.new(1, 20, 0, 0),
		BorderColor3 = Color3.fromRGB(19, 19, 19),
		ZIndex = 2,
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundColor3 = Color3.fromRGB(40, 40, 40),
	})

	local header_gradient_elapsed = 0
	library:connection(run_service.Heartbeat, function(dt)
		if not __holder.Visible then return end

		local anim_speed = flags["color_picker_anim_speed"]
		if not anim_speed then return end

		header_gradient_elapsed += dt
		if header_gradient_elapsed < (1 / 30) then return end
		header_gradient_elapsed = 0

		local now = clock()
		library.sin = abs(sin_wave(now * anim_speed))

		TEXT_ANIMATION_GRADIENT.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
			ColorSequenceKeypoint.new(abs(sin_wave(now)), themes.preset.accent),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
		})
	end)

	task.wait()

	-- esp preview
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
		BorderColor3 = Color3.fromRGB(8, 8, 8),
		Size = UDim2.new(0, 328, 0, 376),
		BackgroundColor3 = Color3.fromRGB(56, 56, 56),
		ZIndex = 4,
	})
	library:make_draggable(esp_preview)
	library:make_resizable(esp_preview)

	library:create("TextLabel", {
		Parent = esp_preview,
		Name = "",
		FontFace = library.font,
		TextColor3 = Color3.fromRGB(170, 170, 170),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		Text = "esp preview",
		TextStrokeTransparency = 0.5,
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, -1),
		Size = UDim2.new(1, 0, 0, 1),
		ZIndex = 2,
		TextSize = 12,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	})

	local esp_main = library:create("Frame", {
		Parent = esp_preview,
		Name = "",
		Position = UDim2.new(0, 4, 0, 4),
		BorderColor3 = Color3.fromRGB(26, 26, 26),
		Size = UDim2.new(1, -8, 1, -8),
		BorderSizePixel = 2,
		BackgroundColor3 = Color3.fromRGB(26, 26, 26),
	})

	library:create("UIStroke", {
		Parent = esp_main,
		Color = Color3.fromRGB(57, 57, 57),
		LineJoinMode = Enum.LineJoinMode.Miter,
	})

	local esp_tabs = library:create("Frame", {
		Parent = esp_main,
		Name = "",
		Position = UDim2.new(0, 8, 0, 8),
		BorderColor3 = Color3.fromRGB(8, 8, 8),
		Size = UDim2.new(1, -16, 1, -16),
		BorderSizePixel = 2,
		BackgroundColor3 = Color3.fromRGB(22, 22, 22),
	})

	library:create("UIStroke", {
		Parent = esp_tabs,
		Color = Color3.fromRGB(57, 57, 57),
		LineJoinMode = Enum.LineJoinMode.Miter,
	})

	local esp_vpf = library:create("ViewportFrame", {
		Parent = esp_tabs,
		Position = UDim2.new(0, 4, 0, 4),
		Size = UDim2.new(1, -8, 1, -8),
		BackgroundTransparency = 1,
		ZIndex = 5,
		LightColor = Color3.fromRGB(255, 255, 255),
		LightDirection = Vector3.new(-0.3, -1, -0.3),
		Ambient = Color3.fromRGB(255, 255, 255),
	})

	local esp_wm = library:create("WorldModel", { Parent = esp_vpf })
	local esp_cam = library:create("Camera", { Parent = esp_vpf })
	esp_cam.FieldOfView = 60
	esp_vpf.CurrentCamera = esp_cam

	local esp_clone_folder = Instance.new("Folder")
	esp_clone_folder.Name = "CharClone"
	esp_clone_folder.Parent = esp_vpf

	local esp_clone_parts = {}

	local function setup_esp_character()
		esp_wm:ClearAllChildren()
		for _, child in ipairs(esp_clone_folder:GetChildren()) do
			child:Destroy()
		end
		esp_clone_parts = {}
		local char = lp.Character
		if not char then return end
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if not hrp then return end
		local hrpCF = hrp.CFrame
		for _, obj in ipairs(char:GetDescendants()) do
			if obj:IsA("BasePart") and obj.Transparency < 1 then
				local ok, clone = pcall(function() return obj:Clone() end)
				if ok and clone then
					clone.Anchored = true
					clone.CanCollide = false
					clone.CanQuery = false
					clone.CanTouch = false
					clone.CastShadow = false
					clone.LocalTransparencyModifier = 0
					clone.Parent = esp_clone_folder
					local offset = hrpCF:ToObjectSpace(clone.CFrame)
					esp_clone_parts[#esp_clone_parts + 1] = {clone = clone, offset = offset}
				end
			end
		end
		for _, acc in ipairs(char:GetChildren()) do
			if acc:IsA("Accessory") then
				local handle = acc:FindFirstChild("Handle")
				if handle and handle:IsA("BasePart") and handle.Transparency < 1 then
					local ok, clone = pcall(function() return handle:Clone() end)
					if ok and clone then
						clone.Anchored = true
						clone.CanCollide = false
						clone.CanQuery = false
						clone.CanTouch = false
						clone.CastShadow = false
						clone.LocalTransparencyModifier = 0
						clone.Parent = esp_clone_folder
						local offset = hrpCF:ToObjectSpace(clone.CFrame)
						esp_clone_parts[#esp_clone_parts + 1] = {clone = clone, offset = offset}
					end
				end
			end
		end
		esp_cam.CFrame = CFrame.new(
			hrp.Position + (hrp.CFrame.LookVector * 12) + Vector3.new(0, -1, 0),
			hrp.Position + Vector3.new(0, 0, 0)
		)
	end

	local esp_setup_done = false
	library:connection(run_service.Heartbeat, function()
		if esp_preview.Visible then
			if not esp_setup_done then
				esp_setup_done = true
				task.defer(setup_esp_character)
			end
			local char = lp.Character
			if char then
				local hrp = char:FindFirstChild("HumanoidRootPart")
				if hrp then
					local hrpCF = hrp.CFrame
					for _, entry in ipairs(esp_clone_parts) do
						if entry.clone and entry.clone.Parent then
							entry.clone.CFrame = hrpCF * entry.offset
						end
					end
					esp_cam.CFrame = CFrame.new(
						hrp.Position + (hrp.CFrame.LookVector * 12) + Vector3.new(0, -1, 0),
						hrp.Position + Vector3.new(0, 0, 0)
					)
				end
			end
		else
			esp_setup_done = false
		end
	end)
	lp.CharacterAdded:Connect(function()
		task.wait(1)
		if esp_preview.Visible then
			setup_esp_character()
		end
	end)

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
		BackgroundTransparency = 0.7,
		BorderSizePixel = 0,
		ZIndex = 10,
		Visible = false,
	})
	library:create("UICorner", { Parent = esp_chams_frame, CornerRadius = UDim.new(0, 4) })

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
		Color = Color3.fromRGB(0, 0, 0),
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
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		ZIndex = 11,
	})
	local esp_health = library:create("Frame", {
		Parent = esp_health_bg,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, 0),
		Size = UDim2.new(1, 0, 0.75, 0),
		BackgroundColor3 = Color3.fromRGB(0, 200, 80),
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

	local esp_tracer = library:create("Frame", {
		Parent = esp_overlay,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(BOX_CX, 0, 0.82, 0),
		Size = UDim2.new(0, 1, 0, 28),
		BackgroundColor3 = themes.preset.accent,
		BorderSizePixel = 0,
		ZIndex = 11,
	})

	function cfg.update_esp_preview()
		if not esp_preview.Visible then return end
		if not (Config and Config.ESP) then return end
		local esp = Config.ESP
		local cols = esp.Colors or {}
		local accent = themes.preset.accent

		esp_box.Visible = esp.Enabled and esp.BoxESP
		esp_box_outline.Enabled = esp.Enabled and esp.BoxESP and esp.BoxOutline ~= false
		esp_box_fill.Visible = esp.Enabled and esp.BoxESP and esp.BoxFilled
		esp_chams_frame.Visible = esp.Enabled and esp.ChamsEnabled
		esp_name.Visible = esp.Enabled and esp.NameESP
		esp_health_bg.Visible = esp.Enabled and esp.HealthESP
		esp_distance.Visible = esp.Enabled and esp.ShowDistance
		esp_tracer.Visible = esp.Enabled and esp.TracerESP
		for _, b in ipairs(esp_skeleton) do
			b.Visible = esp.Enabled and esp.SkeletonESP
		end

		esp_box_stroke.Color = cols.Box or accent
		esp_box_fill.BackgroundColor3 = cols.BoxFill or Color3.fromRGB(100, 100, 100)
		esp_box_outline.Color = cols.BoxOutline or Color3.fromRGB(0, 0, 0)
		esp_name.TextColor3 = cols.Text or accent
		esp_health.BackgroundColor3 = cols.HealthHigh or Color3.fromRGB(0, 200, 80)
		esp_distance.TextColor3 = cols.Distance or accent
		esp_tracer.BackgroundColor3 = cols.Tracer or accent
		esp_chams_frame.BackgroundColor3 = cols.Chams or accent
		for _, b in ipairs(esp_skeleton) do
			b.BackgroundColor3 = cols.Skeleton or accent
		end

		esp_box_stroke.Thickness = esp.BoxThickness or 1
		esp_box_outline.Thickness = esp.BoxOutlineThickness or 3
	end

	local _esp_update_elapsed = 0
	library:connection(run_service.Heartbeat, function(dt)
		if esp_preview.Visible then
			_esp_update_elapsed = _esp_update_elapsed + dt
			if _esp_update_elapsed >= (1/20) then
				_esp_update_elapsed = 0
				cfg.update_esp_preview()
			end
		end
	end)

	local esp_accent = library:create("Frame", {
		Parent = esp_preview,
		BorderColor3 = Color3.fromRGB(34, 34, 34),
		Size = UDim2.new(1, 0, 0, 2),
		BorderSizePixel = 0,
		BackgroundColor3 = themes.preset.accent,
	})
	library:apply_theme(esp_accent, "accent", "BackgroundColor3")

	library:create("Frame", {
		Parent = esp_preview,
		BackgroundTransparency = 0.5,
		Position = UDim2.new(0, 0, 0, 1),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		Size = UDim2.new(1, 0, 0, 1),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
	})

	local esp_glow = library:create("ImageLabel", {
		Parent = esp_preview,
		ImageColor3 = themes.preset.accent,
		ScaleType = Enum.ScaleType.Slice,
		ImageTransparency = 0.9,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
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

	-- playerlist
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
		BorderColor3 = Color3.fromRGB(8, 8, 8),
		Size = UDim2.new(0, 358, 0, 328),
		BackgroundColor3 = Color3.fromRGB(56, 56, 56),
		ZIndex = 4,
	})
	library:make_draggable(playerlist)
	library:make_resizable(playerlist)
	table.insert(library.main_frame, playerlist)

	library:create("TextLabel", {
		Parent = playerlist,
		FontFace = library.font,
		TextColor3 = Color3.fromRGB(170, 170, 170),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		Text = "playerlist",
		TextStrokeTransparency = 0.5,
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, -1),
		Size = UDim2.new(1, 0, 0, 1),
		ZIndex = 2,
		TextSize = 12,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	})

	local pl_main = library:create("Frame", {
		Parent = playerlist,
		Position = UDim2.new(0, 4, 0, 4),
		BorderColor3 = Color3.fromRGB(26, 26, 26),
		Size = UDim2.new(1, -8, 1, -8),
		BorderSizePixel = 2,
		BackgroundColor3 = Color3.fromRGB(26, 26, 26),
	})

	library:create("UIStroke", { Parent = pl_main, Color = Color3.fromRGB(57, 57, 57), LineJoinMode = Enum.LineJoinMode.Miter })

	local pl_tabs = library:create("Frame", {
		Parent = pl_main,
		Position = UDim2.new(0, 8, 0, 8),
		BorderColor3 = Color3.fromRGB(8, 8, 8),
		Size = UDim2.new(1, -16, 1, -16),
		BorderSizePixel = 2,
		BackgroundColor3 = Color3.fromRGB(22, 22, 22),
	})

	library:create("UIStroke", { Parent = pl_tabs, Color = Color3.fromRGB(57, 57, 57), LineJoinMode = Enum.LineJoinMode.Miter })

	local pl_list = library:create("Frame", {
		Parent = pl_tabs,
		Position = UDim2.new(0, 14, 0, 14),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		Size = UDim2.new(1, -28, 0.75, -28),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(8, 8, 8),
	})

	local pl_inline = library:create("Frame", { Parent = pl_list, Position = UDim2.new(0,1,0,1), BorderSizePixel=0, Size=UDim2.new(1,-2,1,-2), BackgroundColor3=Color3.fromRGB(57,57,57) })
	local pl_bg = library:create("Frame", { Parent = pl_inline, Position = UDim2.new(0,1,0,1), BorderSizePixel=0, Size=UDim2.new(1,-2,1,-2), BackgroundColor3=Color3.fromRGB(22,22,22) })
	library:create("UIGradient", { Parent = pl_bg, Rotation=90, Color=ColorSequence.new({ ColorSequenceKeypoint.new(0,Color3.fromRGB(255,255,255)), ColorSequenceKeypoint.new(1,Color3.fromRGB(167,167,167)) }) })
	local pl_contrast = library:create("Frame", { Parent = pl_bg, BorderSizePixel=0, Size=UDim2.new(1,0,1,0), BackgroundColor3=Color3.fromRGB(22,22,22) })

	local __ScrollingFrame = library:create("ScrollingFrame", {
		Parent = pl_contrast,
		ScrollBarImageColor3 = themes.preset.accent,
		MidImage = "rbxassetid://18406573371",
		Active = true,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 2,
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		TopImage = "rbxassetid://18406573371",
		BorderColor3 = Color3.fromRGB(0, 0, 0),
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
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		Size = UDim2.new(1, -28, 0.3, -23),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(8, 8, 8),
	})

	local info_inline = library:create("Frame", { Parent=info_frame, Position=UDim2.new(0,1,0,1), BorderSizePixel=0, Size=UDim2.new(1,-2,1,-2), BackgroundColor3=Color3.fromRGB(57,57,57) })
	local info_bg = library:create("Frame", { Parent=info_inline, Position=UDim2.new(0,1,0,1), BorderSizePixel=0, Size=UDim2.new(1,-2,1,-2), BackgroundColor3=Color3.fromRGB(22,22,22) })
	library:create("UIGradient", { Parent=info_bg, Rotation=90, Color=ColorSequence.new({ ColorSequenceKeypoint.new(0,Color3.fromRGB(255,255,255)), ColorSequenceKeypoint.new(1,Color3.fromRGB(167,167,167)) }) })
	local info_contrast = library:create("Frame", { Parent=info_bg, BorderSizePixel=0, Size=UDim2.new(1,0,1,0), BackgroundColor3=Color3.fromRGB(22,22,22) })

	local InfoScrollingFrame = library:create("ScrollingFrame", {
		Parent = info_contrast,
		ScrollBarImageColor3 = Color3.fromRGB(155, 125, 175),
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
			TextColor3 = Color3.fromRGB(180, 180, 180),
			Text = text,
			BorderSizePixel = 0,
			BackgroundTransparency = 1,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			AutomaticSize = Enum.AutomaticSize.XY,
			TextSize = 12,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
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
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	})

	library:create("UIListLayout", { Parent=btn_frame, VerticalAlignment=Enum.VerticalAlignment.Center, SortOrder=Enum.SortOrder.LayoutOrder, HorizontalAlignment=Enum.HorizontalAlignment.Center, HorizontalFlex=Enum.UIFlexAlignment.Fill, Padding=UDim.new(0,4) })

	local function make_priority_btn(label, on_click)
		local bi = library:create("Frame", { Parent=btn_frame, Position=UDim2.new(0,-15,0,2), BorderColor3=Color3.fromRGB(19,19,19), Size=UDim2.new(1,-26,0,16), BorderSizePixel=0, BackgroundColor3=Color3.fromRGB(8,8,8) })
		local b  = library:create("TextButton", { Parent=bi, FontFace=library.font, TextColor3=Color3.fromRGB(170,170,170), BorderColor3=Color3.fromRGB(56,56,56), Text=label, TextStrokeTransparency=0.5, Position=UDim2.new(0,2,0,2), Size=UDim2.new(1,-4,1,-4), TextSize=12, BackgroundColor3=Color3.fromRGB(38,38,38) })
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

	local pl_accent = library:create("Frame", { Parent=playerlist, BorderColor3=Color3.fromRGB(34,34,34), Size=UDim2.new(1,0,0,2), BorderSizePixel=0, BackgroundColor3=themes.preset.accent })
	library:apply_theme(pl_accent, "accent", "BackgroundColor3")

	library:create("Frame", { Parent=playerlist, BackgroundTransparency=0.5, Position=UDim2.new(0,0,0,1), BorderColor3=Color3.fromRGB(0,0,0), Size=UDim2.new(1,0,0,1), BorderSizePixel=0, BackgroundColor3=Color3.fromRGB(0,0,0) })

	local pl_glow = library:create("ImageLabel", { Parent=playerlist, ImageColor3=themes.preset.accent, ScaleType=Enum.ScaleType.Slice, ImageTransparency=0.9, BorderSizePixel=0, BackgroundColor3=Color3.fromRGB(255,255,255), Image="http://www.roblox.com/asset/?id=18245826428", BackgroundTransparency=1, Position=UDim2.new(0,-20,0,-20), Size=UDim2.new(1,40,0,42), ZIndex=2, SliceCenter=Rect.new(Vector2.new(21,21),Vector2.new(79,79)) })
	library:apply_theme(pl_glow, "accent", "ImageColor3")

	local function create_player(player)
		local TextButton = library:create("TextButton", {
			Parent = __ScrollingFrame,
			FontFace = library.font,
			TextColor3 = Color3.fromRGB(180, 180, 180),
			Text = "",
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 0),
			BorderSizePixel = 0,
			AutomaticSize = Enum.AutomaticSize.Y,
			TextSize = 12,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		})

		player_buttons[player.Name] = { instance = TextButton }

		local function make_col_label(text, align)
			local lbl = library:create("TextLabel", {
				Parent = TextButton,
				FontFace = library.font,
				TextColor3 = Color3.fromRGB(180, 180, 180),
				Text = text,
				BorderSizePixel = 0,
				BackgroundTransparency = 1,
				TextXAlignment = align or Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				AutomaticSize = Enum.AutomaticSize.Y,
				TextSize = 12,
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			})
			library:create("UIStroke", { Parent = lbl })
			return lbl
		end

		make_col_label(player.Name)

		local team_lbl = make_col_label(player.Team and tostring(player.Team) or "None")
		library:create("Frame", { Parent=team_lbl, Position=UDim2.new(0,-10,0,0), BorderSizePixel=0, Size=UDim2.new(0,1,0,12), BackgroundColor3=Color3.fromRGB(32,32,38) })

		local prio_lbl = make_col_label("Neutral")
		player_buttons[player.Name].priority = prio_lbl
		library:create("Frame", { Parent=prio_lbl, Position=UDim2.new(0,-10,0,0), BorderSizePixel=0, Size=UDim2.new(0,1,0,12), BackgroundColor3=Color3.fromRGB(32,32,38) })

		library:create("UIListLayout", { Parent=TextButton, FillDirection=Enum.FillDirection.Horizontal, HorizontalFlex=Enum.UIFlexAlignment.Fill, SortOrder=Enum.SortOrder.LayoutOrder, VerticalFlex=Enum.UIFlexAlignment.Fill })
		library:create("UIPadding", { Parent=TextButton, PaddingRight=UDim.new(0,2), PaddingLeft=UDim.new(0,2) })

		TextButton.MouseButton1Click:Connect(function()
			if selected_button then
				selected_button.BackgroundTransparency = 1
			end

			selected_button = TextButton
			selected_player = player
			TextButton.BackgroundTransparency = 0.85

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

	-- keybind list
	local old_kblist = library:create("Frame", {
		Parent = library.gui,
		BorderColor3 = Color3.fromRGB(19, 19, 19),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 20, 0.5, 0),
		ZIndex = 4,
		Active = true,
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundColor3 = Color3.fromRGB(40, 40, 40),
	})
	library:make_draggable(old_kblist)

	local kb_glow = library:create("ImageLabel", { Parent=old_kblist, ImageColor3=themes.preset.accent, ScaleType=Enum.ScaleType.Slice, ImageTransparency=0.9, BorderSizePixel=0, BackgroundColor3=Color3.fromRGB(255,255,255), Image="http://www.roblox.com/asset/?id=18245826428", BackgroundTransparency=1, Position=UDim2.new(0,-20,0,-20), Size=UDim2.new(1,40,0,42), ZIndex=2, SliceCenter=Rect.new(Vector2.new(21,21),Vector2.new(79,79)) })
	library:apply_theme(kb_glow, "accent", "ImageColor3")

	local kb_inline1 = library:create("Frame", { Parent=old_kblist, BorderColor3=Color3.fromRGB(0,0,0), AutomaticSize=Enum.AutomaticSize.XY, BackgroundColor3=Color3.fromRGB(40,40,40) })
	local kb_accent  = library:create("Frame", { Parent=kb_inline1, BorderColor3=Color3.fromRGB(34,34,34), Size=UDim2.new(1,0,0,2), BorderSizePixel=0, BackgroundColor3=themes.preset.accent })
	library:apply_theme(kb_accent, "accent", "BackgroundColor3")

	library:create("TextLabel", { Parent=kb_inline1, FontFace=library.font, TextColor3=Color3.fromRGB(170,170,170), Text="keybinds", TextStrokeTransparency=0.5, BorderSizePixel=0, BackgroundTransparency=1, Position=UDim2.new(0,0,0,-1), Size=UDim2.new(1,0,0,1), ZIndex=2, TextSize=12, BackgroundColor3=Color3.fromRGB(255,255,255) })

	local kb_inline2 = library:create("Frame", { Parent=kb_inline1, Position=UDim2.new(0,2,0,2), BorderSizePixel=0, Size=UDim2.new(1,-4,1,-4), BackgroundColor3=Color3.fromRGB(26,26,26) })
	local kb_main    = library:create("Frame", { Parent=kb_inline2, Position=UDim2.new(0,2,0,2), BorderColor3=Color3.fromRGB(57,57,57), Size=UDim2.new(1,-4,1,-4), BackgroundColor3=Color3.fromRGB(26,26,26) })
	local kb_ti      = library:create("Frame", { Parent=kb_main, Position=UDim2.new(0,6,0,6), BorderColor3=Color3.fromRGB(19,19,19), Size=UDim2.new(1,-12,1,-12), BorderSizePixel=0, BackgroundColor3=Color3.fromRGB(19,19,19) })
	local kb_tabs    = library:create("Frame", { Parent=kb_ti, Position=UDim2.new(0,2,0,2), BorderColor3=Color3.fromRGB(56,56,56), Size=UDim2.new(1,-4,1,-4), BackgroundColor3=Color3.fromRGB(22,22,22) })

	library:create("UIPadding", { Parent=kb_tabs, PaddingBottom=UDim.new(0,22), PaddingRight=UDim.new(0,20), PaddingLeft=UDim.new(0,20) })
	library:create("UIListLayout", { Parent=kb_tabs, SortOrder=Enum.SortOrder.LayoutOrder, HorizontalAlignment=Enum.HorizontalAlignment.Center, Padding=UDim.new(0,3) })
	library:create("UIStroke", { Parent=kb_tabs, Color=Color3.fromRGB(57,57,57), LineJoinMode=Enum.LineJoinMode.Miter })
	library:create("Frame", { Parent=kb_inline1, BorderColor3=Color3.fromRGB(0,0,0), BackgroundTransparency=0.5, Position=UDim2.new(0,0,0,1), Size=UDim2.new(1,0,0,1), ZIndex=2, BorderSizePixel=0, BackgroundColor3=Color3.fromRGB(0,0,0) })

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
	end

	function cfg.get_esp_preview_frame()
		return esp_preview
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
		wm_name.TextStrokeTransparency = 0.5
	end

	function cfg.set_menu_visibility(bool)
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
		-- hide/show all floating curve editor windows alongside the main menu
		for _, entry in ipairs(library.curve_boxes) do
			local outer = entry.outer
			local enabled = entry.enabled_flag
			if outer then
				-- only show if the menu is open AND the "use custom curve" toggle is on
				outer.Visible = bool and (enabled == nil or flags[enabled] == true)
			end
		end
	end

	-- ══════════════════════════════════════════════════════════════
	-- KEYSTROKE OVERLAY
	-- Matches the watermark layered-frame design exactly.
	-- Draggable via library:make_draggable() — no manual hit-testing.
	-- ══════════════════════════════════════════════════════════════
	local KEY_SIZE = 30
	local KEY_SPACING = 6
	local C_KEY_OFF   = Color3.fromRGB(28, 28, 28)
	local C_KEY_OFF_B = Color3.fromRGB(38, 38, 38)
	local OV_BG_OUTER  = Color3.fromRGB(40, 40, 40)
	local OV_BG_INNER1 = Color3.fromRGB(26, 26, 26)
	local OV_BG_INNER2 = Color3.fromRGB(22, 22, 22)

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
		})
		local cell_inner = library:create("Frame", {
			Parent = cell_outer, Name = label .. "_inner",
			Position = UDim2.new(0, 2, 0, 2),
			Size     = UDim2.new(1, -4, 1, -4),
			BackgroundColor3 = C_KEY_OFF_B, BorderSizePixel = 0,
		})
		-- thin accent bar at top of each key cell
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
			TextColor3 = Color3.fromRGB(170, 170, 170),
			TextStrokeTransparency = 0.5,
			BorderSizePixel = 0,
		})
		return { outer = cell_outer, inner = cell_inner, bar = cell_bar, lbl = cell_lbl }
	end

	-- Build the keystroke holder (called once, lazily on first show)
	local _kl_built = false
	local function build_keystroke_ui()
		if _kl_built then return end
		_kl_built = true

		-- Restore saved position from Config if available
		local cfg_g = getgenv().Config
		if cfg_g and cfg_g.Overlays then
			local sx = tonumber(cfg_g.Overlays.KeyloggerX)
			local sy = tonumber(cfg_g.Overlays.KeyloggerY)
			if sx and sy then KL.position = Vector2.new(sx, sy) end
		end

		-- Layout constants
		-- Row 0: W (centre col)
		-- Row 1: A S D
		-- Row 2: SPC (double-width, spans cols 0-2 centred)
		-- Row 3: M1 (left)  M2 (right)  + CPS labels below each
		local SPC_W = KEY_SIZE * 3.25 + KEY_SPACING   -- double x-width, same height
		local CPS_H = 10                            -- height of CPS text row
		local ROWS  = 4                             -- W/ASD/SPC/M1+M2
		local GRID_W = KEY_SIZE * 3 + KEY_SPACING * 2
		local GRID_H = KEY_SIZE * ROWS + KEY_SPACING * (ROWS - 1) + CPS_H + KEY_SPACING
		local PANEL_W = GRID_W + 16 + 8
		local PANEL_H = GRID_H + 16 + 10

		-- Outer frame — fully transparent (no background)
		local kl_outer = library:create("Frame", {
			Parent   = library.gui,
			Position = UDim2.fromOffset(KL.position.X, KL.position.Y),
			Size     = UDim2.fromOffset(PANEL_W, PANEL_H),
			BackgroundTransparency = 1,
			BorderSizePixel  = 0, ZIndex = 4,
		})
		library:make_draggable(kl_outer)

		-- Inner frame layers — also transparent so no box background is visible
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
		BorderColor3 = Color3.fromRGB(57, 57, 57), ZIndex = 6,
	})
		-- Canvas for key cells
		local kl_canvas = library:create("Frame", {
			Parent = kl_inline2, Position = UDim2.new(0, 8, 0, 8),
			Size = UDim2.new(1, -16, 1, -16),
			BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 7,
		})

		KL.frames = {}

		-- Row 0: W
		KL.frames["W"]   = make_key_cell(kl_canvas, "W",   1, 0)
		-- Row 1: A S D
		KL.frames["A"]   = make_key_cell(kl_canvas, "A",   0, 1)
		KL.frames["S"]   = make_key_cell(kl_canvas, "S",   1, 1)
		KL.frames["D"]   = make_key_cell(kl_canvas, "D",   2, 1)

		-- Row 2: SPC — centred, double X width, normal Y height
		local spc_x = math.floor((GRID_W - SPC_W) / 2)
		local spc_y = 2 * (KEY_SIZE + KEY_SPACING)
		local spc_outer = library:create("Frame", {
			Parent = kl_canvas, Name = "SPC_outer",
			Position = UDim2.fromOffset(spc_x, spc_y),
			Size     = UDim2.fromOffset(SPC_W, KEY_SIZE),
			BackgroundColor3 = C_KEY_OFF, BorderSizePixel = 0,
		})
		local spc_inner = library:create("Frame", {
			Parent = spc_outer, Name = "SPC_inner",
			Position = UDim2.new(0, 2, 0, 2),
			Size     = UDim2.new(1, -4, 1, -4),
			BackgroundColor3 = C_KEY_OFF_B, BorderSizePixel = 0,
		})
		local spc_bar = library:create("Frame", {
			Parent = spc_inner, Name = "SPC_bar",
			Size = UDim2.new(1, 0, 0, 1),
			BackgroundColor3 = themes.preset.accent, BorderSizePixel = 0,
		})
		library:apply_theme(spc_bar, "accent", "BackgroundColor3")
		-- Realistic spacebar: horizontal line across the middle
		library:create("Frame", {
			Parent = spc_inner, Name = "SPC_midline",
			Position = UDim2.new(0.1, 0, 0.5, -1),
			Size = UDim2.new(0.8, 0, 0, 1),
			BackgroundColor3 = Color3.fromRGB(60, 60, 60), BorderSizePixel = 0,
		})
		local spc_lbl = library:create("TextLabel", {
			Parent = spc_inner, Name = "SPC_lbl",
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			FontFace = library.font,
			Text = "", TextSize = 12,
			TextColor3 = Color3.fromRGB(170, 170, 170),
			TextStrokeTransparency = 0.5,
			BorderSizePixel = 0,
		})
		KL.frames["SPC"] = { outer = spc_outer, inner = spc_inner, bar = spc_bar, lbl = spc_lbl }

		-- Row 3: M1 (left) and M2 (right), below spacebar
		local m_row_y = 3 * (KEY_SIZE + KEY_SPACING)
		-- M1 — left side
		local m1_x = 0
		local m1_outer = library:create("Frame", {
			Parent = kl_canvas, Name = "M1_outer",
			Position = UDim2.fromOffset(m1_x, m_row_y),
			Size     = UDim2.fromOffset(KEY_SIZE, KEY_SIZE),
			BackgroundColor3 = C_KEY_OFF, BorderSizePixel = 0,
		})
		local m1_inner = library:create("Frame", {
			Parent = m1_outer, Name = "M1_inner",
			Position = UDim2.new(0, 2, 0, 2),
			Size     = UDim2.new(1, -4, 1, -4),
			BackgroundColor3 = C_KEY_OFF_B, BorderSizePixel = 0,
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
			TextColor3 = Color3.fromRGB(170, 170, 170),
			TextStrokeTransparency = 0.5,
			BorderSizePixel = 0,
		})
		KL.frames["M1"] = { outer = m1_outer, inner = m1_inner, bar = m1_bar, lbl = m1_lbl }

		-- M1 CPS label directly below M1
		local m1_cps_lbl = library:create("TextLabel", {
			Parent = kl_canvas, Name = "M1_cps",
			Position = UDim2.fromOffset(m1_x, m_row_y + KEY_SIZE + 2),
			Size     = UDim2.fromOffset(KEY_SIZE, CPS_H),
			BackgroundTransparency = 1,
			FontFace = library.font,
			Text = "0 cps", TextSize = 10,
			TextColor3 = Color3.fromRGB(120, 120, 120),
			TextStrokeTransparency = 0.5,
			BorderSizePixel = 0,
		})
		KL.frames["M1_cps"] = m1_cps_lbl

		-- M2 — right side
		local m2_x = GRID_W - KEY_SIZE
		local m2_outer = library:create("Frame", {
			Parent = kl_canvas, Name = "M2_outer",
			Position = UDim2.fromOffset(m2_x, m_row_y),
			Size     = UDim2.fromOffset(KEY_SIZE, KEY_SIZE),
			BackgroundColor3 = C_KEY_OFF, BorderSizePixel = 0,
		})
		local m2_inner = library:create("Frame", {
			Parent = m2_outer, Name = "M2_inner",
			Position = UDim2.new(0, 2, 0, 2),
			Size     = UDim2.new(1, -4, 1, -4),
			BackgroundColor3 = C_KEY_OFF_B, BorderSizePixel = 0,
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
			TextColor3 = Color3.fromRGB(170, 170, 170),
			TextStrokeTransparency = 0.5,
			BorderSizePixel = 0,
		})
		KL.frames["M2"] = { outer = m2_outer, inner = m2_inner, bar = m2_bar, lbl = m2_lbl }

		-- M2 CPS label directly below M2
		local m2_cps_lbl = library:create("TextLabel", {
			Parent = kl_canvas, Name = "M2_cps",
			Position = UDim2.fromOffset(m2_x, m_row_y + KEY_SIZE + 2),
			Size     = UDim2.fromOffset(KEY_SIZE, CPS_H),
			BackgroundTransparency = 1,
			FontFace = library.font,
			Text = "0 cps", TextSize = 10,
			TextColor3 = Color3.fromRGB(120, 120, 120),
			TextStrokeTransparency = 0.5,
			BorderSizePixel = 0,
		})
		KL.frames["M2_cps"] = m2_cps_lbl

		-- CPS update heartbeat
		local _cps_elapsed = 0
		run_service.Heartbeat:Connect(function(dt)
			if not KL.visible then return end
			_cps_elapsed = _cps_elapsed + dt
			if _cps_elapsed < 0.25 then return end
			_cps_elapsed = 0
			local now = tick()
			local window = 1  -- count clicks in the last 1 second
			-- prune old timestamps
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

	function cfg.toggle_keystroke(bool)
		if bool then
			build_keystroke_ui()
		end
		KL.visible = bool
		if KL.holder then KL.holder.Visible = bool end
	end

	-- ══════════════════════════════════════════════════════════════
	-- FPS / PING OVERLAY
	-- Same layered-frame design as the watermark.
	-- Draggable via library:make_draggable().
	-- ══════════════════════════════════════════════════════════════
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

		-- Restore saved position from Config if available
		local cfg_g = getgenv().Config
		if cfg_g and cfg_g.Overlays then
			local sx = tonumber(cfg_g.Overlays.FPSPingX)
			local sy = tonumber(cfg_g.Overlays.FPSPingY)
			if sx and sy then FP.position = Vector2.new(sx, sy) end
		end

		local FP_W, FP_H = 130, 40

		-- Outer border frame
		local fp_outer = library:create("Frame", {
			Parent   = library.gui,
			Position = UDim2.fromOffset(FP.position.X, FP.position.Y),
			Size     = UDim2.fromOffset(FP_W, FP_H),
			BackgroundColor3 = OV_BG_OUTER,
			BorderSizePixel  = 0, ZIndex = 4,
		})
		library:make_draggable(fp_outer)

		-- Accent line at top
		local fp_accent = library:create("Frame", {
			Parent = fp_outer, BackgroundColor3 = themes.preset.accent,
			Size = UDim2.new(1, 0, 0, 2), BorderSizePixel = 0, ZIndex = 5,
		})
		library:apply_theme(fp_accent, "accent", "BackgroundColor3")

		-- Subtle dark underline below accent
		library:create("Frame", {
			Parent = fp_outer, BackgroundTransparency = 0.5,
			Position = UDim2.new(0, 0, 0, 1), Size = UDim2.new(1, 0, 0, 1),
			BorderSizePixel = 0, BackgroundColor3 = Color3.fromRGB(0, 0, 0), ZIndex = 5,
		})

		-- Accent glow
		local fp_glow = library:create("ImageLabel", {
			Parent = fp_accent, ImageColor3 = themes.preset.accent,
			ScaleType = Enum.ScaleType.Slice, ImageTransparency = 0.9,
			BorderSizePixel = 0, BackgroundTransparency = 1,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			Image = "http://www.roblox.com/asset/?id=18245826428",
			Position = UDim2.new(0, -20, 0, -20), Size = UDim2.new(1, 40, 0, 42),
			ZIndex = 6, SliceCenter = Rect.new(Vector2.new(21, 21), Vector2.new(79, 79)),
		})
		library:apply_theme(fp_glow, "accent", "ImageColor3")

		-- Inner dark frame layer 1
		local fp_inline1 = library:create("Frame", {
			Parent = fp_outer, Position = UDim2.new(0, 2, 0, 2),
			Size = UDim2.new(1, -4, 1, -4),
			BackgroundColor3 = OV_BG_INNER1, BorderSizePixel = 0, ZIndex = 5,
		})
		-- Inner dark frame layer 2
		local fp_inline2 = library:create("Frame", {
			Parent = fp_inline1, Position = UDim2.new(0, 2, 0, 2),
			Size = UDim2.new(1, -4, 1, -4),
			BackgroundColor3 = OV_BG_INNER2,
			BorderColor3 = Color3.fromRGB(57, 57, 57), ZIndex = 6,
		})
		-- Content area
		local fp_content = library:create("Frame", {
			Parent = fp_inline2, Position = UDim2.new(0, 6, 0, 6),
			Size = UDim2.new(1, -12, 1, -12),
			BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 7,
		})

		-- FPS label (left half)
		local fps_lbl = library:create("TextLabel", {
			Parent = fp_content,
			Size = UDim2.new(0.5, -2, 1, 0), Position = UDim2.new(0, 0, 0, 0),
			BackgroundTransparency = 1, FontFace = library.font,
			Text = "fps: --", TextSize = 12,
			TextColor3 = Color3.fromRGB(170, 170, 170),
			TextStrokeTransparency = 0.5,
			TextXAlignment = Enum.TextXAlignment.Left,
			BorderSizePixel = 0, ZIndex = 8,
		})
		-- Divider
		library:create("Frame", {
			Parent = fp_content, Position = UDim2.new(0.5, -1, 0, 2),
			Size = UDim2.new(0, 1, 1, -4),
			BackgroundColor3 = Color3.fromRGB(50, 50, 50),
			BorderSizePixel = 0, ZIndex = 8,
		})
		-- Ping label (right half)
		local ping_lbl = library:create("TextLabel", {
			Parent = fp_content,
			Size = UDim2.new(0.5, -2, 1, 0), Position = UDim2.new(0.5, 2, 0, 0),
			BackgroundTransparency = 1, FontFace = library.font,
			Text = "ping: --", TextSize = 12,
			TextColor3 = Color3.fromRGB(170, 170, 170),
			TextStrokeTransparency = 0.5,
			TextXAlignment = Enum.TextXAlignment.Left,
			BorderSizePixel = 0, ZIndex = 8,
		})

		FP.holder      = fp_outer
		FP.fps_lbl     = fps_lbl
		FP.ping_lbl    = ping_lbl
		FP.accent_bar  = fp_accent
		FP.initialized = true
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
		TextColor3 = Color3.fromRGB(170, 170, 170),
		Text = "",
		BackgroundTransparency = 1,
		Position = UDim2.new(0.5, 0, 0, 8),
		BorderSizePixel = 0,
		Visible = true,
		TextYAlignment = Enum.TextYAlignment.Top,
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
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
		BackgroundColor3 = Color3.fromRGB(40, 40, 40),
		AnchorPoint = Vector2.new(1, 0),
	})

	local nt_inline1 = library:create("Frame", { Parent=holder, BorderColor3=Color3.fromRGB(0,0,0), Size=UDim2.new(0,0,0,24), AutomaticSize=Enum.AutomaticSize.X, BackgroundColor3=Color3.fromRGB(40,40,40) })
	local nt_inline2 = library:create("Frame", { Parent=nt_inline1, Position=UDim2.new(0,0,0,2), BorderSizePixel=0, Size=UDim2.new(1,-4,1,-4), BackgroundColor3=Color3.fromRGB(26,26,26) })
	local nt_main    = library:create("Frame", { Parent=nt_inline2, Position=UDim2.new(0,2,0,2), BorderColor3=Color3.fromRGB(57,57,57), Size=UDim2.new(1,-4,1,-4), BackgroundColor3=Color3.fromRGB(26,26,26) })
	local nt_ti      = library:create("Frame", { Parent=nt_main, Position=UDim2.new(0,2,0,2), BorderColor3=Color3.fromRGB(19,19,19), Size=UDim2.new(1,-4,1,-4), BorderSizePixel=0, BackgroundColor3=Color3.fromRGB(19,19,19) })

	local nt_name = library:create("TextLabel", {
		Parent = nt_ti,
		FontFace = library.font,
		TextColor3 = Color3.fromRGB(170, 170, 170),
		Text = cfg.text,
		TextStrokeTransparency = 0.5,
		Size = UDim2.new(0, 0, 1, 0),
		Position = UDim2.new(0, 8, 0, 0),
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left,
		BorderSizePixel = 0,
		AutomaticSize = Enum.AutomaticSize.X,
		TextSize = 12,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	})
	library:create("UIPadding", { Parent=nt_ti, PaddingRight=UDim.new(0,14) })

	local nt_depth  = library:create("Frame", { Parent=nt_inline1, BorderSizePixel=0, BackgroundTransparency=0.5, Position=UDim2.new(0,1,0,0), Size=UDim2.new(0,1,1,0), ZIndex=2, BackgroundColor3=Color3.fromRGB(0,0,0) })
	local nt_accent = library:create("Frame", { Parent=nt_inline1, BorderColor3=Color3.fromRGB(34,34,34), Size=UDim2.new(0,2,1,0), BorderSizePixel=0, BackgroundColor3=themes.preset.accent })
	library:apply_theme(nt_accent, "accent", "BackgroundColor3")

	local nt_glow = library:create("ImageLabel", { Parent=holder, ImageColor3=themes.preset.accent, ScaleType=Enum.ScaleType.Slice, ImageTransparency=0.9, BorderSizePixel=0, BackgroundColor3=Color3.fromRGB(255,255,255), Image="http://www.roblox.com/asset/?id=18245826428", BackgroundTransparency=1, Position=UDim2.new(0,-20,0,0), Size=UDim2.new(0,42,1,40), ZIndex=2, SliceCenter=Rect.new(Vector2.new(21,21),Vector2.new(79,79)) })
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
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	})

	local line = library:create("Frame", {
		Parent = TAB_BUTTON,
		Position = UDim2.new(0, 0, 1, 0),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		Size = UDim2.new(1, 0, 0, 2),
		BorderSizePixel = 0,
		BackgroundColor3 = rgb(57, 57, 57),
	})
	library:apply_theme(line, "accent", "BackgroundColor3")

	local tab_glow = library:create("ImageLabel", {
		Parent = line,
		ImageColor3 = themes.preset.accent,
		ScaleType = Enum.ScaleType.Slice,
		ImageTransparency = 0.9,
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
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
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		Size = UDim2.new(1, 0, 0, 1),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
	})

	local TAB = library:create("Frame", {
		Parent = self.tab_instance_holder,
		Visible = false,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	})

	local scrolling_columns = library:create("Frame", {
		Parent = TAB,
		ClipsDescendants = true,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 6, 0, 6),
		Size = UDim2.new(1, -12, 1, -12),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
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
			ScrollBarImageColor3 = Color3.fromRGB(0, 0, 0),
			Active = true,
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollBarThickness = 0,
			Size = UDim2.new(0.5, 0, 1, 0),
			ClipsDescendants = false,
			BackgroundTransparency = 1,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
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

	function cfg.open_tab()
		if library.current_tab and library.current_tab[1] ~= TAB_BUTTON then
			local btn = library.current_tab[1]
			btn.TextColor3 = themes.preset.unselected_text
			local parent_line = btn:FindFirstChildOfClass("Frame")
			if parent_line then
				parent_line.BackgroundColor3 = rgb(57, 57, 57)
				local prev_glow = parent_line:FindFirstChildOfClass("ImageLabel")
				if prev_glow then prev_glow.Visible = false end
			end
			library.current_tab[2].Visible = false
		end

		library.current_tab = { TAB_BUTTON, TAB }

		line.BackgroundColor3 = themes.preset.accent
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

	-- controller nav: register this tab
	cfg._nav_btn = TAB_BUTTON
	table.insert(library.nav_tabs, { cfg = cfg, btn = TAB_BUTTON })

	return setmetatable(cfg, library)
end

function library:section(properties)
	local cfg = {
		name = properties.name or properties.Name or "Section",
		side = properties.side or properties.Side or "left",
	}

	-- Support both sections (have left/right) and tabbox tabs (have holder)
	local parent = self[cfg.side] or self.holder

	local section_outer = library:create("Frame", {
		Parent = parent,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 0),
		ZIndex = 2,
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	})

	local section_inline = library:create("Frame", {
		Parent = section_outer,
		Position = UDim2.new(0, 0, 0, 4),
		BorderColor3 = Color3.fromRGB(19, 19, 19),
		Size = UDim2.new(1, 0, 1, -4),
		BorderSizePixel = 0,
		BackgroundColor3 = themes.preset.inline,
	})
	library:apply_theme(section_inline, "inline", "BackgroundColor3")

	library:create("TextLabel", {
		Parent = section_inline,
		FontFace = library.font,
		TextColor3 = Color3.fromRGB(170, 170, 170),
		Text = cfg.name,
		TextStrokeTransparency = 0.5,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 8, 0, 0),
		ZIndex = 2,
		TextSize = 12,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	})

	local sec_inner = library:create("Frame", {
		Parent = section_inline,
		Position = UDim2.new(0, 2, 0, 2),
		BorderColor3 = Color3.fromRGB(56, 56, 56),
		Size = UDim2.new(1, -4, 1, -4),
		BackgroundColor3 = themes.preset.contrast,
	})
	library:apply_theme(sec_inner, "contrast", "BackgroundColor3")

	local elements = library:create("Frame", {
		Parent = sec_inner,
		Position = UDim2.new(0, 12, 0, 12),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		Size = UDim2.new(1, -24, 0, 0),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
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

	-- ============================================================
	-- AddGroupbox: creates a floating draggable curve editor window
	-- parented to library.gui (not inline), matching the lib window style.
	-- Usage: local grp = mySection:AddGroupbox({ Name = "aimbot curve", CurveBox = true })
	-- ============================================================
	function cfg:AddGroupbox(Info)
		Info = Info or {}
		local Groupbox = {
			Name = Info.Name or "Groupbox",
			IsCurveBox = Info.CurveBox or false,
			Flag = Info.flag or Info.Flag or nil,  -- flag name to write points into
		}

		-- ── floating outer shell (same layered style as watermark/window) ─────
		local grp_outer = library:create("Frame", {
			Parent = library.gui,
			Name = Info.Name or "CurveGroupbox",
			Active = true,
			Draggable = false,
			AnchorPoint = Vector2.new(0, 0),
			Position = Info.Position or UDim2.fromOffset(600, 120),
			Size = UDim2.fromOffset(280, 230),
			BackgroundColor3 = Color3.fromRGB(40, 40, 40),
			BorderColor3 = Color3.fromRGB(8, 8, 8),
			ZIndex = 10,
		})
		library:make_draggable(grp_outer)

		-- accent line
		local grp_accent = library:create("Frame", {
			Parent = grp_outer,
			BorderColor3 = Color3.fromRGB(34, 34, 34),
			Size = UDim2.new(1, 0, 0, 2),
			BorderSizePixel = 0,
			BackgroundColor3 = themes.preset.accent,
			ZIndex = 11,
		})
		library:apply_theme(grp_accent, "accent", "BackgroundColor3")

		-- subtle shadow line
		library:create("Frame", {
			Parent = grp_outer,
			BackgroundTransparency = 0.5,
			Position = UDim2.new(0, 0, 0, 1),
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			Size = UDim2.new(1, 0, 0, 1),
			BorderSizePixel = 0,
			BackgroundColor3 = Color3.fromRGB(0, 0, 0),
			ZIndex = 11,
		})

		-- accent glow (same asset as watermark)
		local grp_glow = library:create("ImageLabel", {
			Parent = grp_outer,
			ImageColor3 = themes.preset.accent,
			ScaleType = Enum.ScaleType.Slice,
			ImageTransparency = 0.9,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			Image = "http://www.roblox.com/asset/?id=18245826428",
			BackgroundTransparency = 1,
			Position = UDim2.new(0, -20, 0, -20),
			Size = UDim2.new(1, 40, 0, 42),
			ZIndex = 11,
			BorderSizePixel = 0,
			SliceCenter = Rect.new(Vector2.new(21, 21), Vector2.new(79, 79)),
		})
		library:apply_theme(grp_glow, "accent", "ImageColor3")

		-- inline 1
		local grp_inline1 = library:create("Frame", {
			Parent = grp_outer,
			Position = UDim2.new(0, 2, 0, 2),
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			Size = UDim2.new(1, -4, 1, -4),
			BorderSizePixel = 0,
			BackgroundColor3 = Color3.fromRGB(26, 26, 26),
			ZIndex = 11,
		})

		-- main content frame
		local grp_frame = library:create("Frame", {
			Parent = grp_inline1,
			Position = UDim2.new(0, 2, 0, 2),
			BorderColor3 = Color3.fromRGB(57, 57, 57),
			Size = UDim2.new(1, -4, 1, -4),
			BackgroundColor3 = Color3.fromRGB(26, 26, 26),
			ZIndex = 12,
		})

		-- tab/inner content area
		local grp_tab = library:create("Frame", {
			Parent = grp_frame,
			Position = UDim2.new(0, 6, 0, 6),
			BorderColor3 = Color3.fromRGB(19, 19, 19),
			Size = UDim2.new(1, -12, 1, -12),
			BorderSizePixel = 0,
			BackgroundColor3 = Color3.fromRGB(19, 19, 19),
			ZIndex = 12,
		})

		local grp_inner = library:create("Frame", {
			Parent = grp_tab,
			Position = UDim2.new(0, 2, 0, 2),
			BorderColor3 = Color3.fromRGB(56, 56, 56),
			Size = UDim2.new(1, -4, 1, -4),
			BackgroundColor3 = Color3.fromRGB(22, 22, 22),
			ZIndex = 13,
		})

		-- title label
		library:create("TextLabel", {
			Parent = grp_inner,
			FontFace = library.font,
			TextColor3 = Color3.fromRGB(170, 170, 170),
			Text = Info.Name or "",
			TextStrokeTransparency = 0.5,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 12),
			BackgroundTransparency = 1,
			TextXAlignment = Enum.TextXAlignment.Left,
			Position = UDim2.new(0, 8, 0, 2),
			ZIndex = 14,
			TextSize = 12,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		})

		Groupbox.BoxOuter = grp_outer
		Groupbox.BoxInner = grp_inner

		-- Register this curve window so set_menu_visibility can show/hide it
		if Info.CurveBox then
			table.insert(library.curve_boxes, {
				outer        = grp_outer,
				enabled_flag = Info.enabled_flag or nil,
			})
		end

		if Info.CurveBox then
			-- ── curve canvas shell ───────────────────────────────────
			local canvas_outer = library:create("Frame", {
				Parent = grp_inner,
				Position = UDim2.new(0, 6, 0, 16),
				BorderColor3 = Color3.fromRGB(56, 56, 56),
				Size = UDim2.new(1, -12, 0, 160),
				BackgroundColor3 = Color3.fromRGB(19, 19, 19),
				ZIndex = 14,
			})

			local canvas_inner = library:create("Frame", {
				Parent = canvas_outer,
				Position = UDim2.new(0, 1, 0, 1),
				Size = UDim2.new(1, -2, 1, -2),
				BackgroundColor3 = Color3.fromRGB(15, 15, 15),
				BorderSizePixel = 0,
			})

			local CurveCanvas = library:create("Frame", {
				Parent = canvas_inner,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 1, 0),
				ZIndex = 104,
				BorderSizePixel = 0,
			})

			-- ── grid lines ───────────────────────────────────────────
			local GridSize = 8
			for i = 1, GridSize - 1 do
				library:create("Frame", {
					Parent = CurveCanvas,
					BackgroundColor3 = Color3.fromRGB(38, 38, 38),
					BorderSizePixel = 0,
					Position = UDim2.new(i / GridSize, 0, 0, 0),
					Size = UDim2.new(0, 1, 1, 0),
					ZIndex = 105,
				})
				library:create("Frame", {
					Parent = CurveCanvas,
					BackgroundColor3 = Color3.fromRGB(38, 38, 38),
					BorderSizePixel = 0,
					Position = UDim2.new(0, 0, i / GridSize, 0),
					Size = UDim2.new(1, 0, 0, 1),
					ZIndex = 105,
				})
			end

			-- ── curve pixels ─────────────────────────────────────────
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

			-- ── control points ───────────────────────────────────────
			for i = 1, PointCount do
				local xPos = (i - 1) / GridSize
				local yPos = 0.5

				local PointFrame = library:create("Frame", {
					Parent = CurveCanvas,
					BackgroundColor3 = themes.preset.accent,
					BorderColor3 = Color3.fromRGB(0, 0, 0),
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
					-- Clear the window drag so moving the mouse only moves this dot
					library.active_drag = nil
					while uis:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
						-- Keep suppressing window drag for the whole dot-drag duration
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
					-- Write points into flags directly so they are saved by get_config
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

			-- ── reset button (matches lib button style) ───────────────
			local btn_row = library:create("Frame", {
				Parent = grp_inner,
				Position = UDim2.new(0, 6, 0, 182),
				Size = UDim2.new(1, -12, 0, 18),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				ZIndex = 14,
			})

			local reset_inline = library:create("Frame", {
				Parent = btn_row,
				BorderColor3 = Color3.fromRGB(19, 19, 19),
				Size = UDim2.new(1, 0, 1, 0),
				BorderSizePixel = 0,
				BackgroundColor3 = Color3.fromRGB(8, 8, 8),
				ZIndex = 14,
			})

			local reset_btn = library:create("TextButton", {
				Parent = reset_inline,
				FontFace = library.font,
				TextColor3 = Color3.fromRGB(170, 170, 170),
				Text = "reset curve",
				TextStrokeTransparency = 0.5,
				Position = UDim2.new(0, 2, 0, 2),
				Size = UDim2.new(1, -4, 1, -4),
				TextSize = 12,
				BackgroundColor3 = Color3.fromRGB(38, 38, 38),
				BorderColor3 = Color3.fromRGB(56, 56, 56),
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



			-- ── public API ────────────────────────────────────────────
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
	}

	flags[cfg.flag] = {}

	local bodyparts = {}
	local bools = {}

	local hp_holder = library:create("Frame", {
		Parent = self[cfg.side],
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 272),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	})

	local hp_inline = library:create("Frame", {
		Parent = hp_holder,
		Position = UDim2.new(0, 0, 0, 4),
		BorderColor3 = Color3.fromRGB(19, 19, 19),
		Size = UDim2.new(1, 0, 1, -4),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(8, 8, 8),
	})

	local hp_frame = library:create("Frame", {
		Parent = hp_inline,
		Position = UDim2.new(0, 2, 0, 2),
		BorderColor3 = Color3.fromRGB(56, 56, 56),
		Size = UDim2.new(1, -4, 1, -4),
		BackgroundColor3 = Color3.fromRGB(22, 22, 22),
	})

	if cfg.type_char == "R15" then
		bodyparts.Head         = library:create("TextButton", { Text="", Parent=hp_frame, Position=UDim2.new(0.5,-25,0,16),  Size=UDim2.new(0,50,0,44),  BorderSizePixel=0, BackgroundColor3=Color3.fromRGB(38,38,38) })
		bodyparts.UpperTorso   = library:create("TextButton", { Text="", Parent=hp_frame, Position=UDim2.new(0.5,-42,0,64),  Size=UDim2.new(0,84,0,76),  BorderSizePixel=0, BackgroundColor3=Color3.fromRGB(38,38,38) })
		bodyparts.LeftUpperArm = library:create("TextButton", { Text="", Parent=hp_frame, Position=UDim2.new(0.5,-86,0,64),  Size=UDim2.new(0,40,0,34),  BorderSizePixel=0, BackgroundColor3=Color3.fromRGB(38,38,38) })
		bodyparts.RightUpperArm= library:create("TextButton", { Text="", Parent=hp_frame, Position=UDim2.new(0.5, 46,0,64),  Size=UDim2.new(0,40,0,34),  BorderSizePixel=0, BackgroundColor3=Color3.fromRGB(38,38,38) })
		bodyparts.LeftUpperLeg = library:create("TextButton", { Text="", Parent=hp_frame, Position=UDim2.new(0.5,-42,0,158), Size=UDim2.new(0,40,0,34),  BorderSizePixel=0, BackgroundColor3=Color3.fromRGB(38,38,38) })
		bodyparts.LeftLowerLeg = library:create("TextButton", { Text="", Parent=hp_frame, Position=UDim2.new(0.5,-42,0,196), Size=UDim2.new(0,40,0,42),  BorderSizePixel=0, BackgroundColor3=Color3.fromRGB(38,38,38) })
		bodyparts.RightFoot    = library:create("TextButton", { Text="", Parent=hp_frame, Position=UDim2.new(0.5,  2,0,242), Size=UDim2.new(0,40,0,6),   BorderSizePixel=0, BackgroundColor3=Color3.fromRGB(38,38,38) })
		bodyparts.LeftFoot     = library:create("TextButton", { Text="", Parent=hp_frame, Position=UDim2.new(0.5,-42,0,242), Size=UDim2.new(0,40,0,6),   BorderSizePixel=0, BackgroundColor3=Color3.fromRGB(38,38,38) })
		bodyparts.RightLowerLeg= library:create("TextButton", { Text="", Parent=hp_frame, Position=UDim2.new(0.5,  2,0,196), Size=UDim2.new(0,40,0,42),  BorderSizePixel=0, BackgroundColor3=Color3.fromRGB(38,38,38) })
		bodyparts.RightUpperLeg= library:create("TextButton", { Text="", Parent=hp_frame, Position=UDim2.new(0.5,  2,0,158), Size=UDim2.new(0,40,0,34),  BorderSizePixel=0, BackgroundColor3=Color3.fromRGB(38,38,38) })
		bodyparts.LeftHand     = library:create("TextButton", { Text="", Parent=hp_frame, Position=UDim2.new(0.5,-86,0,148), Size=UDim2.new(0,40,0,6),   BorderSizePixel=0, BackgroundColor3=Color3.fromRGB(38,38,38) })
		bodyparts.RightHand    = library:create("TextButton", { Text="", Parent=hp_frame, Position=UDim2.new(0.5, 46,0,148), Size=UDim2.new(0,40,0,6),   BorderSizePixel=0, BackgroundColor3=Color3.fromRGB(38,38,38) })
		bodyparts.LowerTorso   = library:create("TextButton", { Text="", Parent=hp_frame, Position=UDim2.new(0.5,-42,0,144), Size=UDim2.new(0,84,0,10),  BorderSizePixel=0, BackgroundColor3=Color3.fromRGB(38,38,38) })
		bodyparts.RightLowerArm= library:create("TextButton", { Text="", Parent=hp_frame, Position=UDim2.new(0.5, 46,0,102), Size=UDim2.new(0,40,0,42),  BorderSizePixel=0, BackgroundColor3=Color3.fromRGB(38,38,38) })
		bodyparts.LeftLowerArm = library:create("TextButton", { Text="", Parent=hp_frame, Position=UDim2.new(0.5,-86,0,102), Size=UDim2.new(0,40,0,42),  BorderSizePixel=0, BackgroundColor3=Color3.fromRGB(38,38,38) })

		local hrp_outline = library:create("TextButton", { Text="", Parent=hp_frame, Position=UDim2.new(0.5,-10,0,96), BorderSizePixel=0, Size=UDim2.new(0,20,0,20), BackgroundColor3=Color3.fromRGB(22,22,22) })
		bodyparts.HumanoidRootPart = library:create("TextButton", { Text="", Parent=hrp_outline, Position=UDim2.new(0,4,0,4), BorderSizePixel=0, Size=UDim2.new(1,-8,1,-8), BackgroundColor3=Color3.fromRGB(38,38,38) })
	else
		bodyparts.Head     = library:create("TextButton", { Parent=hp_frame, Text="", Position=UDim2.new(0.5,-25,0,16),  Size=UDim2.new(0,50,0,44),  BorderSizePixel=0, BackgroundColor3=Color3.fromRGB(38,38,38) })
		bodyparts.Torso    = library:create("TextButton", { Parent=hp_frame, Text="", Position=UDim2.new(0.5,-42,0,64),  Size=UDim2.new(0,84,0,90),  BorderSizePixel=0, BackgroundColor3=Color3.fromRGB(38,38,38) })
		bodyparts.LeftArm  = library:create("TextButton", { Parent=hp_frame, Text="", Position=UDim2.new(0.5,-86,0,64),  Size=UDim2.new(0,40,0,90),  BorderSizePixel=0, BackgroundColor3=Color3.fromRGB(38,38,38) })
		bodyparts.RightArm = library:create("TextButton", { Parent=hp_frame, Text="", Position=UDim2.new(0.5, 46,0,64),  Size=UDim2.new(0,40,0,90),  BorderSizePixel=0, BackgroundColor3=Color3.fromRGB(38,38,38) })
		bodyparts.RightLeg = library:create("TextButton", { Parent=hp_frame, Text="", Position=UDim2.new(0.5,  2,0,158), Size=UDim2.new(0,40,0,90),  BorderSizePixel=0, BackgroundColor3=Color3.fromRGB(38,38,38) })
		bodyparts.LeftLeg  = library:create("TextButton", { Parent=hp_frame, Text="", Position=UDim2.new(0.5,-42,0,158), Size=UDim2.new(0,40,0,90),  BorderSizePixel=0, BackgroundColor3=Color3.fromRGB(38,38,38) })

		local hrp_out = library:create("TextButton", { Parent=hp_frame, Text="", Position=UDim2.new(0.5,-10,0,99), BorderSizePixel=0, Size=UDim2.new(0,20,0,20), BackgroundColor3=Color3.fromRGB(22,22,22) })
		bodyparts.HumanoidRootPart = library:create("TextButton", { Parent=hrp_out, Text="", Position=UDim2.new(0,4,0,4), BorderSizePixel=0, Size=UDim2.new(1,-8,1,-8), BackgroundColor3=Color3.fromRGB(38,38,38) })
	end

	library:create("TextLabel", {
		Parent = hp_inline,
		FontFace = library.font,
		TextColor3 = Color3.fromRGB(170, 170, 170),
		Text = cfg.name,
		TextStrokeTransparency = 0.5,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 8, 0, 0),
		ZIndex = 2,
		TextSize = 12,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	})

	function cfg.set(parts)
		flags[cfg.flag] = {}
		for name_part, button in pairs(bodyparts) do
			bools[name_part] = false
			local g = button:FindFirstChildOfClass("ImageLabel")
			if g then g.Visible = false end
			button.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
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
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
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
				button.BackgroundColor3 = bools[name_part] and themes.preset.accent or Color3.fromRGB(38, 38, 38)
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
		TextColor3 = Color3.fromRGB(170, 170, 170),
		Text = cfg.name,
		TextStrokeTransparency = 0.5,
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, -26, 0, 12),
		ZIndex = 1,
		TextSize = 12,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	})

	local right_components = library:create("Frame", {
		Parent = object,
		Position = UDim2.new(1, 15, 0, 1),
		BorderSizePixel = 0,
		Size = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	})

	library:create("UIListLayout", { Parent=right_components, FillDirection=Enum.FillDirection.Horizontal, HorizontalAlignment=Enum.HorizontalAlignment.Right, Padding=UDim.new(0,3), SortOrder=Enum.SortOrder.LayoutOrder })

	local icon_inline = library:create("TextButton", {
		Parent = object,
		Position = UDim2.new(0, -15, 0, 1),
		BorderColor3 = Color3.fromRGB(19, 19, 19),
		Size = UDim2.new(0, 10, 0, 10),
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = Color3.fromRGB(8, 8, 8),
	})

	local icon = library:create("Frame", {
		Parent = icon_inline,
		Position = UDim2.new(0, 2, 0, 2),
		BorderColor3 = Color3.fromRGB(56, 56, 56),
		Size = UDim2.new(1, -4, 1, -4),
		BackgroundColor3 = Color3.fromRGB(22, 22, 22),
	})

	local icon_2 = library:create("Frame", {
		Parent = icon,
		BorderColor3 = Color3.fromRGB(56, 56, 56),
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
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
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
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
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

	-- FIXED: was referencing undefined left_components
	self.previous_holder  = self.holder
	self.bottom_holder    = bottom_components
	self.right_holder     = right_components

	config_flags[cfg.flag] = cfg.set

	-- controller nav: register this toggle (icon is 20px left of object)
	table.insert(library.nav_elements, { cfg = cfg, type = "toggle", root = object, extend_left = 20 })

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
			TextColor3 = Color3.fromRGB(170, 170, 170),
			Text = cfg.name,
			TextStrokeTransparency = 0.5,
			Size = UDim2.new(1, -26, 0, 12),
			BorderSizePixel = 0,
			BackgroundTransparency = 1,
			TextXAlignment = Enum.TextXAlignment.Left,
			AutomaticSize = Enum.AutomaticSize.Y,
			TextYAlignment = Enum.TextYAlignment.Top,
			TextSize = 12,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		})

		bottom_components = library:create("Frame", {
			Parent = object,
			Visible = true,
			Position = UDim2.new(0, 0, 0, 13),
			BorderSizePixel = 0,
			Size = UDim2.new(1, 26, 0, 0),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
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
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	})

	local slider_inline = library:create("TextButton", {
		Parent = slider_holder,
		Position = UDim2.new(0, 0, 0, 1),
		BorderColor3 = Color3.fromRGB(19, 19, 19),
		Size = UDim2.new(1, -26, 0, 8),
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = Color3.fromRGB(8, 8, 8),
	})

	local fill_inline = library:create("Frame", {
		Parent = slider_inline,
		Size = UDim2.new(0.5, 0, 1, 0),
		BorderColor3 = Color3.fromRGB(19, 19, 19),
		ZIndex = 2,
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(19, 19, 19),
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
		TextColor3 = Color3.fromRGB(170, 170, 170),
		TextStrokeTransparency = 0.5,
		Size = UDim2.new(0, 1, 0, 11),
		BackgroundTransparency = 1,
		Position = UDim2.new(1, 0, 0, 1),
		BorderSizePixel = 0,
		FontFace = library.font,
		TextSize = 12,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	})

	local sl_glow = library:create("ImageLabel", {
		Parent = fill_inline,
		ImageColor3 = themes.preset.accent,
		ScaleType = Enum.ScaleType.Slice,
		ImageTransparency = 0.9,
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
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
		TextColor3 = Color3.fromRGB(170, 170, 170),
		Text = "+",
		TextStrokeTransparency = 0.5,
		BackgroundTransparency = 1,
		Position = UDim2.new(1, 5, 0, -1),
		Size = UDim2.new(0, 8, 0, 8),
		FontFace = library.font,
		TextSize = 8,
		BackgroundColor3 = Color3.fromRGB(38, 38, 38),
	})

	local sub_btn = library:create("TextButton", {
		Parent = slider_inline,
		TextWrapped = true,
		TextColor3 = Color3.fromRGB(170, 170, 170),
		Text = "-",
		TextStrokeTransparency = 0.5,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, -15, 0, -1),
		Size = UDim2.new(0, 8, 0, 8),
		FontFace = library.font,
		TextSize = 12,
		BackgroundColor3 = Color3.fromRGB(38, 38, 38),
	})

	local slider = library:create("Frame", {
		Parent = slider_inline,
		Position = UDim2.new(0, 2, 0, 2),
		BorderColor3 = Color3.fromRGB(56, 56, 56),
		Size = UDim2.new(1, -4, 1, -4),
		BackgroundColor3 = Color3.fromRGB(22, 22, 22),
	})

	library:create("UIPadding", { Parent=slider_holder, PaddingBottom=UDim.new(0,-17) })

	function cfg.set(value)
		if type(value) ~= "number" then return end
		cfg.value = math.clamp(library:round(value, cfg.intervals), cfg.min, cfg.max)
		fill_inline.Size = dim2((cfg.value - cfg.min) / (cfg.max - cfg.min), 0, 1, 0)
		VALUE_TEXT.Text = tostring(cfg.value) .. cfg.suffix
		flags[cfg.flag] = cfg.value
		cfg.callback(flags[cfg.flag])
	end

	cfg.set(cfg.default)
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

	-- controller nav: register this slider
	table.insert(library.nav_elements, { cfg = cfg, type = "slider", root = slider_inline })

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
		local _pSvc = game:GetService("Players")
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
			TextColor3 = Color3.fromRGB(170, 170, 170),
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
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		})

		bottom_components = library:create("Frame", {
			Parent = object,
			Visible = true,
			Position = UDim2.new(0, 0, 0, 13),
			BorderSizePixel = 0,
			Size = UDim2.new(1, 26, 0, 0),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
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
		BorderColor3 = Color3.fromRGB(19, 19, 19),
		Size = UDim2.new(1, -26, 0, 16),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(8, 8, 8),
	})

	local dropdown = library:create("TextButton", {
		Parent = dropdown_inline,
		FontFace = library.font,
		TextColor3 = Color3.fromRGB(170, 170, 170),
		Text = "",
		TextStrokeTransparency = 0.5,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, -4, 1, -4),
		Position = UDim2.new(0, 2, 0, 2),
		TextSize = 12,
		BackgroundColor3 = Color3.fromRGB(38, 38, 38),
	})

	library:create("UIPadding", { Parent=dropdown, PaddingLeft=UDim.new(0,5) })

	local icon = library:create("TextLabel", {
		Parent = dropdown,
		FontFace = library.font,
		TextColor3 = Color3.fromRGB(170, 170, 170),
		Text = "+",
		TextStrokeTransparency = 0.5,
		Size = UDim2.new(0, 1, 1, 0),
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Right,
		Position = UDim2.new(1, -6, 0, -1),
		BorderSizePixel = 0,
		TextSize = 8,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	})

	local optionsHeight = getDropdownHeight(#cfg.items)

	local content_inline = library:create("Frame", {
		Parent = library.gui,
		BorderColor3 = Color3.fromRGB(19, 19, 19),
		BorderSizePixel = 0,
		ZIndex = 9999,
		Visible = false,
		Size = UDim2.new(0, dropdown_inline.AbsoluteSize.X, 0, optionsHeight + 4),
		Position = UDim2.new(0, dropdown_inline.AbsolutePosition.X, 0, dropdown_inline.AbsolutePosition.Y + dropdown_inline.AbsoluteSize.Y + 2),
		BackgroundColor3 = Color3.fromRGB(8, 8, 8),
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
		BorderColor3 = Color3.fromRGB(56, 56, 56),
		Size = UDim2.new(1, -4, 1, -4),
		BackgroundColor3 = Color3.fromRGB(38, 38, 38),
	})

	local options_scroll = library:create("ScrollingFrame", {
		Parent = content,
		Active = true,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = Color3.fromRGB(90, 90, 90),
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
				v.BackgroundTransparency = 0
			else
				v.BackgroundTransparency = 1
			end
		end

		cfg.multi_items = selected
		dropdown.Text = is_table and table.concat(selected, ",  ") or selected[1] or ""
		flags[cfg.flag] = is_table and selected or selected[1]
		cfg.callback(flags[cfg.flag])
	end

	function cfg:refresh_options(refreshed_list)
		for _, v in next, cfg.option_instances do
			v:Destroy()
		end
		cfg.option_instances = {}

		for _, v in next, refreshed_list do
			local op = library:create("TextButton", {
				Parent = options_scroll,
				FontFace = library.font,
				TextColor3 = Color3.fromRGB(170, 170, 170),
				Text = v,
				BackgroundTransparency = 1,
				TextStrokeTransparency = 0.5,
				Size = UDim2.new(1, 0, 0, 14),
				TextXAlignment = Enum.TextXAlignment.Left,
				BorderSizePixel = 0,
				TextSize = 12,
				BackgroundColor3 = Color3.fromRGB(65, 65, 65),
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

		-- Update height
		local itemCount = #refreshed_list
		local newHeight = 16 * math.min(itemCount, 5)
		optionsHeight = newHeight
		options_scroll.Size = UDim2.new(1, -4, 0, newHeight)
		local absW = dropdown_inline.AbsoluteSize.X
		if absW <= 0 then absW = 200 end
		content_inline.Size = UDim2.new(0, absW, 0, newHeight + 4)
		dropdown.Text = ""
	end

	dropdown.MouseButton1Click:Connect(function()
		cfg.open = not cfg.open
		cfg.set_visible(cfg.open)
	end)

	-- Expose the row label frame so set_feature_control_visible can
	-- hide/show the entire row without touching the flyout popup.
	cfg.object = object

	-- Hides/shows the label row (and closes the flyout if hiding).
	-- set_feature_control_visible calls this instead of set_visible so
	-- it never accidentally opens the flyout when the menu is closed.
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

	-- controller nav: register this dropdown
	table.insert(library.nav_elements, { cfg = cfg, type = "dropdown", root = dropdown_inline })

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
			TextColor3 = Color3.fromRGB(170, 170, 170),
			Text = cfg.name,
			TextStrokeTransparency = 0.5,
			Size = UDim2.new(1, -26, 0, 12),
			BorderSizePixel = 0,
			BackgroundTransparency = 1,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			TextSize = 12,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		})

		right_components = library:create("Frame", {
			Parent = obj,
			Position = UDim2.new(1, 15, 0, 1),
			BorderSizePixel = 0,
			Size = UDim2.new(0, 0, 1, 0),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		})

		library:create("UIListLayout", { Parent=right_components, FillDirection=Enum.FillDirection.Horizontal, HorizontalAlignment=Enum.HorizontalAlignment.Right, Padding=UDim.new(0,3), SortOrder=Enum.SortOrder.LayoutOrder })
	end

	local icon_inline = library:create("TextButton", {
		Parent = cfg.name and right_components or self.right_holder,
		Text = "",
		Size = UDim2.new(0, 16, 0, 10),
		Position = UDim2.new(0, -15, 0, 1),
		BorderColor3 = Color3.fromRGB(19, 19, 19),
		ZIndex = 3,
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(9, 9, 44),
	})

	local icon = library:create("Frame", {
		Parent = icon_inline,
		Position = UDim2.new(0, 2, 0, 2),
		BorderColor3 = Color3.fromRGB(22, 22, 108),
		ZIndex = 2,
		Size = UDim2.new(1, -4, 1, -4),
		BackgroundColor3 = Color3.fromRGB(41, 41, 204),
	})

	local cp_glow = library:create("ImageLabel", {
		Parent = icon_inline,
		ImageColor3 = Color3.fromRGB(41, 41, 204),
		ScaleType = Enum.ScaleType.Slice,
		ImageTransparency = 0.9,
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		Image = "http://www.roblox.com/asset/?id=18245826428",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, -20, 0, -20),
		Size = UDim2.new(1, 40, 1, 40),
		ZIndex = 2,
		SliceCenter = Rect.new(Vector2.new(21, 21), Vector2.new(79, 79)),
	})

	-- Picker panel
	local picker_inline = library:create("Frame", {
		Parent = library.gui,
		Size = UDim2.new(0, 142, 0, 146),
		Position = UDim2.fromOffset(-9999, -9999),
		BorderColor3 = Color3.fromRGB(19, 19, 19),
		ZIndex = 9999,
		BorderSizePixel = 0,
		Visible = false,
		BackgroundColor3 = Color3.fromRGB(8, 8, 8),
	})

	local picker = library:create("Frame", {
		Parent = picker_inline,
		Position = UDim2.new(0, 2, 0, 2),
		BorderColor3 = Color3.fromRGB(56, 56, 56),
		Size = UDim2.new(1, -4, 1, -4),
		BackgroundColor3 = Color3.fromRGB(38, 38, 38),
	})

	local sat_inline = library:create("TextButton", {
		Parent = picker,
		Text = "",
		Position = UDim2.new(0, 4, 0, 4),
		BorderColor3 = Color3.fromRGB(19, 19, 19),
		Size = UDim2.new(1, -8, 1, -50),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(8, 8, 8),
	})

	local sat = library:create("Frame", {
		Parent = sat_inline,
		Position = UDim2.new(0, 2, 0, 2),
		BorderColor3 = Color3.fromRGB(56, 56, 56),
		Size = UDim2.new(1, -4, 1, -4),
		BackgroundColor3 = Color3.fromRGB(255, 0, 0),
	})

	local sat_white = library:create("Frame", {
		Parent = sat,
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = 2,
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	})

	library:create("UIGradient", { Parent=sat_white, Transparency=NumberSequence.new({ NumberSequenceKeypoint.new(0,0), NumberSequenceKeypoint.new(1,1) }) })

	local sat_black = library:create("Frame", {
		Parent = sat_white,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	})

	library:create("UIGradient", { Parent=sat_black, Rotation=90, Transparency=NumberSequence.new({ NumberSequenceKeypoint.new(0,1), NumberSequenceKeypoint.new(1,0) }), Color=ColorSequence.new({ ColorSequenceKeypoint.new(0,Color3.fromRGB(0,0,0)), ColorSequenceKeypoint.new(1,Color3.fromRGB(0,0,0)) }) })

	local sat_black_cursor = library:create("Frame", {
		Parent = sat_black,
		Position = UDim2.new(0.8, 0, 0.2, 0),
		BorderColor3 = Color3.fromRGB(108, 22, 22),
		Size = UDim2.new(0, 1, 0, 1),
		BackgroundColor3 = Color3.fromRGB(204, 41, 41),
	})

	local preview_inline = library:create("Frame", {
		Parent = picker,
		Position = UDim2.new(1, -20, 1, -20),
		BorderColor3 = Color3.fromRGB(19, 19, 19),
		Size = UDim2.new(0, 16, 0, 16),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(35, 35, 35),
	})

	local preview = library:create("Frame", {
		Parent = preview_inline,
		BackgroundTransparency = 0,
		Position = UDim2.new(0, 2, 0, 2),
		ZIndex = 2,
		Size = UDim2.new(1, -4, 1, -4),
		BackgroundColor3 = Color3.fromRGB(204, 41, 41),
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
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	})

	local hue_inline = library:create("TextButton", {
		Parent = picker,
		Text = "",
		Position = UDim2.new(0, 4, 1, -44),
		BorderColor3 = Color3.fromRGB(19, 19, 19),
		Size = UDim2.new(1, -8, 0, 10),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(8, 8, 8),
	})

	local hue_border = library:create("Frame", {
		Parent = hue_inline,
		Position = UDim2.new(0, 2, 0, 2),
		BorderColor3 = Color3.fromRGB(56, 56, 56),
		Size = UDim2.new(1, -4, 1, -4),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	})

	local hue = library:create("Frame", {
		Parent = hue_border,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	})

	library:create("UIGradient", { Parent=hue, Color=ColorSequence.new({
		ColorSequenceKeypoint.new(0,     Color3.fromRGB(255, 0, 0)),
		ColorSequenceKeypoint.new(0.167, Color3.fromRGB(255, 255, 0)),
		ColorSequenceKeypoint.new(0.333, Color3.fromRGB(0, 255, 0)),
		ColorSequenceKeypoint.new(0.5,   Color3.fromRGB(0, 255, 255)),
		ColorSequenceKeypoint.new(0.667, Color3.fromRGB(0, 0, 255)),
		ColorSequenceKeypoint.new(0.833, Color3.fromRGB(255, 0, 255)),
		ColorSequenceKeypoint.new(1,     Color3.fromRGB(255, 0, 0)),
	}) })

	local hue_cursor = library:create("Frame", {
		Parent = hue,
		BorderColor3 = Color3.fromRGB(108, 22, 22),
		Size = UDim2.new(0, 1, 1, 0),
		BackgroundColor3 = Color3.fromRGB(204, 41, 41),
	})

	local input_inline = library:create("Frame", {
		Parent = picker,
		Position = UDim2.new(0, 4, 1, -20),
		BorderColor3 = Color3.fromRGB(19, 19, 19),
		Size = UDim2.new(1, -26, 0, 16),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(8, 8, 8),
	})

	local __input = library:create("TextBox", {
		Parent = input_inline,
		FontFace = library.font,
		TextColor3 = Color3.fromRGB(170, 170, 170),
		Text = "204, 41, 41, 0.5",
		TextStrokeTransparency = 0.5,
		Size = UDim2.new(1, -4, 1, -4),
		PlaceholderColor3 = Color3.fromRGB(90, 90, 90),
		Position = UDim2.new(0, 2, 0, 2),
		PlaceholderText = "r, g, b, a",
		TextSize = 12,
		BackgroundColor3 = Color3.fromRGB(38, 38, 38),
	})

	local alpha_inline = library:create("TextButton", {
		Parent = picker,
		Text = "",
		Position = UDim2.new(0, 4, 1, -32),
		BorderColor3 = Color3.fromRGB(19, 19, 19),
		Size = UDim2.new(1, -8, 0, 10),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(8, 8, 8),
	})

	local alpha_frame = library:create("Frame", {
		Parent = alpha_inline,
		Position = UDim2.new(0, 2, 0, 2),
		BorderColor3 = Color3.fromRGB(56, 56, 56),
		Size = UDim2.new(1, -4, 1, -4),
		BackgroundColor3 = Color3.fromRGB(204, 41, 41),
	})

	local alpha_image = library:create("ImageLabel", {
		Parent = alpha_frame,
		ScaleType = Enum.ScaleType.Tile,
		Image = "http://www.roblox.com/asset/?id=18343135386",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		TileSize = UDim2.new(0, 6, 0, 6),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	})

	library:create("UIGradient", { Parent=alpha_image, Transparency=NumberSequence.new({ NumberSequenceKeypoint.new(0,1), NumberSequenceKeypoint.new(1,0) }) })

	local alpha_cursor = library:create("Frame", {
		Parent = alpha_image,
		Position = UDim2.new(0.5, 0, 0, 0),
		BorderColor3 = Color3.fromRGB(108, 22, 22),
		Size = UDim2.new(0, 1, 1, 0),
		BackgroundColor3 = Color3.fromRGB(204, 41, 41),
	})

	-- Animation mode picker
	local anim_inline = library:create("Frame", {
		Parent = library.gui,
		BorderColor3 = Color3.fromRGB(19, 19, 19),
		Size = UDim2.new(0, 73, 0, 0),
		Position = UDim2.fromOffset(-9999, -9999),
		BorderSizePixel = 0,
		ZIndex = 9999,
		Visible = false,
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Color3.fromRGB(8, 8, 8),
	})

	local anim_content = library:create("Frame", {
		Parent = anim_inline,
		Position = UDim2.new(0, 2, 0, 2),
		BorderColor3 = Color3.fromRGB(56, 56, 56),
		Size = UDim2.new(1, -4, 1, -4),
		BackgroundColor3 = Color3.fromRGB(38, 38, 38),
	})

	local anim_options = library:create("Frame", {
		Parent = anim_content,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 2, 0, 2),
		BorderSizePixel = 0,
		Size = UDim2.new(1, -4, 1, -4),
		BackgroundColor3 = Color3.fromRGB(50, 50, 50),
	})

	library:create("UIListLayout", { Parent=anim_options, Padding=UDim.new(0,2), SortOrder=Enum.SortOrder.LayoutOrder })

	local function make_anim_btn(label)
		local b = library:create("TextButton", {
			Parent = anim_options,
			FontFace = library.font,
			TextColor3 = Color3.fromRGB(170, 170, 170),
			Text = label,
			TextStrokeTransparency = 0.5,
			Size = UDim2.new(1, 0, 0, 12),
			BackgroundTransparency = 1,
			TextXAlignment = Enum.TextXAlignment.Left,
			BorderSizePixel = 0,
			TextSize = 12,
			BackgroundColor3 = Color3.fromRGB(65, 65, 65),
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
		cfg.open = not cfg.open
		cfg.set_visible(cfg.open)
	end)

	icon_inline.MouseButton2Click:Connect(function()
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
			a = alpha_val
		end

		local Color = Color3.fromHSV(h, s, v)

		hue_cursor.Position    = UDim2.new(h, -1, 0, 0)
		alpha_cursor.Position  = UDim2.new(a, -1, 0, 0)
		sat_black_cursor.Position = UDim2.new(s, -0.5, 1 - v, -0.5)

		icon_inline.BackgroundColor3 = Color3.fromRGB(Color.R * 255 * 0.25, Color.G * 255 * 0.25, Color.B * 255 * 0.25)
		icon.BackgroundColor3 = Color
		cp_glow.ImageColor3 = Color
		preview.BackgroundColor3 = Color
		alpha_frame.BackgroundColor3 = Color
		sat.BackgroundColor3  = Color3.fromHSV(h, 1, 1)

		__input.Text = string.format("%d, %d, %d, %.2f", Color.R * 255, Color.G * 255, Color.B * 255, a)

		cfg.color = Color
		cfg.alpha = a
		flags[cfg.flag] = { Color = Color, Transparency = a }
		cfg.callback(Color, a)
	end

	__input.FocusLost:Connect(function()
		local r, g, b, al = library:convert_string_rgb(__input.Text)
		if r and g and b and al then
			cfg.set(rgb(r, g, b), al)
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
		if button then button.BackgroundTransparency = 0 end
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

	-- controller nav: register this colorpicker
	-- Activating opens/closes the picker panel (same as clicking the color swatch)
	local _cp_root = (cfg.name and right_components and right_components.Parent) or icon_inline
	cfg._cp_icon = icon_inline
	cfg._cp_picker = picker_inline
	table.insert(library.nav_elements, { cfg = cfg, type = "colorpicker", root = _cp_root })

	local cp_elapsed = 0
	library:connection(run_service.Heartbeat, function(dt)
		if selectedMode == "normal" then return end

		cp_elapsed += dt
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
			TextColor3 = Color3.fromRGB(170, 170, 170),
			Text = cfg.name,
			TextStrokeTransparency = 0.5,
			Size = UDim2.new(1, -26, 0, 12),
			BorderSizePixel = 0,
			BackgroundTransparency = 1,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			TextSize = 12,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		})

		right_components = library:create("Frame", {
			Parent = obj,
			Position = UDim2.new(1, 15, 0, 1),
			BorderSizePixel = 0,
			Size = UDim2.new(0, 0, 1, 0),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		})

		library:create("UIListLayout", { Parent=right_components, FillDirection=Enum.FillDirection.Horizontal, HorizontalAlignment=Enum.HorizontalAlignment.Right, Padding=UDim.new(0,3), SortOrder=Enum.SortOrder.LayoutOrder })
	end

	local keybind = library:create("TextButton", {
		Parent = cfg.name and right_components or self.right_holder,
		FontFace = library.font,
		TextColor3 = Color3.fromRGB(170, 170, 170),
		Text = "[...]",
		TextStrokeTransparency = 0.5,
		Size = UDim2.new(0, 16, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		TextSize = 12,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	})

	local mode_inline = library:create("Frame", {
		Parent = library.gui,
		BorderColor3 = Color3.fromRGB(19, 19, 19),
		Size = UDim2.new(0, 57, 0, 0),
		Position = dim2(0, keybind.AbsolutePosition.X, 0, keybind.AbsolutePosition.Y - 5),
		BorderSizePixel = 0,
		ZIndex = 9999,
		AutomaticSize = Enum.AutomaticSize.Y,
		Visible = false,
		BackgroundColor3 = Color3.fromRGB(8, 8, 8),
	})

	keybind:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
		if not mode_inline.Visible then return end
		mode_inline.Position = UDim2.new(0, keybind.AbsolutePosition.X, 0, keybind.AbsolutePosition.Y + 15)
	end)

	local mode_content = library:create("Frame", {
		Parent = mode_inline,
		Position = UDim2.new(0, 2, 0, 2),
		BorderColor3 = Color3.fromRGB(56, 56, 56),
		Size = UDim2.new(1, -4, 1, -4),
		BackgroundColor3 = Color3.fromRGB(38, 38, 38),
	})

	local mode_opts = library:create("Frame", {
		Parent = mode_content,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 2, 0, 2),
		BorderSizePixel = 0,
		Size = UDim2.new(1, -4, 1, -4),
		BackgroundColor3 = Color3.fromRGB(50, 50, 50),
	})

	library:create("UIListLayout", { Parent=mode_opts, Padding=UDim.new(0,2), SortOrder=Enum.SortOrder.LayoutOrder })

	local function make_mode_btn(label)
		local b = library:create("TextButton", {
			Parent = mode_opts,
			FontFace = library.font,
			TextColor3 = Color3.fromRGB(170, 170, 170),
			Text = label,
			TextStrokeTransparency = 0.5,
			Size = UDim2.new(1, 0, 0, 12),
			BackgroundTransparency = 1,
			TextXAlignment = Enum.TextXAlignment.Left,
			BorderSizePixel = 0,
			TextSize = 12,
			BackgroundColor3 = Color3.fromRGB(65, 65, 65),
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

	-- FIXED: highlight_current_mode defined before use
	local function highlight_current_mode()
		btn_press.BackgroundTransparency  = 1
		btn_hold.BackgroundTransparency   = 1
		btn_always.BackgroundTransparency = 1

		if cfg.mode == "toggle" then
			btn_press.BackgroundTransparency = 0
		elseif cfg.mode == "hold" then
			btn_hold.BackgroundTransparency = 0
		elseif cfg.mode == "always" then
			btn_always.BackgroundTransparency = 0
		end
	end

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
			-- Only overwrite cfg.key if explicitly provided (nil means "not in delta", keep current key)
			if input.key ~= nil then cfg.key = input.key end
			-- Only overwrite cfg.mode if explicitly provided, preserve current mode otherwise
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
				-- Accept any digital gamepad button; skip raw thumbstick axis events
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
		if cfg.binding then return end  -- don't fire while rebinding

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

	-- controller nav: register this keybind
	-- Named keybind: root = obj (the label row). Nameless: root = self.right_holder.Parent
	-- which is the sibling toggle/element's full row, so the highlight covers the whole line.
	local _kb_root
	if cfg.name then
		_kb_root = right_components and right_components.Parent or keybind
	else
		_kb_root = (self.right_holder and self.right_holder.Parent) or keybind
	end
	cfg._keybind_button = keybind
	table.insert(library.nav_elements, { cfg = cfg, type = "keybind", root = _kb_root })

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
		BorderColor3 = Color3.fromRGB(19, 19, 19),
		Size = UDim2.new(1, -26, 0, 16),
		BorderSizePixel = 0,
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Color3.fromRGB(8, 8, 8),
	})

	library:create("UIListLayout", {
		Parent = button_inline,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 2),
	})

	local main_button = library:create("TextButton", {
		Parent = button_inline,
		FontFace = library.font,
		TextColor3 = Color3.fromRGB(170, 170, 170),
		BorderColor3 = Color3.fromRGB(56, 56, 56),
		Text = cfg.name,
		TextStrokeTransparency = 0.5,
		Size = UDim2.new(1, -4, 0, 12),
		TextSize = 12,
		BackgroundColor3 = Color3.fromRGB(38, 38, 38),
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
			TextColor3 = Color3.fromRGB(170, 170, 170),
			BorderColor3 = Color3.fromRGB(56, 56, 56),
			Text = sub_cfg.name,
			TextStrokeTransparency = 0.5,
			Size = UDim2.new(1, -4, 0, 12),
			TextSize = 12,
			BackgroundColor3 = Color3.fromRGB(38, 38, 38),
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

		table.insert(library.nav_elements, { cfg = sub_cfg, type = "button", root = sub_btn })

		return btn_api
	end

	table.insert(library.nav_elements, { cfg = cfg, type = "button", root = main_button })

	return setmetatable(btn_api, library)
end

-- ============================================================
--  AddGroupbox: creates a floating draggable curve editor window
--  Available on sections AND tabbox tabs via library metatable
-- ============================================================

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
		BackgroundColor3 = Color3.fromRGB(40, 40, 40),
		BorderColor3 = Color3.fromRGB(8, 8, 8),
		ZIndex = 10,
	})
	library:make_draggable(grp_outer)

	local grp_accent = library:create("Frame", {
		Parent = grp_outer,
		BorderColor3 = Color3.fromRGB(34, 34, 34),
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
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		Size = UDim2.new(1, 0, 0, 1),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		ZIndex = 11,
	})

	local grp_glow = library:create("ImageLabel", {
		Parent = grp_outer,
		ImageColor3 = themes.preset.accent,
		ScaleType = Enum.ScaleType.Slice,
		ImageTransparency = 0.9,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
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
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		Size = UDim2.new(1, -4, 1, -4),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(26, 26, 26),
		ZIndex = 11,
	})

	local grp_frame = library:create("Frame", {
		Parent = grp_inline1,
		Position = UDim2.new(0, 2, 0, 2),
		BorderColor3 = Color3.fromRGB(57, 57, 57),
		Size = UDim2.new(1, -4, 1, -4),
		BackgroundColor3 = Color3.fromRGB(26, 26, 26),
		ZIndex = 12,
	})

	local grp_tab = library:create("Frame", {
		Parent = grp_frame,
		Position = UDim2.new(0, 6, 0, 6),
		BorderColor3 = Color3.fromRGB(19, 19, 19),
		Size = UDim2.new(1, -12, 1, -12),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(19, 19, 19),
		ZIndex = 12,
	})

	local grp_inner = library:create("Frame", {
		Parent = grp_tab,
		Position = UDim2.new(0, 2, 0, 2),
		BorderColor3 = Color3.fromRGB(56, 56, 56),
		Size = UDim2.new(1, -4, 1, -4),
		BackgroundColor3 = Color3.fromRGB(22, 22, 22),
		ZIndex = 13,
	})

	library:create("TextLabel", {
		Parent = grp_inner,
		FontFace = library.font,
		TextColor3 = Color3.fromRGB(170, 170, 170),
		Text = Info.Name or "",
		TextStrokeTransparency = 0.5,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 12),
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 8, 0, 2),
		ZIndex = 14,
		TextSize = 12,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
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
			BorderColor3 = Color3.fromRGB(56, 56, 56),
			Size = UDim2.new(1, -12, 0, 160),
			BackgroundColor3 = Color3.fromRGB(19, 19, 19),
			ZIndex = 14,
		})

		local canvas_inner = library:create("Frame", {
			Parent = canvas_outer,
			Position = UDim2.new(0, 1, 0, 1),
			Size = UDim2.new(1, -2, 1, -2),
			BackgroundColor3 = Color3.fromRGB(15, 15, 15),
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
				BackgroundColor3 = Color3.fromRGB(38, 38, 38),
				BorderSizePixel = 0,
				Position = UDim2.new(i / GridSize, 0, 0, 0),
				Size = UDim2.new(0, 1, 1, 0),
				ZIndex = 105,
			})
			library:create("Frame", {
				Parent = CurveCanvas,
				BackgroundColor3 = Color3.fromRGB(38, 38, 38),
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
				BorderColor3 = Color3.fromRGB(0, 0, 0),
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
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			ZIndex = 14,
		})

		local reset_inline = library:create("Frame", {
			Parent = btn_row,
			BorderColor3 = Color3.fromRGB(19, 19, 19),
			Size = UDim2.new(1, 0, 1, 0),
			BorderSizePixel = 0,
			BackgroundColor3 = Color3.fromRGB(8, 8, 8),
			ZIndex = 14,
		})

		local reset_btn = library:create("TextButton", {
			Parent = reset_inline,
			FontFace = library.font,
			TextColor3 = Color3.fromRGB(170, 170, 170),
			Text = "reset curve",
			TextStrokeTransparency = 0.5,
			Position = UDim2.new(0, 2, 0, 2),
			Size = UDim2.new(1, -4, 1, -4),
			TextSize = 12,
			BackgroundColor3 = Color3.fromRGB(38, 38, 38),
			BorderColor3 = Color3.fromRGB(56, 56, 56),
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

-- ============================================================
--  TABBOX
-- ============================================================

function library:tabbox(properties)
	local cfg = {
		name = properties.name or properties.Name or "",
		tabs = {},
		default_tab = properties.default or properties.Default or nil,
	}

	-- Remove section top padding so tabbox sits right under the section title
	if self.holder then
		local pad = self.holder:FindFirstChildOfClass("UIPadding")
		if pad then
			pad.PaddingTop = UDim.new(0, 0)
			pad.PaddingBottom = UDim.new(0, 2)
		end
	end

	-- Outer border frame (the "box" look)
	local box_outer = library:create("Frame", {
		Parent = self.holder,
		Size = UDim2.new(1, 0, 0, 0),
		BorderSizePixel = 0,
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Color3.fromRGB(56, 56, 56),
	})

	-- Add spacing below the tabbox to prevent overlap with other sections
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
		BackgroundColor3 = Color3.fromRGB(22, 22, 22),
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

	-- Divider line below tab buttons
	library:create("Frame", {
		Parent = box_inner,
		Position = UDim2.new(0, 0, 0, 18),
		Size = UDim2.new(1, 0, 0, 1),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(56, 56, 56),
	})

	local content_area = library:create("Frame", {
		Parent = box_inner,
		Position = UDim2.new(0, 0, 0, 19),
		Size = UDim2.new(1, 0, 0, 10),
		BorderSizePixel = 0,
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
	})

	-- Bottom line
	library:create("Frame", {
		Parent = box_outer,
		Size = UDim2.new(1, 0, 0, 1),
		Position = UDim2.new(0, 0, 1, -1),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(56, 56, 56),
	})

	function cfg:AddTab(tab_name)
		local tab = {}

		local tab_btn = library:create("TextButton", {
			Parent = tab_buttons,
			FontFace = library.font,
			TextColor3 = Color3.fromRGB(90, 90, 90),
			Text = tab_name,
			TextStrokeTransparency = 0.5,
			Size = UDim2.new(1, 0, 1, 0),
			TextSize = 12,
			BackgroundColor3 = Color3.fromRGB(22, 22, 22),
			BorderSizePixel = 0,
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

		function tab:Show()
			for _, t in next, cfg.tabs do
				t:Hide()
			end

			container.Visible = true
			tab_btn_accent.Visible = true
			tab_btn.TextColor3 = Color3.fromRGB(170, 170, 170)
			tab_btn.BackgroundColor3 = Color3.fromRGB(38, 38, 38)

			-- Force layout recalculation to prevent overlap
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
			tab_btn.TextColor3 = Color3.fromRGB(90, 90, 90)
			tab_btn.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
		end

		tab_btn.MouseButton1Click:Connect(function()
			tab:Show()
		end)

		cfg.tabs[tab_name] = tab

		setmetatable(tab, library)

		-- Show the default tab or the first tab
		local should_show = false
		if cfg.default_tab then
			-- Show if this tab matches the default
			if tab_name == cfg.default_tab then
				should_show = true
			end
		else
			-- No default specified, show the first tab
			local tab_count = 0
			for _ in next, cfg.tabs do tab_count = tab_count + 1 end
			if tab_count == 1 then
				should_show = true
			end
		end

		if should_show then
			task.defer(function()
				tab:Show()
				-- Force layout recalculation to prevent overlap
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

-- ============================================================
--  INVENTORY VIEWER  (horizontal icon strip)
-- ============================================================

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

	-- ── INVENTORY SORTER ────────────────────────────────────────────────────
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

		-- build a lookup so we only touch assigned tools
		local by_name = {}
		for _, tool in ipairs(children) do
			by_name[tool.Name] = tool
		end

		-- only remove tools that have a slot assignment
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

		-- put remaining removed tools back (unassigned ones)
		for _, tool in ipairs(removed) do
			if tool and not tool.Parent then
				tool.Parent = backpack
			end
		end

		sorting_busy = false
	end

	-- ── tooltip (shared, repositioned per icon) ─────────────────────────────
	local tooltip = library:create("TextLabel", {
		Parent               = library.gui,
		Name                 = "InvTooltip",
		FontFace             = library.font,
		TextColor3           = Color3.fromRGB(200, 200, 200),
		TextStrokeTransparency = 0.5,
		Text                 = "",
		TextSize             = 10,
		AutomaticSize        = Enum.AutomaticSize.XY,
		BackgroundTransparency = 0,
		BackgroundColor3     = Color3.fromRGB(18, 18, 18),
		BorderColor3         = Color3.fromRGB(56, 56, 56),
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

	-- ── outer strip frame (horizontal bar, NOT in main_frame so it stays) ──
	local strip_outer = library:create("Frame", {
		Parent           = library.gui,
		Name             = "InventoryStrip",
		Active           = true,
		AnchorPoint      = Vector2.new(0.5, 1),
		Position         = UDim2.new(0.5, 0, 1, -10),
		Size             = UDim2.new(0, 64, 0, 44),
		BackgroundColor3 = Color3.fromRGB(40, 40, 40),
		BorderColor3     = Color3.fromRGB(8, 8, 8),
		ClipsDescendants = true,
		ZIndex           = 4,
		Visible          = false,
	})
	library:make_draggable(strip_outer)

	-- accent bar (top 2 px)
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
		BackgroundColor3     = Color3.fromRGB(0, 0, 0),
	})

	-- glow
	local inv_glow = library:create("ImageLabel", {
		Parent               = strip_outer,
		ImageColor3          = themes.preset.accent,
		ScaleType            = Enum.ScaleType.Slice,
		ImageTransparency    = 0.9,
		BackgroundColor3     = Color3.fromRGB(255, 255, 255),
		Image                = "http://www.roblox.com/asset/?id=18245826428",
		BackgroundTransparency = 1,
		Position             = UDim2.new(0, -20, 0, -20),
		Size                 = UDim2.new(1, 40, 0, 84),
		ZIndex               = 2,
		BorderSizePixel      = 0,
		SliceCenter          = Rect.new(Vector2.new(21, 21), Vector2.new(79, 79)),
	})
	library:apply_theme(inv_glow, "accent", "ImageColor3")

	-- inline border layer
	local strip_inline = library:create("Frame", {
		Parent           = strip_outer,
		Position         = UDim2.new(0, 2, 0, 2),
		Size             = UDim2.new(1, -4, 1, -4),
		BorderSizePixel  = 0,
		ClipsDescendants = true,
		BackgroundColor3 = Color3.fromRGB(26, 26, 26),
	})

	-- main content area
	local strip_main = library:create("Frame", {
		Parent           = strip_inline,
		Position         = UDim2.new(0, 1, 0, 1),
		Size             = UDim2.new(1, -2, 1, -2),
		BorderSizePixel  = 0,
		ClipsDescendants = true,
		BackgroundColor3 = Color3.fromRGB(22, 22, 22),
	})

	-- horizontal scrolling frame for icons
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

	-- ── build / rebuild icon strip ──────────────────────────────────────────
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

			-- icon background
			local icon_bg = library:create("Frame", {
				Parent           = slot,
				Size             = UDim2.new(1, 0, 1, 0),
				BackgroundColor3 = Color3.fromRGB(19, 19, 19),
				BorderSizePixel  = 0,
			})

			library:create("UIStroke", {
				Parent       = icon_bg,
				Color        = Color3.fromRGB(56, 56, 56),
				Thickness    = 1,
				LineJoinMode = Enum.LineJoinMode.Miter,
			})

			-- the icon image
			local icon_img = library:create("ImageLabel", {
				Parent               = icon_bg,
				Position             = UDim2.new(0, 2, 0, 2),
				Size                 = UDim2.new(1, -4, 1, -4),
				BackgroundTransparency = 1,
				BorderSizePixel      = 0,
				Image                = item.image,
				ScaleType            = Enum.ScaleType.Fit,
				BackgroundColor3     = Color3.fromRGB(255, 255, 255),
			})

		-- invisible hover button overlay
		local hover_btn = library:create("TextButton", {
			Parent               = slot,
			Size                 = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			Text                 = "",
			ZIndex               = 10,
		})

		-- sort save button (tiny button in top-right of each icon)
		local tool_name = item.name:gsub(" %(equipped%)$", "")
		local assigned_slot = slot_assignments[tool_name]
		local save_btn = library:create("TextButton", {
			Parent               = slot,
			Size                 = UDim2.new(0, 12, 0, 12),
			Position             = UDim2.new(1, -13, 0, 1),
			BackgroundColor3     = Color3.fromRGB(15, 15, 15),
			BorderSizePixel      = 0,
			Text                 = assigned_slot and tostring(assigned_slot % 10) or "S",
			TextColor3           = assigned_slot and themes.preset.accent or Color3.fromRGB(255, 255, 255),
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

	-- ── auto-refresh ────────────────────────────────────────────────────────
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
	players.LocalPlayer.CharacterAdded:Connect(function()
		local new_bp = players.LocalPlayer:WaitForChild("Backpack", 5)
		watch_backpack(new_bp)
	end)

	-- ── public API ──────────────────────────────────────────────────────────
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

	inv.frame = strip_outer
	inv.sort = sortInventory
	inv.sorting = Sorting
	inv.clear_sort = clear_all_assignments
	inv.rebuild_assignments = rebuild_assignments

	build_icons()

	return inv
end

library.create_inventory_viewer = create_inventory_viewer

-- ============================================================
--  USAGE EXAMPLE
--  Call create_inventory_viewer() after library:window() returns.
--  Then wire inv.toggle() to a toggle or keybind in your menu.
-- ============================================================

--[[
	-- in your main script, after  local win = library:window({ ... })
	local inventory_viewer = create_inventory_viewer()

	-- show / hide from a toggle element:
	local inv_tab = win:tab({ name = "misc" })
	local inv_sec = inv_tab:section({ name = "overlays", side = "left" })
	inv_sec:toggle({
		name     = "Inventory Viewer",
		flag     = "inv_viewer",
		default  = false,
		callback = function(bool)
			inventory_viewer.set_visible(bool)
		end,
	})

	-- or wire it to a keybind:
	inv_sec:keybind({
		name    = "Toggle Inventory",
		flag    = "inv_viewer_key",
		default = Enum.KeyCode.I,
		mode    = "toggle",
		callback = function(active)
			inventory_viewer.set_visible(active)
		end,
	})
--]]

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
		BorderColor3 = Color3.fromRGB(19, 19, 19),
		Size = UDim2.new(1, -26, 0, 16),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(8, 8, 8),
	})

	local textbox = library:create("TextBox", {
		Parent = textbox_inline,
		FontFace = library.font,
		TextColor3 = Color3.fromRGB(170, 170, 170),
		Text = "",
		TextStrokeTransparency = 0.5,
		Position = UDim2.new(0, 2, 0, 2),
		Size = UDim2.new(1, -4, 1, -4),
		ClearTextOnFocus = cfg.clear_on_focus,
		PlaceholderColor3 = Color3.fromRGB(90, 90, 90),
		CursorPosition = -1,
		PlaceholderText = cfg.placeholder,
		TextSize = 12,
		BackgroundColor3 = Color3.fromRGB(38, 38, 38),
	})

	-- FIXED: was textbox.text (lowercase)
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

	-- controller nav: register this textbox
	table.insert(library.nav_elements, { cfg = cfg, type = "textbox", root = textbox_inline, textbox = textbox })

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
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
	})

	local panel_holder = library:create("Frame", {
		Parent = panel_bg,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Position = UDim2.new(0.5, 0, 0.5, 0),
		ZIndex = 21,
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundColor3 = Color3.fromRGB(40, 40, 40),
	})

	local p_inline = library:create("Frame", { Parent=panel_holder, BorderColor3=Color3.fromRGB(8,8,8), AutomaticSize=Enum.AutomaticSize.XY, BackgroundColor3=Color3.fromRGB(56,56,56) })
	local p_main   = library:create("Frame", { Parent=p_inline, Position=UDim2.new(0,4,0,4), BorderColor3=Color3.fromRGB(26,26,26), Size=UDim2.new(1,-8,1,-8), BorderSizePixel=2, BackgroundColor3=Color3.fromRGB(26,26,26) })
	library:create("UIStroke", { Parent=p_main, Color=Color3.fromRGB(57,57,57), LineJoinMode=Enum.LineJoinMode.Miter })

	local p_tabs = library:create("Frame", { Parent=p_main, Position=UDim2.new(0,8,0,8), BorderColor3=Color3.fromRGB(8,8,8), Size=UDim2.new(1,-16,1,-16), BorderSizePixel=2, BackgroundColor3=Color3.fromRGB(22,22,22) })
	library:create("UIStroke", { Parent=p_tabs, Color=Color3.fromRGB(57,57,57), LineJoinMode=Enum.LineJoinMode.Miter })

	library:create("UIPadding", { Parent=p_tabs, PaddingTop=UDim.new(0,5), PaddingBottom=UDim.new(0,22), PaddingRight=UDim.new(0,20), PaddingLeft=UDim.new(0,20) })

	local p_title = library:create("TextLabel", {
		Parent = p_tabs,
		FontFace = library.font,
		LineHeight = 1.2,
		TextStrokeTransparency = 0.5,
		AnchorPoint = Vector2.new(0.5, 0),
		TextSize = 12,
		Size = UDim2.new(0, 0, 0, 11),
		TextColor3 = Color3.fromRGB(170, 170, 170),
		Text = cfg.name,
		BackgroundTransparency = 1,
		Position = UDim2.new(0.5, 0, 0, 8),
		BorderSizePixel = 0,
		TextYAlignment = Enum.TextYAlignment.Top,
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	})
	library:create("UIPadding", { Parent=p_title, PaddingTop=UDim.new(0,6) })

	library:create("UIListLayout", { Parent=p_tabs, SortOrder=Enum.SortOrder.LayoutOrder, HorizontalAlignment=Enum.HorizontalAlignment.Center, Padding=UDim.new(0,4) })

	local p_frame = library:create("Frame", { Parent=p_tabs, BorderSizePixel=0, AutomaticSize=Enum.AutomaticSize.Y, BackgroundColor3=Color3.fromRGB(255,255,255) })
	library:create("UIListLayout", { Parent=p_frame, SortOrder=Enum.SortOrder.LayoutOrder, HorizontalAlignment=Enum.HorizontalAlignment.Center, Padding=UDim.new(0,3) })

	for _, v in next, cfg.options do
		local bi = library:create("Frame", { Parent=p_frame, Position=UDim2.new(0,0,0,4), BorderColor3=Color3.fromRGB(19,19,19), Size=UDim2.new(0,130,0,16), BorderSizePixel=0, BackgroundColor3=Color3.fromRGB(8,8,8) })
		local b  = library:create("TextButton", { Parent=bi, FontFace=library.font, TextColor3=Color3.fromRGB(170,170,170), Text=v, TextStrokeTransparency=0.5, Position=UDim2.new(0,2,0,2), Size=UDim2.new(1,-4,1,-4), TextSize=12, BackgroundColor3=Color3.fromRGB(38,38,38) })
		b.MouseButton1Click:Connect(function()
			cfg.callback(v)
			panel_bg:Destroy()
			library.__panel = false
		end)
	end
end

-- ============================================================
-- KEYSTROKE OVERLAY + FPS/PING OVERLAY
-- Both are built inside library:window() and exposed as:
--   cfg.toggle_keystroke(bool)
--   cfg.toggle_fps_ping(bool)
-- Dragging is handled by library:make_draggable() — no manual
-- hit-testing or external input handlers needed.
-- Called from main.lua exactly like toggle_watermark / toggle_playerlist.
-- ============================================================

-- These are set inside library:window() below (see cfg.toggle_keystroke /
-- cfg.toggle_fps_ping).  The getgenv globals below are thin shims kept so
-- existing main.lua call-sites (set_keylogger_state, set_fps_ping_enabled,
-- init_overlay_input, destroy_*) continue to work without changes.

-- Populated by library:window(); forward-declared here.

-- ── shared colour helpers ───────────────────────────────────────────────────
local function fps_color(v)
	if v >= 55 then return Color3.fromRGB(100, 220, 140) end
	if v >= 30 then return Color3.fromRGB(220, 190, 80)  end
	return Color3.fromRGB(220, 80, 80)
end
local function ping_color(v)
	if v <= 80  then return Color3.fromRGB(100, 220, 140) end
	if v <= 150 then return Color3.fromRGB(220, 190, 80)  end
	return Color3.fromRGB(220, 80, 80)
end

-- ── getgenv shims (called by main.lua) ─────────────────────────────────────

-- KeyLogger key-state updater (called by init_overlay_input in main.lua)
getgenv().set_keylogger_state = function(keyName, active)
	local KL = _KL_REF
	if not KL or not KL.initialized then return end
	KL.keys[keyName] = active or nil
	local C_KEY_OFF_B = Color3.fromRGB(38, 38, 38)
	local f = KL.frames and KL.frames[keyName]
	if not f then return end
	if active then
		f.inner.BackgroundColor3 = themes.preset.accent
		f.lbl.TextColor3         = Color3.fromRGB(22, 22, 22)
	else
		f.inner.BackgroundColor3 = C_KEY_OFF_B
		f.lbl.TextColor3         = Color3.fromRGB(170, 170, 170)
	end
end

getgenv().set_keylogger_visibility = function(bool)
	local KL = _KL_REF
	if not KL then return end
	KL.visible = bool
	if KL.holder then KL.holder.Visible = bool end
end

getgenv().set_keylogger_slider_visibility = function(_bool)
	-- no slider — kept for call-site compatibility
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

-- init_overlay_input: only handles WASD/M1/M2 key-state for the keystroke
-- display.  Drag is now 100% handled by library:make_draggable() so no
-- manual hit-testing or position math is needed here.
getgenv().init_overlay_input = function(uis_service, _getMousePos_fn, _Camera)
	local KL = _KL_REF

	uis_service.InputBegan:Connect(function(input, _gp)
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

	uis_service.InputEnded:Connect(function(input)
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

-- ── unified heartbeat (FPS/Ping + KL accent + position saves) ──────────────
do
	local _fps_elapsed  = 0
	local _fps_frames   = 0
	local _ping_elapsed = 0
	local _stats_ok, _stats_service = pcall(function() return game:GetService("Stats") end)
	if not _stats_ok then _stats_service = nil end
	local _pos_elapsed = 0

	run_service.Heartbeat:Connect(function(dt)
		local FP = _FP_REF
		local KL = _KL_REF

		-- FPS/Ping update (every 0.5s)
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

				if FP.fps_lbl  then FP.fps_lbl.Text  = "fps: "  .. FP.fps;  FP.fps_lbl.TextColor3  = fps_color(FP.fps)  end
				if FP.ping_lbl then FP.ping_lbl.Text = "ping: " .. FP.ping; FP.ping_lbl.TextColor3 = ping_color(FP.ping) end
				if FP.accent_bar then FP.accent_bar.BackgroundColor3 = themes.preset.accent end
			end

			-- Position save (every 0.5s instead of every frame)
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

		-- Keystroke overlay (only when visible)
		if KL and KL.initialized and KL.holder then
			if KL.holder.Visible then
				if KL.accent_bar then KL.accent_bar.BackgroundColor3 = themes.preset.accent end
			end
			-- Position save (shared timer)
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

-- ══════════════════════════════════════════════════════════════════════════════
-- CONTROLLER D-PAD NAVIGATION ENGINE
-- Controls:
--   D-Pad Up / Down    → move focus between elements in the current tab
--   D-Pad Left / Right → switch tabs  (or adjust a focused slider's value,
--                        or scroll a focused open dropdown's options)
--   Button A           → activate (toggle flip, open/confirm dropdown,
--                        click button, focus textbox, enter slider-adjust mode)
--   Button B           → back (exit slider-adjust, close dropdown, clear focus)
-- ══════════════════════════════════════════════════════════════════════════════
do
	-- ── constants ─────────────────────────────────────────────────────────────
	local HOLD_INITIAL = 0.38   -- seconds before key-repeat kicks in
	local HOLD_REPEAT  = 0.12   -- seconds between repeat fires while held

	-- ── nav state ─────────────────────────────────────────────────────────────
	local nav = {
		idx           = 0,     -- focused element index in nav.list (1-based)
		tab_idx       = 0,     -- index in library.nav_tabs (synced lazily)
		list          = {},    -- visible elements for the current tab
		slider_active = false, -- true while L/R adjusts a slider's value
		dd_opt        = 0,     -- highlighted option index when a dropdown is open
		highlight     = nil,   -- the accent overlay Frame (created lazily)
		held          = {},    -- [KeyCode] = bool
		hold_start    = {},    -- [KeyCode] = clock()
		last_repeat   = 0,     -- clock() of last repeated fire
		cp_active     = false, -- true while a colorpicker is open and being controlled
	}

	-- ── highlight frame ────────────────────────────────────────────────────────

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
		if nav.highlight then nav.highlight.Visible = false end
	end

	local function show_hl(e, bright)
		ensure_highlight()
		if not nav.highlight then return end
		local root = e.root
		if not root or not root.Parent then hide_hl(); return end
		local ap  = root.AbsolutePosition
		local as  = root.AbsoluteSize
		local ext = e.extend_left or 0
		-- The canvas is shifted up by gui_offset (Y=-gui_offset) so AbsolutePosition
		-- of elements is in full-screen coords (Y=0 at top of screen, above the topbar).
		-- The highlight lives in ScreenGui space (Y=0 at top of game area, below topbar),
		-- so we must ADD gui_offset to convert element AbsolutePosition to ScreenGui space.
		nav.highlight.Size                   = UDim2.fromOffset(as.X + 8 + ext, as.Y + 6)
		nav.highlight.Position               = UDim2.fromOffset(ap.X - 4 - ext, ap.Y + gui_offset - 60)
		nav.highlight.BackgroundTransparency = bright and 0.42 or 0.72
		nav.highlight.Visible                = true
	end

	local function refresh_hl()
		if nav.idx <= 0 or nav.idx > #nav.list then hide_hl(); return end
		local e = nav.list[nav.idx]
		if e then show_hl(e, nav.slider_active) end
	end

	-- keep highlight pinned every frame (handles scroll / resize)
	local _nav_hl_elapsed = 0
	run_service.Heartbeat:Connect(function(dt)
		if not library.panel_open then return end
		_nav_hl_elapsed = _nav_hl_elapsed + dt
		if _nav_hl_elapsed < (1/30) then return end
		_nav_hl_elapsed = 0
		if nav.highlight and nav.highlight.Visible then refresh_hl() end
	end)

	-- ── element visibility ─────────────────────────────────────────────────────

	local function is_elem_visible(inst)
		if not inst or not inst.Parent then return false end
		if inst.AbsoluteSize.Y <= 0 then return false end
		local p = inst
		while p and p ~= game do
			-- Stop before we reach CoreGui or any non-GuiObject ancestor
			-- that doesn't have a Visible property (e.g. ScreenGui in CoreGui)
			local ok, visible = pcall(function() return p.Visible end)
			if not ok then break end
			if not visible then return false end
			p = p.Parent
		end
		return true
	end

	-- ── build visible element list ─────────────────────────────────────────────

	local function build_list()
		local result = {}
		for _, e in ipairs(library.nav_elements) do
			if is_elem_visible(e.root) then
				table.insert(result, e)
			end
		end
		-- sort top-to-bottom, then left-to-right within the same row
		table.sort(result, function(a, b)
			local ay = a.root.AbsolutePosition.Y
			local by = b.root.AbsolutePosition.Y
			if math.abs(ay - by) > 4 then return ay < by end
			return a.root.AbsolutePosition.X < b.root.AbsolutePosition.X
		end)
		nav.list = result
	end

	-- ── focus helpers ──────────────────────────────────────────────────────────

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

	-- ── tab switching ──────────────────────────────────────────────────────────

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

	-- ── dropdown option highlighting ───────────────────────────────────────────

	local function dd_set_option_colors(e)
		for i, op in ipairs(e.cfg.option_instances) do
			if i == nav.dd_opt then
				op.BackgroundTransparency = 0.55
				op.BackgroundColor3       = themes.preset.accent
				op.TextColor3             = themes.preset.text
			else
				op.BackgroundTransparency = 1
				op.BackgroundColor3       = Color3.fromRGB(65, 65, 65)
				op.TextColor3             = Color3.fromRGB(170, 170, 170)
			end
		end
	end

	local function dd_reset_option_colors(e)
		for _, op in ipairs(e.cfg.option_instances) do
			op.BackgroundTransparency = 1
			op.BackgroundColor3       = Color3.fromRGB(65, 65, 65)
			op.TextColor3             = Color3.fromRGB(170, 170, 170)
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

	-- ── activate the focused element ───────────────────────────────────────────

	local function activate()
		local e = focused()
		if not e then return end

		if e.type == "toggle" then
			e.cfg.enabled = not e.cfg.enabled
			e.cfg.set(e.cfg.enabled)

		elseif e.type == "slider" then
			-- toggle slider-adjust mode; highlight glows brighter while active
			nav.slider_active = not nav.slider_active
			refresh_hl()

		elseif e.type == "button" then
			e.cfg.callback()

		elseif e.type == "dropdown" then
			if not e.cfg.open then
				-- close any other open element first
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
				-- confirm the highlighted option
				local opts = e.cfg.items
				if nav.dd_opt >= 1 and nav.dd_opt <= #opts then
					if e.cfg.multi then
						-- for multi-select: toggle the option, keep dropdown open
						local sel_idx = table.find(e.cfg.multi_items, opts[nav.dd_opt])
						if sel_idx then
							table.remove(e.cfg.multi_items, sel_idx)
						else
							table.insert(e.cfg.multi_items, opts[nav.dd_opt])
						end
						e.cfg.set(e.cfg.multi_items)
						dd_set_option_colors(e)
					else
						-- for single-select: pick and close
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
			-- A button toggles the picker panel open/closed
			e.cfg.open = not e.cfg.open
			e.cfg.set_visible(e.cfg.open)

		elseif e.type == "keybind" then
			-- A button starts rebinding. We defer the listener setup by one frame so the
			-- ButtonA InputBegan that triggered activate() has fully finished before we
			-- start listening -- otherwise ButtonA would immediately capture itself.
			local kb_btn = e.cfg._keybind_button
			if kb_btn then
				kb_btn.Text = "..."
				if e.cfg.binding then
					e.cfg.binding:Disconnect()
					e.cfg.binding = nil
				end
				task.delay(0.05, function()
					if e.cfg.binding then return end  -- already cancelled
					-- Raw Connect (not library:connection) so it isn't auto-disconnected by
					-- the library cleanup cycle. No game_event guard: panel-open gamepad events
					-- arrive with game_event=true which would silently swallow every button press.
					local conn
					conn = uis.InputBegan:Connect(function(input)
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

	-- ── back / cancel ──────────────────────────────────────────────────────────

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
			-- fully clear focus
			nav.idx           = 0
			nav.slider_active = false
			hide_hl()
		end
	end

	-- ── main action dispatcher ─────────────────────────────────────────────────

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
				-- colorpicker open: DPad L/R do nothing (thumbstick controls it)
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
				-- colorpicker open: DPad L/R do nothing (thumbstick controls it)
			elseif not nav.slider_active then
				switch_tab(1)
			end

		elseif kc == Enum.KeyCode.ButtonA then
			activate()

		elseif kc == Enum.KeyCode.ButtonB then
			go_back()
		end
	end

	-- ── input connections ──────────────────────────────────────────────────────

	local NAV_KEYS = {
		[Enum.KeyCode.DPadUp]    = true,
		[Enum.KeyCode.DPadDown]  = true,
		[Enum.KeyCode.DPadLeft]  = true,
		[Enum.KeyCode.DPadRight] = true,
		[Enum.KeyCode.ButtonA]   = true,
		[Enum.KeyCode.ButtonB]   = true,
	}

	-- Keyboard interrupt: any keyboard key press dismisses the controller highlight
	uis.InputBegan:Connect(function(input, gpe)
		if not library.panel_open then return end
		local itype = input.UserInputType
		local kc    = input.KeyCode

		-- Keyboard input kills the controller highlight entirely
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

	uis.InputEnded:Connect(function(input)
		local kc = input.KeyCode
		if NAV_KEYS[kc] then
			nav.held[kc]       = false
			nav.hold_start[kc] = nil
		end
	end)

	-- held-key repeat (fires every HOLD_REPEAT seconds after HOLD_INITIAL delay)
	run_service.Heartbeat:Connect(function()
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

	-- controller thumbstick colorpicker control
	run_service.Heartbeat:Connect(function(dt)
		if not library.panel_open then return end
		local e = focused()
		if not e or e.type ~= "colorpicker" or not e.cfg.open then
			nav.cp_active = false
			return
		end
		nav.cp_active = true

		-- Read thumbstick state (Gamepad1 Thumbstick1 = left stick, Thumbstick2 = right stick)
		local ok, states = pcall(function()
			return uis:GetGamepadState(Enum.UserInputType.Gamepad1)
		end)
		if not ok or not states then return end

		local lx, ly, rx = 0, 0, 0
		for _, state in ipairs(states) do
			if state.KeyCode == Enum.KeyCode.Thumbstick1 then
				lx = state.Position.X  -- left stick X: moves sat cursor horizontally
				ly = -state.Position.Y -- left stick Y: inverted, moves sat cursor vertically
			elseif state.KeyCode == Enum.KeyCode.Thumbstick2 then
				rx = state.Position.X  -- right stick X: moves hue cursor
			end
		end

		local DEAD   = 0.12  -- deadzone
		local SPEED  = 0.6   -- units per second (0-1 range)

		local cfg = e.cfg
		local h2, s2, v2 = cfg.color:ToHSV()
		local a2 = cfg.alpha
		local changed = false

		-- Left stick: move sat/value cursor
		if math.abs(lx) > DEAD or math.abs(ly) > DEAD then
			s2 = math.clamp(s2 + lx * SPEED * dt, 0, 1)
			v2 = math.clamp(v2 - ly * SPEED * dt, 0, 1)
			changed = true
		end

		-- Right stick X: move hue cursor
		if math.abs(rx) > DEAD then
			h2 = math.clamp(h2 + rx * SPEED * dt, 0, 1)
			changed = true
		end

		if changed then
			cfg.set(Color3.fromHSV(h2, s2, v2), a2)
		end
	end)

	-- clear held state if the panel closes mid-hold
	run_service.Heartbeat:Connect(function()
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

	-- expose for external access
	library._ctrl_nav = nav
end

-- ============================================================
-- WELCOME SCREEN (first launch only)
-- ============================================================

function library:show_welcome(properties)
	local VERSION = properties.version or "1.0.0"
	local TITLE = properties.name or "Erme"
	local CHANGELOG_URL = properties.changelog_url or "https://pastebin.com/raw/hsKxNWVN"

	local welcomed_path = library.directory .. "/.welcomed"
	if isfile(welcomed_path) then return end

	-- Dedicated ScreenGui with IgnoreGuiInset so the overlay covers the full screen
	local welcome_gui = library:create("ScreenGui", {
		Name = "WelcomeScreenGui",
		IgnoreGuiInset = true,
		DisplayOrder = 100,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = coregui,
	})

	-- Full-screen overlay
	local overlay = library:create("Frame", {
		Parent = welcome_gui,
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = themes.preset.accent,
		BackgroundTransparency = 0.75,
		BorderSizePixel = 0,
		ZIndex = 100,
	})
	library:apply_theme(overlay, "accent", "BackgroundColor3")
	library:register_theme_element(overlay, "accent", "BackgroundColor3")

	local panel = library:create("Frame", {
		Parent = overlay,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, 420, 0, 340),
		BackgroundColor3 = Color3.fromRGB(22, 22, 22),
		BorderColor3 = Color3.fromRGB(8, 8, 8),
		ZIndex = 101,
	})

	-- Accent bar
	local accent_bar = library:create("Frame", {
		Parent = panel,
		Size = UDim2.new(1, 0, 0, 2),
		BorderSizePixel = 0,
		BackgroundColor3 = themes.preset.accent,
		ZIndex = 102,
	})
	library:apply_theme(accent_bar, "accent", "BackgroundColor3")

	-- Title
	library:create("TextLabel", {
		Parent = panel,
		FontFace = library.font,
		TextColor3 = Color3.fromRGB(200, 200, 200),
		Text = TITLE,
		TextStrokeTransparency = 0.5,
		Size = UDim2.new(1, 0, 0, 24),
		Position = UDim2.new(0, 0, 0, 10),
		BackgroundTransparency = 1,
		TextSize = 14,
		ZIndex = 102,
		BorderSizePixel = 0,
	})

	-- Version
	library:create("TextLabel", {
		Parent = panel,
		FontFace = library.font,
		TextColor3 = Color3.fromRGB(120, 120, 120),
		Text = "v" .. VERSION,
		TextStrokeTransparency = 0.5,
		Size = UDim2.new(1, 0, 0, 14),
		Position = UDim2.new(0, 0, 0, 32),
		BackgroundTransparency = 1,
		TextSize = 11,
		ZIndex = 102,
		BorderSizePixel = 0,
	})

	-- Changelog label
	library:create("TextLabel", {
		Parent = panel,
		FontFace = library.font,
		TextColor3 = Color3.fromRGB(170, 170, 170),
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

	-- Changelog box
	local changelog_outer = library:create("Frame", {
		Parent = panel,
		Position = UDim2.new(0, 16, 0, 72),
		Size = UDim2.new(1, -32, 0, 200),
		BackgroundColor3 = Color3.fromRGB(8, 8, 8),
		BorderColor3 = Color3.fromRGB(19, 19, 19),
		BorderSizePixel = 0,
		ZIndex = 102,
	})

	local changelog_inner = library:create("Frame", {
		Parent = changelog_outer,
		Position = UDim2.new(0, 2, 0, 2),
		Size = UDim2.new(1, -4, 1, -4),
		BackgroundColor3 = Color3.fromRGB(15, 15, 15),
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
		TextColor3 = Color3.fromRGB(150, 150, 150),
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

	-- Continue button
	local btn_outer = library:create("Frame", {
		Parent = panel,
		Position = UDim2.new(0, 16, 1, -42),
		Size = UDim2.new(1, -32, 0, 24),
		BackgroundColor3 = Color3.fromRGB(8, 8, 8),
		BorderColor3 = Color3.fromRGB(19, 19, 19),
		BorderSizePixel = 0,
		ZIndex = 102,
	})

	local continue_btn = library:create("TextButton", {
		Parent = btn_outer,
		FontFace = library.font,
		TextColor3 = Color3.fromRGB(170, 170, 170),
		Text = "continue",
		TextStrokeTransparency = 0.5,
		Position = UDim2.new(0, 2, 0, 2),
		Size = UDim2.new(1, -4, 1, -4),
		TextSize = 12,
		BackgroundColor3 = Color3.fromRGB(38, 38, 38),
		BorderColor3 = Color3.fromRGB(56, 56, 56),
		ZIndex = 103,
	})

	continue_btn.MouseButton1Click:Connect(function()
		writefile(welcomed_path, "1")
		welcome_gui:Destroy()
		if properties.on_continue then
			properties.on_continue()
		end
	end)

	-- Fetch changelog
	task.spawn(function()
		local ok, result = pcall(function()
			return game:HttpGet(CHANGELOG_URL)
		end)
		if ok and result then
			changelog_text.Text = result
		else
			changelog_text.Text = "Failed to load changelog."
		end
	end)
end

return library
