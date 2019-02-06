-- meter.lua
-- Creates a display for combat.lua

local Udometer, UdometerMT = newtype("Udometer")
UdometerMT.__index = {}

function UdometerMT:__init(combat)
    self.settings = {
        draggable = true,
        position = {x = 20, y = 500},
        oldPosition = {x = 20, y = 500},
        size = {x = 250, y = 20},
        displayBarsDefault = 4,
        displayBars = 4
    }

    self.stats = {
        totalAllyDamage = 0,
        totalAllyDPS = 0,
        allyCount = 0,
        combatTime = 0
    }

    self.mouse = {
        clickedMouse = {x = 0, y = 0},
        position = {x = 0, y = 0},
        dragging = false
    }

    self.combat = combat
end

function UdometerMT.__index:draw()
    -- Header --
    do
        -- Bar
        graphics.color(Color.fromHex(0x737495))
        graphics.rectangle(
            self.settings.position.x - 1, self.settings.position.y, 
            self.settings.position.x + self.settings.size.x + 1, self.settings.position.y + 10
        )

        -- Top Text
        graphics.color(Color.WHITE)
        graphics.print("Damage Dealt",
            self.settings.position.x + 3, self.settings.position.y + 1
        )
    end

    -- Body --
    do
        -- Background
        graphics.alpha(0.4)
        graphics.color(Color.BLACK)
        graphics.rectangle(
            self.settings.position.x, 
            self.settings.position.y + 10, 

            self.settings.position.x + self.settings.size.x, 
            self.settings.position.y + self.settings.size.y - 10
        )

        -- Bars
        graphics.alpha(1)
        for i, v in ipairs(self.combat.teams.allies) do
            -- Ugly way of calculating combat time (take highest)
            if v.combat.secondsInCombat > self.stats.combatTime then
                self.stats.combatTime = v.combat.secondsInCombat
            end

            -- Bar Animation
            if self.stats.totalAllyDamage ~= 0 then
                v.display.barOffset = math.approach(
                    v.display.barOffset,
                    self.settings.size.x * (v.combat.damage / self.stats.totalAllyDamage)
                )
            end

            -- % Of Total Damage Bar
            graphics.color(v.display.color)
            graphics.rectangle(
                self.settings.position.x, self.settings.position.y + (i - 1) * 10 + 10 + 1, 
                self.settings.position.x + v.display.barOffset, self.settings.position.y + (i - 1) * 10 + 19
            )

            -- Name
            graphics.color(Color.WHITE)
            graphics.print(
                string.format(
                    "%s", 
                    v.name
                ),
                self.settings.position.x + 3, self.settings.position.y + (i - 1) * 10 + 11
            )

            -- Damage Done (DPS, % Of Total Damage)
            graphics.print(
                string.format(
                    "%s (%s, %.1f%%)", 
                    shortNumber(v.combat.damage), formatNumber(v.combat.DPS), v.combat.damage / self.stats.totalAllyDamage * 100
                ),
                self.settings.position.x + self.settings.size.x - 2, self.settings.position.y + (i - 1) * 10 + 11,
                graphics.FONT_DEFAULT, graphics.ALIGN_RIGHT, graphics.ALIGN_TOP
            )
        end
    end

    -- Footer --
    do
        -- Bar
        graphics.alpha(0.4)
        graphics.color(Color.BLACK)
        graphics.rectangle(
            self.settings.position.x, self.settings.position.y + (self.settings.size.y - 9), 
            self.settings.position.x + self.settings.size.x, self.settings.position.y + self.settings.size.y
        )

        -- Bottom Text
        graphics.alpha(1)
        graphics.color(Color.WHITE)

        -- Total Damage
        graphics.print(
            string.format("Total Damage: %s", shortNumber(self.stats.totalAllyDamage)),
            self.settings.position.x + 2, self.settings.position.y + (self.settings.size.y - 10) + 2,
            graphics.FONT_SMALL, graphics.ALIGN_LEFT, graphics.ALIGN_TOP
        )

        -- Time In Combat
        graphics.print(
            string.format("%s", secondsToClock(self.stats.combatTime)),
            self.settings.position.x + self.settings.size.x / 2, self.settings.position.y + (self.settings.size.y - 10) + 2,
            graphics.FONT_SMALL, graphics.ALIGN_MIDDLE, graphics.ALIGN_TOP
        )

        -- DPS
        graphics.print(
            string.format("DPS: %s", formatNumber(self.stats.totalAllyDPS)),
            self.settings.position.x + self.settings.size.x - 2, self.settings.position.y + (self.settings.size.y - 10) + 2,
            graphics.FONT_SMALL, graphics.ALIGN_RIGHT, graphics.ALIGN_TOP
        )
    end
end

function UdometerMT.__index:update()
    -- Set some stats to be updated
    local boundries = {
        start = {
            x = self.settings.position.x,
            y = self.settings.position.y
        },
        ending = {
            x = self.settings.position.x + self.settings.size.x,
            y = self.settings.position.y + self.settings.size.y
        }
    }

    self.mouse.position.x, self.mouse.position.y = input.getMousePos(true)
    self.stats.totalAllyDamage = 0
    self.stats.totalAllyDPS = 0
    self.stats.allyCount = 0

    -- Count the number of ally players and update total damage and DPS
    for i, player in ipairs(self.combat.teams.allies) do
        self.stats.allyCount = self.stats.allyCount + 1
        self.stats.totalAllyDamage = self.stats.totalAllyDamage + player.combat.damage
        self.stats.totalAllyDPS = self.stats.totalAllyDPS + player.combat.DPS
    end

    -- If we have more allies than our buffer width, change the size of the window
    if self.stats.allyCount >= self.settings.displayBarsDefault then
        self.settings.displayBars = self.stats.allyCount
    end

    self.settings.size.y = 20 + self.settings.displayBars * 10

    -- Check to see if the window is being dragged
    self:drag(boundries)
end

function UdometerMT.__index:drag(boundries)
    -- If draggable, mouse pressed, and bounded
    if isDragging(self, boundries) then
        -- Toggle dragging and set old mouse and window position for calculation
        self.mouse.dragging = true
        self.mouse.clickedMouse.x = self.mouse.position.x
        self.mouse.clickedMouse.y = self.mouse.position.y
        self.settings.oldPosition.x = self.settings.position.x
        self.settings.oldPosition.y = self.settings.position.y
    -- If dragging and mouse held down
    elseif self.mouse.dragging and input.checkMouse("left") == input.HELD then
        -- Update window position
        self.settings.position.x = (
            self.mouse.position.x - (self.mouse.clickedMouse.x - self.settings.oldPosition.x)
        ) 
        self.settings.position.y = (
            self.mouse.position.y - (self.mouse.clickedMouse.y - self.settings.oldPosition.y)
        )
    -- Mostly if the mouse isn't pressed or held, toggle dragging
    else
        self.mouse.dragging = false
    end
end

function isDragging(self, boundries)
    return (
        self.settings.draggable 
        and input.checkMouse("left") == input.PRESSED 
        and isBounded(self.mouse.position, boundries)
    )
end

function isBounded(coordinates, boundries)
    if coordinates.x >= boundries.start.x and coordinates.x <= boundries.ending.x then
        if coordinates.y >= boundries.start.y and coordinates.y <= boundries.ending.y then
            return true
        end
    end

    return false
end

function secondsToClock(s)
    local minutes = math.floor(s / 60)
    local seconds = s % 60

    return string.format("%dm %ds", minutes, seconds)
end

function shortNumber(n)
    if n >= 10^6 then
        return string.format("%.1fm", n / 10^6)
    elseif n >= 10^3 then
        return string.format("%.1fk", n / 10^3)
    else
        return string.format("%.1f", n)
    end
end

function formatNumber(amount)
    local formatted = math.floor(amount)
    while true do  
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
        if (k == 0) then
            break
        end
    end
    return formatted
end

return Udometer
