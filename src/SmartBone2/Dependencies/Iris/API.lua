local Types = require(script.Parent.Types)

return function(Iris: Types.Iris)
	-- basic wrapper for nearly every widget, saves space.
	local function wrapper(name: string): (arguments: Types.WidgetArguments?, states: Types.States?) -> Types.Widget
		return function(arguments: Types.WidgetArguments?, states: Types.States?): Types.Widget
			return Iris.Internal._Insert(name, arguments, states)
		end
	end

	--[[
        ----------------------------
            [SECTION] Window API
        ----------------------------
    ]]

	Iris.Window = wrapper("Window")

	Iris.SetFocusedWindow = Iris.Internal.SetFocusedWindow

	Iris.Tooltip = wrapper("Tooltip")

	Iris.MenuBar = wrapper("MenuBar")

	Iris.Menu = wrapper("Menu")

	Iris.MenuItem = wrapper("MenuItem")

	Iris.MenuToggle = wrapper("MenuToggle")

	Iris.Separator = wrapper("Separator")

	Iris.Indent = wrapper("Indent")

	Iris.SameLine = wrapper("SameLine")

	Iris.Group = wrapper("Group")

	Iris.Text = wrapper("Text")

	Iris.TextWrapped = function(arguments: Types.WidgetArguments): Types.Widget
		arguments[2] = true
		return Iris.Internal._Insert("Text", arguments)
	end

	Iris.TextColored = function(arguments: Types.WidgetArguments): Types.Widget
		arguments[3] = arguments[2]
		arguments[2] = nil
		return Iris.Internal._Insert("Text", arguments)
	end

	Iris.SeparatorText = wrapper("SeparatorText")

	Iris.InputText = wrapper("InputText")

	Iris.Button = wrapper("Button")

	Iris.SmallButton = wrapper("SmallButton")

	Iris.Checkbox = wrapper("Checkbox")

	Iris.RadioButton = wrapper("RadioButton")

	Iris.Tree = wrapper("Tree")

	Iris.CollapsingHeader = wrapper("CollapsingHeader")

	Iris.InputNum = wrapper("InputNum")

	Iris.InputVector2 = wrapper("InputVector2")

	Iris.InputVector3 = wrapper("InputVector3")

	Iris.InputUDim = wrapper("InputUDim")

	Iris.InputUDim2 = wrapper("InputUDim2")

	Iris.InputRect = wrapper("InputRect")

	Iris.DragNum = wrapper("DragNum")

	Iris.DragVector2 = wrapper("DragVector2")

	Iris.DragVector3 = wrapper("DragVector3")

	Iris.DragUDim = wrapper("DragUDim")

	Iris.DragUDim2 = wrapper("DragUDim2")

	Iris.DragRect = wrapper("DragRect")

	Iris.InputColor3 = wrapper("InputColor3")

	Iris.InputColor4 = wrapper("InputColor4")

	Iris.SliderNum = wrapper("SliderNum")

	Iris.SliderVector2 = wrapper("SliderVector2")

	Iris.SliderVector3 = wrapper("SliderVector3")

	Iris.SliderUDim = wrapper("SliderUDim")

	Iris.SliderUDim2 = wrapper("SliderUDim2")

	Iris.SliderRect = wrapper("SliderRect")

	Iris.Selectable = wrapper("Selectable")

	Iris.Combo = wrapper("Combo")

	Iris.ComboArray = function(arguments: Types.WidgetArguments, states: Types.WidgetStates?, selectionArray: { any })
		local defaultState
		if states == nil then
			defaultState = Iris.State(selectionArray[1])
		else
			defaultState = states
		end
		local thisWidget = Iris.Internal._Insert("Combo", arguments, defaultState)
		local sharedIndex: Types.State = thisWidget.state.index
		for _, Selection in selectionArray do
			Iris.Internal._Insert("Selectable", { Selection, Selection }, { index = sharedIndex } :: Types.States)
		end
		Iris.End()

		return thisWidget
	end

	Iris.ComboEnum = function(arguments: Types.WidgetArguments, states: Types.WidgetStates?, enumType: Enum)
		local defaultState
		if states == nil then
			defaultState = Iris.State(enumType[1])
		else
			defaultState = states
		end
		local thisWidget = Iris.Internal._Insert("Combo", arguments, defaultState)
		local sharedIndex = thisWidget.state.index
		for _, Selection in enumType:GetEnumItems() do
			Iris.Internal._Insert("Selectable", { Selection.Name, Selection }, { index = sharedIndex } :: Types.States)
		end
		Iris.End()

		return thisWidget
	end
	Iris.InputEnum = Iris.ComboEnum

	Iris.Table = wrapper("Table")

	Iris.NextColumn = function()
		Iris.Internal._GetParentWidget().RowColumnIndex += 1
	end

	Iris.SetColumnIndex = function(columnIndex: number)
		local ParentWidget: Types.Widget = Iris.Internal._GetParentWidget()
		assert(columnIndex >= ParentWidget.InitialNumColumns, "Iris.SetColumnIndex Argument must be in column range")
		ParentWidget.RowColumnIndex = math.floor(ParentWidget.RowColumnIndex / ParentWidget.InitialNumColumns) + (columnIndex - 1)
	end

	Iris.NextRow = function()
		-- sets column Index back to 0, increments Row
		local ParentWidget: Types.Widget = Iris.Internal._GetParentWidget()
		local InitialNumColumns: number = ParentWidget.InitialNumColumns
		local nextRow: number = math.floor((ParentWidget.RowColumnIndex + 1) / InitialNumColumns) * InitialNumColumns
		ParentWidget.RowColumnIndex = nextRow
	end
end
