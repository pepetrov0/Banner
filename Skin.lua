-- Banner: optional ElvUI skin. Does nothing if ElvUI is not loaded.
-- Disable with /banner skin (then /reload).
Banner = Banner or {}
local B = Banner

function B:SkinUI()
    if self.skinned or not self.frame then return end
    if self.db.skin == false then return end

    local E = ElvUI and ElvUI[1]
    if not E or type(E.GetModule) ~= "function" then return end
    local S = E:GetModule("Skins", true)
    if not S then return end

    -- Every call is guarded: ElvUI builds differ slightly and a missing
    -- helper must never break the Banner window.
    local function Skin(name, ...)
        local fn = S[name]
        if type(fn) == "function" then pcall(fn, S, ...) end
    end
    local function Template(frame, kind)
        if frame and type(frame.SetTemplate) == "function" then
            pcall(frame.SetTemplate, frame, kind or "Transparent")
        end
    end

    local f = self.frame
    Template(f, "Transparent")

    if self.hdr then self.hdr:Hide() end
    if self.title then
        self.title:ClearAllPoints()
        self.title:SetPoint("TOP", f, "TOP", 0, -10)
    end

    if self.closeBtn then Skin("HandleCloseButton", self.closeBtn) end

    for _, btn in ipairs({ self.startBtn, self.onceBtn, self.specBtn }) do
        Skin("HandleButton", btn)
    end
    for _, box in ipairs({ self.gsBox, self.stopBox, self.resBox, self.noteBox }) do
        Skin("HandleEditBox", box)
    end
    for _, dd in ipairs({ self.ddInst, self.ddProg, self.ddChan }) do
        Skin("HandleDropDownBox", dd, 250)
    end
    Skin("HandleSliderFrame", self.slider)
    Template(self.previewFrame, "Transparent")

    local panel = self.specPanel
    if panel then
        Template(panel, "Transparent")
        if self.specPanelClose then Skin("HandleCloseButton", self.specPanelClose) end
        for _, btn in ipairs(self.specPanelButtons or {}) do Skin("HandleButton", btn) end
        for _, cb in pairs(self.classChecks or {}) do Skin("HandleCheckBox", cb) end
        for _, cb in pairs(self.specChecks or {}) do Skin("HandleCheckBox", cb) end
    end

    self.skinned = true
end
