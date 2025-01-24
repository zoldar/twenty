local lg = love.graphics
local b = require("lib/batteries")
local f = b.functional
local push = require("lib/push/push")

BUTTON_SIDE = 100
BUTTON_MARGIN = 10

GAMES = {
  {
    name = "Pong",
    game = require("pong/game")
  }
}

Index = {}

local font, menu, hover

local function setupIndex(games)
  hover = 1
  font = lg.newFont(14)
  local w, h = push:getDimensions()
  local startPosition = b.vec2(
    w / 2 - (BUTTON_SIDE + BUTTON_MARGIN) * #GAMES / 2,
    h / 2 - BUTTON_SIDE / 2
  )

  menu = f.map(GAMES, function(entry, idx)
    return {
      label = entry.name,
      game = entry.game,
      position = startPosition + b.vec2((idx - 1) * (BUTTON_SIDE + BUTTON_MARGIN), 0)
    }
  end)
end

function Index.load(games)
  setupIndex(games)
end

local function openGame(bus)
  bus:publish("open", GAMES[hover].game)
end

function Index.keypressed(bus, key)
  if (key == 'return' or key == 'space') and hover > 0 then
    openGame(bus)
    return true
  end
end

function Index.draw()
  local w, h = push:getDimensions()
  lg.setColor(.2, .2, .2)
  lg.rectangle("fill", 0, 0, w, h)

  for idx, item in ipairs(menu) do
    lg.setColor(1, 1, 1)
    lg.rectangle("line", item.position.x, item.position.y, BUTTON_SIDE, BUTTON_SIDE)

    if idx == hover then
      lg.setColor(1, 1, 0)
      lg.rectangle("line", item.position.x - 5, item.position.y - 5, BUTTON_SIDE + 10, BUTTON_SIDE + 10)
    end

    lg.setColor(1, 1, 1)
    lg.print(
      item.label,
      font,
      item.position.x + BUTTON_SIDE / 2 - font:getWidth(item.label) / 2,
      item.position.y + BUTTON_SIDE / 2 - font:getHeight() / 2
    )
  end
end

return Index
