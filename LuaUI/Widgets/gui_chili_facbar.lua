-------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Chili FactoryBar",
    desc      = "v0.01 Chili buildmenu for factories.",
    author    = "CarRepairer (converted from jK's Buildbar)",
    date      = "2010-11-10",
    license   = "GNU GPL, v2 or later",
    layer     = 1001,
    enabled   = true,
  }
end


-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

WhiteStr   = "\255\255\255\255"
GreyStr    = "\255\210\210\210"
GreenStr   = "\255\092\255\092"

local buttonColor = {0,0,0,0.5}
local queueColor = {0.0,0.4,0.4,0.9}
local progColor = {1,0.7,0,0.6}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local Chili
local Button
local Label
local Window
local StackPanel
local Grid
local TextBox
local Image
local Progressbar
local screen0
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

local window_facbar, stack_main
local echo = Spring.Echo

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

options_path = 'Settings/Interface/FactoryBar'
options = {
	maxVisibleBuilds = {
		type = 'number',
		name = 'Visible Units in Que',
		desc = "The maximum units to show in the factory's queue",
		min = 2, max = 8,
		value = 3,
	},	
}

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------


-- list and interface vars
local facs = {}
local unfinished_facs = {}
local pressedFac  = -1
local waypointFac = -1
local waypointMode = 0   -- 0 = off; 1=lazy; 2=greedy (greedy means: you have to left click once before leaving waypoint mode and you can have units selected)
local buttonsize = 60

local myTeamID = 0
local inTweak  = 0
local cycle_half_s = 1

-------------------------------------------------------------------------------
-- SOUNDS
-------------------------------------------------------------------------------

local sound_waypoint  = LUAUI_DIRNAME .. 'Sounds/buildbar_waypoint.wav'
local sound_click     = LUAUI_DIRNAME .. 'Sounds/buildbar_click.WAV'
local sound_queue_add = LUAUI_DIRNAME .. 'Sounds/buildbar_add.wav'
local sound_queue_rem = LUAUI_DIRNAME .. 'Sounds/buildbar_rem.wav'

-------------------------------------------------------------------------------

local image_repeat    = LUAUI_DIRNAME .. 'Images/repeat.png'

local teamColors = {}
local GetTeamColor = Spring.GetTeamColor or function (teamID)
  local color = teamColors[teamID]
  if (color) then return unpack(color) end
  local _,_,_,_,_,_,r,g,b = Spring.GetTeamInfo(teamID)
  teamColors[teamID] = {r,g,b}
  return r,g,b
end

-------------------------------------------------------------------------------
-- SCREENSIZE FUNCTIONS
-------------------------------------------------------------------------------
local vsx, vsy   = widgetHandler:GetViewSizes()

function widget:ViewResize(viewSizeX, viewSizeY)
  vsx = viewSizeX
  vsy = viewSizeY
end


-------------------------------------------------------------------------------

local GetUnitDefID      = Spring.GetUnitDefID
local GetUnitHealth     = Spring.GetUnitHealth
local GetUnitStates     = Spring.GetUnitStates
local DrawUnitCommands  = Spring.DrawUnitCommands
local GetSelectedUnits  = Spring.GetSelectedUnits
local GetFullBuildQueue = Spring.GetFullBuildQueue
local GetUnitIsBuilding = Spring.GetUnitIsBuilding

local push        = table.insert


-------------------------------------------------------------------------------


local function AddFacButton(unitID, unitDefID, tocontrol, stackname)
	tocontrol:AddChild(
		Button:New{
			width = buttonsize*1.2,
			height = buttonsize*1.0,
			tooltip = 			'Click - ' 			.. GreenStr .. 'Select \n' 					
				.. WhiteStr .. 	'Middle click - ' 	.. GreenStr .. 'Go to \n'
				.. WhiteStr .. 	'Right click - ' 	.. GreenStr .. 'Quick Rallypoint Mode' 
				,
			backgroundColor = buttonColor,
			OnClick = {
				function(_,_,_,button)
					if button == 2 then
						local x,y,z = Spring.GetUnitPosition(unitID)
						Spring.SetCameraTarget(x,y,z)
					elseif button == 3 then
						Spring.Echo("BuildBar: Entered greedy waypoint mode")
						Spring.PlaySoundFile(sound_waypoint, 1)
						waypointMode = 2 -- greedy mode
						waypointFac  = stackname
					else
						Spring.PlaySoundFile(sound_click, 1)
						Spring.SelectUnitArray({unitID})
					end
				end
			},
			children = {
				Image:New {
					file = "#"..unitDefID,
					file2 = WG.GetBuildIconFrame(UnitDefs[unitDefID]),
					keepAspect = false;
					width = '100%',
					height = '100%',
				},
			},
		}
	)

	local boStack = StackPanel:New{
		name = stackname .. '_bo',
		itemMargin={0,0,0,0},
		itemPadding={0,0,0,0},
		padding={0,0,0,0},
		x=0,
		width=700,
		height = buttonsize,
		resizeItems = false,
		orientation = 'horizontal',
		centerItems = false,
	}
	local qStack = StackPanel:New{
		name = stackname .. '_q',
		itemMargin={0,0,0,0},
		itemPadding={0,0,0,0},
		padding={0,0,0,0},
		x=0,
		width=700,
		height = buttonsize,
		resizeItems = false,
		orientation = 'horizontal',
		centerItems = false,
	}
	local qStore = {}
	
	local facStack = StackPanel:New{
		name = stackname,
		itemMargin={0,0,0,0},
		itemPadding={0,0,0,0},
		padding={0,0,0,0},
		width=800,
		height = buttonsize*1.0,
		resizeItems = false,
		centerItems = false,
	}
	
	facStack:AddChild( qStack )
	tocontrol:AddChild( facStack )
	return facStack, boStack, qStack, qStore
end

local function MakeButton(unitDefID, facID)

	local ud = UnitDefs[unitDefID]
	local tooltip = "Build Unit: " .. ud.humanName .. " - " .. ud.tooltip .. "\n"
  
	return
		Button:New{
			name = unitDefID,
			tooltip=tooltip,
			x=0,
			width = buttonsize,
			height = buttonsize,
			padding = {8,8,8,8},
			--padding = {0,0,0,0},
			backgroundColor = queueColor,
			OnClick = {
				function(_,_,_,button)
					local alt, ctrl, meta, shift = Spring.GetModKeyState()
					local rb = button == 3
					local lb = button == 1
					if not (lb or rb) then return end
					
					local opt = {}
					if alt   then push(opt,"alt")   end
					if ctrl  then push(opt,"ctrl")  end
					if meta  then push(opt,"meta")  end
					if shift then push(opt,"shift") end
					
					if rb then
						push(opt,"right")
					end
					
					Spring.GiveOrderToUnit(facID, -(unitDefID), {}, opt)
					
					if rb then
						Spring.PlaySoundFile(sound_queue_rem, 0.97)
					else
						Spring.PlaySoundFile(sound_queue_add, 0.95)
					end
				end
			},
			children = {
				Label:New {
					name='count',
					autosize=false;
					width="100%";
					height="100%";
					align="right";
					valign="top";
					caption = '';
					fontSize = 14;
					fontShadow = true;
				},

				
				Label:New{ caption = ud.metalCost .. ' m', fontSize = 11, x=2, bottom=2, },
				Image:New {
					name = 'bp',
					file = "#"..unitDefID,
					file2 = WG.GetBuildIconFrame(ud),
					keepAspect = false;
					width = '100%',height = '80%',
					children = {
						Progressbar:New{
							value = 0.0,
							name    = 'prog';
							max     = 1;
							color   		= progColor,
							backgroundColor = {1,1,1,  0.01},
							x=4,y=4, bottom=4,right=4,
							skin=nil,
							skinName='default',
						},
					},
				},
			},
		}
	
end


-------------------------------------------------------------------------------


-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

local function GetBuildQueue(unitID)
  local result = {}
  local queue = GetFullBuildQueue(unitID)
  if (queue ~= nil) then
    for _,buildPair in ipairs(queue) do
      local udef, count = next(buildPair, nil)
      if result[udef]~=nil then
        result[udef] = result[udef] + count
      else
        result[udef] = count
      end
    end
  end
  return result
end


local function WaypointHandler(x,y,button)
  if (button==1)or(button>3) then
    Spring.Echo("BuildBar: Exited greedy waypoint mode")
    Spring.PlaySoundFile(sound_waypoint, 1)
    waypointFac  = -1
    waypointMode = 0
    return
  end

  local alt, ctrl, meta, shift = Spring.GetModKeyState()
  local opt = {"right"}
  if alt   then push(opt,"alt")   end
  if ctrl  then push(opt,"ctrl")  end
  if meta  then push(opt,"meta")  end
  if shift then push(opt,"shift") end

  local type,param = Spring.TraceScreenRay(x,y)
  if type=='ground' then
    Spring.GiveOrderToUnit(facs[waypointFac].unitID, CMD.MOVE,param,opt) 
  elseif type=='unit' then
    Spring.GiveOrderToUnit(facs[waypointFac].unitID, CMD.GUARD,{param},opt)     
  else --feature
    type,param = Spring.TraceScreenRay(x,y,true)
    Spring.GiveOrderToUnit(facs[waypointFac].unitID, CMD.MOVE,param,opt)
  end

  --if not shift then waypointMode = 0; return true end
end

local function RecreateFacbar()
	stack_main:ClearChildren()
	for i,facInfo in ipairs(facs) do
		local unitDefID = facInfo.unitDefID
		
		local unitBuildDefID = -1
		local unitBuildID    = -1
		local progress

		-- building?
		unitBuildID      = GetUnitIsBuilding(facInfo.unitID)
		if unitBuildID then
			unitBuildDefID = GetUnitDefID(unitBuildID)
			_, _, _, _, progress = GetUnitHealth(unitBuildID)
			unitDefID      = unitBuildDefID
		elseif (unfinished_facs[facInfo.unitID]) then
			_, _, _, _, progress = GetUnitHealth(facInfo.unitID)
			if (progress>=1) then 
				progress = -1
				unfinished_facs[facInfo.unitID] = nil
			end
		end

		local facStack, boStack, qStack, qStore = AddFacButton(facInfo.unitID, unitDefID, stack_main, i)
		facs[i].facStack 	= facStack
		facs[i].boStack 	= boStack
		facs[i].qStack 		= qStack
		facs[i].qStore 		= qStore
		
		local buildList   = facInfo.buildList
		local buildQueue  = GetBuildQueue(facInfo.unitID)
		for j,unitDefIDb in ipairs(buildList) do
			local unitDefIDb = unitDefIDb
			boStack:AddChild( MakeButton(unitDefIDb, facInfo.unitID) )
			qStore[i .. '|' .. unitDefIDb] = MakeButton(unitDefIDb, facInfo.unitID)
		end
		
	end

	stack_main:Invalidate()
	stack_main:UpdateLayout()
end
local function UpdateFactoryList()

  facs = {}

  local teamUnits = Spring.GetTeamUnits(myTeamID)
  local totalUnits = teamUnits.n

  for num = 1, totalUnits do
    local unitID = teamUnits[num]
    local unitDefID = GetUnitDefID(unitID)
    if UnitDefs[unitDefID].isFactory then
	echo ('updating fac list ' .. unitID)
		local bo =  UnitDefs[unitDefID] and UnitDefs[unitDefID].buildOptions
		if bo and #bo > 0 then	
		  push(facs,{ unitID=unitID, unitDefID=unitDefID, buildList=UnitDefs[unitDefID].buildOptions })
		  local _, _, _, _, buildProgress = GetUnitHealth(unitID)
		  if (buildProgress)and(buildProgress<1) then
			unfinished_facs[unitID] = true
		  end
		end
    end
  end
  
	
	RecreateFacbar()
end



function widget:DrawWorld()
	-- Draw factories command lines
	if waypointMode>1 then
		local unitID
		if waypointMode>1 then 
			unitID = facs[waypointFac].unitID
		end
		DrawUnitCommands(unitID)
	end
end

function widget:UnitCreated(unitID, unitDefID, unitTeam)
  if (unitTeam ~= myTeamID) then
    return
  end

  if UnitDefs[unitDefID].isFactory then
	local bo =  UnitDefs[unitDefID] and UnitDefs[unitDefID].buildOptions
	if bo and #bo > 0 then
		push(facs,{ unitID=unitID, unitDefID=unitDefID, buildList=UnitDefs[unitDefID].buildOptions })
		--UpdateFactoryList()
		RecreateFacbar()
	end
  end
  unfinished_facs[unitID] = true
end

function widget:UnitGiven(unitID, unitDefID, unitTeam, oldTeam)
  widget:UnitCreated(unitID, unitDefID, unitTeam)
end

function widget:UnitDestroyed(unitID, unitDefID, unitTeam)
  if (unitTeam ~= myTeamID) then
    return
  end
  if UnitDefs[unitDefID].isFactory then
    for i,facInfo in ipairs(facs) do
      if unitID==facInfo.unitID then
        
        table.remove(facs,i)
        unfinished_facs[unitID] = nil
		--UpdateFactoryList()
		RecreateFacbar()
        return
      end
    end
  end
end

function widget:UnitTaken(unitID, unitDefID, unitTeam, newTeam)
  widget:UnitDestroyed(unitID, unitDefID, unitTeam)
end

function widget:Update()
	if myTeamID~=Spring.GetMyTeamID() then
		myTeamID = Spring.GetMyTeamID()
		UpdateFactoryList()
	end
	inTweak = widgetHandler:InTweakMode()
  
	cycle_half_s = (cycle_half_s % 16) + 1
	if cycle_half_s ~= 1 then return end
	for i,facInfo in ipairs(facs) do
		if Spring.ValidUnitID( facInfo.unitID ) then
			
			local unitDefID = facInfo.unitDefID
			
			local unitBuildDefID = -1
			local unitBuildID    = -1

			-- building?
			local progress = 0
			unitBuildID      = GetUnitIsBuilding(facInfo.unitID)
			if unitBuildID then
				unitBuildDefID = GetUnitDefID(unitBuildID)
				_, _, _, _, progress = GetUnitHealth(unitBuildID)
				unitDefID      = unitBuildDefID
			elseif (unfinished_facs[facInfo.unitID]) then
				_, _, _, _, progress = GetUnitHealth(facInfo.unitID)
				if (progress>=1) then 
					progress = -1
					unfinished_facs[facInfo.unitID] = nil
				end
			end
			
			-----------------------------------------------------------------------------------------
			
			local buildList   = facInfo.buildList
			local buildQueue  = GetBuildQueue(facInfo.unitID)
			for j,unitDefIDb in ipairs(buildList) do

				local unitDefIDb = unitDefIDb
				
				local amount = buildQueue[unitDefIDb] or 0
				
				local qButton = facs[i].qStore[i .. '|' .. unitDefIDb]
				
				--local qBar = qButton.childrenByName['prog']
				local qBar = qButton.childrenByName['bp'].childrenByName['prog']
				
				
				qBar:SetValue(0)
				facs[i].qStack:RemoveChild(qButton)
				local boButton = facs[i].boStack.childrenByName[unitDefIDb]
				--local boBar = boButton.childrenByName['prog']
				local boBar = boButton.childrenByName['bp'].childrenByName['prog']
				
				boBar:SetValue(0)
				
				boButton.backgroundColor = buttonColor
				boButton:Invalidate()
				
				if unitDefIDb == unitBuildDefID then
					boBar:SetValue(progress)
					qBar:SetValue(progress)
				end
				local boCount = boButton.childrenByName['count']
				local qCount = qButton.childrenByName['count']			
				boCount:SetCaption(amount > 1 and amount or '')
				qCount:SetCaption(amount > 1 and amount or '')
			end
			
			local buildQueue  = Spring.GetFullBuildQueue(facInfo.unitID, options.maxVisibleBuilds.value +1)
			
			if (buildQueue ~= nil) then
				
				local n,j = 1,options.maxVisibleBuilds.value
				
				while (buildQueue[n]) do
					local unitDefIDb, count = next(buildQueue[n], nil)
					local qButton = facs[i].qStore[i .. '|' .. unitDefIDb]
					
					
					local boButton = facs[i].boStack.childrenByName[unitDefIDb]
					boButton.backgroundColor = queueColor
					boButton:Invalidate()
					
					--qCount:SetCaption('abc')
					if not facs[i].qStack:GetChildByName(qButton.name) then
						facs[i].qStack:AddChild(qButton)
					end
					j = j-1
					if j==0 then break end
					n = n+1
				end
			end

		end --is valid?
	end --for i,facInfo in ipairs(facs) do
  
end



-------------------------------------------------------------------------------
-------------------------------------------------------------------------------


function widget:SelectionChanged(selectedUnits)
	if facs[pressedFac] then
		local qStack = facs[pressedFac].qStack
		local boStack = facs[pressedFac].boStack
		facs[pressedFac].facStack:RemoveChild(boStack)
		facs[pressedFac].facStack:AddChild(qStack)
	end

	pressedFac = -1
	
	if (#selectedUnits == 1) then 
		for cnt, f in ipairs(facs) do 
			if f.unitID == selectedUnits[1] then 
				pressedFac = cnt
				
				local qStack = facs[pressedFac].qStack
				local boStack = facs[pressedFac].boStack
				facs[pressedFac].facStack:RemoveChild(qStack)
				facs[pressedFac].facStack:AddChild(boStack)
			end
		end
	end
end


function widget:MouseRelease(x, y, button)
	if (waypointMode>0)and(not inTweak) and (waypointMode>0)and(waypointFac>0) then
		WaypointHandler(x,y,button)	
	end
	return -1
end

function widget:MousePress(x, y, button)
	if waypointMode>1 then
		-- greedy waypointMode
		return (button~=2) -- we allow middle click scrolling in greedy waypoint mode
	end
	if waypointMode>1 then
		Spring.Echo("BuildBar: Exited greedy waypoint mode")
		Spring.PlaySoundFile(sound_waypoint, 1)
	end
	waypointFac  = -1
	waypointMode = 0
	return false
end

function widget:Initialize()
	if (not WG.Chili) then
		widgetHandler:RemoveWidget(widget)
		return
	end

	-- setup Chili
	Chili = WG.Chili
	Button = Chili.Button
	Label = Chili.Label
	Window = Chili.Window
	StackPanel = Chili.StackPanel
	Grid = Chili.Grid
	TextBox = Chili.TextBox
	Image = Chili.Image
	Progressbar = Chili.Progressbar
	screen0 = Chili.Screen0

	stack_main = Grid:New{
		padding = {0,0,0,0},
		itemPadding = {0, 0, 0, 0},
		itemMargin = {0, 0, 0, 0},
		width='100%',
		height = '100%',
		resizeItems = false,
		orientation = 'horizontal',
		centerItems = false,
		columns=2,
	}
	window_facbar = Window:New{
		padding = {3,3,3,3,},
		dockable = true,
		name = "facbar",
		x = 0, y = 0,
		width  = 600,
		height = 200,
		parent = Chili.Screen0,
		draggable = false,
		tweakDraggable = true,
		tweakResizable = true,
		resizable = false,
		dragUseGrip = true,
		minimumSize = {600,200},
		color = {0,0,0,0},
		children = {
			stack_main,
		},
	}
	myTeamID = Spring.GetMyTeamID()

	UpdateFactoryList()

	local viewSizeX, viewSizeY = widgetHandler:GetViewSizes()
	self:ViewResize(viewSizeX, viewSizeY)
end
