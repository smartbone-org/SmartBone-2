local GuiService = game:GetService("GuiService")

export type ImOverlay = {
	DefaultY: number,
	TextSize: number,
	BackFrame: Frame,
	ListLayout: UIListLayout,
	DidUpdate: boolean,
	Begin: (self: ImOverlay, Text: string, BackgroundColor: Color3?, TextColor: Color3?) -> (),
	End: (self: ImOverlay) -> (),
	Text: (self: ImOverlay, Text: string, BackgroundColor: Color3?, TextColor: Color3?) -> (),
	Render: (self: ImOverlay) -> (),
	Destroy: (self: ImOverlay) -> ()
}

local Font = Font.new("rbxasset://fonts/families/PressStart2P.json")
local UseScrollingFrame = false

local ImOverlay = {}
ImOverlay.__index = ImOverlay

function ImOverlay.new(DefaultY: number?, TextSize: number?, UseInset: boolean?): ImOverlay
	DefaultY = DefaultY or 5
	TextSize = TextSize or 11
	UseInset = (UseInset == nil and true or UseInset)

	-- Magic numbers
	local InsetPosition = UDim2.fromOffset(25, 5 + GuiService:GetGuiInset().Y)
	local InsetSize = UDim2.new(1, -25, 1, -5)

	local DefaultPosition = UDim2.fromOffset(0, 0)
	local DefaultSize = UDim2.fromScale(1, 1)

	local self = setmetatable({}, ImOverlay)

	self.DefaultY = DefaultY
	self.TextSize = TextSize

	self.BackFrame = UseScrollingFrame and Instance.new("ScrollingFrame") or Instance.new("Frame")
	self.BackFrame.Position = (UseInset and InsetPosition or DefaultPosition)
	self.BackFrame.Size = (UseInset and InsetSize or DefaultSize)
	self.BackFrame.Name = "BackFrame"
	self.BackFrame.Transparency = 1

	self.ListLayout = Instance.new("UIListLayout")
	self.ListLayout.Padding = UDim.new(0, 2)
	self.ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	self.ListLayout.Parent = self.BackFrame

	self.m_Indent = 0

	self.DidUpdate = false

	-- Decide if we should re-render this frame
	self.m_State = ""
	self.m_PreviousState = ""

	self.m_RenderGroup = {}
	self.m_ItemPool = {}

	return self
end

function ImOverlay:Begin(Text: string, BackgroundColor: Color3?, TextColor: Color3?)
	if not Text or type(Text) ~= "string" then
		warn("Expected text to ImOverlay::Begin", debug.traceback())
		return
	end

	if BackgroundColor and typeof(BackgroundColor) ~= "Color3" then
		warn("BackgroundColor should be a Color3", debug.traceback())
		return
	end

	if TextColor and typeof(TextColor) ~= "Color3" then
		warn("TextColor should be a Color3", debug.traceback())
		return
	end

	self:Text(Text, BackgroundColor, TextColor)
	self.m_Indent += 1
end

function ImOverlay:End()
	if self.m_Indent - 1 < 0 then
		error("Too many callbacks to ImOverlay::End")
		return
	end

	self.m_Indent -= 1
end

function ImOverlay:Text(Text: string, BackgroundColor: Color3?, TextColor: Color3?)
	if not Text or type(Text) ~= "string" then
		warn("Expected text to ImOverlay::Text", debug.traceback())
		return
	end

	if BackgroundColor and typeof(BackgroundColor) ~= "Color3" then
		warn("BackgroundColor should be a Color3", debug.traceback())
		return
	end

	if TextColor and typeof(TextColor) ~= "Color3" then
		warn("TextColor should be a Color3", debug.traceback())
		return
	end

	BackgroundColor = BackgroundColor or Color3.new()
	TextColor = TextColor or Color3.new(1, 1, 1)

	table.insert(self.m_RenderGroup, {
		Text = Text,
		TextColor = TextColor,
		BackgroundColor = BackgroundColor,
		Indent = self.m_Indent,
	})

	self.m_State ..= `{Text}|{TextColor}|{BackgroundColor}|{self.m_Indent}`
end

function ImOverlay:m_Pool()

	
for _, Obj in self.BackFrame:QueryDescendants("> :not(UIListLayout, [Visible = false])") do
		-- Quicker to change visibility than to re-parent
		Obj.Visible = false
		table.insert(self.m_ItemPool, Obj)
	end
end

function ImOverlay:m_Cleanup()
	
self.m_State = ""
	self.m_Indent = 0
	self.m_RenderGroup = {}

end

function ImOverlay:m_CreateLabel(Text: string, TextColor: Color3, BackgroundColor: Color3, Indent: number): Frame
	
local background = Instance.new("Frame")
	background.Name = "Background"
	background.AutomaticSize = Enum.AutomaticSize.XY
	background.BackgroundColor3 = BackgroundColor
	background.BackgroundTransparency = 0.4
	background.BorderSizePixel = 0

	local taskText = Instance.new("TextLabel")
	taskText.Name = "TaskText"
	taskText.FontFace = Font
	taskText.Text = Text
	taskText.TextColor3 = TextColor
	taskText.TextSize = self.TextSize
	taskText.TextXAlignment = Enum.TextXAlignment.Left
	taskText.AutomaticSize = Enum.AutomaticSize.XY
	taskText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	taskText.BackgroundTransparency = 1
	taskText.Position = UDim2.fromOffset(50 * Indent, 0)
	taskText.Size = UDim2.fromOffset(0, self.DefaultY)
	taskText.Parent = background

	local uIPadding2 = Instance.new("UIPadding")
	uIPadding2.Name = "UIPadding"
	uIPadding2.PaddingBottom = UDim.new(0, 2)
	uIPadding2.Parent = taskText

	local uIPadding = Instance.new("UIPadding")
	uIPadding.Name = "UIPadding"
	uIPadding.PaddingRight = UDim.new(0, 5)
	uIPadding.PaddingLeft = UDim.new(0, 5)
	uIPadding.Parent = background
	
return background
end

function ImOverlay:Render()
	-- We arent doing anything this frame
	
if self.m_State == "" then
		self:m_Pool()
		self:m_Cleanup()
		self.DidUpdate = false
		
return
	end

	self.m_State ..= `{self.DefaultY}|{self.TextSize}`

	if self.m_State == self.m_PreviousState then
		self:m_Cleanup()
		self.DidUpdate = false
		
return
	else
		self:m_Pool()
	end

	self.m_PreviousState = self.m_State
	self.DidUpdate = true

	for i, Render in self.m_RenderGroup do
		
if #self.m_ItemPool == 0 then
			local Label = self:m_CreateLabel(Render.Text, Render.TextColor, Render.BackgroundColor, Render.Indent)
			Label.LayoutOrder = i
			Label.Parent = self.BackFrame
			
continue
		end
		

local Label = table.remove(self.m_ItemPool, #self.m_ItemPool)
		local TaskText = Label.TaskText

		Label.LayoutOrder = i
		Label.BackgroundColor3 = Render.BackgroundColor
		TaskText.Text = Render.Text
		TaskText.TextColor3 = Render.TextColor
		TaskText.Position = UDim2.fromOffset(50 * Render.Indent, 0)

		Label.Visible = true
		Label.Parent = self.BackFrame
	


end

	self:m_Cleanup()


end

function ImOverlay:Destroy()
	self.BackFrame:Destroy()

	setmetatable(self, nil)
end

return ImOverlay
