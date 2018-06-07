local util = require 'util'

local surroundings = {
  {-1, 1},
  {0, 1},
  {1, 1},
  {1, 0},
  {1, -1},
  {0, -1},
  {-1, -1},
  {-1, 0}
}

local opposite = {
  N = "S",
  S = "N",
  W = "E",
  E = "W"
}

Map = {}

function Map:new(config)
  local newMap = setmetatable(copy(config), {__index=Map})
  newMap:clear()
  return newMap
end

function Map:inMap(x, y)
  return x >= 1 and y >= 1 and x <= self.size[1] and x <= self.size[2]
end

function Map:setTile(x, y, value)
  self.tiles[(y - 1) * self.size[2] + x] = value
end

function Map:getTile(x, y)
  return self.tiles[(y - 1) * self.size[2] + x]
end

function Map:generate(seed)
  -- initialize random
  love.math.setRandomSeed(seed)

  -- initialize map to null tile
  self:clear(-1)

  -- place outer walls on map borders
  for x = 1, self.size[1] do
    self:setTile(x, 1, 2)
    self:setTile(x, self.size[2], 2)
  end
  for y = 1, self.size[2] do
    self:setTile(1, y, 2)
    self:setTile(self.size[1], y, 2)
  end

  -- generate rooms
  local roomSize = {15, 15}

  local openConnections = {}
  local rooms = {}
  local roomCount = 0
  local targetRoomCount = love.math.random(10, 15)

  local roomCenter = {
    math.floor(roomSize[1] / 2),
    math.floor(roomSize[2] / 2)
  }

  local function connectorOffset(dir)
    if dir == "N" then
      return {roomCenter[1], roomSize[2]}
    elseif dir == "S" then
      return {roomCenter[1], -1}
    elseif dir == "W" then
      return {-1, roomCenter[2]}
    elseif dir == "E" then
      return {roomSize[1], roomCenter[2]}
    end
  end

  function connectorAdjacent(dir)
    if dir == "N" then
      return {roomCenter[1], roomSize[2] - 1}
    elseif dir == "S" then
      return {roomCenter[1], 0}
    elseif dir == "W" then
      return {0, roomCenter[2]}
    elseif dir == "E" then
      return {roomSize[1] - 1, roomCenter[2]}
    end
  end

  local function regionEmpty(xMin, yMin, xMax, yMax)
    for x = xMin, xMax do
      for y = yMin, yMax do
        if not self:inMap(x, y) or self:getTile(x, y) ~= -1 then
          return false
        end
      end
    end
    return true
  end

  local function placeRoom(xPos, yPos, isStart)
    local room = {
      xMin = xPos,
      yMin = yPos,
      xMax = xPos + roomSize[1] - 1,
      yMax = yPos + roomSize[2] - 1,
      connections = {}
    }

    -- mark room area as used
    for x = room.xMin, room.xMax do
      for y = room.yMin, room.yMax do
        self:setTile(x, y, 0)
      end
    end

    if isStart then
      self:setTile(xPos + roomCenter[1], yPos + roomCenter[2], 4)
    end

    roomCount = roomCount + 1
    for dir, _ in pairs(opposite) do
      local offset = connectorOffset(dir)
      table.insert(openConnections, {xPos + offset[1], yPos + offset[2], dir, room})
    end

    table.insert(rooms, room)

    return room
    -- table.insert(openConnections, {xPos - 1, yPos + roomCenter[2], "W", room})
    -- table.insert(openConnections, {xPos + roomSize[1], yPos + roomCenter[2], "E", room})
    -- table.insert(openConnections, {xPos + roomCenter[1], yPos - 1, "S", room})
    -- table.insert(openConnections, {xPos + roomCenter[1], yPos + roomSize[2], "N", room})
  end

  placeRoom(love.math.random(2, self.size[1] - roomSize[1] - 1), love.math.random(2, self.size[2] - roomSize[2] - 1), true)

  while roomCount < targetRoomCount and #openConnections > 0 do
    -- pick connector
    local i = love.math.random(1, #openConnections)
    local conn = openConnections[i]
    table.remove(openConnections, i)

    -- calculate room position
    local offset = connectorOffset(opposite[conn[3]])
    local roomPos = {conn[1] - offset[1], conn[2] - offset[2]}
    -- if conn[3] == "N" then
    --   roomPos = {conn[1] - roomCenter[1], conn[2] + 1}
    -- elseif conn[3] == "S" then
    --   roomPos = {conn[1] - roomCenter[1], conn[2] - roomSize[2]}
    -- elseif conn[3] == "E" then
    --   roomPos = {conn[1] + 1, conn[2] - roomCenter[2]}
    -- elseif conn[3] == "W" then
    --   roomPos = {conn[1] - roomSize[1], conn[2] - roomCenter[2]}
    -- end

    -- check room area
    if regionEmpty(roomPos[1], roomPos[2], roomPos[1] + roomSize[1] - 1, roomPos[2] + roomSize[2] - 1) then
      local newRoom = placeRoom(roomPos[1], roomPos[2])
      self:setTile(conn[1], conn[2], 1)
      conn[4].connections[conn[3]] = newRoom
      newRoom.connections[opposite[conn[3]]] = conn[4]
    end
  end

  -- generate room details
  for _, room in pairs(rooms) do
    -- random walk that hits all connectors
    local toConnect = {}
    for dir, _ in pairs(room.connections) do
      local adjOffset = connectorAdjacent(dir)
      table.insert(toConnect, {room.xMin + adjOffset[1], room.yMin + adjOffset[2]})
    end

    local x = room.xMin + roomCenter[1]
    local y = room.yMin + roomCenter[2]
    while #toConnect > 0 do
      local choice = love.math.random() * 1.15
      local moved = false
      if choice <= 0.25 and x > room.xMin then
        x = x - 1
        moved = true
      elseif choice <= 0.5 and x < room.xMax then
        x = x + 1
        moved = true
      elseif choice <= 0.75 and y > room.yMin then
        y = y - 1
        moved = true
      elseif choice <= 1 and y < room.yMax then
        y = y + 1
        moved = true
      else
        -- move directly toward next connector
        local target = toConnect[1]
        local dirChoice = love.math.random()
        if (dirChoice < 0.5 or x == target[1]) and y ~= target[2] then
          if y < target[2] then
            y = y + 1
          else
            y = y - 1
          end
        else
          if x < target[1] then
            x = x + 1
          else
            x = x - 1
          end
        end
        moved = true
      end

      if moved then
        self:setTile(x, y, 1)
        for i, pos in ipairs(toConnect) do
          if x == pos[1] and y == pos[2] then
            table.remove(toConnect, i)
          end
        end
      end
    end
  end

  -- expand walls around floors
  for x = 1, self.size[1] do
    for y = 1, self.size[2] do
      if self:getTile(x, y) == 1 then
        for _, offset in pairs(surroundings) do
          local sX, sY = x + offset[1], y + offset[2]
          if self:inMap(sX, sY) then
            local current = self:getTile(x + offset[1], y + offset[2])
            if current == -1 or current == 0 then
              self:setTile(sX, sY, 2)
            end
          end
        end
      end
    end
  end
end

function Map:clear(emptyTile)
  self.tiles = {}
  emptyTile = emptyTile or 1
  for x = 1, self.size[1] do
    for y = 1, self.size[2] do
      self:setTile(x, y, emptyTile)
    end
  end
end
