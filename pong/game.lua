local lg = love.graphics
local lk = love.keyboard
local push = require("lib/push/push")
local b = require("lib/batteries")
local slick = require("lib.slick.slick")

PADDLE_HEIGHT = 100
PADDLE_WIDTH = 20
PADDLE_SPEED = 200
BALL_RADIUS = 20
BALL_SPEED = 200
SPEED_INCREMENT = 10

Game = {}

local font, world, state

local function getPlayerInput(player)
  local y = 0

  if lk.isDown(player.upKey) then
    y = y - 1
  end

  if lk.isDown(player.downKey) then
    y = y + 1
  end

  return y
end

local function updatePlayer(player, dt)
  local inputY = getPlayerInput(player)

  player.position.y = b.math.clamp(
    player.position.y + inputY * PADDLE_SPEED * dt,
    state.topBound,
    state.bottomBound - PADDLE_HEIGHT
  )

  world:update(player, player.position.x, player.position.y)
end

local function updateBall(dt)
  local position = state.ball.position
  local direction = state.ball.direction
  local target = position + direction * state.ball.speed * dt
  local cols

  position.x, position.y, cols = world:move(
    state.ball,
    target.x,
    target.y,
    function() return "bounce" end
  )

  if #cols > 0 then
    local bounce = cols[1].extra.bounceNormal
    direction.x, direction.y = bounce.x, bounce.y
    state.ball.speed = state.ball.speed + SPEED_INCREMENT
  end
end

local machine = b.state_machine()

machine:add_state("intro", {
  draw = function()
    local w, h = push:getDimensions()
    lg.setColor(1, 1, 1)
    lg.print("PONG", font, (w - font:getWidth("PONG")) / 2, (h - font:getHeight()) / 2)
  end
})

machine:add_state("playing", {
  update = function(_state, dt)
    updateBall(dt)
    updatePlayer(state.player1, dt)
    updatePlayer(state.player2, dt)
  end,
  draw = function()
    slick.drawWorld(world)
  end
})

function Game.load()
  local w, h = push:getDimensions()
  local middle = (h - PADDLE_HEIGHT) / 2
  font = lg.newFont(26)
  state = {
    topBound = 10,
    bottomBound = h - 10,
    player1 = {
      name = "player1",
      upKey = "w",
      downKey = "s",
      type = "human",
      position = b.vec2(PADDLE_WIDTH, middle),
      score = 0
    },
    player2 = {
      name = "player2",
      upKey = "up",
      downKey = "down",
      type = "human",
      position = b.vec2(w - 2 * PADDLE_WIDTH, middle),
      score = 0
    },
    ball = {
      type = "ball",
      speed = BALL_SPEED,
      position = b.vec2(w / 2, h / 2),
      direction = b.vec2(-1, -1):normalize()
    }
  }

  world = slick.newWorld(w, h)

  world:add(
    state.player1,
    state.player1.position.x,
    state.player1.position.y,
    slick.newRectangleShape(0, 0, PADDLE_WIDTH, PADDLE_HEIGHT)
  )

  world:add(
    state.player2,
    state.player2.position.x,
    state.player2.position.y,
    slick.newRectangleShape(0, 0, PADDLE_WIDTH, PADDLE_HEIGHT)
  )

  world:add(
    state.ball,
    state.ball.position.x,
    state.ball.position.y,
    slick.newCircleShape(0, 0, BALL_RADIUS)
  )

  world:add({ type = "level" }, 0, 0, slick.newShapeGroup(
    slick.newRectangleShape(0, 0, w, 10),
    slick.newRectangleShape(0, h - 10, w, 10)
  ))

  machine:set_state("intro")
end

function Game.unload()
  font = nil
  state = nil
  world = nil
end

function Game.update(dt)
  machine:update(dt)
end

function Game.keypressed(_bus, key)
  if (key == "space" or key == "return") and machine:in_state("intro") then
    machine:set_state("playing")
  end
end

function Game.draw()
  machine:draw()
end

return Game
