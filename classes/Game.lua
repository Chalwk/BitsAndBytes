local ipairs = ipairs
local math_min = math.min
local math_sin = math.sin
local math_cos = math.cos
local math_abs = math.abs
local math_max = math.max
local math_pi = math.pi
local math_floor = math.floor
local math_random = math.random
local table_insert = table.insert
local table_remove = table.remove

local Game = {}
Game.__index = Game

function Game.new()
    local instance = setmetatable({}, Game)

    instance.screenWidth = 1000
    instance.screenHeight = 700
    instance.mazeSize = 15
    instance.cellSize = 40
    instance.maze = {}
    instance.player = {x = 1, y = 1}
    instance.exit = {x = 1, y = 1}
    instance.gameOver = false
    instance.gameWon = false
    instance.holdToMove = false
    instance.difficulty = "medium"
    instance.theme = "retro"
    instance.animations = {}
    instance.particles = {}
    instance.bits = {}
    instance.powerups = {}
    instance.viruses = {}
    instance.firewalls = {}
    instance.dataPackets = {}
    instance.invincible = false
    instance.invincibleTimer = 0
    instance.score = 0
    instance.lives = 3
    instance.powerupActive = nil
    instance.powerupTimer = 0
    instance.startTime = 0
    instance.elapsedTime = 0
    instance.bitsCollected = 0
    instance.totalBits = 0

    instance.powerupTypes = {
        {name = "Firewall", color = {1, 0.5, 0}, duration = 5, effect = "scare"},
        {name = "Encryption", color = {0, 1, 1}, duration = 8, effect = "slow"},
        {name = "Antivirus", color = {0, 1, 0}, duration = 6, effect = "kill"},
        {name = "Overclock", color = {1, 0, 1}, duration = 4, effect = "speed"}
    }

    instance:generateMaze()
    return instance
end

function Game:setScreenSize(width, height)
    self.screenWidth = width
    self.screenHeight = height
    self:calculateCellSize()
end

function Game:calculateCellSize()
    local maxSize = math_min(self.screenWidth, self.screenHeight) * 0.85
    self.cellSize = math_floor(maxSize / self.mazeSize)
    self.mazeX = (self.screenWidth - self.cellSize * self.mazeSize) / 2
    self.mazeY = (self.screenHeight - self.cellSize * self.mazeSize) / 2 + 30
end

function Game:generateMaze()
    self.maze = {}
    for i = 1, self.mazeSize do
        self.maze[i] = {}
        for j = 1, self.mazeSize do
            self.maze[i][j] = {
                walls = {top = true, right = true, bottom = true, left = true},
                visited = false,
                path = false,
                bit = math_random() < 0.7,
                powerup = math_random() < 0.1,
                firewall = math_random() < 0.05
            }
        end
    end

    self:carvePassages(1, 1)
    self.player = {x = 1, y = 1}
    self.exit = {x = self.mazeSize, y = self.mazeSize}
    self.maze[self.exit.y][self.exit.x].exit = true

    self:generateBits()
    self:generatePowerups()
    self:generateViruses()
    self:generateFirewalls()
    self:generateDataPackets()
end

function Game:carvePassages(x, y)
    self.maze[y][x].visited = true
    self.maze[y][x].path = true

    local directions = {
        {dx = 0, dy = -1, wall = "top", opposite = "bottom"},
        {dx = 1, dy = 0, wall = "right", opposite = "left"},
        {dx = 0, dy = 1, wall = "bottom", opposite = "top"},
        {dx = -1, dy = 0, wall = "left", opposite = "right"}
    }

    for i = #directions, 2, -1 do
        local j = math_random(1, i)
        directions[i], directions[j] = directions[j], directions[i]
    end

    for _, dir in ipairs(directions) do
        local nx, ny = x + dir.dx, y + dir.dy
        if nx >= 1 and nx <= self.mazeSize and ny >= 1 and ny <= self.mazeSize and not self.maze[ny][nx].visited then
            self.maze[y][x].walls[dir.wall] = false
            self.maze[ny][nx].walls[dir.opposite] = false
            self:carvePassages(nx, ny)
        end
    end
end

function Game:generateBits()
    self.bits = {}
    self.totalBits = 0
    for y = 1, self.mazeSize do
        for x = 1, self.mazeSize do
            if self.maze[y][x].path and self.maze[y][x].bit and not (x == 1 and y == 1) then
                table_insert(self.bits, {x = x, y = y, collected = false})
                self.totalBits = self.totalBits + 1
            end
        end
    end
end

function Game:generatePowerups()
    self.powerups = {}
    local powerupCount = math_floor(self.mazeSize * 0.3)

    for i = 1, powerupCount do
        local x, y = math_random(2, self.mazeSize - 1), math_random(2, self.mazeSize - 1)
        if self.maze[y][x].path and not (x == 1 and y == 1) then
            local powerupType = self.powerupTypes[math_random(1, #self.powerupTypes)]
            table_insert(self.powerups, {
                x = x,
                y = y,
                collected = false,
                type = powerupType,
                color = powerupType.color
            })
        end
    end
end

function Game:generateViruses()
    self.viruses = {}
    local virusCount = math_floor(self.mazeSize * 0.4)

    for i = 1, virusCount do
        local x, y = math_random(2, self.mazeSize - 1), math_random(2, self.mazeSize - 1)
        if self.maze[y][x].path then
            table_insert(self.viruses, {
                x = x,
                y = y,
                speed = math_random(0.8, 2.5),
                angle = math_random() * math_pi * 2,
                color = {math_random(0.8, 1), math_random(0.2, 0.4), math_random(0.2, 0.4)},
                size = math_random(0.8, 1.3),
                pulse = 0,
                scared = false,
                moveTimer = 0
            })
        end
    end
end

function Game:generateFirewalls()
    self.firewalls = {}
    local firewallCount = math_floor(self.mazeSize * 0.2)

    for i = 1, firewallCount do
        local x, y = math_random(1, self.mazeSize), math_random(1, self.mazeSize)
        if not self.maze[y][x].path then
            table_insert(self.firewalls, {
                x = x,
                y = y,
                active = true,
                pulse = 0
            })
        end
    end
end

function Game:generateDataPackets()
    self.dataPackets = {}
    local packetCount = math_floor(self.mazeSize * 0.15)

    for i = 1, packetCount do
        local x, y = math_random(2, self.mazeSize - 1), math_random(2, self.mazeSize - 1)
        if self.maze[y][x].path then
            table_insert(self.dataPackets, {
                x = x,
                y = y,
                collected = false,
                value = math_random(50, 200),
                rotation = math_random() * math_pi * 2
            })
        end
    end
end

function Game:startNewGame(difficulty, theme)
    self.difficulty = difficulty or "medium"
    self.theme = theme or "retro"

    if self.difficulty == "easy" then
        self.mazeSize = 12
        self.lives = 5
    elseif self.difficulty == "medium" then
        self.mazeSize = 18
        self.lives = 3
    else
        self.mazeSize = 24
        self.lives = 2
    end

    if self.theme == "cyber" then
        self.playerColor = {0, 1, 1}
        self.pathColor = {0.1, 0.3, 0.6}
        self.wallColor = {0.3, 0.8, 1}
    elseif self.theme == "matrix" then
        self.playerColor = {0, 1, 0}
        self.pathColor = {0, 0.2, 0}
        self.wallColor = {0.1, 0.8, 0.1}
    else
        self.playerColor = {1, 0.5, 0}
        self.pathColor = {0.4, 0.2, 0.6}
        self.wallColor = {1, 0.8, 0.2}
    end

    self:calculateCellSize()
    self:generateMaze()
    self.gameOver = false
    self.gameWon = false
    self.score = 0
    self.bitsCollected = 0
    self.invincible = false
    self.invincibleTimer = 0
    self.powerupActive = nil
    self.powerupTimer = 0
    self.startTime = love.timer.getTime()
    self.elapsedTime = 0
end

function Game:setHoldToMove(enabled)
    self.holdToMove = enabled
end

function Game:toggleHoldToMove()
    self.holdToMove = not self.holdToMove
end

function Game:getHoldToMove()
    return self.holdToMove
end

function Game:toggleInvincibility()
    self.invincible = not self.invincible
    self.invincibleTimer = 3
end

function Game:resetGame()
    self:startNewGame(self.difficulty, self.theme)
end

function Game:movePlayer(dx, dy)
    if self.gameOver then return end

    local newX, newY = self.player.x + dx, self.player.y + dy

    if newX >= 1 and newX <= self.mazeSize and newY >= 1 and newY <= self.mazeSize then
        local cell = self.maze[self.player.y][self.player.x]
        local newCell = self.maze[newY][newX]

        if (dx == 1 and not cell.walls.right) or
           (dx == -1 and not cell.walls.left) or
           (dy == 1 and not cell.walls.bottom) or
           (dy == -1 and not cell.walls.top) then

            self.player.x, self.player.y = newX, newY

            self:createParticles(
                self.mazeX + (self.player.x - 0.5) * self.cellSize,
                self.mazeY + (self.player.y - 0.5) * self.cellSize,
                self.playerColor, 2
            )

            self:checkBits()
            self:checkPowerups()
            self:checkDataPackets()
            self:checkViruses()

            if self.player.x == self.exit.x and self.player.y == self.exit.y and self.bitsCollected >= self.totalBits then
                self.gameOver = true
                self.gameWon = true
                self.score = self.score + math_floor(1000 / self.elapsedTime)
                self:createWinParticles()
            end
        end
    end
end

function Game:usePowerup()
    if self.powerupActive then
        self:activatePowerup(self.powerupActive)
        self.powerupActive = nil
    end
end

function Game:activatePowerup(powerup)
    local effect = powerup.type.effect
    
    if effect == "scare" then
        for _, virus in ipairs(self.viruses) do
            virus.scared = true
            virus.color = {0.5, 0.5, 1}
        end
        table_insert(self.animations, {
            type = "powerup",
            text = "FIREWALL ACTIVATED!",
            progress = 0,
            duration = 3
        })
    elseif effect == "slow" then
        for _, virus in ipairs(self.viruses) do
            virus.speed = virus.speed * 0.5
        end
        table_insert(self.animations, {
            type = "powerup",
            text = "ENCRYPTION ACTIVE!",
            progress = 0,
            duration = 3
        })
    elseif effect == "kill" then
        for i = #self.viruses, 1, -1 do
            local virus = self.viruses[i]
            if math_random() < 0.3 then
                self.score = self.score + 100
                table_remove(self.viruses, i)
            end
        end
        table_insert(self.animations, {
            type = "powerup",
            text = "ANTIVIRUS SCAN!",
            progress = 0,
            duration = 3
        })
    elseif effect == "speed" then
        self.invincible = true
        self.invincibleTimer = powerup.type.duration
        table_insert(self.animations, {
            type = "powerup",
            text = "OVERCLOCKED!",
            progress = 0,
            duration = 3
        })
    end
    
    self.powerupTimer = powerup.type.duration
end

function Game:checkBits()
    for _, bit in ipairs(self.bits) do
        if not bit.collected and bit.x == self.player.x and bit.y == self.player.y then
            bit.collected = true
            self.bitsCollected = self.bitsCollected + 1
            self.score = self.score + 10
            self:createParticles(
                self.mazeX + (bit.x - 0.5) * self.cellSize,
                self.mazeY + (bit.y - 0.5) * self.cellSize,
                {1, 1, 0}, 4
            )
        end
    end
end

function Game:checkPowerups()
    for _, powerup in ipairs(self.powerups) do
        if not powerup.collected and powerup.x == self.player.x and powerup.y == self.player.y then
            powerup.collected = true
            self.powerupActive = powerup
            self:createParticles(
                self.mazeX + (powerup.x - 0.5) * self.cellSize,
                self.mazeY + (powerup.y - 0.5) * self.cellSize,
                powerup.color, 8
            )
        end
    end
end

function Game:checkDataPackets()
    for _, packet in ipairs(self.dataPackets) do
        if not packet.collected and packet.x == self.player.x and packet.y == self.player.y then
            packet.collected = true
            self.score = self.score + packet.value
            table_insert(self.animations, {
                type = "score",
                text = "+" .. packet.value,
                x = self.mazeX + (packet.x - 0.5) * self.cellSize,
                y = self.mazeY + (packet.y - 0.5) * self.cellSize,
                progress = 0,
                duration = 2
            })
            self:createParticles(
                self.mazeX + (packet.x - 0.5) * self.cellSize,
                self.mazeY + (packet.y - 0.5) * self.cellSize,
                {1, 0.8, 0.2}, 6
            )
        end
    end
end

function Game:checkViruses()
    if self.invincible then return end

    for _, virus in ipairs(self.viruses) do
        if virus.x == self.player.x and virus.y == self.player.y then
            self.lives = self.lives - 1
            if self.lives <= 0 then
                self.gameOver = true
                self.gameWon = false
            else
                self.player = {x = 1, y = 1}
                self.invincible = true
                self.invincibleTimer = 2
            end
            break
        end
    end
end

function Game:update(dt)
    self.elapsedTime = love.timer.getTime() - self.startTime

    for i = #self.animations, 1, -1 do
        local anim = self.animations[i]
        anim.progress = anim.progress + dt / anim.duration
        if anim.progress >= 1 then
            table_remove(self.animations, i)
        end
    end

    for i = #self.particles, 1, -1 do
        local particle = self.particles[i]
        particle.life = particle.life - dt
        particle.x = particle.x + particle.dx * dt
        particle.y = particle.y + particle.dy * dt
        particle.rotation = particle.rotation + particle.dr * dt

        if particle.life <= 0 then
            table_remove(self.particles, i)
        end
    end

    for _, virus in ipairs(self.viruses) do
        virus.pulse = virus.pulse + dt * 3
        virus.moveTimer = virus.moveTimer - dt
        
        if virus.moveTimer <= 0 then
            local directions = {{0,-1},{1,0},{0,1},{-1,0}}
            local dir = directions[math_random(1,4)]
            local newX, newY = virus.x + dir[1], virus.y + dir[2]
            
            if newX >= 1 and newX <= self.mazeSize and newY >= 1 and newY <= self.mazeSize then
                local cell = self.maze[virus.y][virus.x]
                if (dir[1] == 1 and not cell.walls.right) or
                   (dir[1] == -1 and not cell.walls.left) or
                   (dir[2] == 1 and not cell.walls.bottom) or
                   (dir[2] == -1 and not cell.walls.top) then
                    virus.x, virus.y = newX, newY
                end
            end
            
            virus.moveTimer = 1 / virus.speed
        end
    end

    for _, firewall in ipairs(self.firewalls) do
        firewall.pulse = firewall.pulse + dt * 2
    end

    for _, packet in ipairs(self.dataPackets) do
        packet.rotation = packet.rotation + dt * 2
    end

    if self.invincible then
        self.invincibleTimer = self.invincibleTimer - dt
        if self.invincibleTimer <= 0 then
            self.invincible = false
        end
    end

    if self.powerupTimer > 0 then
        self.powerupTimer = self.powerupTimer - dt
        if self.powerupTimer <= 0 then
            for _, virus in ipairs(self.viruses) do
                virus.scared = false
                virus.color = {math_random(0.8, 1), math_random(0.2, 0.4), math_random(0.2, 0.4)}
                virus.speed = math_random(0.8, 2.5)
            end
        end
    end
end

function Game:createParticles(x, y, color, count)
    for _ = 1, count or 6 do
        table_insert(self.particles, {
            x = x,
            y = y,
            dx = (math_random() - 0.5) * 60,
            dy = (math_random() - 0.5) * 60,
            dr = (math_random() - 0.5) * 6,
            life = math_random(0.8, 1.5),
            color = color,
            size = math_random(2, 6),
            rotation = math_random() * math_pi * 2
        })
    end
end

function Game:createWinParticles()
    for i = 1, 20 do
        local x = self.mazeX + (self.exit.x - 0.5) * self.cellSize
        local y = self.mazeY + (self.exit.y - 0.5) * self.cellSize
        self:createParticles(x, y, {0.2, 1, 0.2}, 1)
    end
end

function Game:draw()
    self:drawMaze()
    self:drawBits()
    self:drawPowerups()
    self:drawDataPackets()
    self:drawFirewalls()
    self:drawViruses()
    self:drawPlayer()
    self:drawExit()
    self:drawUI()
    self:drawParticles()
    self:drawAnimations()

    if self.gameOver then
        self:drawGameOver()
    end
end

function Game:drawMaze()
    love.graphics.setColor(0.05, 0.08, 0.15, 0.9)
    love.graphics.rectangle("fill", self.mazeX - 15, self.mazeY - 15,
        self.cellSize * self.mazeSize + 30,
        self.cellSize * self.mazeSize + 30, 8)

    local pulse = (math.sin(self.elapsedTime * 2) + 1) * 0.25 + 0.75

    for y = 1, self.mazeSize do
        for x = 1, self.mazeSize do
            local cell = self.maze[y][x]
            local cellX = self.mazeX + (x - 1) * self.cellSize
            local cellY = self.mazeY + (y - 1) * self.cellSize

            if cell.path then
                love.graphics.setColor(self.pathColor[1], self.pathColor[2], self.pathColor[3], 0.3)
                love.graphics.rectangle("fill", cellX, cellY, self.cellSize, self.cellSize)
            end

            love.graphics.setColor(
                self.wallColor[1] * 0.3,
                self.wallColor[2] * 0.3,
                self.wallColor[3] * 0.3,
                1
            )
            love.graphics.setLineWidth(6)

            if cell.walls.top then
                love.graphics.line(cellX, cellY, cellX + self.cellSize, cellY)
            end
            if cell.walls.right then
                love.graphics.line(cellX + self.cellSize, cellY, cellX + self.cellSize, cellY + self.cellSize)
            end
            if cell.walls.bottom then
                love.graphics.line(cellX, cellY + self.cellSize, cellX + self.cellSize, cellY + self.cellSize)
            end
            if cell.walls.left then
                love.graphics.line(cellX, cellY, cellX, cellY + self.cellSize)
            end

            love.graphics.setColor(
                self.wallColor[1] * pulse,
                self.wallColor[2] * pulse,
                self.wallColor[3] * pulse,
                1
            )
            love.graphics.setLineWidth(3)

            if cell.walls.top then
                love.graphics.line(cellX, cellY, cellX + self.cellSize, cellY)
            end
            if cell.walls.right then
                love.graphics.line(cellX + self.cellSize, cellY, cellX + self.cellSize, cellY + self.cellSize)
            end
            if cell.walls.bottom then
                love.graphics.line(cellX, cellY + self.cellSize, cellX + self.cellSize, cellY + self.cellSize)
            end
            if cell.walls.left then
                love.graphics.line(cellX, cellY, cellX, cellY + self.cellSize)
            end

            love.graphics.setLineWidth(1)
        end
    end
end

function Game:drawPlayer()
    local x = self.mazeX + (self.player.x - 0.5) * self.cellSize
    local y = self.mazeY + (self.player.y - 0.5) * self.cellSize

    local pulse = (math_sin(self.elapsedTime * 5) + 1) * 0.2
    local alpha = 0.4 + pulse
    if self.invincible then
        local flash = math_floor(self.elapsedTime * 10) % 2
        alpha = flash == 0 and 0.8 or 0.3
    end

    love.graphics.setColor(self.playerColor[1], self.playerColor[2], self.playerColor[3], alpha)
    love.graphics.circle("fill", x, y, self.cellSize * 0.3)

    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.circle("fill", x, y, self.cellSize * 0.15)
end

function Game:drawExit()
    local x = self.mazeX + (self.exit.x - 0.5) * self.cellSize
    local y = self.mazeY + (self.exit.y - 0.5) * self.cellSize

    local pulse = (math_sin(self.elapsedTime * 3) + 1) * 0.3
    if self.bitsCollected >= self.totalBits then
        love.graphics.setColor(0.2, 1, 0.2, 0.6 + pulse)
    else
        love.graphics.setColor(0.5, 0.5, 0.5, 0.3)
    end
    love.graphics.circle("fill", x, y, self.cellSize * 0.3)

    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.circle("line", x, y, self.cellSize * 0.3)
    love.graphics.circle("line", x, y, self.cellSize * 0.2)
end

function Game:drawBits()
    for _, bit in ipairs(self.bits) do
        if not bit.collected then
            local x = self.mazeX + (bit.x - 0.5) * self.cellSize
            local y = self.mazeY + (bit.y - 0.5) * self.cellSize

            local pulse = (math_sin(self.elapsedTime * 4) + 1) * 0.2
            love.graphics.setColor(1, 1, 0, 0.8 + pulse)
            love.graphics.circle("fill", x, y, self.cellSize * 0.08)
        end
    end
end

function Game:drawPowerups()
    for _, powerup in ipairs(self.powerups) do
        if not powerup.collected then
            local x = self.mazeX + (powerup.x - 0.5) * self.cellSize
            local y = self.mazeY + (powerup.y - 0.5) * self.cellSize

            local pulse = (math_sin(self.elapsedTime * 5) + 1) * 0.25
            love.graphics.setColor(powerup.color[1], powerup.color[2], powerup.color[3], 0.8 + pulse)
            love.graphics.circle("fill", x, y, self.cellSize * 0.15)

            love.graphics.setColor(1, 1, 1, 0.9)
            love.graphics.circle("line", x, y, self.cellSize * 0.15)
        end
    end
end

function Game:drawDataPackets()
    for _, packet in ipairs(self.dataPackets) do
        if not packet.collected then
            local x = self.mazeX + (packet.x - 0.5) * self.cellSize
            local y = self.mazeY + (packet.y - 0.5) * self.cellSize

            love.graphics.push()
            love.graphics.translate(x, y)
            love.graphics.rotate(packet.rotation)

            love.graphics.setColor(1, 0.8, 0.2, 0.8)
            love.graphics.rectangle("fill", -self.cellSize * 0.1, -self.cellSize * 0.15, 
                self.cellSize * 0.2, self.cellSize * 0.3, 2)

            love.graphics.setColor(1, 1, 1, 0.9)
            love.graphics.rectangle("line", -self.cellSize * 0.1, -self.cellSize * 0.15, 
                self.cellSize * 0.2, self.cellSize * 0.3, 2)

            love.graphics.pop()
        end
    end
end

function Game:drawFirewalls()
    for _, firewall in ipairs(self.firewalls) do
        if firewall.active then
            local x = self.mazeX + (firewall.x - 0.5) * self.cellSize
            local y = self.mazeY + (firewall.y - 0.5) * self.cellSize

            local pulse = (math_sin(firewall.pulse) + 1) * 0.3
            love.graphics.setColor(1, 0.3, 0.2, 0.6 + pulse)
            love.graphics.rectangle("fill", x - self.cellSize * 0.3, y - self.cellSize * 0.3, 
                self.cellSize * 0.6, self.cellSize * 0.6, 3)
        end
    end
end

function Game:drawViruses()
    for _, virus in ipairs(self.viruses) do
        local x = self.mazeX + (virus.x - 0.5) * self.cellSize
        local y = self.mazeY + (virus.y - 0.5) * self.cellSize

        local pulse = (math_sin(virus.pulse) + 1) * 0.3
        local size = self.cellSize * 0.25 * virus.size

        if virus.scared then
            love.graphics.setColor(0.5, 0.5, 1, 0.8 + pulse)
        else
            love.graphics.setColor(virus.color[1], virus.color[2], virus.color[3], 0.8 + pulse)
        end

        love.graphics.push()
        love.graphics.translate(x, y)

        love.graphics.circle("fill", 0, 0, size)
        
        love.graphics.setColor(1, 1, 1, 0.9)
        love.graphics.circle("fill", -size * 0.3, -size * 0.2, size * 0.15)
        love.graphics.circle("fill", size * 0.3, -size * 0.2, size * 0.15)
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.circle("fill", -size * 0.3, -size * 0.2, size * 0.07)
        love.graphics.circle("fill", size * 0.3, -size * 0.2, size * 0.07)

        love.graphics.pop()
    end
end

function Game:drawUI()
    local font = love.graphics.newFont(16)
    love.graphics.setFont(font)

    local texts = {
        "BitsAndBytes - " .. self.theme:upper() .. " Theme",
        "Difficulty: " .. self.difficulty,
        "Time: " .. math_floor(self.elapsedTime) .. "s",
        "Score: " .. self.score,
        "Bits: " .. self.bitsCollected .. "/" .. self.totalBits,
        "Lives: " .. self.lives,
        "Powerup: " .. (self.powerupActive and self.powerupActive.type.name or "None")
    }

    local maxWidth = 0
    for _, t in ipairs(texts) do
        local w = font:getWidth(t)
        if w > maxWidth then maxWidth = w end
    end
    local boxWidth = maxWidth + 40
    local boxHeight = #texts * 25 + 20

    love.graphics.setColor(0.1, 0.15, 0.25, 0.3)
    love.graphics.rectangle("fill", 20, 20, boxWidth, boxHeight, 5)

    love.graphics.setColor(1, 1, 1)
    for i, t in ipairs(texts) do
        love.graphics.print(t, 35, 35 + (i - 1) * 25)
    end
end

function Game:drawParticles()
    for _, particle in ipairs(self.particles) do
        local alpha = math_min(1, particle.life * 1.5)
        love.graphics.setColor(particle.color[1], particle.color[2], particle.color[3], alpha)
        love.graphics.push()
        love.graphics.translate(particle.x, particle.y)
        love.graphics.rotate(particle.rotation)
        love.graphics.circle("fill", 0, 0, particle.size)
        love.graphics.pop()
    end
end

function Game:drawAnimations()
    for _, anim in ipairs(self.animations) do
        if anim.type == "powerup" then
            local alpha = math_min(1, (1 - math_abs(anim.progress - 0.5) * 2) * 2)
            love.graphics.setColor(0, 0, 0, 0.7 * alpha)
            love.graphics.rectangle("fill", 0, self.screenHeight / 2 - 40, self.screenWidth, 80)

            love.graphics.setColor(0.8, 0.2, 1, alpha)
            love.graphics.setFont(love.graphics.newFont(20))
            love.graphics.printf(anim.text, 50, self.screenHeight / 2 - 20, self.screenWidth - 100, "center")
        elseif anim.type == "score" then
            local progress = anim.progress
            local y = anim.y - progress * 50
            local alpha = 1 - progress
            love.graphics.setColor(1, 0.8, 0.2, alpha)
            love.graphics.setFont(love.graphics.newFont(18))
            love.graphics.print(anim.text, anim.x, y)
        end
    end
end

function Game:drawGameOver()
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", 0, 0, self.screenWidth, self.screenHeight)

    local font = love.graphics.newFont(48)
    love.graphics.setFont(font)

    if self.gameWon then
        love.graphics.setColor(0.2, 1, 0.2)
        love.graphics.printf("SYSTEM SECURED!", 0, self.screenHeight / 2 - 100, self.screenWidth, "center")

        love.graphics.setFont(love.graphics.newFont(24))
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Final Score: " .. self.score, 0, self.screenHeight / 2 - 40, self.screenWidth, "center")
        love.graphics.printf("Time: " .. math_floor(self.elapsedTime) .. " seconds", 0, self.screenHeight / 2 - 10, self.screenWidth, "center")
        love.graphics.printf("Bits Collected: " .. self.bitsCollected .. "/" .. self.totalBits, 0, self.screenHeight / 2 + 20, self.screenWidth, "center")
    else
        love.graphics.setColor(1, 0.4, 0.4)
        love.graphics.printf("SYSTEM INFECTED", 0, self.screenHeight / 2 - 80, self.screenWidth, "center")
    end

    love.graphics.setFont(love.graphics.newFont(20))
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Click anywhere to continue", 0, self.screenHeight / 2 + 80, self.screenWidth, "center")
end

function Game:isGameOver()
    return self.gameOver
end

return Game