local lk = love.keyboard
local lg = love.graphics
local b = require("lib/batteries")
local slick = require("lib.slick.slick")

PLAYER_WIDTH = 32
PLAYER_HEIGHT = 32
PLAYER_SPEED = 200

Player = {}

function Player:new(world, x, y)
  local state = {
    type = "player",
    position = b.vec2(x, y),
    rotation = 0,
  }

  self.__index = self
  local object = setmetatable(state, self)

  world:add(
    object,
    object.position.x,
    object.position.y,
    slick.newRectangleShape(-PLAYER_WIDTH / 2, -PLAYER_HEIGHT / 2, PLAYER_WIDTH, PLAYER_HEIGHT)
  )

  return object
end

function Player:update(world, pointer, dt)
  local direction = b.vec2()
  local speed = 0

  self.rotation = (pointer - self.position):angle()

  if lk.isDown("left", "a") then
    direction.x = direction.x - 1
    speed = PLAYER_SPEED
  end

  if lk.isDown("right", "d") then
    direction.x = direction.x + 1
    speed = PLAYER_SPEED
  end

  if lk.isDown("up", "w") then
    direction.y = direction.y - 1
    speed = PLAYER_SPEED
  end

  if lk.isDown("down", "s") then
    direction.y = direction.y + 1
    speed = PLAYER_SPEED
  end

  if direction.x ~= 0 and direction.y ~= 0 then
    speed = 0.71 * speed
  end

  world:push(self, function(item, _, _, otherShape)
    return item.type == "player" and otherShape.tag == "push"
  end, self.position.x, self.position.y)

  self.position = self.position + direction * speed * dt

  self.position.x, self.position.y = world:move(self, self.position.x, self.position.y, function(_, _, _, otherShape)
    return otherShape.tag == "push"
  end)
end

function Player:shoot(gamebus, pointer)
  local direction = (pointer - self.position):normalize()

  gamebus:publish("shoot", {
    type = "bullet",
    velocity = direction * BULLET_SPEED,
    position = self.position + direction * 10,
  })
end

function Player:draw()
  lg.setColor(1, 1, 1)
  lg.rectangle(
    "fill",
    self.position.x - PLAYER_WIDTH / 2,
    self.position.y - PLAYER_HEIGHT / 2,
    PLAYER_WIDTH,
    PLAYER_HEIGHT
  )

  lg.push()

  lg.translate(self.position.x, self.position.y)
  lg.rotate(self.rotation)
  lg.setColor(0, 0.5, 0.5)
  lg.rectangle("fill", 0, -3, 30, 6)

  lg.pop()
end

return Player
