local lm = love.math
local b = require("lib/batteries")
local slick = require("lib.slick.slick")
local common = require("jettyjoy/entities/common")

Obstacle = {}

function Obstacle:spawn(game, world)
  local lastEntity = b.table.back(game.entities)
  if lastEntity and game.spawnX - lastEntity.x - lastEntity.width < 200 then
    return nil
  end

  local height = lm.random(50, 200)

  local state = {
    type = "obstacle",
    width = 50,
    height = height,
    x = game.spawnX,
    y = game.ground - height,
    speed = game.speed
  }

  self.__index = self
  local object = setmetatable(state, self)

  world:add(
    object,
    state.x,
    state.y,
    slick.newRectangleShape(0, 0, state.width, state.height, slick.newTag("push"))
  )

  return object
end

function Obstacle:update(world, dt)
  local newX = self.x - self.speed * dt

  common.updatePushEntity(world, self, newX, self.y)
end

function Obstacle:draw()
  -- NOOP in debug mode
end

return Obstacle
