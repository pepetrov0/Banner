-- Banner: core logic
Banner = Banner or {}
local B = Banner

local TAG = "|cff33ff99Banner|r"
local ADDON_VERSION = GetAddOnMetadata("Banner", "Version") or "?"
local function Log(msg) DEFAULT_CHAT_FRAME:AddMessage(TAG .. " " .. msg) end
local function LogLoad(hint) Log("v" .. ADDON_VERSION .. " loaded." .. (hint and (" " .. hint) or "")) end
local MAX_LEN     = 250   -- chat limit is 255 bytes; keep a little headroom
local QUEUE_DELAY = 1.5   -- seconds between individual messages (avoids server throttling)
local MIN_INTERVAL = 10

B.running   = false
B.nextSend  = 0
B.nextQueue = 0
B.queue     = {}

-- Non-channel chat types that can also be broadcast to
B.CHAT_TYPES = {
    { type = "SAY",  name = "Say",  menu = "Say (nearby players)" },
    { type = "YELL", name = "Yell", menu = "Yell (wide area)" },
}

local DEFAULTS = {
    instances   = {},     -- [variantKey] = true (at most one entry)
    instanceText = "",    -- free text appended after the instance name, e.g. "ICC25 {text}"
    specs       = {},     -- [specKey]    = true
    channels    = {},     -- [lowercased channel base name] = display name
    chat        = {},     -- [chat type] = true, for SAY / YELL
    skin        = true,   -- apply the ElvUI skin when ElvUI is loaded
    minGS       = 0,
    stopAt      = 0,      -- stop broadcasting when group reaches this size (0 = off)
    reserves    = "",
    note        = "",
    interval    = 60,
}

local function CopyDefaults(src, dst)
    for k, v in pairs(src) do
        if type(v) == "table" then
            if type(dst[k]) ~= "table" then dst[k] = {} end
            CopyDefaults(v, dst[k])
        elseif dst[k] == nil then
            dst[k] = v
        end
    end
end

function B:Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage(TAG .. " " .. msg)
end

------------------------------------------------------------------------
-- Selection helpers
------------------------------------------------------------------------
function B:GetSelectedInstances()
    local out = {}
    for _, raid in ipairs(self.RAIDS) do
        for _, v in ipairs(raid.variants) do
            if self.db.instances[v.key] then
                out[#out + 1] = v.short
            end
        end
    end
    return out
end

-- Free text appended after the instance name (sanitised for chat), or nil
function B:GetInstanceText()
    local raw = strtrim((tostring(self.db.instanceText or ""):gsub("|", "")))
    if raw == "" then return nil end
    return raw
end

-- Returns a list of labels. Collapses a fully selected class to "Any <Class>",
-- and everything selected to a single "All classes/specs".
function B:GetSelectedSpecLabels()
    local out = {}
    local fullClasses = 0
    for _, class in ipairs(self.CLASSES) do
        local specs = self.SPECS_BY_CLASS[class.token]
        local selected = {}
        for _, s in ipairs(specs) do
            if self.db.specs[s.key] then selected[#selected + 1] = s end
        end
        if #selected == #specs then
            fullClasses = fullClasses + 1
            out[#out + 1] = "Any " .. class.short
        else
            for _, s in ipairs(selected) do out[#out + 1] = s.label end
        end
    end
    if fullClasses == #self.CLASSES then
        return { "All classes/specs" }
    end
    return out
end

-- Only one instance may be selected; keep the first one if older saved
-- settings contain several.
function B:NormalizeInstances()
    local keep
    for _, raid in ipairs(self.RAIDS) do
        for _, v in ipairs(raid.variants) do
            if self.db.instances[v.key] and not keep then keep = v.key end
        end
    end
    wipe(self.db.instances)
    if keep then self.db.instances[keep] = true end
end

function B:CountSelectedSpecs()
    local n = 0
    for _, s in ipairs(self.SPECS) do
        if self.db.specs[s.key] then n = n + 1 end
    end
    return n
end

------------------------------------------------------------------------
-- Reservations: plain text, split at commas so a long list can wrap onto the next line
local function ParseReserves(raw)
    raw = tostring(raw or "")
    raw = raw:gsub("|c%x%x%x%x%x%x%x%x|H.-|h(%[.-%])|h|r", "%1") -- pasted link -> just its [Name]
    raw = raw:gsub("|", "")                                       -- stray pipes would break chat
    local atoms = {}
    for part in raw:gmatch("[^,]+") do
        local text = strtrim(part)
        if text ~= "" then atoms[#atoms + 1] = text end
    end
    return atoms
end
B.ParseReserves = ParseReserves

------------------------------------------------------------------------
-- Message building
------------------------------------------------------------------------
function B:BuildMessage()
    local db = self.db
    local atoms = {}

    -- A "section" is a labelled list: first atom starts with " - ", the rest with ", "
    local function section(label, list)
        for i, text in ipairs(list) do
            if i == 1 then
                atoms[#atoms + 1] = { sep = " - ", text = label .. text }
            else
                atoms[#atoms + 1] = { sep = ", ", text = text }
            end
        end
    end

    local inst = self:GetSelectedInstances()
    if #inst == 0 then inst = { "raid" } end
    local text = self:GetInstanceText()
    if text then inst[1] = inst[1] .. " " .. text end   -- "ICC25 {text}"
    section("LFM ", inst)

    local specs = self:GetSelectedSpecLabels()
    if #specs > 0 then section("Need: ", specs) end

    local gs = tonumber(db.minGS) or 0
    if gs > 0 then section("", { "GS " .. gs .. "+" }) end

    local res = ParseReserves(db.reserves)
    if #res > 0 then section("Reserves: ", res) end

    local note = strtrim((tostring(db.note or ""):gsub("|", "")))
    if note ~= "" then section("", { note }) end

    -- Pack atoms into lines of at most MAX_LEN bytes without splitting any atom
    local lines, line = {}, ""
    for _, a in ipairs(atoms) do
        local text = a.text
        if #text > MAX_LEN then text = text:sub(1, MAX_LEN) end
        if line == "" then
            line = text
        elseif #line + #a.sep + #text <= MAX_LEN then
            line = line .. a.sep .. text
        else
            lines[#lines + 1] = line
            line = text
        end
    end
    if line ~= "" then lines[#lines + 1] = line end
    return lines
end

------------------------------------------------------------------------
-- Channels
------------------------------------------------------------------------
-- Returns { {id=, name=, base=}, ... } for every channel the player has joined.
function B:GetJoinedChannels()
    local out = {}
    local list = { GetChannelList() }
    local i = 1
    while list[i] ~= nil do
        local id, name = list[i], list[i + 1]
        i = i + 2
        if type(list[i]) == "boolean" then i = i + 1 end -- newer clients add a "disabled" flag
        if type(id) == "number" and type(name) == "string" then
            -- "General - Dalaran" -> "General"; "LookingForGroup" stays as is
            local base = name:match("^(.-)%s%-%s") or name
            out[#out + 1] = { id = id, name = name, base = base }
        end
    end
    return out
end

function B:GetTargets()
    local targets = {}
    for _, ch in ipairs(self:GetJoinedChannels()) do
        if self.db.channels[ch.base:lower()] then
            targets[#targets + 1] = ch
        end
    end
    for _, c in ipairs(self.CHAT_TYPES) do
        if self.db.chat[c.type] then
            targets[#targets + 1] = { type = c.type, name = c.name }
        end
    end
    return targets
end

------------------------------------------------------------------------
-- Group size / broadcasting
------------------------------------------------------------------------
function B:GroupSize()
    local raid = GetNumRaidMembers()
    if raid and raid > 0 then return raid end
    local party = GetNumPartyMembers()
    if party and party > 0 then return party + 1 end
    return 1
end

function B:IsFull()
    local stopAt = tonumber(self.db.stopAt) or 0
    return stopAt > 0 and self:GroupSize() >= stopAt
end

-- manual = true: send one round now without touching the schedule
function B:Broadcast(manual)
    local now = GetTime()

    if not manual then
        self.nextSend = now + math.max(MIN_INTERVAL, tonumber(self.db.interval) or 60)
        if #self.queue > 0 then return end -- previous round still sending
        if self:IsFull() then
            self:Print("Group is full - broadcasting stopped.")
            self:Stop()
            return
        end
    end

    local targets = self:GetTargets()
    if #targets == 0 then
        self:Print("None of your selected channels are available (try /join LookingForGroup).")
        if not manual then self:Stop() end
        return
    end

    local lines = self:BuildMessage()
    for _, ch in ipairs(targets) do
        for _, text in ipairs(lines) do
            self.queue[#self.queue + 1] = { channel = ch.name, type = ch.type, text = text }
        end
    end
end

function B:Start()
    if self.running then return end
    if not next(self.db.channels) and not next(self.db.chat) then
        self:Print("Pick at least one channel first (/banner).")
        return
    end
    self.running  = true
    self.nextSend = GetTime()
    self:Print(format("Broadcasting every %d seconds. Use /banner stop to stop.", self.db.interval))
    self:RefreshAll()
end

function B:Stop()
    if not self.running then return end
    self.running = false
    wipe(self.queue)
    self:Print("Broadcasting stopped.")
    self:RefreshAll()
end

function B:RefreshAll()
    if self.RefreshUI then self:RefreshUI() end
end

------------------------------------------------------------------------
-- Driver: schedules broadcasts and drains the send queue
------------------------------------------------------------------------
local driver = CreateFrame("Frame")
driver:RegisterEvent("ADDON_LOADED")
driver:RegisterEvent("RAID_ROSTER_UPDATE")
driver:RegisterEvent("PARTY_MEMBERS_CHANGED")

driver:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "Banner" then
        BannerDB = BannerDB or {}
        CopyDefaults(DEFAULTS, BannerDB)
        B.db = BannerDB
        B:NormalizeInstances()
        LogLoad("Type /banner to configure.")
    elseif event == "RAID_ROSTER_UPDATE" or event == "PARTY_MEMBERS_CHANGED" then
        if B.running and B:IsFull() then
            B:Print("Group is full - broadcasting stopped.")
            B:Stop()
        end
    end
end)

driver:SetScript("OnUpdate", function(self, elapsed)
    if not B.db then return end
    local now = GetTime()

    if B.running and now >= B.nextSend then
        B:Broadcast()
    end

    if #B.queue > 0 and now >= B.nextQueue then
        local item = table.remove(B.queue, 1)
        if item.type then
            SendChatMessage(item.text, item.type)
        else
            local id = GetChannelName(item.channel)
            if id and id > 0 then
                SendChatMessage(item.text, "CHANNEL", nil, id)
            end
        end
        B.nextQueue = now + QUEUE_DELAY
    end

    self.acc = (self.acc or 0) + elapsed
    if self.acc >= 0.5 then
        self.acc = 0
        if B.UpdateStatus then B:UpdateStatus() end
    end
end)

------------------------------------------------------------------------
-- Slash commands
------------------------------------------------------------------------
SLASH_BANNER1 = "/banner"
SlashCmdList["BANNER"] = function(msg)
    if not B.db then return end
    msg = strlower(strtrim(msg or ""))
    if msg == "" or msg == "show" or msg == "config" then
        B:ToggleUI()
    elseif msg == "start" then
        B:Start()
    elseif msg == "stop" then
        B:Stop()
    elseif msg == "toggle" then
        if B.running then B:Stop() else B:Start() end
    elseif msg == "now" then
        B:Broadcast(true)
    elseif msg == "skin" then
        B.db.skin = not B.db.skin
        B:Print("ElvUI skin " .. (B.db.skin and "enabled" or "disabled") .. ". Type /reload to apply.")
    elseif msg == "preview" then
        for _, line in ipairs(B:BuildMessage()) do B:Print(line) end
    else
        B:Print("Commands: /banner (window), start, stop, toggle, now (send once), preview, skin")
    end
end
