local function print() end

-- Location Indexes
local UserInputService = game:GetService("UserInputService")

local GUI = script.Parent.Parent.Parent
local Main = GUI.Main
local UseDark = GUI.UseDark
local IsPaused = GUI.IsPaused

local Background = script.Parent.Parent
local PauseButton = script.Parent.PauseButton

-- Modules
local Themes = require(Main.Themes)
local CurrentTheme;

-- Variables
local SnappingDistance = 10 -- In pixels

local Play = "rbxasset://textures/StudioToolbox/AudioPreview/light_play.png"
local Play_Hover = "rbxasset://textures/StudioToolbox/AudioPreview/light_play_hover.png"
local Pause = "rbxasset://textures/StudioToolbox/AudioPreview/light_pause.png"
local Pause_Hover = "rbxasset://textures/StudioToolbox/AudioPreview/light_pause_hover.png"

local Mouse = game:GetService("Players").LocalPlayer:GetMouse()
local Dragging = false
local Offset = Vector2.new()

local Connections = {
	ThemeChanged,
	PauseStatusChanged,
	PauseButtonClicked,
	KillConnections,
	TitleMouseDown,
}

-- Functions
local function OnThemeChange(UseDark)
	if UseDark then
		CurrentTheme = Themes.Dark
	else
		CurrentTheme = Themes.Light
	end
	PauseButton.BackgroundColor3 = CurrentTheme.Titlebar
	print("Theme updated to", UseDark)
end

local function OnPauseStatusChanged(IsPaused)
	if IsPaused then
		PauseButton.Image = Play
		PauseButton.HoverImage = Play_Hover
	else
		PauseButton.Image = Pause
		PauseButton.HoverImage = Pause_Hover
	end
	print("PauseStatus changed to", IsPaused)
end

local function OnPauseButtonClicked()
	IsPaused.Value = not IsPaused.Value
end

local function OnTitleBarClicked()
	Dragging = true
	local AbsPos = script.Parent.Parent.AbsolutePosition
	Offset = Vector2.new(AbsPos.X-Mouse.X, AbsPos.Y-Mouse.Y)
	
	repeat wait() until UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) == false
	Dragging = false
end

local clamp, UDim2_new = math.clamp, UDim2.new
local function DragBinding()
	if not Dragging then return end
	local OffX, OffY = Mouse.X+Offset.X, Mouse.Y+Offset.Y
	
	local SizeX, SizeY = Background.AbsoluteSize.X, Background.AbsoluteSize.Y
	
	local FarEdgeX, FarEdgeY = Background.Parent.AbsoluteSize.X-SizeX, Background.Parent.AbsoluteSize.Y-SizeY
	
	OffX = math.clamp(OffX, -(SizeX-SnappingDistance), (FarEdgeX+SizeX)-SnappingDistance)
	OffY = math.clamp(OffY, -(SizeY-SnappingDistance), (FarEdgeY+SizeY)-SnappingDistance)
	
	if math.abs(OffX) <= SnappingDistance then OffX = 0 end
	if math.abs(OffY) <= SnappingDistance then OffY = 0 end
	
	if OffX+SnappingDistance >= FarEdgeX and OffX-SnappingDistance <= FarEdgeX then OffX = FarEdgeX end 
	if OffY+SnappingDistance >= FarEdgeY and OffY-SnappingDistance <= FarEdgeY then OffY = FarEdgeY end 
	
	Background.Position = UDim2.new(0, OffX, 0, OffY)
end

-- Connections
Connections.ThemeChanged = UseDark.Changed:Connect(OnThemeChange)
Connections.PauseStatusChanged = IsPaused.Changed:Connect(OnPauseStatusChanged)
Connections.PauseButtonClicked = PauseButton.MouseButton1Click:Connect(OnPauseButtonClicked)

Connections.TitleMouseDown = script.Parent.MouseButton1Down:Connect(OnTitleBarClicked)

game:GetService("RunService"):BindToRenderStep("DekkonotExplorerDrag", Enum.RenderPriority.Camera.Value-1, DragBinding)

if GUI.ResetOnSpawn then
	Connections.KillConnections = game:GetService("Players").LocalPlayer.CharacterRemoving:Connect(function()
		for _, Type in pairs(Connections) do
			if type(Type) == "table" then
				for _, Connection in ipairs(Type) do
					Connection:Disconnect()
				end
			else
				Type:Disconnect()
			end
		end
	end)
	game:GetService("RunService"):UnbindFromRenderStep("DekkonotExplorerDrag")
end

-- Initialization
OnThemeChange(UseDark.Value)
OnPauseStatusChanged(IsPaused.Value)