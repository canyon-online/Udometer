-- combat.lua
-- Store and access onHit damage done by players and eventually enemies -- :p

Ally = require("ally")

local Combat, CombatMT = newtype("Combat")
CombatMT.__index = {}

function CombatMT:__init()
    self.teams = {allies = {}, enemies = {}}
    self.time = {globalTime = 0, futureTime = 1}

    self.outOfCombatWindow = 10
end

function CombatMT.__index:addTeamMember(team, name)
    if team == "player" or team == "allies" then
        local newAlly = Ally(name)
        table.insert(self.teams.allies, newAlly)
        return newAlly
    end
end

function CombatMT.__index:getTeamMember(team, name)
    if team == "player" or team == "allies" then
        for i, v in ipairs(self.teams.allies) do
            if v.name == name then
                return i, v
            end
        end
    end

    return nil, nil
end

function CombatMT.__index:sortTeamByValue(team, value)
    if team == "player" or team == "allies" then
        table.sort(self.teams.allies, function(a, b)
            return a.combat[value] > b.combat[value]
        end)
    end
end

function CombatMT.__index:addDamage(team, name, value)
    local index, actor = self:getTeamMember(team, name)

    if actor == nil and (team == "player" or team == "allies") then
        actor = self:addTeamMember(team, name)
        actor.combat.inCombat = true
    end

    if team == "player" or team == "allies" then
        actor.combat.damage = actor.combat.damage + value
        actor.combat.inCombat = true
        actor.combat.secondsOutOfCombat = 0
    end
end

function CombatMT.__index:onHit(damager, hit, x, y)
    if checkOnHitValidity(damager, hit) then
        local hitAccessor, damagerAccessor = hit:getAccessor(), damager:getAccessor()
        local damagerParentAccessor = damager:getParent():getAccessor()
        local damageDone = damagerAccessor.damage_fake

        if damagerAccessor.team == "player" and damageDone > 0 then 
            self:addDamage("allies", damagerParentAccessor.name, damageDone)
        end
    end
end

function CombatMT.__index:update()
    local secondTick = false

    if misc.director:isValid() then
        self.time.globalTime = misc.director:get("time_start")
    end

    -- god forbid futureTime ever fall behind globalTIme...
    if self.time.futureTime <= self.time.globalTime then
        secondTick = true
        self.time.futureTime = self.time.futureTime + 1
    end

    for i, v in ipairs(self.teams.allies) do
        v:update(secondTick)
    end

    self:sortTeamByValue("allies", "damage")
end

-- Just to ease the eyes
function checkOnHitValidity(d, h)
    return d:isValid() and h:isValid() and d:getParent() and d:getParent():isValid()
end

return Combat
