--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Chili Player List Window",
    desc      = "vX.XXX Chili Player List Window. Displays list of players with relevant information.",
    author    = "Aquanim",
    date      = "2017-01-12",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = false,
  }
end

-- Adapted from Deluxe Player List by CarRepairer, KingRaptor, CrazyEddie

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local spSendCommands			= Spring.SendCommands

local echo = Spring.Echo

local Chili
local Image
local Button
local Checkbox
local Window
local Panel
local ScrollPanel
local StackPanel
local Label
local screen0
local color2incolor
local incolor2color

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local DEBUG = true

local UPDATE_FREQUENCY = 0.8	-- seconds

local timer = 0

--------------------------------------------------------------------------------
-- variables for game state and personal state

local IsMission
if VFS.FileExists("mission.lua") then
	IsMission = true
else
	IsMission = false
end

local ceasefireAvailable = (not Spring.FixedAllies()) and IsFFA()
local localTeam = 0
local localAlliance = 0
local myID
local myName
local iAmSpec

--------------------------------------------------------------------------------
-- variables for large playerlist window

local window_playerlist
local contentHolder
local playersPanel
local exitButton
local debugButton

--------------------------------------------------------------------------------
-- variables for entity handling

-- entity = player (NOT including specs), human or AI
-- indexed by numbers mapped to playerID or teamID (if AI) in playerLookup and teamLookup
-- Contains isAI, playerID (if not AI), teamID, allyTeamID, smallControl, windowControl
local entities = {}
local playerLookup = {}
local teamLookup = {}

-- spectatorEntity = player (NOT including specs), human or AI
-- indexed by numbers mapped to playerID in playerSpectatorLookup
-- Contains playerID, smallControl, windowContro
local spectatorEntities = {}
local spectatorLookup = {}

-- allyteamEntities = groups of allied players
-- indexed by ...
local allyteamEntities = {}

-- local allyTeamOrderRank = {}
-- local allyTeamsDead = {}
-- local allyTeamsElo = {}
-- local playerTeamStatsCache = {}
-- local finishedUnits = {}
-- local numBigTeams = 0
-- local existsVeryBigTeam = nil
-- local myTeamIsVeryBig = nil
-- local specTeam = {roster = {}}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

options_path = 'Settings/HUD Panels/Player List Window'
options = {
	visible = {
		name = "Visible",
		type = 'bool',
		value = false, --set to false when initialisation is complete
		desc = "Set a hotkey here to toggle the playerlist on and off",
		OnChange = function() UpdateVisibility() end,
	},
	background_opacity = {
		name = "Opacity",
		type = "number",
		value = 0.8, min = 0, max = 1, step = 0.01,
	},
	show_ccr = {
		name = "Show clan/country/rank",
		type = 'bool',
		value = true,
		desc = "Show the clan, country, and rank columns",
		OnChange = function() SetupControls() end,
	},
	show_resource_status = {
		name = "Show unit and income stats",
		type = 'bool',
		value = true,
		desc = "Display resource statistics: metal in mobile units and static defenses; metal and energy income; current stored resrouces.",
		OnChange = function() SetupControls() end,
	},
	show_cpu_ping = {
		name = "Show ping and cpu",
		type = 'bool',
		value = true,
		desc = "Show player's ping and cpu",
		OnChange = function() SetupControls() end,
	},
	text_height = {
		name = 'Font Size (16-30)',
		type = 'number',
		value = 16,
		min=16,max=30,step=1,
		OnChange = function() SetupControls() end,
		advanced = true
	},
	name_width = {
		name = 'Name Width (20-40)',
		type = 'number',
		value = 20,
		min=20,max=40,step=1,
		OnChange = function() SetupControls() end,
		advanced = true
	},
	stats_width = {
		name = 'Metal worth stats width (2-5)',
		type = 'number',
		value = 4,
		min=2,max=5,step=1,
		OnChange = function() SetupControls() end,
		advanced = true
	},
	income_width = {
		name = 'Income width (2-5)',
		type = 'number',
		value = 3,
		min=2,max=5,step=1,
		OnChange = function() SetupControls() end,
		advanced = true
	},
	fancySkinning = {
		name = 'Fancy Skinning',
		type = 'bool',
		value = 'panel',
		items = {
			{key = 'panel', name = 'None'},
			{key = 'panel_0001', name = 'Flush',},
			{key = 'panel_0001_small', name = 'Flush Small',},
			{key = 'panel_1001_small', name = 'Top Left',},
		},
		OnChange = function (self)
			local currentSkin = Chili.theme.skin.general.skinName
			local skin = Chili.SkinHandler.GetSkin(currentSkin)
			
			local className = self.value
			local newClass = skin.panel
			if skin[className] then
				newClass = skin[className]
			end
			
			playersPanel.tiles = newClass.tiles
			playersPanel.TileImageFG = newClass.TileImageFG
			--playersPanel.backgroundColor = newClass.backgroundColor
			playersPanel.TileImageBK = newClass.TileImageBK
			playersPanel:Invalidate()
		end,
		advanced = true,
		noHotkey = true,
	},
	cpu_ping_as_text = {
		name = "Show ping/cpu as text",
		type = 'bool',
		value = false,
		desc = "Show ping and cpu stats as text (vs. as an icon)",
		OnChange = function() SetupPanels() end,
		advanced = true
	},
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- config for large playerlist window

-- local x_icon_clan
-- local x_icon_country
-- local x_icon_rank
-- local x_cf
-- local x_status
-- local x_name
-- local x_teamsize
-- local x_teamsize_dude
-- local x_share
-- local x_m_mobiles
-- local x_m_defense
-- local x_m_income
-- local x_e_income
-- local x_m_fill
-- local x_e_fill
-- local x_cpu
-- local x_ping
-- local x_postping
-- local x_bound
-- local x_windowbound

-- local x_m_mobiles_width
-- local x_m_defense_width
-- local x_m_income_width
-- local x_e_income_width

-- local function CalculateWidths()
	-- x_start 		= 0
	
	-- x_icon_clan		= x_start
	-- x_icon_country	= x_icon_clan + 18
	-- x_icon_rank		= x_icon_country + 20
	-- x_ccr_finished	= options.show_ccr.value and x_icon_rank + 16 or x_start
	
	-- x_name			=  x_ccr_finished
	-- x_id_finished 	= x_name + (options.name_width.value or 20) * options.text_height.value / 2
	
	-- x_m_mobiles 	= x_id_finished
	-- x_m_mobiles_width = options.stats_width.value * options.text_height.value / 2 + 10
	-- x_m_defense		= x_m_mobiles + x_m_mobiles_width -- + 34
	-- x_m_defense_width = options.stats_width.value * options.text_height.value / 2 + 10
	-- x_m_income		= x_m_defense + x_m_defense_width
	-- x_m_income_width = options.income_width.value * options.text_height.value / 2 + 10
	-- x_e_income		= x_m_income + x_m_income_width
	-- x_e_income_width = options.income_width.value * options.text_height.value / 2 + 10
	-- x_m_fill		= x_e_income + x_e_income_width
	-- x_e_fill		= x_m_fill + 30
	-- x_resouce_status_finished = options.show_resource_status.value and x_e_fill + 30 or x_id_finished
	
	-- x_share_m			= x_resouce_status_finished + 20
	-- x_share_e			= x_resouce_status_finished + options.text_height.value + 4
	-- x_share_u			= x_resouce_status_finished + options.text_height.value + 4
	-- x_share_finished = x_share_u + options.text_height.value + 4 + 10
	
	-- x_cfstatus		= x_share_finished
	-- x_actions_finished = ceasefireAvailable and (x_cfstatus + options.text_height.value + 4) or x_share_finished
	
	-- x_cpu			= x_actions_finished + (options.show_cpu_ping.value and (options.cpu_ping_as_text.value and 52 or 30) or 0)
	-- x_ping			= x_cpu + (options.show_cpu_ping.value and (options.cpu_ping_as_text.value and 46 or 16) or 0)
	-- x_bound			= x_ping + 28
	-- x_windowbound	= x_bound + 0
	
	-- x_teamsize		= x_icon_clan
	-- x_teamsize_dude	= x_icon_rank 
-- end
-- CalculateWidths()

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- functions for large playerlist controls

function CreateWindowPlayerControl()

	local ControlType = ComboBox
	if disableInteraction then
		ControlType = Control
	end
	
	return nil
end

-- call this whenever configuration changes (alignment, etc.)
function ArrangeSmallPlayerControl()
	
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- functions for large playerlist window

-- creates panel
local function SetupControls()
	if window_playerlist then
		window_playerlist:Invalidate()
	end
	
	window_playerlist = Window:New{  
		name = "PlayerlistWindow",
		x = 0,
		y = 55,
		width  = 550,
		height = 450,
		minWidth  = 550,
		minHeight = 450,
		autosize = true,
		dockable  = true,
		draggable = true,
		resizable = false,
		tweakDraggable = true,
		tweakResizable = true,
		padding = {0, 0, 0, 0},
		color = {0, 0, 0, 0},
		parent = screen0,
	}
	
	contentHolder = Panel:New{
		classname = options.fancySkinning.value,
		x = 0,
		y = 0,
		right = 0,
		bottom = 0,
		draggable = false,
		resizable = false,
		padding = {0, 0, 0, 0},
		backgroundColor = {1, 1, 1, options.background_opacity.value},
		parent = window_playerlist,
	}
	
	playersPanel = ScrollPanel:New{
		classname = 'panel',
		x = 0,
		y = 0,
		right = 0,
		bottom = 0,
		draggable = false,
		resizable = false,
		padding = {0, 0, 0, 0},
		backgroundColor = {1, 1, 1, 0},
		parent = contentHolder,
	}
	
	exitButton = Button:New{
		height=25;
		width=50;
		right=10;
		bottom=10;
		caption="Exit",
		OnClick = {
			function() 
				TogglePlayerlistWindow()
			end
		};
		parent = contentHolder;
	}
end

-- Puts the headers at the top of the panel.
-- local function AddTableHeaders()
	-- local fontsize = options.text_height.value
	-- local row = 0
	-- if options.show_resource_status.value then
		-- playersPanel:AddChild( Image:New{ x=x_m_mobiles + x_m_mobiles_width/2 -5, y=5,	height = (fontsize)+1, color =	{1, .3, .3, 1},  file = 'LuaUI/Images/commands/Bold/attack.png',} )
		-- playersPanel:AddChild( Image:New{ x=x_m_defense + x_m_defense_width/2 -5, y=5,	height = (fontsize)+1, color = {.3, .3, 1, 1}, file = 'LuaUI/Images/commands/Bold/guard.png',} )
		-- playersPanel:AddChild( Image:New{ x=x_e_income + x_e_income_width/2 -7, y=5,	height = (fontsize)+1,  file = 'LuaUI/Images/energy.png',} )
		-- playersPanel:AddChild( Image:New{ x=x_m_income + x_m_income_width/2 -7, y=5,	height = (fontsize)+1, file = 'LuaUI/Images/ibeam.png',} )
	-- end
	-- if options.show_cpu_ping.value then
		-- playersPanel:AddChild( Label:New{ x=x_cpu, y=5,	caption = 'C', 	fontShadow = true,  fontsize = fontsize,} )
		-- playersPanel:AddChild( Label:New{ x=x_ping, y=5,	caption = 'P', 	fontShadow = true,  fontsize = fontsize,} )
	-- end
-- end

function UpdateVisibility()
	if screen0 and window_playerlist then
		if options.visible.value then
			screen0:AddChild(window_playerlist)
		else
			screen0:RemoveChild(window_playerlist)
		end
	end
end

function TogglePlayerlistWindow()
	options.visible.value = not options.visible.value
	if UpdateVisibility then UpdateVisibility() end
end

WG.TogglePlayerlistWindow = TogglePlayerlistWindow -- called by global commands widget

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- config for small playerlist display



--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- functions for small playerlist controls

function CreateSmallPlayerControl()

	local ControlType = ComboBox
	if disableInteraction then
		ControlType = Control
	end
	
	return nil
end

-- call this whenever configuration changes (alignment, etc.)
function ArrangeSmallPlayerControl()
	
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- functions for small playerlist display

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- functions for entity handling

function CreateEntity(ai, pID, tID, atID)
	local entity = { isAI = ai, playerID = pID, teamID = tID, allyTeamID = atID, smallControl = nil, windowControl = nil}
	return entity
end

function CreateSpectatorEntity(pID)
	local entity = { playerID = pID, smallControl = nil, windowControl = nil}
	return entity
end

function CreateAllyteamEntity(atID)
	local entity = { allyteamID = atID, smallControl = nil, windowControl = nil}
	return entity
end

function AddHumanEntity(playerID)
	local name,active,spectator,teamID,allyTeamID,pingTime,cpuUsage,country,rank,customKeys = Spring.GetPlayerInfo(playerID)
	if spectator then
		local i = #spectatorEntities + 1
		spectatorEntities[i] = CreateSpectatorEntity(playerID)
		spectatorLookup[playerID] = i
	else
		local i = #entities + 1
		entities[i] = CreateEntity(false, playerID, teamID, allyTeamID)
		playerLookup[playerID] = i
	end
end

function AddAIEntity(teamID)
	local skirmishAIID, name, hostingPlayerID, shortName, version, options = Spring.GetAIInfo(teamID)
	local _,leader,isDead,isAI,side,allyTeamID,customTeamKeys,incomeMultiplier = Spring.GetTeamInfo(teamID)
	local i = #entities + 1
	entities[i] = CreateEntity(true, nil, teamID, allyTeamID)
	teamLookup[teamID] = i
end

function AddAllyteamEntity(allyteamID)
	local customTeamKeys = Spring.GetAllyTeamInfo(allyteamID) --????
	allyteamEntities[allyteamID] = CreateAllyteamEntity(allyteamID)
end

local function ReadAllPlayers()
	local playersList = Spring.GetPlayerList()
	local teamsList = Spring.GetTeamList()
	local allyTeamsList = Spring.GetAllyTeamList()
	
	-- look through teams list for AIs.
	for i=1,#teamsList do
		local teamID = teamsList[i]
		if teamID ~= Spring.GetGaiaTeamID() then
			--teams[teamID] = teams[teamID] or {roster = {}}
			local _,leader,isDead,isAI,side,allyTeamID,customTeamKeys,incomeMultiplier = Spring.GetTeamInfo(teamID)
			if isAI then
				AddAIEntity(teamID)
			end
		end 
	end
	
	-- look through players list for humans (players and spectators).
	for i=1,#playersList do
		local playerID = playersList[i]
		AddHumanEntity(playerID)
	end
	
	-- look through allyteams list
	for i=1,#allyTeamsList do
		local allyTeamID = allyTeamsList[i]
		AddAllyteamEntity(allyTeamID)
	end
	
end

local function CheckPlayer(playerID)
	local name,active,spectator,teamID,allyTeamID,pingTime,cpuUsage,country,rank,customKeys = Spring.GetPlayerInfo(playerID)
	local becameSpectator = false
	local changedTeam = false
	
	if playerLookup[playerID] then
		if teamID ~= entities[playerLookup[playerID]].teamID then
			--this player has changed teamID
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- functions for entity updating

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- functions for status updating

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- callins

function widget:Update(dt)
	timer = timer + dt
	if timer > UPDATE_FREQUENCY then
		timer = 0
		-- TODO do updatey things
	end
end

function widget:PlayerChanged(playerID)
	Spring.Echo("Playerlist Window Debug: PlayerChanged called, pID "..playerID)
	local name,active,spectator,teamID,allyTeamID,pingTime,cpuUsage,country,rank,customKeys = Spring.GetPlayerInfo(playerID)
	CheckPlayer(playerID)
end

function widget:PlayerAdded(playerID)
	Spring.Echo("Playerlist Window Debug: PlayerAdded called, pID "..playerID)
	local name,active,spectator,teamID,allyTeamID,pingTime,cpuUsage,country,rank,customKeys = Spring.GetPlayerInfo(playerID)
	AddHumanEntity(playerID)
end

function widget:PlayerRemoved(playerID)
	Spring.Echo("Playerlist Window Debug: PlayerRemoved called, pID "..playerID)
	--TODO
end

function widget:TeamDied(teamID)
	Spring.Echo("Playerlist Window Debug: TeamDied called, tID "..teamID)
	--TODO
end

function widget:TeamChanged(teamID)
	Spring.Echo("Playerlist Window Debug: TeamChanged called, tID "..teamID)
	--TODO
end

function widget:Initialize()
	if (not WG.Chili) then
		widgetHandler:RemoveWidget()
		return
	end

	iAmSpec = Spring.GetSpectatingState()

	Chili = WG.Chili
	Image = Chili.Image
	Button = Chili.Button
	Checkbox = Chili.Checkbox
	Window = Chili.Window
	Panel = Chili.Panel
	ScrollPanel = Chili.ScrollPanel
	StackPanel = Chili.StackPanel
	Label = Chili.Label
	screen0 = Chili.Screen0
	color2incolor = Chili.color2incolor
	incolor2color = Chili.incolor2color
	
	SetupControls()
	--AddTableHeaders()
	ReadAllPlayers()

	--Spring.SendCommands("endgraph 0")
	
	--widgetHandler:RegisterGlobal("PlayerListWindow", PlayerListWindow)
	
	options.visible.value = true
	if UpdateVisibility then UpdateVisibility() end
	
	--SetTeamNamesAndColors()
	
	--if Spring.IsGameOver() then
	--	showEndgameWindowTimer = 1
	--end
	
	if DEBUG then
		debugButton = Button:New{
			height=25;
			width=50;
			x=10;
			bottom=10;
			caption="DEBUG",
			OnClick = {
				function() 
					for id, data in pairs(entities) do
						if data.isAI then
							local skirmishAIID, name, hostingPlayerID, shortName, version, options = Spring.GetAIInfo(data.teamID)
							if (IsMission == false) then
								name = '<'.. name ..'> '.. shortName
							end
							Spring.Echo("Playerlist Window Debug: "..name.." (AI)")
						else
							local name,active,spectator,teamID,allyTeamID,pingTime,cpuUsage,country,rank,customKeys = Spring.GetPlayerInfo(data.playerID)
							local act
							if active then act = "true" else act = "false" end
							Spring.Echo("Playerlist Window Debug: "..name.." (Player) active:"..act.." teamID:"..teamID)
						end
					end
					for id, data in pairs(spectatorEntities) do
						local name,active,spectator,teamID,allyTeamID,pingTime,cpuUsage,country,rank,customKeys = Spring.GetPlayerInfo(data.playerID)
						local act
						if active then act = "true" else act = "false" end
						Spring.Echo("Playerlist Window Debug: "..name.." (Spectator) active:"..act)
					end
				end
			};
			parent = contentHolder;
		}
	end
end

function widget:Shutdown()
	--widgetHandler:DeregisterGlobal("PlayerListWindow")
end

