local lg = love.graphics

local cam = require("lib/cam11/cam11")
local push = require("lib/push/push")
local b = require("lib/batteries")
local slick = require("lib.slick.slick")
local Player = require("brawl/entities/player")
local Projectiles = require("brawl/entities/projectiles")

PLAYER_HEIGHT = 32
PLAYER_SPEED = 200
BULLET_SPEED = 1000
BULLET_TIME = 3

Brawl = {}

local state, world

local function reset()
  local w, h = push:getDimensions()

  world = slick.newWorld(w, h)

  local gamebus = b.pubsub()

  local startX, startY = w / 2, h / 2
  local player = Player:new(world, startX, startY)

  state = {
    debug = true,
    camera = cam(),
    gamebus = gamebus,
    pointer = b.vec2(0, 0),
    player = player,
    dynamicEntities = {
      player,
    },
    staticEntities = {},
    projectiles = Projectiles:new(world, gamebus),
    map = {
      walls = {
        { x = 20, y = 30, width = 100, height = 200 },
        { x = w - 300, y = h - 100, width = 200, height = 100 },
      },
    },
  }

  for _, wall in ipairs(state.map.walls) do
    world:add(
      { type = "level" },
      0,
      0,
      slick.newRectangleShape(wall.x, wall.y, wall.width, wall.height, slick.newTag("push"))
    )
  end
end

local machine = b.state_machine()

machine:add_state("intro", {
  draw = function()
    local w, h = push:getDimensions()
    lg.printf(
      [[
      BRAWL
      PRESS SPACE TO CONTINUE
      ]],
      0,
      h / 2,
      w,
      "center"
    )
  end,
})

machine:add_state("playing", {
  enter = function()
    love.mouse.setVisible(false)
    reset()
  end,
  leave = function()
    love.mouse.setVisible(true)
  end,
  update = function(_, dt)
    local mx, my = love.mouse.getX(), love.mouse.getY()
    local lx, ly = push:toGame(mx, my)
    if lx and ly then
      local wx, wy = state.camera:toWorld(lx, ly)
      state.pointer.x, state.pointer.y = wx, wy
    end

    for i = #state.dynamicEntities, 1, -1 do
      state.dynamicEntities[i]:update(world, state.pointer, dt)
    end

    state.projectiles:update(world, dt)

    -- FIXME: work out proper offset
    local w, h = push:getDimensions()
    state.camera:setPos(state.player.position.x + w - PLAYER_WIDTH * 2, state.player.position.y + h - PLAYER_HEIGHT)
  end,
  draw = function()
    local w, h = push:getDimensions()

    lg.setColor(0.2, 0.2, 0.2)
    lg.rectangle("fill", 0, 0, w, h)

    state.camera:attach()

    -- walls
    for _, wall in ipairs(state.map.walls) do
      lg.setColor(0, 1, 0)
      lg.rectangle("fill", wall.x, wall.y, wall.width, wall.height)
    end

    for _, entity in ipairs(state.dynamicEntities) do
      entity:draw()
    end

    -- projectiles
    state.projectiles:draw()

    -- pointer
    lg.setColor(1, 0, 0)
    lg.circle("fill", state.pointer.x, state.pointer.y, 4)

    state.camera:detach()
  end,
})

function Brawl.load()
  machine:set_state("playing")
end

function Brawl.update(dt)
  machine:update(dt)
end

function Brawl.keypressed(_, key)
  if key == "space" or key == "return" then
    if machine:in_state("intro") then
      machine:set_state("playing")
    end

    if machine:in_state("playing") then
      state.player:shoot(state.gamebus, state.pointer)
    end
  end

  if key == "d" then
    state.debug = not state.debug
  end

  if key == "escape" then
    if not machine:in_state("intro") then
      machine:set_state("intro")
      return true
    end
  end

  return false
end

function Brawl.mousepressed(_, _, _, button)
  if button == 1 then
    state.player:shoot(state.gamebus, state.pointer)
  end
end

function Brawl.draw()
  machine:draw()
end

return Brawl
