require 'Util'
require 'Enemy'

Alpaca = Class{}

local RUN_SPEED = 100
local JUMP_VELOCITY = 200

function Alpaca:init(map)
    self.map = map
    self.texture = love.graphics.newImage('Graphics/Alpaca/Alpaca_Spritesheet.png')

    self.height = 20
    self.width = 20
    self.xOffset = 10
    self.yOffset = 10

    self.x = map.tileWidth * 3
    self.y = 0 
    self.dy = 0
    self.dx = 0

    self.isAttacking = false

    self.sounds = {
        ['jump'] = love.audio.newSource('Sounds/jump.wav', 'static'),
        ['hit'] = love.audio.newSource('Sounds/collide.wav', 'static'),
        ['lose'] = love.audio.newSource('Sounds/lose.wav', 'static')
    }

    self.direction = 'right'

    -- initializes player animation
    self.animations = {
        ['idle'] = Animation({
            texture = self.texture,
            frames = {
                love.graphics.newQuad(0, 0, self.width, self.height, self.texture:getDimensions())
            }
        }),
        ['running'] = Animation({
            texture = self.texture,
            frames = {
                love.graphics.newQuad(20, 0, self.width, self.height, self.texture:getDimensions()),
                love.graphics.newQuad(40, 0, self.width, self.height, self.texture:getDimensions()),
                love.graphics.newQuad(60, 0, self.width, self.height, self.texture:getDimensions()),
                love.graphics.newQuad(20, 0, self.width, self.height, self.texture:getDimensions())
            },
            interval = .15
        }),
        ['jumping'] = Animation({
            texture = self.texture,
            frames = {
                love.graphics.newQuad(80, 0, 16, 20, self.texture:getDimensions())
            }
        }),
        ['headbutt'] = Animation({
            texture = self.texture,
            frames = {
                love.graphics.newQuad(100, 0, self.width, self.height, self.texture:getDimensions()),
                love.graphics.newQuad(140, 0, self.width, self.height, self.texture:getDimensions()),
                love.graphics.newQuad(140, 0, self.width, self.height, self.texture:getDimensions()),
                love.graphics.newQuad(0, 0, self.width, self.height, self.texture:getDimensions()),
                love.graphics.newQuad(0, 0, self.width, self.height, self.texture:getDimensions()),
                love.graphics.newQuad(0, 0, self.width, self.height, self.texture:getDimensions()),
                love.graphics.newQuad(0, 0, self.width, self.height, self.texture:getDimensions()),
                love.graphics.newQuad(100, 0, self.width, self.height, self.texture:getDimensions())
            },
            interval = .05
        })
    }

    self.frames = {}

    self.animation = self.animations['idle']
    self.currentFrame = self.animation:getCurrentFrame()

    self.state = 'idle'

    self.behaviors = {
        ['idle'] = function(dt)
            
            if love.keyboard.wasPressed('w') then
                self.dy = -JUMP_VELOCITY
                self.state = 'jumping'
                self.animation = self.animations['jumping']
                self.sounds['jump']:play()
            elseif love.keyboard.isDown('d') then
                self.dx = RUN_SPEED
                self.state = 'running'
                self.direction = 'right'
                self.animations['running']:restart()
                self.animation = self.animations['running']
            elseif love.keyboard.isDown('a') then
                self.dx = -RUN_SPEED
                self.state = 'running'
                self.direction = 'left'
                self.animations['running']:restart()
                self.animation = self.animations['running']
            else
                self.dx = 0
            end
        end,
        ['running'] = function(dt)

            if love.keyboard.wasPressed('w') then
                self.dy = -JUMP_VELOCITY
                self.state = 'jumping'
                self.animation = self.animations['jumping']
                self.sounds['jump']:play()
            elseif love.keyboard.isDown('d') then
                self.direction = 'right'
                self.dx = RUN_SPEED
            elseif love.keyboard.isDown('a') then
                self.direction = 'left'
                self.dx = -RUN_SPEED
            else
                self.dx = 0
                self.state = 'idle'
                self.animation = self.animations['idle']
            end

            self:checkRightCollision()
            self:checkLeftCollision()

            -- check if there's a tile directly beneath us
            if not self.map:collides(self.map:tileAt(self.x, self.y + self.height)) and
                not self.map:collides(self.map:tileAt(self.x + self.width - 1, self.y + self.height)) then
                
                -- if so, reset velocity and position and change state
                self.state = 'jumping'
                self.animation = self.animations['jumping']
                
            end
        end,
        ['jumping'] = function(dt)

            if love.keyboard.isDown('d') then
                self.direction = 'right'
                self.dx = RUN_SPEED
            elseif love.keyboard.isDown('a') then
                self.direction = 'left'
                self.dx = -RUN_SPEED
            else
                self.dx = 0 
            end

            self.dy = self.dy + self.map.gravity

              -- check if there's a tile directly beneath us
            if self.map:collides(self.map:tileAt(self.x, self.y + self.height)) or
              self.map:collides(self.map:tileAt(self.x + self.width - 1, self.y + self.height)) then
              
                -- if so, reset velocity and position and change state
                self.dy = 0
                self.state = 'idle'
                self.animation = self.animations['idle']
                self.y = (self.map:tileAt(self.x, self.y + self.height).y - 1) * self.map.tileHeight - self.height
            end

            self:checkRightCollision()
            self:checkLeftCollision()
            self:checkTopCollision()

        end,
    }
end

-- lets alpaca headbutt when space is pressed
function Alpaca:headbutt()
    if self.state ~= 'jumping' then
        if love.keyboard.isDown('space') then
            self.animation = self.animations['headbutt']
            self.isAttacking = true
            self.sounds['hit']:play()
            self:checkRightCollision()
            self:checkLeftCollision()

        elseif love.keyboard.wasReleased('space') then
            self.animation = self.animations['idle']
            self.state = 'idle'
            self.isAttacking = false
        end
    end
end

-- updates alpaca
function Alpaca:update(dt)
    self.behaviors[self.state](dt)
    self:headbutt()
    self.currentFrame = self.animation:getCurrentFrame()
    self.animation:update(dt)
    
    self.x = self.x + self.dx * dt

    self.y = self.y + self.dy * dt
end

-- checks two tiles to our left to see if a collision occurred
function Alpaca:checkLeftCollision()
    if self.dx < 0 then
        -- check if there's a tile directly beneath us
        if self.map:collides(self.map:tileAt(self.x - 1, self.y)) or
            self.map:collides(self.map:tileAt(self.x - 1, self.y + self.height - 1)) then
            
            -- if so, reset velocity and position and change state
            self.dx = 0
            self.x = self.map:tileAt(self.x - 1, self.y).x * self.map.tileWidth
        end
    end
end

-- checks two tiles to our right to see if a collision occurred
function Alpaca:checkRightCollision()
    if self.dx > 0 then
        -- check if there's a tile directly beneath us
        if self.map:collides(self.map:tileAt(self.x + self.width, self.y)) or
            self.map:collides(self.map:tileAt(self.x + self.width, self.y + self.height - 1)) then
            
            -- if so, reset velocity and position and change state
            self.dx = 0
            self.x = (self.map:tileAt(self.x + self.width, self.y).x - 1) * self.map.tileWidth - self.width
        end
    end
end

-- check tiles above to see if a collision occured
function Alpaca:checkTopCollision()

    if self.dy < 0 then
        if self.map:tileAt(self.x, self.y).id ~= TILE_EMPTY or
            self.map:tileAt(self.x + self.width - 1, self.y).id ~= TILE_EMPTY then
        
            -- reset y velocity
            self.dy = 0
        end
    end
end

function Alpaca:render()

    local direction = 1

    if self.direction == 'right' then
        direction = 1
    else
        direction = -1
    end

    love.graphics.draw(self.texture, self.currentFrame, math.floor(self.x + self.xOffset),
        math.floor(self.y + self.yOffset), 0, direction, 1, self.xOffset, self.yOffset)
end