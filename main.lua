local lg = love.graphics
local lw = love.window
local b = require("lib/batteries")
local f = b.functional
local push = require("lib/push/push")
local Index = require("index")

lg.setDefaultFilter("nearest", "nearest")

GAME_WIDTH, GAME_HEIGHT = 640, 360
WINDOW_WIDTH, WINDOW_HEIGHT = lw.getDesktopDimensions()

push:setupScreen(
  GAME_WIDTH, GAME_HEIGHT,
  WINDOW_WIDTH * 0.7, WINDOW_HEIGHT * 0.7,
  {
    fullscreen = false,
    resizable = true,
    pixelperfect = true
  }
)

local state

function love.load()
  state = {
    currentView = Index,
    bus = b.pubsub()
  }

  state.bus:subscribe("open", function(view)
    local oldView = state.currentView
    state.currentView = view
    state.currentView.load()

    if oldView.unload then
      oldView.unload()
    end
  end)

  state.currentView.load(state.bus)
end

function love.update(dt)
  if state.currentView.update then
    state.currentView.update(dt)
  end
end

function love.keypressed(key)
  if key == 'q' or key == 'escape' then
    state.bus:publish("open", Index)
    return
  end

  if state.currentView.keypressed then
    state.currentView.keypressed(state.bus, key)
  end
end

function love.mousepressed(x, y, button)
  if state.currentView.mousepressed then
    state.currentView.mousepressed(state.bus, x, y, button)
  end
end

function love.resize(w, h)
  push:resize(w, h)
end

function love.draw()
  push:start()
  state.currentView.draw()
  push:finish()
end
