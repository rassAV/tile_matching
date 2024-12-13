require "vector"
require "particle"

TileMatching = {}
TileMatching.__index = TileMatching

function TileMatching:create(first_player, second_player, screenWidth, screenHeight)
    local tilematching = {}
    setmetatable(tilematching, TileMatching)
    tilematching.screen_width = screenWidth -- ширина окна
    tilematching.screen_height = screenHeight -- высота окна
    tilematching.field_width = 20 -- ширина поля
    tilematching.field_height = 20 -- высота поля
    tilematching.win_length = 5 -- длинна для победы
    tilematching.field = {} -- хранилище значений ячеек поля
    for y = 1, tilematching.field_height do
        tilematching.field[y] = {}
        for x = 1, tilematching.field_width do
            tilematching.field[y][x] = "empty" -- ячейка закрашена "empty", "blue" или "red"
        end
    end
    tilematching.blue_sequence = true -- очерёдность синего игрока
    tilematching.last_sequence = false
    tilematching.blue_player = first_player -- при true Синий это Игрок, при false Компьютер
    tilematching.red_player = second_player -- при true Красный это Игрок, при false Компьютер
    tilematching.blue_score = 0 -- кол-во побед синего игрока
    tilematching.red_score = 0 -- кол-во побед красного игрока

    -- Настройка частиц
    tilematching.left_pos = Vector:create(screenWidth / 8, screenHeight + 50)
    tilematching.right_pos = Vector:create(screenWidth * 7 / 8, screenHeight + 50)
    tilematching.particles_left = ParticleSystem:create(tilematching.left_pos, 100)
    tilematching.particles_right = ParticleSystem:create(tilematching.right_pos, 100)
    tilematching.gravity = Vector:create(0, 0.005)
    tilematching.particles_timer = 0.
    tilematching.particles_timer_max = 4.
    tilematching.win_color = "blue"
    tilematching.AI_timer = 0.3
    tilematching.AI_timer_max = 0.3
    
    return tilematching
end

function TileMatching:update(screenWidth, screenHeight, dt)
    self.screen_width, self.screen_height = screenWidth, screenHeight
    self.left_pos = Vector:create(screenWidth / 8, screenHeight + 50)
    self.right_pos = Vector:create(screenWidth * 7 / 8, screenHeight + 50)
    self.particles_left.origin = self.left_pos
    self.particles_right.origin = self.right_pos

    local draw = self:checkDraw()
    local winner = self:checkWin()

    -- Обновление состояния частиц
    if self.particles_timer > 2 then
        self.particles_timer = self.particles_timer - dt
        self.particles_left:update()
        self.particles_right:update()
        self.particles_left:applyForce(self.gravity)
        self.particles_right:applyForce(self.gravity)
    elseif self.particles_timer > 0.1 then
        self.particles_timer = self.particles_timer - dt
        self.particles_left:final_update()
        self.particles_right:final_update()
        self.particles_left:applyForce(self.gravity)
        self.particles_right:applyForce(self.gravity)
    elseif self.particles_timer > 0 then
        self:resetField()
    else
        if draw then
            self.blue_score = self.blue_score + 1
            self.red_score = self.red_score + 1
        end
        
        if winner then
            self.particles_timer = self.particles_timer_max
            self.win_color = winner

            if winner == "blue" then
                self.blue_score = self.blue_score + 1
            elseif winner == "red" then
                self.red_score = self.red_score + 1
            end
        end

        if (not self.blue_player and self.blue_sequence) or (not self.red_player and not self.blue_sequence) then
            if self.AI_timer > 0 then
                self.AI_timer = self.AI_timer - dt
            else
                self:AI()
            end
        end
    end
end

function TileMatching:cursorColor()
    if self.particles_timer > 0.1 then
        return "white"
    elseif self.particles_timer > 0 then
        if self.blue_sequence and self.blue_player then
            return "blue"
        elseif not self.blue_sequence and self.red_player then
            return "red"
        else
            return "white"
        end
    end
    if self.blue_sequence == self.last_sequence then
        self.last_sequence = not self.blue_sequence
        if self.blue_sequence and self.blue_player then
            return "blue"
        elseif not self.blue_sequence and self.red_player then
            return "red"
        else
            return "white"
        end
    end
    return "none"
end

function TileMatching:AI()
    local bestScore = -math.huge
    local bestMove = nil
    local currentPlayer = self.blue_sequence and "blue" or "red"
    local opponent = self.blue_sequence and "red" or "blue"

    local fieldCopy = {}
    for y = 1, self.field_height do
        fieldCopy[y] = {}
        for x = 1, self.field_width do
            fieldCopy[y][x] = self.field[y][x]
        end
    end

    for y = 1, self.field_height do
        for x = 1, self.field_width do
            if fieldCopy[y][x] == "empty" then
                -- ход ИИ
                fieldCopy[y][x] = currentPlayer
                local playerScore = self:evaluateMove(x, y, currentPlayer, opponent, fieldCopy)

                -- ход противника (чтобы блокировать)
                fieldCopy[y][x] = opponent
                local opponentScore = self:evaluateMove(x, y, opponent, currentPlayer, fieldCopy)

                local score = math.max(playerScore, opponentScore * 2) -- блокировка важнее

                if score > bestScore then
                    bestScore = score
                    bestMove = {x = x, y = y}
                end
            end
        end
    end

    -- совершаем ход
    if bestMove then
        self.field[bestMove.y][bestMove.x] = currentPlayer
        self.blue_sequence = not self.blue_sequence
    end
    self.AI_timer = self.AI_timer_max
end

function TileMatching:evaluateMove(x, y, currentPlayer, opponent)
    local function countInDirection(dx, dy, color)
        local count = 0
        local blocked = false
        for i = 1, self.win_length - 1 do
            local nx = x + i * dx
            local ny = y + i * dy
            if nx < 1 or nx > self.field_width or ny < 1 or ny > self.field_height then
                blocked = true
                break
            end
            if self.field[ny][nx] == color then
                count = count + 1
            elseif self.field[ny][nx] ~= "empty" then
                blocked = true
                break
            else
                break
            end
        end
        return count, blocked
    end

    local directions = {
        {1, 0}, -- горизонтально
        {0, 1}, -- вертикально
        {1, 1}, -- диагональ вправо-вниз
        {1, -1} -- диагональ вправо-вверх
    }

    local score = 0

    for _, dir in ipairs(directions) do
        local dx, dy = dir[1], dir[2]

        local forwardCount, forwardBlocked = countInDirection(dx, dy, currentPlayer)
        local backwardCount, backwardBlocked = countInDirection(-dx, -dy, currentPlayer)
        local totalPlayerCount = forwardCount + backwardCount + 1

        local oppForwardCount, oppForwardBlocked = countInDirection(dx, dy, opponent)
        local oppBackwardCount, oppBackwardBlocked = countInDirection(-dx, -dy, opponent)
        local totalOpponentCount = oppForwardCount + oppBackwardCount + 1

        -- критические угрозы
        if totalOpponentCount >= self.win_length - 1 and not (oppForwardBlocked and oppBackwardBlocked) then
            return math.huge -- Самый высокий приоритет для блокировки победы
        end

        -- если победа
        if totalOpponentCount == self.win_length - 2 and not (oppForwardBlocked or oppBackwardBlocked) then
            score = score + 100
        end

        -- вес за длину цепочки
        score = score + (totalPlayerCount ^ 2) - (totalOpponentCount ^ 2)
    end

    return score
end

function TileMatching:checkWin()
    local function checkDirection(row, col, dx, dy, color)
        local count = 0
        for i = 0, self.win_length - 1 do
            local x = col + i * dx
            local y = row + i * dy
            if x >= 1 and x <= self.field_width and y >= 1 and y <= self.field_height and self.field[y][x] == color then
                count = count + 1
            else
                break
            end
        end
        return count == self.win_length
    end

    for row = 1, self.field_height do
        for col = 1, self.field_width do
            if self.field[row][col] ~= "empty" then
                local color = self.field[row][col]
                if checkDirection(row, col, 1, 0, color) or  -- горизонтально
                   checkDirection(row, col, 0, 1, color) or  -- вертикально
                   checkDirection(row, col, 1, 1, color) or  -- диагональ вправо-вниз
                   checkDirection(row, col, 1, -1, color) then -- диагональ вправо-вверх
                    return color
                end
            end
        end
    end
    return nil
end

function TileMatching:checkDraw()
    for y = 1, self.field_height do
        for x = 1, self.field_width do
            if self.field[y][x] == "empty" then
                return false
            end
        end
    end
    return true
end

function TileMatching:resetField()
    for y = 1, self.field_height do
        for x = 1, self.field_width do
            self.field[y][x] = "empty"
        end
    end
    self.blue_sequence = true
end

function TileMatching:clicked(mousex, mousey)
    if self.particles_timer <= 0 and ((self.blue_player and self.blue_sequence) or (self.red_player and not self.blue_sequence)) then
        local col, row = self:getCircle(mousex, mousey)
        if col and row and self.field[row][col] == "empty" then
            if self.blue_sequence then
                self.field[row][col] = "blue"
            else
                self.field[row][col] = "red"
            end
            self.blue_sequence = not self.blue_sequence
        end
    end
end

function TileMatching:getCircle(mousex, mousey)
    local cellSize = math.min(self.screen_width / self.field_width, (self.screen_height - 50) / self.field_height)
    local offsetX = (self.screen_width - cellSize * self.field_width) / 2
    local offsetY = 50 + (self.screen_height - 50 - cellSize * self.field_height) / 2
    local radius = cellSize / 2

    for row = 1, self.field_height do
        for col = 1, self.field_width do
            local centerX = offsetX + (col - 1) * cellSize + radius
            local centerY = offsetY + (row - 1) * cellSize + radius

            local distance = math.sqrt((mousex - centerX)^2 + (mousey - centerY)^2)
            if distance <= radius then
                return col, row
            end
        end
    end

    return nil, nil
end

function TileMatching:draw()
    local r, g, b, a = love.graphics.getColor()

    -- Отображение счёта
    local centerX = self.screen_width / 2
    local centerY = 10

    local player1 = self.blue_player and "Player 1" or "Computer 1"
    local player2 = self.red_player and "Player 2" or "Computer 2"
    local score = self.blue_score .. ":" .. self.red_score

    local player1Width = love.graphics.getFont():getWidth(player1)
    local scoreWidth = love.graphics.getFont():getWidth(score)
    local player2Width = love.graphics.getFont():getWidth(player2)
    
    love.graphics.setColor(0.2, 0.2, 1)
    love.graphics.print(player1, centerX - player1Width - scoreWidth / 2 - 10, centerY)

    love.graphics.setColor(0.9, 0.9, 0.9)
    love.graphics.print(score, centerX - scoreWidth / 2, centerY)

    love.graphics.setColor(1, 0.2, 0.2)
    love.graphics.print(player2, centerX + scoreWidth / 2 + 10, centerY)

    -- Отрисовка поля
    local cellSize = math.min(self.screen_width / self.field_width, (self.screen_height - 50) / self.field_height)
    local offsetX = (self.screen_width - cellSize * self.field_width) / 2
    local offsetY = 50 + (self.screen_height - 50 - cellSize * self.field_height) / 2

    for y = 1, self.field_height do
        for x = 1, self.field_width do
            local cellX = offsetX + (x - 1) * cellSize + cellSize / 2
            local cellY = offsetY + (y - 1) * cellSize + cellSize / 2

            if self.field[y][x] == "blue" then
                love.graphics.setColor(0, 0, 1) -- Синий цвет для ячейки
            elseif self.field[y][x] == "red" then
                love.graphics.setColor(1, 0, 0) -- Красный цвет для ячейки
            else
                love.graphics.setColor(1, 1, 1) -- Белый цвет для пустой ячейки
            end

            love.graphics.circle("fill", cellX, cellY, cellSize / 2)
        end
    end

    -- Отображение частиц
    if self.particles_timer > 0 then
        if self.win_color == "blue" then
            self.particles_left:draw(0.2, 0.2, 1)
            self.particles_right:draw(0.2, 0.2, 1)
        elseif self.win_color == "red" then
            self.particles_left:draw(1, 0.2, 0.2)
            self.particles_right:draw(1, 0.2, 0.2)
        end
    end

    love.graphics.setColor(r, g, b, a)
end