-- Drawing functions for rendering game state

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

function draw_fallen_snow()
    -- draw after the snow dots, but before the player
    -- rectfill(x1, y1, x2, y2, color)
    rectfill(0, 128 - snow_height, 127, 128, 7)
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

function draw_gameover_screen()
    -- Draw Game Over Screen
    print("g a m e   o v e r", 40, 50, 7)
    print("final score: " .. score, 42, 60, 12)
    print("click to try again", 35, 80, 6)
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
