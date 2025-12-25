-- catch the gifts

function load_hiscore()
    -- load the high score from memory (slot 0)
    -- if it's the first time playing, it will be 0
    hi_score = dget(0)
end

function enable_trackpad()
    -- Enable mouse/trackpad support
    poke(0x5f2d, 1)
end

function select_new_gift_color()
    return gift_colors[flr(rnd(#gift_colors)) + 1]
end

function init_hud()
    -- game state variables
    score = 0
    lives = 3
end

function init_player()
    -- game state variables
    player_x = 60
    -- player horizontal position
    player_y = 110

    -- previous frame position
    old_x = player_x
end

function init_magnet()
    magnet_active = false
    magnet_timer = 0
    magnet_range = 40
    -- how far the "pull" reaches
end

function update_magnet()
    -- If magnet is active, count down
    if magnet_timer > 0 then
        magnet_timer -= 1
        magnet_active = true
    else
        magnet_active = false
    end

    -- Inside your fruit/gift loop:
    if magnet_active then
        -- calculate distance on the X axis
        local dx_dist = player_x - gift_x

        -- if within range, move the gift toward the player
        if abs(dx_dist) < magnet_range then
            -- 0.1 is the 'pull strength'
            gift_x += dx_dist * 0.1
        end
    end
end

function init_bonuses()
    bonuses = {
        { spr = 14, col = 14, name = "magnet", val = 2 } -- pink: Magnet
    }

    init_magnet()

    -- We'll store the active bonus here
    current_bonus = nil
end

function spawn_gift()
    gift_x = flr(rnd(120))
    gift_y = -10

    -- pick a random bonus from our list
    current_bonus = bonuses[flr(rnd(#bonuses)) + 1]
end

function _init()
    -- use a unique name for your game
    cartdata("santa_catcher_2025")

    load_hiscore()
    enable_trackpad()

    init_bonuses()

    camera_shake_amount = 0

    -- 12 (Blue), 14 (Pink), 11 (Green), or 8 (Red)
    gift_colors = { 12, 14, 11, 8 }
    -- Pick a random color for the box:
    gift_colour = select_new_gift_color()

    -- Which screen are we on?
    main_play_mode = 0
    game_over_mode = 1
    game_mode = main_play_mode
    -- 0: playing, 1: game over

    init_player()

    init_hud()

    -- this will store our "speed"
    dx = 0

    player_sprite = 1
    hat_sprite = 3

    -- gift variables
    gift_x = flr(rnd(120))
    -- start at top
    gift_y = 0
    -- how fast it falls
    gift_spd = 2

    gift_sprite = 4

    initialise_snow()
end

function initialise_snow()
    snow_height = 0
    snow = {}
    for i = 1, 50 do
        -- give each snowflake a random x, y, and speed
        add(
            snow, {
                x = rnd(128),
                y = rnd(128),
                spd = 0.2 + rnd(0.5) -- different speeds for depth
            }
        )
    end
end

function _update()
    if game_mode == main_play_mode then
        update_camera_shake()
        update_game_state()
    elseif game_mode == game_over_mode then
        update_gameover_screen()
    end
end

function update_camera_shake()
    -- decrease the shake amount every frame
    if camera_shake_amount > 0 then
        camera_shake_amount *= 0.8 -- shrink by 20% each frame
        if (camera_shake_amount < 0.1) camera_shake_amount = 0
    end
end

function gift_missed()
    lives -= 1
    camera_shake_amount = 4
    -- start the shake!
end

function update_player()
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
end

function update_gift()
    -- 2. move gift
    gift_y += gift_spd

    -- 3. check collision (catching the gift)
    -- simple distance check: if gift is close to player
    if (abs(player_x - gift_x) < 8 and abs(player_y - gift_y) < 8) then
        score += 1
        sfx(0) -- play sound 0 (make sure to draw a sound in sfx editor!)
        reset_gift()
    end

    -- 4. check miss (gift hit floor)
    if (gift_y > 128) then
        gift_missed()
        sfx(1) -- play sound 1 for miss
        reset_gift()
    end
end

function check_game_over()
    -- 5. game over check
    if (lives < 0) then
        game_mode = game_over_mode
    end
end

function spawn_bonus()
    -- spawn a bonus gift instead of a regular one
    gift_x = flr(rnd(120))
    gift_y = -10

    -- pick a random bonus from our list
    current_bonus = bonuses[flr(rnd(#bonuses)) + 1]
end

function spawn_bonus()
    -- 1. Choose a random type from our table
    local type_index = flr(rnd(#bonuses)) + 1
    local picked = bonuses[type_index]

    -- 2. Create the bonus object
    current_bonus = {
        x = 10 + rnd(108),
        y = -10,
        sp = picked.spr,
        type = picked.name,
        t = 0 -- We'll use this for the sin() waving movement
    }
end

function update_bonus()
    if current_bonus != nil then
        current_bonus.y += 0.8 -- Fall slower than regular gifts
        current_bonus.t += 0.05 -- Increase time for the sine wave

        -- The "Waver": add a sine offset to the X position
        local wave = sin(current_bonus.t) * 2

        -- Collision check
        if abs((current_bonus.x + wave) - player_x) < 8 and abs(current_bonus.y - player_y) < 8 then
            apply_bonus(current_bonus.type)
            current_bonus = nil -- Remove after catching
        elseif current_bonus.y > 128 then
            current_bonus = nil -- Remove if missed
        end
    end
end

function update_game_state()
    update_magnet()

    update_player()

    update_gift()

    -- Occurs rarely (e.g., 1% chance every 10 seconds)
    if rnd(500) < 1 then
        spawn_bonus()
    end

    update_bonus()

    update_camera_shake()
    update_snow_state()

    check_game_over()
end

function update_snow_state()
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
    -- inside your 'game over' logic
    if score > hi_score then
        hi_score = score
        dset(0, hi_score) -- this saves it to the permanent memory!
    end

    -- If Game Over, check for a button press to restart
    if btn(4) or btn(5) or stat(34) > 0 then
        run() -- The easiest way to restart is just to re-run the cart!
    end
end

function _draw()
    camera(0, 0)
    -- reset camera at start of every frame
    cls()
    -- clear screen

    if game_mode == main_play_mode then
        draw_camera_shake()
        draw_game_state()
        reset_camera()
    elseif game_mode == game_over_mode then
        draw_gameover_screen()
    end
end

function draw_camera_shake()
    -- calculate random offset based on current shake
    local sx = rnd(camera_shake_amount) - (camera_shake_amount / 2)
    local sy = rnd(camera_shake_amount) - (camera_shake_amount / 2)
    camera(sx, sy)
    -- move the whole screen
end

function reset_camera()
    -- IMPORTANT: reset camera at the end of draw
    -- so UI elements (like score) don't jump around
    camera(0, 0)
end

function draw_snow()
    -- Draw snow background
    for s in all(snow) do
        -- Use color 6 (light gray) or 12 (light blue)
        -- so it's subtler than the white (7) gift ribbon
        pset(s.x, s.y, 6)
    end
end

function draw_hud()
    -- draw score and lives
    print("score: " .. score, 2, 2, 7)
    print("hi-score:  " .. hi_score, 2, 10, 6)
    -- using light gray for the record
    print("lives: " .. lives, 90, 2, 8)
end

function draw_gift()
    -- draw gift (sprite 2)
    -- 1. Swap Color 8 (Red) for this gift's specific color
    pal(8, gift_colour)

    -- 2. Swap Color 7 (White) for Color 10 (Yellow) to make a gold ribbon
    pal(7, 10)
    spr(gift_sprite, gift_x, gift_y)
    -- 4. RESET the palette so nothing else is affected!
    pal()
end

function draw_player()
    -- draw player (sprite 1)
    spr(player_sprite, player_x, player_y)

    -- Calculate Stretch amount
    -- abs(dx) makes sure the stretch is positive regardless of direction
    local stretch = abs(dx) * 1.5
    if (stretch > 6) stretch = 6
    -- don't let it stretch more than 6 pixels
    -- The "Lag" calculation:
    -- We move the hat in the OPPOSITE direction of dx
    local lean_offset = dx * -0.8

    -- Determine if we should flip horizontally
    local do_flip = false
    if (dx > 0) do_flip = true
    -- flip if moving right
    -- Draw the hat slightly above the player
    -- Sprite 3 (Hat) starts at x=24 on the sprite sheet
    -- we subtract 4 from player_y so it sits on their "head"
    sspr(
        hat_sprite * 8, 0, -- source x, y (top-left of sprite 3)
        8, 8, -- source width, height
        player_x + lean_offset, -- apply the lag here!
        player_y - 4 + (stretch / 4), -- squash it down slightly
        8 + stretch, -- target width (wider!)
        8 - (stretch / 2), -- target height (shorter!)
        do_flip, -- [NEW] flip_x
        false -- [NEW] flip_y (we don't want it upside down!)
    )

    if magnet_active then
        -- draw a pulsing circle
        -- circ(x, y, radius, color)
        local pulse = 2 + sin(time()) * 2
        circ(player_x + 4, player_y + 4, magnet_range + pulse, 12)
    end
end

function draw_bonus()
    if current_bonus != nil then
        local wave = sin(current_bonus.t) * 2

        -- Draw a pulsing yellow circle (Color 10) behind it
        local pulse = 1 + sin(time() * 2)
        circfill(current_bonus.x + wave + 4, current_bonus.y + 4, 5 + pulse, 10)

        -- Draw the symbol on top
        spr(current_bonus.sp, current_bonus.x + wave, current_bonus.y)
    end
end

function apply_bonus(type)
    -- Play a "special" sound effect for bonuses
    sfx(3)

    if type == "magnet" then
        -- Activate the magnet logic we wrote earlier
        magnet_active = true
        magnet_timer = 300 -- lasts about 10 seconds
    end
end

function draw_game_state()
    cls(0)
    -- clear to black

    draw_snow()
    draw_hud()
    draw_player()
    draw_gift()
    draw_bonus()
    draw_fallen_snow()
end

function draw_fallen_snow()
    -- draw after the snow dots, but before the player
    -- rectfill(x1, y1, x2, y2, color)
    rectfill(0, 128 - snow_height, 127, 128, 7)
end

function draw_gameover_screen()
    -- Draw Game Over Screen
    print("g a m e   o v e r", 40, 50, 7)
    print("final score: " .. score, 42, 60, 12)
    print("click to try again", 35, 80, 6)
end

-- helper function to respawn gift
function reset_gift()
    gift_x = flr(rnd(120))

    -- start slightly off screen
    gift_y = -10

    -- make it harder over time!
    gift_spd += 0.1

    -- Pick a random color for the box:
    gift_colour = select_new_gift_color()
end

function shake()
    local sx = 4 - rnd(8)
    local sy = 4 - rnd(8)
    camera(sx, sy)
    -- This pokes the camera memory for you!
end