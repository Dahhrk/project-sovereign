--[[
    Progression System Module - Phase 2
    Skill trees and perk unlocking system
]]--

-- Skill tree definitions
GM.SkillTrees = GM.SkillTrees or {
    Combat = {},
    Economy = {}
}

-- Initialize player skills
local function InitializePlayerSkills(ply)
    ply.Skills = ply.Skills or {
        Combat = {},
        Economy = {},
        skillPoints = 0
    }
end

-- Define a skill
function GM:DefineSkill(tree, skillID, data)
    if not self.SkillTrees[tree] then
        self.SkillTrees[tree] = {}
    end
    
    self.SkillTrees[tree][skillID] = {
        id = skillID,
        name = data.name or skillID,
        description = data.description or "",
        maxLevel = data.maxLevel or 5,
        cost = data.cost or 1,
        requires = data.requires or nil, -- Required skill and level
        onUnlock = data.onUnlock or nil,
        onLevelUp = data.onLevelUp or nil,
        effects = data.effects or {}
    }
end

-- Register Combat Skills
GM:DefineSkill("Combat", "accuracy", {
    name = "Improved Accuracy",
    description = "Increase weapon accuracy",
    maxLevel = 5,
    cost = 1,
    effects = {
        accuracyBonus = 5 -- +5% per level
    }
})

GM:DefineSkill("Combat", "health_boost", {
    name = "Health Boost",
    description = "Increase maximum health",
    maxLevel = 5,
    cost = 1,
    effects = {
        healthBonus = 20 -- +20 HP per level
    }
})

GM:DefineSkill("Combat", "armor_boost", {
    name = "Armor Enhancement",
    description = "Increase armor effectiveness",
    maxLevel = 5,
    cost = 1,
    effects = {
        armorBonus = 10 -- +10 armor per level
    }
})

GM:DefineSkill("Combat", "weapon_mastery", {
    name = "Weapon Mastery",
    description = "Access to advanced weapons",
    maxLevel = 3,
    cost = 2,
    requires = {skill = "accuracy", level = 3},
    effects = {
        weaponTier = 1 -- Unlocks weapon tier per level
    }
})

GM:DefineSkill("Combat", "tactical_reload", {
    name = "Tactical Reload",
    description = "Faster reload speed",
    maxLevel = 3,
    cost = 1,
    effects = {
        reloadSpeedBonus = 15 -- +15% per level
    }
})

-- Register Economy Skills
GM:DefineSkill("Economy", "merchant", {
    name = "Merchant",
    description = "Better prices when buying/selling",
    maxLevel = 5,
    cost = 1,
    effects = {
        priceDiscount = 5 -- +5% discount per level
    }
})

GM:DefineSkill("Economy", "scavenger", {
    name = "Scavenger",
    description = "Find more resources",
    maxLevel = 5,
    cost = 1,
    effects = {
        resourceBonus = 10 -- +10% per level
    }
})

GM:DefineSkill("Economy", "investor", {
    name = "Investor",
    description = "Earn passive income",
    maxLevel = 3,
    cost = 2,
    effects = {
        passiveIncome = 100 -- +100 credits/hour per level
    }
})

GM:DefineSkill("Economy", "trade_master", {
    name = "Trade Master",
    description = "Reduced transaction taxes",
    maxLevel = 5,
    cost = 1,
    requires = {skill = "merchant", level = 2},
    effects = {
        taxReduction = 10 -- -10% tax per level
    }
})

GM:DefineSkill("Economy", "crafting_expert", {
    name = "Crafting Expert",
    description = "Reduced crafting time and material cost",
    maxLevel = 3,
    cost = 2,
    effects = {
        craftingSpeed = 20, -- +20% faster per level
        materialDiscount = 10 -- -10% materials per level
    }
})

-- Get skill data path
local function GetSkillsDataPath(steamID)
    local sanitized = string.gsub(steamID, ":", "_")
    return string.format("project_sovereign/skills/%s.txt", sanitized)
end

-- Save player skills
function GM:SavePlayerSkills(ply)
    if not SERVER then return false end
    
    if not self:IsValidPlayer(ply) then
        return false
    end
    
    InitializePlayerSkills(ply)
    
    local steamID = ply:SteamID()
    local json = util.TableToJSON(ply.Skills, true)
    
    if not json then
        self:ErrorLog("Failed to serialize skills for " .. ply:Nick())
        return false
    end
    
    file.CreateDir("project_sovereign")
    file.CreateDir("project_sovereign/skills")
    
    local filePath = GetSkillsDataPath(steamID)
    file.Write(filePath, json)
    
    self:DebugLog(string.format("Saved skills for %s", ply:Nick()))
    return true
end

-- Load player skills
function GM:LoadPlayerSkills(ply)
    if not SERVER then return false end
    
    if not self:IsValidPlayer(ply) then
        return false
    end
    
    local steamID = ply:SteamID()
    local filePath = GetSkillsDataPath(steamID)
    
    if not file.Exists(filePath, "DATA") then
        InitializePlayerSkills(ply)
        self:SavePlayerSkills(ply)
        return true
    end
    
    local json = file.Read(filePath, "DATA")
    if not json then
        self:ErrorLog("Failed to read skills for " .. ply:Nick())
        InitializePlayerSkills(ply)
        return false
    end
    
    local data = util.JSONToTable(json)
    if not data then
        self:ErrorLog("Failed to parse skills for " .. ply:Nick())
        InitializePlayerSkills(ply)
        return false
    end
    
    ply.Skills = data
    
    self:DebugLog(string.format("Loaded skills for %s", ply:Nick()))
    return true
end

-- Get player skill level
function GM:GetSkillLevel(ply, tree, skillID)
    if not self:IsValidPlayer(ply) then return 0 end
    
    InitializePlayerSkills(ply)
    
    if not ply.Skills[tree] then return 0 end
    
    return ply.Skills[tree][skillID] or 0
end

-- Check if player can unlock skill
function GM:CanUnlockSkill(ply, tree, skillID)
    if not self:IsValidPlayer(ply) then
        return false, "Invalid player"
    end
    
    local skill = self.SkillTrees[tree] and self.SkillTrees[tree][skillID]
    if not skill then
        return false, "Invalid skill"
    end
    
    InitializePlayerSkills(ply)
    
    local currentLevel = self:GetSkillLevel(ply, tree, skillID)
    
    if currentLevel >= skill.maxLevel then
        return false, "Skill already at max level"
    end
    
    -- Check skill points
    if ply.Skills.skillPoints < skill.cost then
        return false, string.format("Not enough skill points (need %d, have %d)",
            skill.cost, ply.Skills.skillPoints)
    end
    
    -- Check requirements
    if skill.requires then
        local reqLevel = self:GetSkillLevel(ply, tree, skill.requires.skill)
        if reqLevel < skill.requires.level then
            return false, string.format("Requires %s level %d",
                skill.requires.skill, skill.requires.level)
        end
    end
    
    return true
end

-- Unlock/level up skill
function GM:UnlockSkill(ply, tree, skillID)
    if not SERVER then return false end
    
    if not self:IsValidPlayer(ply) then
        return false, "Invalid player"
    end
    
    local skill = self.SkillTrees[tree] and self.SkillTrees[tree][skillID]
    if not skill then
        return false, "Invalid skill"
    end
    
    local canUnlock, reason = self:CanUnlockSkill(ply, tree, skillID)
    if not canUnlock then
        return false, reason
    end
    
    InitializePlayerSkills(ply)
    
    -- Deduct skill points
    ply.Skills.skillPoints = ply.Skills.skillPoints - skill.cost
    
    -- Increase skill level
    if not ply.Skills[tree] then
        ply.Skills[tree] = {}
    end
    
    local oldLevel = ply.Skills[tree][skillID] or 0
    ply.Skills[tree][skillID] = oldLevel + 1
    
    self:SavePlayerSkills(ply)
    
    -- Call callback if exists
    if skill.onLevelUp then
        skill.onLevelUp(ply, ply.Skills[tree][skillID])
    elseif oldLevel == 0 and skill.onUnlock then
        skill.onUnlock(ply)
    end
    
    self:Log(string.format("%s unlocked %s level %d in %s tree",
        ply:Nick(), skill.name, ply.Skills[tree][skillID], tree))
    
    return true, ply.Skills[tree][skillID]
end

-- Award skill points
function GM:AwardSkillPoints(ply, points)
    if not SERVER then return false end
    
    if not self:IsValidPlayer(ply) then return false end
    
    InitializePlayerSkills(ply)
    
    ply.Skills.skillPoints = ply.Skills.skillPoints + points
    self:SavePlayerSkills(ply)
    
    self:Notify(ply, string.format("Earned %d skill point%s! (Total: %d)",
        points, points > 1 and "s" or "", ply.Skills.skillPoints), NOTIFY_GENERIC)
    
    return true
end

-- Get player skill points
function GM:GetSkillPoints(ply)
    if not self:IsValidPlayer(ply) then return 0 end
    
    InitializePlayerSkills(ply)
    
    return ply.Skills.skillPoints or 0
end

-- Commands

-- View skill trees
GM:RegisterCommand("skills", function(ply, args)
    local tree = args[1] or "Combat"
    
    if not GAMEMODE.SkillTrees[tree] then
        GAMEMODE:Notify(ply, "Invalid skill tree. Available: Combat, Economy", NOTIFY_ERROR)
        return
    end
    
    local skills = GAMEMODE.SkillTrees[tree]
    local skillPoints = GAMEMODE:GetSkillPoints(ply)
    
    ply:ChatPrint(string.format("=== %s SKILL TREE ===", tree))
    ply:ChatPrint(string.format("Skill Points Available: %d", skillPoints))
    ply:ChatPrint("")
    
    for skillID, skill in pairs(skills) do
        local currentLevel = GAMEMODE:GetSkillLevel(ply, tree, skillID)
        local status = currentLevel > 0 and string.format("[%d/%d]", currentLevel, skill.maxLevel) or "[ ]"
        
        ply:ChatPrint(string.format("%s %s (%s)", status, skill.name, skillID))
        ply:ChatPrint("  " .. skill.description)
        ply:ChatPrint(string.format("  Cost: %d skill point%s | Max Level: %d",
            skill.cost, skill.cost > 1 and "s" or "", skill.maxLevel))
        
        if skill.requires then
            local reqLevel = GAMEMODE:GetSkillLevel(ply, tree, skill.requires.skill)
            local reqMet = reqLevel >= skill.requires.level
            ply:ChatPrint(string.format("  Requires: %s level %d %s",
                skill.requires.skill, skill.requires.level,
                reqMet and "✓" or "✗"))
        end
        
        ply:ChatPrint("")
    end
    
    ply:ChatPrint("Use /unlockskill <tree> <skillID> to unlock a skill")
    ply:ChatPrint("====================")
end, false, "View skill trees (Combat, Economy)")

-- Unlock skill
GM:RegisterCommand("unlockskill", function(ply, args)
    if #args < 2 then
        GAMEMODE:Notify(ply, "Usage: /unlockskill <tree> <skillID>", NOTIFY_ERROR)
        GAMEMODE:Notify(ply, "Example: /unlockskill Combat accuracy", NOTIFY_HINT)
        return
    end
    
    local tree = args[1]
    local skillID = args[2]
    
    local success, result = GAMEMODE:UnlockSkill(ply, tree, skillID)
    
    if success then
        local skill = GAMEMODE.SkillTrees[tree][skillID]
        GAMEMODE:Notify(ply, string.format("Unlocked %s level %d!", skill.name, result), NOTIFY_GENERIC)
    else
        GAMEMODE:Notify(ply, "Error: " .. result, NOTIFY_ERROR)
    end
end, false, "Unlock or level up a skill")

-- Admin: Award skill points
GM:RegisterCommand("giveskillpoints", function(ply, args)
    if #args < 2 then
        GAMEMODE:Notify(ply, "Usage: /giveskillpoints <player> <points>", NOTIFY_ERROR)
        return
    end
    
    local target = GAMEMODE:FindPlayer(args[1])
    if not target then
        GAMEMODE:Notify(ply, "Player not found: " .. args[1], NOTIFY_ERROR)
        return
    end
    
    local points = tonumber(args[2])
    if not points or points < 1 then
        GAMEMODE:Notify(ply, "Invalid points amount", NOTIFY_ERROR)
        return
    end
    
    GAMEMODE:AwardSkillPoints(target, points)
    
    GAMEMODE:Notify(ply, string.format("Gave %d skill points to %s", points, target:Nick()), NOTIFY_GENERIC)
    GAMEMODE:Log(string.format("%s gave %d skill points to %s", ply:Nick(), points, target:Nick()))
end, true, "Give skill points to a player (admin only)")

-- Reset skills
GM:RegisterCommand("resetskills", function(ply, args)
    InitializePlayerSkills(ply)
    
    -- Calculate total points to refund
    local refundPoints = 0
    
    for tree, skills in pairs(ply.Skills) do
        if tree ~= "skillPoints" then
            for skillID, level in pairs(skills) do
                local skillData = GAMEMODE.SkillTrees[tree] and GAMEMODE.SkillTrees[tree][skillID]
                if skillData then
                    refundPoints = refundPoints + (skillData.cost * level)
                end
            end
        end
    end
    
    -- Reset all skills
    ply.Skills = {
        Combat = {},
        Economy = {},
        skillPoints = ply.Skills.skillPoints + refundPoints
    }
    
    GAMEMODE:SavePlayerSkills(ply)
    
    GAMEMODE:Notify(ply, string.format("Skills reset! Refunded %d skill points", refundPoints), NOTIFY_GENERIC)
    GAMEMODE:Log(string.format("%s reset their skills (refunded %d points)", ply:Nick(), refundPoints))
end, false, "Reset all your skills and refund skill points")

-- Load skills on player spawn
if SERVER then
    hook.Add("PlayerInitialSpawn", "ProjectSovereign_LoadSkills", function(ply)
        GAMEMODE:LoadPlayerSkills(ply)
    end)
    
    -- Save skills on disconnect
    hook.Add("PlayerDisconnected", "ProjectSovereign_SaveSkills", function(ply)
        GAMEMODE:SavePlayerSkills(ply)
    end)
    
    -- Save all skills periodically
    timer.Create("ProjectSovereign_SkillsAutoSave", 300, 0, function()
        for _, ply in ipairs(player.GetAll()) do
            GAMEMODE:SavePlayerSkills(ply)
        end
    end)
    
    -- Print loaded skills
    hook.Add("Initialize", "ProjectSovereign_SkillsInit", function()
        local combatSkills = table.Count(GAMEMODE.SkillTrees.Combat)
        local economySkills = table.Count(GAMEMODE.SkillTrees.Economy)
        GAMEMODE:Log(string.format("Loaded %d Combat skills and %d Economy skills",
            combatSkills, economySkills))
    end)
end
