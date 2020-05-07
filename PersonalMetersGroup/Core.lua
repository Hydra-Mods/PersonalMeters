local Options = {
	["DPS"] = {
		["WindowWidth"] = 195,
		["NumBarsToShow"] = 5,
		["BarHeight"] = 22,
		["UseSchoolColors"] = true,
	},
}

local Backdrop = {
	bgFile = "Interface\\AddOns\\PersonalMetersGroup\\Assets\\vUIBlank.tga",
	insets = {top = 0, left = 0, bottom = 0, right = 0},
}

local BackdropAndBorder = {
	bgFile = "Interface\\AddOns\\PersonalMetersGroup\\Assets\\vUIBlank.tga",
	edgeFile = "Interface\\AddOns\\PersonalMetersGroup\\Assets\\vUIBlank.tga", edgeSize = 1,
	insets = {top = 0, left = 0, bottom = 0, right = 0},
}

local ConfigWindows = {}

-- Main Window
GUI = CreateFrame("Frame", nil, UIParent)
GUI:SetSize(201, 212) -- 398
GUI:SetPoint("CENTER", UIParent, 0, 0)
GUI:SetBackdrop(BackdropAndBorder)
GUI:SetBackdropColor(0.17, 0.17, 0.17, 0.8)
GUI:SetBackdropBorderColor(0, 0, 0)
GUI:Hide()

GUI.Header = CreateFrame("StatusBar", nil, GUI)
GUI.Header:SetSize(199, 20) -- 396
GUI.Header:SetPoint("BOTTOM", GUI, "TOP", 0, 0)
GUI.Header:SetMinMaxValues(0, 1)
GUI.Header:SetValue(1)
GUI.Header:SetStatusBarTexture("Interface\\AddOns\\PersonalMetersGroup\\Assets\\vUI4.tga")
GUI.Header:SetStatusBarColor(0.17, 0.17, 0.17)

GUI.Header.BG = GUI.Header:CreateTexture(nil, "BORDER")
GUI.Header.BG:SetPoint("TOPLEFT", GUI.Header, -1, 1)
GUI.Header.BG:SetPoint("BOTTOMRIGHT", GUI.Header, 1, -1)
GUI.Header.BG:SetTexture(0, 0, 0)

GUI.Text = GUI.Header:CreateFontString(nil, "OVERLAY")
GUI.Text:SetPoint("LEFT", GUI.Header, 3, 0)
GUI.Text:SetFont("Interface\\AddOns\\PersonalMetersGroup\\Assets\\PTSans.ttf", 12, "OUTLINE")
GUI.Text:SetJustifyH("LEFT")
GUI.Text:SetText("PersonalMetersGroup")

GUI.CloseButton = CreateFrame("Frame", nil, GUI.Header)
GUI.CloseButton:SetPoint("RIGHT", GUI.Header, 0, 1.5)
GUI.CloseButton:SetSize(20, 20)
GUI.CloseButton:SetScript("OnEnter", function(self) self.Label:SetTextColor(1, 0, 0) end)
GUI.CloseButton:SetScript("OnLeave", function(self) self.Label:SetTextColor(1, 1, 1) end)
GUI.CloseButton:SetScript("OnMouseUp", function(self) GUI:Hide() end)

GUI.CloseButton.Label = GUI.CloseButton:CreateFontString(nil, "OVERLAY")
GUI.CloseButton.Label:SetPoint("CENTER", GUI.CloseButton, 0, 0)
GUI.CloseButton.Label:SetFont("Interface\\AddOns\\PersonalMetersGroup\\Assets\\PTSans.ttf", 18, "OUTLINE")
GUI.CloseButton.Label:SetText("×")
GUI.CloseButton.Label:SetShadowColor(0, 0, 0)
GUI.CloseButton.Label:SetShadowOffset(1.25, -1.25)

-- DPS Options Window
local DPSWindow = CreateFrame("Frame", "PersonalMeterGUIDPS", GUI)
DPSWindow:SetSize(195, 22)
DPSWindow:SetPoint("TOPLEFT", GUI, 3, -3)
DPSWindow:SetBackdrop(Backdrop)
DPSWindow:SetBackdropColor(0, 0, 0)

DPSWindow.Header = CreateFrame("StatusBar", nil, DPSWindow)
DPSWindow.Header:SetSize(193, 20)
DPSWindow.Header:SetPoint("CENTER", DPSWindow, 0, 0)
DPSWindow.Header:SetMinMaxValues(0, 1)
DPSWindow.Header:SetValue(1)
DPSWindow.Header:SetStatusBarTexture("Interface\\AddOns\\PersonalMetersGroup\\Assets\\vUI4.tga")
DPSWindow.Header:SetStatusBarColor(0.17, 0.17, 0.17)

DPSWindow.Text = DPSWindow.Header:CreateFontString(nil, "OVERLAY")
DPSWindow.Text:SetPoint("LEFT", DPSWindow.Header, 3, 0)
DPSWindow.Text:SetFont("Interface\\AddOns\\PersonalMetersGroup\\Assets\\PTSans.ttf", 12, "OUTLINE")
DPSWindow.Text:SetJustifyH("LEFT")
DPSWindow.Text:SetText("DPS Options")

DPSWindow.Options = CreateFrame("Frame", nil, DPSWindow)
DPSWindow.Options:SetSize(195, 185) -- (NumBarsToShow * 22 - (NumBarsToShow - 1))
DPSWindow.Options:SetPoint("TOP", DPSWindow, "BOTTOM", 0, 1)
DPSWindow.Options:SetBackdrop(BackdropAndBorder)
DPSWindow.Options:SetBackdropColor(0.17, 0.17, 0.17, 0.8)
DPSWindow.Options:SetBackdropBorderColor(0, 0, 0)

-- HPS Options Window
local HPSWindow = CreateFrame("Frame", "PersonalMeterGUIHPS", GUI)
HPSWindow:SetSize(195, 22)
HPSWindow:SetPoint("TOPLEFT", GUI, 3, -3)
HPSWindow:SetBackdrop(Backdrop)
HPSWindow:SetBackdropColor(0, 0, 0)
HPSWindow:Hide()

HPSWindow.Header = CreateFrame("StatusBar", nil, HPSWindow)
HPSWindow.Header:SetSize(193, 20)
HPSWindow.Header:SetPoint("CENTER", HPSWindow, 0, 0)
HPSWindow.Header:SetMinMaxValues(0, 1)
HPSWindow.Header:SetValue(1)
HPSWindow.Header:SetStatusBarTexture("Interface\\AddOns\\PersonalMetersGroup\\Assets\\vUI4.tga")
HPSWindow.Header:SetStatusBarColor(0.17, 0.17, 0.17)

HPSWindow.Text = HPSWindow.Header:CreateFontString(nil, "OVERLAY")
HPSWindow.Text:SetPoint("LEFT", HPSWindow.Header, 3, 0)
HPSWindow.Text:SetFont("Interface\\AddOns\\PersonalMetersGroup\\Assets\\PTSans.ttf", 12, "OUTLINE")
HPSWindow.Text:SetJustifyH("LEFT")
HPSWindow.Text:SetText("HPS Options")

HPSWindow.Options = CreateFrame("Frame", nil, HPSWindow)
HPSWindow.Options:SetSize(195, 185) -- (NumBarsToShow * 22 - (NumBarsToShow - 1))
HPSWindow.Options:SetPoint("TOP", HPSWindow, "BOTTOM", 0, 1)
HPSWindow.Options:SetBackdrop(BackdropAndBorder)
HPSWindow.Options:SetBackdropColor(0.17, 0.17, 0.17, 0.8)
HPSWindow.Options:SetBackdropBorderColor(0, 0, 0)

ConfigWindows[1] = DPSWindow
ConfigWindows[2] = HPSWindow

local ActiveWindow = 1
local Min = 1
local Max = #ConfigWindows

local ScrollWindows = function(self, delta)
	if (delta > 0) then -- right
		ActiveWindow = ActiveWindow + 1
	else -- left
		ActiveWindow = ActiveWindow - 1
	end
	
	if (ActiveWindow < Min) then
		ActiveWindow = Min
	end
	
	if (ActiveWindow > Max) then
		ActiveWindow = Max
	end
	
	for i = 1, Max do
		ConfigWindows[i]:Hide()
	end
	
	ConfigWindows[ActiveWindow]:Show()
end

GUI:SetScript("OnMouseWheel", ScrollWindows)

local CreateCheckbox = function(p)
	local Checkbox = CreateFrame("Frame", nil, p)
	Checkbox:SetSize(22, 22)
	Checkbox:SetBackdrop(Backdrop)
	Checkbox:SetBackdropColor(0, 0, 0)
	Checkbox.Boolean = true
	Checkbox:SetScript("OnMouseUp", function(self)
		if self.Boolean then
			self.Boolean = false
			self.Texture:SetStatusBarColor(0.8, 0.2, 0.2)
		else
			self.Boolean = true
			self.Texture:SetStatusBarColor(0.2, 0.8, 0.2)
		end
		
		if self.Hook then
			self:Hook(self.Boolean)
		end
	end)
	
	Checkbox.Texture = CreateFrame("StatusBar", nil, Checkbox)
	Checkbox.Texture:SetSize(20, 20)
	Checkbox.Texture:SetPoint("CENTER", Checkbox, 0, 0)
	Checkbox.Texture:SetMinMaxValues(0, 1)
	Checkbox.Texture:SetValue(1)
	Checkbox.Texture:SetStatusBarTexture("Interface\\AddOns\\PersonalMetersGroup\\Assets\\vUI4.tga")
	Checkbox.Texture:SetStatusBarColor(0.2, 0.8, 0.2)
	
	Checkbox.Text = Checkbox:CreateFontString(nil, "OVERLAY")
	Checkbox.Text:SetPoint("LEFT", Checkbox, "RIGHT", 3, 0)
	Checkbox.Text:SetFont("Interface\\AddOns\\PersonalMetersGroup\\Assets\\PTSans.ttf", 12, "OUTLINE")
	Checkbox.Text:SetJustifyH("LEFT")
	
	return Checkbox
end

local CreateEditbox = function(p)
	local Editbox = CreateFrame("Frame", nil, p)
	Editbox:SetSize(36, 22)
	Editbox:SetBackdrop(Backdrop)
	Editbox:SetBackdropColor(0, 0, 0)
	Editbox.Number = 0
	Editbox.Max = 20
	Editbox.Min = 1
	Editbox.Step = 1
	Editbox:SetScript("OnMouseWheel", function(self, delta)
		if (delta > 0) then
			self.Number = self.Number + self.Step
			
			if (self.Number > self.Max) then
				self.Number = self.Max
			end
		else
			self.Number = self.Number - self.Step
			
			if (self.Number < self.Min) then
				self.Number = self.Min
			end
		end
		
		Editbox.Label:SetText(self.Number)
		
		if self.Hook then
			self:Hook(self.Number)
		end
	end)
	
	Editbox.Texture = CreateFrame("StatusBar", nil, Editbox)
	Editbox.Texture:SetSize(34, 20)
	Editbox.Texture:SetPoint("CENTER", Editbox, 0, 0)
	Editbox.Texture:SetMinMaxValues(0, 1)
	Editbox.Texture:SetValue(1)
	Editbox.Texture:SetStatusBarTexture("Interface\\AddOns\\PersonalMetersGroup\\Assets\\vUI4.tga")
	Editbox.Texture:SetStatusBarColor(0.17, 0.17, 0.17)
	
	Editbox.Label = Editbox.Texture:CreateFontString(nil, "OVERLAY")
	Editbox.Label:SetPoint("LEFT", Editbox, 3, 0)
	Editbox.Label:SetFont("Interface\\AddOns\\PersonalMetersGroup\\Assets\\PTSans.ttf", 12, "OUTLINE")
	Editbox.Label:SetJustifyH("LEFT")
	
	Editbox.Text = Editbox:CreateFontString(nil, "OVERLAY")
	Editbox.Text:SetPoint("LEFT", Editbox, "RIGHT", 3, 0)
	Editbox.Text:SetFont("Interface\\AddOns\\PersonalMetersGroup\\Assets\\PTSans.ttf", 12, "OUTLINE")
	Editbox.Text:SetJustifyH("LEFT")
	
	return Editbox
end

local CreateButton = function(p)
	local Button = CreateFrame("Frame", nil, p)
	Button:SetSize(120, 22)
	Button:SetBackdrop(Backdrop)
	Button:SetBackdropColor(0, 0, 0)
	Button:SetScript("OnMouseUp", function(self)
		if self.Hook then
			self:Hook(self.Number)
		end
	end)
	
	Button.Texture = CreateFrame("StatusBar", nil, Button)
	Button.Texture:SetSize(118, 20)
	Button.Texture:SetPoint("CENTER", Button, 0, 0)
	Button.Texture:SetMinMaxValues(0, 1)
	Button.Texture:SetValue(1)
	Button.Texture:SetStatusBarTexture("Interface\\AddOns\\PersonalMetersGroup\\Assets\\vUI4.tga")
	Button.Texture:SetStatusBarColor(0.17, 0.17, 0.17)
	
	Button.Text = Button.Texture:CreateFontString(nil, "OVERLAY")
	Button.Text:SetPoint("CENTER", Button, 0, 0)
	Button.Text:SetFont("Interface\\AddOns\\PersonalMetersGroup\\Assets\\PTSans.ttf", 12, "OUTLINE")
	Button.Text:SetJustifyH("CENTER")
	
	return Button
end

-- DPS Widgets
local DPSEnable = CreateCheckbox(DPSWindow.Options)
DPSEnable:SetPoint("TOPLEFT", DPSWindow.Options, 3, -3)
DPSEnable.Text:SetText("Enable DPS Window")
DPSEnable.Hook = function(self, var)
	if var then
		PersonalMeterFrameDPS:Enable()
	else
		PersonalMeterFrameDPS:Disable()
	end
end

local DPSSchoolColors = CreateCheckbox(DPSWindow.Options)
DPSSchoolColors:SetPoint("TOPLEFT", DPSEnable, "BOTTOMLEFT", 0, -2)
DPSSchoolColors.Text:SetText("Use School Colors")
DPSSchoolColors.Hook = function(self, var)
	PersonalMeterFrameDPS:UpdateBarColors(var)
end

local DPSNumBars = CreateEditbox(DPSWindow.Options)
DPSNumBars:SetPoint("TOPLEFT", DPSSchoolColors, "BOTTOMLEFT", 0, -2)
DPSNumBars.Text:SetText("Number of Bars to Show")
DPSNumBars.Number = 5
DPSNumBars.Label:SetText("5")
DPSNumBars.Hook = function(self, var)
	PersonalMeterFrameDPS:UpdateBarsToShow(var)
end

local DPSWindowWidth = CreateEditbox(DPSWindow.Options)
DPSWindowWidth:SetPoint("TOPLEFT", DPSNumBars, "BOTTOMLEFT", 0, -2)
DPSWindowWidth.Text:SetText("Set Window Width")
DPSWindowWidth.Number = 195
DPSWindowWidth.Max = 300
DPSWindowWidth.Min = 100
DPSWindowWidth.Label:SetText("195")
DPSWindowWidth.Hook = function(self, var)
	PersonalMeterFrameDPS:UpdateWidth(var)
end

local DPSBarHeight = CreateEditbox(DPSWindow.Options)
DPSBarHeight:SetPoint("TOPLEFT", DPSWindowWidth, "BOTTOMLEFT", 0, -2)
DPSBarHeight.Text:SetText("Set Bar Height")
DPSBarHeight.Number = 22
DPSBarHeight.Max = 30
DPSBarHeight.Min = 15
DPSBarHeight.Label:SetText("22")
DPSBarHeight.Hook = function(self, var)
	PersonalMeterFrameDPS:UpdateBarHeight(var)
end

local DPSTestMode = CreateButton(DPSWindow.Options)
DPSTestMode:SetPoint("TOPLEFT", DPSBarHeight, "BOTTOMLEFT", 0, -2)
DPSTestMode.Text:SetText("Start Test Mode")
DPSTestMode.v = false
DPSTestMode.Hook = function(self)
	if self.v then
		PersonalMeterFrameDPS:StopTestMode()
		DPSTestMode.Text:SetText("Start Test Mode")
		self.v = false
	else
		PersonalMeterFrameDPS:StartTestMode()
		DPSTestMode.Text:SetText("Stop Test Mode")
		self.v = true
	end
end

-- HPS Widgets
local HPSEnable = CreateCheckbox(HPSWindow.Options)
HPSEnable:SetPoint("TOPLEFT", HPSWindow.Options, 3, -3)
HPSEnable.Text:SetText("Enable HPS Window")
HPSEnable.Hook = function(self, var)
	if var then
		PersonalMeterFrameHPS:Enable()
	else
		PersonalMeterFrameHPS:Disable()
	end
end

local HPSSchoolColors = CreateCheckbox(HPSWindow.Options)
HPSSchoolColors:SetPoint("TOPLEFT", HPSEnable, "BOTTOMLEFT", 0, -2)
HPSSchoolColors.Text:SetText("Use School Colors")
HPSSchoolColors.Hook = function(self, var)
	PersonalMeterFrameHPS:UpdateBarColors(var)
end

local HPSNumBars = CreateEditbox(HPSWindow.Options)
HPSNumBars:SetPoint("TOPLEFT", HPSSchoolColors, "BOTTOMLEFT", 0, -2)
HPSNumBars.Text:SetText("Number of Bars to Show")
HPSNumBars.Number = 5
HPSNumBars.Label:SetText("5")
HPSNumBars.Hook = function(self, var)
	PersonalMeterFrameHPS:UpdateBarsToShow(var)
end

local HPSWindowWidth = CreateEditbox(HPSWindow.Options)
HPSWindowWidth:SetPoint("TOPLEFT", HPSNumBars, "BOTTOMLEFT", 0, -2)
HPSWindowWidth.Text:SetText("Set Window Width")
HPSWindowWidth.Number = 195
HPSWindowWidth.Max = 300
HPSWindowWidth.Min = 100
HPSWindowWidth.Label:SetText("195")
HPSWindowWidth.Hook = function(self, var)
	PersonalMeterFrameHPS:UpdateWidth(var)
end

local HPSBarHeight = CreateEditbox(HPSWindow.Options)
HPSBarHeight:SetPoint("TOPLEFT", HPSWindowWidth, "BOTTOMLEFT", 0, -2)
HPSBarHeight.Text:SetText("Set Bar Height")
HPSBarHeight.Number = 22
HPSBarHeight.Max = 30
HPSBarHeight.Min = 15
HPSBarHeight.Label:SetText("22")
HPSBarHeight.Hook = function(self, var)
	PersonalMeterFrameHPS:UpdateBarHeight(var)
end

local HPSTestMode = CreateButton(HPSWindow.Options)
HPSTestMode:SetPoint("TOPLEFT", HPSBarHeight, "BOTTOMLEFT", 0, -2)
HPSTestMode.Text:SetText("Start Test Mode")
HPSTestMode.v = false
HPSTestMode.Hook = function(self)
	if self.v then
		PersonalMeterFrameHPS:StopTestMode()
		HPSTestMode.Text:SetText("Start Test Mode")
		self.v = false
	else
		PersonalMeterFrameHPS:StartTestMode()
		HPSTestMode.Text:SetText("Stop Test Mode")
		self.v = true
	end
end

SLASH_PersonalMetersGroup1 = "/pmeters"
SlashCmdList["PersonalMetersGroup"] = function(cmd)
	if GUI:IsShown() then
		GUI:Hide()
	else
		GUI:Show()
	end
end