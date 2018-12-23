----------------------------------------
--
-- VerticallyScalingListFrame
--
-- Creates a frame that organizes children into a list layout.
-- Will scale dynamically as children grow.
-- Modified from ROBLOX's to use a ScrollingFrame instead to support horizontal shifts
--
----------------------------------------
VerticallyScalingListFrameClass = {}
VerticallyScalingListFrameClass.__index = VerticallyScalingListFrameClass

local kBottomPadding = 10

local function SortByLayout(Item1, Item2)
	return Item1.LayoutOrder < Item2.LayoutOrder
end

function VerticallyScalingListFrameClass.new(Name)
	local self = {}
	setmetatable(self, VerticallyScalingListFrameClass)

	self._resizeCallback = nil
	
	local Frame = Instance.new("ScrollingFrame")
	self._frame = Frame
	Frame.Name = Name
	Frame.Size = UDim2.new(1, 0, 0, 0)
	Frame.BackgroundTransparency = 1
	
	Frame.ScrollBarThickness = 17
	Frame.MidImage = "rbxassetid://1535685612"
	Frame.BottomImage = "rbxassetid://1533256504"
	Frame.TopImage = "rbxassetid://1533255544"
	
	self._childCount = 0
	self._locked = false
	
	local function ChildAdded(child)
		local Children = self._frame:GetChildren()
		table.sort(Children, SortByLayout)
		self._maxY = 1
		for i, Child in ipairs(Children) do
			if i~= 1 then
				self._maxY = self._maxY+Child.Size.Y.Offset+1
			end
			Child.Position = UDim2.new(Child.Position.X, UDim.new(0, self._maxY))
			if Child.Position.X.Offset > self._maxX then
				self._maxX = Child.Position.X.Offset
			end
		end
		local LastChild = Children[#Children]
		self._frame.CanvasSize = UDim2.new(0, self._maxX, 0, self._maxY+(LastChild.AbsoluteSize.Y*2))
		
		if self._resizeCallback then
			self._resizeCallback()
		end
	end
	
	self._frame.ChildAdded:Connect(ChildAdded)

	return self
end

function VerticallyScalingListFrameClass:AddBottomPadding()
	local frame = Instance.new("Frame")
	frame.Name = "BottomPadding"
	frame.BackgroundTransparency = 1
	frame.Size = UDim2.new(1, 0, 0, kBottomPadding)
	frame.LayoutOrder = (2^31)-1
	frame.Parent = self._frame
end

function VerticallyScalingListFrameClass:GetFrame()
	return self._frame
end

function VerticallyScalingListFrameClass:AddChild(childFrame)
	childFrame.LayoutOrder = self._childCount
	self._childCount = self._childCount + 1
	childFrame.Parent = self._frame
end

function VerticallyScalingListFrameClass:Wipe()
	self._frame:ClearAllChildren()
	self._childCount = 0
	self._maxX = 0
	self._maxY = 0
end

function VerticallyScalingListFrameClass:SetCallbackOnResize(callback)
	self._resizeCallback = callback
end

return VerticallyScalingListFrameClass