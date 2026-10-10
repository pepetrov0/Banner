-- Banner: channel checkbox grid (side panel next to the main window)
Banner = Banner or {}
local B = Banner

local PANEL_W = 380
local COLS    = 2
local ROWS    = 8
local COL_W   = 170
local ROW_H   = 22
local GRID_X  = 18
local GRID_Y  = -40

function B:CreateChannelPanel()
    if self.chanPanel or not self.frame then return end
    local db = self.db

    local p = CreateFrame("Frame", "BannerChannelPanel", self.frame)
    p:SetWidth(PANEL_W)
    p:SetHeight(-GRID_Y + ROWS * ROW_H + 40)
    p:SetPoint("TOPLEFT", self.frame, "TOPRIGHT", -2, -12)
    p:EnableMouse(true)
    p:SetBackdrop({
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 },
    })
    p:Hide()
    self.chanPanel = p

    local title = p:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    title:SetPoint("TOP", p, "TOP", 0, -16)
    title:SetText("Channels")

    local close = CreateFrame("Button", nil, p, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", p, "TOPRIGHT", -5, -5)
    self.chanPanelClose = close

    -- A fixed pool of checkboxes; Refresh fills in as many as are needed.
    -- (Created up front so the ElvUI skin can reach every one of them.)
    self.chanChecks = {}
    for i = 1, COLS * ROWS do
        local col = (i - 1) % COLS
        local row = math.floor((i - 1) / COLS)
        local cb = CreateFrame("CheckButton", "BannerChanChk" .. i, p, "UICheckButtonTemplate")
        cb:SetPoint("TOPLEFT", p, "TOPLEFT", GRID_X + col * COL_W, GRID_Y - row * ROW_H)
        cb:SetWidth(22)
        cb:SetHeight(22)
        cb:SetHitRectInsets(0, -(COL_W - 24), 0, 0)
        _G[cb:GetName() .. "Text"]:SetFontObject(GameFontHighlightSmall)
        cb:SetScript("OnClick", function(self)
            local e = self.entry
            if not e then return end
            local on = self:GetChecked() and true or nil
            if e.kind == "chat" then
                db.chat[e.key] = on
            else
                db.channels[e.key] = on and e.display or nil
            end
            B:UpdateTexts()
        end)
        cb:Hide()
        self.chanChecks[i] = cb
    end

    local hint = p:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    hint:SetPoint("BOTTOMLEFT", p, "BOTTOMLEFT", GRID_X, 18)
    hint:SetText("Not listed? /join <name> in chat, then reopen.")

    p:SetScript("OnShow", function() B:RefreshChannelPanel() end)

    -- keep the list current if the player joins or leaves a channel while it is open
    local ev = CreateFrame("Frame")
    ev:RegisterEvent("CHAT_MSG_CHANNEL_NOTICE")
    ev:SetScript("OnEvent", function()
        if p:IsShown() then B:RefreshChannelPanel() end
    end)
end

function B:RefreshChannelPanel()
    local p = self.chanPanel
    if not p then return end
    local db = self.db

    local entries = {}

    for _, c in ipairs(self.CHAT_TYPES) do
        entries[#entries + 1] = {
            kind = "chat", key = c.type, text = c.name,
            checked = db.chat[c.type] and true or false,
            r = 1, g = (c.type == "YELL") and 0.4 or 1, b = (c.type == "YELL") and 0.4 or 1,
        }
    end

    local seen = {}
    for _, ch in ipairs(self:GetJoinedChannels()) do
        local lower = ch.base:lower()
        if not seen[lower] then
            seen[lower] = true
            entries[#entries + 1] = {
                kind = "channel", key = lower, display = ch.base,
                text = format("%d. %s", ch.id, ch.base),
                checked = db.channels[lower] ~= nil,
                r = 1, g = 1, b = 1,
            }
        end
    end

    -- remembered selections for channels that are not currently joined
    local stale = {}
    for lower, display in pairs(db.channels) do
        if not seen[lower] then stale[#stale + 1] = { lower = lower, display = display } end
    end
    table.sort(stale, function(x, y) return x.lower < y.lower end)
    for _, s in ipairs(stale) do
        entries[#entries + 1] = {
            kind = "channel", key = s.lower, display = s.display,
            text = s.display .. " (not joined)", checked = true,
            r = 0.6, g = 0.6, b = 0.6,
        }
    end

    for i, cb in ipairs(self.chanChecks) do
        local e = entries[i]
        cb.entry = e
        if e then
            local text = _G[cb:GetName() .. "Text"]
            text:SetText(e.text)
            text:SetTextColor(e.r, e.g, e.b)
            cb:SetChecked(e.checked and 1 or nil)
            cb:Show()
        else
            cb:Hide()
        end
    end
end

function B:ToggleChannelPanel()
    local p, f = self.chanPanel, self.frame
    if not p or not f then return end
    if p:IsShown() then
        p:Hide()
        return
    end
    if self.specPanel then self.specPanel:Hide() end

    p:ClearAllPoints()
    local right, left, screen = f:GetRight(), f:GetLeft(), UIParent:GetRight()
    if right and left and screen and right + PANEL_W > screen and left - PANEL_W > 0 then
        p:SetPoint("TOPRIGHT", f, "TOPLEFT", 2, -12)
    else
        p:SetPoint("TOPLEFT", f, "TOPRIGHT", -2, -12)
    end
    p:Show() -- OnShow refreshes the list
end
