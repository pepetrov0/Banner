-- Banner: class + spec checkbox grid (side panel next to the main window)
Banner = Banner or {}
local B = Banner

local PANEL_W      = 430
local ROW_H        = 22
local CLASS_COL_W  = 112
local SPEC_COL_W   = 72
local GRID_X       = 18
local GRID_Y       = -62

local counter = 0
local function UName(prefix)
    counter = counter + 1
    return "BannerSpec" .. prefix .. counter
end

local function MakeCheck(parent, x, y, label, colWidth, r, g, b)
    local cb = CreateFrame("CheckButton", UName("Chk"), parent, "UICheckButtonTemplate")
    cb:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    cb:SetWidth(22)
    cb:SetHeight(22)
    -- keep the clickable label area inside this cell so neighbours don't overlap
    cb:SetHitRectInsets(0, -(colWidth - 24), 0, 0)
    local text = _G[cb:GetName() .. "Text"]
    text:SetFontObject(GameFontHighlightSmall)
    text:SetText(label)
    if r then text:SetTextColor(r, g, b) end
    return cb
end

local function Tooltip(frame, title, line)
    frame:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(title)
        if line then GameTooltip:AddLine(line, 1, 1, 1) end
        GameTooltip:Show()
    end)
    frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

function B:CreateSpecPanel()
    if self.specPanel or not self.frame then return end
    local db = self.db

    local p = CreateFrame("Frame", "BannerSpecPanel", self.frame)
    p:SetWidth(PANEL_W)
    p:SetHeight(-GRID_Y + (#B.CLASSES * ROW_H) + 34)
    p:SetPoint("TOPLEFT", self.frame, "TOPRIGHT", -2, -12)
    p:EnableMouse(true)
    p:SetBackdrop({
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 },
    })
    p:Hide()
    self.specPanel = p

    local title = p:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    title:SetPoint("TOP", p, "TOP", 0, -16)
    title:SetText("Classes & Specs")

    local close = CreateFrame("Button", nil, p, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", p, "TOPRIGHT", -5, -5)
    self.specPanelClose = close

    -- Quick-select buttons ----------------------------------------------------
    local function ToggleRole(role)
        local all = true
        for _, s in ipairs(B.SPECS) do
            if s.role == role and not db.specs[s.key] then all = false break end
        end
        for _, s in ipairs(B.SPECS) do
            if s.role == role then db.specs[s.key] = (not all) or nil end
        end
        B:UpdateTexts()
    end

    local quick = {
        { "All",    function() for _, s in ipairs(B.SPECS) do db.specs[s.key] = true end B:UpdateTexts() end },
        { "None",   function() wipe(db.specs) B:UpdateTexts() end },
        { "Tanks",  function() ToggleRole("T") end },
        { "Healers", function() ToggleRole("H") end },
        { "Melee",  function() ToggleRole("M") end },
        { "Ranged", function() ToggleRole("R") end },
    }
    self.specPanelButtons = {}
    for i, q in ipairs(quick) do
        local btn = CreateFrame("Button", UName("Btn"), p, "UIPanelButtonTemplate")
        btn:SetPoint("TOPLEFT", p, "TOPLEFT", GRID_X + (i - 1) * 62, -36)
        btn:SetWidth(58)
        btn:SetHeight(20)
        btn:SetText(q[1])
        btn:SetScript("OnClick", q[2])
        self.specPanelButtons[#self.specPanelButtons + 1] = btn
    end

    -- Grid: one row per class, one checkbox per spec ---------------------------
    self.classChecks = {}
    self.specChecks = {}
    for row, class in ipairs(B.CLASSES) do
        local y = GRID_Y - (row - 1) * ROW_H
        local token, className = class.token, class.name
        local c = RAID_CLASS_COLORS and RAID_CLASS_COLORS[token]

        local ccb = MakeCheck(p, GRID_X, y, className, CLASS_COL_W, c and c.r, c and c.g, c and c.b)
        ccb:SetScript("OnClick", function(self)
            local on = self:GetChecked() and true or nil
            for _, s in ipairs(B.SPECS_BY_CLASS[token]) do db.specs[s.key] = on end
            B:UpdateTexts()
        end)
        Tooltip(ccb, className, "Toggle every " .. className .. " spec")
        self.classChecks[token] = ccb

        for col, s in ipairs(B.SPECS_BY_CLASS[token]) do
            local key, specName, role = s.key, s.name, s.role
            local scb = MakeCheck(p, GRID_X + CLASS_COL_W + (col - 1) * SPEC_COL_W, y, s.tag, SPEC_COL_W)
            scb:SetScript("OnClick", function(self)
                db.specs[key] = self:GetChecked() and true or nil
                B:UpdateTexts()
            end)
            Tooltip(scb, specName .. " " .. className, B.ROLE_NAMES[role])
            self.specChecks[key] = scb
        end
    end

    local hint = p:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    hint:SetPoint("BOTTOMLEFT", p, "BOTTOMLEFT", GRID_X, 18)
    hint:SetText("Tick a class to select all of its specs.")
end

-- Sync every checkbox with the saved selection
function B:RefreshSpecPanel()
    if not self.specPanel then return end
    local db = self.db
    for _, class in ipairs(self.CLASSES) do
        local all = true
        for _, s in ipairs(self.SPECS_BY_CLASS[class.token]) do
            local on = db.specs[s.key] and true or false
            self.specChecks[s.key]:SetChecked(on and 1 or nil)
            if not on then all = false end
        end
        self.classChecks[class.token]:SetChecked(all and 1 or nil)
    end
end

function B:ToggleSpecPanel()
    local p, f = self.specPanel, self.frame
    if not p or not f then return end
    if p:IsShown() then
        p:Hide()
        return
    end
    if self.chanPanel then self.chanPanel:Hide() end
    -- open on the right, or on the left if there is no room
    p:ClearAllPoints()
    local right, left, screen = f:GetRight(), f:GetLeft(), UIParent:GetRight()
    if right and left and screen and right + PANEL_W > screen and left - PANEL_W > 0 then
        p:SetPoint("TOPRIGHT", f, "TOPLEFT", 2, -12)
    else
        p:SetPoint("TOPLEFT", f, "TOPRIGHT", -2, -12)
    end
    self:RefreshSpecPanel()
    p:Show()
end
