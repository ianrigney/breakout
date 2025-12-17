-- IAN RIGNEY CS-371-1 MOBILE COMPUTING ASSIGNMENT 4
-- authors note: this one was a little easier than the one on the exam 2
-- didnt have to tango with images regarding movement and stuff

local composer = require("composer")
local widget = require("widget")
local json = require("json")

-- these variables are local to the module
local nameText
local scoreLines = {}

-- create this scene
local scene = composer.newScene()

-- double tapping anywhere goes back to first sceneGroup
local function tapListener(event)
    if event.numTaps == 2 then
        composer.gotoScene("splash", {effect = "crossFade"})
    end
end

function scene:create(event)
    local sceneGroup = self.view

    nameText = display.newText("GAME OVER", display.contentCenterX, display.contentCenterY - 250, native.systemFontBold, 40)
    sceneGroup:insert(nameText)
    
    -- leaderboard text objects
    local yPos = display.contentCenterY + 240
    display.newText({
        parent = sceneGroup,
        text = "Leaderboard",
        x = display.contentCenterX,
        y = yPos,
        font = native.systemFontBold,
        fontSize = 40
    })
    for i = 1,5 do
        yPos = yPos + 48
        local t = display.newText({
            parent = sceneGroup,
            text = "---",
            x = display.contentCenterX,
            y = yPos,
            font = native.systemFontBold,
            fontSize = 40
        })
        table.insert(scoreLines, t)
    end

    function handlePlayButton(event)
        -- effects ref: https://docs.coronalabs.com/api/library/composer/gotoScene.html
        composer.gotoScene("splash", {effect = "flip"})
        return true
    end

    -- set up new game button
    local button = widget.newButton({id="start_game", x=display.contentCenterX, y=display.contentCenterY, onPress=handlePlayButton, 
        shape="roundedRect",
        cornerRadius=32,
        width=display.contentWidth / 1.2,
        height=100,
        fillColor = {default = {0, 0, 0.5, 1}, over = {0, 0, 0.5, 1}},
        strokeColor = {default = {0, 0, 1, 1}, over = {1, 1, 1, 1}},
        labelColor = {default = {1, 1, 1, 1}, over = {1, 1, 1, 1}},
        strokeWidth = 8,
        label="New Game", fontSize=60})
    sceneGroup:insert(button)
    
end

-- show the game over / leaderboard screen
-- if text is passed to us via params then show it ("game over" and "victory")
-- fetch the leaderboard scores from the json file, if a score is passed to us
-- see if that score makes it on the leaderboard and if so update it and save 
-- the update then display the final leaderboard
function scene:show(event)
    if event.phase == "will" then
        nameText.text = event.params.text or ""

        -- fetch the high scores from the JSON file
        local path = system.pathForFile("highscores.json", system.DocumentsDirectory)
        local file, errorString = io.open(path, "r")
        if not file then
            -- JSON file does not exist, create empty dable with default high score
            highscores = {1000}
        else
            -- read the file, it comes in as text
            -- convert it back to a table
            local serialized = file:read("*a")
            highscores = json.decode(serialized)
            io.close(file)
        end

        -- if playerScore (param from previous scene) is valid (not nil) and higher than the lowest highscore stored,
        -- put playerScore on the table
        local playerScore = event.params.playerScore
        if playerScore ~= nil and ( playerScore > highscores[#highscores] or #highscores < 5 ) then
            -- player makes the leaderboard! add the score
            table.insert(highscores, playerScore)
            -- now re-sort the table, descending
            table.sort(highscores, function(a,b) return b<a end)
            -- now make sure the table is no longer than 5 entries
            while #highscores > 5 do
                table.remove(highscores, #highscores)
            end
            -- now save the new table
            local file, errorString = io.open(path, "w")
            if not file then
                print("**** Can't save highscores", path, errorString)
            else
                local serialized = json.encode(highscores)
                file:write(serialized)
                io.close(file)
            end
        end
        -- write the highscores to the text objects
        for i = 1, #scoreLines do
            if i > #highscores then
                scoreLines[i].text = "---"
            else
                scoreLines[i].text = tostring(highscores[i])
            end
        end
        
        Runtime:addEventListener("tap", tapListener)

    end
end

function scene:hide(event)
    if event.phase == "will" then
        Runtime:removeEventListener("tap", tapListener)
    end
end    

scene:addEventListener("create", scene)
scene:addEventListener("show", scene)
scene:addEventListener("hide", scene)
-- scene:addEventListener("destroy", scene)

return scene