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
        return "warning"
      end
    end
  },
  warning = {
    enter = function(ctx)
      ctx.timer = 2
    end,
    update = function(ctx, dt)
      ctx.timer = ctx.timer - dt

      if ctx.timer <= 0 then
        return "flying"
      end
    end
  },
  flying = {}
}

Projectile = {}

function Projectile:spawn(game, world, opts)
  opts = opts or {}
  local spawnY = opts.spawnY or game.ground - lm.random(50, 200)
  local startTimer = opts.startTimer or lm.random(1, 10)
  local machine = b.table.deep_copy(MACHINE)
  machine.pending.timer = startTimer

  local state = {
    damageDealt = false,
    type = "projectile",
    group = "dynamic",
    width = 100,
    height = 20,
    x = game.spawnX,
    y = spawnY,
    speed = 700,
    machine = b.state_machine(machine)
  }

  state.machine:set_state("pending")

  self.__index = self
  local object = setmetatable(state, self)

  world:add(
    object,
    state.x,
    state.y,
    slick.newRectangleShape(0, 0, state.width, state.height, slick.newTag("damage"))
  )

  return object
end

function Projectile:update(world, dt)
  self.machine:update(dt)
  local currentState = self.machine.current_state_name

  if currentState == "flying" then
    local newX = self.x - self.speed * dt

    self.x = newX
    world:update(self, self.x, self.y)
  end
end

function Projectile:onCollide(player)
  if not self.damageDealt then
    self.damageDealt = true
    print("damage dealt")
  end
end

function Projectile:draw()
  local currentState = self.machine.current_state_name

  if currentState == "warning" then
    local w, _ = push:getDimensions()

    lg.circle("line", w - 40, self.y + self.height / 2, 20)
  end
end

return Projectile
