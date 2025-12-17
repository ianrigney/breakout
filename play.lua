-- IAN RIGNEY CS-371-1 MOBILE COMPUTING ASSIGNMENT 4
-- authors note: this one was a little easier than the one on the exam 2
-- didnt have to tango with images regarding movement and stuff

-- boolean just for testing (demo playing)
local demoPlay = false

local composer = require("composer")
local widget = require("widget")
local physics = require("physics")

-- create this scene
local scene = composer.newScene()

-- variables are "local" to this module
local bg, ball, paddle, scoreHUD, reds, greens, yellows
local score, brickCount, ballInPlay
local gameLevel, ballSpeed

-- each level of the game has different size paddle
-- i increased these to scale with the increased screen size
-- and to make speed 10 actually possible for a human being
local paddleWidths = {120, 90, 60}

-- table for the background
local backgroundTable = {
    "background1.png",
    "background2.png",
    "background3.png"
}

-- preload sounds
local soundTable = {
    brickhit = audio.loadSound("brickhit.wav"),
    paddlehit = audio.loadSound("paddlehit.wav"),
    cheer = audio.loadSound("cheer.wav"),
    lostball = audio.loadSound("lostball.wav")
}

-- worlds dumbest AI player (for testing)
local function followBall()
    if ball.isVisible then
        paddle.x = ball.x
        timer.performWithDelay(10, followBall, 1)
    end
end

-- this function creates a new ball, sets up its physics, and gets it moving
local function newBall()
    ball.x = 50 + math.floor(math.random() * (display.contentWidth - 100)) -- not within 50 pixels of the sides
    ball.y = display.contentCenterY + math.floor(math.random() * 100) - 50
    ball.isVisible = true
    local xf = 200 + (ballSpeed - 1) * 400 / 9
    local yf = xf
    if math.random() >= 0.5 then
        xf = -xf
    end
    ball:applyForce(xf, yf, ball.x, ball.y)

    if demoPlay then
        timer.performWithDelay(10, followBall, 1)
    end
end

-- this function stops the ball from moving
-- and removes it from the displaye but does not remove or destroy the object
local function stopBall()
    ball:setLinearVelocity(0, 0)
    ball.isVisible = false
end

-- timer event handler to move to the game over screen
local function gameOver(event)
    local text = event.source.params.text
    composer.gotoScene("gameover", {effect = "slideLeft", params = {playerScore = score, text = text}})
end

-- initialize for a new level of gameplay
local function newLevel()
    scene:discardBricks()

    -- set this level's background
    local background = display.newImageRect(backgroundTable[gameLevel], display.contentWidth, display.contentHeight)
    while bg.numChildren > 0 do
        bg:remove(1)
    end
    bg:insert(background)
    bg.x = display.contentCenterX
    bg.y = display.contentCenterY

    -- set this level's paddle width
    paddle.width = paddleWidths[gameLevel]
    paddle.x = display.contentCenterX

    -- remove and re-add the paddle to physics, so it uses the updated paddle size
    -- only remove if it is already a physics object, though, so we dont get a warning logged
    if paddle.bodyType == "kinematic" then
        physics.removeBody(paddle)
    end
    physics.addBody(paddle, "kinematic")
    
    -- draw this level's brick pattern
    scene:drawBricks()
end

-- helper function, cycle to the next level
local function nextLevel()
    newLevel()
    newBall()
end

-- double tapping anywhere goes back to first sceneGroup
local function tapListener(event)
    if event.numTaps == 2 then
        stopBall()
        composer.gotoScene("splash", {effect = "crossFade"})
    end
end

-- youll never guess what this is doing by reading the first line
function scene:create(event)
    print("play scene create")
    local sceneGroup = self.view

    -- put background in its own display group FIRST so it is behind all the rest
    bg = display.newGroup()
    sceneGroup:insert(bg)

    -- borders
    borders = {}
    borders.top = display.newRect(0, 40, display.contentWidth, 10)
    sceneGroup:insert(borders.top)
    borders.left = display.newRect(0, 0, 10, display.contentHeight)
    sceneGroup:insert(borders.left)
    borders.right = display.newRect(display.contentWidth-10, 0, 20, display.contentHeight)
    sceneGroup:insert(borders.right)
    borders.bottom = display.newRect(0, display.contentHeight-10, display.contentWidth, 10)
    sceneGroup:insert(borders.bottom)

    borders.top.anchorX = 0
    borders.left.anchorX = 0
    borders.right.anchorX = 0
    borders.bottom.anchorX = 0

    borders.top.anchorY = 0
    borders.left.anchorY = 0
    borders.right.anchorY = 0
    borders.bottom.anchorY = 0

    borders.top:setFillColor(0.5, 0.5, 0.5)
    borders.left:setFillColor(0.5, 0.5, 0.5)
    borders.right:setFillColor(0.5, 0.5, 0.5)
    borders.bottom:setFillColor(0.5, 0.5, 0.5)

    -- set up paddle
    paddle = display.newRect(display.contentCenterX, display.contentHeight-50, 60, 12)
    sceneGroup:insert(paddle)
    paddle:setFillColor(0.529, 0.808, 0.922)

    -- provided function for moving the paddle
    local function move ( event )
        if event.phase == "began" then		
            paddle.markX = paddle.x 
        elseif event.phase == "moved" then	 	
            local x = (event.x - event.xStart) + paddle.markX
        
            if (x <= 10 + paddle.width/2) then
                paddle.x = 10+paddle.width/2
            elseif (x >= display.contentWidth-10-paddle.width/2) then
                paddle.x = display.contentWidth-10-paddle.width/2
            else
                paddle.x = x	
            end
        end
    end -- end of move()

    -- detect hit on paddle to play sound
    local function paddlehit(event)
        if event.phase == "ended" then
            audio.stop()
            audio.play(soundTable.paddlehit)
        end
    end

    paddle:addEventListener("collision", paddlehit)
    Runtime:addEventListener("touch", move)

    -- create the ball
    ball = display.newCircle(display.contentCenterX, display.contentCenterY, 10)
    ball.isVisible = false
    sceneGroup:insert(ball)

    -- special handling for bottom -- if we hit it, the ball goes away
    -- if there are no balls left, go to the game over screen
    -- otherwise start a new ball in play
    local function bottomCollision(event)
        if event.other == ball and event.phase == "ended" then
            -- stop the ball's movement and make it invisible
            stopBall()

            audio.stop()
            audio.play(soundTable.lostball)

            -- next ball maybe
            ballInPlay = ballInPlay - 1
            if ballInPlay < 1 then
                local t = timer.performWithDelay(1500, gameOver, 1)
                t.params = {text = "GAME OVER"}
                return true
            end

            -- set a timer to create a new ball and resume play
            timer.performWithDelay(1500, newBall, 1)
        end
        return true
    end
    borders.bottom:addEventListener("collision", bottomCollision)

    -- score HUD
    scoreHUD = display.newText({parent = sceneGroup, text = "Score: 0", x = display.contentCenterX, y = 15, font = native.systemFontBold, fontSize = 30, align = "center"})

    reds = {}
    greens = {}
    yellows = {}

end -- scene:create

-- timer function to remove brick that was hit form the display, update score, etc
-- we do this here rather than in the collision handler because you cant do some operations
-- in the collision handler (limitation of the physics lib)
local function removeBrick(event)
    local color = event.source.params.color
    local index = event.source.params.index
    print("removeBrick", color, index)

    if color == "R" then
        physics.removeBody(reds[index])
        reds[index]:removeSelf()
        reds[index] = nil
        score = score + 1000
    elseif color == "G" then
        physics.removeBody(greens[index])
        greens[index]:removeSelf()
        greens[index] = nil
        score = score + 100
    else
        physics.removeBody(yellows[index])
        yellows[index]:removeSelf()
        yellows[index] = nil
        score = score + 50
    end
    
    scoreHUD.text = "Score: " .. tostring(score)

    -- reduce brickcount by 1 for each brick broken
    -- check if all bricks hit, if true, stop the ball and go to next level
    -- if on final level, display victory ON gameover scene
    brickCount = brickCount - 1
    if brickCount <= 0 then
        stopBall()
        gameLevel = gameLevel + 1
        if gameLevel <= 3 then
            timer.performWithDelay(1500, nextLevel, 1)
        else
            local t = timer.performWithDelay(1500, gameOver, 1)
            t.params = {text = "VICTORY"}
        end
        
        -- start level complete sound
        audio.stop()
        audio.play(soundTable.cheer)
    end
end

-- handle a post-collision event for a brick, determine which brick, score it, and remove it
local function brickCollision(event)
    -- find brick thta was hit using its ID. the ID is set up so the first character
    -- is the color (R, G, Y), and the rest of the ID is the index (number) of the brick.
    -- this is faster/cleaner than going through all three tables looking for a brick that
    -- matches the event target
    if event.target.id ~= nil then
        local color = event.target.id:sub(1, 1) -- first character is color
        local index = tonumber(event.target.id:sub(2)) -- rest is the inde in its color table.concat
        print("Hit to brick", color, index)

        -- remove brick's ID, so its "handled"
        event.target.id = nil

        -- start sound
        audio.stop()
        audio.play(soundTable.brickhit)

        -- pass the work to a timer function. we cant do somethings here, like remove brick from physics
        local t = timer.performWithDelay(5, removeBrick)
        t.params = {color = color, index = index}
    end

    return true
end

-- draw the brick pattern for the current level
-- as we draw store the bricks in tables for collision
-- detection and setup physics
function scene:drawBricks()
    -- brick drawing
    local sceneGroup = self.view

    brickCount = 0
    reds = {}
    greens = {}
    yellows = {}

    local function createRed (xPos, width, id)
        local red = display.newRect(xPos, 110, width, 20)
        sceneGroup:insert(red)
        red:setFillColor(1,0,0)
        red.id = "R" .. tostring(id) -- see comment in brickCollision() above
        red:addEventListener("postCollision", brickCollision)
        reds[id] = red
        brickCount = brickCount + 1
        physics.addBody(red, "static")
    end

    if gameLevel == 1 then
        for i=1,9 do
            createRed(64*i, 60, i)
        end
    elseif gameLevel == 2 then
        for i = 1,19,2 do
            createRed(32*i, 30, i)
        end
    elseif gameLevel == 3 then
        for i = 1,19 do
            createRed(32*i, 30, i)
        end
    end

    local function createGreen (xPos, width, id)
        local green = display.newRect(xPos, 133, width, 20)
        sceneGroup:insert(green)
        green:setFillColor(0,1,0)
        green.id = "G" .. tostring(id)
        green:addEventListener("postCollision", brickCollision)
        greens[id] = green
        brickCount = brickCount + 1
        physics.addBody(green, "static")
    end

    if gameLevel == 1 then
        for i=1,9 do
            createGreen(64*i, 60, i)
        end
    elseif gameLevel == 2 then
        for i = 1,12 do
            createGreen(48*i, 42, i)
        end
    elseif gameLevel == 3 then
        for i = 1,19 do
            createGreen(32*i, 30, i)
        end
    end

    local function createYellow (xPos, width, id)
        local yellow = display.newRect(xPos, 158, 60, 20)
        sceneGroup:insert(yellow)
        yellow:setFillColor(1,1,0)
        yellow.id = "Y" .. tostring(id)
        yellow:addEventListener("postCollision", brickCollision)
        yellows[id] = yellow
        brickCount = brickCount + 1
        physics.addBody(yellow, "static")
    end

    for i=1,9 do
        createYellow(64*i, 60, i)
    end
end

-- remove bricks from scene that havent been removed by collisions
function scene:discardBricks()
    local function discard(t)
        -- must use pairs() here, not ipairs(), because of nil values in table
        -- will stop ipairs() from touching every member of the table
        for i,brick in pairs(t) do
            if brick ~= nil then
                -- physics.removeBody(brick)
                brick:removeSelf()
            end
        end
    end
    discard(reds)
    discard(greens)
    discard(yellows)
    reds = {}
    greens = {}
    yellows = {}
end

-- show objects for this scene and start gameplay
function scene:show(event)
    print("show", event.phase)
    if event.phase == "will" then
        -- reset for new game
        gameLevel = tonumber(event.params.level)
        ballSpeed = event.params.speed
        print("New Game! Play Level", gameLevel, "ball speed", ballSpeed)

        score = 0
        scoreHUD.text = "Score: " .. tostring(score)
        ballInPlay = 3
        ball.x = display.contentCenterX
        ball.y = display.contentCenterY -- make sure ball is away from bricks and paddle

        physics.start()
        physics.setGravity(0, 0)
        physics.addBody(borders.top, "static")
        physics.addBody(borders.left, "static")
        physics.addBody(borders.right, "static")
        physics.addBody(borders.bottom, "static")
        -- physics.addBody(paddle, "kinematic") -- newLevel() will handle this
        physics.addBody(ball, "dynamic", {bounce = 1, density = 1, radius = ball.path.radius})
        -- bricks are added to the physics by drawBricks() called from newLevel() below
        newLevel()

        Runtime:addEventListener("tap", tapListener)
    elseif event.phase == "did" then
        -- launch the first ball
        newBall()
    end
end   

function scene:hide(event)
    print("hide", event.phase)
    if event.phase == "will" then
        -- stop game play
        self:discardBricks()
        physics.stop()
        Runtime:removeEventListener("tap", tapListener)
    end

    return true
end

function scene:destroy(event)
    print("destroy", event.phase)
    return true
end

scene:addEventListener("create", scene)
scene:addEventListener("show", scene)
scene:addEventListener("hide", scene)
scene:addEventListener("destroy", scene)

return scene