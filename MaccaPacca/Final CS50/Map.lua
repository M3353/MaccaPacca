require 'Util'

Map = Class{}

-- gives number values to the tile types depending on their location on the spritesheet
TILE_EMPTY = 64
TILE_SURFACE = 2

TILE_DIRT = 18
TILE_ROCK = 10

LEFT_CURVED = 1
LEFT_VERTICAL = 9 
LEFT_JUT = 17

RIGHT_CURVED = 3  
RIGHT_VERTICAL = 11
RIGHT_JUT = 19 

PLATFORM_RIGHT = 13
PLATFORM_LEFT = 12
TILE_SPIKES = 6

DRAGON_TR = 27
DRAGON_TL = 26
DRAGON_BR = 35
DRAGON_BL = 34

SMALL_RUIN_1 = 29
SMALL_RUIN_2 = 37

SMALL_STATUE_1 = 4
SMALL_STATUE_2 = 5

WALL_BOTTOM = 28
WALL_TOP = 36

DIETY_TOP = 25
DIETY_MIDDLE = 33
DIETY_BOTTOM = 41

function Map:init()
    
    self.spawnTimer = 0
    self.gravity = 2
   
    self.tileWidth = 16
    self.tileHeight = 16
    self.mapHeight = 36
    self.mapWidth = 100
    self.mapWidthPixels = self.mapWidth * self.tileWidth
    self.mapHeightPixels = self.mapHeight * self.tileHeight
    self.tiles = {}
    

    self.camX= 0
    self.camY = 0

    -- adds spritesheets and generates tiles
    self.texture = love.graphics.newImage('graphics/Background/Map_Spritesheet.png')
    self.tileSprites = generateQuads(self.texture, self.tileWidth, self.tileHeight)
    
    -- adds music
    self.music = love.audio.newSource('Sounds/gamemusic.wav', 'static')
    self.intromusic = love.audio.newSource('Sounds/intro.wav', 'static')

    -- adds the player and a empty table intended for enemies
    self.alpaca = Alpaca(self)
    self.runningEnemies = {}

    -- covers the map in blank tiles
    for y = 1, self.mapHeight do
        for x = 1, self.mapWidth do
            self:setTile(x, y, TILE_EMPTY)
        end 
    end

    -- creates the contour of the map
    local x = 1
    local surface = self.mapHeight / 3
    while x < self.mapWidth do

        -- 1 in 5 chance to deviate either up or down by one block(spawn a hill or valley)
        -- sets random elevation and width
        if math.random(5) == 1 then

            self:setTile(x, surface, TILE_SURFACE)
            x = x + 1

            local deviation = math.random(2) == 1 and -1 or 1
            local elevation = math.random(6)
            local plateau = math.random(5)

            -- draws a valley or hill depending on the deviation direction
            if deviation < 0 then
                self:setTile(x, surface - 1, LEFT_CURVED)
                x = x + 1

                for h = 2, elevation do
                    self:setTile(x, surface - h, LEFT_CURVED)
                    x = x + 1
                end
                for w = 0, plateau do
                    self:setTile(x, surface - elevation, TILE_SURFACE)
                    x = x + 1
                end
                for h = elevation, 1, -1 do
                    self:setTile(x, surface - h, RIGHT_CURVED)
                    x = x + 1
                end
            else
                self:setTile(x, surface, RIGHT_CURVED)
                x = x + 1

                for h = 1, elevation do
                    self:setTile(x, surface + h, RIGHT_CURVED)
                    x = x + 1
                end
                for w = 0, plateau do
                    self:setTile(x, surface + elevation + 1, TILE_SURFACE)
                    x = x + 1
                end
                for h = elevation, 0, -1 do
                    self:setTile(x, surface + h, LEFT_CURVED)
                    x = x + 1
                end
            end

            self:setTile(x, surface, TILE_SURFACE)
            x = x + 1

        -- creates flat path
        elseif math.random(8) ~= 1 then 

            self:setTile(x, surface, TILE_SURFACE) 
            x = x + 1

        -- 1 out of 8 chance to create gap in the path
        else
            self:setTile(x, surface, RIGHT_CURVED)
            self:setTile(x, surface + 1, RIGHT_VERTICAL)
            self:setTile(x, surface + 2, RIGHT_JUT)

            for y = surface + 3, self.mapHeight do
                self:setTile(x , y, TILE_DIRT)
            end          

            x = x + 4

            self:setTile(x, surface, LEFT_CURVED)
            self:setTile(x, surface + 1, LEFT_VERTICAL)
            self:setTile(x, surface + 2, LEFT_JUT)

            for y = surface + 3, self.mapHeight do
                self:setTile(x , y, TILE_DIRT)
            end

            x = x + 1

            self:setTile(x, surface, TILE_SURFACE)

            for y = surface + 1, self.mapHeight do
                self:setTile(x , y, TILE_DIRT)
            end

            x = x + 1
            
        end
    end

    -- fills in the map starting from the index of the contour
    x = 1
    local index = self.mapHeight
    while x < self.mapWidth do

        -- gets the y index of the contour at a given x value
        for y = 1, self.mapHeight do
            if self:getTile(x, y) ~= TILE_EMPTY then
                index = y + 1
            end
        end 

        local height = math.random(1,10) + index

        -- 1 in 40 chance to spawn a dragon ruin
        if math.random(40) == 1 then
            
            for y = index, self.mapHeight do
                self:setTile(x, y, TILE_DIRT)
            end
            
            self:setTile(x, height, DRAGON_TL) 
            self:setTile(x, height + 1, DRAGON_BL) 

            x = x + 1
   
        -- 1 in 15 chance to spawn a diety statue ruin 
        elseif math.random(15) == 1 then
        
            for y = index, self.mapHeight do
                self:setTile(x , y, TILE_DIRT)
            end

            self:setTile(x, height, DIETY_TOP)
            self:setTile(x, height + 1, DIETY_MIDDLE)
            self:setTile(x, height + 2, DIETY_BOTTOM)

            x = x + 1

        -- if not prints a column of dirt with a random chance to spawn smaller ruins/ rocks
        else 
            for y = index, self.mapHeight do
                self:setTile(x, y, TILE_DIRT)

                -- adds second half of the dragon ruin
                if self:getTile(x - 1, y) == DRAGON_TL then
                    self:setTile(x, y, DRAGON_TR)
                elseif self:getTile(x - 1, y) ==  DRAGON_BL then
                    self:setTile(x, y, DRAGON_BR)

                elseif math.random(20) == 2 then
                    self:setTile(x, y, SMALL_RUIN_1)
                elseif math.random(20) == 3 then
                    self:setTile(x, y, SMALL_RUIN_2)
                elseif math.random(20) == 4 then
                    self:setTile(x, y + 1, WALL_TOP) 
                    self:setTile(x, y + 2, WALL_BOTTOM)
                elseif math.random(10) == 1 then
                    self:setTile(x, y, TILE_ROCK)
                end
            end

            x = x + 1
        end
    end

    -- fills the map with spikes starting from the index of the contour
    x = 1
    while x < self.mapWidth do

        index = self.mapHeight

         -- gets the y index of the contour at a given x value
        for y = 1, index do
            if self:getTile(x, y) ~= TILE_EMPTY then
                index = y - 1
                break
            end
        end 

        if math.random(20) ==  1 then
            self:setTile(x, index, TILE_SPIKES)
            x = x + 2
        end

        x = x + 1
    end

    self.intromusic:setLooping(false)
    self.intromusic:play()

end

-- updates the game
function Map:update(dt)
    self.alpaca:update(dt)
    self:runningEnemyBehavior(dt)
    self:checkDeath()

    -- allows the camera to follow the alpaca's movement
    self.camX = math.max(0, math.min(self.alpaca.x - VIRTUAL_WIDTH / 2,
        math.min(self.mapWidthPixels - VIRTUAL_WIDTH, self.alpaca.x)))
    self.camY = math.max(0, math.min(self.alpaca.y - VIRTUAL_HEIGHT / 2,
        math.min(self.mapHeightPixels - VIRTUAL_HEIGHT, self.alpaca.y)))

    -- starts the game music after the intro
    if not self.intromusic:isPlaying() then
        self.music:setLooping(true)
        self.music:play()
    end
end

-- returns an integer value for the tile at a given x-y coordinate
function Map:getTile(x, y)
    return self.tiles[(y - 1) * self.mapWidth + x]
end

-- gets the index of the specific tile given a certain x-y coordinate
function Map:getTileIndex(x, y)
    return (math.floor(x / self.tileWidth) * self.mapWidthPixels) + math.ceil(y / self.tileHeight)
end

-- sets a tile at a given x-y coordinate to an integer value
function Map:setTile(x, y, tile)
    self.tiles[(y - 1) * self.mapWidth + x] = tile
end

-- gets the tile type at a given pixel coordinate
function Map:tileAt(x, y)
    return {
        x = math.floor(x / self.tileWidth) + 1,
        y = math.floor(y / self.tileHeight) + 1,
        id = self:getTile(math.floor(x / self.tileWidth) + 1, math.floor(y / self.tileHeight) + 1)
    }
end

-- checks to see if the player collides with any of the specified tiles
function Map:collides(tile)
    -- define our collidable tiles
    local collidables = {TILE_SURFACE, TILE_DIRT, PLATFORM_RIGHT, PLATFORM_LEFT, 
        LEFT_JUT, RIGHT_JUT, LEFT_VERTICAL, RIGHT_VERTICAL, LEFT_CURVED, 
        RIGHT_CURVED, SMALL_STATUE_1, SMALL_STATUE_2    
    }
    -- iterate and return true if our tile type matches
    for _, v in ipairs(collidables) do
        if tile.id == v then
            return true
        end
    end

    return false
end

-- spawns running enemy 
function Map:runningEnemyBehavior(dt)

    --  spawns a running enemy if the timer is at a certain value
    if self.spawnTimer > 0 then
        self.spawnTimer = self.spawnTimer - (dt / math.random(3, 8))
    else
        enemy = Enemy(self)
        table.insert(self.runningEnemies, enemy)

        -- resets the spawn timer
        self.spawnTimer = 1
    end

    -- if the enemy goes beyond the screen, delete it
    for i=table.getn(self.runningEnemies), 1, -1 do
        enemy = self.runningEnemies[i]
        enemy:update(dt)
        if enemy.x < -enemy.width or
            enemy.y > self.tileHeight * (self.mapHeight) then

            table.remove(self.runningEnemies, i)
        end
    end

end

-- check to see alpaca death conditions
function Map:checkDeath()

    -- check to see if the alpaca is beyond a certain y value
    if self.alpaca.y > self.tileHeight * (self.mapHeight) then
        love.event.quit('restart')
    end

    -- check to see if the alpaca is touching a spike on the right side; if so, restart the game
    if self:tileAt(self.alpaca.x + self.alpaca.width - 2, self.alpaca.y).id == TILE_SPIKES or
            self:tileAt(self.alpaca.x + self.alpaca.width - 2, self.alpaca.y + self.alpaca.height / 2).id == TILE_SPIKES then
        love.event.quit('restart')
    end

    -- check to see if the alpaca is touching a spike on the left side; if so, restart the game
    if self:tileAt(self.alpaca.x + 2, self.alpaca.y).id == TILE_SPIKES or
            self:tileAt(self.alpaca.x + 2, self.alpaca.y + self.alpaca.height / 2).id == TILE_SPIKES then
        love.event.quit('restart')
    end

    -- iterates through table of enemies to see if an enemy and the player occupy the same tile 
    for index, enemy in ipairs(self.runningEnemies) do
        if self:getTileIndex(enemy.x, enemy.y) == self:getTileIndex(self.alpaca.x, self.alpaca.y) then
        
            -- if alpaca is not headbutting, end the game
            if not self.alpaca.isAttacking then
                love.event.quit('restart')

            -- if alpaca is headbutting, delete the enmy
            else 
                table.remove(self.runningEnemies, index)
            end
        end
    end

end

-- draws tiles/sprites at a given x-y coordinate
function Map:render()    
    for y = 1, self.mapHeight do
        for x = 1, self.mapWidth do
            love.graphics.draw(
                self.texture, 
                self.tileSprites[self:getTile(x, y)],
                (x - 1) * self.tileWidth, 
                (y - 1) * self.tileHeight
            )
        end
    end

    self.alpaca:render()

    -- iterates through table of enemies to draw
    for index, enemy in ipairs(self.runningEnemies) do
        enemy:render()
    end

end