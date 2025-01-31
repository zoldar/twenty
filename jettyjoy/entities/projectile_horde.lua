local lm = love.math
local b = require("lib/batteries")
local Projectile = require("jettyjoy/entities/projectile")

ProjectileHorde = {}

MIN_DISTANCE = 100

function ProjectileHorde:spawn(game, world)
  local topBound, bottomBound = game.ceiling + 10, game.ground - 10
  local spawnYs = { lm.random(topBound, bottomBound) }
  local startTimer = lm.random(1, 10)

  while #spawnYs < 2 do
    local newY = lm.random(topBound, bottomBound)
    local tooClose = b.functional.any(spawnYs, function(existing)
      return math.abs(existing - newY) < MIN_DISTANCE
    end)

    if not tooClose then
      table.insert(spawnYs, newY)
    end
  end

  return b.functional.map(spawnYs, function(y)
    return Projectile:spawn(game, world, { spawnY = y, startTimer = startTimer })
  end)
end

return ProjectileHorde
