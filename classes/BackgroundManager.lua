-- BitsAndBytes - Computer Themed Game
-- License: MIT
-- Copyright (c) 2025 Jericho Crosby (Chalwk)

local math_pi = math.pi
local math_sin = math.sin
local math_cos = math.cos
local math_random = math.random
local table_insert = table.insert

local BackgroundManager = {}
BackgroundManager.__index = BackgroundManager

function BackgroundManager.new()
    local instance = setmetatable({}, BackgroundManager)
    instance.menuParticles = {}
    instance.gameParticles = {}
    instance.time = 0
    instance:initMenuParticles()
    instance:initGameParticles()
    return instance
end

function BackgroundManager:initMenuParticles()
    self.menuParticles = {}
    for _ = 1, 80 do
        table_insert(self.menuParticles, {
            x = math_random() * 1000,
            y = math_random() * 1000,
            size = math_random(3, 8),
            speed = math_random(15, 40),
            angle = math_random() * math_pi * 2,
            pulseSpeed = math_random(0.5, 2),
            pulsePhase = math_random() * math_pi * 2,
            type = math_random(1, 4), -- Different types: bits, bytes, processors, data packets
            rotation = math_random() * math_pi * 2,
            rotationSpeed = (math_random() - 0.5) * 2,
            color = {math_random(0.6, 1), math_random(0.6, 0.8), math_random(0.2, 0.4)}
        })
    end
end

function BackgroundManager:initGameParticles()
    self.gameParticles = {}
    for _ = 1, 60 do
        table_insert(self.gameParticles, {
            x = math_random() * 1000,
            y = math_random() * 1000,
            size = math_random(2, 6),
            speed = math_random(8, 25),
            angle = math_random() * math_pi * 2,
            type = math_random(1, 5),
            pulseSpeed = math_random(0.3, 1.2),
            pulsePhase = math_random() * math_pi * 2,
            isGlowing = math_random() > 0.5,
            glowPhase = math_random() * math_pi * 2,
            color = {
                math_random(0.7, 1),
                math_random(0.7, 1),
                math_random(0.3, 0.6)
            }
        })
    end
end

function BackgroundManager:update(dt)
    self.time = self.time + dt

    -- Update menu particles
    for _, particle in ipairs(self.menuParticles) do
        particle.x = particle.x + math_cos(particle.angle) * particle.speed * dt
        particle.y = particle.y + math_sin(particle.angle) * particle.speed * dt
        particle.rotation = particle.rotation + particle.rotationSpeed * dt

        if particle.x < -50 then particle.x = 1050 end
        if particle.x > 1050 then particle.x = -50 end
        if particle.y < -50 then particle.y = 1050 end
        if particle.y > 1050 then particle.y = -50 end
    end

    -- Update game particles
    for _, particle in ipairs(self.gameParticles) do
        particle.x = particle.x + math_cos(particle.angle) * particle.speed * dt
        particle.y = particle.y + math_sin(particle.angle) * particle.speed * dt
        particle.glowPhase = particle.glowPhase + dt * 2

        if particle.x < -50 then particle.x = 1050 end
        if particle.x > 1050 then particle.x = -50 end
        if particle.y < -50 then particle.y = 1050 end
        if particle.y > 1050 then particle.y = -50 end
    end
end

function BackgroundManager:drawMenuBackground(screenWidth, screenHeight)
    local time = love.timer.getTime()

    -- Circuit board gradient background
    for y = 0, screenHeight, 4 do
        local progress = y / screenHeight
        local pulse = (math_sin(time * 2 + progress * 8) + 1) * 0.02

        local r = 0.1 + progress * 0.15 + pulse
        local g = 0.15 + progress * 0.1 + pulse
        local b = 0.25 + progress * 0.2 + pulse

        love.graphics.setColor(r, g, b, 0.8)
        love.graphics.line(0, y, screenWidth, y)
    end

    -- Floating computer element particles
    for _, particle in ipairs(self.menuParticles) do
        local pulse = (math_sin(particle.pulsePhase + time * particle.pulseSpeed) + 1) * 0.3
        local alpha = 0.4 + pulse * 0.3

        love.graphics.setColor(particle.color[1], particle.color[2], particle.color[3], alpha)

        love.graphics.push()
        love.graphics.translate(particle.x, particle.y)
        love.graphics.rotate(particle.rotation)

        if particle.type == 1 then
            -- Bit (0/1)
            love.graphics.setColor(0.2, 0.8, 1, alpha)
            love.graphics.circle("fill", 0, 0, particle.size)
            love.graphics.setColor(1, 1, 1, alpha)
            love.graphics.setFont(love.graphics.newFont(particle.size * 1.5))
            love.graphics.printf(math_random(0, 1), -particle.size/2, -particle.size/3, particle.size, "center")
        elseif particle.type == 2 then
            -- Data packet
            love.graphics.setColor(1, 0.8, 0.2, alpha)
            love.graphics.rectangle("fill", -particle.size, -particle.size/2, particle.size * 2, particle.size)
            love.graphics.setColor(1, 1, 0.8, alpha * 1.2)
            love.graphics.rectangle("fill", -particle.size/2, -particle.size/4, particle.size, particle.size/2)
        elseif particle.type == 3 then
            -- Processor chip
            love.graphics.setColor(0.8, 0.8, 0.8, alpha)
            love.graphics.rectangle("fill", -particle.size, -particle.size, particle.size * 2, particle.size * 2)
            love.graphics.setColor(0.4, 0.4, 0.6, alpha)
            for i = -1, 1, 0.5 do
                love.graphics.rectangle("fill", -particle.size*0.8, i * particle.size*0.6, particle.size*1.6, particle.size*0.1)
            end
        else
            -- Binary arc
            love.graphics.setColor(1, 1, 0.2, alpha)
            love.graphics.arc("fill", 0, 0, particle.size, math_pi/6, 11*math_pi/6)
        end

        love.graphics.pop()
    end

    -- Circuit board pattern
    love.graphics.setColor(0.4, 0.5, 0.8, 0.2)
    local cellSize = 80
    for x = 0, screenWidth, cellSize do
        for y = 0, screenHeight, cellSize do
            if math_random() > 0.7 then
                love.graphics.setColor(0.8, 0.6, 0.2, 0.15)
                love.graphics.rectangle("fill", x + 10, y + 10, cellSize - 20, cellSize - 20)
            else
                love.graphics.setColor(0.3, 0.4, 0.7, 0.1)
                love.graphics.rectangle("line", x, y, cellSize, cellSize)
                -- Circuit lines
                love.graphics.line(x + cellSize/2, y, x + cellSize/2, y + cellSize)
                love.graphics.line(x, y + cellSize/2, x + cellSize, y + cellSize/2)
            end
        end
    end
end

function BackgroundManager:drawGameBackground(screenWidth, screenHeight)
    local time = love.timer.getTime()

    -- Dark blue circuit board background with wave effect
    for y = 0, screenHeight, 3 do
        local progress = y / screenHeight
        local wave = math_sin(progress * 15 + time * 3) * 0.01
        local r = 0.05 + wave
        local g = 0.08 + progress * 0.05 + wave
        local b = 0.15 + progress * 0.1 + wave

        love.graphics.setColor(r, g, b, 0.9)
        love.graphics.line(0, y, screenWidth, y)
    end

    -- Computer element particles
    for _, particle in ipairs(self.gameParticles) do
        local alpha = 0.2
        if particle.isGlowing then
            local glow = (math_sin(particle.glowPhase) + 1) * 0.1
            alpha = 0.15 + glow
        end

        love.graphics.setColor(particle.color[1], particle.color[2], particle.color[3], alpha)

        if particle.type == 1 then
            -- Binary digit
            love.graphics.setColor(0.3, 0.8, 1, alpha)
            love.graphics.circle("fill", particle.x, particle.y, particle.size)
            love.graphics.setColor(1, 1, 1, alpha)
            love.graphics.setFont(love.graphics.newFont(particle.size * 1.2))
            love.graphics.printf(math_random(0, 1), particle.x - particle.size/2, particle.y - particle.size/3, particle.size, "center")
        elseif particle.type == 2 then
            -- Data packet with glow
            love.graphics.setColor(1, 0.9, 0.3, alpha * 1.5)
            love.graphics.rectangle("fill", particle.x - particle.size, particle.y - particle.size/2, particle.size * 2, particle.size)
        elseif particle.type == 3 then
            -- Virus silhouette
            love.graphics.setColor(1, 0.3, 0.3, alpha)
            love.graphics.circle("fill", particle.x, particle.y, particle.size)
            love.graphics.setColor(1, 0.6, 0.6, alpha)
            for i = 0, 5 do
                local angle = i * math.pi / 3
                love.graphics.line(
                    particle.x, particle.y,
                    particle.x + math.cos(angle) * particle.size * 1.5,
                    particle.y + math.sin(angle) * particle.size * 1.5
                )
            end
        else
            -- Chip shape
            love.graphics.setColor(0.8, 0.8, 1, alpha)
            love.graphics.rectangle("fill", particle.x - particle.size, particle.y - particle.size, particle.size * 2, particle.size * 2)
            love.graphics.setColor(0.5, 0.5, 0.8, alpha)
            love.graphics.rectangle("line", particle.x - particle.size, particle.y - particle.size, particle.size * 2, particle.size * 2)
        end
    end

    -- Subtle circuit grid in background
    love.graphics.setColor(0.2, 0.3, 0.5, 0.15)
    local gridSize = 40
    for x = 0, screenWidth, gridSize do
        for y = 0, screenHeight, gridSize do
            if math_random() > 0.8 then
                love.graphics.rectangle("line", x + 5, y + 5, gridSize - 10, gridSize - 10)
                -- Circuit connections
                love.graphics.setColor(0.3, 0.4, 0.6, 0.1)
                love.graphics.line(x + gridSize/2, y, x + gridSize/2, y + gridSize)
                love.graphics.line(x, y + gridSize/2, x + gridSize, y + gridSize/2)
            end
        end
    end
end

return BackgroundManager