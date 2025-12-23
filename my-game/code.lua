-- catch the fruit
-- a simple 1-hour game

function _init()
    -- NEW: Enable mouse/trackpad support
    poke(0x5f2d, 1)

    -- Which screen are we on?
    state = 0
    -- 0: playing, 1: game over

    -- game state variables
    player_x = 60
    -- player horizontal position
    player_y = 110
    -- player vertical position (fixed)
    score = 0
    lives = 3

    old_x = player_x
    dx = 0 -- this will store our "speed"
  
    player_sprite = 1
    hat_sprite = 3

    -- fruit variables
    fruit_x = flr(rnd(120))
    -- random start x
    fruit_y = 0
    -- start at top
    fruit_spd = 2
    -- how fast it falls

    fruit_sprite = 4


    snow_height = 0
    snow = {}
    for i=1, 50 do
        -- give each snowflake a random x, y, and speed
        add(snow, {
            x = rnd(128), 
            y = rnd(128), 
            spd = 0.2 + rnd(0.5) -- different speeds for depth
        })
    end    

end

function _update()
    if state == 0 then
        update_game_state()
    elseif state == 1 then
        update_gameover_screen()
    end
end

function update_game_state()
    -- 1. move player via trackpad
    -- stat(32) gets the horizontal mouse position
    player_x = stat(32)

    -- clamp the value so the sprite doesn't go too far off screen
    -- (assuming sprite is 8 pixels wide, stop at 120)
    if (player_x < 0) player_x = 0
    if (player_x > 120) player_x = 120

    -- Calculate velocity (Current - Previous)
    local current_speed = player_x - old_x

    -- Smooth the velocity (Linear Interpolation)
    -- This makes the hat "settle" back to normal instead of snapping
    dx = dx + (current_speed - dx) * 0.5

    -- Save current x for the next frame
    old_x = player_x

    -- 2. move fruit
    fruit_y += fruit_spd

    -- 3. check collision (catching the fruit)
    -- simple distance check: if fruit is close to player
    if (abs(player_x - fruit_x) < 8 and abs(player_y - fruit_y) < 8) then
        score += 1
        sfx(0) -- play sound 0 (make sure to draw a sound in sfx editor!)
        reset_fruit()
    end

    -- 4. check miss (fruit hit floor)
    if (fruit_y > 128) then
        lives -= 1
        sfx(1) -- play sound 1 for miss
        reset_fruit()
    end

    -- 5. game over check
    if (lives < 0) then
        shake()
        state = 1
    end

    -- grow by a tiny decimal so it takes time
    snow_height += 0.005 

    -- cap it so it doesn't cover the whole screen!
    if (snow_height > 10) snow_height = 10    

    for s in all(snow) do
        s.y += s.spd
        -- if it hits the bottom, move to top and randomize x
        if (s.y > 128) then
            s.y = 0
            s.x = rnd(128)
        end
    end    
end

function update_gameover_screen()
    -- If Game Over, check for a button press to restart
    if btn(4) or btn(5) or stat(34) > 0 then
        run() -- The easiest way to restart is just to re-run the cart!
    end
end

function _draw()
    camera(0,0) -- reset camera at start of every frame    
    cls()
    -- clear screen

    if state == 0 then 
        draw_game_state()
    elseif state == 1 then
        draw_gameover_screen()
    end
end

function draw_game_state()
    cls(0) -- clear to black

    -- Draw snow background
    for s in all(snow) do
        -- Use color 6 (light gray) or 12 (light blue) 
        -- so it's subtler than the white (7) fruit ribbon
        pset(s.x, s.y, 6)
    end

    -- draw score and lives
    print("score: " .. score, 2, 2, 7)
    print("lives: " .. lives, 90, 2, 8)

    -- draw player (sprite 1)
    spr(player_sprite, player_x, player_y)

    -- Calculate Stretch amount
    -- abs(dx) makes sure the stretch is positive regardless of direction
    local stretch = abs(dx) * 1.5
    if (stretch > 6) stretch = 6 -- don't let it stretch more than 6 pixels

    -- The "Lag" calculation: 
    -- We move the hat in the OPPOSITE direction of dx
    local lean_offset = dx * -0.8

    -- Determine if we should flip horizontally
    local do_flip = false
    if (dx > 0) do_flip = true -- flip if moving right    

    -- Draw the hat slightly above the player
    -- Sprite 3 (Hat) starts at x=24 on the sprite sheet
    -- we subtract 4 from player_y so it sits on their "head"
    sspr(
        hat_sprite * 8, 0,    -- source x, y (top-left of sprite 3)
        8, 8,     -- source width, height
        player_x + lean_offset,     -- apply the lag here!
        player_y - 4 + (stretch/4), -- squash it down slightly
        8 + stretch, -- target width (wider!)
        8 - (stretch/2), -- target height (shorter!)
        do_flip,                    -- [NEW] flip_x
        false                       -- [NEW] flip_y (we don't want it upside down!)
    )

    -- draw fruit (sprite 2)
    -- 1. Swap Color 8 (Red) for this gift's specific color
    pal(8, fruit_col)
  
    -- 2. Swap Color 7 (White) for Color 10 (Yellow) to make a gold ribbon
    pal(7, 10)    
    spr(fruit_sprite, fruit_x, fruit_y)
    -- 4. RESET the palette so nothing else is affected!
    pal()    

    -- draw after the snow dots, but before the player
    -- rectfill(x1, y1, x2, y2, color)
    rectfill(0, 128 - snow_height, 127, 128, 7)    
end

function draw_gameover_screen()
    -- Draw Game Over Screen
    print("g a m e   o v e r", 40, 50, 7)
    print("final score: "..score, 42, 60, 12)
    print("click to try again", 35, 80, 6)
end

-- helper function to respawn fruit
function reset_fruit()
    fruit_x = flr(rnd(120))
    fruit_y = -10
    -- start slightly off screen
    fruit_spd += 0.1
    -- make it harder over time!

    -- Pick a random color for the box: 
    -- 12 (Blue), 14 (Pink), 11 (Green), or 8 (Red)
    local colors = {12, 14, 11, 8}
    fruit_col = colors[flr(rnd(#colors)) + 1]    
end

function shake()
  local sx = 4 - rnd(8)
  local sy = 4 - rnd(8)
  camera(sx, sy) -- This pokes the camera memory for you!
end