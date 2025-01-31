local lm = love.math
local slick = require("lib.slick.slick")
local b = require("lib/batteries")

Laser = {}

function Laser:spawn(game, world)
  local height = lm.random(100, 200)
  local y = lm.random(game.ceiling + height / 2, game.ground - height / 2)
  local rotation = lm.random(0, 7) * math.pi / 4

  local state = {
    damageDealt = false,
    type = "laser",
    group = "static",
    rotating = b.table.pick_random({ false, true }),
    rotation = rotation,
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
      slick.newRectangleShape(-state.width / 2, -state.height / 2, state.width, 15, slick.newTag("push")),
      slick.newRectangleShape(-state.width / 2 + 5, -state.height / 2 + 15, 10, state.height - 30, slick.newTag("damage")),
      slick.newRectangleShape(-state.width / 2, state.height / 2 - 15, state.width, 15, slick.newTag("push"))
    )
  )

  world:rotate(object, state.rotation)

  return object
end

function Laser:update(world, dt)
  local newX = self.x - self.speed * dt

  self.x = newX
  world:update(self, self.x, self.y)

  if self.rotating then
    self.rotation = self.rotation + math.pi * dt / 4
    world:rotate(
      self,
      self.rotation,
      function() return false end, function(item)
        return item.type == "player"
      end)
  end
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
