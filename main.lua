require "vector"
require "tile_matching"

local screenWidth = 800
local screenHeight = 600

local cursor_blue = love.mouse.newCursor("assets/blue_cursor.png", 0, 0)
local cursor_red = love.mouse.newCursor("assets/red_cursor.png", 0, 0)
local cursor_white = love.mouse.newCursor("assets/white_cursor.png", 0, 0)

local tilematching = TileMatching:create(true, false, screenWidth, screenHeight)

function love.load()
    love.window.setMode(screenWidth, screenHeight, {resizable = true, minwidth = 800, minheight = 600})
    love.window.setTitle("Tilematching Game")
    love.graphics.setFont(love.graphics.newFont(20))
    love.mouse.setCursor(cursor_blue)
end

function love.update(dt)
    tilematching:update(screenWidth, screenHeight, dt)

    local color = tilematching:cursorColor()
    if color == "blue" then
        love.mouse.setCursor(cursor_blue)
    elseif color == "red" then
        love.mouse.setCursor(cursor_red)
    elseif color == "white" then
        love.mouse.setCursor(cursor_white)
    end
end

function love.draw()
    tilematching:draw()
end

function love.resize(w, h)
    screenWidth = w
    screenHeight = h
end

function love.keypressed(key)
end

function love.mousepressed(x, y, button, istouch, presses)
    if button == 1 then
        tilematching:clicked(love.mouse.getPosition())
    end
end

function love.mousereleased(x, y, button, istouch, presses)
end