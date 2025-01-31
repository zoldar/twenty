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
    debug = true,
    distance = 0,
    speed = SPEED,
    ground = ground,
    ceiling = 0,
    spawnX = w + SPAWN_POINT,
    player = {
      type = "player",
      hit = false,
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
  if lk.isDown("space") and not state.player.hit then
    state.player.thrust = b.math.lerp(state.player.thrust, MAX_THRUST, 0.1)
  else
    state.player.thrust = b.math.lerp(state.player.thrust, 0, 0.1)
  end

  world:push(
    state.player,
    function(item, _shape, _otherIteam, otherShape)
      return item.type == "player" and not item.hit and otherShape.tag == "push"
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
    function(_item, other, _shape, otherShape)
      return not state.player.hit and otherShape.tag == "push"
    end
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

local machine = b.state_machine()

machine:add_state("intro", {
  enter = function()
    reset()
  end,
  draw = function()
    local w, h = push:getDimensions()
    lg.printf([[
      JETTY JOY
      PRESS SPACE TO CONTINUE
      ]], 0, h / 2, w, "center")
  end
})

machine:add_state("playing", {
  update = function(_ctx, dt)
    state.distance = state.distance + 5 * dt
    updateEntities(state.staticEntities, dt)
    updateEntities(state.dynamicEntities, dt)
    updatePlayer(dt)
    spawnStaticEntity(dt)
    spawnDynamicEntities(dt)

    if state.player.hit or state.player.x < -100 then
      state.player.hit = true
      return "finish"
    end
  end,
  draw = function()
    local w, _ = push:getDimensions()
    drawEntities(state.staticEntities)
    drawEntities(state.dynamicEntities)
    lg.printf("DISTANCE: " .. math.floor(state.distance), 0, 20, w, "right")
    slick.drawWorld(world)
  end
})

machine:add_state("finish", {
  enter = function(ctx)
    ctx.timer = 5
  end,
  update = function(ctx, dt)
    ctx.timer = ctx.timer - dt
    updateEntities(state.staticEntities, dt)
    updateEntities(state.dynamicEntities, dt)
    updatePlayer(dt)

    if ctx.timer < 0 then
      return "intro"
    end
  end,
  draw = function()
    local w, h = push:getDimensions()
    drawEntities(state.staticEntities)
    drawEntities(state.dynamicEntities)
    lg.printf("DISTANCE: " .. math.floor(state.distance), 0, 20, w, "right")
    lg.printf("YOU DIED!", 0, h / 2, w, "center")
    slick.drawWorld(world)
  end
})

function JettyJoy.load()
  reset()
  machine:set_state("intro")
end

function JettyJoy.update(dt)
  machine:update(dt)
end

function JettyJoy.keypressed(_bus, key)
  if (key == "space" or key == "return") then
    if machine:in_state("intro") then
      machine:set_state("playing")
    end
  end

  if (key == "d") then
    state.debug = not state.debug
  end

  if (key == "q" or key == "escape") then
    if not machine:in_state("intro") then
      machine:set_state("intro")
      return true
    end
  end

  return false
end

function JettyJoy.draw()
  machine:draw()
end

return JettyJoy
