local lg = love.graphics
local lk = love.keyboard
local push = require("lib/push/push")
local b = require("lib/batteries")
local slick = require("lib.slick.slick")
local Inky = require("lib/inky")

PADDLE_HEIGHT = 100
PADDLE_WIDTH = 20
PADDLE_SPEED = 200
BALL_RADIUS = 20
BALL_SPEED = 200
SPEED_INCREMENT = 10

Game = {}

local font, world, state, mainBus

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

local function getCPUInput(player)
  local ballY = state.ball.position.y
  local playerY = player.position.y + PADDLE_HEIGHT / 2

  local y = 0

  if ballY > playerY + 10 then
    y = 1
  end

  if ballY < playerY - 10 then
    y = -1
  end

  return y
end

local function updatePlayer(player, dt)
  local inputY
  if player.type == "human" then
    inputY = getPlayerInput(player)
  else
    inputY = getCPUInput(player)
  end

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

local function randomDirection()
  local angle1 = love.math.random(-math.pi / 4, math.pi / 4)
  local angle2 = love.math.random(-math.pi * 5 / 4, -math.pi * 3 / 4)
  return b.vec2():polar(1, b.table.pick_random({ angle1, angle2 }))
end

local function newButton(scene, label, action)
  return Inky.defineElement(function(self)
    self.props.hover = false

    self:onPointer("release", action)

    self:onPointerEnter(function()
      self.props.hover = true
    end)

    self:onPointerExit(function()
      self.props.hover = false
    end)

    return function(_, x, y, w, h)
      lg.setColor(1, 1, 1)
      lg.rectangle("line", x, y, w, h)
      if self.props.hover then
        lg.setColor(1, 1, 0)
        lg.rectangle("line", x - 3, y - 3, w + 6, h + 6)
      end
      lg.setColor(1, 1, 1)
      lg.printf(label, font, x, y + (h - font:getHeight()) / 2, w, "center")
    end
  end)(scene)
end

local machine = b.state_machine()

machine:add_state("intro", {
  enter = function(ctx)
    ctx.scene = Inky.scene()
    ctx.pointer = Inky.pointer(ctx.scene)
    ctx.buttonOnePlayer = newButton(ctx.scene, "One Player", function()
      state.player1.type = "human"
      state.player2.type = "cpu"
      machine:set_state("playing")
    end)
    ctx.buttonTwoPlayers = newButton(ctx.scene, "Two Players", function()
      state.player1.type = "human"
      state.player2.type = "human"
      machine:set_state("playing")
    end)
    ctx.buttonMainMenu = newButton(ctx.scene, "Back to Main Menu", function()
      mainBus:publish("open_index")
    end)
  end,
  update = function(ctx)
    local mx, my = love.mouse.getX(), love.mouse.getY()
    local lx, ly = push:toGame(mx, my)
    ctx.pointer:setPosition(lx, ly)
  end,
  draw = function(ctx)
    local w, h = push:getDimensions()
    ctx.scene:beginFrame()

    lg.setColor(1, 1, 1)
    lg.printf("PONG", font, 0, 100, w, "center")

    ctx.buttonOnePlayer:render((w - 280) / 2, 150, 280, 40)
    ctx.buttonTwoPlayers:render((w - 280) / 2, 200, 280, 40)
    ctx.buttonMainMenu:render((w - 280) / 2, 250, 280, 40)

    ctx.scene:finishFrame()
  end
})

machine:add_state("playing", {
  update = function(_ctx, dt)
    updateBall(dt)
    updatePlayer(state.player1, dt)
    updatePlayer(state.player2, dt)

    if state.ball.position.x + BALL_RADIUS < state.leftEdge then
      state.lastScore = "player1"
      machine:set_state("score")
    elseif state.ball.position.x - BALL_RADIUS > state.rightEdge then
      state.lastScore = "player2"
      machine:set_state("score")
    end
  end,
  draw = function()
    slick.drawWorld(world)
  end
})

machine:add_state("score", {
  enter = function(ctx)
    ctx.timer = b.timer(1, nil, function()
      machine:set_state("playing")
    end)

    local w, h = push:getDimensions()
    state.ball.position = b.vec2(w / 2, h / 2)
    state.ball.direction = randomDirection()
    state.ball.speed = BALL_SPEED
    world:update(state.ball, state.ball.position.x, state.ball.position.y)
  end,
  update = function(ctx, dt)
    ctx.timer:update(dt)
    updatePlayer(state.player1, dt)
    updatePlayer(state.player2, dt)
  end,
  draw = function()
    slick.drawWorld(world)
  end
})

function Game.load(bus)
  local w, h = push:getDimensions()
  local middle = (h - PADDLE_HEIGHT) / 2
  mainBus = bus
  font = lg.newFont(26)
  state = {
    leftEdge = 0,
    rightEdge = w,
    topBound = 10,
    bottomBound = h - 10,
    lastScore = nil,
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
      type = "cpu",
      position = b.vec2(w - 2 * PADDLE_WIDTH, middle),
      score = 0
    },
    ball = {
      type = "ball",
      speed = BALL_SPEED,
      position = b.vec2(w / 2, h / 2),
      direction = randomDirection()
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
  if (key == "space" or key == "return") then
    if machine:in_state("intro") then
      machine:set_state("playing")
    end
  end

  if (key == "q" or key == "escape") then
    if machine:in_state("playing") then
      machine:set_state("intro")
      return true
    end
  end

  return false
end

function Game.mousereleased(_bus, _x, _y, button)
  if button == 1 and machine:current_state().pointer then
    machine:current_state().pointer:raise("release")
  end
end

function Game.draw()
  machine:draw()
end

return Game
