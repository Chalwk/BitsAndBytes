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
            x = math_random() * 1200,
            y = math_random() * 1200,
            size = math_random(3, 8),
            speed = math_random(15, 40),
            angle = math_random() * math_pi * 2,
            pulseSpeed = math_random(0.5, 2),
            pulsePhase = math_random() * math_pi * 2,
            type = math_random(1, 6),
            rotation = math_random() * math_pi * 2,
            rotationSpeed = (math_random() - 0.5) * 2,
            color = {math_random(0.4, 0.9), math_random(0.3, 0.7), math_random(0.6, 1), math_random(0.3, 0.7)},
            shape = math_random(1, 3)
        })
    end
end

function BackgroundManager:initGameParticles()
    self.gameParticles = {}
    for _ = 1, 60 do
        table_insert(self.gameParticles, {
            x = math_random() * 1200,
            y = math_random() * 1200,
            size = math_random(2, 6),
            speed = math_random(8, 25),
            angle = math_random() * math_pi * 2,
            type = math_random(1, 4),
            rotation = math_random() * math_pi * 2,
            rotationSpeed = (math_random() - 0.5) * 1.5,
            isGlowing = math_random() > 0.5,
            glowPhase = math_random() * math_pi * 2,
            color = {math_random(0.5, 1), math_random(0.3, 0.8), math_random(0.4, 0.9), math_random(0.4, 0.8)},
            trail = {}
        })
    end
end

function BackgroundManager:update(dt)
    self.time = self.time + dt

    for _, particle in ipairs(self.menuParticles) do
        particle.x = particle.x + math_cos(particle.angle) * particle.speed * dt
        particle.y = particle.y + math_sin(particle.angle) * particle.speed * dt
        particle.rotation = particle.rotation + particle.rotationSpeed * dt

        if particle.x < -100 then particle.x = 1300 end
        if particle.x > 1300 then particle.x = -100 end
        if particle.y < -100 then particle.y = 1300 end
        if particle.y > 1300 then particle.y = -100 end
    end

    for _, particle in ipairs(self.gameParticles) do
        particle.x = particle.x + math_cos(particle.angle) * particle.speed * dt
        particle.y = particle.y + math_sin(particle.angle) * particle.speed * dt
        particle.rotation = particle.rotation + particle.rotationSpeed * dt
        particle.glowPhase = particle.glowPhase + dt * 3

        table_insert(particle.trail, {x = particle.x, y = particle.y, life = 1.0})
        for i = #particle.trail, 1, -1 do
            particle.trail[i].life = particle.trail[i].life - dt * 2
            if particle.trail[i].life <= 0 then
                table.remove(particle.trail, i)
            end
        end

        if particle.x < -100 then particle.x = 1300 end
        if particle.x > 1300 then particle.x = -100 end
        if particle.y < -100 then particle.y = 1300 end
        if particle.y > 1300 then particle.y = -100 end
    end
end

function BackgroundManager:drawMenuBackground(screenWidth, screenHeight)
    local time = love.timer.getTime()

    for y = 0, screenHeight, 4 do
        local progress = y / screenHeight
        local pulse = (math_sin(time * 1.2 + progress * 8) + 1) * 0.04

        local r = 0.1 + progress * 0.15 + pulse
        local g = 0.15 + math_sin(progress * 6 + time) * 0.1 + pulse
        local b = 0.25 + progress * 0.2 + pulse

        love.graphics.setColor(r, g, b, 0.8)
        love.graphics.rectangle("fill", 0, y, screenWidth, 4)
    end

    for _, particle in ipairs(self.menuParticles) do
        local pulse = (math_sin(particle.pulsePhase + time * particle.pulseSpeed) + 1) * 0.3
        local alpha = 0.4 + pulse * 0.3

        love.graphics.setColor(particle.color[1], particle.color[2], particle.color[3], alpha)

        love.graphics.push()
        love.graphics.translate(particle.x, particle.y)
        love.graphics.rotate(particle.rotation)

        if particle.shape == 1 then
            love.graphics.circle("line", 0, 0, particle.size)
            love.graphics.circle("line", 0, 0, particle.size * 0.6)
        elseif particle.shape == 2 then
            love.graphics.polygon("line",
                particle.size, 0,
                -particle.size/2, particle.size,
                -particle.size/2, -particle.size
            )
        else
            love.graphics.rectangle("line", -particle.size/2, -particle.size/2, particle.size, particle.size)
        end

        love.graphics.pop()
    end

    love.graphics.setColor(0.3, 0.5, 0.8, 0.15)
    local gridSize = 80
    for x = 0, screenWidth, gridSize do
        for y = 0, screenHeight, gridSize do
            if math_random() > 0.85 then
                love.graphics.setColor(0.8, 0.6, 0.2, 0.2)
                love.graphics.circle("line", x + gridSize/2, y + gridSize/2, gridSize/3)
                love.graphics.setColor(0.3, 0.5, 0.8, 0.15)
            else
                love.graphics.rectangle("line", x, y, gridSize, gridSize)
            end
        end
    end

    love.graphics.setColor(1, 1, 1, 0.1 * math_sin(time * 3))
    love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)
end

function BackgroundManager:drawGameBackground(screenWidth, screenHeight)
    local time = love.timer.getTime()

    for y = 0, screenHeight, 3 do
        local progress = y / screenHeight
        local wave1 = math_sin(progress * 12 + time * 1.5) * 0.03
        local wave2 = math_cos(progress * 8 + time * 2) * 0.02

        local r = 0.08 + wave1
        local g = 0.12 + progress * 0.1 + wave2
        local b = 0.18 + progress * 0.15 + wave1

        love.graphics.setColor(r, g, b, 0.9)
        love.graphics.rectangle("fill", 0, y, screenWidth, 3)
    end

    for _, particle in ipairs(self.gameParticles) do
        local alpha = 0.3
        if particle.isGlowing then
            local glow = (math_sin(particle.glowPhase) + 1) * 0.2
            alpha = 0.25 + glow
        end

        for i, point in ipairs(particle.trail) do
            local trailAlpha = point.life * 0.2
            love.graphics.setColor(particle.color[1], particle.color[2], particle.color[3], trailAlpha)
            love.graphics.circle("fill", point.x, point.y, particle.size * point.life * 0.5)
        end

        love.graphics.setColor(particle.color[1], particle.color[2], particle.color[3], alpha)

        love.graphics.push()
        love.graphics.translate(particle.x, particle.y)
        love.graphics.rotate(particle.rotation)

        if particle.type == 1 then
            love.graphics.circle("fill", 0, 0, particle.size)
            love.graphics.setColor(1, 1, 1, alpha * 0.8)
            love.graphics.circle("fill", 0, 0, particle.size * 0.5)
        elseif particle.type == 2 then
            love.graphics.polygon("line",
                0, -particle.size,
                particle.size * 0.7, particle.size * 0.7,
                -particle.size * 0.7, particle.size * 0.7
            )
        else
            love.graphics.circle("line", 0, 0, particle.size)
            love.graphics.circle("line", 0, 0, particle.size * 0.6)
        end

        love.graphics.pop()
    end

    love.graphics.setColor(0.3, 0.4, 0.6, 0.15)
    local cellSize = 35
    for x = 0, screenWidth, cellSize do
        love.graphics.line(x, 0, x, screenHeight)
    end
    for y = 0, screenHeight, cellSize do
        love.graphics.line(0, y, screenWidth, y)
    end

    local borderGlow = (math_sin(time * 2) + 1) * 0.05
    love.graphics.setColor(0.2, 0.3, 0.5, borderGlow)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", 2, 2, screenWidth - 4, screenHeight - 4)
    love.graphics.setLineWidth(1)
end

return BackgroundManager