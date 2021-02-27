require("dynamicClass")

Animation = Dynamic:new()

function Animation:new(id, x, y, shape, width, height, baseSpeed, maxSpeed, angle, action, obstacles)
    local o = Dynamic:new(id, x, y, shape, width, height, baseSpeed, maxSpeed, angle, action, obstacles)
    setmetatable(o, self)
    self.__index = self

    o.animation = nil
    o.animations = {}

    return o
end

function Animation:addAnimation(image, width, height, duration)
    local animation = {}
    animation.spiteSheet = image
    animation.quads = {}
    animation.duration = duration or 1
    animation.currentTime = 0

    for y=0, image:getHeight()-height, height do
        for x=0, image:getWidth()-width, width do
            table.insert(animation.quads, love.graphics.newQuad(x, y, width, height, image:getDimensions()))
        end
    end

    table.insert(self.animations, animation)
end

-- function Animation:updateAnimation(self, dt)
function Animation.updateAnimation(self, dt)

    print("----------2-----------CALLBACK " .. dt)

    if self.animations then

        print("----------2.1-----------CALLBACK")

        if self.direction == "right" and #self.animations > 0 then
            self.animation = self.animations[1]
        elseif self.direction == "left" and #self.animations > 0 then
            print("----------2.1.1-----------CALLBACK")
            self.animation = self.animations[2]
        elseif #self.animations > 0 then
            self.animation = self.animations[1]
        end

        if self.animation and dt then

            print("----------2.1.2-----------CALLBACK")

            self.animation.currentTime = self.animation.currentTime + dt
            if self.animation.currentTime >= self.animation.duration then
                self.animation.currentTime = self.animation.currentTime - self.animation.duration
            end
        end
    end
end

function Animation:setAnimation(index)
    self.animation = self.animations[index]
end

function Animation:update(dt, obstacles, direction)
    print("----------0-----------PRE CALLBACK " .. dt)
    callbacks = {}
    left = function(s, t)
        -- Animation.updateAnimation(self, dt)

        print("----------1-----------CALLBACK " .. t)

        -- Animation:updateAnimation(s, t)
        Animation.updateAnimation(s, t)
    end
    callbacks["left"] = left

    o = Dynamic.update(self, dt, obstacles, direction, callbacks) -- for some reason I have to call Dynamic.update with explicit self and explicitly return the object
    return o
end

function Animation:draw(isAnimate)
    if self.animation then
        if isAnimate then
            spriteNum = math.floor(self.animation.currentTime/self.animation.duration * #self.animation.quads) + 1
            love.graphics.draw(self.animation.spiteSheet, self.animation.quads[spriteNum], self.x, self.y)
        elseif isAnimate == false then -- should be explicit "false" otherwise there are some frames when it's nil
            love.graphics.draw(self.animation.spiteSheet, self.animation.quads[1], self.x, self.y)
        end
    else
        love.graphics.rectangle("line", self.x, self.y, self.width, self.height)
    end
end
