Class = require 'class'
push = require 'push'

require 'Ball'
require 'Paddle'

WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 720

VIRTUAL_WIDTH = 432
VIRTUAL_HEIGHT = 243


--200 PIXELS PER SECOND
PADDLE_SPEED = 200



-- vsync syncs the frames with the monitor refresh rate to prevent tearing
-- functions have to end with end
function love.load()
	--initiate random
	math.randomseed(os.time())
	love.graphics.setDefaultFilter('nearest', 'nearest')
	
	smallFont = love.graphics.newFont('04b03.ttf', 8)

	victoryFont = love.graphics.newFont('04b03.ttf', 24)
	-- same font but 32 bit instead of 8
	scoreFont = love.graphics.newFont('04b03.ttf', 32)
	

	sounds = {
		['paddleHit'] = love.audio.newSource('paddlehit.wav', 'static'),
		['pointScored'] = love.audio.newSource('pointscore.wav', 'static'),
		['wallHit'] = love.audio.newSource('wallhit.wav', 'static')
	}

	--declare scores
	player1Score = 0
	player2Score = 0

	servingPlayer = math.random(2) == 1 and 1 or 2

	winningPlayer = 0

	--declare y co-ordinates
	paddle1 = Paddle(5, 20, 5, 20)
	paddle2 = Paddle(VIRTUAL_WIDTH - 10, VIRTUAL_HEIGHT - 30, 5, 20)

	ball = Ball(VIRTUAL_WIDTH/2 -2, VIRTUAL_HEIGHT/2 -2, 5, 5)

	if servingPlayer == 1 then 
		ball.dx = 100
	else
		ball.dx = -100
	end
	gameState = 'start'

	love.window.setTitle("Pong")
	-- object calling a method

	push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, {
		fullscreen = false,
		vsync = true,
		resizable = false
	})

end

-- set ball back to middle and send in random direction


--dt allows you to move things and normalises the scale/movement
function love.update(dt)

	paddle1:update(dt)
	paddle2:update(dt)

	if ball.x >= 0 and ball.dx > 0 then
		paddle2.y = ball.y - paddle2.height / 2
	end

	if ball.x <= 600 and ball.dx < 0 then
		paddle1.y = ball.y - paddle1.height / 2
	end


	-- update score if ball reaches sides of screen then reset game
	if ball.x <= 0 then
		player2Score = player2Score + 1
		servingPlayer = 1
		sounds['pointScored']:play()
		ball:reset()


		if player2Score >= 3 then
			gameState = 'victory'
			winningPlayer = 2
		else
			gameState = 'serve'
		end

		ball.dx =  100
		
	end

	if ball.x >= VIRTUAL_WIDTH-4 then
		player1Score = player1Score + 1
		servingPlayer = 2
		sounds['pointScored']:play()
		ball:reset()
		ball.dx = -100

		if player1Score >= 3 then
			gameState = 'victory'
			winningPlayer = 1
		else
			gameState = 'serve'
		end
		
	end

	--collision check per ball.lua
	if ball:collides(paddle1) then
		ball.dx = -ball.dx * 1.1
		ball.x = paddle1.x + 5

		sounds['paddleHit']:play()

		if ball.dy < 0 then
			ball.dy = -math.random(10,150)
		else
			ball.dy = math.random(10,150)
		end

	end
	
	if ball:collides(paddle2) then
		sounds['paddleHit']:play()
		ball.dx = -ball.dx * 1.1
		ball.x = paddle2.x - 5
		
		if ball.dy < 0 then
			ball.dy = -math.random(10,150)
		else
			ball.dy = math.random(10,150)
		end
	end

	if ball.y <= 0 then
		ball.dy = -ball.dy
		ball.y = 0
		sounds['wallHit']:play()
	end
	
	if ball.y >= VIRTUAL_HEIGHT - 4 then
		ball.dy = -ball.dy
		ball.y = VIRTUAL_HEIGHT - 4
		sounds['wallHit']:play()
	end


	-- if key pressed is w then move the paddle up but not bigger than top of screen i.e. y = 0
	if love.keyboard.isDown('w') then
		paddle1.dy = -PADDLE_SPEED
	elseif love.keyboard.isDown('s') then
		paddle1.dy = PADDLE_SPEED
	else
		paddle1.dy = 0
	end

	if love.keyboard.isDown('up') then
		paddle2.dy = -PADDLE_SPEED
	elseif love.keyboard.isDown('down') then
		paddle2.dy = PADDLE_SPEED
	else
		paddle2.dy = 0
	end

	if gameState == 'play' then
		ball:update(dt)
	end
end
-- exits the program when esc is pressed
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
	--begin rendering at virtual resolution
	push:apply('start')
	--clear is like fill and should be done before other drawings
	love.graphics.clear(40/255, 45/255, 52/255, 255/255)

	love.graphics.setFont(smallFont)
	if gameState == 'start' then
		love.graphics.printf("Welcome to Pong!", 0, 20,VIRTUAL_WIDTH, 'center')
		love.graphics.printf("Press Enter to Play", 0, 32, VIRTUAL_WIDTH, 'center')
	elseif gameState =='serve' then
		love.graphics.printf("Player " .. tostring(servingPlayer) .. "'s turn!", 0, 20, VIRTUAL_WIDTH, 'center')
		love.graphics.printf("Press Enter to Serve", 0, 32, VIRTUAL_WIDTH, 'center')
	elseif gameState == 'play' then
		love.graphics.printf("You're going to lose Vera", 0, 20, VIRTUAL_WIDTH, 'center')
	elseif gameState == 'victory' then
		love.graphics.setFont(victoryFont)
		love.graphics.clear(190/255, 120/255, 70/255, 255/255)
		love.graphics.printf('Player ' .. tostring (winningPlayer) .. " is the winner!", 0, 10, VIRTUAL_WIDTH, 'center')
		love.graphics.printf("Press Enter to Replay", 0, 42, VIRTUAL_WIDTH, 'center')
		love.graphics.setFont(smallFont)
	end
	love.graphics.setFont(scoreFont)
	
	--print scores
	displayScore()
	

	-- draw rectangle on left of size 20 x 5 and fill
	
	paddle1:render()
	paddle2:render()
	
	ball:render()
	
	displayFPS()
	
	
	
	
	--end rendering at virtual resolution
	push:apply('end')
end

function displayFPS()
	love.graphics.setColor(0, 1, 0, 1)
	love.graphics.setFont(smallFont)
	love.graphics.print('FPS: ' .. tostring(love.timer.getFPS()), 40, 20)
	love.graphics.setColor(1, 1, 1, 1)
end

function displayScore()
	love.graphics.setFont(scoreFont)
	love.graphics.print(tostring(player1Score), VIRTUAL_WIDTH / 2 - 50, VIRTUAL_HEIGHT /3)
	love.graphics.print(tostring(player2Score), VIRTUAL_WIDTH - 180, VIRTUAL_HEIGHT /3)
end
