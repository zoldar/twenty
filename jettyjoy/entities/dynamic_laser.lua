local lg = love.graphics
local lm = love.math
local b = require("lib/batteries")
local slick = require("lib.slick.slick")
local push = require("lib/push/push")

local MACHINE = {
  pending = {
    update = function(ctx, dt)
      ctx.timer = ctx.timer - dt

      if ctx.timer <= 0 then
        return "moving_in"
      end
    end
  },
  moving_in = {
    enter = function(ctx)
      ctx.timer = 2
    end,
    update = function(ctx, dt)
      ctx.timer = ctx.timer - dt

      if ctx.timer <= 0 then
        return "damage"
      end
    end
  },
  damage = {
    enter = function(ctx)
      ctx.timer = 3
    end,
    update = function(ctx, dt)
      ctx.timer = ctx.timer - dt

      if ctx.timer <= 0 then
        return "moving_away"
      end
    end
  },
  moving_away = {}
}

DynamicLaser = {}

function DynamicLaser:spawn(game, world, opts)
  local w, _ = push:getDimensions()
  opts = opts or {}
  local spawnY = opts.spawnY or game.ground - lm.random(50, 200)
  local startTimer = opts.startTimer or lm.random(1, 10)
  local machine = b.table.deep_copy(MACHINE)
  machine.pending.timer = startTimer

  local state = {
    damageDealt = false,
    type = "dynamic_laser",
    group = "dynamic",
    height = 20,
    width = w,
    x = game.spawnX,
    y = spawnY,
    speed = 400,
    machine = b.state_machine(machine)
  }

  state.machine:set_state("pending")

  self.__index = self
  local object = setmetatable(state, self)

  world:add(
    object,
    state.x,
    state.y,
    slick.newShapeGroup(
      slick.newRectangleShape(0, 0, 20, 20, slick.newTag("damage")),
      slick.newRectangleShape(20, 5, state.width - 40, 10, slick.newTag("damage")),
      slick.newRectangleShape(state.width - 20, 0, 20, 20, slick.newTag("damage"))
    )
  )

  return object
end

function DynamicLaser:update(world, dt)
  self.machine:update(dt)
  local currentState = self.machine.current_state_name
  print("dynamic_laser: "..currentState)

  local targetX = currentState == "moving_in" and 0 or - self.width - 200

  if currentState == "moving_in" or currentState == "moving_away" then
    local newX = b.math.lerp(self.x, targetX, 5 * dt)

    self.x = newX
    world:update(self, self.x, self.y)
  end
end

function DynamicLaser:onCollide(player)
  local currentState = self.machine.current_state_name
  if currentState == "damage" and not self.damageDealt then
    self.damageDealt = true
    print("damage dealt")
  end
end

function DynamicLaser:draw()
  -- local currentState = self.machine.current_state_name
end

return DynamicLaser
