-- BitsAndBytes - Computer Themed Game
-- License: MIT
-- Copyright (c) 2025 Jericho Crosby (Chalwk)

local ipairs = ipairs
local math_sin = math.sin

local helpText = {
    "BitsAndBytes - Navigate the Digital Realm!",
    "",
    "How to Play:",
    "• Arrow Keys to move your Bit Runner",
    "• Collect all Data Bits to secure the system",
    "• Power Cores activate Firewall mode",
    "• Firewall lets you encrypt Viruses",
    "• Avoid Viruses when firewall is down",
    "• Collect special upgrades for bonuses",
    "",
    "System Elements:",
    "• Cyan Circles: Data Bits (+10)",
    "• Orange Pulsing: Power Cores (+50)",
    "• Spiky Circles: Malicious Viruses",
    "• Yellow Pac: Your Bit Runner",
    "",
    "Special Upgrades:",
    "• Green Square: Overclock (Speed Boost)",
    "• White Triangle: System Boot (Extra Life)",
    "• Magenta Circle: Data Bonus (Double Score)",
    "",
    "Game Protocols:",
    "• Classic: Traditional gameplay",
    "• Timed: Race against the clock",
    "• Survival: How long can you last?",
    "",
    "Security Levels:",
    "• Easy: Smaller network, fewer viruses",
    "• Normal: Balanced challenge",
    "• Hard: Larger network, faster viruses",
    "",
    "Controls:",
    "• R: Reset system",
    "• ESC: Return to main menu",
    "",
    "Click anywhere to close"
}

local Menu = {}
Menu.__index = Menu

function Menu.new()
    local instance = setmetatable({}, Menu)

    instance.screenWidth = 800
    instance.screenHeight = 600
    instance.difficulty = "normal"
    instance.gameMode = "classic"
    instance.title = {
        text = "BitsAndBytes",
        scale = 1,
        scaleDirection = 1,
        scaleSpeed = 0.3,
        minScale = 0.95,
        maxScale = 1.05,
        rotation = 0,
        rotationSpeed = 0.2
    }
    instance.showHelp = false

    instance.smallFont = love.graphics.newFont(16)
    instance.mediumFont = love.graphics.newFont(22)
    instance.largeFont = love.graphics.newFont(42)
    instance.sectionFont = love.graphics.newFont(18)

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
            text = "Boot System",
            action = "start",
            width = 200,
            height = 45,
            x = 0,
            y = 0
        },
        {
            text = "Configuration",
            action = "options",
            width = 200,
            height = 45,
            x = 0,
            y = 0
        },
        {
            text = "Shutdown",
            action = "quit",
            width = 200,
            height = 45,
            x = 0,
            y = 0
        }
    }

    -- Help button (question mark)
    self.helpButton = {
        text = "?",
        action = "help",
        width = 40,
        height = 40,
        x = 30,
        y = self.screenHeight - 50
    }

    self:updateButtonPositions()
end

function Menu:createOptionsButtons()
    self.optionsButtons = {
        -- Security Section
        {
            text = "Basic",
            action = "difficulty easy",
            width = 120,
            height = 35,
            x = 0,
            y = 0,
            section = "difficulty"
        },
        {
            text = "Standard",
            action = "difficulty normal",
            width = 120,
            height = 35,
            x = 0,
            y = 0,
            section = "difficulty"
        },
        {
            text = "Advanced",
            action = "difficulty hard",
            width = 120,
            height = 35,
            x = 0,
            y = 0,
            section = "difficulty"
        },

        -- Protocol Section
        {
            text = "Classic",
            action = "gameMode classic",
            width = 140,
            height = 35,
            x = 0,
            y = 0,
            section = "gameMode"
        },
        {
            text = "Timed",
            action = "gameMode timed",
            width = 140,
            height = 35,
            x = 0,
            y = 0,
            section = "gameMode"
        },
        {
            text = "Survival",
            action = "gameMode survival",
            width = 140,
            height = 35,
            x = 0,
            y = 0,
            section = "gameMode"
        },

        -- Navigation
        {
            text = "Back to Main",
            action = "back",
            width = 160,
            height = 40,
            x = 0,
            y = 0,
            section = "navigation"
        }
    }
    self:updateOptionsButtonPositions()
end

function Menu:updateButtonPositions()
    local startY = self.screenHeight / 2
    for i, button in ipairs(self.menuButtons) do
        button.x = (self.screenWidth - button.width) / 2
        button.y = startY + (i - 1) * 60
    end

    -- Update help button position
    self.helpButton.y = self.screenHeight - 50
end

function Menu:updateOptionsButtonPositions()
    local centerX = self.screenWidth / 2
    local totalSectionsHeight = 240
    local startY = (self.screenHeight - totalSectionsHeight) / 2

    -- Security buttons
    local securityButtonW, securityButtonH, securitySpacing = 120, 35, 15
    local securityTotalW = 3 * securityButtonW + 2 * securitySpacing
    local securityStartX = centerX - securityTotalW / 2
    local securityY = startY + 40

    -- Protocol buttons
    local protocolButtonW, protocolButtonH, protocolSpacing = 140, 35, 10
    local protocolTotalW = 3 * protocolButtonW + 2 * protocolSpacing
    local protocolStartX = centerX - protocolTotalW / 2
    local protocolY = startY + 120

    -- Navigation
    local navY = startY + 200

    local securityIndex, protocolIndex = 0, 0
    for _, button in ipairs(self.optionsButtons) do
        if button.section == "difficulty" then
            button.x = securityStartX + securityIndex * (securityButtonW + securitySpacing)
            button.y = securityY
            securityIndex = securityIndex + 1
        elseif button.section == "gameMode" then
            button.x = protocolStartX + protocolIndex * (protocolButtonW + protocolSpacing)
            button.y = protocolY
            protocolIndex = protocolIndex + 1
        elseif button.section == "navigation" then
            button.x = centerX - button.width / 2
            button.y = navY
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

    -- Update title animation
    self.title.scale = self.title.scale + self.title.scaleDirection * self.title.scaleSpeed * dt

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
    -- Draw animated title
    love.graphics.setColor(0.2, 0.8, 1)  -- Cyan color for tech theme
    love.graphics.setFont(self.largeFont)

    love.graphics.push()
    love.graphics.translate(screenWidth / 2, screenHeight / 6)
    love.graphics.rotate(math_sin(self.title.rotation) * 0.05)
    love.graphics.scale(self.title.scale, self.title.scale)
    love.graphics.printf(self.title.text, -screenWidth / 2, -self.largeFont:getHeight() / 2, screenWidth, "center")
    love.graphics.pop()

    if state == "menu" then
        if self.showHelp then
            self:drawHelpOverlay(screenWidth, screenHeight)
        else
            self:drawMenuButtons()
            -- Draw instructions
            love.graphics.setColor(0.9, 0.9, 0.9)
            love.graphics.setFont(self.smallFont)
            love.graphics.printf(
                "Navigate the digital network, collect data bits, avoid viruses!\nActivate firewall to encrypt malicious software.",
                0, screenHeight / 4 + 50, screenWidth, "center")

            -- Draw help button
            self:drawHelpButton()
        end
    elseif state == "options" then
        self:drawOptionsInterface()
    end

    -- Draw copyright
    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.setFont(self.smallFont)
    love.graphics.printf("© 2025 Jericho Crosby – BitsAndBytes", 10, screenHeight - 25, screenWidth - 20, "right")
end

function Menu:drawHelpButton()
    local button = self.helpButton

    -- Button background
    love.graphics.setColor(0.3, 0.5, 0.8, 0.8)
    love.graphics.circle("fill", button.x + button.width / 2, button.y + button.height / 2, button.width / 2)

    -- Button border
    love.graphics.setColor(0.6, 0.7, 1)
    love.graphics.setLineWidth(2)
    love.graphics.circle("line", button.x + button.width / 2, button.y + button.height / 2, button.width / 2)

    -- Question mark
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
    -- Semi-transparent overlay
    love.graphics.setColor(0, 0, 0, 0.85)
    love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)

    -- Help box
    local boxWidth = 600
    local boxHeight = 500
    local boxX = (screenWidth - boxWidth) / 2
    local boxY = (screenHeight - boxHeight) / 2

    -- Box background
    love.graphics.setColor(0.1, 0.1, 0.2, 0.95)
    love.graphics.rectangle("fill", boxX, boxY, boxWidth, boxHeight, 10)

    -- Box border
    love.graphics.setColor(0.3, 0.5, 0.8)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", boxX, boxY, boxWidth, boxHeight, 10)

    -- Title
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(self.largeFont)
    love.graphics.printf("System Manual", boxX, boxY + 20, boxWidth, "center")

    -- Help text
    love.graphics.setColor(0.9, 0.9, 0.9)
    love.graphics.setFont(self.smallFont)

    local lineHeight = 22
    for i, line in ipairs(helpText) do
        local y = boxY + 80 + (i - 1) * lineHeight
        love.graphics.printf(line, boxX + 30, y, boxWidth - 60, "left")
    end

    love.graphics.setLineWidth(1)
end

function Menu:drawOptionsInterface()
    local totalSectionsHeight = 240
    local startY = (self.screenHeight - totalSectionsHeight) / 2

    -- Draw section headers
    love.graphics.setFont(self.sectionFont)
    love.graphics.setColor(0.8, 0.8, 1)
    love.graphics.printf("Security Level", 0, startY + 15, self.screenWidth, "center")
    love.graphics.printf("Protocol", 0, startY + 95, self.screenWidth, "center")

    self:updateOptionsButtonPositions()
    self:drawOptionSection("difficulty")
    self:drawOptionSection("gameMode")
    self:drawOptionSection("navigation")
end

function Menu:drawOptionSection(section)
    for _, button in ipairs(self.optionsButtons) do
        if button.section == section then
            -- Draw selection highlight first (behind the button)
            if button.action:sub(1, 10) == "difficulty" then
                local difficulty = button.action:sub(12)
                if difficulty == self.difficulty then
                    love.graphics.setColor(0.2, 0.8, 0.2, 0.6)
                    love.graphics.rectangle("fill", button.x - 4, button.y - 4, button.width + 8, button.height + 8, 6)
                end
            elseif button.action:sub(1, 8) == "gameMode" then
                local gameMode = button.action:sub(10)
                if gameMode == self.gameMode then
                    love.graphics.setColor(0.2, 0.8, 0.2, 0.6)
                    love.graphics.rectangle("fill", button.x - 4, button.y - 4, button.width + 8, button.height + 8, 6)
                end
            end

            -- Then draw the button on top
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
    love.graphics.setColor(0.25, 0.25, 0.4, 0.9)
    love.graphics.rectangle("fill", button.x, button.y, button.width, button.height, 8, 8)

    love.graphics.setColor(0.6, 0.6, 1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", button.x, button.y, button.width, button.height, 8, 8)

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

    -- Check help button in menu state
    if state == "menu" then
        if self.helpButton and x >= self.helpButton.x and x <= self.helpButton.x + self.helpButton.width and
            y >= self.helpButton.y and y <= self.helpButton.y + self.helpButton.height then
            self.showHelp = true
            return "help"
        end

        -- If help is showing, any click closes it
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

function Menu:setGameMode(gameMode)
    self.gameMode = gameMode
end

function Menu:getGameMode()
    return self.gameMode
end

return Menu