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
STATIC_ENTITIES = {
  require("jettyjoy/entities/obstacle"),
  require("jettyjoy/entities/laser")
}
DYNAMIC_ENTITIES = {
  require("jettyjoy/entities/projectile"),
  require("jettyjoy/entities/projectile_horde"),
  require("jettyjoy/entities/dynamic_laser"),
  require("jettyjoy/entities/laser_group")
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
    staticEntities = {},
    dynamicEntities = {}
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

local function spawnStaticEntity(_dt)
  local lastEntity = b.table.back(state.staticEntities)

  if not lastEntity or state.spawnX - lastEntity.x - lastEntity.width >= 500 then
    local nextEntity = b.table.pick_random(STATIC_ENTITIES)
    if not nextEntity.canSpawn or nextEntity.canSpawn(state) then
      table.insert(state.staticEntities, nextEntity:spawn(state, world))
    end
  end
end

local function spawnDynamicEntities(_dt)
  if #state.dynamicEntities == 0 then
    local nextEntity = b.table.pick_random(DYNAMIC_ENTITIES):spawn(state, world)
    if not nextEntity.type then
      for _, entity in ipairs(nextEntity) do
        table.insert(state.dynamicEntities, entity)
      end
    else
      table.insert(state.dynamicEntities, nextEntity)
    end
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

  state.player.x = b.math.lerp(state.player.x, state.player.forwardX, 0.5 * dt)
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

local function updateEntities(entities, dt)
  for _, entity in ipairs(entities) do
    entity:update(world, dt)
    if entity.x + entity.width < -100 then
      world:remove(entity)
      b.table.remove_value(entities, entity)
    end
  end
end

local function drawEntities(entities)
  for _, entity in ipairs(entities) do
    if entity.draw then
      entity:draw()
    end
  end
end

function JettyJoy.load()
  reset()
end

function JettyJoy.update(dt)
  state.distance = state.distance + dt
  updateEntities(state.staticEntities, dt)
  updateEntities(state.dynamicEntities, dt)
  updatePlayer(dt)
  spawnStaticEntity(dt)
  spawnDynamicEntities(dt)
end

function JettyJoy.draw()
  local w, _ = push:getDimensions()
  drawEntities(state.staticEntities)
  drawEntities(state.dynamicEntities)
  lg.printf("DISTANCE: "..math.floor(state.distance), 0, 20, w, "right")
  slick.drawWorld(world)
end

return JettyJoy
