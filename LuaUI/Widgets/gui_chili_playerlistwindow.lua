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

-- Adapted from Deluxe Player List (created by CarRepairer, KingRaptor, CrazyEddie)

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
local LayoutPanel
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
-- controls for large playerlist window

local window_playerlist
local contentHolder
local contentScrollPanel
local playerListControl
local spectatorListControl
local exitButton
local debugButton

--------------------------------------------------------------------------------
-- variables for entity handling

-- entity = player (NOT including specs), human or AI
-- indexed by numbers mapped to playerID or teamID (if AI) in playerLookup and teamLookup
-- Contains isAI, playerID (if not AI), teamID, allyTeamID, active, resigned, smallControls, windowControls
local entities = {}
local playerLookup = {}
local teamLookup = {}

-- spectatorEntity = player (NOT including specs), human or AI
-- indexed by numbers mapped to playerID in playerSpectatorLookup
-- Contains playerID, active, smallControl, windowControl
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
	plwindow_visible = {
		name = "Visible",
		type = 'bool',
		value = false, --set to false when initialisation is complete
		desc = "Set a hotkey here to toggle the playerlist on and off",
		OnChange = function() UpdateVisibility() end,
	},
	plwindow_backgroundOpacity = {
		name = "Opacity",
		type = "number",
		value = 0.8, min = 0, max = 1, step = 0.01,
	},
	plwindow_showCcr = {
		name = "Show clan/country/rank in playerlist window",
		type = 'bool',
		value = true,
		desc = "Show the clan, country, and rank columns",
		OnChange = function() SetupControls() end,
	},
	plwindow_show_resourceStatus = {
		name = "Show unit and income stats in playerlist window",
		type = 'bool',
		value = true,
		desc = "Display resource statistics: metal in mobile units and static defenses; metal and energy income; current stored resrouces.",
		OnChange = function() SetupControls() end,
	},
	plwindow_show_cpuPing = {
		name = "Show ping and cpu",
		type = 'bool',
		value = true,
		desc = "Show player's ping and cpu",
		OnChange = function() SetupControls() end,
	},
	plwindow_textHeight = {
		name = 'Font Size (10-18)',
		type = 'number',
		value = 13,
		min=10,max=18,step=1,
		OnChange = function() SetupControls() end,
		advanced = true
	},
	plwindow_nameWidth = {
		name = 'Name Width (20-40)',
		type = 'number',
		value = 20,
		min=20,max=40,step=1,
		OnChange = function() SetupControls() end,
		advanced = true
	},
	plwindow_statsWidth = {
		name = 'Metal worth stats width (2-5)',
		type = 'number',
		value = 4,
		min=2,max=5,step=1,
		OnChange = function() SetupControls() end,
		advanced = true
	},
	plwindow_incomeWidth = {
		name = 'Income width (2-5)',
		type = 'number',
		value = 3,
		min=2,max=5,step=1,
		OnChange = function() SetupControls() end,
		advanced = true
	},
	plwindow_cpuPingAsText = {
		name = "Show ping/cpu as text",
		type = 'bool',
		value = false,
		desc = "Show ping and cpu stats as text (vs. as an icon)",
		OnChange = function() SetupPanels() end,
		advanced = true
	},
	plwindow_fancySkinning = {
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
			
			contentScrollPanel.tiles = newClass.tiles
			contentScrollPanel.TileImageFG = newClass.TileImageFG
			--contentScrollPanel.backgroundColor = newClass.backgroundColor
			contentScrollPanel.TileImageBK = newClass.TileImageBK
			contentScrollPanel:Invalidate()
		end,
		advanced = true,
		noHotkey = true,
	},
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- config for window playerlist 

local plwindow_sectionheader_display = true

local plwindow_x_exists

local plwindow_border_slack

local plwindow_x_window_begin
local plwindow_x_ccr_begin
local plwindow_x_ccr_width
local plwindow_x_name_begin
local plwindow_x_name_width
local plwindow_x_playerstate_begin
local plwindow_x_playerstate_width
local plwindow_x_resourcestate_begin
local plwindow_x_resourcestate_width
local plwindow_x_actions_begin
local plwindow_x_actions_width
local plwindow_x_cpuping_begin
local plwindow_x_cpuping_width
local plwindow_x_window_width

local plwindow_x_icon_clan_width
local plwindow_x_icon_country_width
local plwindow_x_icon_rank_width
local plwindow_x_name_width
local plwindow_x_playerstate_width
local plwindow_x_m_mobiles_width
local plwindow_x_m_defense_width
local plwindow_x_m_income_width
local plwindow_x_e_income_width
local plwindow_x_m_fill_width
local plwindow_x_e_fill_width
local plwindow_x_cpu_width
local plwindow_x_ping_width

local plwindow_x_icon_clan_offset
local plwindow_x_icon_country_offset
local plwindow_x_icon_rank_offset
local plwindow_x_name_offset
local plwindow_x_playerstate_offset
local plwindow_x_m_mobiles_offset
local plwindow_x_m_defense_offset
local plwindow_x_m_income_offset
local plwindow_x_e_income_offset
local plwindow_x_m_fill_offset
local plwindow_x_e_fill_offset
local plwindow_x_cpu_offset
local plwindow_x_ping_offset

local plwindow_sectionheader_offset
local plwindow_subsectionheader_offset

local function CalculateWidths()

	plwindow_x_exists = true

	plwindow_border_slack = 15

	plwindow_x_icon_clan_width = 18
	plwindow_x_icon_country_width = 20
	plwindow_x_icon_rank_width = 16
	plwindow_x_name_width = (options.plwindow_nameWidth.value or 20) * options.plwindow_textHeight.value / 2
	plwindow_x_playerstate_width = 20
	plwindow_x_m_mobiles_width = options.plwindow_statsWidth.value * options.plwindow_textHeight.value / 2 + 10
	plwindow_x_m_defense_width = options.plwindow_statsWidth.value * options.plwindow_textHeight.value / 2 + 10
	plwindow_x_m_income_width = options.plwindow_incomeWidth.value * options.plwindow_textHeight.value / 2 + 10
	plwindow_x_e_income_width = options.plwindow_incomeWidth.value * options.plwindow_textHeight.value / 2 + 10
	plwindow_x_m_fill_width = 30
	plwindow_x_e_fill_width = 30
	plwindow_x_cpu_width = options.plwindow_cpuPingAsText.value and 52 or 30
	plwindow_x_ping_width = options.plwindow_cpuPingAsText.value and 46 or 16

	plwindow_x_window_begin = 0
	
	plwindow_x_ccr_begin = plwindow_x_window_begin
	plwindow_x_icon_clan_offset = 0
	plwindow_x_icon_country_offset = plwindow_x_icon_clan_offset + plwindow_x_icon_clan_width
	plwindow_x_icon_rank_offset = plwindow_x_icon_country_offset + plwindow_x_icon_country_width
	plwindow_x_ccr_width = (plwindow_x_icon_rank_offset + plwindow_x_icon_rank_width) or 0
	
	plwindow_x_playerstate_begin = plwindow_x_ccr_begin + (options.plwindow_showCcr.value and plwindow_x_ccr_width or 0)
	plwindow_x_playerstate_offset = 0
	
	plwindow_x_name_begin = plwindow_x_playerstate_begin + plwindow_x_playerstate_width
	plwindow_x_name_offset = 0
	
	plwindow_x_resourcestate_begin = plwindow_x_name_begin + plwindow_x_name_width
	plwindow_x_m_mobiles_offset = 0
	plwindow_x_m_defense_offset = plwindow_x_m_mobiles_offset + plwindow_x_m_mobiles_width
	plwindow_x_m_income_offset = plwindow_x_m_defense_offset + plwindow_x_m_defense_width
	plwindow_x_e_income_offset = plwindow_x_m_income_offset + plwindow_x_m_income_width
	plwindow_x_m_fill_offset = plwindow_x_e_income_offset + plwindow_x_e_income_width
	plwindow_x_e_fill_offset = plwindow_x_m_fill_offset + plwindow_x_m_fill_width
	plwindow_x_resourcestate_width = plwindow_x_e_fill_offset + plwindow_x_e_fill_width
	
	plwindow_x_actions_begin = plwindow_x_resourcestate_begin + (options.plwindow_show_resourceStatus.value and plwindow_x_resourcestate_width or 0)
	plwindow_x_actions_width = 0
	
	plwindow_x_cpuping_begin = plwindow_x_actions_begin + plwindow_x_actions_width
	plwindow_x_cpu_offset = 0
	plwindow_x_ping_offset = plwindow_x_cpu_offset + plwindow_x_cpu_width
	plwindow_x_cpuping_width = plwindow_x_ping_offset + plwindow_x_ping_width
	
	plwindow_x_window_width = plwindow_x_cpuping_begin + (options.plwindow_show_cpuPing.value and plwindow_x_cpuping_width or 0)
	
	plwindow_sectionheader_offset = 20
	plwindow_subsectionheader_offset = 40
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- functions for window playerlist controls

function PLWindow_CreatePlayerControls(entityID)

	local mainControl = Window.New{
		name = "Player Bar "..entityID,
		x = 0,
		y = 0,
		width = plwindow_x_window_width,
		height = options.plwindow_textHeight.value,
		parent = window_playerlist,
	}
	
	return nil
end

function PLWindow_CreateSpectatorControls(entityID)

	local mainControl = Control:New{
		name = "Player Bar (Spectator) "..entityID,
		x = 0,
		y = 0,
		width = plwindow_x_window_width,
		height = options.plwindow_textHeight.value + 4,
		padding = {0, 0, 0, 0},
		color = {0, 0, 0, 0},
		--parent = window_playerlist,
	}
	
	local clanImage = Image:New{x = plwindow_x_ccr_begin + plwindow_x_icon_clan_offset, y = 0, width = plwindow_x_icon_clan_width, height = options.plwindow_textHeight.value, parent = mainControl}
	local countryImage = Image:New{x = plwindow_x_ccr_begin + plwindow_x_icon_country_offset, y = 0, width = plwindow_x_icon_country_width, height = options.plwindow_textHeight.value, parent = mainControl}
	local rankImage = Image:New{x = plwindow_x_ccr_begin + plwindow_x_icon_rank_offset, y = 0, width = plwindow_x_icon_rank_width, height = options.plwindow_textHeight.value, parent = mainControl}
	
	local nameLabel = Label:New{
		name = "Name Label (Spectator) "..entityID,
		x = plwindow_x_name_begin + plwindow_x_name_offset,
		y = 0,
		width = plwindow_x_name_width,
		height = options.plwindow_textHeight.value,
		minWidth  = plwindow_x_window_width,
		minHeight = plwindow_textHeight,
		caption = "Hello!",
		fontsize = options.plwindow_textHeight.value,
		parent = mainControl,
	}
	
	
	
	return { main = mainControl, name = nameLabel, clan = clanImage, country = countryImage, rank = rankImage }
end

-- call this whenever configuration changes (alignment, etc.)
function PLWindow_ArrangePlayerControl()
	
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- functions for window playerlist

-- creates panel
local function PLWindow_SetupControls()
	
	CalculateWidths()
	
	if window_playerlist then
		window_playerlist:Dispose()
	end
	
	window_playerlist = Window:New{  
		name = "PlayerlistWindow",
		x = 0,
		y = 55,
		width  = plwindow_x_window_width + 20,
		height = 450,
		minWidth  = plwindow_x_window_width + 20,
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
		classname = options.plwindow_fancySkinning.value,
		x = 0,
		y = 0,
		right = 0,
		bottom = 0,
		draggable = false,
		resizable = false,
		padding = {0, 0, 0, 0},
		backgroundColor = {1, 1, 1, options.plwindow_backgroundOpacity.value},
		parent = window_playerlist,
	}
	
	contentScrollPanel = ScrollPanel:New{
		classname = 'panel',
		x = 10,
		y = 10,
		right = 10,
		bottom = 45,
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
	
	playerListControl = Control:New{
		name = "Player List Control",
		x = 0,
		y = 0,
		width = plwindow_x_window_width,
		bottom = 0,
		--padding = {0, 0, 0, 0},
		--color = {0, 0, 0, 0},
		parent = contentScrollPanel,
	}
	
	spectatorListControl = Control:New{
		name = "Spectator List Control",
		x = 0,
		y = 0,
		width = plwindow_x_window_width,
		bottom = 0,
		--padding = {0, 0, 0, 0},
		--color = {0, 0, 0, 0},
		parent = contentScrollPanel,
	}
	
	if plwindow_sectionheader_display then
		
		headerHeight =  options.plwindow_textHeight.value * 1.8 + 8
		
		playerListControl.bottom = playerListControl.bottom + headerHeight
		
		local playerSectionHeader = Label:New{
		name = "Player Section Header",
		x = plwindow_sectionheader_offset,
		y = 0,
		width = plwindow_x_name_width,
		height = headerHeight,
		caption = "Players",
		fontsize = options.plwindow_textHeight.value * 1.8,
		parent = playerListControl,
		}
		
		spectatorListControl.y = playerListControl.bottom
		
		spectatorListControl.bottom = spectatorListControl.bottom + headerHeight
		
		local spectatorSectionHeader = Label:New{
		name = "Spectator Section Header",
		x = plwindow_sectionheader_offset,
		y = 0,
		width = plwindow_x_name_width,
		height = headerHeight,
		caption = "Spectators",
		fontsize = options.plwindow_textHeight.value * 1.8,
		parent = spectatorListControl,
		}
		
	end
end

--TODO
local function PLWindow_DisplayPlayers()
	local yCoordinate = spectatorListControl.bottom
	for id, i in pairs(spectatorLookup) do
		spectatorEntities[i].windowControls.main.y = yCoordinate
		spectatorListControl:AddChild(spectatorEntities[i].windowControls.main)
		yCoordinate = yCoordinate + spectatorEntities[i].windowControls.main.height
	end
	spectatorListControl.bottom = yCoordinate
end

-- Puts the headers at the top of the panel.
-- local function AddTableHeaders()
	-- local fontsize = options.text_height.value
	-- local row = 0
	-- if options.show_resource_status.value then
		-- contentScrollPanel:AddChild( Image:New{ x=x_m_mobiles + x_m_mobiles_width/2 -5, y=5,	height = (fontsize)+1, color =	{1, .3, .3, 1},  file = 'LuaUI/Images/commands/Bold/attack.png',} )
		-- contentScrollPanel:AddChild( Image:New{ x=x_m_defense + x_m_defense_width/2 -5, y=5,	height = (fontsize)+1, color = {.3, .3, 1, 1}, file = 'LuaUI/Images/commands/Bold/guard.png',} )
		-- contentScrollPanel:AddChild( Image:New{ x=x_e_income + x_e_income_width/2 -7, y=5,	height = (fontsize)+1,  file = 'LuaUI/Images/energy.png',} )
		-- contentScrollPanel:AddChild( Image:New{ x=x_m_income + x_m_income_width/2 -7, y=5,	height = (fontsize)+1, file = 'LuaUI/Images/ibeam.png',} )
	-- end
	-- if options.show_cpu_ping.value then
		-- contentScrollPanel:AddChild( Label:New{ x=x_cpu, y=5,	caption = 'C', 	fontShadow = true,  fontsize = fontsize,} )
		-- contentScrollPanel:AddChild( Label:New{ x=x_ping, y=5,	caption = 'P', 	fontShadow = true,  fontsize = fontsize,} )
	-- end
-- end

function PLWindow_UpdateVisibility()
	if screen0 and window_playerlist then
		if options.plwindow_visible.value then
			screen0:AddChild(window_playerlist)
		else
			screen0:RemoveChild(window_playerlist)
		end
	end
end

function PLWindow_Toggle()
	options.plwindow_visible.value = not options.plwindow_visible.value
	if UpdateVisibility then UpdateVisibility() end
end

WG.TogglePlayerlistWindow = PLWindow_Toggle -- called by global commands widget

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- config for small playerlist display



--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- functions for small playerlist controls

function PLSmall_CreatePlayerControl()
	return nil
end

-- call this whenever configuration changes (alignment, etc.)
function PLSmall_ArrangePlayerControl()
	
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- functions for small playerlist display

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- functions for entity handling

function CreateEntity(eID, ai, pID, tID, atID, act)
	local entity = { isAI = ai, playerID = pID, teamID = tID, allyTeamID = atID, active = act, resigned = false, smallControl = nil, windowControl = nil}
	return entity
end

function CreateSpectatorEntity(eID, pID, act)
	local entity = { playerID = pID, active = act, smallControls = nil, windowControls = PLWindow_CreateSpectatorControls(eID)}
	--entity = { playerID = pID, active = act, smallControls = nil, windowControls = nil}
	return entity
end

function CreateAllyteamEntity(eID, atID)
	local entity = { allyteamID = atID, smallControls = nil, windowControls = nil}
	return entity
end

function AddHumanEntity(playerID)
	if playerID then
		local name,active,spectator,teamID,allyTeamID,pingTime,cpuUsage,country,rank,customKeys = Spring.GetPlayerInfo(playerID)
		
		local clan, faction, level, elo, wins
		if customKeys then
			clan = customKeys.clan
			faction = customKeys.faction
			level = customKeys.level
			elo = customKeys.elo
		end
		
		local clanicon, rankicon, countryicon
		if clan and clan ~= "" then 
			clanicon = "LuaUI/Configs/Clans/" .. clan ..".png"
		elseif faction and faction ~= "" then
			clanicon = "LuaUI/Configs/Factions/" .. faction ..".png"
		end
		local countryicon = country and country ~= '' and country ~= '??' and "LuaUI/Images/flags/" .. (country) .. ".png" or nil
		if level and level ~= "" and elo and elo ~= "" then 
			local trelo, xp = Spring.Utilities.TranslateLobbyRank(tonumber(elo), tonumber(level))
			rankicon = "LuaUI/Images/LobbyRanks/" .. xp .. "_" .. trelo .. ".png"
		end
		
		if spectator then
			local i = #spectatorEntities + 1
			spectatorEntities[i] = CreateSpectatorEntity(i, playerID, active)
			spectatorLookup[playerID] = i
			
			spectatorEntities[i].windowControls.name.caption = name 
			if clanicon then spectatorEntities[i].windowControls.clan.file = clanicon end
			if countryicon then spectatorEntities[i].windowControls.country.file = countryicon end 
			if rankicon then spectatorEntities[i].windowControls.rank.file = rankicon end
			
		else
			local i = #entities + 1
			entities[i] = CreateEntity(i, false, playerID, teamID, allyTeamID, active)
			playerLookup[playerID] = i
		end
	end
end

function AddAIEntity(teamID)
	if teamID then
		local skirmishAIID, name, hostingPlayerID, shortName, version, options = Spring.GetAIInfo(teamID)
		local _,leader,isDead,isAI,side,allyTeamID,customTeamKeys,incomeMultiplier = Spring.GetTeamInfo(teamID)
		local i = #entities + 1
		entities[i] = CreateEntity(i, true, nil, teamID, allyTeamID, nil)
		teamLookup[teamID] = i
	end
end

function AddAllyteamEntity(allyTeamID)
	if allyTeamID then
		local customTeamKeys = Spring.GetAllyTeamInfo(allyTeamID) --????
		allyteamEntities[allyteamID] = CreateAllyteamEntity(i, allyTeamID)
	end
end

local function ReadAllPlayers()
	CalculateWidths()
	
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
		--AddAllyteamEntity(allyTeamID)
	end
	
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- functions for entity updating

local function CheckPlayer(playerID)
	local name,active,spectator,teamID,allyTeamID,pingTime,cpuUsage,country,rank,customKeys = Spring.GetPlayerInfo(playerID)
	
	if playerLookup[playerID] then
		if spectator and not entities[playerLookup[playerID]].resigned then
			--this player has resigned
			entities[playerLookup[playerID]].resigned = true
		end
		if active ~= entities[playerLookup[playerID]].active then
			--this player has changed activity
			entities[playerLookup[playerID]].active = active
		end
		if teamID ~= entities[playerLookup[playerID]].teamID then
			--this player has changed teamID
			entities[playerLookup[playerID]].teamID = teamID
		end
		if allyTeamID ~= entities[playerLookup[playerID]].allyTeamID then
			--this player has changed allyTeamID
			entities[playerLookup[playerID]].allyTeamID = allyTeamID
		end
	end
	
	if spectatorLookup[playerID] then
		if active ~= spectatorEntities[spectatorLookup[playerID]].active then
			--this spectator has changed activity
			spectatorEntities[spectatorLookup[playerID]].active = active
		end
	end
end

local function CheckTeam(teamID)
	local _,leader,isDead,isAI,side,allyTeamID,customTeamKeys,incomeMultiplier = Spring.GetTeamInfo(teamID)
	
	if teamLookup[teamID] then
		local skirmishAIID, name, hostingPlayerID, shortName, version, options = Spring.GetAIInfo(teamID)
		if isDead and not entities[teamLookup[playerID]].resigned then
			--this team is dead/resigned
		end
		if allyTeamID ~= entities[teamLookup[playerID]].allyTeamID then
			--this team has changed allyTeamID
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- functions for updating entity controls with current status

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
	
	if playerLookup[playerID] or spectatorLookup[playerID] then --sanity check; do we already have this player?
		CheckPlayer(playerID)
	else
		AddHumanEntity(playerID)
	end
end

function widget:PlayerAdded(playerID)
	Spring.Echo("Playerlist Window Debug: PlayerAdded called, pID "..playerID)
	
	if playerLookup[playerID] or spectatorLookup[playerID] then --sanity check; do we already have this player?
		CheckPlayer(playerID)
	else
		AddHumanEntity(playerID)
	end
end

function widget:PlayerRemoved(playerID)
	Spring.Echo("Playerlist Window Debug: PlayerRemoved called, pID "..playerID)
	
	if playerLookup[playerID] or spectatorLookup[playerID] then --sanity check; do we already have this player?
		CheckPlayer(playerID)
	end
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
	LayoutPanel = Chili.LayoutPanel
	Label = Chili.Label
	Control = Chili.Control
	screen0 = Chili.Screen0
	color2incolor = Chili.color2incolor
	incolor2color = Chili.incolor2color
	
	CalculateWidths()
	ReadAllPlayers()
	PLWindow_SetupControls()
	PLWindow_DisplayPlayers()
	--AddTableHeaders()
	

	--Spring.SendCommands("endgraph 0")
	
	--widgetHandler:RegisterGlobal("PlayerListWindow", PlayerListWindow)
	
	options.plwindow_visible.value = true
	if PLWindow_UpdateVisibility then PLWindow_UpdateVisibility() end
	
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
							Spring.Echo("Playerlist Window Debug: "..name.." (Player) active:"..act.." teamID:"..teamID.." allyTeamID:"..allyTeamID)
						end
					end
					for id, data in pairs(spectatorEntities) do
						local name,active,spectator,teamID,allyTeamID,pingTime,cpuUsage,country,rank,customKeys = Spring.GetPlayerInfo(data.playerID)
						local act
						if active then act = "true" else act = "false" end
						Spring.Echo("Playerlist Window Debug: "..name.." (Spectator) active:"..act.." teamID:"..teamID.." allyTeamID:"..allyTeamID)
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

