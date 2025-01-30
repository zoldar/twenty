local lm = love.math
local slick = require("lib.slick.slick")

Obstacle = {}

function Obstacle:spawn(game, world)
  local height = lm.random(50, 200)

  local state = {
    type = "obstacle",
    group = "static",
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

  self.x = newX
  world:update(self, self.x, self.y)
end

function Obstacle:draw()
  -- NOOP in debug mode
end

return Obstacle
