-- IAN RIGNEY CS-371-1 MOBILE COMPUTING ASSIGNMENT 4
-- authors note: this one was a little easier than the one on the exam 2
-- didnt have to tango with images regarding movement and stuff

local composer = require("composer")
local widget = require("widget")

local scene = composer.newScene()

function scene:create(event)
    local sceneGroup = self.view

    -- display name as requirements ask
    local nameText = display.newText("Ian Rigney", display.contentCenterX, display.contentCenterY - 250, native.systemFontBold, 40)
    sceneGroup:insert(nameText)

    -- reset game settings to default values
    selectedLevel = "1"
    ballSpeed = 1

    function handlePlayButton(event)
        composer.gotoScene("play", {effect = "slideLeft", params = {level = selectedLevel, speed = ballSpeed}})
        return true
    end

    function goLeader(event)
        composer.gotoScene("gameover", {effect = "slideDown", params = {playerScore = nil, text = nil}})
        return true
    end

    -- start game button setup
    local button = widget.newButton({id = "start_game", x = display.contentCenterX, y = display.contentCenterY, onPress = handlePlayButton,
        shape = "roundedRect",
        cornerRadius = 16,
        width = 400,
        height = 100,
        fillColor = {default = {1, 0, 0, 1}, over = {1, 0.1, 0.7, 0.4}},
        strokeColor = {default = {1, 0.4, 0.1}, over = {0.8, 0.8, 1, 1}},
        strokeWidth = 4,
        label = "Start Game", fontSize = 60})
    sceneGroup:insert(button)

    -- leaderboard button setup
    button = widget.newButton({id="leaderboard", x=display.contentCenterX, y=display.contentCenterY+150, onPress=goLeader, 
        shape="roundedRect",
        cornerRadius=32,
        width=display.contentWidth / 1.2,
        height=100,
        fillColor = { default={0,0,0.5,1}, over={0,0,0.5,1} },
        strokeColor = { default={0,0,1,1}, over={0,1,0,1} },
        labelColor = { default={1,1,1,1}, over={1,1,1,1} },
        strokeWidth = 8,
        label="Leaderboard", fontSize=60})
    sceneGroup:insert(button)

    -- switch handler used by level radio buttons
    local function onSwitchPress(event)
        local switch = event.target
        print(switch.id)
        selectedLevel = switch.id
    end

    -- slider handler for speed
    local function handleSpeedSlider(event)
        ballSpeed = 1 + math.floor(event.target.value / 100.0 * 9 + 0.5)
        speedDisplay.text = tostring(ballSpeed)
    end

    -- radio buttons setup amd display
    local radioGroup = display.newGroup()
    sceneGroup:insert(radioGroup)
    local radio1 = widget.newSwitch({left = display.contentCenterX - 120, top = display.contentHeight - 50, style = "radio", id = "1", initialSwitchState = true, onPress = onSwitchPress})
    radioGroup:insert(radio1)

    local radio2 = widget.newSwitch({left = display.contentCenterX, top = display.contentHeight - 50, style = "radio", id = "2", onPress = onSwitchPress})
    radioGroup:insert(radio2)

    local radio3 = widget.newSwitch({left = display.contentCenterX + 120, top = display.contentHeight - 50, style = "radio", id = "3", onPress = onSwitchPress})
    radioGroup:insert(radio3)

    -- labels for radio buttons
    local opts = {parent = sceneGroup, text = "Level 1", x = display.contentCenterX - 100, y = display.contentHeight - 75, font = native.systemFont, fontSize = 32}
    display.newText(opts)

    opts.x = display.contentCenterX
    opts.text = "Level 2"
    display.newText(opts)

    opts.x = display.contentCenterX + 100
    opts.text = "Level 3"
    display.newText(opts)

    -- set up and display for slider
    local speedSlider = widget.newSlider({id = "speed_slider", x = display.contentCenterX, y = display.contentHeight - 150, orientation = "horizontal", width = 200, value = ballSpeed, listener = handleSpeedSlider})
    sceneGroup:insert(speedSlider)
    speedDisplay = display.newText({text = tostring(ballSpeed), parent = sceneGroup, x = display.contentCenterX, y = display.contentHeight - 175, font = native.systemFont, fontSize = 32, align = "center"})

end

scene:addEventListener("create", scene)
-- scene:addEventListener("show", scene)
-- scene:addEventListener("hide", scene)
-- scene:addEventListener("destroy", scene)

return scene