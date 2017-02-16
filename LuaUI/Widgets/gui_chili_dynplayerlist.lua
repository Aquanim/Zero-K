--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Chili Dynamic Player List",
    desc      = "vX.XXX Dynamic Player List. Displays list of players with relevant information.",
    author    = "Aquanim",
    date      = "2018-11-13",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = false,
  }
end

-- Adapted from Deluxe Player List v0.210 by CarRepairer, KingRaptor, CrazyEddie
-- (which was based on v1.31 Chili Crude Player List by CarRepairer, KingRaptor, et al)
-- and from Chili Share Menu v1.24 by _Shaman and DeinFreund

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
VFS.Include("LuaRules/Configs/constants.lua")
VFS.Include("LuaRules/Utilities/lobbyStuff.lua")

local spSendCommands			= Spring.SendCommands

local echo = Spring.Echo

local Chili
local Line
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

local cpuPic		  = ":n:"..LUAUI_DIRNAME.."Images/playerlist/cpu.png"
local pingPic		  = ":n:"..LUAUI_DIRNAME.."Images/playerlist/ping.png"

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
local myTeam = 0
local myAllyTeam = 0
local myID
local myName
local iAmSpec
local drawTeamnames

--------------------------------------------------------------------------------
-- controls for large playerlist window

local plw_windowPlayerlist
local plw_contentHolder
local plw_vcon_scrollPanel
local plw_vcon_playerList
local plw_vcon_spectatorList
local plw_vcon_playerHeader
local plw_vcon_spectatorHeader
local plw_exitButton
local plw_debugButton

local plw_vcon_playerControls = {}
local plw_vcon_spectatorControls = {}
local plw_vcon_teamControls = {}
local plw_vcon_allyTeamControls = {}
local plw_vcon_allyTeamBarControls = {}

--------------------------------------------------------------------------------
-- variables for entity handling

-- entity = player (NOT including specs), human or AI
-- indexed by numbers mapped to playerID or teamID (if AI) in humanLookup and aiLookup
-- Contains isAI, playerID (if not AI), teamID, allyTeamID, active, resigned TODO update this
local playerEntities = {}
local humanLookup = {}
local aiLookup = {}

-- spectatorEntity = player (NOT including specs), human or AI
-- indexed by numbers mapped to playerID in playerSpectatorLookup
-- Contains playerID, active TODO update this
local spectatorEntities = {}
local spectatorLookup = {}

--
local teamEntities = {}

-- allyTeamEntities = groups of allied players
-- indexed by allyTeamID TODO update this
local allyTeamEntities = {}

local playerlistNeedsFullVisUpdate = false
local speclistNeedsFullVisUpdate = false

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
-- utility functions

local function FormatMetalStats(stat)
	--return stat < 1000 and string.format("%.0f", stat) or string.format("%.1f", stat/1000) .. "k"
	return stat < 1000 and " " .. string.format("%.0f", stat) or string.format("%.1f", stat/1000) .. "k"
end

local function FormatIncomeStats(stat)
	--return stat < 1000 and string.format("%." .. (0) .. "f",stat) or string.format("%.1f", stat/1000) .. "k"
	return stat < 1000 and " " .. string.format("%." .. (0) .. "f",stat) or string.format("%.1f", stat/1000) .. "k"
end


local function SafeAddChild(child, parent)
	if child and parent then
		if child.parent then
			child.parent:RemoveChild(child)
		end
		parent:AddChild(child)
	end
end

local function FormatPingCpu(ping,cpu)
	-- guard against being called with nils
	ping = ping or 0
	cpu = cpu or 0
	-- guard against silly values
	ping = math.max(math.min(ping,999),0)
	cpu = math.max(math.min(cpu,9.99),0)

	local pingMult = 2/3	-- lower = higher ping needed to be red
	local pingCpuColors = {
		{0, 1, 0, 1},
		{0.7, 1, 0, 1},
		{1, 1, 0, 1},
		{1, 0.6, 0, 1},
		{1, 0, 0, 1}
	}

	local pingCol = pingCpuColors[ math.ceil( math.min(ping * pingMult, 1) * 5) ] or {.85,.85,.85,1}
	local cpuCol = pingCpuColors[ math.ceil( math.min(cpu, 1) * 5 ) ] or {.85,.85,.85,1}

	local pingText
	if ping < 1 then
		pingText = (math.floor(ping*1000) ..'ms')
	else
		pingText = ('' .. (math.floor(ping*100)/100)):sub(1,4) .. 's'
	end

	local cpuText = math.round(cpu*100) .. '%'
	
	return pingCol,cpuCol,pingText,cpuText
end

local function FormatCCR(clan, faction, country, level, elo, rank)
	local clanicon, countryicon, rankicon
	if clan and clan ~= "" then 
		clanicon = "LuaUI/Configs/Clans/" .. clan ..".png"
	elseif faction and faction ~= "" then
		clanicon = "LuaUI/Configs/Factions/" .. faction ..".png"
	end
	local countryicon = country and country ~= '' and country ~= '??' and "LuaUI/Images/flags/" .. (country) .. ".png" or nil
	if level and level ~= "" and elo and elo ~= "" then 
		--local trelo, xp = Spring.Utilities.TranslateLobbyRank(tonumber(elo), tonumber(level))
		--rankicon = "LuaUI/Images/LobbyRanks/" .. xp .. "_" .. trelo .. ".png"
		rankicon = "LuaUI/Images/LobbyRanks/" .. (rank or "0_0") .. ".png"
	end
	return clanicon, countryicon, rankicon
end

local function FormatStatus(active, resigned, cpu, teamUnitCount)
	local teamStatusCol = {1,1,1,1}
	local teamStatusText = ''
	local playerVacant = false
	
	if not active then
		if (Spring.GetGameSeconds() and Spring.GetGameSeconds() < 0.1) or (cpuUsage and cpuUsage > 1) then 
			teamStatusText = '?'
			teamStatusCol = {1,1,0,1}
		else 
			playerStatusText = "xx:"
			playerVacant = true
		end
	--elseif spectator and (teamID ~= 0 or teamZeroPlayers[playerID]) then
	elseif resigned then
		playerStatusText = "ss:"
		playerVacant = true
	end

	if playerVacant then
		if teamUnitCount > 0  then
			teamStatusText = '!'
			teamStatusCol = {1,1,0,1}
		else
			teamStatusText = 'X'
			teamStatusCol = {1,0,0,1}
		end
	end

	return teamStatusCol, teamStatusText, playerStatusText
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- config for window playerlist 

local plw_sectionheader_display

local plw_playerbar_added_height

local plw_border_slack

local plw_y_buffer

local plw_headerTextHeight

local plw_x_window_begin
local plw_x_ccr_begin
local plw_x_ccr_width
local plw_x_name_begin
local plw_x_name_width
local plw_x_playerstate_begin
local plw_x_playerstate_width
local plw_x_resourcestate_begin
local plw_x_resourcestate_width
local plw_x_actions_begin
local plw_x_actions_width
local plw_x_cpuping_begin
local plw_x_cpuping_width
local plw_x_window_width

local plw_x_icon_clan_width
local plw_x_icon_country_width
local plw_x_icon_rank_width
local plw_x_name_width
local plw_x_playerstate_width
local plw_x_m_mobiles_width
local plw_x_m_defense_width
local plw_x_m_income_width
local plw_x_e_income_width
local plw_x_m_fill_width
local plw_x_e_fill_width
local plw_x_cpu_width
local plw_x_ping_width

local plw_x_icon_clan_offset
local plw_x_icon_country_offset
local plw_x_icon_rank_offset
local plw_x_name_offset
local plw_x_playerstate_offset
local plw_x_m_mobiles_offset
local plw_x_m_defense_offset
local plw_x_m_income_offset
local plw_x_e_income_offset
local plw_x_m_fill_offset
local plw_x_e_fill_offset
local plw_x_cpu_offset
local plw_x_ping_offset

local plw_sectionheader_offset
local plw_subsectionheader_offset

local plw_x_name_spectator_width
local plw_x_playerstate_spectator_width
local plw_x_cpuping_spectator_width
local plw_x_actions_spectator_width

local plw_x_name_spectator_begin
local plw_x_name_spectator_offset
local plw_x_playerstate_spectator_begin
local plw_x_playerstate_spectator_offset
local plw_x_playerstate_actions_begin
local plw_x_cpuping_spectator_begin
local plw_x_cpu_spectator_offset
local plw_x_ping_spectator_offset

local plw_linebuffer

local plw_header_icon_width
local plw_header_icon_height
local plw_x_mobile_icon
local plw_x_defence_icon
local plw_x_metal_icon
local plw_x_energy_icon
local plw_x_cpu_icon
local plw_x_ping_icon

local plw_y_endbuffer

local function PLW_CalculateDimensions()

	plw_sectionheader_display = true

	plw_playerbar_text_height = options.plw_textHeight.value
	plw_playerbar_image_height = options.plw_textHeight.value + 2
	plw_playerbar_height = plw_playerbar_text_height + 4
	plw_playerbar_text_y = 2
	plw_headerTextHeight = math.floor(options.plw_textHeight.value * 1.8)

	plw_border_slack = 15
	
	plw_y_buffer = 7

	plw_x_icon_clan_width = 22
	plw_x_icon_country_width = 24
	plw_x_icon_rank_width = 20
	plw_x_name_width = 18 * options.plw_textHeight.value / 2
	plw_x_playerstate_width = 20
	plw_x_m_mobiles_width = 5 * options.plw_textHeight.value / 2 + 10
	plw_x_m_defense_width = 5 * options.plw_textHeight.value / 2 + 10
	plw_x_m_income_width = 5 * options.plw_textHeight.value / 2 + 10
	plw_x_e_income_width = 5 * options.plw_textHeight.value / 2 + 10
	plw_x_m_fill_width = 30
	plw_x_e_fill_width = 30
	plw_x_cpu_width = options.plw_cpuPingAsText.value and 30 or 20
	plw_x_ping_width = options.plw_cpuPingAsText.value and 44 or 20

	plw_x_window_begin = 0
	
	plw_x_ccr_begin = plw_x_window_begin
	plw_x_icon_clan_offset = 0
	--plw_x_icon_country_offset = plw_x_icon_clan_offset + plw_x_icon_clan_width
	plw_x_icon_country_offset = plw_x_icon_clan_offset + plw_x_icon_clan_width - plw_x_icon_country_width
	plw_x_icon_rank_offset = plw_x_icon_country_offset + plw_x_icon_country_width
	plw_x_ccr_width = (plw_x_icon_rank_offset + plw_x_icon_rank_width + 5) or 0
	
	plw_x_name_offset = 0
	plw_x_name_begin = plw_x_ccr_begin + (options.plw_showCcr.value and plw_x_ccr_width or 0)
	
	plw_x_playerstate_begin = plw_x_name_begin + plw_x_name_width
	plw_x_playerstate_offset = 0
	
	plw_x_resourcestate_begin = plw_x_playerstate_begin + plw_x_playerstate_width
	plw_x_m_mobiles_offset = 0
	plw_x_m_defense_offset = plw_x_m_mobiles_offset + plw_x_m_mobiles_width + 5
	plw_x_m_income_offset = plw_x_m_defense_offset + plw_x_m_defense_width + 5
	plw_x_m_fill_offset = plw_x_m_income_offset + plw_x_m_income_width + 5
	plw_x_e_income_offset = plw_x_m_fill_offset + plw_x_m_fill_width + 5
	plw_x_e_fill_offset = plw_x_e_income_offset + plw_x_e_income_width + 5
	plw_x_resourcestate_width = plw_x_e_fill_offset + plw_x_e_fill_width + 5
	
	plw_x_actions_begin = plw_x_resourcestate_begin + (options.plw_show_resourceStatus.value and plw_x_resourcestate_width or 0)
	plw_x_actions_width = 0
	
	plw_x_cpuping_begin = plw_x_actions_begin + plw_x_actions_width
	plw_x_cpu_offset = 0
	plw_x_ping_offset = plw_x_cpu_offset + plw_x_cpu_width + 5
	plw_x_cpuping_width = plw_x_ping_offset + plw_x_ping_width
	
	plw_x_window_width = plw_x_cpuping_begin + (options.plw_show_cpuPing.value and plw_x_cpuping_width or 0)
	
	plw_x_name_spectator_begin = plw_x_window_begin
	plw_x_name_spectator_offset = 10
	plw_x_name_spectator_width = 18 * options.plw_textHeight.value / 2 + plw_x_name_spectator_offset
	
	plw_x_playerstate_spectator_begin = plw_x_name_spectator_begin + plw_x_name_spectator_width
	plw_x_playerstate_spectator_offset = 0
	plw_x_playerstate_spectator_width = 0
	
	plw_x_actions_spectator_begin = plw_x_playerstate_spectator_begin + plw_x_playerstate_spectator_width
	plw_x_actions_spectator_width = 0
	
	plw_x_cpuping_spectator_begin = plw_x_actions_spectator_begin + plw_x_actions_spectator_width
	plw_x_cpu_spectator_offset = 0
	plw_x_ping_spectator_offset = plw_x_cpu_spectator_offset + plw_x_cpu_width
	plw_x_cpuping_spectator_width = plw_x_ping_spectator_offset + plw_x_ping_width
	
	PLW_CalculateDimensions_P2()
end

function PLW_CalculateDimensions_P2()
	plw_sectionheader_offset = 20
	plw_subsectionheader_offset = 40
	
	plw_linebuffer = 6
	
	plw_header_icon_width = plw_playerbar_image_height
	plw_header_icon_height = plw_playerbar_image_height
	plw_x_metal_icon = plw_x_resourcestate_begin + (plw_x_m_income_offset + plw_x_m_fill_offset + plw_x_m_fill_width - plw_header_icon_width) * 0.5
	plw_x_energy_icon = plw_x_resourcestate_begin + (plw_x_e_income_offset + plw_x_e_fill_offset + plw_x_e_fill_width - plw_header_icon_width) * 0.5
	plw_x_mobile_icon = plw_x_resourcestate_begin + plw_x_m_mobiles_offset + (plw_x_m_mobiles_width - plw_header_icon_width) * 0.5
	plw_x_defence_icon = plw_x_resourcestate_begin + plw_x_m_defense_offset + (plw_x_m_defense_width - plw_header_icon_width) * 0.5
	plw_x_cpu_icon = plw_x_cpuping_begin + plw_x_cpu_offset + ( plw_x_cpu_width - plw_header_icon_width) * 0.5
	plw_x_ping_icon = plw_x_cpuping_begin + plw_x_ping_offset + ( plw_x_ping_width - plw_header_icon_width) * 0.5
	
	plw_y_endbuffer = 80
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- functions for managing vertically-stacked controls

--Defining all these nils is pointless, but they explain what a VControl *should* eventually have.
--vID is NOT a unique identifier; for a team Vcon it is the teamID, etc.
local function CreateVcon(id, m, s, tb, bb)
	return { vID = id, main = m, subcon = s, parent = nil, above = nil, below = nil, firstChild = nil, lastChild = nil, topBuffer = tb, bottomBuffer = bb, isOuterScrollPanel = nil }
end

-- puts all vcons below the changed one in their correct y-position
local function RealignVcons(changed)
	local vcontrol = changed
	
	local bbabove = vcontrol.above and vcontrol.above.bottomBuffer or 0
	local ub = vcontrol.topBuffer or 0
	local bb = vcontrol.bottomBuffer or 0
	local ubbelow = vcontrol.below and vcontrol.below.topBuffer or 0
	
	if vcontrol.above then 
		vcontrol.main:SetPos(vcontrol.main.x, vcontrol.above.main.y + vcontrol.above.main.height + bbabove + ub, vcontrol.main.width, vcontrol.main.height)
	elseif vcontrol.parent then
		vcontrol.main:SetPos(vcontrol.main.x, ub, vcontrol.main.width, vcontrol.main.height)
	end
	local continue = true
	while continue do
		bbabove = vcontrol.above and vcontrol.above.bottomBuffer or 0
		ub = vcontrol.topBuffer or 0
		bb = vcontrol.bottomBuffer or 0
		ubbelow = vcontrol.below and vcontrol.below.topBuffer or 0
		if vcontrol.below then
			vcontrol.below.main:SetPos(vcontrol.below.main.x, vcontrol.main.y + vcontrol.main.height + bb + ubbelow ,vcontrol.below.main.width, vcontrol.below.main.height)
			vcontrol = vcontrol.below
		elseif (not vcontrol.parent) or (vcontrol.parent.isOuterScrollPanel) then 
			continue = false
		else
			vcontrol.parent.main:SetPos(vcontrol.parent.main.x, vcontrol.parent.main.y, vcontrol.parent.main.width, vcontrol.parent.lastChild.main.y + vcontrol.parent.lastChild.main.height + bb)
			vcontrol = vcontrol.parent
		end
	end
end

-- removes a vcon
local function RemoveVcon(target)
	if (not target) then Spring.Echo ("ERROR RemoveVcon Nil Target"); return end
	if (not target.parent) then Spring.Echo ("ERROR RemoveVcon Nil Parent"); return end
	local parent = target.parent
	if parent then
		if target == parent.firstChild then
			parent.firstChild = target.below
		end
		if target == target.parent.lastChild then
			parent.lastChild = target.above
		end
	end
	if target.below then
		target.below.above = target.above
	end
	if target.above then
		target.above.below = target.below
	end
	target.parent = nil
	target.above = nil
	target.below = nil
	if parent.firstChild then RealignVcons(parent.firstChild) end
end

-- inserts a new vcon as the first child of a parent
local function InsertTopVconChild(new, parent)
	if (not new) or (not parent) then Spring.Echo ("ERROR InsertTopVconChild"); return end
	new.below = parent.firstChild
	new.above = nil
	new.parent = parent
	if new.below then new.below.above = new end
	parent.firstChild = new
	if (not parent.lastChild) then parent.lastChild = new end
	RealignVcons(new)
end

-- inserts a new vcon as the last child of a parent
local function InsertBottomVconChild(new, parent)
	if (not new) or (not parent) then Spring.Echo ("ERROR InsertBottomVconChild"); return end
	new.above = parent.lastChild
	new.below = nil
	new.parent = parent
	if new.above then new.above.below = new end
	parent.lastChild = new
	if (not parent.firstChild) then parent.firstChild = new end
	RealignVcons(new)
end

-- inserts a new vcon before some other one
local function InsertVconBefore(new, nextCon)
	if (not new) or (not parent) then Spring.Echo ("ERROR InsertVconBefore"); return end
	new.parent = nextCon.parent
	new.below = nextCon
	new.above = nextCon.above
	if new.above then new.above.below = new end
	new.below.above = new
	if new.parent.firstChild == nextCon then new.parent.firstChild = new end
	RealignVcons(new)
end

-- switch a vcon with the one below it
local function SwitchVconDown(moving)
	if (not moving) or (not moving.below) then Spring.Echo ("ERROR SwitchVconDown"); return end
	local pos1, pos2, pos3, pos4
	pos1 = moving.above
	pos3 = moving
	pos2 = moving.below
	pos4 = moving.below.below
	if pos1 then pos1.below = pos2 end
	pos2.above = pos1
	pos2.below = pos3
	pos3.above = pos2
	pos3.below = pos4
	if pos4 then pos4.above = pos3 end
	if moving.parent.firstChild == pos3 then moving.parent.firstChild = pos2 end
	if moving.parent.lastChild == pos2 then moving.parent.lastChild = pos3 end
	RealignVcons(pos2)
end

-- sorts a single vcon down or up
local function SortSingleVcon(startVCon, endVCon, SwapFunction, sortUpwards, stopAtFirstFail)
	-- SwapFunction should return true if the first should NOT be above the second.
	local vcon = startVCon
	if vcon then
		local nextVCon = sortUpwards and vcon.above or vcon.below
		local continue = true
		while vcon and nextVCon and nextVCon ~= endVCon and continue do
			if sortUpwards then
				if SwapFunction(nextVCon, vcon) then
					SwitchVconDown(nextVCon)
				else
					vcon = nextVCon
					if stopAtFirstFail then continue = false end
				end
				nextVCon = vcon.above
			else
				if SwapFunction(vcon, nextVCon) then
					SwitchVconDown(vcon)
				else
					vcon = nextVCon
					if stopAtFirstFail then continue = false end
				end
				nextVCon = vcon.below
			end
		end
	end
	return vcon
end

-- performs a bubble sort on vcons
local function SortVcons(startVCon, SwapFunction, sortUpwards)
	-- SwapFunction should return true if the first should NOT be above the second.
	local vcon = startVCon
	local endcon = nil
	while vcon ~= endcon do
		endcon = SortSingleVcon(vcon, endcon, SwapFunction, sortUpwards, false)
		vcon = startVCon
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- functions for managing player/spectatorbars

local function PLW_AutoSetHeight()
	local height = plw_vcon_scrollPanel.lastChild.main.y + plw_vcon_scrollPanel.lastChild.main.height + plw_y_endbuffer
	if not height or height > (plw_maxWindowHeight or 600) then height = (plw_maxWindowHeight or 600) end
	plw_windowPlayerlist:SetPos(plw_windowPlayerlist.x, plw_windowPlayerlist.y, plw_windowPlayerlist.width,height)
end

-- updates the contents of main panels
local function PLW_UpdateStatePlayerListControl()
	if not plw_vcon_playerList then
		return
	end
	
	for atID, _ in pairs(allyTeamEntities) do
		local allyTeamVCon = plw_vcon_allyTeamControls[atID]
		if allyTeamVCon and allyTeamVCon.parent ~= plw_vcon_playerList then
			if allyTeamVCon.parent then
				-- TODO remove from ???
			end
			SafeAddChild(plw_vcon_allyTeamControls[atID].main, plw_vcon_playerList.main)
			--plw_vcon_playerList.main:AddChild(plw_vcon_allyTeamControls[atID].main)
			InsertBottomVconChild(plw_vcon_allyTeamControls[atID], plw_vcon_playerList)
			SortSingleVcon(plw_vcon_allyTeamControls[atID], nil, PLW_CompareAllyTeamVcons, true, true)
		end
	end
end

local function PLW_UpdateStateSpectatorListControl()
	if not plw_vcon_spectatorList then
		return
	end

	local nSpectators = 0
	for id, eID in pairs(spectatorLookup) do
		nSpectators = nSpectators + 1
	end
	if nSpectators > 0 then
		if not plw_vcon_spectatorHeader.main.parent then
			SafeAddChild(plw_vcon_spectatorHeader.main,plw_vcon_spectatorList.main)
			InsertTopVconChild(plw_vcon_spectatorHeader,plw_vcon_spectatorList)
		end
	else
		if plw_vcon_spectatorHeader.main.parent then
			plw_vcon_spectatorList.main:RemoveChild(plw_vcon_spectatorHeader.main)
			RemoveVcon(plw_vcon_spectatorHeader)
		end
	end
	
	for id, eID in pairs(spectatorLookup) do
		local specVCon = plw_vcon_spectatorControls[eID]
		if specVCon and specVCon.parent ~= plw_vcon_spectatorList then
			if specVCon.parent then
				-- TODO remove from ???
			end
			SafeAddChild(plw_vcon_spectatorControls[eID].main,plw_vcon_spectatorList.main)
			--plw_vcon_spectatorList.main:AddChild(plw_vcon_spectatorControls[eID].main)
			InsertBottomVconChild(plw_vcon_spectatorControls[eID],plw_vcon_spectatorList)
			SortSingleVcon(plw_vcon_spectatorControls[eID], nil, PLW_CompareSpectatorVcons, true, true)
		end
	end
	
	
end


-- configures main panels and other stuff that doesn't move
local function PLW_ConfigureStaticControls()

	PLW_CalculateDimensions()
	
	if plw_windowPlayerlist then 
		plw_windowPlayerlist:SetPos(0, 55, plw_x_window_width + 30, 160)
		plw_windowPlayerlist.minWidth = plw_x_window_width + 40
		plw_windowPlayerlist.maxWidth = plw_x_window_width + 40
		plw_windowPlayerlist.minHeight = 160
		SafeAddChild(plw_windowPlayerlist, screen0)
		--screen0:AddChild(plw_windowPlayerlist)
	end
	
	if plw_contentHolder then
		plw_contentHolder.backgroundColor = {1, 1, 1, options.plw_backgroundOpacity.value}
	end
	
	if plw_vcon_scrollPanel.main then
		
		local playerHeaderHeight = plw_headerTextHeight + plw_playerbar_image_height
		local specHeaderHeight = plw_headerTextHeight + plw_y_buffer
		
		if plw_vcon_playerList.main then
			
			plw_vcon_playerList.main:SetPos(0,plw_y_buffer,plw_x_window_width,0)
			--plw_vcon_scrollPanel.main:AddChild(plw_vcon_playerList.main)
			SafeAddChild(plw_vcon_playerList.main, plw_vcon_scrollPanel.main)
			InsertBottomVconChild(plw_vcon_playerList,plw_vcon_scrollPanel)
			if plw_sectionheader_display then
				--if plw_vcon_playerHeader.main then plw_vcon_playerHeader.main:Dispose() end
				local phmain = plw_vcon_playerHeader.main
				local phtitle = plw_vcon_playerHeader.subcon.title
				local aa = plw_vcon_playerHeader.subcon.aIcon
				local dd = plw_vcon_playerHeader.subcon.dIcon
				local mm = plw_vcon_playerHeader.subcon.mIcon
				local ee = plw_vcon_playerHeader.subcon.eIcon
				local cc = plw_vcon_playerHeader.subcon.cpuIcon
				local pp = plw_vcon_playerHeader.subcon.pingIcon
				if phmain and phtitle then 
					phmain:SetPos(0,0,plw_x_window_width,playerHeaderHeight)
					phtitle:SetPos(plw_sectionheader_offset,0,plw_x_name_width,headerHeight)
					phtitle:SetCaption("Players")
					SafeAddChild(phtitle,phmain)
					SafeAddChild(phmain, plw_vcon_playerList.main)
				end
				if aa then 
					aa:SetPos(plw_x_mobile_icon,plw_headerTextHeight,plw_header_icon_width,plw_header_icon_height)
					aa.file = "LuaUI/Images/commands/Bold/attack.png"
					aa:Invalidate()
					SafeAddChild(aa, phmain)
				end
				if dd then 
					dd:SetPos(plw_x_defence_icon,plw_headerTextHeight,plw_header_icon_width,plw_header_icon_height)
					dd.file = "LuaUI/Images/commands/Bold/guard.png"
					dd:Invalidate()
					SafeAddChild(dd, phmain)
				end
				if mm then 
					mm:SetPos(plw_x_metal_icon,plw_headerTextHeight,plw_header_icon_width,plw_header_icon_height)
					mm.file = "LuaUI/Images/metalplus.png"
					mm:Invalidate()
					SafeAddChild(mm, phmain)
				end
				if ee then 
					ee:SetPos(plw_x_energy_icon,plw_headerTextHeight,plw_header_icon_width,plw_header_icon_height)
					ee.file = "LuaUI/Images/energyplus.png"
					ee:Invalidate()
					SafeAddChild(ee, phmain)
				end
				if cc then 
					cc.file = "LuaUI/Images/playerlist/cpu.png"
					if options.plw_cpuPingAsText.value then
						cc:SetPos(plw_x_cpu_icon,plw_headerTextHeight,plw_header_icon_width,plw_header_icon_height)
					else
						cc:SetPos(-100,-100,plw_header_icon_width,plw_header_icon_height)
					end
					cc:Invalidate()
					SafeAddChild(cc, phmain)
				end
				if pp then 
					pp:SetPos(plw_x_ping_icon,plw_headerTextHeight,plw_header_icon_width,plw_header_icon_height)
					pp.file = "LuaUI/Images/playerlist/ping.png"
					if options.plw_cpuPingAsText.value then
						pp:SetPos(plw_x_cpu_icon,plw_headerTextHeight,plw_header_icon_width,plw_header_icon_height)
					else
						pp:SetPos(-100,-100,plw_header_icon_width,plw_header_icon_height)
					end
					pp:Invalidate()
					SafeAddChild(pp, phmain)
				end
				InsertTopVconChild(plw_vcon_playerHeader,plw_vcon_playerList)
			end
		end
		
		if plw_vcon_spectatorList.main then
			plw_vcon_spectatorList.main:SetPos(0,0,plw_x_window_width,0)
			SafeAddChild(plw_vcon_spectatorList.main, plw_vcon_scrollPanel.main)
			--plw_vcon_scrollPanel.main:AddChild(plw_vcon_spectatorList.main)
			InsertBottomVconChild(plw_vcon_spectatorList,plw_vcon_scrollPanel)
			if plw_sectionheader_display then
				--if plw_vcon_spectatorHeader.main then plw_vcon_spectatorHeader.main:Dispose() end
				local shmain = plw_vcon_spectatorHeader.main
				local shtitle = plw_vcon_spectatorHeader.subcon.title
				shmain:SetPos(0,0,plw_x_window_width,specHeaderHeight)
				shtitle:SetPos(plw_sectionheader_offset,0,plw_x_name_width,headerHeight)
				shtitle:SetCaption("Spectators")
				SafeAddChild(shtitle,shmain)
				SafeAddChild(shmain,plw_vcon_spectatorList.main)
				--plw_vcon_spectatorList.main:AddChild(plw_vcon_spectatorHeader.main)
				InsertTopVconChild(plw_vcon_spectatorHeader,plw_vcon_spectatorList)
			end
			
		end
		
	end
	
	PLW_UpdateStatePlayerListControl()
	PLW_UpdateStateSpectatorListControl()
end

-- creates main panels and other stuff that isn't dynamic
local function PLW_CreateStaticControls()
	
	--PLW_CalculateDimensions()
	
	if plw_windowPlayerlist then
		plw_windowPlayerlist:Dispose()
	end
	
	plw_windowPlayerlist = Window:New{autosize = false, dockable = false, draggable = false, resizable = false, tweakDraggable = true, disableChildrenHitTest = false, tweakResizable = true, padding = {0, 0, 0, 0}, color = {0, 0, 0, 0},
	--OnMouseDown = {function() Spring.Echo("Bung") end},
	--OnMouseUp = {function() Spring.Echo("Bung") end},
	}
	--function plw_windowPlayerlist:HitTest(x,y) return self end
	--function plw_windowPlayerlist:MouseUp(x,y) return self end
	--function plw_windowPlayerlist:MouseDown(x,y) return self end
	--function plw_windowPlayerlist:MouseClick(x,y) return self end
	
	plw_contentHolder = Panel:New{classname = options.plw_fancySkinning.value, x = 0, y = 0, right = 0, bottom = 0, padding = {0, 0, 0, 0}, disableChildrenHitTest = false, parent = plw_windowPlayerlist}
	
	plw_exitButton = Button:New{height=25;width=50;x=10;bottom=10;caption="Exit";OnClick = {function() PLW_Toggle() end}; parent = plw_contentHolder}
	
	local scr = ScrollPanel:New{
		--classname = 'panel',
		x = 10,
		y = 10,
		right = 10,
		bottom = 45,
		padding = {3, 3, 3, 3},
		backgroundColor = {1, 1, 1, 0.5},
		verticalSmartScroll = true,
		disableChildrenHitTest = false,
		parent = plw_contentHolder,
		--children = { plw_vcon_playerList.main, plw_vcon_spectatorList.main }
	}
	
	plw_vcon_scrollPanel = CreateVcon(nil, scr, nil, 0, 0)
	
	plw_vcon_scrollPanel.isOuterScrollPanel = true
	
	plw_vcon_playerList = CreateVcon(false, Control:New{padding = {0, 0, 0, 0},color = {0, 0, 0, 0}}, nil, 0, plw_y_buffer)
	
	plw_vcon_spectatorList= CreateVcon(false, Control:New{padding = {0, 0, 0, 0},color = {0, 0, 0, 0}}, nil, 0, plw_y_buffer)
	
	local playTitle = Label:New{padding = {0, 0, 0, 0}, fontsize = plw_headerTextHeight, valign = "top"}
	
	-- plw_windowPlayerlist.OnMouseDown = {function() Spring.Echo("Bung") end}
	-- plw_windowPlayerlist.OnMouseUp = {function() Spring.Echo("Bung") end}
	-- plw_windowPlayerlist.MouseUp = {function() return self end}
	-- plw_windowPlayerlist.MouseDown = {function() return self end}
	
	local aa = Image:New{}
	local dd = Image:New{}
	local mm = Image:New{}
	local ee = Image:New{}
	local cc = Image:New{}
	local pp = Image:New{}
	
	plw_vcon_playerHeader = CreateVcon(false, Control:New{padding = {0, 0, 0, 0},color = {0, 0, 0, 0}}, {title = playTitle, aIcon = aa, dIcon = dd, mIcon = mm, eIcon = ee, cpuIcon = cc, pingIcon = pp}, plw_y_buffer, plw_y_buffer)
	
	local specTitle = Label:New{padding = {0, 0, 0, 0}, fontsize = plw_headerTextHeight, valign = "top",tooltip = "test1"}
	
	plw_vcon_spectatorHeader = CreateVcon(false, Control:New{padding = {0, 0, 0, 0},color = {0, 0, 0, 0}}, {title = specTitle}, plw_y_buffer, plw_y_buffer) 
	
	PLW_ConfigureStaticControls()
end

-- comparison function for allyteam boxes
function PLW_CompareAllyTeamVcons(vcon1, vcon2)
	if not vcon1.vID then -- the ally team bar should be at the top
		return false
	elseif not vcon2.vID then -- if neither of these are true, the vIDs should be team IDs
		return true
	elseif allyTeamEntities[vcon1.vID] and allyTeamEntities[vcon2.vID] then
		local res1 = allyTeamEntities[vcon1.vID].resigned
		local res2 = allyTeamEntities[vcon2.vID].resigned
		if res2 then 
			return false
		elseif res1 then
			return true
		elseif vcon2.vID < vcon1.vID then
			return true
		end
	end
	return false
end

-- updates volatile components of allyteam box
local function PLW_UpdateVolatileAllyTeamControls(allyTeamID)
	if (not allyTeamEntities[allyTeamID]) or (not plw_vcon_allyTeamControls[allyTeamID]) or (not plw_vcon_allyTeamControls[allyTeamID].subcon) then
		return
	end
	
	if allyTeamEntities[allyTeamID].resigned then
		plw_vcon_allyTeamBarControls[allyTeamID].subcon.aVal:SetCaption("")
		plw_vcon_allyTeamBarControls[allyTeamID].subcon.aVal:Invalidate()
		plw_vcon_allyTeamBarControls[allyTeamID].subcon.dVal:SetCaption("")
		plw_vcon_allyTeamBarControls[allyTeamID].subcon.dVal:Invalidate()
		plw_vcon_allyTeamBarControls[allyTeamID].subcon.mInc:SetCaption("")
		plw_vcon_allyTeamBarControls[allyTeamID].subcon.mInc:Invalidate()
		plw_vcon_allyTeamBarControls[allyTeamID].subcon.eInc:SetCaption("")
		plw_vcon_allyTeamBarControls[allyTeamID].subcon.eInc:Invalidate()
	else
		if allyTeamEntities[allyTeamID].m_mobiles then
			plw_vcon_allyTeamBarControls[allyTeamID].subcon.aVal:SetCaption(FormatMetalStats(allyTeamEntities[allyTeamID].m_mobiles))
			--plw_vcon_allyTeamBarControls[allyTeamID].subcon.aVal:Invalidate()
		end
		if allyTeamEntities[allyTeamID].m_defence then
			plw_vcon_allyTeamBarControls[allyTeamID].subcon.dVal:SetCaption(FormatMetalStats(allyTeamEntities[allyTeamID].m_defence))
			--plw_vcon_allyTeamBarControls[allyTeamID].subcon.dVal:Invalidate()
		end
		if allyTeamEntities[allyTeamID].m_income then
			plw_vcon_allyTeamBarControls[allyTeamID].subcon.mInc:SetCaption(FormatIncomeStats(allyTeamEntities[allyTeamID].m_income))
			--plw_vcon_allyTeamBarControls[allyTeamID].subcon.mInc:Invalidate()
		end
		if allyTeamEntities[allyTeamID].e_income then
			plw_vcon_allyTeamBarControls[allyTeamID].subcon.eInc:SetCaption(FormatIncomeStats(allyTeamEntities[allyTeamID].e_income))
			--plw_vcon_allyTeamBarControls[allyTeamID].subcon.eInc:Invalidate()
		end
		if (Spring.GetGameSeconds() and Spring.GetGameSeconds() < 0.1) then
			plw_vcon_allyTeamBarControls[allyTeamID].subcon.eBar:SetValue(0)
			plw_vcon_allyTeamBarControls[allyTeamID].subcon.eBar:SetCaption("")
			plw_vcon_allyTeamBarControls[allyTeamID].subcon.mBar:SetValue(0)
			plw_vcon_allyTeamBarControls[allyTeamID].subcon.mBar:SetCaption("")
		else
			if allyTeamEntities[allyTeamID].e_curr and allyTeamEntities[allyTeamID].e_stor then
				plw_vcon_allyTeamBarControls[allyTeamID].subcon.eBar:SetValue(allyTeamEntities[allyTeamID].e_curr / ((allyTeamEntities[allyTeamID].e_stor > 0) and allyTeamEntities[allyTeamID].e_stor or 10000))
				if Spring.GetGameFrame() > 0 and allyTeamEntities[allyTeamID].e_stor > 0 then
					if allyTeamEntities[allyTeamID].e_curr < 0.051 * allyTeamEntities[allyTeamID].e_stor then
						plw_vcon_allyTeamBarControls[allyTeamID].subcon.eBar:SetCaption("!")
					else
						plw_vcon_allyTeamBarControls[allyTeamID].subcon.eBar:SetCaption("")
					end
				else
					plw_vcon_allyTeamBarControls[allyTeamID].subcon.eBar:SetCaption("x")
					plw_vcon_allyTeamBarControls[allyTeamID].subcon.eBar:SetValue(0)
				end
				plw_vcon_allyTeamBarControls[allyTeamID].subcon.eBar.tooltip = string.format("%.0f", (allyTeamEntities[allyTeamID].e_curr > allyTeamEntities[allyTeamID].e_stor) and allyTeamEntities[allyTeamID].e_stor or allyTeamEntities[allyTeamID].e_curr) .. "/" .. string.format("%.0f", allyTeamEntities[allyTeamID].e_stor)
			end
			
			if allyTeamEntities[allyTeamID].m_curr and allyTeamEntities[allyTeamID].m_stor then
				plw_vcon_allyTeamBarControls[allyTeamID].subcon.mBar:SetValue(allyTeamEntities[allyTeamID].m_curr / ((allyTeamEntities[allyTeamID].m_stor > 0) and allyTeamEntities[allyTeamID].m_stor or 10000))
				if allyTeamEntities[allyTeamID].m_stor > 0 then
					if allyTeamEntities[allyTeamID].m_curr > 0.99 * allyTeamEntities[allyTeamID].m_stor then
						--plw_vcon_allyTeamBarControls[allyTeamID].subcon.mBar:SetColor{.75,.5,.5,1}
						plw_vcon_allyTeamBarControls[allyTeamID].subcon.mBar:SetCaption("!")
					else
						--plw_vcon_allyTeamBarControls[allyTeamID].subcon.mBar:SetColor{.5,.5,.5,1}
						plw_vcon_allyTeamBarControls[allyTeamID].subcon.mBar:SetCaption("")
					end
				else
					plw_vcon_allyTeamBarControls[allyTeamID].subcon.mBar:SetCaption("x")
					plw_vcon_allyTeamBarControls[allyTeamID].subcon.mBar:SetValue(0)
				end
				plw_vcon_allyTeamBarControls[allyTeamID].subcon.mBar.tooltip = string.format("%.0f", (allyTeamEntities[allyTeamID].m_curr > allyTeamEntities[allyTeamID].m_stor) and allyTeamEntities[allyTeamID].m_stor or allyTeamEntities[allyTeamID].m_curr) .. "/" .. string.format("%.0f", allyTeamEntities[allyTeamID].m_stor)
			end
		end
	end
end

-- updates allyteam box
local function PLW_UpdateStateAllyTeamControls(allyTeamID)
	if (not allyTeamEntities[allyTeamID]) or (not plw_vcon_allyTeamControls[allyTeamID]) or (not plw_vcon_allyTeamControls[allyTeamID].subcon) or (not plw_vcon_allyTeamBarControls[allyTeamID]) or (not plw_vcon_allyTeamBarControls[allyTeamID].subcon) then
		return
	end
	
	local namewidth
	if drawTeamnames then
		if allyTeamEntities[allyTeamID].drawTeamname and allyTeamEntities[allyTeamID].name then 
			-- this allyteam has a summary bar
			plw_vcon_allyTeamBarControls[allyTeamID].subcon.name.caption = allyTeamEntities[allyTeamID].name 
			namewidth = math.max(2, plw_vcon_allyTeamBarControls[allyTeamID].subcon.name.font:GetTextWidth(allyTeamEntities[allyTeamID].name))
			local clanicon
			local leftlineend = plw_x_name_begin - (plw_linebuffer * 2)
			--local rightlinestart = plw_x_name_begin + plw_x_name_offset + namewidth + plw_linebuffer
			local rightlinestart = plw_x_cpuping_begin + plw_linebuffer
			local midlinestart = plw_x_name_begin + plw_x_name_offset + namewidth + plw_linebuffer
			local midlineend = plw_x_resourcestate_begin - plw_linebuffer
			if allyTeamEntities[allyTeamID].clan and allyTeamEntities[allyTeamID].clan ~= "" then 
				clanicon = "LuaUI/Configs/Clans/" .. clan ..".png"
			end
			if clanicon then 
				plw_vcon_allyTeamBarControls[allyTeamID].subcon.clan.file = clanicon 
				plw_vcon_allyTeamBarControls[allyTeamID].subcon.clan:Invalidate()
				leftlineend = plw_x_name_begin - plw_x_icon_clan_width - (plw_linebuffer * 2)
			end
			plw_vcon_allyTeamBarControls[allyTeamID].subcon.leftline.x = plw_linebuffer
			plw_vcon_allyTeamBarControls[allyTeamID].subcon.leftline.y = plw_playerbar_text_height * 0.25
			plw_vcon_allyTeamBarControls[allyTeamID].subcon.leftline.width = leftlineend
			plw_vcon_allyTeamBarControls[allyTeamID].subcon.leftline:Invalidate()
			if allyTeamEntities[allyTeamID].drawTeamEcon and (iAmSpec or myAllyTeam == allyTeamID) then 
				plw_vcon_allyTeamBarControls[allyTeamID].subcon.midline:SetPos(midlinestart, plw_playerbar_text_height * 0.25, midlineend - midlinestart, 1)
				plw_vcon_allyTeamBarControls[allyTeamID].subcon.rightline.x = rightlinestart
				plw_vcon_allyTeamBarControls[allyTeamID].subcon.rightline.y = plw_playerbar_text_height * 0.25
				plw_vcon_allyTeamBarControls[allyTeamID].subcon.rightline.width = plw_x_window_width - rightlinestart - (plw_linebuffer * 2)
				plw_vcon_allyTeamBarControls[allyTeamID].subcon.rightline:Invalidate()
				plw_vcon_allyTeamBarControls[allyTeamID].subcon.aVal:SetPos(plw_x_resourcestate_begin + plw_x_m_mobiles_offset, plw_playerbar_text_y, plw_x_m_mobiles_width, plw_playerbar_text_height)
				plw_vcon_allyTeamBarControls[allyTeamID].subcon.dVal:SetPos(plw_x_resourcestate_begin + plw_x_m_defense_offset, plw_playerbar_text_y, plw_x_m_defense_width, plw_playerbar_text_height)
				plw_vcon_allyTeamBarControls[allyTeamID].subcon.mInc:SetPos(plw_x_resourcestate_begin + plw_x_m_income_offset, plw_playerbar_text_y, plw_x_m_income_width, plw_playerbar_text_height)
				plw_vcon_allyTeamBarControls[allyTeamID].subcon.eInc:SetPos(plw_x_resourcestate_begin + plw_x_e_income_offset, plw_playerbar_text_y, plw_x_e_income_width, plw_playerbar_text_height)
				plw_vcon_allyTeamBarControls[allyTeamID].subcon.mBar:SetPos(plw_x_resourcestate_begin + plw_x_m_fill_offset, plw_playerbar_text_y + 1, plw_x_m_fill_width, plw_playerbar_text_height - 2)
				plw_vcon_allyTeamBarControls[allyTeamID].subcon.eBar:SetPos(plw_x_resourcestate_begin + plw_x_e_fill_offset, plw_playerbar_text_y + 1, plw_x_e_fill_width, plw_playerbar_text_height - 2)
			else
				plw_vcon_allyTeamBarControls[allyTeamID].subcon.midline:SetPos(-100, -100, 1, 1)
				plw_vcon_allyTeamBarControls[allyTeamID].subcon.rightline.x = midlinestart
				plw_vcon_allyTeamBarControls[allyTeamID].subcon.rightline.y = plw_playerbar_text_height * 0.25
				plw_vcon_allyTeamBarControls[allyTeamID].subcon.rightline.width = plw_x_window_width - midlinestart - (plw_linebuffer * 2)
				plw_vcon_allyTeamBarControls[allyTeamID].subcon.rightline:Invalidate()
				plw_vcon_allyTeamBarControls[allyTeamID].subcon.aVal:SetPos(-100, -100, 1,1)
				plw_vcon_allyTeamBarControls[allyTeamID].subcon.dVal:SetPos(-100, -100, 1,1)
				plw_vcon_allyTeamBarControls[allyTeamID].subcon.mInc:SetPos(-100, -100, 1,1)
				plw_vcon_allyTeamBarControls[allyTeamID].subcon.eInc:SetPos(-100, -100, 1,1)
				plw_vcon_allyTeamBarControls[allyTeamID].subcon.mBar:SetPos(-100, -100, 1,1)
				plw_vcon_allyTeamBarControls[allyTeamID].subcon.eBar:SetPos(-100, -100, 1,1)
			end
		else
			-- this allyteam does not have a summary bar but others do - draw a line for consistency
			plw_vcon_allyTeamBarControls[allyTeamID].subcon.name.caption = ""
			plw_vcon_allyTeamBarControls[allyTeamID].subcon.rightline.x = 0
			plw_vcon_allyTeamBarControls[allyTeamID].subcon.rightline.y = plw_playerbar_text_height * 0.25
			plw_vcon_allyTeamBarControls[allyTeamID].subcon.rightline.width = plw_x_window_width
			plw_vcon_allyTeamBarControls[allyTeamID].subcon.rightline:Invalidate()
			plw_vcon_allyTeamBarControls[allyTeamID].subcon.leftline:SetPos(-100, -100, 1, 1)
			plw_vcon_allyTeamBarControls[allyTeamID].subcon.midline:SetPos(-100, -100, 1, 1)
			plw_vcon_allyTeamBarControls[allyTeamID].subcon.aVal:SetPos(-100, -100, 1, 1)
			plw_vcon_allyTeamBarControls[allyTeamID].subcon.dVal:SetPos(-100, -100, 1, 1)
			plw_vcon_allyTeamBarControls[allyTeamID].subcon.mInc:SetPos(-100, -100, 1, 1)
			plw_vcon_allyTeamBarControls[allyTeamID].subcon.eInc:SetPos(-100, -100, 1, 1)
			plw_vcon_allyTeamBarControls[allyTeamID].subcon.mBar:SetPos(-100, -100, 1, 1)
			plw_vcon_allyTeamBarControls[allyTeamID].subcon.eBar:SetPos(-100, -100, 1, 1)
		end
		if not plw_vcon_allyTeamBarControls[allyTeamID].parent then
			plw_vcon_allyTeamControls[allyTeamID].main:AddChild(plw_vcon_allyTeamBarControls[allyTeamID].main)
			InsertTopVconChild(plw_vcon_allyTeamBarControls[allyTeamID], plw_vcon_allyTeamControls[allyTeamID])
		end
	else
		-- not drawing any summary bars
		-- plw_vcon_allyTeamBarControls[allyTeamID].subcon.rightline.x = -100
		-- plw_vcon_allyTeamBarControls[allyTeamID].subcon.rightline.y = -100
		-- plw_vcon_allyTeamBarControls[allyTeamID].subcon.rightline.width = 1
		-- plw_vcon_allyTeamBarControls[allyTeamID].subcon.rightline:Invalidate()
		-- plw_vcon_allyTeamBarControls[allyTeamID].subcon.leftline.x = -100
		-- plw_vcon_allyTeamBarControls[allyTeamID].subcon.leftline.y = -100
		-- plw_vcon_allyTeamBarControls[allyTeamID].subcon.leftline.width = 1
		-- plw_vcon_allyTeamBarControls[allyTeamID].subcon.leftline:Invalidate()
		plw_vcon_allyTeamBarControls[allyTeamID].subcon.rightline:SetPos(-100, -100, 1, 1)
		plw_vcon_allyTeamBarControls[allyTeamID].subcon.leftline:SetPos(-100, -100, 1, 1)
		plw_vcon_allyTeamBarControls[allyTeamID].subcon.aVal:SetPos(-100, -100, 1, 1)
		plw_vcon_allyTeamBarControls[allyTeamID].subcon.dVal:SetPos(-100, -100, 1, 1)
		plw_vcon_allyTeamBarControls[allyTeamID].subcon.mInc:SetPos(-100, -100, 1, 1)
		plw_vcon_allyTeamBarControls[allyTeamID].subcon.eInc:SetPos(-100, -100, 1, 1)
		plw_vcon_allyTeamBarControls[allyTeamID].subcon.mBar:SetPos(-100, -100, 1, 1)
		plw_vcon_allyTeamBarControls[allyTeamID].subcon.eBar:SetPos(-100, -100, 1, 1)
		if plw_vcon_allyTeamBarControls[allyTeamID].parent then
			plw_vcon_allyTeamControls[allyTeamID].main:RemoveChild(plw_vcon_allyTeamBarControls[allyTeamID].main)
			RemoveVcon(plw_vcon_allyTeamBarControls[allyTeamID])
		end
		
	end
	
	for tID, _ in pairs(allyTeamEntities[allyTeamID].memberTEIDs) do
		local nPlayers = 0
		for eID, _ in pairs(teamEntities[tID].memberPEIDs) do
			nPlayers = nPlayers + 1
		end
		local teamVCon = plw_vcon_teamControls[tID]
		
		if nPlayers == 0 and teamVCon and teamVCon.parent then
			RemoveVcon(teamVCon)
			if plw_vcon_allyTeamControls[allyTeamID].firstChild then SortVcons(plw_vcon_allyTeamControls[allyTeamID].firstChild,PLW_CompareTeamVcons,false) end
			plw_vcon_allyTeamControls[allyTeamID].main:RemoveChild(plw_vcon_teamControls[tID].main)
		end
		
		if teamVCon and teamVCon.parent ~= plw_vcon_allyTeamControls[allyTeamID] then
			if teamVCon.parent then
				local oldparent = teamVCon.parent
				RemoveVcon(teamVCon)
				oldparent.main:RemoveChild(teamVCon.main)
				if oldparent.firstChild then SortVcons(oldparent.firstChild,PLW_CompareTeamVcons,false) end
			end
			if nPlayers > 0 then
				plw_vcon_allyTeamControls[allyTeamID].main:AddChild(teamVCon.main)
				InsertBottomVconChild(teamVCon, plw_vcon_allyTeamControls[allyTeamID])
				SortSingleVcon(teamVCon, nil, PLW_CompareTeamVcons, true, true)
			end
		end
	end
	
	-- try shifting this allyteam up and down
	SortSingleVcon(plw_vcon_allyTeamControls[allyTeamID], nil, PLW_CompareAllyTeamVcons, true, true)
	SortSingleVcon(plw_vcon_allyTeamControls[allyTeamID], nil, PLW_CompareAllyTeamVcons, false, true)
end


-- configures allyteam box
local function PLW_ConfigureAllyTeamControls(allyTeamID)
	if plw_vcon_allyTeamControls[allyTeamID] then
		local main = plw_vcon_allyTeamControls[allyTeamID].main
		
		if main then main:SetPos(0,0,plw_x_window_width,0) end
	end
	
	if plw_vcon_allyTeamBarControls[allyTeamID] then
		local barMain = plw_vcon_allyTeamBarControls[allyTeamID].main
		local name = plw_vcon_allyTeamBarControls[allyTeamID].subcon.name
		local clan = plw_vcon_allyTeamBarControls[allyTeamID].subcon.clan
		local playerCount = plw_vcon_allyTeamBarControls[allyTeamID].subcon.playerCount
		local status = plw_vcon_allyTeamBarControls[allyTeamID].subcon.status
		local rightline = plw_vcon_allyTeamBarControls[allyTeamID].subcon.rightline
		local midline = plw_vcon_allyTeamBarControls[allyTeamID].subcon.midline
		local leftline = plw_vcon_allyTeamBarControls[allyTeamID].subcon.leftline
		local aVal = plw_vcon_allyTeamBarControls[allyTeamID].subcon.aVal
		local dVal = plw_vcon_allyTeamBarControls[allyTeamID].subcon.dVal
		local mInc = plw_vcon_allyTeamBarControls[allyTeamID].subcon.mInc
		local eInc = plw_vcon_allyTeamBarControls[allyTeamID].subcon.eInc
		local mBar = plw_vcon_allyTeamBarControls[allyTeamID].subcon.mBar
		local eBar = plw_vcon_allyTeamBarControls[allyTeamID].subcon.eBar
		
		if barMain then barMain:SetPos(0, 0, plw_x_window_width, plw_playerbar_height + 3) end
		if name then 
			name:SetPos(plw_x_name_begin + plw_x_name_offset, plw_playerbar_text_y, plw_x_name_width, plw_playerbar_text_height)
			name.font.size = plw_playerbar_text_height
			name:SetCaption("ERROR")
			barMain:AddChild(name)
		end
		if clan then
			clan:SetPos(plw_x_name_begin - plw_x_icon_clan_width - 5, 0, plw_x_icon_clan_width, plw_playerbar_image_height);
			barMain:AddChild(clan)
		end
		if rightline then
			rightline.x = plw_x_cpuping_begin + plw_linebuffer
			rightline.y = plw_playerbar_text_height * 0.25
			rightline.width = plw_x_window_width - plw_x_cpuping_begin - (plw_linebuffer * 2)
			SafeAddChild(rightline, barMain)
			--barMain:AddChild(rightline)
		end
		if leftline then
			leftline.x = plw_linebuffer
			leftline.y = plw_playerbar_text_height * 0.25
			leftline.width = plw_x_name_begin - (plw_linebuffer * 2)
			SafeAddChild(leftline, barMain)
			--barMain:AddChild(leftline)
		end
		if midline then
			midline.x = plw_linebuffer
			midline.y = plw_playerbar_text_height * 0.25
			midline.width = plw_x_name_begin - (plw_linebuffer * 2)
			SafeAddChild(midline, barMain)
			--barMain:AddChild(leftline)
		end
		if aVal then 
			aVal:SetPos(plw_x_resourcestate_begin + plw_x_m_mobiles_offset, plw_playerbar_text_y, plw_x_m_mobiles_width, plw_playerbar_text_height)
			aVal.font.size = plw_playerbar_text_height
			aVal.font:SetColor{1,0.7,0.7,1}
			aVal.align = 'right'
			aVal:SetCaption("E")
			SafeAddChild(aVal,barMain)
		end
		if dVal then 
			dVal:SetPos(plw_x_resourcestate_begin + plw_x_m_defense_offset, plw_playerbar_text_y, plw_x_m_defense_width, plw_playerbar_text_height)
			dVal.font.size = plw_playerbar_text_height
			dVal.font:SetColor{0.7,0.7,1,1}
			dVal.align = 'right'
			dVal:SetCaption("E")
			SafeAddChild(dVal,barMain)
		end
		if mInc then 
			mInc:SetPos(plw_x_resourcestate_begin + plw_x_m_income_offset, plw_playerbar_text_y, plw_x_m_income_width, plw_playerbar_text_height)
			mInc.font.size = plw_playerbar_text_height
			mInc.font:SetColor{0.7,0.7,0.7,1}
			mInc.align = 'right'
			mInc:SetCaption("E")
			SafeAddChild(mInc,barMain)
		end
		if eInc then 
			eInc:SetPos(plw_x_resourcestate_begin + plw_x_e_income_offset, plw_playerbar_text_y, plw_x_e_income_width, plw_playerbar_text_height)
			eInc.font.size = plw_playerbar_text_height
			eInc.font:SetColor{1,1,0.5,1}
			eInc.align = 'right'
			eInc:SetCaption("E")
			SafeAddChild(eInc,barMain)
		end
		if mBar then
			mBar:SetPos(plw_x_resourcestate_begin + plw_x_m_fill_offset, plw_playerbar_text_y + 1, plw_x_m_fill_width, plw_playerbar_text_height - 2)
			mBar:SetColor{.7,.7,.7,1}
			mBar.font:SetColor{1,.5,.5,1}
			mBar:SetMinMax(0,1)
			function mBar:HitTest(x,y) return self end
			SafeAddChild(mBar,barMain)
		end
		if eBar then
			eBar:SetPos(plw_x_resourcestate_begin + plw_x_e_fill_offset, plw_playerbar_text_y + 1, plw_x_e_fill_width, plw_playerbar_text_height - 2)
			eBar:SetColor{1,1,0.5,1}
			eBar.font:SetColor{1,.5,.5,1}
			eBar:SetMinMax(0,1)
			function eBar:HitTest(x,y) return self end
			SafeAddChild(eBar,barMain)
		end
	end
	
	PLW_UpdateStateAllyTeamControls(allyTeamID)
end

-- creates allyteam box
local function PLW_CreateAllyTeamControls(allyTeamID)
	local mainControl = Control:New{padding = {0, 0, 0, 0},color = {0, 0, 0, 0}}
	
	plw_vcon_allyTeamControls[allyTeamID] = CreateVcon(allyTeamID, mainControl, {}, plw_y_buffer/2, plw_y_buffer/2)

	local barMainControl = Control:New{padding = {0, 0, 0, 0},color = {0, 0, 0, 0}}
	local clanImage = Image:New{}
	local nameLabel = Label:New{autosize = false}
	local playerCountLabel = Label:New{autosize = false}
	local statusImage = Image:New{}
	local leftLine = Line:New{}
	local midLine = Line:New{}
	local rightLine = Line:New{}
	local mArmy = Label:New{autosize = false}
	local mStatic = Label:New{autosize = false}
	local mIncome = Label:New{autosize = false}
	local eIncome = Label:New{autosize = false}
	local metalBar = Chili.Progressbar:New{}
	local energyBar = Chili.Progressbar:New{}
	
	local subcon = {name = nameLabel, clan = clanImage, playerCount = playerCountLabel, status = statusImage, aVal = mArmy, dVal = mStatic, mInc = mIncome, eInc = eIncome, mBar = metalBar, eBar = energyBar, rightline = leftLine, midline = midLine, leftline = rightLine}
	
	plw_vcon_allyTeamBarControls[allyTeamID] = CreateVcon(false, barMainControl, subcon, 0, 0)
	
	PLW_ConfigureAllyTeamControls(allyTeamID)
end

-- comparison function for team boxes
function PLW_CompareTeamVcons(vcon1, vcon2)
	if not vcon1.vID then -- the ally team bar should be at the top
		return false
	elseif not vcon2.vID then -- if neither of these happen, the vIDs should be team IDs
		return true
	elseif teamEntities[vcon1.vID] and teamEntities[vcon2.vID] then
		local elo1 = teamEntities[vcon1.vID].elo
		local res1 = teamEntities[vcon1.vID].resigned
		local elo2 = teamEntities[vcon2.vID].elo
		local res2 = teamEntities[vcon2.vID].resigned
		if res2 then 
			return false
		elseif res1 then
			return true
		elseif elo2 and (not elo1 or elo2 > elo1) then
			return true
		end
	end
	return false
end

-- updates volatile components of team box
local function PLW_UpdateVolatileTeamControls(teamID)
	if (not teamEntities[teamID]) or (not plw_vcon_teamControls[teamID]) or (not plw_vcon_teamControls[teamID].subcon) then
		return
	end

	if teamEntities[teamID].resigned then
		plw_vcon_teamControls[teamID].subcon.aVal:SetCaption("")
		--plw_vcon_teamControls[teamID].subcon.aVal:Invalidate()
		plw_vcon_teamControls[teamID].subcon.dVal:SetCaption("")
		--plw_vcon_teamControls[teamID].subcon.dVal:Invalidate()
		plw_vcon_teamControls[teamID].subcon.mInc:SetCaption("")
		--plw_vcon_teamControls[teamID].subcon.mInc:Invalidate()
		plw_vcon_teamControls[teamID].subcon.eInc:SetCaption("")
		--plw_vcon_teamControls[teamID].subcon.eInc:Invalidate()
		plw_vcon_teamControls[teamID].subcon.mBar:SetPos(-100, -100, 1,1)
		plw_vcon_teamControls[teamID].subcon.eBar:SetPos(-100, -100, 1,1)
	else
		if teamEntities[teamID].m_mobiles then
			plw_vcon_teamControls[teamID].subcon.aVal:SetCaption(FormatMetalStats(teamEntities[teamID].m_mobiles))
			--plw_vcon_teamControls[teamID].subcon.aVal:Invalidate()
		end
		if teamEntities[teamID].m_defence then
			plw_vcon_teamControls[teamID].subcon.dVal:SetCaption(FormatMetalStats(teamEntities[teamID].m_defence))
			--plw_vcon_teamControls[teamID].subcon.dVal:Invalidate()
		end
		if teamEntities[teamID].m_income then
			plw_vcon_teamControls[teamID].subcon.mInc:SetCaption(FormatIncomeStats(teamEntities[teamID].m_income))
			--plw_vcon_teamControls[teamID].subcon.mInc:Invalidate()
		end
		if teamEntities[teamID].e_income then
			plw_vcon_teamControls[teamID].subcon.eInc:SetCaption(FormatIncomeStats(teamEntities[teamID].e_income))
			--plw_vcon_teamControls[teamID].subcon.eInc:Invalidate()
		end
		if (Spring.GetGameSeconds() and Spring.GetGameSeconds() < 0.1) then
			plw_vcon_teamControls[teamID].subcon.eBar:SetValue(0)
			plw_vcon_teamControls[teamID].subcon.eBar:SetCaption("")
			plw_vcon_teamControls[teamID].subcon.mBar:SetValue(0)
			plw_vcon_teamControls[teamID].subcon.mBar:SetCaption("")
		else
			if teamEntities[teamID].e_curr and teamEntities[teamID].e_stor then
				plw_vcon_teamControls[teamID].subcon.eBar:SetValue(teamEntities[teamID].e_curr / ((teamEntities[teamID].e_stor > 0) and teamEntities[teamID].e_stor or 1000))
				if teamEntities[teamID].e_stor > 0 then
					if teamEntities[teamID].e_curr < 0.051 * teamEntities[teamID].e_stor then
						plw_vcon_teamControls[teamID].subcon.eBar:SetCaption("!")
					else
						plw_vcon_teamControls[teamID].subcon.eBar:SetCaption("")
					end
				else
					plw_vcon_teamControls[teamID].subcon.eBar:SetCaption("x")
					plw_vcon_teamControls[teamID].subcon.eBar:SetValue(0)
				end
				
				local ttip = string.format("%.0f", (teamEntities[teamID].e_curr > teamEntities[teamID].e_stor) and teamEntities[teamID].e_stor or teamEntities[teamID].e_curr) .. "/" .. string.format("%.0f", teamEntities[teamID].e_stor)
				if not iAmSpec and teamEntities[teamID].allyTeamID == myAllyTeam then
					ttip = (ttip or "") .. "\nClick to give 100 energy"
				end 
				plw_vcon_teamControls[teamID].subcon.eBar.tooltip  = ttip
			end
			if teamEntities[teamID].m_curr and teamEntities[teamID].m_stor then
				plw_vcon_teamControls[teamID].subcon.mBar:SetValue(teamEntities[teamID].m_curr / ((teamEntities[teamID].m_stor > 0) and teamEntities[teamID].m_stor or 1000))
				if teamEntities[teamID].m_stor > 0 then
					if teamEntities[teamID].m_curr > 0.99 * teamEntities[teamID].m_stor then
						plw_vcon_teamControls[teamID].subcon.mBar:SetCaption("!")
						--plw_vcon_teamControls[teamID].subcon.mBar:SetColor{.75,.5,.5,1}
					else
						plw_vcon_teamControls[teamID].subcon.mBar:SetCaption("")
						--plw_vcon_teamControls[teamID].subcon.mBar:SetColor{.5,.5,.5,1}
					end
				else
					plw_vcon_teamControls[teamID].subcon.mBar:SetCaption("x")
					plw_vcon_teamControls[teamID].subcon.mBar:SetValue(0)
				end
				local ttip = string.format("%.0f", (teamEntities[teamID].m_curr > teamEntities[teamID].m_stor) and teamEntities[teamID].m_stor or teamEntities[teamID].m_curr) .. "/" .. string.format("%.0f", teamEntities[teamID].m_stor)
				if not iAmSpec and teamEntities[teamID].allyTeamID == myAllyTeam then
					ttip = (ttip or "") .. "\nClick to give 100 metal"
				end 
				plw_vcon_teamControls[teamID].subcon.mBar.tooltip = ttip
			end
		end
	end
end

-- updates team box
local function PLW_UpdateStateTeamControls(teamID)
	if (not teamEntities[teamID]) or (not plw_vcon_teamControls[teamID]) or (not plw_vcon_teamControls[teamID].subcon) then
		return
	end
	
	local nPlayers = 0
	if teamEntities[teamID].isAI then
		nPlayers = 1
		local eID = aiLookup[teamID]
		if plw_vcon_playerControls[eID] and plw_vcon_playerControls[eID].parent ~= plw_vcon_teamControls[teamID] then
			if plw_vcon_playerControls[eID].parent then
				local oldparent = plw_vcon_playerControls[eID].parent
				RemoveVcon(plw_vcon_playerControls[eID])
				oldparent.main:RemoveChild(plw_vcon_playerControls[eID].main)
				if oldparent.firstChild then SortVcons(oldparent.firstChild,PLW_ComparePlayerVcons,false) end
			end
			InsertBottomVconChild(plw_vcon_playerControls[eID], plw_vcon_teamControls[teamID])
			plw_vcon_teamControls[teamID].main:AddChild(plw_vcon_playerControls[eID].main)
			SortSingleVcon(plw_vcon_playerControls[eID], nil, PLW_ComparePlayerVcons, true, true)
		end
	else
		for eID, _ in pairs(teamEntities[teamID].memberPEIDs) do
			nPlayers = nPlayers + 1
			if plw_vcon_playerControls[eID] and plw_vcon_playerControls[eID].parent ~= plw_vcon_teamControls[teamID] then
				if plw_vcon_playerControls[eID].parent then
					local oldparent = plw_vcon_playerControls[eID].parent
					RemoveVcon(plw_vcon_playerControls[eID])
					oldparent.main:RemoveChild(plw_vcon_playerControls[eID].main)
					if oldparent.firstChild then SortVcons(oldparent.firstChild,PLW_ComparePlayerVcons,false) end
				end
				InsertBottomVconChild(plw_vcon_playerControls[eID], plw_vcon_teamControls[teamID])
				SafeAddChild(plw_vcon_playerControls[eID].main,plw_vcon_teamControls[teamID].main)
				SortSingleVcon(plw_vcon_playerControls[eID], nil, PLW_ComparePlayerVcons, true, true)
			end
		end
	end
	
	if plw_vcon_teamControls[teamID] and plw_vcon_teamControls[teamID].subcon.rBar then
		if not teamEntities[teamID].resigned and (iAmSpec or myAllyTeam == teamEntities[teamID].allyTeamID) then
			plw_vcon_teamControls[teamID].subcon.rBar:SetPos(0,(nPlayers - 1) * plw_playerbar_height * 0.5,plw_x_window_width,plw_playerbar_height)
		else
			plw_vcon_teamControls[teamID].subcon.rBar:SetPos(0,-500,plw_x_window_width,plw_playerbar_height)
		end
	end

	-- try shifting this teambox up and down
	SortSingleVcon(plw_vcon_teamControls[teamID], nil, PLW_CompareTeamVcons, true, true)
	SortSingleVcon(plw_vcon_teamControls[teamID], nil, PLW_CompareTeamVcons, false, true)
	
	PLW_UpdateVolatileTeamControls(teamID)
end

-- configures team box
local function PLW_ConfigureTeamControls(teamID)
	if plw_vcon_teamControls[teamID] then
		local main = plw_vcon_teamControls[teamID].main
		local rBar = plw_vcon_teamControls[teamID].subcon.rBar
		local aVal = plw_vcon_teamControls[teamID].subcon.aVal
		local dVal = plw_vcon_teamControls[teamID].subcon.dVal
		local mInc = plw_vcon_teamControls[teamID].subcon.mInc
		local eInc = plw_vcon_teamControls[teamID].subcon.eInc
		local mBar = plw_vcon_teamControls[teamID].subcon.mBar
		local eBar = plw_vcon_teamControls[teamID].subcon.eBar
		
		if main then main:SetPos(0,0,plw_x_window_width,0) end
		if rBar then 
			rBar:SetPos(0,0,plw_x_window_width,plw_playerbar_height)
			SafeAddChild(rBar,main)
		end
		if aVal then 
			aVal:SetPos(plw_x_resourcestate_begin + plw_x_m_mobiles_offset, plw_playerbar_text_y, plw_x_m_mobiles_width, plw_playerbar_text_height)
			aVal.font.size = plw_playerbar_text_height
			aVal.font:SetColor{0.9,0.5,0.5,1}
			aVal.align = 'right'
			aVal:SetCaption("E")
			SafeAddChild(aVal,rBar)
		end
		if dVal then 
			dVal:SetPos(plw_x_resourcestate_begin + plw_x_m_defense_offset, plw_playerbar_text_y, plw_x_m_defense_width, plw_playerbar_text_height)
			dVal.font.size = plw_playerbar_text_height
			dVal.font:SetColor{0.5,0.5,0.9,1}
			dVal.align = 'right'
			dVal:SetCaption("E")
			SafeAddChild(dVal,rBar)
		end
		if mInc then 
			mInc:SetPos(plw_x_resourcestate_begin + plw_x_m_income_offset, plw_playerbar_text_y, plw_x_m_income_width, plw_playerbar_text_height)
			mInc.font.size = plw_playerbar_text_height
			mInc.font:SetColor{0.5,0.5,0.5,1}
			mInc.align = 'right'
			mInc:SetCaption("E")
			SafeAddChild(mInc,rBar)
		end
		if eInc then 
			eInc:SetPos(plw_x_resourcestate_begin + plw_x_e_income_offset, plw_playerbar_text_y, plw_x_e_income_width, plw_playerbar_text_height)
			eInc.font.size = plw_playerbar_text_height
			eInc.font:SetColor{0.85,0.85,0.6,1}
			eInc.align = 'right'
			eInc:SetCaption("E")
			SafeAddChild(eInc,rBar)
		end
		if mBar then
			mBar:SetPos(plw_x_resourcestate_begin + plw_x_m_fill_offset, plw_playerbar_text_y + 1, plw_x_m_fill_width, plw_playerbar_text_height - 2)
			mBar:SetColor{.5,.5,.5,1}
			mBar.font:SetColor{1,.5,.5,1}
			mBar:SetMinMax(0,1)
			function mBar:HitTest(x,y) return self end
			SafeAddChild(mBar,rBar)
		end
		if eBar then
			eBar:SetPos(plw_x_resourcestate_begin + plw_x_e_fill_offset, plw_playerbar_text_y + 1, plw_x_e_fill_width, plw_playerbar_text_height - 2)
			eBar:SetColor{0.85,0.85,0.6,1}
			eBar.font:SetColor{1,.5,.5,1}
			eBar:SetMinMax(0,1)
			function eBar:HitTest(x,y) return self end
			SafeAddChild(eBar,rBar)
		end
	end
	
	PLW_UpdateStateTeamControls(teamID)
end

-- creates team box
local function PLW_CreateTeamControls(teamID)
	local mainControl = Control:New{padding = {0, 0, 0, 0},color = {0, 0, 0, 0}}
	local resBar = Control:New{padding = {0, 0, 0, 0},color = {0, 0, 0, 0}}
	
	local mArmy = Label:New{autosize = false}
	local mStatic = Label:New{autosize = false}
	local mIncome = Label:New{autosize = false}
	local eIncome = Label:New{autosize = false}
	local metalBar = Chili.Progressbar:New{}
	local energyBar = Chili.Progressbar:New{}
	
	local subcon = {rBar = resBar, aVal = mArmy, dVal = mStatic, mInc = mIncome, eInc = eIncome, mBar = metalBar, eBar = energyBar}
	
	plw_vcon_teamControls[teamID] = CreateVcon(teamID, mainControl, subcon, 0, 0)
	
	PLW_ConfigureTeamControls(teamID)
end

function PLW_ComparePlayerVcons(vcon1, vcon2)
	if not vcon1.vID then -- the ally team bar should be at the top
		return false
	elseif not vcon2.vID then -- if neither of these are true, the vIDs should be team IDs
		return true
	elseif teamEntities[vcon1.vID] and teamEntities[vcon2.vID] then
		local elo1 = playerEntities[vcon1.vID].elo
		local res1 = playerEntities[vcon1.vID].resigned
		local elo2 = playerEntities[vcon2.vID].elo
		local res2 = playerEntities[vcon2.vID].resigned
		if res2 then 
			return false
		elseif res1 then
			return true
		elseif elo2 and (not elo1 or elo2 > elo1) then
			return true
		end
	end
	return false
end

-- updates player row
local function PLW_UpdateVolatilePlayerControls(eID)
	if (not playerEntities[eID]) or (not plw_vcon_playerControls[eID]) or (not plw_vcon_playerControls[eID].subcon) then
		return
	end
	
	-- TODO other player updates
	local teamStatusCol, teamStatusText
	local playerStatusText = ""
	
	if playerEntities[eID].cpu and playerEntities[eID].teamID then 
		teamStatusCol, teamStatusText, playerStatusText = FormatStatus(playerEntities[eID].active, playerEntities[eID].resigned, playerEntities[eID].cpu, Spring.GetTeamUnitCount(playerEntities[eID].teamID))
		plw_vcon_playerControls[eID].subcon.statusText.font:SetColor(teamStatusCol)
		plw_vcon_playerControls[eID].subcon.statusText:SetCaption(teamStatusText)
		plw_vcon_playerControls[eID].subcon.statusText:Invalidate()
	else
		plw_vcon_playerControls[eID].subcon.statusText.font:SetColor({0,0,0,0})
		plw_vcon_playerControls[eID].subcon.statusText:SetCaption('Q')
		plw_vcon_playerControls[eID].subcon.statusText:Invalidate()
	end
	
	if playerEntities[eID].ping and playerEntities[eID].cpu then
		local pingCol, cpuCol, pingText, cpuTxt = FormatPingCpu(playerEntities[eID].ping,playerEntities[eID].cpu)
		if options.plw_cpuPingAsText.value then
			plw_vcon_playerControls[eID].subcon.cpuText.font:SetColor(cpuCol)
			plw_vcon_playerControls[eID].subcon.cpuText:SetCaption(cpuTxt)
			plw_vcon_playerControls[eID].subcon.cpuText:Invalidate()
		else
			plw_vcon_playerControls[eID].subcon.cpuImage.color = cpuCol
			plw_vcon_playerControls[eID].subcon.cpuImage.tooltip = 'CPU: ' .. cpuTxt
			plw_vcon_playerControls[eID].subcon.cpuImage:Invalidate()
		end
		if options.plw_cpuPingAsText.value then
			plw_vcon_playerControls[eID].subcon.pingText.font:SetColor(pingCol)
			plw_vcon_playerControls[eID].subcon.pingText:SetCaption(pingText)
			plw_vcon_playerControls[eID].subcon.pingText:Invalidate()
		else
			plw_vcon_playerControls[eID].subcon.pingImage.color = pingCol
			plw_vcon_playerControls[eID].subcon.pingImage.tooltip = 'Ping: ' .. pingText
			plw_vcon_playerControls[eID].subcon.pingImage:Invalidate()
		end
	end
	
	if playerEntities[eID].isLeader then 
		--plw_vcon_playerControls[eID].subcon.country:Show()
	else
		--plw_vcon_playerControls[eID].subcon.country:Hide()
	end
end

local function PLW_UpdateStatePlayerControls(eID)
	if (not playerEntities[eID]) or (not plw_vcon_playerControls[eID]) or (not plw_vcon_playerControls[eID].subcon) then
		return
	end
	
	if playerEntities[eID].name then plw_vcon_playerControls[eID].subcon.name.caption = playerEntities[eID].name end
	if playerEntities[eID].teamcolor then
		if playerEntities[eID].resigned then
			plw_vcon_playerControls[eID].subcon.name.font.color = {0.5,0.5,0.5,1}
		else
			plw_vcon_playerControls[eID].subcon.name.font.color = playerEntities[eID].teamcolor
		end
	end
	plw_vcon_playerControls[eID].subcon.name:Invalidate()
	
	local clanicon, countryicon, rankicon = FormatCCR(playerEntities[eID].clan, playerEntities[eID].faction, playerEntities[eID].country, playerEntities[eID].level, playerEntities[eID].elo, playerEntities[eID].rank)
	if clanicon then 
		plw_vcon_playerControls[eID].subcon.clan.file = clanicon 
		plw_vcon_playerControls[eID].subcon.clan:Invalidate()
	end
	if countryicon then 
		-- country not displayed
		--plw_vcon_playerControls[eID].subcon.country.file = countryicon 
		--plw_vcon_playerControls[eID].subcon.country:Invalidate()
	end 
	if rankicon then 
		plw_vcon_playerControls[eID].subcon.rank.file = rankicon 
		plw_vcon_playerControls[eID].subcon.rank:Invalidate()
	end
	
	-- try shifting this playerbox up and down
	SortSingleVcon(plw_vcon_playerControls[eID], nil, PLW_ComparePlayerVcons, true, true)
	SortSingleVcon(plw_vcon_playerControls[eID], nil, PLW_ComparePlayerVcons, false, true)
	
	PLW_UpdateVolatilePlayerControls(eID)
end

-- configures player row
local function PLW_ConfigurePlayerControls(entityID)
	
	if not plw_vcon_playerControls[entityID] or not plw_vcon_playerControls[entityID].subcon then
		return
	end
	
	--if main then main:ClearChildren() else Spring.Echo("ERROR"); return end
	
	local main = plw_vcon_playerControls[entityID].main
	local clan = plw_vcon_playerControls[entityID].subcon.clan
	local country = plw_vcon_playerControls[entityID].subcon.country
	local rank = plw_vcon_playerControls[entityID].subcon.rank
	local name = plw_vcon_playerControls[entityID].subcon.name
	local statusText = plw_vcon_playerControls[entityID].subcon.statusText
	local cpuText = plw_vcon_playerControls[entityID].subcon.cpuText
	local pingText = plw_vcon_playerControls[entityID].subcon.pingText
	local cpuImage = plw_vcon_playerControls[entityID].subcon.cpuImage
	local pingImage = plw_vcon_playerControls[entityID].subcon.pingImage
	
	if main then main:SetPos(0, 0, plw_x_window_width, plw_playerbar_height) end
	if clan then clan:SetPos(plw_x_ccr_begin + plw_x_icon_clan_offset, 0, plw_x_icon_clan_width, plw_playerbar_image_height); main:AddChild(clan) end
	if country then country:SetPos(plw_x_ccr_begin + plw_x_icon_country_offset, 0, plw_x_icon_country_width, plw_playerbar_image_height); main:AddChild(country) end
	if rank then rank:SetPos(plw_x_ccr_begin + plw_x_icon_rank_offset, 0, plw_x_icon_rank_width, plw_playerbar_image_height); main:AddChild(rank) end
	if name then 
		name:SetPos(plw_x_name_begin + plw_x_name_offset, plw_playerbar_text_y, plw_x_name_width, plw_playerbar_text_height)
		name.font.size = plw_playerbar_text_height
		name:SetCaption("ERROR")
		main:AddChild(name)
	end
	if statusText then 
		statusText:SetPos(plw_x_playerstate_begin + plw_x_playerstate_offset, plw_playerbar_text_y, plw_x_icon_playerstate_width, plw_playerbar_text_height)
		--statusText:SetPos(plw_x_playerstate_begin + plw_x_playerstate_offset, 0, plw_x_icon_playerstate_width, plw_playerbar_image_height)
		statusText.font.size = plw_playerbar_text_height
		statusText:SetCaption("ERROR")
		main:AddChild(statusText) 
	end
	if options.plw_cpuPingAsText.value then
		if cpuImage then main:RemoveChild(cpuImage) end
		if pingImage then main:RemoveChild(pingImage) end
		if cpuText then 
			cpuText:SetPos(plw_x_cpuping_begin + plw_x_cpu_offset, plw_playerbar_text_y, plw_x_cpu_width, plw_playerbar_text_height) 
			cpuText.font.size = plw_playerbar_text_height
			cpuText:SetCaption("ERROR")
			main:AddChild(cpuText) 
		end
		if pingText then 
			pingText:SetPos(plw_x_cpuping_begin + plw_x_ping_offset, plw_playerbar_text_y, plw_x_ping_width, plw_playerbar_text_height) 
			pingText.font.size = plw_playerbar_text_height
			pingText:SetCaption("ERROR")
			main:AddChild(pingText) 
		end
	else
		if cpuText then main:RemoveChild(cpuText) end
		if pingText then main:RemoveChild(pingText) end
		if cpuImage then 
			cpuImage:SetPos(plw_x_cpuping_begin + plw_x_cpu_offset, 0, plw_x_cpu_width, plw_playerbar_image_height)
			cpuImage.file = "LuaUI/Images/playerlist/cpu.png"
			function cpuImage:HitTest(x,y) return self end
			cpuImage:Invalidate()
			main:AddChild(cpuImage) 
		end
		if pingImage then 
			pingImage:SetPos(plw_x_cpuping_begin + plw_x_ping_offset, 0, plw_x_ping_width, plw_playerbar_image_height)
			pingImage.file = "LuaUI/Images/playerlist/ping.png"
			function pingImage:HitTest(x,y) return self end
			pingImage:Invalidate()
			main:AddChild(pingImage)
		end
	end
	
	PLW_UpdateStatePlayerControls(entityID)
end

-- creates player row
local function PLW_CreatePlayerControls(entityID)

	local mainControl = Control:New{padding = {0, 0, 0, 0},color = {0, 0, 0, 0}}
	local clanImage = Image:New{}
	local countryImage = Image:New{}
	local rankImage = Image:New{}
	local nameLabel = Label:New{autosize = false}
	local statusLabel = Label:New{autosize = false}
	local cpuLabel = Label:New{autosize = false, align = "center"}
	local pingLabel = Label:New{autosize = false, align = "center"}
	local cpuIm = Image:New{}
	local pingIm = Image:New{}
	
	local subcon = {name = nameLabel, clan = clanImage, country = countryImage, rank = rankImage, statusText = statusLabel, cpuText = cpuLabel, pingText = pingLabel, cpuImage = cpuIm, pingImage = pingIm}
	
	plw_vcon_playerControls[entityID] = CreateVcon(entityID, mainControl, subcon, 0, 0)
	
	PLW_ConfigurePlayerControls(entityID)
	
end

function PLW_CompareSpectatorVcons(vcon1, vcon2)
	if not vcon1.vID then
		return false
	elseif not vcon2.vID then
		return true
	elseif spectatorEntities[vcon1.vID] and spectatorEntities[vcon2.vID] then
		local name1 = spectatorEntities[vcon1.vID].name
		local name2 = spectatorEntities[vcon2.vID].name
		if name1 and name2 then
			if name2 == "unknown" then 
				return false
			elseif name1 == "unknown" or name1 > name2 then 
				return true
			end
		end
	end

	return false
end

-- updates spectator row
local function PLW_UpdateVolatileSpectatorControls(eID)
	if (not spectatorEntities[eID]) or (not plw_vcon_spectatorControls[eID]) or (not plw_vcon_spectatorControls[eID].subcon) then
		return
	end
	
	if spectatorEntities[eID].ping and spectatorEntities[eID].cpu then
		local pingCol, cpuCol, pingText, cpuTxt = FormatPingCpu(spectatorEntities[eID].ping,spectatorEntities[eID].cpu)
		if options.plw_cpuPingAsText.value then
			plw_vcon_spectatorControls[eID].subcon.cpuText.font:SetColor(cpuCol)
			plw_vcon_spectatorControls[eID].subcon.cpuText:SetCaption(cpuTxt)
			plw_vcon_spectatorControls[eID].subcon.cpuText:Invalidate()
		else
			plw_vcon_spectatorControls[eID].subcon.cpuImage.color = cpuCol
			plw_vcon_spectatorControls[eID].subcon.cpuImage.tooltip = 'CPU: ' .. cpuTxt
			plw_vcon_spectatorControls[eID].subcon.cpuImage:Invalidate()
		end
		if options.plw_cpuPingAsText.value then
			plw_vcon_spectatorControls[eID].subcon.pingText.font:SetColor(pingCol)
			plw_vcon_spectatorControls[eID].subcon.pingText:SetCaption(pingText)
			plw_vcon_spectatorControls[eID].subcon.pingText:Invalidate()
		else
			plw_vcon_spectatorControls[eID].subcon.pingImage.color = pingCol
			plw_vcon_spectatorControls[eID].subcon.pingImage.tooltip = 'Ping: ' .. pingText
			plw_vcon_spectatorControls[eID].subcon.pingImage:Invalidate()
		end
	end
end

local function PLW_UpdateStateSpectatorControls(eID)
	if (not spectatorEntities[eID]) or (not plw_vcon_spectatorControls[eID]) or (not plw_vcon_spectatorControls[eID].subcon) then
		return
	end
	--if spectatorEntities[eID].name then plw_vcon_spectatorControls[eID].subcon.name.caption = spectatorEntities[eID].name end
	if spectatorEntities[eID].name then 
		plw_vcon_spectatorControls[eID].subcon.name:SetCaption(spectatorEntities[eID].name) 
		plw_vcon_spectatorControls[eID].subcon.name:Invalidate()
	end
	-- local clanicon, countryicon, rankicon = FormatCCR(spectatorEntities[eID].clan, spectatorEntities[eID].faction, spectatorEntities[eID].country, spectatorEntities[eID].level, spectatorEntities[eID].elo)
	-- if clanicon then 
		-- plw_vcon_spectatorControls[eID].subcon.clan.file = clanicon 
		-- plw_vcon_spectatorControls[eID].subcon.clan:Invalidate()
	-- end
	-- if countryicon then 
		-- plw_vcon_spectatorControls[eID].subcon.country.file = countryicon 
		-- plw_vcon_spectatorControls[eID].subcon.country:Invalidate()
	-- end 
	-- if rankicon then 
		-- Spring.Echo("Setting Spectator Rank Icon")
		-- plw_vcon_spectatorControls[eID].subcon.rank.file = rankicon 
		-- plw_vcon_spectatorControls[eID].subcon.rank:Invalidate()
	-- end

	-- try shifting this specbox up and down
	SortSingleVcon(plw_vcon_spectatorControls[eID], nil, PLW_CompareSpectatorVcons, true, true)
	SortSingleVcon(plw_vcon_spectatorControls[eID], nil, PLW_CompareSpectatorVcons, false, true)
	
	PLW_UpdateVolatileSpectatorControls(eID)
end

-- configures spectator row
local function PLW_ConfigureSpectatorControls(entityID)
	
	if not plw_vcon_spectatorControls[entityID] or not plw_vcon_spectatorControls[entityID].subcon then
		return
	end
	
	local main = plw_vcon_spectatorControls[entityID].main
	-- local clan = plw_vcon_spectatorControls[entityID].subcon.clan
	-- local country = plw_vcon_spectatorControls[entityID].subcon.country
	-- local rank = plw_vcon_spectatorControls[entityID].subcon.rank
	local name = plw_vcon_spectatorControls[entityID].subcon.name
	local statusText = plw_vcon_spectatorControls[entityID].subcon.statusText
	local cpuText = plw_vcon_spectatorControls[entityID].subcon.cpuText
	local pingText = plw_vcon_spectatorControls[entityID].subcon.pingText
	local cpuImage = plw_vcon_spectatorControls[entityID].subcon.cpuImage
	local pingImage = plw_vcon_spectatorControls[entityID].subcon.pingImage
	
	--if main then main:ClearChildren() else Spring.Echo("ERROR"); return end
	
	if main then main:SetPos(0, 0, plw_x_window_width, plw_playerbar_height) end
	-- if clan then clan:SetPos(plw_x_ccr_begin + plw_x_icon_clan_offset, 0, plw_x_icon_clan_width, plw_playerbar_image_height); main:AddChild(clan) end
	-- if country then country:SetPos(plw_x_ccr_begin + plw_x_icon_country_offset, 0, plw_x_icon_country_width, plw_playerbar_image_height); main:AddChild(country) end
	-- if rank then rank:SetPos(plw_x_ccr_begin + plw_x_icon_rank_offset, 0, plw_x_icon_rank_width, plw_playerbar_image_height); main:AddChild(rank) end
	if name then 
		name:SetPos(plw_x_name_spectator_begin + plw_x_name_spectator_offset, plw_playerbar_text_y, plw_x_name_spectator_width, plw_playerbar_text_height)
		name.font.size = plw_playerbar_text_height
		name:SetCaption("ERROR")
		main:AddChild(name)
	end
	if statusText then 
		statusText:SetPos(plw_x_playerstate_spectator_begin + plw_x_playerstate_spectator_offset, 0, plw_x_icon_playerstate_spectator_width, plw_playerbar_text_height)
		statusText.font.size = plw_playerbar_text_height
		statusText:SetCaption("")
		main:AddChild(statusText) 
	end
	if options.plw_cpuPingAsText.value then
		if cpuImage then main:RemoveChild(cpuImage) end
		if pingImage then main:RemoveChild(pingImage) end
		if cpuText then 
			cpuText:SetPos(plw_x_cpuping_spectator_begin + plw_x_cpu_spectator_offset, plw_playerbar_text_y, plw_x_cpu_width, plw_playerbar_text_height) 
			cpuText.font.size = plw_playerbar_text_height
			cpuText:SetCaption("ERROR")
			main:AddChild(cpuText) 
			
		end
		if pingText then 
			pingText:SetPos(plw_x_cpuping_spectator_begin + plw_x_ping_spectator_offset, plw_playerbar_text_y, plw_x_ping_width, plw_playerbar_text_height) 
			pingText.font.size = plw_playerbar_text_height
			pingText:SetCaption("ERROR")
			main:AddChild(pingText) 
		end
	else
		if cpuText then main:RemoveChild(cpuText) end
		if pingText then main:RemoveChild(pingText) end
		if cpuImage then 
			cpuImage:SetPos(plw_x_cpuping_spectator_begin + plw_x_cpu_spectator_offset, 0, plw_x_cpu_width, plw_playerbar_image_height)
			cpuImage.file = "LuaUI/Images/playerlist/cpu.png"
			function cpuImage:HitTest(x,y) return self end
			cpuImage:Invalidate()
			main:AddChild(cpuImage) 
		end
		if pingImage then 
			pingImage:SetPos(plw_x_cpuping_spectator_begin + plw_x_ping_spectator_offset, 0, plw_x_ping_width, plw_playerbar_image_height)
			pingImage.file = "LuaUI/Images/playerlist/ping.png"
			function pingImage:HitTest(x,y) return self end
			pingImage:Invalidate()
			main:AddChild(pingImage)
		end
	end
	
	PLW_UpdateStateSpectatorControls(entityID, true)
end

-- creates spectator row
local function PLW_CreateSpectatorControls(entityID)

	local mainControl = Control:New{padding = {0, 0, 0, 0},color = {0, 0, 0, 0}}
	-- local clanImage = Image:New{}
	-- local countryImage = Image:New{}
	-- local rankImage = Image:New{}
	local nameLabel = Label:New{autosize = false}
	local statusLabel = Label:New{autosize = false}
	local cpuLabel = Label:New{autosize = false, align = "center"}
	local pingLabel = Label:New{autosize = false, align = "center"}
	local cpuIm = Image:New{}
	local pingIm = Image:New{}
	
	--local subcon = {name = nameLabel, clan = clanImage, country = countryImage, rank = rankImage, statusText = statusLabel, cpuText = cpuLabel, pingText = pingLabel, cpuImage = cpuIm, pingImage = pingIm}
	local subcon = {name = nameLabel, statusText = statusLabel, cpuText = cpuLabel, pingText = pingLabel, cpuImage = cpuIm, pingImage = pingIm}
	
	plw_vcon_spectatorControls[entityID] = CreateVcon(entityID, mainControl, subcon, 0, 0)
	
	PLW_ConfigureSpectatorControls(entityID)
	
end

local function PLW_CreateInitialControls()
	
	for eID, _ in pairs(playerEntities) do
		PLW_CreatePlayerControls(eID)
	end
	
	for eID, _ in pairs(spectatorEntities) do
		PLW_CreateSpectatorControls(eID)
	end
	
	for tID, _ in pairs(teamEntities) do
		PLW_CreateTeamControls(tID)
	end
	
	for atID, _ in pairs(allyTeamEntities) do
		PLW_CreateAllyTeamControls(atID)
	end
	
	PLW_CreateStaticControls()
	
	PLW_AutoSetHeight()
	
end

-- Puts the headers at the top of the panel.
-- local function AddTableHeaders()
	-- local fontsize = options.text_height.value
	-- local row = 0
	-- if options.show_resource_status.value then
		-- plw_vcon_scrollPanel.main:AddChild( Image:New{ x=x_m_mobiles + x_m_mobiles_width/2 -5, y=5,	height = (fontsize)+1, color =	{1, .3, .3, 1},  file = 'LuaUI/Images/commands/Bold/attack.png',} )
		-- plw_vcon_scrollPanel.main:AddChild( Image:New{ x=x_m_defense + x_m_defense_width/2 -5, y=5,	height = (fontsize)+1, color = {.3, .3, 1, 1}, file = 'LuaUI/Images/commands/Bold/guard.png',} )
		-- plw_vcon_scrollPanel.main:AddChild( Image:New{ x=x_e_income + x_e_income_width/2 -7, y=5,	height = (fontsize)+1,  file = 'LuaUI/Images/energy.png',} )
		-- plw_vcon_scrollPanel.main:AddChild( Image:New{ x=x_m_income + x_m_income_width/2 -7, y=5,	height = (fontsize)+1, file = 'LuaUI/Images/ibeam.png',} )
	-- end
	-- if options.show_cpu_ping.value then
		-- plw_vcon_scrollPanel.main:AddChild( Label:New{ x=x_cpu, y=5,	caption = 'C', 	fontShadow = true,  fontsize = fontsize,} )
		-- plw_vcon_scrollPanel.main:AddChild( Label:New{ x=x_ping, y=5,	caption = 'P', 	fontShadow = true,  fontsize = fontsize,} )
	-- end
-- end

local function PLW_UpdateVisibility()
	if screen0 and plw_windowPlayerlist then
		if options.plw_visible.value then
			screen0:AddChild(plw_windowPlayerlist)
		else
			screen0:RemoveChild(plw_windowPlayerlist)
		end
	end
end

function PLW_Toggle()
	options.plw_visible.value = not options.plw_visible.value
	if PLW_UpdateVisibility then PLW_UpdateVisibility() end
end

WG.TogglePlayerlistWindow = PLW_Toggle -- called by global commands widget

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
-- interface for all displays

local function UpdateAllControls()

	local anyLargeUpdate = false

	for eID, _ in pairs(playerEntities) do
		if playerEntities[eID].needsVisUpdate then
			if playerEntities[eID].needsFullVisUpdate then
				PLW_UpdateStatePlayerControls(eID)
				playerEntities[eID].needsFullVisUpdate = false
				anyLargeUpdate = true
			else
				PLW_UpdateVolatilePlayerControls(eID)
			end
			playerEntities[eID].needsVisUpdate = false	
		end
	end
	
	for sID, _ in pairs(spectatorEntities) do
		if spectatorEntities[sID].needsVisUpdate then
			if spectatorEntities[sID].needsFullVisUpdate then
				PLW_UpdateStateSpectatorControls(sID)
				spectatorEntities[sID].needsFullVisUpdate = false
				anyLargeUpdate = true
			else
				PLW_UpdateVolatileSpectatorControls(sID)
			end
			spectatorEntities[sID].needsVisUpdate = false	
		end
	end
	
	for tID, _ in pairs(teamEntities) do
		if teamEntities[tID].needsVisUpdate then
			if teamEntities[tID].needsFullVisUpdate then
				PLW_UpdateStateTeamControls(tID)
				teamEntities[tID].needsFullVisUpdate = false
				anyLargeUpdate = true
			else
				PLW_UpdateVolatileTeamControls(tID)
			end
			teamEntities[tID].needsVisUpdate = false	
		end
	end
	
	drawTeamnames = false
	for atID, _ in pairs(allyTeamEntities) do
		if allyTeamEntities[atID].drawTeamname then drawTeamnames = true end
	end
	
	for atID, _ in pairs(allyTeamEntities) do
		if allyTeamEntities[atID].needsVisUpdate then
			if allyTeamEntities[atID].needsFullVisUpdate then
				PLW_UpdateStateAllyTeamControls(atID)
				allyTeamEntities[atID].needsFullVisUpdate = false
				anyLargeUpdate = true
			else
				PLW_UpdateVolatileAllyTeamControls(atID)
			end
			allyTeamEntities[atID].needsVisUpdate = false	
		end
	end
	
	if playerlistNeedsFullVisUpdate then
		PLW_UpdateStatePlayerListControl()
		playerlistNeedsFullVisUpdate = false
		anyLargeUpdate = true
	end
	
	if speclistNeedsFullVisUpdate then
		PLW_UpdateStateSpectatorListControl()
		speclistNeedsFullVisUpdate = false
		anyLargeUpdate = true
	end
	
	if anyLargeUpdate then
		PLW_AutoSetHeight()
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- functions for entity handling

local function CreateHumanPlayerEntity(pID)
	--local name,act,spectator,tID,atID,pingTime,cpuUsage,country,rank,customKeys = Spring.GetPlayerInfo(pID)
	--local _,leader,isDead,isAI,side,_,customTeamKeys,incomeMultiplier = Spring.GetTeamInfo(tID)
	return { isAI = false, playerID = pID, teamID = nil, allyTeamID = nil, active = "", isLeader = true, resigned = false, clan = "", faction = "", country = "", level = "", elo = "", rank = "", name = "", teamcolor = "", cpu = 0, ping = 0, needsVisUpdate = false, needsFullVisUpdate = false}
end

local function CreateAIPlayerEntity(tID)
	local skirmishAIID, name, hostingPlayerID, shortName, version, options = Spring.GetAIInfo(tID)
	--local _,leader,isDead,isAI,side,atID,customTeamKeys,incomeMultiplier = Spring.GetTeamInfo(tID)
	return { isAI = true, playerID = hostingPlayerID, teamID = tID, allyTeamID = nil, active = "", leader = true, resigned = false, clan = "", faction = "", country = "", level = "", elo = "", rank = "", name = "", teamcolor = "", cpu = 0, ping = 0, needsVisUpdate = false, needsFullVisUpdate = false}
end

local function CreateSpectatorEntity(pID)
	--local name,act,spectator,tID,atID,pingTime,cpuUsage,country,rank,customKeys = Spring.GetPlayerInfo(pID)
	return { playerID = pID, active = "", clan = "", faction = "", country = "", level = "", elo = "", name = "", teamID = nil, cpu = 0, ping = 0, needsVisUpdate = false, needsFullVisUpdate = false}
end

local function CreateTeamEntity(tID)
	local _,leader,isDead,ai,side,_,customTeamKeys,incomeMultiplier = Spring.GetTeamInfo(tID)
	return { teamID = tID, allyTeamID = nil, isAI = ai, memberPEIDs = {}, elo = false, resigned = false, m_mobiles = 0, m_defence = 0, m_income = 0, e_income = 0, m_curr = 0, m_stor = 0, e_curr = 0, e_stor = 0, needsVisUpdate = false, needsFullVisUpdate = false}
end

local function CreateAllyTeamEntity(atID)
	return { allyteamID = atID, memberTEIDs = {}, resigned = false, clan = "", country = "", name = "", m_mobiles = 0, m_defence = 0, m_income = 0, e_income = 0, m_curr = 0, m_stor = 0, e_curr = 0, e_stor = 0, drawTeamname = true, drawTeamEcon = false, needsVisUpdate = false, needsFullVisUpdate = false}
end

local function UpdateAllyTeamEntity(atID, fullUpdate)
	if allyTeamEntities[atID] then
	
		-- this depends on the team update being done first. kind of ugly but whatever
		allyTeamEntities[atID].m_mobiles = 0
		allyTeamEntities[atID].m_defence = 0
		allyTeamEntities[atID].m_income = 0
		allyTeamEntities[atID].e_income = 0
		allyTeamEntities[atID].m_curr = 0
		allyTeamEntities[atID].m_stor = 0
		allyTeamEntities[atID].e_curr = 0
		allyTeamEntities[atID].e_stor = 0
		for tEID, _ in pairs(allyTeamEntities[atID].memberTEIDs) do
			if teamEntities[tEID].m_mobiles then allyTeamEntities[atID].m_mobiles = allyTeamEntities[atID].m_mobiles + teamEntities[tEID].m_mobiles end
			if teamEntities[tEID].m_defence then allyTeamEntities[atID].m_defence = allyTeamEntities[atID].m_defence + teamEntities[tEID].m_defence end
			if teamEntities[tEID].m_income then allyTeamEntities[atID].m_income = allyTeamEntities[atID].m_income + teamEntities[tEID].m_income end
			if teamEntities[tEID].e_income then allyTeamEntities[atID].e_income = allyTeamEntities[atID].e_income + teamEntities[tEID].e_income end
			if teamEntities[tEID].m_curr then allyTeamEntities[atID].m_curr = allyTeamEntities[atID].m_curr + teamEntities[tEID].m_curr end
			if teamEntities[tEID].m_stor then allyTeamEntities[atID].m_stor = allyTeamEntities[atID].m_stor + teamEntities[tEID].m_stor end
			if teamEntities[tEID].e_curr then allyTeamEntities[atID].e_curr = allyTeamEntities[atID].e_curr + teamEntities[tEID].e_curr end
			if teamEntities[tEID].e_stor then allyTeamEntities[atID].e_stor = allyTeamEntities[atID].e_stor + teamEntities[tEID].e_stor end
		end
		
		if fullUpdate then
			
			local allResign = true
			local playercount = 0
			local teamcount = 0
			for tEID, _ in pairs(allyTeamEntities[atID].memberTEIDs) do
				if teamEntities[tEID].isAI then
					playercount = playercount + 1
					teamcount = teamcount + 1
					allResign = false
				else
					local thisteamcount = 0
					for pEID, _ in pairs(teamEntities[tEID].memberPEIDs) do
						thisteamcount = thisteamcount + 1
						if allResign and not playerEntities[pEID].resigned then
							allResign = false
						end
					end
					playercount = playercount + thisteamcount
					if thisteamcount > 0 then
						teamcount = teamcount + 1
					end
				end
			end
			allyTeamEntities[atID].resigned = allResign
			if teamcount > 1 then allyTeamEntities[atID].drawTeamEcon = true else allyTeamEntities[atID].drawTeamEcon = false end
			if playercount > 1 then allyTeamEntities[atID].drawTeamname = true else allyTeamEntities[atID].drawTeamname = false end
			
			allyTeamEntities[atID].clan = ""
			allyTeamEntities[atID].country = ""
			
			local name = Spring.GetGameRulesParam("allyteam_long_name_" .. atID)
			if string.len(name) > 10 then
				name = Spring.GetGameRulesParam("allyteam_short_name_" .. atID)
			end
			
			allyTeamEntities[atID].name = name
			allyTeamEntities[atID].needsFullVisUpdate = true
		end
	--{ allyteamID = atID, memberEIDs = {}, status = "", resigned = false, clan = "", country = "", name = "", m_mobiles = "", m_defence = "", m_income = "", e_income = ""}
	
		allyTeamEntities[atID].needsVisUpdate = true
	end
end

local function UpdateTeamEntity(tID, fullUpdate)
	local _,leader,isDead,isAI,side,atID,customTeamKeys,incomeMultiplier = Spring.GetTeamInfo(tID)
	if teamEntities[tID] then
		if fullUpdate then
			local numPlayers = 0
			local allResign = true
			for pEID, _ in pairs(teamEntities[tID].memberPEIDs) do
				numPlayers = numPlayers + 1
				if not teamEntities[tID].elo or (playerEntities[pEID].elo and playerEntities[pEID].elo ~= "" and playerEntities[pEID].elo > teamEntities[tID].elo) then 
					teamEntities[tID].elo = playerEntities[pEID].elo
				end
				if allResign and not playerEntities[pEID].resigned then
					allResign = false
				end
				teamEntities[tID].resigned = allResign
			end
			--if numPlayers > 0 or teamEntities[tID].isAI then
			if true then
				if atID ~= teamEntities[tID].allyTeamID then
					local oldAllyTeam = teamEntities[tID].allyTeamID
					local newAllyTeam = atID
					if oldAllyTeam and allyTeamEntities[oldAllyTeam] and allyTeamEntities[oldAllyTeam].memberTEIDs[tID] then 
						allyTeamEntities[oldAllyTeam].memberTEIDs[tID] = nil 
					end
					if newAllyTeam then
						if not allyTeamEntities[newAllyTeam] then
							allyTeamEntities[newAllyTeam] = CreateAllyTeamEntity(tID)
							playerlistNeedsFullVisUpdate = true
						end
						allyTeamEntities[newAllyTeam].memberTEIDs[tID] = true
					end
					if oldAllyTeam then UpdateAllyTeamEntity(oldAllyTeam, true) end
					if newAllyTeam then UpdateAllyTeamEntity(newAllyTeam, true) end
					teamEntities[tID].allyTeamID = newAllyTeam
				end
			else
				local oldAllyTeam = teamEntities[tID].allyTeamID
				if oldAllyTeam and allyTeamEntities[oldAllyTeam] and allyTeamEntities[oldAllyTeam].memberTEIDs[tID] then 
					allyTeamEntities[oldAllyTeam].memberTEIDs[tID] = nil 
					UpdateAllyTeamEntity(oldAllyTeam, true)
				end
			end
			teamEntities[tID].needsFullVisUpdate = true
			if atID then UpdateAllyTeamEntity(atID, true) end
		end
		
		teamEntities[tID].m_mobiles = 0
		local army = Spring.GetTeamRulesParam(tID, "stats_history_unit_value_army_current")
		local other = Spring.GetTeamRulesParam(tID,"stats_history_unit_value_other_current")
		if army then teamEntities[tID].m_mobiles = teamEntities[tID].m_mobiles + army end
		if other then teamEntities[tID].m_mobiles = teamEntities[tID].m_mobiles + other end
		teamEntities[tID].m_defence = Spring.GetTeamRulesParam(tID, "stats_history_unit_value_def_current") or 0
		local eCurr, eStor, ePull, eInco, eExpe, eShar, eSent, eReci = Spring.GetTeamResources(tID, "energy")
		local mCurr, mStor, mPull, mInco, mExpe, mShar, mSent, mReci = Spring.GetTeamResources(tID, "metal")
		teamEntities[tID].m_income = mInco or 0
		teamEntities[tID].e_income = (eInco or 0) + 
		(Spring.GetTeamRulesParam(tID, "OD_energyIncome") or 0) - 
		math.max(0, (Spring.GetTeamRulesParam(tID, "OD_energyChange") or 0)) --TODO
		teamEntities[tID].m_curr = mCurr or 0 --TODO
		teamEntities[tID].m_stor = (mStor and HIDDEN_STORAGE) and mStor - HIDDEN_STORAGE or 0
		teamEntities[tID].e_curr = eCurr or 0
		teamEntities[tID].e_stor = (eStor and HIDDEN_STORAGE) and eStor - HIDDEN_STORAGE or 0
		if teamEntities[tID].e_stor > 50000 then teamEntities[tID].e_stor = 1000 end
		
		teamEntities[tID].needsVisUpdate = true
	end
	
end

local function UpdateSpectatorEntity(eID, fullUpdate)
	if spectatorEntities[eID] then
		local name,act,spectator,tID,atID,ping,cpu,country,rank,customKeys = Spring.GetPlayerInfo(spectatorEntities[eID].playerID)
		local clan, faction, level, elo
		if customKeys then
			clan = customKeys.clan
			faction = customKeys.faction
			level = customKeys.level
			elo = customKeys.elo
			rank = customKeys.icon
		end
		if fullUpdate then
			spectatorEntities[eID].clan = clan
			spectatorEntities[eID].country = country
			spectatorEntities[eID].faction = faction
			spectatorEntities[eID].level = level
			spectatorEntities[eID].elo = elo
			spectatorEntities[eID].name = name
			spectatorEntities[eID].teamID = tID
			spectatorEntities[eID].needsFullVisUpdate = true
		end
		
		spectatorEntities[eID].cpu = cpu
		spectatorEntities[eID].ping = ping
		
		spectatorEntities[eID].needsVisUpdate = true
	end
end

local function UpdatePlayerEntity(eID, fullUpdate)
	if playerEntities[eID] then
		if playerEntities[eID].isAI then
			local _, ainame, hostingPlayerID, aishortName, _, _ = Spring.GetAIInfo(playerEntities[eID].teamID)
			local _,leader,isDead,isAI,side,atID,customTeamKeys,incomeMultiplier = Spring.GetTeamInfo(playerEntities[eID].teamID)
			local _,_,_,_,_,hostping,hostcpu,_,_,_ = Spring.GetPlayerInfo(hostingPlayerID)
			
			if fullUpdate then
				if (IsMission == false) then
					ainame = '<'.. ainame ..'> '.. aishortName
				end
				playerEntities[eID].name = ainame
				playerEntities[eID].allyTeamID = atID
				playerEntities[eID].needsFullVisUpdate = true
				
				if not teamEntities[playerEntities[eID].teamID] then
					teamEntities[playerEntities[eID].teamID] = CreateTeamEntity(playerEntities[eID].teamID)
				end
				teamEntities[playerEntities[eID].teamID].memberPEIDs[eID] = true
				
				teamEntities[playerEntities[eID].teamID].needsFullVisUpdate = true
			end
			--TODO other updates
			playerEntities[eID].cpu = hostcpu
			playerEntities[eID].ping = hostping
			playerEntities[eID].teamcolor = (playerEntities[eID].teamID and playerEntities[eID].teamID ~= -1) and {Spring.GetTeamColor(playerEntities[eID].teamID)} or {1,1,1,1}
		else
			local name,act,spectator,tID,atID,ping,cpu,country,_,customKeys = Spring.GetPlayerInfo(playerEntities[eID].playerID)
			local _,leader,isDead,isAI,side,atID,customTeamKeys,incomeMultiplier = Spring.GetTeamInfo(tID)
			local clan, faction, level, elo
			if customKeys then
				clan = customKeys.clan
				faction = customKeys.faction
				level = customKeys.level
				elo = customKeys.elo
				rank = customKeys.icon
			end
			
			if fullUpdate then
				playerEntities[eID].allyTeamID = atID
				playerEntities[eID].clan = clan
				playerEntities[eID].country = country
				playerEntities[eID].faction = faction
				playerEntities[eID].level = level
				playerEntities[eID].elo = elo
				playerEntities[eID].rank = rank
				playerEntities[eID].name = name
				playerEntities[eID].isLeader = (leader == playerEntities[eID].playerID)
			
				if spectator and not playerEntities[eID].resigned then
					playerEntities[eID].resigned = true
					local oldTeam = playerEntities[eID].teamID
					if oldTeam and teamEntities[oldTeam] then 
						UpdateTeamEntity(oldTeam, true)
					end
					if not spectatorLookup[playerEntities[eID].playerID] then
						local specEID = #spectatorEntities + 1
						spectatorEntities[specEID] = CreateSpectatorEntity(playerEntities[eID].playerID)
						speclistNeedsFullVisUpdate = true
						spectatorLookup[playerEntities[eID].playerID] = specEID
						UpdateSpectatorEntity(specEID, true)
					end
				end
			
				if tID ~= playerEntities[eID].teamID then
					local oldTeam = playerEntities[eID].teamID
					local newTeam = tID
					if oldTeam and teamEntities[oldTeam] and teamEntities[oldTeam].memberPEIDs[eID] then 
						teamEntities[oldTeam].memberPEIDs[eID] = nil 
					end
					if newTeam then
						if not teamEntities[newTeam] then
							teamEntities[newTeam] = CreateTeamEntity(tID)
						end
						teamEntities[newTeam].memberPEIDs[eID] = true
					end
					if oldTeam then UpdateTeamEntity(oldTeam, true) end
					if newTeam then UpdateTeamEntity(newTeam, true) end
					playerEntities[eID].teamID = newTeam
				end
				if tID then UpdateTeamEntity(tID, true) end
				playerEntities[eID].needsFullVisUpdate = true
			end
			--TODO other updates
			playerEntities[eID].active = act
			playerEntities[eID].cpu = cpu
			playerEntities[eID].ping = ping
			playerEntities[eID].teamcolor = (playerEntities[eID].teamID and playerEntities[eID].teamID ~= -1) and {Spring.GetTeamColor(playerEntities[eID].teamID)} or {1,1,1,1}
		end
		playerEntities[eID].needsVisUpdate = true
	end
end

local function AddHumanEntity(playerID)
	local eID = false
	if playerID then
		local name,active,spectator,teamID,allyTeamID,pingTime,cpuUsage,country,rank,customKeys = Spring.GetPlayerInfo(playerID)
		spec = spectator
		if spectator then
			if not spectatorLookup[playerID] then
				eID = #spectatorEntities + 1
				spectatorEntities[eID] = CreateSpectatorEntity(playerID)
				spectatorLookup[playerID] = eID
			end
			UpdateSpectatorEntity(eID, true)
			speclistNeedsFullVisUpdate = true
		else
			if not humanLookup[playerID] then
				eID = #playerEntities + 1
				playerEntities[eID] = CreateHumanPlayerEntity(playerID)
				humanLookup[playerID] = eID
			end
			
			UpdatePlayerEntity(eID, true)
			playerlistNeedsFullVisUpdate = true
		end
	end
	return eID
end

local function AddAIEntity(teamID)
	local eID = false
	if teamID then
		local skirmishAIID, name, hostingPlayerID, shortName, version, options = Spring.GetAIInfo(teamID)
		local _,leader,isDead,isAI,side,allyTeamID,customTeamKeys,incomeMultiplier = Spring.GetTeamInfo(teamID)
		
		if not aiLookup[teamID] then
			eID = #playerEntities + 1
			playerEntities[eID] = CreateAIPlayerEntity(teamID)
			aiLookup[teamID] = eID
		end
		
		UpdatePlayerEntity(eID, true)
		playerlistNeedsFullVisUpdate = true
	
		-- if not teamEntities[teamID] then
			-- teamEntities[teamID] = CreateTeamEntity(teamID)
		-- end
		UpdateTeamEntity(teamID, true)
	end
	return eID
end

local function CreateInitialEntities()
	local playersList = Spring.GetPlayerList()
	local teamsList = Spring.GetTeamList()
	
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
		Spring.Echo("Playerlist Window Debug: Adding Player with playerID:"..playerID)
		AddHumanEntity(playerID)
	end
	
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- functions for ...

local function checkMyself()
	myID = Spring.GetMyPlayerID()
	myName,_,iAmSpec = Spring.GetPlayerInfo(myID)
	myTeam = Spring.GetMyTeamID()
	myAllyTeam = Spring.GetMyAllyTeamID()
end
	

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- callins

function widget:Update(dt)
	timer = timer + dt
	if timer > UPDATE_FREQUENCY then
		timer = 0
		for eID, _ in pairs(playerEntities) do
			UpdatePlayerEntity(eID, false)
		end
		for eID, _ in pairs(spectatorEntities) do
			UpdateSpectatorEntity(eID, false)
		end
		for eID, _ in pairs(teamEntities) do
			UpdateTeamEntity(eID, false)
		end
		for eID, _ in pairs(allyTeamEntities) do
			UpdateAllyTeamEntity(eID, false)
		end
	end
	
	UpdateAllControls()
end

function widget:PlayerChanged(playerID)
	Spring.Echo("Playerlist Window Debug: PlayerChanged called, pID "..playerID)
	
	checkMyself()
	
	if playerID then
		if not humanLookup[playerID] and not spectatorLookup[playerID] then
			local eID = AddHumanEntity(playerID)
			if humanLookup[playerID] then
				if not plw_vcon_playerControls[eID] then
					PLW_CreatePlayerControls(eID)
				end
			elseif spectatorLookup[playerID] then
				if not plw_vcon_spectatorControls[eID] then
					PLW_CreateSpectatorControls(eID)
				end
			end
		else
			if humanLookup[playerID] then
				UpdatePlayerEntity(humanLookup[playerID], true)
				if not plw_vcon_playerControls[humanLookup[playerID]] then
					PLW_CreatePlayerControls(humanLookup[playerID])
				end
			end -- something can become a spectator after UpdatePlayerEntity so this should not be an elseif.
			if spectatorLookup[playerID] then
				UpdateSpectatorEntity(spectatorLookup[playerID], true)
				if not plw_vcon_spectatorControls[spectatorLookup[playerID]] then
					PLW_CreateSpectatorControls(spectatorLookup[playerID])
				end
			end
		end
	end
end

function widget:PlayerAdded(playerID)
	Spring.Echo("Playerlist Window Debug: PlayerAdded called, pID "..playerID)
	
	checkMyself()
	
	if playerID then
		if not humanLookup[playerID] and not spectatorLookup[playerID] then
			local eID = AddHumanEntity(playerID)
			if humanLookup[playerID] then
				if not plw_vcon_playerControls[humanLookup[playerID]] then
					PLW_CreatePlayerControls(humanLookup[playerID])
				end
			elseif spectatorLookup[playerID] then
				if not plw_vcon_spectatorControls[spectatorLookup[playerID]] then
					PLW_CreateSpectatorControls(spectatorLookup[playerID])
				end
			end
		else
			if humanLookup[playerID] then
				UpdatePlayerEntity(humanLookup[playerID], true)
				if not plw_vcon_playerControls[humanLookup[playerID]] then
					PLW_CreatePlayerControls(humanLookup[playerID])
				end
			end -- something can become a spectator after UpdatePlayerEntity so this should not be an elseif.
			if spectatorLookup[playerID] then
				UpdateSpectatorEntity(spectatorLookup[playerID], true)
				if not plw_vcon_spectatorControls[spectatorLookup[playerID]] then
					PLW_CreateSpectatorControls(spectatorLookup[playerID])
				end
			end
		end
	end
	
	-- if playerID then
		-- if humanLookup[playerID] then
			-- UpdatePlayerEntity(humanLookup[playerID], true)
			-- --PLW_UpdateStatePlayerControls(humanLookup[playerID])
		-- end
		-- if spectatorLookup[playerID] then
			-- UpdateSpectatorEntity(spectatorLookup[playerID], true)
		-- end
		-- else
			-- local eID = AddHumanEntity(playerID)
			-- if humanLookup[playerID] then
				-- if not plw_vcon_playerControls[eID] then
					-- PLW_CreatePlayerControls(eID)
				-- end
			-- elseif spectatorLookup[playerID] then
				-- if not plw_vcon_spectatorControls[eID] then
					-- PLW_CreateSpectatorControls(eID)
				-- end
			-- end
		-- end
	-- end
end

function widget:PlayerRemoved(playerID)
	Spring.Echo("Playerlist Window Debug: PlayerRemoved called, pID "..playerID)
	
	checkMyself()
	
	if playerID then
		if humanLookup[playerID] then
			UpdatePlayerEntity(humanLookup[playerID], true)
		elseif spectatorLookup[playerID] then
			UpdateSpectatorEntity(spectatorLookup[playerID], true)
		else
			--AddHumanEntity(playerID)
		end
	end
end

function widget:TeamDied(teamID)
	Spring.Echo("Playerlist Window Debug: TeamDied called, tID "..teamID)
	
	checkMyself()
	
	if teamID then
		if aiLookup[teamID] then
			UpdatePlayerEntity(aiLookup[teamID], true)
		end
		if teamEntities[teamID] then
			UpdateTeamEntity(teamID)
		end
	end
end

function widget:TeamChanged(teamID)
	Spring.Echo("Playerlist Window Debug: TeamChanged called, tID "..teamID)
	
	checkMyself()
	
	if teamID then
		local _,leader,isDead,isAI,side,allyTeamID,customTeamKeys,incomeMultiplier = Spring.GetTeamInfo(teamID)
		if isAI then 
			if aiLookup[teamID] then
				UpdatePlayerEntity(aiLookup[teamID], true)
			else
				AddAIEntity(teamID)
			end
		end
		if teamEntities[teamID] then
			UpdateTeamEntity(teamID)
		end
		-- if a team is created we trust that this has been dealt with in a player update.
	end
end

function widget:Initialize()
	if (not WG.Chili) then
		widgetHandler:RemoveWidget()
		return
	end

	checkMyself()

	Chili = WG.Chili
	Line = Chili.Line
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
	
	CreateInitialEntities()

	PLW_CalculateDimensions()
	PLW_CreateInitialControls()
	
	--AddTableHeaders()
	

	--Spring.SendCommands("endgraph 0")
	
	--widgetHandler:RegisterGlobal("PlayerListWindow", PlayerListWindow)
	
	options.plw_visible.value = true
	if PLW_UpdateVisibility then PLW_UpdateVisibility() end
	
	--SetTeamNamesAndColors()
	
	--if Spring.IsGameOver() then
	--	showEndgameWindowTimer = 1
	--end
	
	if DEBUG then
		plw_debugButton = Button:New{
			height=25;
			width=50;
			x=70;
			bottom=10;
			caption="DEBUG",
			OnClick = {
				function() 
					for eID, data in pairs(playerEntities) do
						if not data.isAI then
							--local name,active,spectator,teamID,allyTeamID,pingTime,cpuUsage,country,rank,customKeys = Spring.GetPlayerInfo(data.playerID)
							if playerEntities[eID].active then act = "true" else act = "false" end
							Spring.Echo("Playerlist Window Debug: "..data.name.." (Player) active:"..act.." playerID:"..data.playerID.." teamID:"..data.teamID.." elo:"..data.elo.." allyTeamID:"..data.allyTeamID)
						end
					end
					
					for eID, data in pairs(spectatorEntities) do
							--local name,active,spectator,teamID,allyTeamID,pingTime,cpuUsage,country,rank,customKeys = Spring.GetPlayerInfo(data.playerID)
							Spring.Echo("Playerlist Window Debug: "..data.name.." (Spectator)".." playerID:"..data.playerID.." teamID:"..data.teamID)
					end
					
					for tID, data in pairs(teamEntities) do
						Spring.Echo("Playerlist Window Debug: Team "..tID.." has ")
						Spring.Echo("elo:"..tostring(data.elo).." resigned:"..tostring(data.resigned).." players:")
						if data.isAI then
							Spring.Echo(playerEntities[aiLookup[tID]].name)
						else
							for eID, _ in pairs(data.memberPEIDs) do
								Spring.Echo(playerEntities[eID].name)
							end
						end
					end
					
					for atID, data in pairs(allyTeamEntities) do
						Spring.Echo("Playerlist Window Debug: AllyTeam "..atID.." has name "..data.name.." and players:")
						for tID, _ in pairs(data.memberTEIDs) do
							if teamEntities[tID].isAI then
								Spring.Echo(playerEntities[aiLookup[tID]].name)
							else
								for eID, _ in pairs(teamEntities[tID].memberPEIDs) do
									Spring.Echo(playerEntities[eID].name)
								end
							end
	
						end
					end
					-- for id, data in pairs(spectatorEntities) do
						-- local name,active,spectator,teamID,allyTeamID,pingTime,cpuUsage,country,rank,customKeys = Spring.GetPlayerInfo(data.playerID)
						-- local act
						-- if active then act = "true" else act = "false" end
						-- Spring.Echo("Playerlist Window Debug: "..name.." (Spectator) active:"..act.." teamID:"..teamID.." allyTeamID:"..allyTeamID)
					-- end
				end
			};
			parent = plw_contentHolder;
		}
	end
end

function widget:Shutdown()
	--widgetHandler:DeregisterGlobal("PlayerListWindow")
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

options_path = 'Settings/HUD Panels/Player List Window'
options = {
	plw_visible = {
		name = "Visible",
		type = 'bool',
		value = false, --set to false when initialisation is complete
		desc = "Set a hotkey here to toggle the playerlist on and off",
		OnChange = function() PLW_UpdateVisibility() end,
	},
	plw_backgroundOpacity = {
		name = "Opacity",
		type = "number",
		value = 0.8, min = 0, max = 1, step = 0.01,
	},
	plw_showCcr = {
		name = "Show clan/country/rank in playerlist window",
		type = 'bool',
		value = true,
		desc = "Show the clan, country, and rank columns",
		OnChange = function() PLW_ConfigureStaticControls() end,
	},
	plw_show_resourceStatus = {
		name = "Show unit and income stats in playerlist window",
		type = 'bool',
		value = true,
		desc = "Display resource statistics: metal in mobile units and static defenses; metal and energy income; current stored resrouces.",
		OnChange = function() PLW_ConfigureStaticControls() end,
	},
	plw_show_cpuPing = {
		name = "Show ping and cpu",
		type = 'bool',
		value = true,
		desc = "Show player's ping and cpu",
		OnChange = function() PLW_ConfigureStaticControls() end,
	},
	plw_textHeight = {
		name = 'Font Size (10-18)',
		type = 'number',
		value = 13,
		min=10,max=18,step=1,
		OnChange = function() PLW_ConfigureStaticControls() end,
		advanced = true
	},
	-- plw_nameWidth = {
		-- name = 'Name Width (20-40)',
		-- type = 'number',
		-- value = 20,
		-- min=20,max=40,step=1,
		-- OnChange = function() PLW_ConfigureStaticControls() end,
		-- advanced = true
	-- },
	-- plw_statsWidth = {
		-- name = 'Metal worth stats width (2-5)',
		-- type = 'number',
		-- value = 4,
		-- min=2,max=5,step=1,
		-- OnChange = function() PLW_ConfigureStaticControls() end,
		-- advanced = true
	-- },
	-- plw_incomeWidth = {
		-- name = 'Income width (2-5)',
		-- type = 'number',
		-- value = 3,
		-- min=2,max=5,step=1,
		-- OnChange = function() PLW_ConfigureStaticControls() end,
		-- advanced = true
	-- },
	plw_cpuPingAsText = {
		name = "Show ping/cpu as text",
		type = 'bool',
		value = false,
		desc = "Show ping and cpu stats as text (vs. as an icon)",
		OnChange = function() PLW_ConfigureStaticControls() end,
		advanced = true
	},
	plw_maxWindowHeight = {
		name = "Maximum playerlist window height",
		type = 'number',
		value = 600,
		min=300,max=750,step=25,
		OnChange = function() PLW_ConfigureStaticControls() end,
		advanced = true
	},
	plw_fancySkinning = {
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
			
			plw_vcon_scrollPanel.main.tiles = newClass.tiles
			plw_vcon_scrollPanel.main.TileImageFG = newClass.TileImageFG
			--plw_vcon_scrollPanel.main.backgroundColor = newClass.backgroundColor
			plw_vcon_scrollPanel.main.TileImageBK = newClass.TileImageBK
			plw_vcon_scrollPanel.main:Invalidate()
		end,
		advanced = true,
		noHotkey = true,
	},
}
