-- TODO:
-- handle id over network
-- handle ALL dynamics updates over network (to avoid the case when it's has slightly different positions probably because of some minor coordinate difference)
-- handle isJump over network (do I need this?)
--      handle projectiles over network
--      remove projectiles from over the screen size
--      screen to follow up player
--      detect projectiles collisions
-- handle window movement (???)
-- add gun to player -> point gun to the mouse (???)
-- TODO: the pushing issue fix creates another issue, when I can't get through the line between 2 dynamics (well, I can jump over it)

-- network test
local address, port = "127.0.0.1", 5555
---------------

local id = "player1"
local opponentId = "player2"

local fixedDT = 0.01666667
local jump = false
local jumpUpSpeed = 7
local jumpAngleSpeed = 50
local jumpLeftAngle = 120
local jumpRightAngle = 60
local animationSpeed = 0.4

local screenWidth = 1600
local screenHeight = 900
local screenFlags = {fullscreen = false} -- set fullscreen to avoid issues with pointer detached from crosshairs

-- proj test
local projs = {}
------------

function love.load()

    love.window.setMode(screenWidth, screenHeight, screenFlags)

    require("playerNetworkClass")
    -- TODO: spawn players in loop (I need number of players for match + players ids, probably I should get them from server)
    dynamic = Player:new(id, 1000, 0, nil, 32, 32, nil, 10)
    dynamic2 = Player:new(opponentId, 1050, 0, nil, 32, 32, nil, 10)

    -- TODO: spawn dynamics in loop
    dynamic3 = Dynamic:new(3, 300, 0, nil, nil, nil, nil, 10)
    dynamic4 = Dynamic:new(4, 600, 0, nil, nil, nil, nil, 10)
    dynamic4:setIsMovable(true)
    dynamic5 = Dynamic:new(5, 700, 0, nil, nil, nil, nil, 10)
    dynamic5:setIsMovable(true)

    require("staticClass")
    obstacles = {}

    -- animation test -- TODO: load graphics in loop for the number of players availible
    -- player 1
    imgRight1 = love.graphics.newImage("Pink_Monster_Run_6_right.png")
    imgLeft1 = love.graphics.newImage("Pink_Monster_Run_6_left.png")
    imgDeath1 = love.graphics.newImage("Pink_Monster_Death_8.png")
    -- player 2
    imgRight2 = love.graphics.newImage("Dude_Monster_Run_6_right.png")
    imgLeft2 = love.graphics.newImage("Dude_Monster_Run_6_left.png")
    imgDeath2 = love.graphics.newImage("Dude_Monster_Death_8.png")

    dynamic:addAnimation(imgRight1, 32, 32, animationSpeed)
    dynamic:addAnimation(imgLeft1, 32, 32, animationSpeed)
    dynamic:addAnimation(imgDeath1, 32, 32, animationSpeed)
    dynamic:setAnimation(1)

    dynamic2:addAnimation(imgRight2, 32, 32, animationSpeed)
    dynamic2:addAnimation(imgLeft2, 32, 32, animationSpeed)
    dynamic2:addAnimation(imgDeath2, 32, 32, animationSpeed)
    dynamic2:setAnimation(1)
    -----------------

    obstacles = {
        dynamic,
        dynamic2,
        dynamic3,
        dynamic4,
        dynamic5
    }

    -- create platforms -- TODO: spawn in loop
    spawnObstacle(150, 150, 300, 50)
        spawnObstacle(350, 200, 300, 50)

        spawnObstacle(350, 350, 450, 50)

                spawnObstacle(650, 650, 600, 50)

    spawnObstacle(0, 1000, 5000, 50)
    -------------------

    -- network test
    dynamic:connect(address, port)
    ---------------

    sprites = {}
    sprites.crosshairs = love.graphics.newImage('crosshairs.png')
    love.mouse.setVisible(false)

    gameState = 1
end

dtotal = 0
function love.update(dt)
    dtotal = dtotal + dt

    if dtotal >= fixedDT then
        dtotal = dtotal - fixedDT
        dt = fixedDT

        if gameState == 2 then
            if jump then
                if love.keyboard.isDown("a") then
                    dynamic:throwAngle(jumpAngleSpeed, jumpLeftAngle)
                elseif love.keyboard.isDown("d") then
                    dynamic:throwAngle(jumpAngleSpeed, jumpRightAngle)
                else
                    dynamic:throwUp(jumpUpSpeed)
                end
            else
                if love.keyboard.isDown("a") then
                    dynamic:update(dt, obstacles, "left")
                elseif love.keyboard.isDown("d") then
                    dynamic:update(dt, obstacles, "right")
                else
                    dynamic:update(dt, obstacles, "none") -- have to clear previous with NON nil value
                end
            end

            for i,o in ipairs(obstacles) do
                print(o.type)
                if o.type == "player" and o.id ~= id then
                    o:update(dt, obstacles)
                    shootNetworkProj(o)
                elseif o.type == "dynamic" then
                    o:update(dt, obstacles)
                elseif o.type == "static" then
                    o:update(dt)
                end
            end

        end

    end

    -- network test
    local opponents = {}
    opponents[dynamic2.id] = dynamic2
    dynamic:updateOpponents(opponents)
    gameState = dynamic:networkUpdate(dt)
    ---------------

    jump = false

    -- proj test
    -- print(#projs)

    for i,p in ipairs(projs) do
        p.x = p.x + math.cos(p.direction) * p.speed * dt
        p.y = p.y + math.sin(p.direction) * p.speed * dt
    end

    for i=#projs, 1, -1 do
        local p = projs[i]
        if p.x > love.graphics.getWidth() + screenWidth/2 or p.x < 0 - screenWidth/2 or p.y > love.graphics.getHeight() + screenHeight/2 or p.y < 0 - screenHeight/2 or p.isDead == true then
            table.remove(projs, i)
        end
    end

    for i,o in ipairs(obstacles) do
        for n,p in ipairs(projs) do
            if isCollided(o, p) then
                p.isDead = true
            end
        end
    end

    for i=#obstacles, 1, -1 do
        local o = obstacles[i]
        if o.isDead == true then
            table.remove(obstacles, i)
        end
    end
    ------------
end

function love.draw()

    -- follow player test
    love.graphics.push()
    love.graphics.translate(-dynamic.x+(screenWidth/2), -dynamic.y+(screenHeight/2))
        -- draw map here

        for i,o in ipairs(obstacles) do
            if o.type == "player" then
                o:draw(true)
            else
                o:draw()
            end
        end

        love.graphics.draw(sprites.crosshairs, love.mouse.getX()-20, love.mouse.getY()-20)

        for i,p in ipairs(projs) do
            love.graphics.circle("fill", p.x, p.y, p.radius)
        end
        ------------

    love.graphics.pop()
    -- draw gui here

    love.graphics.print("Current FPS: "..tostring(love.timer.getFPS( )), 10, 10)
    love.graphics.print("Player's X: "..tostring(dynamic.x).. " Y: "..tostring(dynamic.y), 10, 30)

end

function love.keypressed(key)
    if key == "space" then
        jump = true
    end
end

function spawnObstacle(x, y, width, height)
    obstacle = Static.new(x, y, nil, width, height)
    table.insert(obstacles, obstacle)
end

-- proj test
function love.mousepressed(x, y, button, istouch, presses)
    if button == 1 and gameState == 2 then
        shootProj(dynamic)
    end
end

function shootProj(player)
    local proj = {}

    proj.x = player.x + player.width/2
    proj.y = player.y + player.height/2
    proj.radius = 3

    proj.speed = 300
    proj.direction = playerMouseAngle(player)
    proj.isDead = false

    proj.source = player.id

    player:storeProj(proj.direction, proj.x, proj.y)

    table.insert(projs, proj)
end

function shootNetworkProj(player)
    -- print(player.shoot)

    if player.shoot then
        local proj = {}

        proj.x = player.projStartCoords[1]
        proj.y = player.projStartCoords[2]
        proj.radius = 3

        proj.speed = 300
        proj.direction = player.projAngle
        proj.isDead = false

        proj.source = player.id

        table.insert(projs, proj)
    end
    player.shoot = false

    -- print(player.shoot)
end

function playerMouseAngle(player)
    local x = player.x + player.width/2
    local y = player.y + player.height/2

    local mX = love.mouse.getX()
    local mY = love.mouse.getY()
    -- return math.atan2(y - love.mouse.getY(), x - love.mouse.getX()) + math.pi -- this is getting from PLAYER to MOUSE but rotated on 180 deg (Pi)
    return math.atan2(mY - y, mX - x) -- this is without additional rotation
end

function isCollided(o, p)
    local pCenterX = p.x + p.radius/2
    local pCenterY = p.y + p.radius/2
    local res = false
    if o.id ~= p.source then
        res = pCenterX < o.x + o.width and
            pCenterX > o.x and
            pCenterY < o.y + o.height and
            pCenterY > o.y
        if res and (o.type == "dynamic" or o.type == "player") then
            o:handleProj()
        end
    else
        res = false
    end
    return res
end
------------
