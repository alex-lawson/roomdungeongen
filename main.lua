require "game"

WindowSize = {820, 835}
MapScreenPos = {10, 10}
MapSize = {100, 100}
MapSeed = 0

function love.load()
  love.window.setMode(unpack(WindowSize))
  love.window.setTitle("Dungeon Generator Scratchproject")

  GuiFont = love.graphics.newFont("cour.ttf", 16)

  game = Game:new({
      mapSize = MapSize
    })

  game:generateMap(MapSeed)

  love.graphics.setBackgroundColor(0.05, 0.05, 0.05, 1)
end

function love.update(dt)
  game:update(dt)
end

function love.draw()
  game:renderMap(MapScreenPos)

  love.graphics.setFont(GuiFont)
  love.graphics.print(string.format("Seed: %d", MapSeed), 15, 813)
end

function love.mousepressed(x, y, button)

end

function love.mousereleased(x, y, button)

end

function love.keypressed(key)
  if key == "space" then
    MapSeed = math.random(1, 2^53 - 1)
    game:generateMap(MapSeed)
  end
end

function love.keyreleased(key)

end

function love.focus(f)

end

function love.quit()

end

