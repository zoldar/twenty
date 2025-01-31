local lm = love.math
local b = require("lib/batteries")
local DynamicLaser = require("jettyjoy/entities/dynamic_laser")

MIN_DISTANCE = 200

LaserGroup = {}

function LaserGroup:spawn(game, world)
  local topBound, bottomBound = game.ceiling + 10, game.ground - 10
  local spawnYs = { lm.random(topBound, bottomBound) }
  local startTimer = lm.random(1, 10)

  local spawnAttempts = 0
  while #spawnYs < 2 and spawnAttempts < 10 do
    local newY = lm.random(topBound, bottomBound)
    local tooClose = b.functional.any(spawnYs, function(existing)
      return math.abs(existing - newY) < MIN_DISTANCE
    end)

    if not tooClose then
      table.insert(spawnYs, newY)
    end
    spawnAttempts = spawnAttempts + 1
  end

  return b.functional.map(spawnYs, function(y)
    return DynamicLaser:spawn(game, world, { spawnY = y, startTimer = startTimer })
  end)
end

return LaserGroup
