local lg = love.graphics
local lk = love.keyboard
local push = require("lib/push/push")
local b = require("lib/batteries")
local slick = require("lib.slick.slick")

PLAYER_HEIGHT = 64
PLAYER_WIDTH = 40
SPEED = 200
GROUND_BOUNDARY = 20
PLAYER_POSITION_RATIO = 0.3
GRAVITY = 300
MAX_THRUST = 600
SPAWN_POINT = 200
ENTITIES = {
  require("jettyjoy/entities/obstacle"),
  require("jettyjoy/entities/laser")
}

JettyJoy = {}

local world, state

local function reset()
  local w, h = push:getDimensions()
  local ground = h - GROUND_BOUNDARY
  local forwardX = w * PLAYER_POSITION_RATIO

  state = {
    distance = 0,
    speed = SPEED,
    ground = ground,
    ceiling = 0,
    spawnX = w + SPAWN_POINT,
    player = {
      type = "player",
      thrust = 0,
      forwardX = forwardX,
      x = forwardX,
      y = ground - PLAYER_HEIGHT
    },
    entities = {}
  }

  world = slick.newWorld(w, h)

  world:add(
    state.player,
    state.player.x,
    state.player.y,
    slick.newRectangleShape(0, 0, PLAYER_WIDTH, PLAYER_HEIGHT)
  )

  world:add({ type = "level" }, 0, 0, slick.newShapeGroup(
    slick.newRectangleShape(0, state.ceiling - 10, w, state.ceiling, slick.newTag("push")),
    slick.newRectangleShape(0, state.ground, w, state.ground + 10, slick.newTag("push"))
  ))
end

local function spawnEntity(_dt)
  local nextEntity = b.table.pick_random(ENTITIES):spawn(state, world)

  if nextEntity then
    table.insert(state.entities, nextEntity)
  end
end

local function updatePlayer(dt)
  if lk.isDown("space") then
    state.player.thrust = b.math.lerp(state.player.thrust, MAX_THRUST, 0.1)
  else
    state.player.thrust = b.math.lerp(state.player.thrust, 0, 0.1)
  end

  world:push(
    state.player,
    function(item, _shape, _otherIteam, otherShape)
      return item.type == "player" and otherShape.tag == "push"
    end,
    state.player.x,
    state.player.y
  )

  state.player.x = b.math.lerp(state.player.x, state.player.forwardX, 0.01)
  state.player.y = state.player.y - state.player.thrust * dt + GRAVITY * dt

  state.player.x, state.player.y = world:move(
    state.player,
    state.player.x,
    state.player.y,
    function(_item, other, _shape, otherShape) return otherShape.tag == "push" end
  )

  local _, _, cols = world:check(
    state.player,
    state.player.x,
    state.player.y,
    function(_item, _other, _shape, otherShape) return otherShape.tag ~= "push" end
  )

  for _, col in ipairs(cols) do
    if col.other.onCollide then
      col.other:onCollide(state.player, col)
    end
  end
end

function JettyJoy.load()
  reset()
end

function JettyJoy.update(dt)
  for idx, entity in ipairs(state.entities) do
    entity:update(world, dt)
    if entity.x + entity.width < -100 then
      world:remove(entity)
      table.remove(state.entities, idx)
    end
  end
  updatePlayer(dt)
  spawnEntity(dt)
end

function JettyJoy.draw()
  slick.drawWorld(world)
end

return JettyJoy
