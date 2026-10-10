-- Banner: configuration window (WotLK 3.3.5 API)
Banner = Banner or {}
local B = Banner

local counter = 0
local function UName(prefix)
    counter = counter + 1
    return "BannerUI" .. prefix .. counter
end

local function ClassColored(token, text)
    local c = RAID_CLASS_COLORS and RAID_CLASS_COLORS[token]
    if not c then return text end
    return format("|cff%02x%02x%02x%s|r", c.r * 255, c.g * 255, c.b * 255, text)
end

-- 3.3.5 UIDropDownMenu helpers (argument orders differ between patches, so
-- width and text are set directly on the template's child regions)
local function SetDDWidth(dd, w)
    local n = dd:GetName()
    _G[n .. "Middle"]:SetWidth(w)
    dd:SetWidth(w + 50)
    _G[n .. "Text"]:SetWidth(w - 25)
    dd.noResize = 1
end

local function SetDDText(dd, text)
    _G[dd:GetName() .. "Text"]:SetText(text)
end

local function MenuLevel(a, b)
    if type(a) == "number" then return a end
    return b or UIDROPDOWNMENU_MENU_LEVEL or 1
end

local function Summarize(list, empty)
    if #list == 0 then return empty end
    local s = table.concat(list, ", ")
    if #s > 30 then s = #list .. " selected" end
    return s
end

------------------------------------------------------------------------
-- Dropdown menu builders
------------------------------------------------------------------------
local function InstanceInit(a, b)
    local level = MenuLevel(a, b)
    local db = B.db
    if level == 1 then
        UIDropDownMenu_AddButton({
            text = "Clear all", notCheckable = 1,
            func = function() wipe(db.instances); wipe(db.progress); B:RefreshAll() end,
        }, level)
        for i, raid in ipairs(B.RAIDS) do
            UIDropDownMenu_AddButton({
                text = raid.name, hasArrow = 1, notCheckable = 1, value = i,
            }, level)
        end
    else
        local raid = B.RAIDS[UIDROPDOWNMENU_MENU_VALUE]
        if not raid then return end
        for _, v in ipairs(raid.variants) do
            local key = v.key
            UIDropDownMenu_AddButton({
                text = v.label,
                checked = db.instances[key] and 1 or nil,
                keepShownOnClick = 1,
                func = function()
                    db.instances[key] = (not db.instances[key]) or nil
                    B:UpdateTexts()
                end,
            }, level)
        end
    end
end

local function ProgressInit(a, b)
    local level = MenuLevel(a, b)
    local db = B.db
    if level == 1 then
        local any = false
        for _, raid in ipairs(B.RAIDS) do
            for _, v in ipairs(raid.variants) do
                if db.instances[v.key] and (v.bosses or 0) > 1 then
                    any = true
                    local p = db.progress[v.key]
                    UIDropDownMenu_AddButton({
                        text = p and format("%s  (%d/%d)", v.short, p, v.bosses) or v.short,
                        hasArrow = 1, notCheckable = 1, value = v.key,
                    }, level)
                end
            end
        end
        if not any then
            UIDropDownMenu_AddButton({
                text = "Select instances first", isTitle = 1, notCheckable = 1,
            }, level)
        end
    else
        local key = UIDROPDOWNMENU_MENU_VALUE
        local v = B.VARIANTS[key]
        if not v then return end
        UIDropDownMenu_AddButton({
            text = "Not specified",
            checked = (db.progress[key] == nil) and 1 or nil,
            func = function() db.progress[key] = nil; B:RefreshAll() end,
        }, level)
        for n = 1, v.bosses do
            local count = n
            UIDropDownMenu_AddButton({
                text = format("%d/%d bosses", count, v.bosses),
                checked = (db.progress[key] == count) and 1 or nil,
                func = function() db.progress[key] = count; B:RefreshAll() end,
            }, level)
        end
    end
end

local function ChannelInit(a, b)
    local level = MenuLevel(a, b)
    if level ~= 1 then return end
    local db = B.db
    local seen = {}

    local function toggle(lower, display)
        if db.channels[lower] then db.channels[lower] = nil else db.channels[lower] = display end
        B:UpdateTexts()
    end

    for _, c in ipairs(B.CHAT_TYPES) do
        local t = c.type
        UIDropDownMenu_AddButton({
            text = c.menu,
            checked = db.chat[t] and 1 or nil,
            keepShownOnClick = 1,
            func = function()
                db.chat[t] = (not db.chat[t]) or nil
                B:UpdateTexts()
            end,
        }, level)
    end

    for _, ch in ipairs(B:GetJoinedChannels()) do
        local lower, display = ch.base:lower(), ch.base
        if not seen[lower] then
            seen[lower] = true
            UIDropDownMenu_AddButton({
                text = format("%d. %s", ch.id, ch.name),
                checked = db.channels[lower] and 1 or nil,
                keepShownOnClick = 1,
                func = function() toggle(lower, display) end,
            }, level)
        end
    end

    -- Remembered selections for channels that are not currently joined
    for lower, display in pairs(db.channels) do
        if not seen[lower] then
            UIDropDownMenu_AddButton({
                text = display .. " (not joined)",
                checked = 1,
                keepShownOnClick = 1,
                func = function() toggle(lower, display) end,
            }, level)
        end
    end

    UIDropDownMenu_AddButton({
        text = "Tip: /join LookingForGroup", isTitle = 1, notCheckable = 1,
    }, level)
end

------------------------------------------------------------------------
-- Widget helpers
------------------------------------------------------------------------
local function MakeLabel(parent, text, x, y, font)
    local fs = parent:CreateFontString(nil, "ARTWORK", font or "GameFontNormal")
    fs:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    fs:SetText(text)
    return fs
end

local function MakeEdit(parent, x, y, w, numeric)
    local e = CreateFrame("EditBox", UName("Edit"), parent, "InputBoxTemplate")
    e:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    e:SetWidth(w)
    e:SetHeight(20)
    e:SetAutoFocus(false)
    if numeric then
        e:SetNumeric(true)
        e:SetMaxLetters(5)
    end
    e:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    e:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    return e
end

------------------------------------------------------------------------
-- Window
------------------------------------------------------------------------
function B:CreateUI()
    if self.frame then return end
    local db = self.db

    local f = CreateFrame("Frame", "BannerFrame", UIParent)
    f:SetWidth(400)
    f:SetHeight(576)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:SetClampedToScreen(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetBackdrop({
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 },
    })
    f:Hide()
    tinsert(UISpecialFrames, "BannerFrame")
    self.frame = f

    local hdr = f:CreateTexture(nil, "ARTWORK")
    hdr:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
    hdr:SetWidth(256)
    hdr:SetHeight(64)
    hdr:SetPoint("TOP", f, "TOP", 0, 12)
    self.hdr = hdr
    local title = f:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    title:SetPoint("TOP", hdr, "TOP", 0, -14)
    title:SetText("Banner")
    self.title = title

    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -5, -5)
    self.closeBtn = close

    -- Instances / Specs / Channels dropdowns -------------------------------
    local function MakeDropdown(label, y, init)
        MakeLabel(f, label, 24, y - 8)
        local dd = CreateFrame("Frame", UName("DD"), f, "UIDropDownMenuTemplate")
        dd:SetPoint("TOPLEFT", f, "TOPLEFT", 84, y)
        SetDDWidth(dd, 200)
        UIDropDownMenu_Initialize(dd, init, nil, 1)
        return dd
    end
    self.ddInst = MakeDropdown("Instances", -40,  InstanceInit)
    self.ddProg = MakeDropdown("Progress",  -76,  ProgressInit)
    MakeLabel(f, "Specs", 24, -120)
    local specBtn = CreateFrame("Button", UName("Btn"), f, "UIPanelButtonTemplate")
    specBtn:SetPoint("TOPLEFT", f, "TOPLEFT", 98, -114)
    specBtn:SetWidth(240)
    specBtn:SetHeight(24)
    specBtn:SetScript("OnClick", function() B:ToggleSpecPanel() end)
    self.specBtn = specBtn
    self.ddChan = MakeDropdown("Channels",  -148, ChannelInit)

    -- Min GearScore / stop size ---------------------------------------------
    MakeLabel(f, "Min GS", 24, -198)
    self.gsBox = MakeEdit(f, 90, -194, 60, true)
    self.gsBox:SetScript("OnTextChanged", function(e)
        if B.refreshing then return end
        db.minGS = tonumber(e:GetText()) or 0
        B:UpdateTexts()
    end)

    MakeLabel(f, "Stop at size", 180, -198)
    self.stopBox = MakeEdit(f, 268, -194, 40, true)
    self.stopBox:SetScript("OnTextChanged", function(e)
        if B.refreshing then return end
        db.stopAt = tonumber(e:GetText()) or 0
    end)
    MakeLabel(f, "(0 = off)", 316, -198, "GameFontHighlightSmall")

    -- Reservations ------------------------------------------------------------
    MakeLabel(f, "Reserves", 24, -226)
    self.resBox = MakeEdit(f, 28, -245, 344)
    self.resBox:SetScript("OnTextChanged", function(e)
        if B.refreshing then return end
        db.reserves = e:GetText()
        B:UpdateTexts()
    end)
    MakeLabel(f, "Shift-click items to add links. Separate text entries with commas.",
        24, -270, "GameFontHighlightSmall")

    -- Extra note ----------------------------------------------------------------
    MakeLabel(f, "Extra note (optional)", 24, -292)
    self.noteBox = MakeEdit(f, 28, -310, 344)
    self.noteBox:SetScript("OnTextChanged", function(e)
        if B.refreshing then return end
        db.note = e:GetText()
        B:UpdateTexts()
    end)

    -- Interval slider -------------------------------------------------------------
    local sName = "BannerIntervalSlider"
    local s = CreateFrame("Slider", sName, f, "OptionsSliderTemplate")
    s:SetPoint("TOPLEFT", f, "TOPLEFT", 28, -368)
    s:SetWidth(340)
    s:SetMinMaxValues(10, 300)
    s:SetValueStep(10)
    _G[sName .. "Low"]:SetText("10s")
    _G[sName .. "High"]:SetText("300s")
    s:SetScript("OnValueChanged", function(self, value)
        value = floor((value or 60) / 10 + 0.5) * 10
        _G[sName .. "Text"]:SetText("Post every " .. value .. " seconds")
        if B.refreshing then return end
        db.interval = value
    end)
    self.slider = s

    -- Preview -------------------------------------------------------------------------
    MakeLabel(f, "Preview", 24, -398)
    local pv = CreateFrame("Frame", nil, f)
    pv:SetPoint("TOPLEFT", f, "TOPLEFT", 24, -416)
    pv:SetWidth(352)
    pv:SetHeight(88)
    pv:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    pv:SetBackdropColor(0, 0, 0, 0.6)
    self.previewFrame = pv
    local pt = pv:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    pt:SetPoint("TOPLEFT", pv, "TOPLEFT", 8, -8)
    pt:SetPoint("BOTTOMRIGHT", pv, "BOTTOMRIGHT", -8, 8)
    pt:SetJustifyH("LEFT")
    pt:SetJustifyV("TOP")
    self.preview = pt

    -- Status + buttons --------------------------------------------------------------------
    self.status = MakeLabel(f, "", 24, -514, "GameFontHighlightSmall")

    local startBtn = CreateFrame("Button", UName("Btn"), f, "UIPanelButtonTemplate")
    startBtn:SetPoint("TOPLEFT", f, "TOPLEFT", 24, -534)
    startBtn:SetWidth(130)
    startBtn:SetHeight(24)
    startBtn:SetScript("OnClick", function()
        if B.running then B:Stop() else B:Start() end
    end)
    self.startBtn = startBtn

    local onceBtn = CreateFrame("Button", UName("Btn"), f, "UIPanelButtonTemplate")
    onceBtn:SetPoint("LEFT", startBtn, "RIGHT", 8, 0)
    onceBtn:SetWidth(110)
    onceBtn:SetHeight(24)
    onceBtn:SetText("Send once")
    onceBtn:SetScript("OnClick", function() B:Broadcast(true) end)
    self.onceBtn = onceBtn

    f:SetScript("OnShow", function() B:RefreshUI() end)

    if self.CreateSpecPanel then self:CreateSpecPanel() end
    if self.SkinUI then self:SkinUI() end
end

------------------------------------------------------------------------
-- Refresh
------------------------------------------------------------------------
function B:UpdateTexts()
    if not self.frame then return end
    local db = self.db

    SetDDText(self.ddInst, Summarize(self:GetSelectedInstances(), "None selected"))

    local prog = {}
    for _, raid in ipairs(self.RAIDS) do
        for _, v in ipairs(raid.variants) do
            if db.instances[v.key] and db.progress[v.key] and (v.bosses or 0) > 1 then
                prog[#prog + 1] = self:FormatInstance(v)
            end
        end
    end
    SetDDText(self.ddProg, Summarize(prog, "Not set"))

    local specLabels = self:CountSelectedSpecs() > 0 and self:GetSelectedSpecLabels() or {}
    self.specBtn:SetText(Summarize(specLabels, "None selected"))

    local chans = {}
    for _, display in pairs(db.channels) do chans[#chans + 1] = display end
    table.sort(chans)
    for i = #self.CHAT_TYPES, 1, -1 do
        local c = self.CHAT_TYPES[i]
        if db.chat[c.type] then table.insert(chans, 1, c.name) end
    end
    SetDDText(self.ddChan, Summarize(chans, "None selected"))

    local lines = self:BuildMessage()
    self.preview:SetText(table.concat(lines, "\n"))

    if self.RefreshSpecPanel then self:RefreshSpecPanel() end
end

function B:RefreshUI()
    if not self.frame then return end
    local db = self.db

    self.refreshing = true
    self.gsBox:SetText(tostring(db.minGS or 0))
    self.stopBox:SetText(tostring(db.stopAt or 0))
    self.resBox:SetText(db.reserves or "")
    self.noteBox:SetText(db.note or "")
    self.slider:SetValue(db.interval or 60)
    _G["BannerIntervalSliderText"]:SetText("Post every " .. (db.interval or 60) .. " seconds")
    self.refreshing = false

    self:UpdateTexts()
    self:UpdateStatus()
end

function B:UpdateStatus()
    local f = self.frame
    if not f or not f:IsShown() then return end

    local txt
    if self.running then
        if #self.queue > 0 then
            txt = format("|cff00ff00Broadcasting|r - sending (%d queued)", #self.queue)
        else
            local left = math.max(0, math.ceil(self.nextSend - GetTime()))
            txt = format("|cff00ff00Broadcasting|r - next post in %ds", left)
        end
    else
        txt = "|cffff4040Stopped|r"
    end
    self.status:SetText(txt)
    self.startBtn:SetText(self.running and "Stop" or "Start")
end

function B:ToggleUI()
    self:CreateUI()
    if self.frame:IsShown() then self.frame:Hide() else self.frame:Show() end
end

------------------------------------------------------------------------
-- Shift-click item links into the reservations box
------------------------------------------------------------------------
hooksecurefunc("ChatEdit_InsertLink", function(text)
    local box = B.resBox
    if text and box and box:IsVisible() and box:HasFocus() then
        box:Insert(text .. " ")
    end
end)
