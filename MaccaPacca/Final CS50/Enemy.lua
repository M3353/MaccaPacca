require 'Util'

Enemy = Class{}

local RUN_SPEED = math.random(80, 100)
local JUMP_VELOCITY = math.random(175, 225)

function Enemy:init(map)
    self.map = map
    self.texture = love.graphics.newImage('Graphics/Alpaca/Enemy_Spritesheet.png')

    self.height = 20
    self.width = 20

    self.x = map.tileWidth * (map.mapWidth - math.random(2, 8))
    self.y = 0 + self.height
    self.dy = 0
    self.dx = -RUN_SPEED

    self.xOffset = 10
    self.yOffset = 10

    self.__index = self

    self.animations = {
        ['running'] = Animation({
            texture = self.texture,
            frames = {
                love.graphics.newQuad(20, 0, 20, 20, self.texture:getDimensions()),
                love.graphics.newQuad(40, 0, 20, 20, self.texture:getDimensions()),
                love.graphics.newQuad(60, 0, 20, 20, self.texture:getDimensions()),
                love.graphics.newQuad(20, 0, 20, 20, self.texture:getDimensions())
            },
            interval = .15
        }),
        ['jumping'] = Animation({
            texture = self.texture,
            frames = {
                love.graphics.newQuad(80, 0, 16, 20, self.texture:getDimensions())
            }
        }),
    }

    self.frames = {}

    self.animation = self.animations['running']
    self.currentFrame = self.animation:getCurrentFrame()

    self.state = 'running'

    self.behaviors = {
        ['running'] = function(dt)

            self.dx = -RUN_SPEED

            -- check if there's a tile directly beneath us
            
            if not self.map:collides(self.map:tileAt(self.x, self.y + self.height)) and
                not self.map:collides(self.map:tileAt(self.x + self.width - 1, self.y + self.height)) then
                
                    -- if so, reset velocity and position and change state
                    self.state = 'jumping'
                    self.animation = self.animations['jumping']
            end

            if self:needJump() then

                self.dy = -JUMP_VELOCITY
                self.state = 'jumping'
                self.animation = self.animations['jumping']
            end
            
        end,
        ['jumping'] = function(dt)

            self.dx = -RUN_SPEED
            self.dy = self.dy + self.map.gravity

              -- check if there's a tile directly beneath us
            if self.map:collides(self.map:tileAt(self.x, self.y + self.height)) or
              self.map:collides(self.map:tileAt(self.x + self.width - 1, self.y + self.height)) then
              
                -- if so, reset velocity and position and change state
                self.dy = 0
                self.state = 'running'
                self.animation = self.animations['running']
                self.y = (self.map:tileAt(self.x, self.y + self.height).y - 1) * self.map.tileHeight - self.height
            end

            self:checkLeftCollision()
            self:checkTopCollision()

        end
    }
end

function Enemy:update(dt)
    self.behaviors[self.state](dt)
    self.currentFrame = self.animation:getCurrentFrame()
    self.animation:update(dt)

    self.x = self.x + self.dx * dt

    self.y = self.y + self.dy * dt
end

function Enemy:checkLeftCollision()
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

function Enemy:checkTopCollision()

    if self.dy < 0 then
        if self.map:tileAt(self.x, self.y).id ~= TILE_EMPTY or
            self.map:tileAt(self.x + self.width - 1, self.y).id ~= TILE_EMPTY then
        
            -- reset y velocity
            self.dy = 0
        end
    end
end

function Enemy:needJump()

    if self.dy == 0 then
        if self.map:collides(self.map:tileAt(self.x - 1, self.y)) or 
            self.map:collides(self.map:tileAt(self.x - 2, self.y + self.height - 1)) or not
                self.map:collides(self.map:tileAt(self.x - (map.tileWidth * 2), self.y + (map.tileHeight * 10))) then

                    self.dx = 0
                    return true
        end
    end

    return false
end


function Enemy:render()

    love.graphics.draw(self.texture, self.currentFrame, math.floor(self.x + self.xOffset),
        math.floor(self.y + self.yOffset), 0, -1, 1, self.xOffset, self.yOffset)
end

