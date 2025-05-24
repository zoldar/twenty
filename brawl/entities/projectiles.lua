local lg = love.graphics

BULLET_TIME = 5

Projectiles = {}

function Projectiles:new(_, gamebus)
  local state = {
    entities = {},
  }

  self.__index = self
  local object = setmetatable(state, self)

  gamebus:subscribe("shoot", function(params)
    table.insert(state.entities, {
      type = params.type,
      velocity = params.velocity,
      position = params.position,
      timer = BULLET_TIME,
    })
  end)

  return object
end

function Projectiles:update(_, dt)
  for i = #self.entities, 1, -1 do
    local projectile = self.entities[i]

    projectile.position = projectile.position + projectile.velocity * dt
    projectile.timer = projectile.timer - dt

    if projectile.timer <= 0 then
      table.remove(self.entities, i)
    end
  end
end

function Projectiles:draw(_, _)
  for _, projectile in ipairs(self.entities) do
    lg.setColor(1, 0.5, 0)
    lg.circle("fill", projectile.position.x, projectile.position.y, 2)
  end
end

return Projectiles
