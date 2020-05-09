-- Recycled bars are shown before they're sorted. sometimes causes a hiccup.

-- Config
local NumBarsToShow = 5 -- Set how many bars should be shown on the main window. All bars can be scrolled through with the mousewheel.
local ReportChannel = "SAY" -- Set which channel reports will be sent to. SAY, PARTY, RAID, INSTANCE_CHAT, GUILD
local ReportLines = 5

-- Locals
local Timestamp, EventType, SourceGUID, SourceName, SourceFlags, DestGUID, DestName, DestFlags
local Amount, Overkill, School, Absorbed, Critical, SpellID, SpellName, SpellSchool, Absorbed
local _

local max = math.max
local select = select
local tremove = tremove
local tinsert = tinsert
local format = format
local GetSpellInfo = GetSpellInfo
local UnitName = UnitName
local UnitGUID = UnitGUID
local GetNumGroupMembers = GetNumGroupMembers
local IsInRaid = IsInRaid
local IsInGroup = IsInGroup
local UnitExists = UnitExists
local RAID_CLASS_COLORS = RAID_CLASS_COLORS
local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo
local date = date
local type = type
local tonumber = tonumber
local floor = floor
local match = string.match
local reverse = string.reverse
local gsub = gsub
local sort = table.sort
local strsplit = strsplit
local MyGUID = UnitGUID("player")
local MeleeName = ACTION_SWING
local Pets = {}
local BarFactory = {FreePlayers = {}, ActivePlayers = {}, FreeSpells = {}}
local CombatTime = 0
local LastCombatTime = 0
local TotalDamage = 0
local LastTotalDamage = 0
local Throttle = 0
local DPS = 0
local DPSValue = 0
local NeedsReset = false
local BossName = nil
local LastBossName = nil
local WindowWidth = 195
local BarHeight = 22
local Window = CreateFrame("Frame", "PersonalMeterFrameDPS", UIParent)
local Group = {}
local ScrollTable = BarFactory.ActivePlayers
local CurrentBar

local PetTimer = CreateFrame("Frame")
PetTimer.int = 0

local ShortValue = function(number)
	if (number <= 999) then
		return floor(number)
	elseif (number >= 1000000) then
		return format("%.2fM", number / 1000000)
	elseif (number >= 10000) then
		return format("%.1fK", number / 1000)
	else
		return 0
	end
end

local SecondsToTime = function(seconds)
	return format("%s:%s", date("%M", seconds), date("%S", seconds))
end

local SchoolColors = {
	-- Basic schools
	[STRING_SCHOOL_UNKNOWN] = {1, 1, 1},
	[STRING_SCHOOL_PHYSICAL] = {1, 1, 0},
	[STRING_SCHOOL_HOLY] = {1, 0.9, 0.5},
	[STRING_SCHOOL_FIRE] = {1, 0.5, 0},
	[STRING_SCHOOL_NATURE] = {0.3, 1, 0.3},
	[STRING_SCHOOL_FROST] = {0.5, 1, 1},
	[STRING_SCHOOL_SHADOW] = {0.5, 0.5, 1},
	[STRING_SCHOOL_ARCANE] = {1, 0.5, 1},
	
	-- Double schools (Using color midpoints of basic schools)
	[STRING_SCHOOL_HOLYSTRIKE] = {1, 0.95, 0.25}, -- Holy + Physical
	[STRING_SCHOOL_FLAMESTRIKE] = {1, 0.72, 0}, -- Fire + Physical
	[STRING_SCHOOL_HOLYFIRE] = {1, 0.70, 0.25}, -- Fire + Holy
	[STRING_SCHOOL_STORMSTRIKE] = {0.65, 1, 0.15}, -- Nature + Physical
	[STRING_SCHOOL_HOLYSTORM] = {0.65, 0.95, 0.40}, -- Nature + Holy
	[STRING_SCHOOL_FIRESTORM] = {0.65, 0.75, 0.15}, -- Nature + Fire
	[STRING_SCHOOL_FROSTSTRIKE] = {0.75, 1, 0.50}, -- Frost + Physical
	[STRING_SCHOOL_HOLYFROST] = {0.75, 0.95, 0.75}, -- Frost + Holy
	[STRING_SCHOOL_FROSTFIRE] = {0.75, 0.75, 0.50}, -- Frost + Fire
	[STRING_SCHOOL_FROSTSTORM] = {0.40, 1, 0.65}, -- Frost + Nature
	[STRING_SCHOOL_SHADOWSTRIKE] = {0.75, 0.75, 0.50}, -- Shadow + Physical
	[STRING_SCHOOL_SHADOWLIGHT] = {0.75, 0.70, 0.75}, -- Shadow + Holy
	[STRING_SCHOOL_SHADOWFLAME] = {0.75, 0.50, 0.50}, -- Shadow + Fire
	[STRING_SCHOOL_SHADOWSTORM] = {0.40, 0.75, 0.65}, -- Shadow + Nature
	[STRING_SCHOOL_SHADOWFROST] = {0.5, 0.75, 1}, -- Shadow + Frost
	[STRING_SCHOOL_SPELLSTRIKE] = {1, 0.75, 0.50}, -- Arcane + Physical
	[STRING_SCHOOL_DIVINE] = {1, 0.70, 0.75}, -- Arcane + Holy
	[STRING_SCHOOL_SPELLFIRE] = {1, 0.50, 0.50}, -- Arcane + Fire
	[STRING_SCHOOL_SPELLSTORM] = {0.65, 0.75, 0.65}, -- Arcane + Nature
	[STRING_SCHOOL_SPELLFROST] = {0.75, 0.75, 1}, -- Arcane + Frost
	[STRING_SCHOOL_SPELLSHADOW] = {0.75, 0.50, 1}, -- Arcane + Shadow
	
	-- Multi schools (Not even sure if they're used?) Currently using color averages of basic schools, but these colors are quite ugly and muddy. May make unique colors if necessary.
	[STRING_SCHOOL_ELEMENTAL] = {0.6, 0.83, 0.43}, -- Frost + Nature + Fire
	[STRING_SCHOOL_CHROMATIC] = {0.66, 0.7, 0.66}, -- Arcane + Shadow + Frost + Nature + Fire
	[STRING_SCHOOL_MAGIC] = {0.71, 0.73, 0.63}, -- Arcane + Shadow + Frost + Nature + Fire + Holy
	[STRING_SCHOOL_CHAOS] = {0.75, 0.77, 0.54}, -- Arcane + Shadow + Frost + Nature + Fire + Holy + Physical
}

local SchoolID = {
	-- Basic schools
	[0] = STRING_SCHOOL_UNKNOWN,
	[1] = STRING_SCHOOL_PHYSICAL,
	[2] = STRING_SCHOOL_HOLY,
	[4] = STRING_SCHOOL_FIRE,
	[8] = STRING_SCHOOL_NATURE,
	[16] = STRING_SCHOOL_FROST,
	[32] = STRING_SCHOOL_SHADOW,
	[64] = STRING_SCHOOL_ARCANE,
	
	-- Double schools
	[3] = STRING_SCHOOL_HOLYSTRIKE,
	[5] = STRING_SCHOOL_FLAMESTRIKE,
	[6] = STRING_SCHOOL_HOLYFIRE,
	[9] = STRING_SCHOOL_STORMSTRIKE,
	[10] = STRING_SCHOOL_HOLYSTORM,
	[12] = STRING_SCHOOL_FIRESTORM,
	[17] = STRING_SCHOOL_FROSTSTRIKE,
	[18] = STRING_SCHOOL_HOLYFROST,
	[20] = STRING_SCHOOL_FROSTFIRE,
	[24] = STRING_SCHOOL_FROSTSTORM,
	[33] = STRING_SCHOOL_SHADOWSTRIKE,
	[34] = STRING_SCHOOL_SHADOWLIGHT, -- Shadowlight. Global string says "Twilight" though.
	[36] = STRING_SCHOOL_SHADOWFLAME,
	[40] = STRING_SCHOOL_SHADOWSTORM, -- Shadowstorm. Global string says "Plague" though.
	[48] = STRING_SCHOOL_SHADOWFROST,
	[65] = STRING_SCHOOL_SPELLSTRIKE,
	[66] = STRING_SCHOOL_DIVINE,
	[68] = STRING_SCHOOL_SPELLFIRE,
	[72] = STRING_SCHOOL_SPELLSTORM,
	[80] = STRING_SCHOOL_SPELLFROST,
	[96] = STRING_SCHOOL_SPELLSHADOW,
	
	-- Multi schools
	[28] = STRING_SCHOOL_ELEMENTAL,
	[124] = STRING_SCHOOL_CHROMATIC,
	[126] = STRING_SCHOOL_MAGIC,
	[127] = STRING_SCHOOL_CHAOS,
}

local GetSchoolColor = function(school)
	if SchoolID[school] then
		return SchoolColors[SchoolID[school]][1], SchoolColors[SchoolID[school]][2], SchoolColors[SchoolID[school]][3]
	else
		return SchoolColors[STRING_SCHOOL_UNKNOWN][1], SchoolColors[STRING_SCHOOL_UNKNOWN][2], SchoolColors[STRING_SCHOOL_UNKNOWN][3]  -- Shouldn't ever happen, but just in case
	end
end

local GetRandomSchool = function()
	local Index = random(1, 29)
	local i = 0
	
	for school in pairs(SchoolID) do
		i = i + 1
		
		if (i == Index) then
			return school
		end
	end
end

local GetRandomClass = function()
	local Index = random(1, 11)
	local i = 0
	
	for class in pairs(RAID_CLASS_COLORS) do
		i = i + 1
		
		if (i == Index) then
			return class
		end
	end
end

local IgnoreEvents = {
	["ENCHANT_APPLIED"] = true,
	["ENCHANT_REMOVED "] = true,
	["PARTY_KILL"] = true,
	["SPELL_AURA_APPLIED"] = true,
	["SPELL_AURA_REMOVED"] = true,
	["SPELL_AURA_REFRESH"] = true,
	["SPELL_AURA_APPLIED_DOSE"] = true,
	["SPELL_AURA_REMOVED_DOSE"] = true,
	["SPELL_BUILDING_DAMAGE"] = true,
	["SPELL_ENERGGIZE"] = true,
	["SPELL_CAST_START"] = true,
	["SPELL_CAST_SUCCESS"] = true,
	["SPELL_CAST_FAILED"] = true,
	["SPELL_CREATE"] = true,
	["SPELL_DISPEL_FAILED"] = true,
	["SPELL_ENERGIZE"] = true,
	["SPELL_LEECH"] = true,
	["SPELL_DRAIN"] = true,
	["SPELL_MISSED"] = true,
	["SPELL_DURABILITY_DAMAGE"] = true,
	["SPELL_DURABILITY_DAMAGE_ALL"] = true,
	["SPELL_PERIODIC_DRAIN"] = true,
	["SPELL_PERIODIC_LEECH"] = true,
	["SWING_MISSED"] = true,
	["SPELL_DISPEL"] = true,
	["SPELL_INTERRUPT"] = true,
	["SPELL_RESURRECT"] = true,
	["UNIT_DIED"] = true,
	["SPELL_ABSORBED"] = true,
}

local Comma = function(number)
	if (not number) then
		return
	end
	
   	local Left, Number = match(floor(number + 0.5), "^([^%d]*%d)(%d+)(.-)$")
	
	return Left and Left .. reverse(gsub(reverse(Number), "(%d%d%d)", "%1,")) or number
end

local Backdrop = {
	bgFile = "Interface\\Buttons\\WHITE8X8",
	insets = {top = 0, left = 0, bottom = 0, right = 0},
}

local BackdropAndBorder = {
	bgFile = "Interface\\Buttons\\WHITE8X8",
	edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1,
	insets = {top = 0, left = 0, bottom = 0, right = 0},
}

-- Data
local WindowOnEnter = function(self)
	GameTooltip:ClearLines()
	GameTooltip_SetDefaultAnchor(GameTooltip, self)
	
	GameTooltip:AddLine(SecondsToTime(CombatTime > 0 and CombatTime or LastCombatTime))
	
	GameTooltip:Show()
end

local WindowOnLeave = function(self)
	GameTooltip:Hide()
end

local WindowOnMouseUp = function(self)
	if IsShiftKeyDown() then
		if Window.ShowPlayers then -- We're showing players right now, list player damage
			if (BossName or LastBossName) then
				--print("Damage for " .. (BossName and BossName or LastBossName))
				local DPS = strsub(Window.Text:GetText(), 6, strlen(Window.Text:GetText()))
				SendChatMessage(format("Damage for %s: %s (%s)", (BossName and BossName or LastBossName), Window.Value:GetText(), DPS), ReportChannel)
			else
				--print("Damage for last fight:")
				local DPS = strsub(Window.Text:GetText(), 6, strlen(Window.Text:GetText()))
				SendChatMessage(format("Damage for last fight: %s (%s)", Window.Value:GetText(), DPS), ReportChannel)
			end
			
			for i = 1, ReportLines do
				if BarFactory.ActivePlayers[i] then
					local Name = BarFactory.ActivePlayers[i].Name:GetText()
					local Damage = BarFactory.ActivePlayers[i].Value:GetText()
					
					if IsInRaid() then
						ReportChannel = "RAID"
					elseif IsInGroup() then
						ReportChannel = "PARTY"
					else
						ReportChannel = "SAY"
					end
					
					--print(format("%d. %s: %s", i, Name, Damage))
					SendChatMessage(format("%d. %s: %s", i, Name, Damage), ReportChannel)
				end
			end
		else -- We're looking at a players spells, list them
			local Player = CurrentBar.Name:GetText()
			
			if (BossName or LastBossName) then
				--print(Player .. "'s damage for " .. (BossName and BossName or LastBossName))
				SendChatMessage(Player .. "'s damage for " .. (BossName and BossName or LastBossName) .. ":", ReportChannel)
			else
				--print(Player .. "'s damage for last fight:")
				SendChatMessage(Player .. "'s damage for last fight:", ReportChannel)
			end
			
			for i = 1, ReportLines do
				if CurrentBar.Spells[i] then -- Double check
					if IsInRaid() then
						ReportChannel = "RAID"
					elseif IsInGroup() then
						ReportChannel = "PARTY"
					else
						ReportChannel = "SAY"
					end
					
					--print(format("%d. %s: %s", i, format("\124cff71d5ff\124Hspell:%d\124h[%s]\124h\124r", CurrentBar.Spells[i].SpellID, CurrentBar.Spells[i].SpellName), CurrentBar.Spells[i].Value:GetText()))
					SendChatMessage(format("%d. %s: %s", i, format("\124cff71d5ff\124Hspell:%d\124h[%s]\124h\124r", CurrentBar.Spells[i].SpellID, CurrentBar.Spells[i].SpellName), CurrentBar.Spells[i].Value:GetText()), ReportChannel)
				end
			end
		end
	end
end

local OnMouseWheel = function(self, delta)
	local First = false
	
	if (delta == 1) then -- up
		self.BarOffset = self.BarOffset - 1
		
		if (self.BarOffset <= 1) then
			self.BarOffset = 1
		end
	else -- down
		self.BarOffset = self.BarOffset + 1
		
		if (self.BarOffset > (#ScrollTable - (NumBarsToShow - 1))) then
			self.BarOffset = self.BarOffset - 1
		end
	end
	
	for i = 1, #ScrollTable do
		if (i >= self.BarOffset) and (i <= self.BarOffset + (NumBarsToShow - 1)) then
			if (not First) then
				ScrollTable[i]:SetPoint("TOPLEFT", Window, "BOTTOMLEFT", 0, 1)
				First = true
			else
				ScrollTable[i]:SetPoint("TOPLEFT", ScrollTable[i-1], "BOTTOMLEFT", 0, 1)
			end
			
			ScrollTable[i]:Show()
		else
			ScrollTable[i]:Hide()
		end
	end
end

local StartTestMode = function()
	if NeedsReset then
		BarFactory:Reset()
	end
	
	local Total = 0
	local FakeCombatTime  = random(60, 120)
	
	for i = 1, 10 do
		local Value = random(750000, 5000000)
		local Class = GetRandomClass()
		local Color = RAID_CLASS_COLORS[Class]
		
		local Bar = BarFactory:GetPlayer()
		Bar.Name:SetText("Dummy " .. i)
		Bar.Value:SetText(format("%s (%s)", ShortValue(Value), ShortValue(Value / max(1, FakeCombatTime))))
		Bar.Class = Class
		Bar.Bar:SetStatusBarColor(Color.r, Color.g, Color.b)
		Bar.Total = Value
		Bar:Show()
		tinsert(BarFactory.ActivePlayers, Bar)
		
		Total = Total + Value
	end
	
	Window.Value:SetText(ShortValue(Total))
	Window.Text:SetText(format("DPS: %s", ShortValue(Total / FakeCombatTime)))
	BarFactory:SortPlayers()
end

local StopTestMode = function()
	for i = #BarFactory.ActivePlayers, 1, -1 do
		BarFactory:RecyclePlayer(BarFactory.ActivePlayers[i])
	end
	
	Window.BarParent.BarOffset = 1
	NeedsReset = false
	Window.Value:SetText("0.0")
	Window.Text:SetText("DPS: 0")
end

function Window:Create()
	if Window.Created then
		return
	end
	
	Window:SetSize(WindowWidth, 22)
	Window:SetPoint("LEFT", UIParent, 400, 120)
	Window:SetBackdrop(Backdrop)
	Window:SetBackdropColor(0, 0, 0)
	Window:EnableMouse(true)
	Window:SetMovable(true)
	Window:SetUserPlaced(true)
	Window:RegisterForDrag("LeftButton")
	Window:SetScript("OnDragStart", Window.StartMoving)
	Window:SetScript("OnDragStop", Window.StopMovingOrSizing)
	Window:SetScript("OnMouseUp", WindowOnMouseUp)
	Window:SetScript("OnEnter", WindowOnEnter)
	Window:SetScript("OnLeave", WindowOnLeave)
	
	Window.Bar = CreateFrame("StatusBar", nil, Window)
	Window.Bar:SetSize(WindowWidth - 2, 20)
	Window.Bar:SetPoint("CENTER", Window, 0, 0)
	Window.Bar:SetMinMaxValues(0, 1)
	Window.Bar:SetValue(1)
	Window.Bar:SetStatusBarTexture("Interface\\AddOns\\PersonalMetersGroup\\Assets\\vUI4.tga")
	Window.Bar:SetStatusBarColor(0.17, 0.17, 0.17)
	
	Window.BarParent = CreateFrame("Frame", nil, Window)
	Window.BarParent:SetSize(WindowWidth, 106) -- (NumBarsToShow * 22 - (NumBarsToShow - 1))
	Window.BarParent:SetPoint("TOP", Window, "BOTTOM", 0, 1)
	Window.BarParent:SetBackdrop(BackdropAndBorder)
	Window.BarParent:SetBackdropColor(0.17, 0.17, 0.17, 0.8)
	Window.BarParent:SetBackdropBorderColor(0, 0, 0)
	Window.BarParent.BarOffset = 1
	Window.BarParent:SetScript("OnMouseWheel", OnMouseWheel)
	
	Window.Text = Window.Bar:CreateFontString(nil, "OVERLAY")
	Window.Text:SetPoint("LEFT", Window.Bar, 4, 0)
	Window.Text:SetFont("Interface\\AddOns\\PersonalMetersGroup\\Assets\\PTSans.ttf", 12)
	Window.Text:SetJustifyH("LEFT")
	Window.Text:SetShadowColor(0, 0, 0)
	Window.Text:SetShadowOffset(1, -1)
	Window.Text:SetText("DPS: 0")
	
	Window.Value = Window.Bar:CreateFontString(nil, "OVERLAY")
	Window.Value:SetPoint("RIGHT", Window.Bar, -4, 0)
	Window.Value:SetFont("Interface\\AddOns\\PersonalMetersGroup\\Assets\\PTSans.ttf", 12)
	Window.Value:SetJustifyH("RIGHT")
	Window.Value:SetShadowColor(0, 0, 0)
	Window.Value:SetShadowOffset(1, -1)
	Window.Value:SetText("")
	
	-- Events
	Window:RegisterEvent("PLAYER_REGEN_ENABLED")
	Window:RegisterEvent("PLAYER_REGEN_DISABLED")
	Window:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	Window:RegisterEvent("ENCOUNTER_START")
	Window:RegisterEvent("GROUP_ROSTER_UPDATE")
	
	-- Window hooks
	function Window:UpdateBarsToShow(num)
		NumBarsToShow = num
		
		self.BarParent:SetHeight((NumBarsToShow * BarHeight - (NumBarsToShow - 1)))
		self.BarParent.BarOffset = 1
		BarFactory:SortPlayers()
	end
	
	function Window:UpdateBarColors(value)
		if value then -- Use Class Coloring
			for i = 1, #BarFactory.ActivePlayers do
				local Color = RAID_CLASS_COLORS[BarFactory.ActivePlayers[i].Class]
				
				BarFactory.ActivePlayers[i].Bar:SetStatusBarColor(Color.r, Color.g, Color.b)
			end
		else
			for i = 1, #BarFactory.ActivePlayers do
				BarFactory.ActivePlayers[i].Bar:SetStatusBarColor(0.17, 0.17, 0.17)
			end
		end
	end
	
	function Window:UpdateWidth(width)
		WindowWidth = width
		
		self:SetWidth(width)
		self.BarParent:SetWidth(width)
		self.Bar:SetWidth(width - 2)
		
		for i = 1, #BarFactory.ActivePlayers do
			BarFactory.ActivePlayers[i].Bar:SetSize((width - BarHeight) - 1, BarHeight - 2)
		end
	end
	
	function Window:UpdateBarHeight(height)
		BarHeight = height
		
		self.BarParent:SetHeight((NumBarsToShow * BarHeight - (NumBarsToShow - 1)))
		
		for i = 1, #BarFactory.ActivePlayers do
			BarFactory.ActivePlayers[i]:SetSize(height, height)
			BarFactory.ActivePlayers[i].Bar:SetSize((WindowWidth - height) - 1, height - 2)
		end
	end
	
	function Window:StartTestMode()
		StartTestMode()
	end
	
	function Window:StopTestMode()
		StopTestMode()
	end
	
	function Window:Enable()
		self:RegisterEvent("PLAYER_REGEN_ENABLED")
		self:RegisterEvent("PLAYER_REGEN_DISABLED")
		self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
		self:RegisterEvent("ENCOUNTER_START")
		self:RegisterEvent("GROUP_ROSTER_UPDATE")
		self:Show()
	end
	
	function Window:Disable()
		self:UnregisterAllEvents()
		self:Hide()
	end
	
	Window.Created = true
	Window.ShowPlayers = true
end

local OnUpdate = function(self, ela)
	CombatTime = CombatTime + ela
	Throttle = Throttle + ela
	
	if (Throttle > 0.2) then
		if Window.ShowPlayers then
			BarFactory:SortPlayers()
		else
			BarFactory:SortSpells(CurrentBar)
		end
		
		Throttle = 0
	end
end

local AddPet = function(petguid, petname, sourceguid)
	Pets[petguid] = {Owner = sourceguid, Name = petname}
end

local IsPet = function(petguid)
	if Pets[petguid] then
		return Pets[petguid].Owner
	end
end

local GetBarByName = function(player)
	for i = 1, #BarFactory.ActivePlayers do
		if (BarFactory.ActivePlayers[i].PlayerName == player) then
			return BarFactory.ActivePlayers[i]
		end
	end
end

local GetBarByGUID = function(guid)
	for i = 1, #BarFactory.ActivePlayers do
		if (BarFactory.ActivePlayers[i].GUID == guid) then
			return BarFactory.ActivePlayers[i]
		end
	end
end

local GetSpellByName = function(bar, name)
	for i = 1, #bar.Spells do
		if (bar.Spells[i].SpellName == name) then
			return bar.Spells[i]
		end
	end
end

local GetSpellByID = function(bar, id)
	for i = 1, #bar.Spells do
		if (bar.Spells[i].SpellID == id) then
			return bar.Spells[i]
		end
	end
end

local AddData = function(player, guid, id, name, school, total, effective, crit, pet)
	if (effective <= 0) then -- This isn't useful data
		return
	end
	
	if NeedsReset then
		BarFactory:Reset()
	end
	
	if (pet) then
		name = Pets[guid].Name .. ": " .. name
	end
	
	local Bar = GetBarByGUID(pet and pet or guid) -- GetBarByID(id)
	
	if (not Bar) then
		Bar = BarFactory:GetPlayer()
		
		Bar.PlayerName = strsplit("-", player)
		Bar.GUID = guid
		Bar.Class = select(2, UnitClass(player))
		Bar.NeedsSort = true
		
		--Bar.Icon:SetTexture(select(3, GetSpellInfo(id)))
		
		Bar.Name:SetText(Bar.PlayerName)
		
		if Bar.Class then
			local Color = RAID_CLASS_COLORS[Bar.Class]
			
			Bar.Bar:SetStatusBarColor(Color.r, Color.g, Color.b)
		end
		
		tinsert(BarFactory.ActivePlayers, Bar)
	end
	
	Bar.Total = Bar.Total + total
	
	local Spell = GetSpellByName(Bar, name)
	
	if (not Spell) then
		Spell = BarFactory:GetSpell()
		
		Spell.SpellID = id
		Spell.SpellName = name
		Spell.SpellSchool = school
		Spell.Icon:SetTexture(select(3, GetSpellInfo(id)))
		Spell.Bar:SetStatusBarColor(GetSchoolColor(school))
		Spell.Name:SetText(name)
		Spell.Parent = Bar
		tinsert(Bar.Spells, Spell)
	end
	
	Spell.Total = Spell.Total + total
	Spell.Effective = Spell.Effective + effective
	Spell.Waste = Spell.Waste + (total - effective)
	
	if crit then
		Spell.Criticals = Spell.Criticals + crit
	end
	
	Spell.Count = Spell.Count + 1
	
	Spell.Value:SetText(ShortValue(Spell.Total))
	
	if (total < Spell.Min) then
		Spell.Min = total
	end
	
	if (total > Spell.Max) then
		Spell.Max = total
	end
	
	--Bar.Value:SetText(ShortValue(Bar.Total))
	Bar.Value:SetText(format("%s (%s)", ShortValue(Bar.Total), ShortValue(Bar.Total / max(1, CombatTime))))
	
	TotalDamage = TotalDamage + total
	
	-- Header update
	DPSValue = (TotalDamage / CombatTime)
	
	if (1 > CombatTime) then
		DPSValue = TotalDamage
	end
	
	Window.Text:SetText(format("DPS: %s", ShortValue(DPSValue)))
	Window.Value:SetText(ShortValue(TotalDamage))
	
	if Bar.NeedsSort then
		BarFactory:SortPlayers()
		Bar.NeedsSort = false
	end
end

-- Events
Window.Modules = {}
Window:RegisterEvent("PLAYER_ENTERING_WORLD")
Window:RegisterEvent("UNIT_PET")

local UpdateGroupMembers = function()
	local NumGroupMembers = GetNumGroupMembers()
	
	if IsInRaid() then
		for i = 1, NumGroupMembers do
			if UnitExists("raid"..i) then
				Group[UnitGUID("raid"..i)] = true
			end
		end
	elseif IsInGroup() then
		for i = 1, NumGroupMembers do
			if UnitExists("party"..i) then
				Group[UnitGUID("party"..i)] = true
			end
		end
	end
	
	Group[UnitGUID("player")] = true
end

local UpdateGroupPets = function()
	local NumGroupMembers = GetNumGroupMembers()
	
	if IsInRaid() then
		for i = 1, NumGroupMembers do
			if UnitExists("raid"..i.."pet") then
				AddPet(UnitGUID("raid"..i.."pet"), UnitName("raid"..i.."pet"), UnitGUID("raid"..i))
			end
		end
	elseif IsInGroup() then
		for i = 1, NumGroupMembers do
			if UnitExists("party"..i.."pet") then
				AddPet(UnitGUID("party"..i.."pet"), UnitName("party"..i.."pet"), UnitGUID("party"..i))
			end
		end
	end
	
	if UnitExists("pet") then
		AddPet(UnitGUID("pet"), UnitName("pet"), UnitGUID("player"))
	end
end

local PetTimerOnUpdate = function(self, elapsed)
	self.int = self.int + elapsed
	
	if (self.int >= 10) then
		UpdateGroupPets()
		
		self.int = 0
	end
end

function Window:GROUP_ROSTER_UPDATE()
	UpdateGroupMembers()
	UpdateGroupPets()
end

-- Boss start
function Window:ENCOUNTER_START(id, name)
	BossName = name
end

-- Entering combat
function Window:PLAYER_REGEN_DISABLED()
	PetTimer:SetScript("OnUpdate", nil)
	self:SetScript("OnUpdate", OnUpdate)
end

-- Leaving combat
function Window:PLAYER_REGEN_ENABLED()
	self:SetScript("OnUpdate", nil)
	PetTimer:SetScript("OnUpdate", PetTimerOnUpdate)
	
	-- Header update
	--Window.Text:SetText(format("DPS: %s", ShortValue(TotalDamage / CombatTime)))
	--Window.Value:SetText(ShortValue(TotalDamage))
	
	LastCombatTime = CombatTime
	LastTotalDamage = TotalDamage
	CombatTime = 0
	TotalDamage = 0
	NeedsReset = true
end

-- PEW
function Window:PLAYER_ENTERING_WORLD()
	self:Create()
	
	PetTimer:SetScript("OnUpdate", 	PetTimerOnUpdate)
	
	UpdateGroupMembers()
	UpdateGroupPets()
end

-- Pet summon
function Window:UNIT_PET(owner)
	UpdateGroupPets()
end

function Window:COMBAT_LOG_EVENT_UNFILTERED()
	EventType, _, SourceGUID = select(2, CombatLogGetCurrentEventInfo())
	
	if IgnoreEvents[EventType] then
		return
	end
	
	if (Group[SourceGUID] or Pets[SourceGUID]) then
		if self.Modules[EventType] then
			self.Modules[EventType](CombatLogGetCurrentEventInfo())
		end
	end
end

Window:SetScript("OnEvent", function(self, event, ...)
	self[event](self, ...)
end)

function Window:RegisterModule(event, func)
	if self.Modules[event] then -- A module for this event exists?
		return
	end
	
	IgnoreEvents[event] = false -- Don't ignore this event anymore
	self.Modules[event] = func
end

function Window:UnregisterModule(event)
	if self.Modules[event] then
		IgnoreEvents[event] = true
		self.Modules[event] = nil
	end
end

-- Bars
local ShowIconTooltip = function(self)
	GameTooltip:ClearLines()
	GameTooltip_SetDefaultAnchor(GameTooltip, self)
	
	local R, G, B = GetSchoolColor(self.SpellSchool)
	
	GameTooltip:AddLine(self.SpellName)
	GameTooltip:AddLine(" ")
	GameTooltip:AddDoubleLine("Count:", self.Count, 1, 1, 1)
	GameTooltip:AddDoubleLine("Total:", ShortValue(self.Total), 1, 1, 1)
	GameTooltip:AddDoubleLine("Effective Total:", ShortValue(self.Effective), 1, 1, 1)
	
	if (self.Waste > 0) then
		GameTooltip:AddDoubleLine("Waste:", format("%s (%.1f%%)", ShortValue(self.Waste), (self.Waste / self.Total) * 100), 1, 1, 1)
	end
	
	GameTooltip:AddLine(" ")
	GameTooltip:AddDoubleLine("% of Total Damage:", format("%.1f%%", (self.Effective / (TotalDamage > 0 and TotalDamage or LastTotalDamage)) * 100), 1, 1, 1)
	--GameTooltip:AddDoubleLine("Spell DPS:", (ShortValue(self.DPS)), 1, 1, 1)
	--GameTooltip:AddDoubleLine("Effective Spell DPS:", (ShortValue(self.EDPS)), 1, 1, 1)
	GameTooltip:AddLine(" ")
	GameTooltip:AddDoubleLine("Critical hits:", format("%s (%.1f%%)", self.Criticals, (self.Criticals / self.Count) * 100), 1, 1, 1)
	GameTooltip:AddDoubleLine("Min hit:", ShortValue(self.Min), 1, 1, 1)
	GameTooltip:AddDoubleLine("Max hit:", ShortValue(self.Max), 1, 1, 1)
	GameTooltip:AddDoubleLine("Average hit:", ShortValue(self.Total / self.Count), 1, 1, 1)
	GameTooltip:AddLine(" ")
	GameTooltip:AddDoubleLine("Spell School:", SchoolID[self.SpellSchool], 1, 1, 1, R, G, B)
	
	GameTooltip:Show()
end

local HideIconTooltip = function()
	GameTooltip:Hide()
end

local ShowBarTooltip = function(self)
	GameTooltip:ClearLines()
	GameTooltip_SetDefaultAnchor(GameTooltip, self)
	
	local R, G, B = GetSchoolColor(self.Parent.SpellSchool)
	
	GameTooltip:AddLine(self.Parent.SpellName)
	GameTooltip:AddLine(" ")
	GameTooltip:AddDoubleLine("Count:", self.Parent.Count, 1, 1, 1)
	GameTooltip:AddDoubleLine("Total:", ShortValue(self.Parent.Total), 1, 1, 1)
	GameTooltip:AddDoubleLine("Effective Total:", ShortValue(self.Parent.Effective), 1, 1, 1)
	
	if (self.Parent.Waste > 0) then
		GameTooltip:AddDoubleLine("Waste:", format("%s (%.1f%%)", ShortValue(self.Parent.Waste), (self.Parent.Waste / self.Parent.Total) * 100), 1, 1, 1)
	end
	
	GameTooltip:AddLine(" ")
	GameTooltip:AddDoubleLine("% of Total Damage:", format("%.1f%%", (self.Parent.Effective / (TotalDamage > 0 and TotalDamage or LastTotalDamage)) * 100), 1, 1, 1)
	--GameTooltip:AddDoubleLine("Spell DPS:", (ShortValue(self.Parent.DPS)), 1, 1, 1)
	--GameTooltip:AddDoubleLine("Effective Spell DPS:", (ShortValue(self.Parent.EDPS)), 1, 1, 1)
	GameTooltip:AddLine(" ")
	GameTooltip:AddDoubleLine("Critical hits:", format("%s (%.1f%%)", self.Parent.Criticals, (self.Parent.Criticals / self.Parent.Count) * 100), 1, 1, 1)
	GameTooltip:AddDoubleLine("Min hit:", ShortValue(self.Parent.Min), 1, 1, 1)
	GameTooltip:AddDoubleLine("Max hit:", ShortValue(self.Parent.Max), 1, 1, 1)
	GameTooltip:AddDoubleLine("Average hit:", ShortValue(self.Parent.Total / self.Parent.Count), 1, 1, 1)
	GameTooltip:AddLine(" ")
	GameTooltip:AddDoubleLine("Spell School:", SchoolID[self.Parent.SpellSchool], 1, 1, 1, R, G, B)
	
	GameTooltip:Show()
end

local HideBarTooltip = function()
	GameTooltip:Hide()
end

-- New hooks
local PlayerBarOnMouseUp = function(self, button)
	if (button == "LeftButton") then
		if Window.ShowPlayers then
			for i = 1, #BarFactory.ActivePlayers do
				BarFactory.ActivePlayers[i]:Hide()
			end
			
			for i = 1, #self.Spells do
				self.Spells[i]:Show()
			end
			
			Window.BarParent.BarOffset = 1
			BarFactory:SortSpells(self)
			ScrollTable = self.Spells
			CurrentBar = self
			Window.ShowPlayers = false
		end
	end
end

local SpellBarOnMouseUp = function(self, button)
	if (button == "RightButton") then
		if (not Window.ShowPlayers) then
			for i = 1, #self.Parent.Parent.Spells do
				self.Parent.Parent.Spells[i]:Hide()
			end
			
			for i = 1, #BarFactory.ActivePlayers do
				BarFactory.ActivePlayers[i]:Show()
			end
			
			BarFactory:SortPlayers() -- not needed?
			
			Window.BarParent.BarOffset = 1
			ScrollTable = BarFactory.ActivePlayers
			Window.ShowPlayers = true
		end
	elseif (button == "LeftButton" and IsShiftKeyDown()) then
		local Player = CurrentBar.Name:GetText()
		local Spell = format("\124cff71d5ff\124Hspell:%d\124h[%s]\124h\124r", self.Parent.SpellID, self.Parent.SpellName)
		
		if (BossName or LastBossName) then
			--print(format("%s's %s damage for %s: %s", Player, Spell, (BossName and BossName or LastBossName), self.Parent.Value:GetText()))
			SendChatMessage(format("%s's %s damage for %s: %s", Player, Spell, (BossName and BossName or LastBossName), self.Parent.Value:GetText()), ReportChannel)
		else
			--print(format("%s's %s damage for last fight: %s", Player, Spell, self.Parent.Value:GetText()))
			SendChatMessage(format("%s's %s damage for last fight: %s", Player, Spell, self.Parent.Value:GetText()), ReportChannel)
		end
	end
end

function BarFactory:NewPlayer()
	local Bar = CreateFrame("Frame", nil, Window.BarParent)
	Bar:SetSize(WindowWidth, BarHeight)
	
	Bar.Bar = CreateFrame("StatusBar", nil, Bar)
	Bar.Bar:SetSize(WindowWidth - 2, BarHeight - 2)
	Bar.Bar:SetPoint("LEFT", Bar, 1, 0)
	Bar.Bar:SetMinMaxValues(0, 0)
	Bar.Bar:SetValue(0)
	Bar.Bar:SetStatusBarTexture("Interface\\AddOns\\PersonalMetersGroup\\Assets\\vUI4.tga")
	Bar.Bar.Parent = Bar
	
	Bar.BarBG = Bar.Bar:CreateTexture(nil, "BACKGROUND")
	Bar.BarBG:SetPoint("TOPLEFT", Bar.Bar, -1, 1)
	Bar.BarBG:SetPoint("BOTTOMRIGHT", Bar.Bar:GetStatusBarTexture(), 1, -1)
	Bar.BarBG:SetTexture(0, 0, 0)
	
	Bar.Name = Bar.Bar:CreateFontString(nil, "OVERLAY")
	Bar.Name:SetPoint("LEFT", Bar.Bar, 4, 0)
	Bar.Name:SetFont("Interface\\AddOns\\PersonalMetersGroup\\Assets\\PTSans.ttf", 12)
	Bar.Name:SetJustifyH("LEFT")
	Bar.Name:SetShadowColor(0, 0, 0)
	Bar.Name:SetShadowOffset(1, -1)
	Bar.Name:SetSize(110, 12)
	
	Bar.Value = Bar.Bar:CreateFontString(nil, "OVERLAY")
	Bar.Value:SetPoint("RIGHT", Bar.Bar, -4, 0)
	Bar.Value:SetFont("Interface\\AddOns\\PersonalMetersGroup\\Assets\\PTSans.ttf", 12)
	Bar.Value:SetJustifyH("RIGHT")
	Bar.Value:SetShadowColor(0, 0, 0)
	Bar.Value:SetShadowOffset(1, -1)
	
	-- Data
	Bar.Total = 0 -- Healing/Damage/Whatever
	Bar.Effective = 0 -- Healing/Damage/Whatever - Overkill/Overhealing
	Bar.Waste = 0 -- Total - Effective
	Bar.Count = 0 -- Count of hits
	Bar.Criticals = 0 -- Count of crits
	Bar.Min = 0 -- Minimum hit
	Bar.Max = 0 -- Maximum hit
	
	Bar.Spells = {}
	
	Bar:SetScript("OnMouseUp", PlayerBarOnMouseUp)
	
	--[[Bar:SetScript("OnEnter", ShowIconTooltip)
	Bar:SetScript("OnLeave", HideIconTooltip)
	
	Bar.Bar:SetScript("OnMouseUp", PlayerBarOnMouseUp)
	Bar.Bar:SetScript("OnEnter", ShowBarTooltip)
	Bar.Bar:SetScript("OnLeave", HideBarTooltip)]]
	
	return Bar
end

function BarFactory:NewSpell()
	local Bar = CreateFrame("Frame", nil, Window.BarParent)
	Bar:SetSize(BarHeight, BarHeight)
	Bar:SetBackdrop(Backdrop)
	Bar:SetBackdropColor(0, 0, 0)
	
	Bar.Icon = Bar:CreateTexture(nil, "OVERLAY")
	Bar.Icon:SetPoint("TOPLEFT", Bar, 1, -1)
	Bar.Icon:SetPoint("BOTTOMRIGHT", Bar, -1, 1)
	Bar.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	
	Bar.Bar = CreateFrame("StatusBar", nil, Bar)
	Bar.Bar:SetSize((WindowWidth - BarHeight) - 1, BarHeight - 2)
	Bar.Bar:SetPoint("LEFT", Bar, "RIGHT", 0, 0)
	Bar.Bar:SetMinMaxValues(0, 0)
	Bar.Bar:SetValue(0)
	Bar.Bar:SetStatusBarTexture("Interface\\AddOns\\PersonalMetersGroup\\Assets\\vUI4.tga")
	Bar.Bar.Parent = Bar
	
	Bar.BarBG = Bar.Bar:CreateTexture(nil, "BACKGROUND")
	Bar.BarBG:SetPoint("TOPLEFT", Bar.Bar, -1, 1)
	Bar.BarBG:SetPoint("BOTTOMRIGHT", Bar.Bar:GetStatusBarTexture(), 1, -1)
	Bar.BarBG:SetTexture(0, 0, 0)
	
	Bar.Name = Bar.Bar:CreateFontString(nil, "OVERLAY")
	Bar.Name:SetPoint("LEFT", Bar.Bar, 4, 0)
	Bar.Name:SetFont("Interface\\AddOns\\PersonalMetersGroup\\Assets\\PTSans.ttf", 12)
	Bar.Name:SetJustifyH("LEFT")
	Bar.Name:SetSize(110, 12)
	Bar.Name:SetShadowColor(0, 0, 0)
	Bar.Name:SetShadowOffset(1, -1)
	
	Bar.Value = Bar.Bar:CreateFontString(nil, "OVERLAY")
	Bar.Value:SetPoint("RIGHT", Bar.Bar, -4, 0)
	Bar.Value:SetFont("Interface\\AddOns\\PersonalMetersGroup\\Assets\\PTSans.ttf", 12)
	Bar.Value:SetJustifyH("RIGHT")
	Bar.Value:SetShadowColor(0, 0, 0)
	Bar.Value:SetShadowOffset(1, -1)
	
	-- Data
	Bar.Total = 0 -- Healing/Damage/Whatever
	Bar.Effective = 0 -- Healing/Damage/Whatever - Overkill/Overhealing
	Bar.Waste = 0 -- Total - Effective
	Bar.Count = 0 -- Count of hits
	Bar.Criticals = 0 -- Count of crits
	Bar.Min = 0 -- Minimum hit
	Bar.Max = 0 -- Maximum hit
	
	Bar:SetScript("OnEnter", ShowIconTooltip)
	Bar:SetScript("OnLeave", HideIconTooltip)
	
	Bar.Bar:SetScript("OnEnter", ShowBarTooltip)
	Bar.Bar:SetScript("OnLeave", HideBarTooltip)
	
	Bar.Bar:SetScript("OnMouseUp", SpellBarOnMouseUp)
	
	return Bar
end

function BarFactory:RecyclePlayer(bar)
	for i = 1, #self.ActivePlayers do
		if (self.ActivePlayers[i] == bar) then
			local Bar = tremove(self.ActivePlayers, i)
			
			Bar.Total = 0
			Bar.Effective = 0
			Bar.Waste = 0
			Bar.Count = 0
			Bar.Criticals = 0
			Bar.Min = 0
			Bar.Max = 0
			
			Bar:Hide()
			Bar:ClearAllPoints()
			
			for i = 1, #Bar.Spells do
				self:RecycleSpell(Bar, Bar.Spells[1])
			end
			
			tinsert(self.FreePlayers, Bar)
		end
	end
end

function BarFactory:RecycleSpell(player, spell)
	for i = 1, #player.Spells do
		if (player.Spells[i] == spell) then
			local Bar = tremove(player.Spells, i)
			
			Bar.Total = 0
			Bar.Effective = 0
			Bar.Waste = 0
			Bar.Count = 0
			Bar.Criticals = 0
			Bar.Min = 0
			Bar.Max = 0
			
			Bar:Hide()
			Bar:ClearAllPoints()
			
			tinsert(self.FreeSpells, Bar)
		end
	end
end

function BarFactory:GetPlayer()
	local Bar
	
	if self.FreePlayers[1] then
		Bar = tremove(self.FreePlayers, 1)
		Bar:Show()
	else
		Bar = self:NewPlayer()
	end
	
	return Bar
end

function BarFactory:GetSpell()
	local Bar
	
	if self.FreeSpells[1] then
		Bar = tremove(self.FreeSpells, 1)
		Bar:Show()
	else
		Bar = self:NewSpell()
	end
	
	return Bar
end

function BarFactory:SortPlayers()
	sort(self.ActivePlayers, function(a, b)
		return a.Total > b.Total
	end)
	
	for i = 1, #self.ActivePlayers do
		if (i == 1) then
			self.ActivePlayers[i]:SetPoint("TOPLEFT", Window, "BOTTOMLEFT", 0, 1)
		else
			self.ActivePlayers[i]:SetPoint("TOPLEFT", self.ActivePlayers[i-1], "BOTTOMLEFT", 0, 1)
		end
		
		self.ActivePlayers[i].Bar:SetMinMaxValues(0, self.ActivePlayers[1].Total)
		self.ActivePlayers[i].Bar:SetValue(self.ActivePlayers[i].Total)
		
		if  (i > NumBarsToShow) then
			self.ActivePlayers[i]:Hide()
		else
			self.ActivePlayers[i]:Show()
		end
	end
end

function BarFactory:SortSpells(bar)
	sort(bar.Spells, function(a, b)
		return a.Total > b.Total
	end)
	
	for i = 1, #bar.Spells do
		if (i == 1) then
			bar.Spells[i]:SetPoint("TOPLEFT", Window, "BOTTOMLEFT", 0, 1)
		else
			bar.Spells[i]:SetPoint("TOPLEFT", bar.Spells[i-1], "BOTTOMLEFT", 0, 1)
		end
		
		bar.Spells[i].Bar:SetMinMaxValues(0, bar.Spells[1].Total)
		bar.Spells[i].Bar:SetValue(bar.Spells[i].Total)
		
		if  (i > NumBarsToShow) then
			bar.Spells[i]:Hide()
		else
			bar.Spells[i]:Show()
		end
	end
end

function BarFactory:Reset()
	for i = 1, #self.ActivePlayers do
		self:RecyclePlayer(self.ActivePlayers[1])
	end
	
	Window.BarParent.BarOffset = 1
	LastBossName = BossName
	BossName = nil
	NeedsReset = false
end

-- Modules
Window:RegisterModule("SWING_DAMAGE", function(...)
	Timestamp, EventType, _, SourceGUID, SourceName, SourceFlags, _, DestGUID, DestName, DestFlags = ...
	_, _, _, Amount, Overkill, School, _, _, Absorbed, Critical = select(9, ...)
	Overkill = max(0, Overkill)
	
	AddData(SourceName, SourceGUID, 6603, MeleeName, School, Amount, (Amount - Overkill), (Critical and 1 or 0), IsPet(SourceGUID))
end)

Window:RegisterModule("SPELL_DAMAGE", function(...)
	Timestamp, EventType, _, SourceGUID, SourceName, SourceFlags, _, DestGUID, DestName, DestFlags = ...
	_, _, _, SpellID, SpellName, SpellSchool, Amount, Overkill, _, _, _, _, Critical = select(9, ...)
	Overkill = max(0, Overkill)
	
	AddData(SourceName, SourceGUID, SpellID, SpellName, SpellSchool, Amount, (Amount - Overkill), (Critical and 1 or 0), IsPet(SourceGUID))
end)

Window:RegisterModule("SPELL_PERIODIC_DAMAGE", function(...)
	Timestamp, EventType, _, SourceGUID, SourceName, SourceFlags, _, DestGUID, DestName, DestFlags = ...
	_, _, _, SpellID, SpellName, SpellSchool, Amount, Overkill, _, _, _, _, Critical = select(9, ...)
	Overkill = max(0, Overkill)
	
	AddData(SourceName, SourceGUID, SpellID, SpellName, SpellSchool, Amount, (Amount - Overkill), (Critical and 1 or 0), IsPet(SourceGUID))
end)

Window:RegisterModule("RANGE_DAMAGE", function(...)
	Timestamp, EventType, _, SourceGUID, SourceName, SourceFlags, _, DestGUID, DestName, DestFlags = ...
	_, _, _, SpellID, SpellName, SpellSchool, Amount, Overkill, _, _, _, _, Critical = select(9, ...)
	Overkill = max(0, Overkill)
	
	AddData(SourceName, SourceGUID, SpellID, SpellName, SpellSchool, Amount, (Amount - Overkill), (Critical and 1 or 0), IsPet(SourceGUID))
end)

Window:RegisterModule("SPELL_SUMMON", function(...)
	Timestamp, EventType, _, SourceGUID, SourceName, SourceFlags, _, DestGUID, DestName, DestFlags = ...
	
	AddPet(DestGUID, DestName, SourceGUID)
end)