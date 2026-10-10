-- Banner: static data (raids, classes, specs)
Banner = Banner or {}
local B = Banner

------------------------------------------------------------------------
-- Raids
------------------------------------------------------------------------
local function BuildVariants(raid)
    local code, hcode = raid.code, raid.hcode
    local v = {}
    v[#v + 1] = { key = code .. "10", short = code .. "10", label = "10-man" }
    v[#v + 1] = { key = code .. "25", short = code .. "25", label = "25-man" }
    if raid.heroic then
        v[#v + 1] = { key = code .. "10H", short = hcode and (hcode .. "10") or (code .. "10H"), label = "10-man Heroic" }
        v[#v + 1] = { key = code .. "25H", short = hcode and (hcode .. "25") or (code .. "25H"), label = "25-man Heroic" }
    end
    return v
end

B.RAIDS = {
    { name = "Icecrown Citadel",       code = "ICC",   heroic = true },
    { name = "Ruby Sanctum",           code = "RS",    heroic = true },
    { name = "Trial of the Crusader",  code = "ToC",   hcode = "ToGC", heroic = true },
    { name = "Ulduar",                 code = "Uld" },
    { name = "Naxxramas",              code = "Naxx" },
    { name = "Eye of Eternity",        code = "EoE" },
    { name = "Obsidian Sanctum",       code = "OS" },
    { name = "Vault of Archavon",      code = "VoA" },
    { name = "Onyxia's Lair",          code = "Ony" },
}
for _, raid in ipairs(B.RAIDS) do
    raid.variants = BuildVariants(raid)
end

------------------------------------------------------------------------
-- Classes and specs
-- role: T = tank, H = healer, M = melee dps, R = ranged dps
------------------------------------------------------------------------
B.CLASSES = {
    { token = "WARRIOR",     name = "Warrior",      short = "Warrior" },
    { token = "PALADIN",     name = "Paladin",      short = "Paladin" },
    { token = "HUNTER",      name = "Hunter",       short = "Hunter" },
    { token = "ROGUE",       name = "Rogue",        short = "Rogue" },
    { token = "PRIEST",      name = "Priest",       short = "Priest" },
    { token = "DEATHKNIGHT", name = "Death Knight", short = "DK" },
    { token = "SHAMAN",      name = "Shaman",       short = "Shaman" },
    { token = "MAGE",        name = "Mage",         short = "Mage" },
    { token = "WARLOCK",     name = "Warlock",      short = "Lock" },
    { token = "DRUID",       name = "Druid",        short = "Druid" },
}

B.ROLES = {
    { id = "T", label = "All Tanks" },
    { id = "H", label = "All Healers" },
    { id = "M", label = "All Melee DPS" },
    { id = "R", label = "All Ranged DPS" },
}
B.ROLE_NAMES = { T = "Tank", H = "Healer", M = "Melee", R = "Ranged" }

-- { class, menu name, message label, role }
local specDefs = {
    { "WARRIOR", "Arms",              "Arms Warr",     "M" },
    { "WARRIOR", "Fury",              "Fury Warr",     "M" },
    { "WARRIOR", "Protection",        "Prot Warr",     "T" },

    { "PALADIN", "Holy",              "Holy Pally",    "H" },
    { "PALADIN", "Protection",        "Prot Pally",    "T" },
    { "PALADIN", "Retribution",       "Ret Pally",     "M" },

    { "HUNTER",  "Beast Mastery",     "BM Hunter",     "R" },
    { "HUNTER",  "Marksmanship",      "MM Hunter",     "R" },
    { "HUNTER",  "Survival",          "Surv Hunter",   "R" },

    { "ROGUE",   "Assassination",     "Assa Rogue",    "M" },
    { "ROGUE",   "Combat",            "Combat Rogue",  "M" },
    { "ROGUE",   "Subtlety",          "Sub Rogue",     "M" },

    { "PRIEST",  "Discipline",        "Disc Priest",   "H" },
    { "PRIEST",  "Holy",              "Holy Priest",   "H" },
    { "PRIEST",  "Shadow",            "Shadow Priest", "R" },

    { "DEATHKNIGHT", "Blood",         "Blood DK",      "T" },
    { "DEATHKNIGHT", "Frost",         "Frost DK",      "M" },
    { "DEATHKNIGHT", "Unholy",        "Unholy DK",     "M" },

    { "SHAMAN",  "Elemental",         "Ele Shaman",    "R" },
    { "SHAMAN",  "Enhancement",       "Enh Shaman",    "M" },
    { "SHAMAN",  "Restoration",       "Resto Shaman",  "H" },

    { "MAGE",    "Arcane",            "Arcane Mage",   "R" },
    { "MAGE",    "Fire",              "Fire Mage",     "R" },
    { "MAGE",    "Frost",             "Frost Mage",    "R" },

    { "WARLOCK", "Affliction",        "Aff Lock",      "R" },
    { "WARLOCK", "Demonology",        "Demo Lock",     "R" },
    { "WARLOCK", "Destruction",       "Destro Lock",   "R" },

    { "DRUID",   "Balance",           "Balance Druid", "R" },
    { "DRUID",   "Feral (Bear)",      "Bear Druid",    "T" },
    { "DRUID",   "Feral (Cat)",       "Cat Druid",     "M" },
    { "DRUID",   "Restoration",       "Resto Druid",   "H" },
}

B.SPECS = {}
B.SPECS_BY_CLASS = {}
for _, d in ipairs(specDefs) do
    local s = { key = d[1] .. ":" .. d[2], class = d[1], name = d[2], label = d[3], role = d[4] }
    B.SPECS[#B.SPECS + 1] = s
    B.SPECS_BY_CLASS[d[1]] = B.SPECS_BY_CLASS[d[1]] or {}
    table.insert(B.SPECS_BY_CLASS[d[1]], s)
end
