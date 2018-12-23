local function print() end

-- Location Indexes
local UseDark = script.Parent.UseDark
local IsPaused = script.Parent.IsPaused
local SelectedObject = script.Parent.SelectedObject
local Base = script.BaseFrame
local Background = script.Parent.Background

-- Modules
local InstanceIconPositions = require(script.IconPositions)
local VerticallyScalingListFrame = require(script.VerticallyScalingListFrame)
local Themes = require(script.Themes)
local CurrentTheme

-- Variables
local AccessibleServices = {
	"Workspace", "Players", "Lighting", "ReplicatedStorage", "StarterGui",
	"StarterPack", "StarterPlayer", "SoundService", "Chat", "LocalizationService",
}
local CreatedLines = {}
local Connections = {
	Toggle = {},
	Select = {},
	NameChanged = {},
	MouseEnter = {},
	MouseLeave = {},
	AncestryChanged = {},
	DescendantAdded = {},
	ServiceAdded = {},
	ServiceRemoving = {},
	PauseStatusChanged,
	ThemeChanged,
	RemakeGUI,
	KillConnections,
}
local ObjectStatus = setmetatable({}, {__mode="k"}) -- Whether an instance is open or closed in the explorer
local VisibleList = setmetatable({}, {__mode="k"}) -- Whether an instance is visible to the explorer (ie whether to generate a line for it)
local UpdateList = setmetatable({}, {__mode="k"}) -- Whether an instance has been updated when updates are paused

local SelectedLine
local InstanceIconSheet = "rbxassetid://2245672825"
local ExpandIcon = "rbxasset://textures/TerrainTools/button_arrow.png"
local CloseIcon = "rbxasset://textures/TerrainTools/button_arrow_down.png"

local ListContainer = VerticallyScalingListFrame.new("InstanceContainer")
local ListFrame = ListContainer:GetFrame()

ListFrame.Size = UDim2.new(1, 0, 1, -28)
ListFrame.Position = UDim2.new(0, 0, 0, 28)
ListFrame.Parent = Background

local UpdateGUI = Instance.new("BindableEvent", script)
UpdateGUI.Name = "UpdateExplorer"

Instance.new("ObjectValue", script.Parent).Name = "__EXPLORERIGNORE"

--Functions
local function OnPauseStatusChanged(Status)
	UpdateList = {}
	UpdateGUI:Fire()
end

local function OnThemeChange(UseDark)
	if UseDark then
		CurrentTheme = Themes.Dark
	else
		CurrentTheme = Themes.Light
	end
	Background.BackgroundColor3 = CurrentTheme.MainBackground
	Background.BorderColor3 = CurrentTheme.Border
	Background.Title.BackgroundColor3 = CurrentTheme.Titlebar
	Background.Title.BorderColor3 = CurrentTheme.Border
	Background.Title.TextColor3 = CurrentTheme.TitlebarText
	
	ListFrame.ScrollBarImageColor3 = CurrentTheme.ScrollBar
	ListFrame.BackgroundColor3 = CurrentTheme.ScrollBarBackground
	ListFrame.BorderColor3 = CurrentTheme.Border
	
	for _, Line in ipairs(CreatedLines) do
		Line.MainButton.BackgroundColor3 = CurrentTheme.Item
		Line.MainButton.NameLabel.TextColor3 = CurrentTheme.MainText
	end
	print("Theme updated to", UseDark)
end

local function OnToggle(Object, Level)
	local NewStatus = not ObjectStatus[Object]
	print("Toggled open status of", Object:GetFullName(), "to", NewStatus)
	ObjectStatus[Object] = NewStatus
	for _, Child in ipairs(Object:GetChildren()) do
		if not NewStatus then
			VisibleList[Child] = nil
		else
			VisibleList[Child] = true
		end
	end
	UpdateGUI:Fire()
end

local function OnSelect(Line, Object)
	SelectedObject.Value = Object
	if SelectedLine then
		SelectedLine.MainButton.BackgroundColor3 = CurrentTheme.Item
		SelectedLine.MainButton.NameLabel.TextColor3 = CurrentTheme.MainText
	end
	SelectedLine = Line
	Line.MainButton.BackgroundColor3 = CurrentTheme.Item_Selected
	Line.MainButton.NameLabel.TextColor3 = CurrentTheme.MainText_Selected
end

local function CreateLine(Object, Level)
	Level = Level or 0
	local Line = Base:Clone()
	Line.Visible = true
	Line.Position = Line.Position+UDim2.new(0, 22*Level, 0, 0)
	Line.Name = Object:GetFullName()
	Line.MainButton.ClassLabel.Image = InstanceIconSheet
	Line.MainButton.ClassLabel.ImageRectOffset = InstanceIconPositions[Object.ClassName] or Vector2.new(0, 0)
	Line.MainButton.NameLabel.Text = Object.Name
	if Connections.NameChanged[Object] then
		Connections.NameChanged[Object]:Disconnect()
	end
	Connections.NameChanged[Object] = Object:GetPropertyChangedSignal("Name"):Connect(function()
		if IsPaused.Value then return end
		Line.MainButton.NameLabel.Text = Object.Name
	end)
	if Connections.MouseEnter[Object] then
		Connections.MouseLeave[Object]:Disconnect()
	end
	Connections.MouseEnter[Object] = Line.MainButton.MouseEnter:Connect(function()
		if SelectedLine == Line then return end
		Line.MainButton.BackgroundColor3 = CurrentTheme.Item_Hover
	end)
	if Connections.MouseLeave[Object] then
		Connections.MouseLeave[Object]:Disconnect()
	end
	Connections.MouseLeave[Object] = Line.MainButton.MouseLeave:Connect(function()
		if SelectedLine == Line then return end
		Line.MainButton.BackgroundColor3 = CurrentTheme.Item
	end)
	if Connections.Select[Object] then
		Connections.Select[Object]:Disconnect()
	end
	Connections.Select[Object] = Line.MainButton.MouseButton1Down:Connect(function()
		OnSelect(Line, Object)
	end)
	if Connections.Toggle[Object] then
		Connections.Toggle[Object]:Disconnect()
	end
	Connections.Toggle[Object] = Line.ToggleButton.MouseButton1Down:Connect(function()
		OnToggle(Object, Level)
	end)
	Line.ToggleButton.Visible = #Object:GetChildren() ~= 0
	if ObjectStatus[Object] then
		Line.ToggleButton.ToggleLabel.Image = CloseIcon
	else
		Line.ToggleButton.ToggleLabel.Image = ExpandIcon
	end
	Line.MainButton.BackgroundColor3 = CurrentTheme.Item
	Line.MainButton.NameLabel.TextColor3 = CurrentTheme.MainText
	if SelectedObject.Value == Object then
		Line.MainButton.BackgroundColor3 = CurrentTheme.Item_Selected
		Line.MainButton.NameLabel.TextColor3 = CurrentTheme.MainText_Selected
		SelectedLine = Line
	end
	table.insert(CreatedLines, Line)
	print("(LEVEL", tostring(Level)..")", "CreateLine for", Object:GetFullName(), "finished")
	return Line
end

local function GetAncestors(Object)
	local Original = Object
	local Ancestors = {}
	repeat
		table.insert(Ancestors, Object)
		Object = Object.Parent
	until Object == game
	table.remove(Ancestors, 1)
	print("Got", #Ancestors, "ancestors for", Original:GetFullName())
	return Ancestors
end

local function SetUpOpenStructure()
	print("Starting ObjectStatus setup")
	local function AncestryChanged(Object, NewParent)
		if NewParent ~= nil then
			ObjectStatus[Object] = false
		else
			ObjectStatus[Object] = nil
		end
	end
	local function DescendantAdded(Object)
		ObjectStatus[Object] = false
		if Connections.AncestryChanged[Object] then
			Connections.AncestryChanged[Object]:Disconnect()
		end
		Connections.AncestryChanged[Object] = Object.AncestryChanged:Connect(AncestryChanged)
	end
	for _, Service in ipairs(AccessibleServices) do
		Service = game:GetService(Service)
		VisibleList[Service] = true
		ObjectStatus[Service] = false
		if Connections.DescendantAdded[Service] then
			Connections.DescendantAdded[Service]:Disconnect()
		end
		Connections.DescendantAdded[Service] = Service.DescendantAdded:Connect(DescendantAdded)
		for _, Descendant in ipairs(Service:GetDescendants()) do
			ObjectStatus[Descendant] = false
			if Connections.AncestryChanged[Descendant] then
				Connections.AncestryChanged[Descendant]:Disconnect()
			end
			Connections.AncestryChanged[Descendant] = Descendant.AncestryChanged:Connect(AncestryChanged)
		end
	end
	print("ObjectStatus setup and hooked")
end

local function GenerateGUI()
	print("GUI started generating")
	local STARTTIME = tick()
	
	ListContainer:Wipe()
	ListContainer:AddBottomPadding()
	CreatedLines = {}
	
	local function RecursivelyPopulateChildren(Object)
		if not Object:FindFirstChild("__EXPLORERIGNORE") then
			if VisibleList[Object] then
				CreateLine(Object, #GetAncestors(Object))
			end
			if ObjectStatus[Object] then
				for _, Child in ipairs(Object:GetChildren()) do
					RecursivelyPopulateChildren(Child)
				end
			end
		end
	end
	
	for _, Service in ipairs(AccessibleServices) do
		Service = game:GetService(Service)
		RecursivelyPopulateChildren(Service)
	end
	
	for _, Line in ipairs(CreatedLines) do
		ListContainer:AddChild(Line)
		Line.Parent = ListFrame
	end

	print("GUI finished generating. Took: "..tostring(tick()-STARTTIME)..")")
end

local function UpdateFunction()
	GenerateGUI()
end

-- Connections
Connections.ThemeChanged = UseDark.Changed:Connect(OnThemeChange)
Connections.PauseStatusChanged = IsPaused.Changed:Connect(OnPauseStatusChanged)

Connections.RemakeGUI = UpdateGUI.Event:Connect(UpdateFunction)

for _, Name in ipairs(AccessibleServices) do
	local Service = game:GetService(Name)
	table.insert(Connections.ServiceAdded, Service.DescendantAdded:Connect(function(Descendant)
		if not ObjectStatus[Descendant.Parent] then return end
		if Descendant:IsDescendantOf(script.Parent) then return end
		VisibleList[Descendant] = true
		if IsPaused.Value then return end
		UpdateGUI.Event:Fire()
	end))
end

for _, Name in ipairs(AccessibleServices) do
	local Service = game:GetService(Name)
	table.insert(Connections.ServiceRemoving, Service.DescendantRemoving:Connect(function(Descendant)
		if not ObjectStatus[Descendant.Parent] then return end
		if Descendant:IsDescendantOf(script.Parent) then return end
		VisibleList[Descendant] = nil
		if IsPaused.Value then return end
		UpdateGUI.Event:Fire()
	end))
end

if script.Parent.ResetOnSpawn then
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
end

-- Initialization
OnThemeChange(UseDark.Value)
SetUpOpenStructure()
GenerateGUI()