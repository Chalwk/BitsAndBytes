-- BitsAndBytes - Computer Themed Game
-- License: MIT
-- Copyright (c) 2025 Jericho Crosby (Chalwk)

local ipairs = ipairs
local math_floor = math.floor
local math_random = math.random
local math_abs = math.abs
local math_min = math.min
local math_cos = math.cos
local math_sin = math.sin
local math_pi = math.pi
local table_insert = table.insert
local table_remove = table.remove

local Game = {}
Game.__index = Game

function Game.new()
    local instance = setmetatable({}, Game)

    instance.screenWidth = 800
    instance.screenHeight = 600
    instance.cellSize = 20
    instance.mazeWidth = 25
    instance.mazeHeight = 25
    instance.maze = {}
    instance.dataBits = {}
    instance.powerCores = {}
    instance.specialItems = {}
    instance.viruses = {}
    instance.bitRunner = {}
    instance.gameOver = false
    instance.gameWon = false
    instance.score = 0
    instance.lives = 3
    instance.level = 1
    instance.firewallMode = false
    instance.firewallTimer = 0
    instance.firewallDuration = 10
    instance.animations = {}
    instance.particles = {}
    instance.difficulty = "normal"
    instance.gameMode = "classic"

    instance.fonts = {
        small = love.graphics.newFont(12),
        medium = love.graphics.newFont(16),
        large = love.graphics.newFont(24),
        veryLarge = love.graphics.newFont(48)
    }

    return instance
end

function Game:setScreenSize(width, height)
    self.screenWidth = width
    self.screenHeight = height
    self:calculateCellSize()
end

function Game:calculateCellSize()
    local maxWidth = self.screenWidth * 0.8
    local maxHeight = self.screenHeight * 0.7
    self.cellSize = math_floor(math_min(maxWidth / self.mazeWidth, maxHeight / self.mazeHeight))
    self.boardX = (self.screenWidth - self.cellSize * self.mazeWidth) / 2
    self.boardY = (self.screenHeight - self.cellSize * self.mazeHeight) / 2 + 20
end

function Game:generateMaze()
    -- Initialize maze with circuit walls
    self.maze = {}
    for x = 1, self.mazeWidth do
        self.maze[x] = {}
        for y = 1, self.mazeHeight do
            self.maze[x][y] = 1 -- 1 = circuit wall, 0 = data path
        end
    end

    -- Use recursive backtracking to generate maze
    local function carvePassage(x, y)
        self.maze[x][y] = 0

        local directions = {
            { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 }
        }

        -- Shuffle directions
        for i = 4, 2, -1 do
            local j = math_random(1, i)
            directions[i], directions[j] = directions[j], directions[i]
        end

        for _, dir in ipairs(directions) do
            local nx, ny = x + dir[1] * 2, y + dir[2] * 2
            if nx >= 1 and nx <= self.mazeWidth and ny >= 1 and ny <= self.mazeHeight and self.maze[nx][ny] == 1 then
                self.maze[x + dir[1]][y + dir[2]] = 0
                carvePassage(nx, ny)
            end
        end
    end

    -- Start from a random even position
    local startX, startY = 2, 2
    if startX % 2 == 0 then startX = startX + 1 end
    if startY % 2 == 0 then startY = startY + 1 end
    carvePassage(startX, startY)

    -- Create entrance and exit
    self.maze[2][1] = 0
    self.maze[self.mazeWidth - 1][self.mazeHeight] = 0

    -- Ensure minimum path width and add some open areas
    self:improveMaze()
end

function Game:improveMaze()
    -- Add some open areas and ensure connectivity
    for i = 1, 5 do
        local x = math_random(3, self.mazeWidth - 2)
        local y = math_random(3, self.mazeHeight - 2)
        for dx = -1, 1 do
            for dy = -1, 1 do
                local nx, ny = x + dx, y + dy
                if nx >= 1 and nx <= self.mazeWidth and ny >= 1 and ny <= self.mazeHeight then
                    self.maze[nx][ny] = 0
                end
            end
        end
    end
end

function Game:placeGameElements()
    self.dataBits = {}
    self.powerCores = {}
    self.specialItems = {}

    -- Place data bits in accessible areas
    for x = 1, self.mazeWidth do
        for y = 1, self.mazeHeight do
            if self.maze[x][y] == 0 then
                -- Data bits (regular collectibles)
                if math_random() > 0.3 then -- 70% chance for data bit
                    table_insert(self.dataBits, { x = x, y = y, collected = false })
                end

                -- Power cores (less frequent)
                if math_random() > 0.95 then -- 5% chance for power core
                    table_insert(self.powerCores, { x = x, y = y, collected = false })
                end

                -- Special items (very rare)
                if math_random() > 0.98 then -- 2% chance for special item
                    table_insert(self.specialItems, {
                        x = x,
                        y = y,
                        type = math_random(1, 3), -- 1: Speed, 2: Extra Life, 3: Score Multiplier
                        collected = false
                    })
                end
            end
        end
    end

    -- Place bit runner at start position
    self.bitRunner = {
        x = 2,
        y = 2,
        direction = "right",
        nextDirection = "right",
        processorAngle = 0,
        processorSpeed = 8,
        size = self.cellSize * 0.4,
        value = 0 -- Binary value that changes
    }

    -- Place viruses
    self:placeViruses()
end

function Game:placeViruses()
    self.viruses = {}
    local virusColors = {
        { 1,   0.2, 0.2 }, -- Red virus
        { 0.2, 1,   1 },   -- Cyan virus
        { 1,   0.2, 1 },   -- Magenta virus
        { 1,   0.6, 0.2 }  -- Orange virus
    }

    local virusNames = { "Trojan", "Worm", "Spyware", "Ransomware" }
    local virusBehaviors = { "replicate", "spread", "corrupt", "encrypt" }

    for i = 1, 4 do
        -- Find a suitable position away from bit runner
        local vx, vy
        repeat
            vx = math_random(5, self.mazeWidth - 4)
            vy = math_random(5, self.mazeHeight - 4)
        until self.maze[vx][vy] == 0 and math_abs(vx - self.bitRunner.x) + math_abs(vy - self.bitRunner.y) > 10

        table_insert(self.viruses, {
            x = vx,
            y = vy,
            color = virusColors[i],
            name = virusNames[i],
            behavior = virusBehaviors[i],
            speed = math_random(20, 30) * 0.01,
            encrypted = false,
            direction = "right",
            size = self.cellSize * 0.35,
            spikes = i -- Number of spikes for visual variety
        })
    end
end

function Game:startNewGame(difficulty, gameMode)
    self.difficulty = difficulty or "normal"
    self.gameMode = gameMode or "classic"

    -- Adjust maze size based on difficulty
    if self.difficulty == "easy" then
        self.mazeWidth = 20
        self.mazeHeight = 20
    elseif self.difficulty == "normal" then
        self.mazeWidth = 25
        self.mazeHeight = 25
    else -- hard
        self.mazeWidth = 30
        self.mazeHeight = 30
    end

    self:calculateCellSize()
    self:generateMaze()
    self:placeGameElements()

    self.gameOver = false
    self.gameWon = false
    self.score = 0
    self.lives = 3
    self.level = 1
    self.firewallMode = false
    self.firewallTimer = 0
    self.animations = {}
    self.particles = {}
end

function Game:resetGame()
    self:startNewGame(self.difficulty, self.gameMode)
end

function Game:update(dt)
    if self.gameOver then return end

    -- Update bit runner animation and binary value
    self.bitRunner.processorAngle = (self.bitRunner.processorAngle + dt * self.bitRunner.processorSpeed) % (math_pi * 2)
    self.bitRunner.value = love.timer.getTime() % 2 > 1 and 1 or 0 -- Alternating 0/1

    -- Update firewall mode timer
    if self.firewallMode then
        self.firewallTimer = self.firewallTimer - dt
        if self.firewallTimer <= 0 then
            self.firewallMode = false
            for _, virus in ipairs(self.viruses) do
                virus.encrypted = false
            end
        end
    end

    -- Move bit runner
    self:moveBitRunner(dt)

    -- Move viruses
    self:moveViruses(dt)

    -- Check collisions
    self:checkCollisions()

    -- Update animations
    for i = #self.animations, 1, -1 do
        local anim = self.animations[i]
        anim.timer = anim.timer - dt
        if anim.timer <= 0 then
            table_remove(self.animations, i)
        end
    end

    -- Update particles
    for i = #self.particles, 1, -1 do
        local particle = self.particles[i]
        particle.life = particle.life - dt
        particle.x = particle.x + particle.dx * dt
        particle.y = particle.y + particle.dy * dt

        if particle.life <= 0 then
            table_remove(self.particles, i)
        end
    end

    -- Check win condition
    if #self.dataBits == 0 and #self.powerCores == 0 then
        self.gameWon = true
        self.gameOver = true
        self:createParticles(self.bitRunner.x, self.bitRunner.y, { 0, 1, 0 }, 20)
    end
end

function Game:moveBitRunner(dt)
    -- Store previous position for collision recovery
    local prevX, prevY = self.bitRunner.x, self.bitRunner.y

    -- Try to change direction if there's a next direction queued
    if self.bitRunner.nextDirection ~= self.bitRunner.direction then
        local canChange = self:canMove(self.bitRunner.x, self.bitRunner.y, self.bitRunner.nextDirection)
        if canChange then
            self.bitRunner.direction = self.bitRunner.nextDirection
        end
    end

    -- Move in current direction
    local speed = self.firewallMode and 1.5 or 1.0
    local moveAmount = speed * dt * 3

    if self.bitRunner.direction == "right" then
        self.bitRunner.x = self.bitRunner.x + moveAmount
    elseif self.bitRunner.direction == "left" then
        self.bitRunner.x = self.bitRunner.x - moveAmount
    elseif self.bitRunner.direction == "up" then
        self.bitRunner.y = self.bitRunner.y - moveAmount
    elseif self.bitRunner.direction == "down" then
        self.bitRunner.y = self.bitRunner.y + moveAmount
    end

    -- Check wall collisions and correct position
    local cellX, cellY = self:getCellCoordinates(self.bitRunner.x, self.bitRunner.y)

    -- If we're in a wall, move back to previous position
    if cellX >= 1 and cellX <= self.mazeWidth and cellY >= 1 and cellY <= self.mazeHeight then
        if self.maze[cellX] and self.maze[cellX][cellY] == 1 then
            self.bitRunner.x, self.bitRunner.y = prevX, prevY
        end
    end

    -- Wrap around edges (only through designated tunnels)
    if cellX < 1 then
        -- Check if this is a valid tunnel
        local entranceY = math_floor(self.bitRunner.y + 0.5)
        if entranceY == 1 and self.maze[1] and self.maze[1][entranceY] == 0 then
            self.bitRunner.x = self.mazeWidth
        else
            self.bitRunner.x = prevX
        end
    elseif cellX > self.mazeWidth then
        local exitY = math_floor(self.bitRunner.y + 0.5)
        if exitY == self.mazeHeight and self.maze[self.mazeWidth] and self.maze[self.mazeWidth][exitY] == 0 then
            self.bitRunner.x = 1
        else
            self.bitRunner.x = prevX
        end
    end

    -- Snap to grid for better collision detection
    self:snapToGrid()
end

function Game:moveViruses(dt)
    for _, virus in ipairs(self.viruses) do
        local speed = virus.speed * (virus.encrypted and 0.7 or 1.0)
        local moveAmount = speed * dt * 2

        -- Better AI for virus movement
        if math_random() < 0.05 then -- 5% chance to change direction each frame
            local directions = {}
            local possibleDirs = { "right", "left", "up", "down" }

            -- Check which directions are valid
            for _, dir in ipairs(possibleDirs) do
                if self:canMove(virus.x, virus.y, dir) then
                    table_insert(directions, dir)
                end
            end

            -- Only change direction if there are valid options
            if #directions > 0 then
                virus.direction = directions[math_random(1, #directions)]
            end
        end

        -- Try to move in current direction
        local newX, newY = virus.x, virus.y
        if virus.direction == "right" then
            newX = newX + moveAmount
        elseif virus.direction == "left" then
            newX = newX - moveAmount
        elseif virus.direction == "up" then
            newY = newY - moveAmount
        elseif virus.direction == "down" then
            newY = newY + moveAmount
        end

        -- Check if movement is valid
        local cellX, cellY = self:getCellCoordinates(newX, newY)
        if cellX >= 1 and cellX <= self.mazeWidth and cellY >= 1 and cellY <= self.mazeHeight and
            self.maze[cellX] and self.maze[cellX][cellY] == 0 then
            virus.x, virus.y = newX, newY
        else
            -- Hit a wall or boundary, choose a new valid direction
            local directions = {}
            local possibleDirs = { "right", "left", "up", "down" }

            for _, dir in ipairs(possibleDirs) do
                if self:canMove(virus.x, virus.y, dir) then
                    table_insert(directions, dir)
                end
            end

            if #directions > 0 then
                virus.direction = directions[math_random(1, #directions)]
            end
        end

        -- Keep viruses within bounds (no wrapping)
        virus.x = math.max(1, math.min(self.mazeWidth, virus.x))
        virus.y = math.max(1, math.min(self.mazeHeight, virus.y))
    end
end

function Game:canMove(x, y, direction)
    local cellX, cellY = self:getCellCoordinates(x, y)
    local checkX, checkY = cellX, cellY

    if direction == "right" then
        checkX = checkX + 1
    elseif direction == "left" then
        checkX = checkX - 1
    elseif direction == "up" then
        checkY = checkY - 1
    elseif direction == "down" then
        checkY = checkY + 1
    end

    -- Boundary check
    if checkX < 1 or checkX > self.mazeWidth or checkY < 1 or checkY > self.mazeHeight then
        return false
    end

    return self.maze[checkX] and self.maze[checkX][checkY] == 0
end

function Game:snapToGrid()
    local cellX, cellY = self:getCellCoordinates(self.bitRunner.x, self.bitRunner.y)

    -- Only snap if we're very close to center (allows for direction changes)
    local centerX, centerY = self:getCellCenter(cellX, cellY)
    local distX = math_abs(self.bitRunner.x - centerX)
    local distY = math_abs(self.bitRunner.y - centerY)

    if distX < 0.1 and distY < 0.1 then
        self.bitRunner.x, self.bitRunner.y = centerX, centerY
    end
end

function Game:getCellCoordinates(x, y)
    return math_floor(x + 0.5), math_floor(y + 0.5)
end

function Game:getCellCenter(cellX, cellY)
    return cellX + 0.5, cellY + 0.5
end

function Game:checkCollisions()
    local runnerCellX, runnerCellY = self:getCellCoordinates(self.bitRunner.x, self.bitRunner.y)

    -- Check data bit collisions
    for i = #self.dataBits, 1, -1 do
        local dataBit = self.dataBits[i]
        if not dataBit.collected and dataBit.x == runnerCellX and dataBit.y == runnerCellY then
            dataBit.collected = true
            self.score = self.score + 10
            self:createParticles(dataBit.x, dataBit.y, { 1, 1, 1 }, 5)
            table_remove(self.dataBits, i)
        end
    end

    -- Check power core collisions
    for i = #self.powerCores, 1, -1 do
        local powerCore = self.powerCores[i]
        if not powerCore.collected and powerCore.x == runnerCellX and powerCore.y == runnerCellY then
            powerCore.collected = true
            self.score = self.score + 50
            self.firewallMode = true
            self.firewallTimer = self.firewallDuration
            for _, virus in ipairs(self.viruses) do
                virus.encrypted = true
            end
            self:createParticles(powerCore.x, powerCore.y, { 1, 0.5, 0 }, 10)
            table_remove(self.powerCores, i)
        end
    end

    -- Check special item collisions
    for i = #self.specialItems, 1, -1 do
        local item = self.specialItems[i]
        if not item.collected and item.x == runnerCellX and item.y == runnerCellY then
            item.collected = true
            self:applySpecialItem(item)
            self:createParticles(item.x, item.y, { 0, 1, 1 }, 15)
            table_remove(self.specialItems, i)
        end
    end

    -- Check virus collisions
    for _, virus in ipairs(self.viruses) do
        local virusCellX, virusCellY = self:getCellCoordinates(virus.x, virus.y)
        if virusCellX == runnerCellX and virusCellY == runnerCellY then
            if virus.encrypted then
                -- Encrypt virus
                self.score = self.score + 200
                virus.encrypted = false
                -- Respawn virus
                repeat
                    virus.x = math_random(5, self.mazeWidth - 4)
                    virus.y = math_random(5, self.mazeHeight - 4)
                until self.maze[virus.x] and self.maze[virus.x][virus.y] == 0
                self:createParticles(virus.x, virus.y, { 1, 1, 0 }, 20)
            else
                -- Lose life
                self.lives = self.lives - 1
                self:createParticles(self.bitRunner.x, self.bitRunner.y, { 1, 0, 0 }, 15)
                if self.lives <= 0 then
                    self.gameOver = true
                else
                    -- Reset positions
                    self.bitRunner.x, self.bitRunner.y = 2, 2
                    self:placeViruses()
                end
            end
        end
    end
end

function Game:applySpecialItem(item)
    if item.type == 1 then
        -- Speed boost
        self.bitRunner.processorSpeed = self.bitRunner.processorSpeed * 1.5
        table_insert(self.animations, {
            type = "speed",
            text = "OVERCLOCKED!",
            timer = 2,
            x = self.bitRunner.x,
            y = self.bitRunner.y
        })
    elseif item.type == 2 then
        -- Extra life
        self.lives = self.lives + 1
        table_insert(self.animations, {
            type = "life",
            text = "SYSTEM BOOT!",
            timer = 2,
            x = self.bitRunner.x,
            y = self.bitRunner.y
        })
    elseif item.type == 3 then
        -- Score multiplier
        self.score = self.score * 2
        table_insert(self.animations, {
            type = "score",
            text = "DATA BONUS!",
            timer = 2,
            x = self.bitRunner.x,
            y = self.bitRunner.y
        })
    end
end

function Game:createParticles(x, y, color, count)
    for _ = 1, count or 8 do
        table_insert(self.particles, {
            x = x,
            y = y,
            dx = (math_random() - 0.5) * 3,
            dy = (math_random() - 0.5) * 3,
            life = math_random(0.5, 1.5),
            color = color,
            size = math_random(1, 3)
        })
    end
end

function Game:handleKeyPress(key)
    if key == "r" then
        self:resetGame()
    elseif key == "right" then
        self.bitRunner.nextDirection = "right"
    elseif key == "left" then
        self.bitRunner.nextDirection = "left"
    elseif key == "up" then
        self.bitRunner.nextDirection = "up"
    elseif key == "down" then
        self.bitRunner.nextDirection = "down"
    end
end

function Game:draw()
    self:drawMaze()
    self:drawDataBits()
    self:drawPowerCores()
    self:drawSpecialItems()
    self:drawViruses()
    self:drawBitRunner()
    self:drawUI()
    self:drawParticles()
    self:drawAnimations()

    if self.gameOver then
        self:drawGameOver()
    end
end

function Game:drawMaze()
    -- Draw maze background
    love.graphics.setColor(0.05, 0.05, 0.15, 0.9)
    love.graphics.rectangle("fill", self.boardX - 10, self.boardY - 10,
        self.cellSize * self.mazeWidth + 20,
        self.cellSize * self.mazeHeight + 20, 5)

    -- Draw circuit walls
    love.graphics.setColor(0.2, 0.3, 0.8)
    for x = 1, self.mazeWidth do
        for y = 1, self.mazeHeight do
            if self.maze[x][y] == 1 then
                local screenX = self.boardX + (x - 1) * self.cellSize
                local screenY = self.boardY + (y - 1) * self.cellSize
                love.graphics.rectangle("fill", screenX, screenY, self.cellSize, self.cellSize)

                -- Add circuit pattern to walls
                love.graphics.setColor(0.3, 0.4, 0.9)
                love.graphics.rectangle("line", screenX + 2, screenY + 2, self.cellSize - 4, self.cellSize - 4)
            end
        end
    end
end

function Game:drawDataBits()
    love.graphics.setColor(0.2, 0.8, 1) -- Cyan for data bits

    local bitFont = love.graphics.newFont(self.cellSize * 0.15)
    love.graphics.setFont(bitFont)

    for _, dataBit in ipairs(self.dataBits) do
        if not dataBit.collected then
            local screenX = self.boardX + (dataBit.x - 0.5) * self.cellSize
            local screenY = self.boardY + (dataBit.y - 0.5) * self.cellSize
            love.graphics.circle("fill", screenX, screenY, self.cellSize * 0.1)

            -- Add binary digit inside
            love.graphics.setColor(1, 1, 1)
            love.graphics.printf(math_random(0, 1), screenX - self.cellSize * 0.1, screenY - self.cellSize * 0.07,
                self.cellSize * 0.2, "center")
            love.graphics.setColor(0.2, 0.8, 1) -- Reset color
        end
    end
end

function Game:drawPowerCores()
    for _, powerCore in ipairs(self.powerCores) do
        if not powerCore.collected then
            local screenX = self.boardX + (powerCore.x - 0.5) * self.cellSize
            local screenY = self.boardY + (powerCore.y - 0.5) * self.cellSize

            -- Pulsing effect
            local pulse = (math_sin(love.timer.getTime() * 8) + 1) * 0.2

            love.graphics.setColor(1, 0.8, 0.2, 0.8 + pulse)
            love.graphics.circle("fill", screenX, screenY, self.cellSize * 0.2)

            -- Inner core
            love.graphics.setColor(1, 1, 0.8, 0.9)
            love.graphics.circle("fill", screenX, screenY, self.cellSize * 0.1)

            -- Circuit pattern
            love.graphics.setColor(0.8, 0.6, 0.1, 0.6)
            for i = 0, 3 do
                local angle = i * math.pi / 2
                love.graphics.line(
                    screenX, screenY,
                    screenX + math.cos(angle) * self.cellSize * 0.15,
                    screenY + math.sin(angle) * self.cellSize * 0.15
                )
            end
        end
    end
end

function Game:drawSpecialItems()
    for _, item in ipairs(self.specialItems) do
        if not item.collected then
            local screenX = self.boardX + (item.x - 0.5) * self.cellSize
            local screenY = self.boardY + (item.y - 0.5) * self.cellSize

            if item.type == 1 then
                love.graphics.setColor(0, 1, 0) -- Green - Speed (Overclock)
                love.graphics.rectangle("fill", screenX - self.cellSize * 0.15, screenY - self.cellSize * 0.15,
                    self.cellSize * 0.3, self.cellSize * 0.3)
            elseif item.type == 2 then
                love.graphics.setColor(1, 1, 1) -- White - Life (System Boot)
                love.graphics.polygon("fill",
                    screenX, screenY - self.cellSize * 0.2,
                    screenX + self.cellSize * 0.15, screenY + self.cellSize * 0.15,
                    screenX - self.cellSize * 0.15, screenY + self.cellSize * 0.15
                )
            elseif item.type == 3 then
                love.graphics.setColor(1, 0, 1) -- Magenta - Score (Data Bonus)
                love.graphics.circle("fill", screenX, screenY, self.cellSize * 0.15)
            end
        end
    end
end

function Game:drawViruses()
    -- Pre-create virus font once
    local virusFont = love.graphics.newFont(self.cellSize * 0.14)
    love.graphics.setFont(virusFont)

    for _, virus in ipairs(self.viruses) do
        local screenX = self.boardX + (virus.x - 0.5) * self.cellSize
        local screenY = self.boardY + (virus.y - 0.5) * self.cellSize

        if virus.encrypted then
            love.graphics.setColor(0.2, 0.2, 1) -- Blue when encrypted
        else
            love.graphics.setColor(virus.color[1], virus.color[2], virus.color[3])
        end

        -- Draw virus body as spiky circle
        love.graphics.circle("fill", screenX, screenY, virus.size)

        -- Draw virus spikes
        local spikeLength = virus.size * 1.2
        for i = 1, virus.spikes + 3 do
            local angle = i * (2 * math_pi / (virus.spikes + 3))
            love.graphics.line(
                screenX, screenY,
                screenX + math_cos(angle) * spikeLength,
                screenY + math_sin(angle) * spikeLength
            )
        end

        -- Draw virus "eyes" as binary
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("10", screenX - virus.size * 0.3, screenY - virus.size * 0.2, virus.size * 0.6, "center")
    end
end

function Game:drawBitRunner()
    local screenX = self.boardX + (self.bitRunner.x - 0.5) * self.cellSize
    local screenY = self.boardY + (self.bitRunner.y - 0.5) * self.cellSize

    love.graphics.setColor(1, 1, 0) -- Yellow for bit runner

    -- Draw the bit runner as a circle with a processor opening
    local processorOpenAngle = math_pi / 4 -- 45 degrees open
    local startAngle, endAngle

    if self.bitRunner.direction == "right" then
        startAngle = processorOpenAngle
        endAngle = 2 * math_pi - processorOpenAngle
    elseif self.bitRunner.direction == "left" then
        startAngle = math_pi + processorOpenAngle
        endAngle = math_pi - processorOpenAngle
    elseif self.bitRunner.direction == "up" then
        startAngle = math_pi * 1.5 + processorOpenAngle
        endAngle = math_pi * 1.5 - processorOpenAngle
    else -- down
        startAngle = math_pi * 0.5 + processorOpenAngle
        endAngle = math_pi * 0.5 - processorOpenAngle
    end

    -- Ensure we're drawing in the correct direction
    if startAngle > endAngle then
        startAngle, endAngle = endAngle, startAngle
    end

    -- Draw the bit runner body
    love.graphics.arc("fill", screenX, screenY, self.bitRunner.size, startAngle, endAngle)

    -- Display current binary value in the center
    love.graphics.setColor(0, 0, 0)

    -- Use pre-created font
    local runnerFont = love.graphics.newFont(self.bitRunner.size * 0.6)
    love.graphics.setFont(runnerFont)

    love.graphics.printf(tostring(self.bitRunner.value),
        screenX - self.bitRunner.size * 0.3,
        screenY - self.bitRunner.size * 0.3,
        self.bitRunner.size * 0.6, "center")
end

function Game:drawUI()
    -- Use pre-created fonts
    love.graphics.setFont(self.fonts.medium)

    -- Score
    love.graphics.setColor(1, 0.8, 0.2)
    love.graphics.print("Data: " .. self.score, 20, 20)

    -- Lives (now "Systems")
    love.graphics.setColor(1, 0.4, 0.4)
    love.graphics.print("Systems: " .. self.lives, 20, 50)

    -- Level
    love.graphics.setColor(0.4, 0.8, 1)
    love.graphics.print("Network: " .. self.level, 20, 80)

    -- Firewall mode indicator
    if self.firewallMode then
        love.graphics.setColor(0.2, 0.8, 1)
        love.graphics.print("FIREWALL: " .. math_floor(self.firewallTimer * 10) / 10 .. "s", 20, 110)
    end

    -- Game mode and difficulty
    love.graphics.setColor(1, 1, 1, 0.7)
    love.graphics.setFont(self.fonts.small)
    love.graphics.print("Protocol: " .. self.gameMode, 20, 140)
    love.graphics.print("Security: " .. self.difficulty, 20, 160)

    -- Controls
    love.graphics.print("Arrow Keys: Navigate", 20, self.screenHeight - 90)
    love.graphics.print("R: Reset System", 20, self.screenHeight - 70)
    love.graphics.print("ESC: Main Menu", 20, self.screenHeight - 50)
end

function Game:drawParticles()
    for _, particle in ipairs(self.particles) do
        local alpha = math_min(1, particle.life * 2)
        love.graphics.setColor(particle.color[1], particle.color[2], particle.color[3], alpha)
        love.graphics.circle("fill",
            self.boardX + (particle.x - 0.5) * self.cellSize,
            self.boardY + (particle.y - 0.5) * self.cellSize,
            particle.size
        )
    end
end

function Game:drawAnimations()
    for _, anim in ipairs(self.animations) do
        local screenX = self.boardX + (anim.x - 0.5) * self.cellSize
        local screenY = self.boardY + (anim.y - 0.5) * self.cellSize - anim.timer * 20

        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(love.graphics.newFont(14))
        love.graphics.print(anim.text, screenX - 30, screenY)
    end
end

function Game:drawGameOver()
    -- Semi-transparent overlay
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, self.screenWidth, self.screenHeight)

    local font = love.graphics.newFont(48)
    love.graphics.setFont(font)

    if self.gameWon then
        love.graphics.setColor(0.2, 1, 0.2)
        love.graphics.printf("SYSTEM SECURE!", 0, self.screenHeight / 2 - 80, self.screenWidth, "center")
        love.graphics.setFont(love.graphics.newFont(24))
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Data Processed: " .. self.score, 0, self.screenHeight / 2 - 20, self.screenWidth, "center")
    else
        love.graphics.setColor(1, 0.4, 0.4)
        love.graphics.printf("SYSTEM FAILURE", 0, self.screenHeight / 2 - 80, self.screenWidth, "center")
        love.graphics.setFont(love.graphics.newFont(24))
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Data Lost: " .. self.score, 0, self.screenHeight / 2 - 20, self.screenWidth, "center")
    end

    love.graphics.setFont(love.graphics.newFont(20))
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Click to return to main menu", 0, self.screenHeight / 2 + 20, self.screenWidth, "center")
end

function Game:isGameOver()
    return self.gameOver
end

return Game
