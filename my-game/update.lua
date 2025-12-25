-- Update functions for game logic and state management

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

function apply_bonus(type)
    -- Play a "special" sound effect for bonuses
    sfx(3)

    if type == "magnet" then
        -- Activate the magnet logic we wrote earlier
        magnet_active = true
        magnet_timer = 300 -- lasts about 10 seconds
    end
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

function _update()
    if game_mode == main_play_mode then
        update_camera_shake()
        update_game_state()
    elseif game_mode == game_over_mode then
        update_gameover_screen()
    end
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
