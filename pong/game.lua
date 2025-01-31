local lg = love.graphics
local lk = love.keyboard
local push = require("lib/push/push")
local b = require("lib/batteries")
local slick = require("lib.slick.slick")
local Inky = require("lib/inky")
local Button = require("ui/button")

TOP_BOUND = 18
BOTTOM_BOUND = 340
PADDLE_HEIGHT = 100
PADDLE_WIDTH = 20
PADDLE_SPEED = 200
BALL_RADIUS = 15
BALL_SPEED = 200
SPEED_INCREMENT = 10
MAX_SPEED = 1000
MAX_SCORE = 5

Game = {}

local assets, world, state, mainBus

local function randomDirection()
  local angle1 = love.math.random(-math.pi / 4, math.pi / 4)
  local angle2 = love.math.random(-math.pi * 5 / 4, -math.pi * 3 / 4)
  return b.vec2():polar(1, b.table.pick_random({ angle1, angle2 }))
end

local function reset()
  local w, h = push:getDimensions()
  local middle = (h - PADDLE_HEIGHT) / 2
  state = {
    debug = false,
    leftEdge = 0,
    rightEdge = w,
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
    slick.newRectangleShape(0, 0, w, TOP_BOUND),
    slick.newRectangleShape(0, BOTTOM_BOUND, w, h)
  ))
end

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
  local w, _h = push:getDimensions()
  local ballY = state.ball.position.y
  local playerY = player.position.y + PADDLE_HEIGHT / 2

  local y = 0

  if math.abs(player.position.x - state.ball.position.x) > w * 0.5 then
    return y
  end

  if ballY > playerY + 30 then
    y = 1
  end

  if ballY < playerY - 30 then
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
    TOP_BOUND + 3,
    BOTTOM_BOUND - PADDLE_HEIGHT - 3
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
    assets.bumpSound:stop()
    assets.bumpSound:play()
    local bounce = cols[1].extra.bounceNormal
    direction.x, direction.y = bounce.x, bounce.y
    state.ball.speed = b.math.clamp(state.ball.speed + SPEED_INCREMENT, 0, MAX_SPEED)
  end
end

local function drawGame()
  local w, h = push:getDimensions()

  lg.setColor(1, 1, 1)

  lg.draw(assets.backdrop, 0, 0)

  lg.setLineWidth(3)
  lg.line(w / 2, 30, w / 2, h - 30)
  lg.setLineWidth(1)

  lg.draw(
    assets.paddle,
    state.player1.position.x - 1,
    state.player1.position.y
  )

  lg.draw(
    assets.paddle,
    state.player2.position.x - 1,
    state.player2.position.y
  )

  lg.draw(
    assets.ball,
    state.ball.position.x - BALL_RADIUS - 1,
    state.ball.position.y - BALL_RADIUS
  )

  if state.debug then
    slick.drawWorld(world)
  end
end

local function drawUI()
  local w, _h = push:getDimensions()

  lg.print(
    state.player1.score,
    assets.scoreFont, w / 2 - 30 - assets.scoreFont:getWidth(state.player1.score),
    20
  )
  lg.print(
    state.player2.score, assets.scoreFont,
    w / 2 + 30,
    20
  )
end

local machine = b.state_machine()

machine:add_state("intro", {
  enter = function(ctx)
    reset()
    ctx.scene = Inky.scene()
    ctx.pointer = Inky.pointer(ctx.scene)
    ctx.buttonOnePlayer = Button(ctx.scene, "One Player", assets.font, function()
      state.player1.type = "human"
      state.player1.upKey = { "w", "up" }
      state.player1.downKey = { "s", "down" }
      state.player2.type = "cpu"
      machine:set_state("playing")
    end)
    ctx.buttonTwoPlayers = Button(ctx.scene, "Two Players", assets.font, function()
      state.player1.type = "human"
      state.player1.upKey = "w"
      state.player1.downKey = "s"
      state.player2.type = "human"
      state.player2.upKey = "up"
      state.player2.downKey = "down"
      machine:set_state("playing")
    end)
    ctx.buttonMainMenu = Button(ctx.scene, "Back to Main Menu", assets.font, function()
      mainBus:publish("open_index")
    end)
  end,
  update = function(ctx)
    local mx, my = love.mouse.getX(), love.mouse.getY()
    local lx, ly = push:toGame(mx, my)
    ctx.pointer:setPosition(lx, ly)
  end,
  draw = function(ctx)
    lg.draw(assets.backdrop, 0, 0)
    local w, _h = push:getDimensions()
    ctx.scene:beginFrame()

    lg.setColor(1, 1, 1)
    lg.printf("PONG", assets.blockFont, 0, 40, w, "center")

    ctx.buttonOnePlayer:render((w - 200) / 2, 150, 200, 40)
    ctx.buttonTwoPlayers:render((w - 200) / 2, 200, 200, 40)
    ctx.buttonMainMenu:render((w - 200) / 2, 250, 200, 40)

    if ctx.buttonOnePlayer.props.hover then
      lg.setColor(.4, .4, .4)
      lg.print([[
      W or UP - move up
      S or DOWN - move down
      ]], assets.helpFont, 10, 160)
    end

    if ctx.buttonTwoPlayers.props.hover then
      lg.setColor(.4, .4, .4)

      lg.print([[
      PLAYER 1:
      W - move up
      S - move down
      ]], assets.helpFont, 10, 210)

      lg.print([[
      PLAYER 2:
      UP - move up
      DOWN - move down
      ]], assets.helpFont, w - 200, 210)
    end

    ctx.scene:finishFrame()
  end
})

machine:add_state("playing", {
  update = function(_ctx, dt)
    updateBall(dt)
    updatePlayer(state.player1, dt)
    updatePlayer(state.player2, dt)

    if state.ball.position.x + BALL_RADIUS < state.leftEdge then
      state.lastScore = "player2"
      machine:set_state("score")
    elseif state.ball.position.x - BALL_RADIUS > state.rightEdge then
      state.lastScore = "player1"
      machine:set_state("score")
    end
  end,
  draw = function()
    drawGame()
    drawUI()
  end
})

machine:add_state("score", {
  enter = function(ctx)
    local scoringPlayer = state[state.lastScore]
    scoringPlayer.score = scoringPlayer.score + 1
    assets.scoreSound:play()

    if scoringPlayer.score == MAX_SCORE then
      machine:set_state("finished")
    else
      ctx.timer = b.timer(1, nil, function()
        machine:set_state("playing")
      end)

      local w, h = push:getDimensions()
      state.ball.position = b.vec2(w / 2, h / 2)
      state.ball.direction = randomDirection()
      state.ball.speed = BALL_SPEED
      world:update(state.ball, state.ball.position.x, state.ball.position.y)
    end
  end,
  update = function(ctx, dt)
    ctx.timer:update(dt)
    updatePlayer(state.player1, dt)
    updatePlayer(state.player2, dt)
  end,
  draw = function()
    drawGame()
    drawUI()
  end
})

machine:add_state("finished", {
  enter = function(ctx)
    ctx.timer = b.timer(2, nil, function()
      machine:set_state("intro")
    end)

    if state.player1.score > state.player2.score then
      ctx.winner = state.player1
    else
      ctx.winner = state.player2
    end
  end,
  update = function(ctx, dt)
    ctx.timer:update(dt)
  end,
  draw = function(ctx)
    local w, h = push:getDimensions()
    drawGame()
    drawUI()
    lg.printf(
      ctx.winner.name .. " won!",
      assets.font, 0, (h - assets.font:getHeight()) / 2, w, "center"
    )
  end
})

function Game.load(bus)
  assets = {
    font = lg.newFont("assets/Kenney High.ttf", 28),
    helpFont = lg.newFont("assets/Kenney High.ttf", 23),
    scoreFont = lg.newFont("assets/Kenney High.ttf", 32),
    blockFont = lg.newFont("assets/Kenney Blocks.ttf", 64),
    scoreSound = love.audio.newSource("pong/assets/score.wav", "static"),
    bumpSound = love.audio.newSource("pong/assets/bump.wav", "static"),
    backdrop = lg.newImage("pong/assets/backdrop.png"),
    ball = lg.newImage("pong/assets/ball.png"),
    paddle = lg.newImage("pong/assets/paddle.png")
  }
  mainBus = bus
  reset()
  machine:set_state("intro")
end

function Game.unload()
  assets = nil
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

function Game.mousereleased(_bus, _x, _y, button)
  if button == 1 and machine:current_state().pointer then
    machine:current_state().pointer:raise("release")
  end
end

function Game.draw()
  machine:draw()
end

return Game
