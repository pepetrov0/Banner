-- Banner: static data (raids, classes, specs)
Banner = Banner or {}
local B = Banner

------------------------------------------------------------------------
-- Raids
------------------------------------------------------------------------
-- size   = a single fixed raid size (key and short name are just the code, e.g. "SSC")
-- sizes  = list of sizes for raids that come in several (default 10 and 25)
-- heroic = adds 10-/25-man heroic variants
local function BuildVariants(raid)
    local code, hcode = raid.code, raid.hcode
    local v = {}
    if raid.size then
        v[#v + 1] = { key = code, short = code, label = raid.size .. "-man" }
    else
        for _, size in ipairs(raid.sizes or { 10, 25 }) do
            v[#v + 1] = { key = code .. size, short = code .. size, label = size .. "-man" }
        end
        if raid.heroic then
            v[#v + 1] = { key = code .. "10H", short = hcode and (hcode .. "10") or (code .. "10H"), label = "10-man Heroic" }
            v[#v + 1] = { key = code .. "25H", short = hcode and (hcode .. "25") or (code .. "25H"), label = "25-man Heroic" }
        end
    end
    for _, variant in ipairs(v) do
        variant.bosses = raid.bosses
    end
    return v
end

-- exp    = expansion heading shown in the instance menu
-- bosses = number of bosses in the raid
B.RAIDS = {
    -- Wrath of the Lich King
    { exp = "Wrath of the Lich King", name = "Icecrown Citadel",       code = "ICC",   bosses = 12, heroic = true },
    { exp = "Wrath of the Lich King", name = "Ruby Sanctum",           code = "RS",    bosses = 4,  heroic = true },
    { exp = "Wrath of the Lich King", name = "Trial of the Crusader",  code = "ToC",   bosses = 5,  hcode = "ToGC", heroic = true },
    { exp = "Wrath of the Lich King", name = "Ulduar",                 code = "Uld",   bosses = 14 },
    { exp = "Wrath of the Lich King", name = "Naxxramas",              code = "Naxx",  bosses = 15, sizes = { 10, 25, 40 } },
    { exp = "Wrath of the Lich King", name = "Eye of Eternity",        code = "EoE",   bosses = 1 },
    { exp = "Wrath of the Lich King", name = "Obsidian Sanctum",       code = "OS",    bosses = 1 },
    { exp = "Wrath of the Lich King", name = "Vault of Archavon",      code = "VoA",   bosses = 4 },
    { exp = "Wrath of the Lich King", name = "Onyxia's Lair",          code = "Ony",   bosses = 1,  sizes = { 10, 25, 40 } },

    -- The Burning Crusade
    { exp = "The Burning Crusade", name = "Sunwell Plateau",           code = "SWP",   bosses = 6,  size = 25 },
    { exp = "The Burning Crusade", name = "Black Temple",              code = "BT",    bosses = 9,  size = 25 },
    { exp = "The Burning Crusade", name = "Hyjal Summit",              code = "Hyjal", bosses = 5,  size = 25 },
    { exp = "The Burning Crusade", name = "Tempest Keep",              code = "TK",    bosses = 4,  size = 25 },
    { exp = "The Burning Crusade", name = "Serpentshrine Cavern",      code = "SSC",   bosses = 6,  size = 25 },
    { exp = "The Burning Crusade", name = "Magtheridon's Lair",        code = "Mag",   bosses = 1,  size = 25 },
    { exp = "The Burning Crusade", name = "Gruul's Lair",              code = "Gruul", bosses = 2,  size = 25 },
    { exp = "The Burning Crusade", name = "Zul'Aman",                  code = "ZA",    bosses = 6,  size = 10 },
    { exp = "The Burning Crusade", name = "Karazhan",                  code = "Kara",  bosses = 11, size = 10 },

    -- Classic
    { exp = "Classic", name = "Temple of Ahn'Qiraj",                   code = "AQ40",  bosses = 9,  size = 40 },
    { exp = "Classic", name = "Ruins of Ahn'Qiraj",                    code = "AQ20",  bosses = 6,  size = 20 },
    { exp = "Classic", name = "Blackwing Lair",                        code = "BWL",   bosses = 8,  size = 40 },
    { exp = "Classic", name = "Molten Core",                           code = "MC",    bosses = 10, size = 40 },
    { exp = "Classic", name = "Zul'Gurub",                             code = "ZG",    bosses = 10, size = 20 },
}
B.VARIANTS = {}
for _, raid in ipairs(B.RAIDS) do
    raid.variants = BuildVariants(raid)
    for _, variant in ipairs(raid.variants) do
        B.VARIANTS[variant.key] = variant
    end
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
    -- tag = label without the trailing class word, e.g. "Prot Warr" -> "Prot"
    local s = { key = d[1] .. ":" .. d[2], class = d[1], name = d[2], label = d[3], role = d[4],
                tag = d[3]:match("^(.-)%s%S+$") or d[3] }
    B.SPECS[#B.SPECS + 1] = s
    B.SPECS_BY_CLASS[d[1]] = B.SPECS_BY_CLASS[d[1]] or {}
    table.insert(B.SPECS_BY_CLASS[d[1]], s)
end
