local lg = love.graphics
local lk = love.keyboard
local lm = love.math

local push = require("lib/push/push")
local b = require("lib/batteries")

PLAYER_HEIGHT = 32
SPEED = 100
HSPEED = 40
PROPEL_SPEED = 180
BRAKE_SPEED = 50

JoyRaid = {}

local state

local function reset()
  local w, h = push:getDimensions()

  state = {
    debug = true,
    player = {
      hit = false,
      speed = SPEED,
      x = w / 2,
      y = h - PLAYER_HEIGHT - 8,
    },
  }
end

local function terrain(seed)
  lm.setRandomSeed(seed)

  local w, h = push:getDimensions()
  -- min_width = PLAYER_SIZE * 3
  -- max_width = w * 0.75
  -- min_segment = h / 3
  -- max_segment = h * 1.5
  -- slope = pi / 4
  -- stage_length = h * 20
  -- start_width = max_width

  local distance = 0
  local width = w * 0.75
  local shore = {}

  while distance <= h * 20 do
    table.insert(shore, { x = (w - width) / 2, distance })
    local segment = h / 3 + lm.noise(distance) * h * 1.5
    distance = distance + segment
  end
end

local function updatePlayer(dt)
  terrain(123)
  local direction = 0
  local thrust = 0

  if lk.isDown("left") then
    direction = direction - 1
  end

  if lk.isDown("right") then
    direction = direction + 1
  end

  if lk.isDown("up") then
    thrust = thrust + 1
  end

  if lk.isDown("down") then
    thrust = thrust - 1
  end

  local speed = SPEED

  if thrust > 0 then
    speed = PROPEL_SPEED
  elseif thrust < 0 then
    speed = BRAKE_SPEED
  end

  state.player.x = state.player.x + direction * HSPEED * dt
  state.player.y = state.player.y - speed * dt
end

local machine = b.state_machine()

machine:add_state("intro", {
  enter = function()
    reset()
  end,
  draw = function()
    local w, h = push:getDimensions()
    lg.printf(
      [[
      JOYRAID
      PRESS SPACE TO CONTINUE
      ]],
      0,
      h / 2,
      w,
      "center"
    )
  end,
})

machine:add_state("playing", {
  update = function(_ctx, dt)
    updatePlayer(dt)
  end,
  draw = function()
    local _w, h = push:getDimensions()
    lg.push()
    lg.translate(0, -state.player.y + h - PLAYER_HEIGHT - 8)
    lg.setColor(1, 1, 1)
    lg.circle("fill", state.player.x, state.player.y, 16)
    lg.pop()
  end,
})

function JoyRaid.load()
  machine:set_state("intro")
end

function JoyRaid.update(dt)
  machine:update(dt)
end

function JoyRaid.keypressed(_bus, key)
  if key == "space" or key == "return" then
    if machine:in_state("intro") then
      machine:set_state("playing")
    end
  end

  if key == "d" then
    state.debug = not state.debug
  end

  if key == "q" or key == "escape" then
    if not machine:in_state("intro") then
      machine:set_state("intro")
      return true
    end
  end

  return false
end

function JoyRaid.draw()
  machine:draw()
end

return JoyRaid
