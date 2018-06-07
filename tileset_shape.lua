TileSet = {}

function TileSet:new(config)
  local newTileSet = setmetatable(copy(config), {__index=TileSet})

  newTileSet.tileColors = {
    [1] = {1, 1, 1, 1}, -- floor
    [2] = {0.35, 0.35, 0.3, 1}, -- wall
    [3] = {0.3, 0.3, 0.1, 1}, -- door
    [4] = {0, 1, 0, 1} -- start
  }

  return newTileSet
end

function TileSet:render(map, toScreen, bounds)
  for y = bounds[4], bounds[2], -1 do
    for x = bounds[1], bounds[3] do
      self:renderTile(map:getTile(x, y), toScreen(x, y))
    end
  end
end

function TileSet:renderTile(id, screenX, screenY)
  if self.tileColors[id] then
    love.graphics.setColor(unpack(self.tileColors[id]))
    love.graphics.rectangle("fill", screenX, screenY, self.tileSize - 1, self.tileSize - 1)
  end
end
