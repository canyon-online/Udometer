-- Udometer
-- Made by who is he

require("class_colors")
Udometer = require("meter")
Combat = require("combat")

combat = Combat()
udo = Udometer(combat)

registercallback("onStep", function()
    combat:update()
    udo:update()
end)

registercallback("onPlayerHUDDraw", function(player, x, y)
    udo:draw()
end)

registercallback("onHit", function(damager, hit, x, y)
    combat:onHit(damager, hit, x, y)
end)

registercallback("onGameStart", function()
    combat = Combat()
    udo = Udometer(combat)
end)

print("Udometer v1.5 loaded")
