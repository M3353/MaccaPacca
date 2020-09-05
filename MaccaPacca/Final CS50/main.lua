Class = require 'class'
push = require 'push'

require 'Animation'
require 'Map'
require 'Alpaca'
require 'Enemy'

-- close resolution to NES but 16:9
VIRTUAL_WIDTH = 400
VIRTUAL_HEIGHT = 225

-- actual window resolution
WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 720

-- seed RNG
math.randomseed(os.time())

function love.load()
    -- makes upscaling look pixel-y instead of blurry
    love.graphics.setDefaultFilter('nearest', 'nearest')

    -- adds the map class
    map = Map()
    
    push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, {
        fullscreen = false,
        vsync = true,
        resizable = false
    })

    love.keyboard.keysPressed = {}
    love.keyboard.keysReleased = {}
end

-- global key pressed function
function love.keyboard.wasPressed(key)
    if (love.keyboard.keysPressed[key]) then
        return true
    else
        return false
    end
end

-- global key released function
function love.keyboard.wasReleased(key)
    if (love.keyboard.keysReleased[key]) then
        return true
    else
        return false
    end
end

-- called whenever a key is pressed
function love.keypressed(key)
    if key == 'escape' then
        love.event.quit()
    end

    love.keyboard.keysPressed[key] = true
end

-- called whenever a key is released
function love.keyreleased(key)
    love.keyboard.keysReleased[key] = true
end

function love.update(dt)
    -- changes the random seed every update interval
    math.randomseed(os.time())

    map:update(dt)

    -- reset all keys pressed and released this frame
    love.keyboard.keysPressed = {}
    love.keyboard.keysReleased = {}
end

function love.draw()
    -- begin virtual resolution drawing
    push:apply('start')

    -- clear screen using sky background
    love.graphics.clear(156/255, 203/255, 245/255, 255/255)

    -- moves game window according to players position
    love.graphics.translate(math.floor(-map.camX + 0.5), math.floor(-map.camY))

    -- draws map on the screen
    map:render()

    -- end virtual resolution
    push:apply('end')
end