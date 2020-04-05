WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 720

VIRTUAL_WIDTH = 432
VIRTUAL_HEIGHT = 243

PADDLE_SPEED =200 --200 pixel per second
PADDLE_SPEED_AI = 115

Class = require 'class'
push = require 'push'

require 'Ball'
require 'Paddle'


function love.load()
    math.randomseed(os.time()) 
    love.graphics.setDefaultFilter('nearest', 'nearest')

    love.window.setTitle('Pong')

    smallFont = love.graphics.newFont('font.ttf', 8)
    scoreFont = love.graphics.newFont('font.ttf', 32)
    victoryFont = love.graphics.newFont('font.ttf', 16)
    love.graphics.setFont(smallFont)

    sounds = {
        ['paddle_hit'] = love.audio.newSource('sounds/paddle_hit.wav', 'static'),
        ['score'] = love.audio.newSource('sounds/score.wav', 'static'),
        ['wall_hit'] = love.audio.newSource('sounds/wall_hit.wav', 'static')
    }

    --default values
    player1Score = 0
    player2Score = 0

    servingPlayer = math.random(2) == 1 and 1 or 2 -- who is serving, random between 1 and 2

    winningPlayer = 0

    StartMoving = 0

    paddel1 = Paddle(10, 30, 5, 20)
    paddel2 = Paddle(VIRTUAL_WIDTH - 15, VIRTUAL_HEIGHT -30, 5, 20)
    ball = Ball(VIRTUAL_WIDTH /2 -2, VIRTUAL_HEIGHT/2 -2, 4, 4)

    if servingPlayer == 1 then
        ball.dx = 100
    else
        ball.dx = -100
    end

    gameState = 'start'

    push:setupScreen(VIRTUAL_WIDTH,VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, {
        fullscreen = false,
        vsync = true,
        resizable = true
    })
end

function love.resize(w,h)
    push:resize(w,h)
end

function love.update(dt)

    if gameState == 'serve' then
        -- before switching to play, initialize ball's velocity based
        -- on player who last scored
        ball.dy = math.random(-50, 50)
        if servingPlayer == 1 then
            ball.dx = math.random(140, 200)--100
        else
            ball.dx = -math.random(140, 200) -- -100
        end
    end

    -- update score

    if ball.x <= 0 then
        player2Score = player2Score + 1
        servingPlayer = 1
        sounds['score']:play()
        ball:reset()

        if player2Score >=5 then
            gameState = 'victory'
            winningPlayer = 2
            else
            gameState = 'serve'
            end
    end

    if ball.x >= VIRTUAL_WIDTH -4 then
        player1Score = player1Score + 1
        servingPlayer = 2
        sounds['score']:play()
        ball:reset()
        if player1Score >=5 then
            gameState = 'victory'
            winningPlayer = 1
            else
            gameState = 'serve'
            end
    end


    --handle collaiding
    if ball:collides(paddel1) then
        -- deflact ball to the right
        ball.dx = -ball.dx * 1.03
        ball.x = paddel1.x + 5
        if ball.dy < 0 then
            ball.dy = -math.random(10, 150)
        else
            ball.dy = math.random(10, 150)
        end
        sounds['paddle_hit']:play()

    end

    if ball:collides(paddel2) then
        -- deflact ball to the left 
        ball.dx = -ball.dx * 1.03
        ball.x = paddel2.x - 4
        if ball.dy < 0 then
            ball.dy = -math.random(10, 150)
        else
            ball.dy = math.random(10, 150)
        end
        sounds['paddle_hit']:play()
    end

    if ball.y <=0 then --top of the screen deflact he ball down
        ball.dy = -ball.dy
        ball.y = 0
        sounds['wall_hit']:play()
    end

    if ball.y >= VIRTUAL_HEIGHT -4 then
        ball.dy = -ball.dy
        ball.y = VIRTUAL_HEIGHT -4
        sounds['wall_hit']:play()
    end
    -- move the paddel and make sure that they are not go over the screen

    paddel1:update(dt)
    paddel2:update(dt)
    --[[
    if love.keyboard.isDown('w') then 
        paddel1.dy = -PADDLE_SPEED
    elseif love.keyboard.isDown('s') then
        paddel1.dy = PADDLE_SPEED
    else
        paddel1.dy = 0
    end
    ]]
    if gameState ~= 'start' then
        player2AI(dt)

    end

    if love.keyboard.isDown('up') then
        paddel2.dy = -PADDLE_SPEED
    elseif love.keyboard.isDown('down') then
        paddel2.dy = PADDLE_SPEED
    else
        paddel2.dy = 0
    end

    if gameState == 'play' then 
        ball:update(dt)
    end
end

function love.keypressed(key)
    if key == 'escape' then
        love.event.quit()
    elseif key == 'enter' or key == 'return' then 
        if gameState == 'start' then
            gameState = 'serve'
        elseif gameState == 'victory' then
            gameState = 'start'
            player1Score = 0
            player2Score = 0
        elseif gameState == 'serve' then
        gameState = 'play'
        end
    end
end

function love.draw()
    push:apply('start')
    -- background
    love.graphics.clear(40/255,45/255,52/255,255/255)
    --print hello pong
    love.graphics.setFont(smallFont) 

    if gameState == 'start' then
        love.graphics.printf("Welcome to Pong!", 0, 10, VIRTUAL_WIDTH, 'center')
        love.graphics.printf("Press Enter to Play!", 0, 20, VIRTUAL_WIDTH, 'center')
    elseif gameState == 'serve' then
        love.graphics.printf("Player " .. tostring(servingPlayer) .. "'s turn!'",  0, 10, VIRTUAL_WIDTH, 'center')
        love.graphics.printf("Press Enter to Serve!", 0, 20, VIRTUAL_WIDTH, 'center')

    elseif gameState == 'victory' then
        --draw victory msg
        love.graphics.setFont(victoryFont)
        love.graphics.printf("Player " .. tostring(winningPlayer) .. "' wins!'",  0, 10, VIRTUAL_WIDTH, 'center')
        love.graphics.setFont(smallFont)
        love.graphics.printf("Press Enter to Serve!", 0, 42, VIRTUAL_WIDTH, 'center')

    elseif gameState == 'play' then
        --no UI msg to display

    end


    displayScore()

    -- print 2 peddals
    paddel1:render()
    paddel2:render()

    --print ball
    ball:render()

    -- displat fps
    displayFPS()

    push:apply('end')
end

function displayFPS()
    love.graphics.setColor(0, 1, 0 , 1) -- change text color to green
    love.graphics.setFont(smallFont)
    love.graphics.print('FPS: ' .. tostring(love.timer.getFPS( )), 40, 20) -- .. is like + in java/python
    love.graphics.setColor(1, 1, 1, 1) -- return to default color (white)
    --love.graphics.print('PADDLE_SPEED_AI: ' .. tostring(PADDLE_SPEED_AI), 40, 30) 
    --love.graphics.print('paddel2 y: ' .. tostring(paddel2.y), 40, 40) 

end

function displayScore()
    -- print score
    love.graphics.setFont(scoreFont)
    love.graphics.print(player1Score, VIRTUAL_WIDTH/2 -50, VIRTUAL_HEIGHT/3)
    love.graphics.print(player2Score, VIRTUAL_WIDTH/2 +50, VIRTUAL_HEIGHT/3)
end

function player2AI(dt)


    --[[
    if ball:collides(paddel2) then
        paddel1.dy = -PADDLE_SPEED*5
        paddel1:update(dt)

    end
    
    if ball:collides(paddel1) then
        StartMoving = 1
    elseif ball:collides(paddel2) then
        StartMoving = 1
    end

        if ball.y   < paddel1.y + paddel1.height/2 then
        paddel1.y = paddel1.y-1 
    elseif ball.y  > paddel1.y + paddel1.height/2 then
        paddel1.y = paddel1.y +1]]

    if ball:collides(paddel1) then -- random speed for human felling
        PADDLE_SPEED_AI = math.random(105, 160)
    end

    if ball.y  < paddel1.y  then -- if ball is above the top of the paddel, move paddel up
        paddel1.dy = -PADDLE_SPEED_AI
    elseif ball.y < paddel1.height + paddel1.y then -- if the ball is not above the top of the paddel but above the buttom of the paddel move to ball position (remove jitter)
        paddel1.y = ball.y
    end
    

    if ball.y  > paddel1.y + paddel1.height then -- if ball is bellow the buttom of the paddel, move paddel up
        paddel1.dy = PADDLE_SPEED_AI
    elseif ball.y >  paddel1.y then -- if the ball is not bellow the buttom of the paddel but bellow the top of the paddel move to ball position (remove jitter)
        paddel1.y = ball.y
    end

    --fix bug that the paddel go a littel beyond the screen
    if paddel1.y < 0 then -- if dy< 0 it goes up and reverse
        paddel1.y = 0
    elseif paddel1.y > VIRTUAL_HEIGHT-20 then
        paddel1.y = VIRTUAL_HEIGHT-20
    end


end
