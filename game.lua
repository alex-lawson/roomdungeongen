require 'util'
require 'map'
require 'tileset_shape'

Game = {}

function Game:new(config)
  local newGame = setmetatable(copy(config), {__index=Game})

  newGame.map = Map:new({
      size = newGame.mapSize
    })

  newGame.tileSet = TileSet:new({
      tileSize = 8
    })

  return newGame
end

function Game:update(dt)

end

function Game:generateMap(seed)
  self.map:generate(seed)
end

function Game:renderMap(screenPosition)
  local bounds = {1, 1, self.map.size[1], self.map.size[2]}

  local mapToScreen = function(x, y)
    local screenX = screenPosition[1] + (x - 1) * self.tileSet.tileSize
    local screenY = screenPosition[2] + (bounds[4] - y) * self.tileSet.tileSize
    return screenX, screenY
  end

  self.tileSet:render(self.map, mapToScreen, bounds)
end
