local lg = love.graphics
local lw = love.window
local push = require("lib/push/push")

lg.setDefaultFilter("nearest", "nearest")

GAME_WIDTH, GAME_HEIGHT = 640, 360
WINDOW_SIDE = math.min(lw.getDesktopDimensions())

push:setupScreen(
  GAME_WIDTH, GAME_HEIGHT,
  WINDOW_SIDE * 0.7, WINDOW_SIDE * 0.4,
  {
    fullscreen = false,
    resizable = true,
    pixelperfect = true
  }
)

function love.load()
end

function love.update(dt)
end

function love.resize(w, h)
  push:resize(w, h)
end

function love.draw()
  local w, h = push:getDimensions()
  push:start()
  lg.setColor(0.2, 0.2, 0.2)
  lg.rectangle("fill", 0, 0, w, h)
  lg.setColor(1, 1, 1)
  lg.print("Hello World", 0, 0)
  push:finish()
end
