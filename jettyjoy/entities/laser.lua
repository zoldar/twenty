local lm = love.math
local b = require("lib/batteries")
local slick = require("lib.slick.slick")
local common = require("jettyjoy/entities/common")

Laser = {}

function Laser:spawn(game, world)
  local lastEntity = b.table.back(game.entities)
  if lastEntity and game.spawnX - lastEntity.x - lastEntity.width < 200 then
    return nil
  end

  local height = lm.random(100, 200)
  local y = lm.random(game.ceiling, game.ground - height)

  local state = {
    damageDealt = false,
    type = "laser",
    width = 20,
    height = height,
    x = game.spawnX,
    y = y,
    speed = game.speed
  }

  self.__index = self
  local object = setmetatable(state, self)

  world:add(
    object,
    state.x,
    state.y,
    slick.newShapeGroup(
      slick.newRectangleShape(0, 0, state.width, 15, slick.newTag("push")),
      slick.newRectangleShape(5, 15, 10, state.height - 30, slick.newTag("damage")),
      slick.newRectangleShape(0, state.height - 15, state.width, 15, slick.newTag("push"))
    )
  )

  return object
end

function Laser:update(world, dt)
  local newX = self.x - self.speed * dt

  common.updatePushEntity(world, self, newX, self.y)
end

function Laser:onCollide(player)
  if not self.damageDealt then
    self.damageDealt = true
    print("damage dealt")
  end
end

function Laser:draw()
  -- NOOP in debug mode
end

return Laser
