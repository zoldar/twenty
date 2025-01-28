_M = {}

function _M.updatePushEntity(world, entity, newX, newY)
  local cols = world:project(
    entity,
    entity.x,
    entity.y,
    newX,
    newY,
    function(_item, other) return other.type == "player" end
  )

  entity.x = newX
  entity.y = newY
  world:update(entity, entity.x, entity.y)

  for _, col in ipairs(cols) do
    world:push(
      col.other,
      function(item, _shape, _otherIteam, otherShape)
        return item.type == "player" and otherShape.tag == "push"
      end,
      col.other.x,
      col.other.y
    )
  end
end

return _M
