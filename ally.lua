-- ally.lua
-- Creates an allied player class to be used by Udometer

local Ally, AllyMT = newtype("ally")
AllyMT.__index = {}

function AllyMT:__init(name, color)
    self.name = name or "nil"

    self.combat = {}
    self.combat.inCombat = false
    self.combat.secondsInCombat = 0
    self.combat.secondsOutOfCombat = 0
    self.combat.damage = 0
    self.combat.DPS = 0

    self.display = {}
    self.display.barOffset = 250 -- For animation
    self.display.color = misc.classColor[name] or color or Color.GREY 
end

function AllyMT.__index:update(secondTick)
    -- We really only care to update this once every second
    if secondTick then
        self.combat.secondsOutOfCombat = self.combat.secondsOutOfCombat + 1

        if self.combat.inCombat then
            self.combat.secondsInCombat = self.combat.secondsInCombat + 1
            if self.combat.secondsOutOfCombat > 10 then
                self.combat.inCombat = false
            end
        end

        if self.combat.secondsInCombat ~= 0 then
            self.combat.DPS = self.combat.damage / self.combat.secondsInCombat
        else
            self.combat.DPS = 0
        end
    end
end

return Ally
