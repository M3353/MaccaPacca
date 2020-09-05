require 'Util'

Map = Class{}

TILE_EMPTY = 6
TILE_SURFACE = 2

TILE_DIRT = 18

LEFT_CURVED = 1
LEFT_VERTICAL = 9 
LEFT_JUT = 17

RIGHT_CURVED = 3  
RIGHT_VERTICAL = 11
RIGHT_JUT = 19 

PLATFORM_RIGHT = 13
PLATFORM_LEFT = 12

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

    self.gravity = 6
    self.tileWidth = 16
    self.tileHeight = 16
    self.mapHeight = 36
    self.mapWidth = 64
    self.tiles = {}

    self.camX= 0
    self.camY = 0

    self.texture = love.graphics.newImage('graphics/Background/Map_Spritesheet.png')
    self.tileSprites = generateQuads(self.texture, self.tileWidth, self.tileHeight)

    self.mapWidthPixels = self.mapWidth * self.tileWidth
    self.mapHeightPixels = self.mapHeight * self.tileHeight

    self.alpaca = Alpaca(self)

    for y = 1, self.mapHeight do
        for x = 1, self.mapWidth do
            self:setTile(x, y, TILE_EMPTY)
        end 
    end

    local x = 5
    local surface = self.mapHeight / 3

    for i = 0, 5 do
        self:setTile(i, surface, TILE_SURFACE)
        for y = surface + 1, self.mapHeight do
            self:setTile(i, y, TILE_DIRT)
        end
    end
    
    while x < self.mapWidth do

        -- spawns a random one tile wide ruin at ground level
        if math.random(10) == 1 then
            local ruin = math.random(4, 5)

            self:setTile(x, surface - 1, ruin)
            self:setTile(x, surface, TILE_SURFACE)

            for y = surface + 1, self.mapHeight do
                self:setTile(x, y, TILE_DIRT)
            end
            
            x = x + 1                             

        -- spawns a floating platform with a chance of a ruin on top
        elseif math.random(10) == 1 and x < self.mapWidth - 1 then
            local height = surface - math.random(6)

            self:setTile(x, height, PLATFORM_LEFT)
            self:setTile(x + 1, height, PLATFORM_RIGHT)

            self:setTile(x, surface, TILE_SURFACE)
            self:setTile(x + 1, surface, TILE_SURFACE)

            if math.random(10) == 1 then
                local ruin = math.random(4, 5)
    
                self:setTile(x, height - 1, ruin)
            end

            for i = 0, 1 do
                for y = surface + 1, self.mapHeight do
                    self:setTile(x + i, y, TILE_DIRT)
                end
            end

            x = x + 2

        -- spawns a dragon statue ruin
        elseif math.random(40) == 1 then

            local height = math.random(1, 2) + surface

            for i = 0, 1 do
                self:setTile(x + i, surface, TILE_SURFACE)
                for y = surface + 1, self.mapHeight do
                    self:setTile(x + i, y, TILE_DIRT)
                end
            end

            self:setTile(x, height, DRAGON_TL) 
            self:setTile(x + 1, height, DRAGON_TR) 
            self:setTile(x, height + 1, DRAGON_BL) 
            self:setTile(x + 1, height + 1, DRAGON_BR) 

            x = x + 2

        -- spawns a diety statue ruin
        elseif math.random(15) == 2 then

            local height = math.random(1, 2) + surface

            self:setTile(x, surface, TILE_SURFACE)
            
            for y = surface + 1, self.mapHeight do
                self:setTile(x , y, TILE_DIRT)
            end

            self:setTile(x, height, DIETY_TOP)
            self:setTile(x, height + 1, DIETY_MIDDLE)
            self:setTile(x, height + 2, DIETY_BOTTOM)

            x = x + 1

        -- spawns a dirt column with various ruins inside    
        elseif math.random(10) ~= 1 then

            self:setTile(x, surface, TILE_SURFACE)

            for y = surface + 1, self.mapHeight do
                self:setTile(x, y, TILE_DIRT)
                
                if math.random(20) == 2 then
                    self:setTile(x, y, SMALL_RUIN_1)
                elseif math.random(20) == 3 then
                    self:setTile(x, y, SMALL_RUIN_2)
                elseif math.random(20) == 4 then
                    self:setTile(x, y + 1, WALL_TOP) 
                    self:setTile(x, y + 2, WALL_BOTTOM)
                end
            end

            x = x + 1

        -- spawns a gap
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

        end
    end

end

function Map:update(dt)
    self.alpaca:update(dt)

    self.camX = math.max(0, math.min(self.alpaca.x - VIRTUAL_WIDTH / 2,
        math.min(self.mapWidthPixels - VIRTUAL_WIDTH, self.alpaca.x)))
end

-- returns an integer value for the tile at a given x-y coordinate
function Map:getTile(x, y)
    return self.tiles[(y - 1) * self.mapWidth + x]
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

function Map:collides(tile)
    -- define our collidable tiles
    local collidables = {TILE_SURFACE, PLATFORM_RIGHT, PLATFORM_LEFT, 
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

-- draws tiles at a given x-y coordinate
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
end