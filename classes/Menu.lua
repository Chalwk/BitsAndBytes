local ipairs = ipairs
local math_sin = math.sin

local helpText = {
    "Welcome to BitsAndBytes - The Digital Maze!",
    "",
    "Game Features:",
    "• Collect bits (yellow dots) to score points",
    "• Avoid viruses (red creatures) that roam the maze",
    "• Use power-ups to gain temporary advantages",
    "• Collect data packets for bonus points",
    "• Avoid firewalls (red squares) that block your path",
    "• Find the exit portal after collecting all bits",
    "",
    "Power-ups:",
    "• Firewall: Scares viruses away temporarily",
    "• Encryption: Slows down all viruses",
    "• Antivirus: Destroys some viruses instantly",
    "• Overclock: Makes you invincible and faster",
    "",
    "Themes:",
    "• Retro: Orange/yellow classic computer theme",
    "• Cyber: Blue/cyan futuristic cyber theme",
    "• Matrix: Green monochrome matrix theme",
    "",
    "Controls:",
    "• WASD or Arrow Keys: Move through the maze",
    "• Space: Activate collected power-up",
    "• F: Toggle invincibility (debug)",
    "• R: Reset the current maze",
    "• ESC: Return to main menu",
    "",
    "Click anywhere to close"
}

local Menu = {}
Menu.__index = Menu

function Menu.new()
    local instance = setmetatable({}, Menu)

    instance.screenWidth = 1000
    instance.screenHeight = 700
    instance.difficulty = "medium"
    instance.theme = "retro"
    instance.title = {
        text = "BITSANDBYTES",
        subtitle = "The Digital Maze",
        scale = 1,
        scaleDirection = 1,
        scaleSpeed = 0.2,
        minScale = 0.98,
        maxScale = 1.02,
        rotation = 0,
        rotationSpeed = 0.1,
        pulse = 0
    }
    instance.showHelp = false

    instance.smallFont = love.graphics.newFont(16)
    instance.mediumFont = love.graphics.newFont(24)
    instance.largeFont = love.graphics.newFont(52)
    instance.subtitleFont = love.graphics.newFont(28)
    instance.sectionFont = love.graphics.newFont(20)

    instance:createMenuButtons()
    instance:createOptionsButtons()

    return instance
end

function Menu:setScreenSize(width, height)
    self.screenWidth = width
    self.screenHeight = height
    self:updateButtonPositions()
    self:updateOptionsButtonPositions()
end

function Menu:createMenuButtons()
    self.menuButtons = {
        {
            text = "Start Game",
            action = "start",
            width = 240,
            height = 50,
            x = 0,
            y = 0,
            color = { 0.2, 0.7, 0.9 }
        },
        {
            text = "Options",
            action = "options",
            width = 240,
            height = 50,
            x = 0,
            y = 0,
            color = { 0.7, 0.5, 0.9 }
        },
        {
            text = "Quit",
            action = "quit",
            width = 240,
            height = 50,
            x = 0,
            y = 0,
            color = { 0.9, 0.3, 0.4 }
        }
    }

    self.helpButton = {
        text = "?",
        action = "help",
        width = 45,
        height = 45,
        x = 30,
        y = self.screenHeight - 55,
        color = { 0.3, 0.6, 0.9 }
    }

    self:updateButtonPositions()
end

function Menu:createOptionsButtons()
    self.optionsButtons = {
        {
            text = "Easy",
            action = "difficulty easy",
            width = 140,
            height = 40,
            x = 0,
            y = 0,
            section = "difficulty",
            color = { 0.3, 0.8, 0.4 }
        },
        {
            text = "Medium",
            action = "difficulty medium",
            width = 140,
            height = 40,
            x = 0,
            y = 0,
            section = "difficulty",
            color = { 0.8, 0.7, 0.2 }
        },
        {
            text = "Hard",
            action = "difficulty hard",
            width = 140,
            height = 40,
            x = 0,
            y = 0,
            section = "difficulty",
            color = { 0.8, 0.3, 0.3 }
        },

        {
            text = "Retro",
            action = "theme retro",
            width = 160,
            height = 40,
            x = 0,
            y = 0,
            section = "theme",
            color = { 1, 0.5, 0 }
        },
        {
            text = "Cyber",
            action = "theme cyber",
            width = 160,
            height = 40,
            x = 0,
            y = 0,
            section = "theme",
            color = { 0, 1, 1 }
        },
        {
            text = "Matrix",
            action = "theme matrix",
            width = 160,
            height = 40,
            x = 0,
            y = 0,
            section = "theme",
            color = { 0, 1, 0 }
        },

        {
            text = "Hold-to-Move: OFF",
            action = "toggle hold",
            width = 200,
            height = 45,
            x = 0,
            y = 0,
            section = "navigation",
            color = { 0.4, 0.7, 0.9 }
        },
        {
            text = "Back to Menu",
            action = "back",
            width = 180,
            height = 45,
            x = 0,
            y = 0,
            section = "navigation",
            color = { 0.6, 0.5, 0.8 }
        }
    }
    self:updateOptionsButtonPositions()
end

function Menu:updateButtonPositions()
    local startY = self.screenHeight / 2 + 20
    for i, button in ipairs(self.menuButtons) do
        button.x = (self.screenWidth - button.width) / 2
        button.y = startY + (i - 1) * 70
    end

    self.helpButton.y = self.screenHeight - 55
end

function Menu:updateHoldToMoveButton(state)
    for _, button in ipairs(self.optionsButtons) do
        if button.action == "toggle hold" then
            button.text = "Hold-to-Move: " .. (state and "ON" or "OFF")
        end
    end
end

function Menu:updateOptionsButtonPositions()
    local centerX = self.screenWidth / 2
    local totalSectionsHeight = 320
    local startY = (self.screenHeight - totalSectionsHeight) / 2 + 40

    local diffButtonW, diffButtonH, diffSpacing = 140, 40, 15
    local diffTotalW = 3 * diffButtonW + 2 * diffSpacing
    local diffStartX = centerX - diffTotalW / 2
    local diffY = startY + 50

    local themeButtonW, themeButtonH, themeSpacing = 160, 40, 12
    local themeTotalW = 3 * themeButtonW + 2 * themeSpacing
    local themeStartX = centerX - themeTotalW / 2
    local themeY = startY + 130

    local navY = startY + 210
    local navSpacing = 55
    local navIndex = 0

    local diffIndex, themeIndex = 0, 0
    for _, button in ipairs(self.optionsButtons) do
        if button.section == "difficulty" then
            button.x = diffStartX + diffIndex * (diffButtonW + diffSpacing)
            button.y = diffY
            diffIndex = diffIndex + 1
        elseif button.section == "theme" then
            button.x = themeStartX + themeIndex * (themeButtonW + themeSpacing)
            button.y = themeY
            themeIndex = themeIndex + 1
        elseif button.section == "navigation" then
            button.x = centerX - button.width / 2
            button.y = navY + navIndex * navSpacing
            navIndex = navIndex + 1
        end
    end
end

function Menu:update(dt, screenWidth, screenHeight)
    if screenWidth ~= self.screenWidth or screenHeight ~= self.screenHeight then
        self.screenWidth = screenWidth
        self.screenHeight = screenHeight
        self:updateButtonPositions()
        self:updateOptionsButtonPositions()
    end

    self.title.scale = self.title.scale + self.title.scaleDirection * self.title.scaleSpeed * dt
    self.title.pulse = self.title.pulse + dt * 2

    if self.title.scale > self.title.maxScale then
        self.title.scale = self.title.maxScale
        self.title.scaleDirection = -1
    elseif self.title.scale < self.title.minScale then
        self.title.scale = self.title.minScale
        self.title.scaleDirection = 1
    end

    self.title.rotation = self.title.rotation + self.title.rotationSpeed * dt
end

function Menu:draw(screenWidth, screenHeight, state)
    local pulse = (math_sin(self.title.pulse) + 1) * 0.1
    love.graphics.setColor(0.4 + pulse, 0.7 + pulse, 1, 1)
    love.graphics.setFont(self.largeFont)

    love.graphics.push()
    love.graphics.translate(screenWidth / 2, screenHeight / 4)
    love.graphics.rotate(math_sin(self.title.rotation) * 0.03)
    love.graphics.scale(self.title.scale, self.title.scale)
    love.graphics.printf(self.title.text, -screenWidth / 2, -self.largeFont:getHeight() / 2, screenWidth, "center")
    love.graphics.pop()

    love.graphics.setColor(0.8, 0.9, 1, 0.8)
    love.graphics.setFont(self.subtitleFont)
    love.graphics.printf(self.title.subtitle, 0, screenHeight / 4 + 20, screenWidth, "center")

    if state == "menu" then
        if self.showHelp then
            self:drawHelpOverlay(screenWidth, screenHeight)
        else
            self:drawMenuButtons()

            love.graphics.setColor(0.9, 0.9, 1)
            love.graphics.setFont(self.smallFont)
            love.graphics.printf("Collect Bits • Avoid Viruses • Use Power-ups • Find the Exit",
                0, screenHeight / 2 - 40, screenWidth, "center")

            self:drawHelpButton()
        end
    elseif state == "options" then
        self:drawOptionsInterface()
    end

    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.setFont(self.smallFont)
    love.graphics.printf("© 2025 Jericho Crosby – BitsAndBytes", 10, screenHeight - 25, screenWidth - 20, "right")
end

function Menu:drawHelpButton()
    local button = self.helpButton
    local pulse = (math_sin(self.title.pulse * 2) + 1) * 0.2

    love.graphics.setColor(button.color[1], button.color[2], button.color[3], 0.8 + pulse)
    love.graphics.circle("fill", button.x + button.width / 2, button.y + button.height / 2, button.width / 2)

    love.graphics.setColor(0.9, 0.9, 1)
    love.graphics.setLineWidth(2)
    love.graphics.circle("line", button.x + button.width / 2, button.y + button.height / 2, button.width / 2)

    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(self.mediumFont)
    local textWidth = self.mediumFont:getWidth(button.text)
    local textHeight = self.mediumFont:getHeight()
    love.graphics.print(button.text,
        button.x + (button.width - textWidth) / 2,
        button.y + (button.height - textHeight) / 2)

    love.graphics.setLineWidth(1)
end

function Menu:drawHelpOverlay(screenWidth, screenHeight)
    love.graphics.setColor(0, 0, 0, 0.9)
    love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)

    local boxWidth = 700
    local boxHeight = 550
    local boxX = (screenWidth - boxWidth) / 2
    local boxY = (screenHeight - boxHeight) / 2

    love.graphics.setColor(0.1, 0.15, 0.25, 0.95)
    love.graphics.rectangle("fill", boxX, boxY, boxWidth, boxHeight, 12)

    love.graphics.setColor(0.3, 0.6, 1)
    love.graphics.setLineWidth(4)
    love.graphics.rectangle("line", boxX, boxY, boxWidth, boxHeight, 12)
    love.graphics.setLineWidth(1)

    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(self.largeFont)
    love.graphics.printf("BitsAndBytes Guide", boxX, boxY + 25, boxWidth, "center")

    love.graphics.setColor(0.9, 0.9, 1)
    love.graphics.setFont(self.smallFont)
    local lineHeight = 20

    local textTop = boxY + 90
    local textHeight = boxHeight - 120
    love.graphics.setScissor(boxX, textTop, boxWidth, textHeight)

    for i, line in ipairs(helpText) do
        local y = textTop + (i - 1) * lineHeight
        if y + lineHeight < boxY + boxHeight - 20 then
            if line == "" then
                love.graphics.setColor(0.5, 0.6, 0.8, 0.5)
                love.graphics.line(boxX + 40, y + 5, boxX + boxWidth - 40, y + 5)
                love.graphics.setColor(0.9, 0.9, 1)
            else
                love.graphics.printf(line, boxX + 40, y, boxWidth - 80, "left")
            end
        end
    end

    love.graphics.setScissor()
end

function Menu:drawOptionsInterface()
    local totalSectionsHeight = 280
    local startY = (self.screenHeight - totalSectionsHeight) / 2 + 20

    love.graphics.setFont(self.sectionFont)
    love.graphics.setColor(0.8, 0.9, 1)
    love.graphics.printf("Select Difficulty", 0, startY + 15, self.screenWidth, "center")
    love.graphics.printf("Choose Theme", 0, startY + 105, self.screenWidth, "center")

    self:updateOptionsButtonPositions()
    self:drawOptionSection("difficulty")
    self:drawOptionSection("theme")
    self:drawOptionSection("navigation")
end

function Menu:drawOptionSection(section)
    for _, button in ipairs(self.optionsButtons) do
        if button.section == section then
            local isSelected = false
            if button.action:sub(1, 10) == "difficulty" then
                local difficulty = button.action:sub(12)
                isSelected = difficulty == self.difficulty
            elseif button.action:sub(1, 5) == "theme" then
                local theme = button.action:sub(7)
                isSelected = theme == self.theme
            end

            if isSelected then
                love.graphics.setColor(1, 1, 1, 0.3)
                love.graphics.rectangle("fill", button.x - 6, button.y - 6, button.width + 12, button.height + 12, 8)
                love.graphics.setColor(1, 1, 1, 0.8)
                love.graphics.setLineWidth(3)
                love.graphics.rectangle("line", button.x - 6, button.y - 6, button.width + 12, button.height + 12, 8)
                love.graphics.setLineWidth(1)
            end

            self:drawButton(button)
        end
    end
end

function Menu:drawMenuButtons()
    for _, button in ipairs(self.menuButtons) do
        self:drawButton(button)
    end
end

function Menu:drawButton(button)
    local pulse = (math_sin(self.title.pulse * 3) + 1) * 0.05

    love.graphics.setColor(button.color[1] * 0.3, button.color[2] * 0.3, button.color[3] * 0.3, 0.9)
    love.graphics.rectangle("fill", button.x, button.y, button.width, button.height, 10, 10)

    love.graphics.setColor(button.color[1] + pulse, button.color[2] + pulse, button.color[3] + pulse, 0.8)
    love.graphics.rectangle("fill", button.x + 2, button.y + 2, button.width - 4, button.height - 4, 8, 8)

    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", button.x, button.y, button.width, button.height, 10, 10)

    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(self.mediumFont)
    local textWidth = self.mediumFont:getWidth(button.text)
    local textHeight = self.mediumFont:getHeight()
    love.graphics.print(button.text, button.x + (button.width - textWidth) / 2,
        button.y + (button.height - textHeight) / 2)

    love.graphics.setLineWidth(1)
end

function Menu:handleClick(x, y, state)
    local buttons = state == "menu" and self.menuButtons or self.optionsButtons

    for _, button in ipairs(buttons) do
        if x >= button.x and x <= button.x + button.width and
            y >= button.y and y <= button.y + button.height then
            return button.action
        end
    end

    if state == "menu" then
        if self.helpButton and x >= self.helpButton.x and x <= self.helpButton.x + self.helpButton.width and
            y >= self.helpButton.y and y <= self.helpButton.y + self.helpButton.height then
            self.showHelp = true
            return "help"
        end

        if self.showHelp then
            self.showHelp = false
            return "help_close"
        end
    end

    return nil
end

function Menu:setDifficulty(difficulty)
    self.difficulty = difficulty
end

function Menu:getDifficulty()
    return self.difficulty
end

function Menu:setTheme(theme)
    self.theme = theme
end

function Menu:getTheme()
    return self.theme
end

return Menu