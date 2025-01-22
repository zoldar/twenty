local lg = love.graphics
local push = require("lib/push/push")

Game = {}

local font

function Game.load()
  font = lg.newFont(26)
end

function Game.draw()
  local w, h = push:getDimensions()
  lg.setColor(1, 1, 1)
  lg.print("PONG", font, (w - font:getWidth("PONG")) / 2, (h - font:getHeight()) / 2)
end

return Game
