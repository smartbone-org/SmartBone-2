--!optimize 2
local Types = require(script.Types)
local Iris = {} :: Types.Iris
local Internal: Types.Internal = require(script.Internal)(Iris)

Iris.Disabled = false

Iris.Args = {}

Iris.Events = {}

function Iris.HasInit()
	return Internal._started
end

function Iris.Init(parentInstance: BasePlayerGui?, eventConnection: (RBXScriptSignal | () -> ())?): Types.Iris
	if parentInstance == nil then
		-- coalesce to playerGui
		parentInstance = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
	end
	if eventConnection == nil then
		-- coalesce to Heartbeat
		eventConnection = game:GetService("RunService").Heartbeat
	end
	Internal.parentInstance = parentInstance :: BasePlayerGui
	assert(Internal._started == false, "Iris.Init can only be called once.")
	Internal._started = true

	Internal._generateRootInstance()
	Internal._generateSelectionImageObject()

	-- spawns the connection to call `Internal._cycle()` within.
	task.spawn(function()
		if typeof(eventConnection) == "function" then
			while true do
				eventConnection()
				Internal._cycle()
			end
		elseif eventConnection ~= nil then
			eventConnection:Connect(function()
				Internal._cycle()
			end)
		end
	end)

	return Iris
end

function Iris:Connect(callback: () -> ()) -- this uses method syntax for no reason.
	if Internal._started == false then
		warn("Iris:Connect() was called before calling Iris.Init(), the connected function will never run")
	end
	table.insert(Internal._connectedFunctions, callback)
end

function Iris.Append(userInstance: GuiObject)
	local parentWidget: Types.Widget = Internal._GetParentWidget()
	local widgetInstanceParent: GuiObject
	if Internal._config.Parent then
		widgetInstanceParent = Internal._config.Parent :: any
	else
		widgetInstanceParent = Internal._widgets[parentWidget.type].ChildAdded(parentWidget, { type = "userInstance" } :: Types.Widget)
	end
	userInstance.Parent = widgetInstanceParent
end

function Iris.End()
	if Internal._stackIndex == 1 then
		error("Callback has too many calls to Iris.End()", 2)
	end
	Internal._IDStack[Internal._stackIndex] = nil
	Internal._stackIndex -= 1
end

--[[
    ------------------------
        [SECTION] Config
    ------------------------
]]

function Iris.ForceRefresh()
	Internal._globalRefreshRequested = true
end

function Iris.UpdateGlobalConfig(deltaStyle: { [string]: any })
	for index, style in deltaStyle do
		Internal._rootConfig[index] = style
	end
	Iris.ForceRefresh()
end

function Iris.PushConfig(deltaStyle: { [string]: any })
	local ID = Iris.State(-1)
	if ID.value == -1 then
		ID:set(deltaStyle)
	else
		-- compare tables
		if Internal._deepCompare(ID:get(), deltaStyle) == false then
			-- refresh local
			Internal._localRefreshActive = true
			ID:set(deltaStyle)
		end
	end

	Internal._config = setmetatable(deltaStyle, {
		__index = Internal._config,
	}) :: any
end

function Iris.PopConfig()
	Internal._localRefreshActive = false
	Internal._config = getmetatable(Internal._config :: any).__index
end

Iris.TemplateConfig = require(script.config)
Iris.UpdateGlobalConfig(Iris.TemplateConfig.colorDark) -- use colorDark and sizeDefault themes by default
Iris.UpdateGlobalConfig(Iris.TemplateConfig.sizeDefault)
Iris.UpdateGlobalConfig(Iris.TemplateConfig.utilityDefault)
Internal._globalRefreshRequested = false -- UpdatingGlobalConfig changes this to true, leads to Root being generated twice.

--[[
    --------------------
        [SECTION] ID
    --------------------
]]

function Iris.PushId(id: Types.ID)
	assert(typeof(id) == "string", "Iris expected Iris.PushId id to PushId to be a string.")

	Internal._pushedId = tostring(id)
end

function Iris.PopId()
	Internal._pushedId = nil
end

function Iris.SetNextWidgetID(id: Types.ID)
	Internal._nextWidgetId = id
end

--[[
    -----------------------
        [SECTION] State
    -----------------------
]]

function Iris.State(initialValue: any): Types.State
	local ID: Types.ID = Internal._getID(2)
	if Internal._states[ID] then
		return Internal._states[ID]
	end
	Internal._states[ID] = {
		value = initialValue,
		ConnectedWidgets = {},
		ConnectedFunctions = {},
	} :: any
	setmetatable(Internal._states[ID], Internal.StateClass)
	return Internal._states[ID]
end

function Iris.WeakState(initialValue: any): Types.State
	local ID: Types.ID = Internal._getID(2)
	if Internal._states[ID] then
		if #Internal._states[ID].ConnectedWidgets == 0 then
			Internal._states[ID] = nil
		else
			return Internal._states[ID]
		end
	end
	Internal._states[ID] = {
		value = initialValue,
		ConnectedWidgets = {},
		ConnectedFunctions = {},
	} :: any
	setmetatable(Internal._states[ID], Internal.StateClass)
	return Internal._states[ID]
end

function Iris.ComputedState(firstState: Types.State, onChangeCallback: (firstState: any) -> any): Types.State
	local ID: Types.ID = Internal._getID(2)

	if Internal._states[ID] then
		return Internal._states[ID]
	else
		Internal._states[ID] = {
			value = onChangeCallback(firstState.value),
			ConnectedWidgets = {},
			ConnectedFunctions = {},
		} :: any
		firstState:onChange(function(newValue: any)
			Internal._states[ID]:set(onChangeCallback(newValue))
		end)
		setmetatable(Internal._states[ID], Internal.StateClass)
		return Internal._states[ID]
	end
end

Iris.ShowDemoWindow = require(script.demoWindow)(Iris)

require(script.widgets)(Internal)
require(script.API)(Iris)

return Iris
