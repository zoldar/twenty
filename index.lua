local lg = love.graphics
local b = require("lib/batteries")
local f = b.functional
local push = require("lib/push/push")
local Inky = require("lib/inky")
local Button = require("ui/button")

BUTTON_SIDE = 100
BUTTON_MARGIN = 10

GAMES = {
  {
    name = "Pong",
    game = require("pong/game")
  }
}

Index = {}

local font, titleFont, menu, scene, pointer

local function setupIndex(bus, games)
  scene = Inky.scene()
  pointer = Inky.pointer(scene)
  font = lg.newFont(14)
  titleFont = lg.newFont(26)
  menu = f.map(GAMES, function(entry, idx)
    return Button(scene, entry.name, font, function()
      bus:publish("open", entry.game)
    end)
  end)
end

function Index.load(bus, games)
  setupIndex(bus, games)
end

function Index.update(_bus, key)
  local mx, my = love.mouse.getX(), love.mouse.getY()
  local lx, ly = push:toGame(mx, my)
  pointer:setPosition(lx, ly)
end

function Index.mousereleased(_bus, _x, _y, button)
  if button == 1 then
    pointer:raise("release")
  end
end

function Index.draw()
  local w, h = push:getDimensions()
  local startPosition = b.vec2(
    w / 2 - (BUTTON_SIDE + BUTTON_MARGIN) * #GAMES / 2,
    h / 2 - BUTTON_SIDE / 2
  )

  lg.setColor(.2, .2, .2)
  lg.rectangle("fill", 0, 0, w, h)

  lg.setColor(1, 1, 1)
  lg.printf("20 GAMES CHALLENGE", titleFont, 0, 20, w, "center")

  scene:beginFrame()
  for idx, button in ipairs(menu) do
    button.props.margin = BUTTON_MARGIN
    local position = startPosition + b.vec2(
      (idx - 1) * (BUTTON_SIDE + BUTTON_MARGIN),
      0
    )
    button:render(position.x, position.y, BUTTON_SIDE, BUTTON_SIDE)
  end
  scene:finishFrame()
end

return Index
