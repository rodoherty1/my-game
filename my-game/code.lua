
-- #### ##    ## #### ######## 
--  ##  ###   ##  ##     ##    
--  ##  ####  ##  ##     ##    
--  ##  ## ## ##  ##     ##    
--  ##  ##  ####  ##     ##    
--  ##  ##   ###  ##     ##    
-- #### ##    ## ####    ##  


-- Initialization functions for game setup


-- Add to the top of your code
ID_PLAYER1, ID_PLAYER2, ID_PLAYER3 = 1, 2, 3

function init_profiles()
    profiles = {
        { name = "Rob", hi = 0 },
        { name = "Holly", hi = 0 }
    }
    -- This index tracks who is currently playing
    current_profile_idx = 1
end

function load_all_scores()
    for i=1,#profiles do
        -- Profile 1 uses slot 0, Profile 2 uses slot 1, etc.
        profiles[i].hi = dget(i-1)
    end
end

function save_current_score()
    local p = profiles[current_profile_idx]
    if score > p.hi then
        p.hi = score
        dset(current_profile_idx - 1, p.hi)
    end
end

function enable_trackpad()
    -- Enable mouse/trackpad support
    poke(0x5f2d, 1)
end

function select_new_gift_color()
    return gift_colors[flr(rnd(#gift_colors)) + 1]
end

function init_player()

    player_sprite = 1
    hat_sprite = 3

    -- game state variables
    player_x = 60
    -- player horizontal position
    player_y = 110

    -- previous frame position
    old_x = player_x
end



function init_bonuses()
    -- Bonus type definitions (static metadata)
    bonuses = {
        { spr = 14, type = BONUS_TYPE.MAGNET, range = 40, duration = 300 },
        { spr = 15, type = BONUS_TYPE.FREEZE, duration = 300 }
    }

    -- Runtime state for active effects
    active_effects = {
        magnet = { active = false, timer = 0 },
        freeze = { active = false, timer = 0 }
    }

    bonus_actions = {
        [BONUS_TYPE.MAGNET] = activate_magnet_bonus,
        [BONUS_TYPE.FREEZE] = activate_freeze_bonus
    }

    -- We'll store the active bonus falling object here
    current_bonus = nil
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

function initialise_gift_variables()
    -- 12 (Blue), 14 (Pink), 11 (Green), or 8 (Red)
    gift_colors = { COLOURS.BLUE, COLOURS.PINK, COLOURS.LIGHT_GREEN, COLOURS.RED }
    -- Pick a random color for the box:
    gift_colour = select_new_gift_color()

    -- gift variables
    gift_x = flr(rnd(120))
    -- start at top
    gift_y = 0
    -- how fast it falls
    gift_spd = 2

    gift_sprite = 4
end

function init_constants()
    -- constants
    BONUS_TYPE = { MAGNET=1, FREEZE=2 }    

    COLOURS = { LIGHT_GREY=6, WHITE=7, RED=8, GOLD=10, LIGHT_GREEN=11, BLUE=12 }

    GAME_MODES = { PLAY=0, GAMEOVER=1, TITLE_SCREEN=2 }
end

function enable_title_screen()
    current_game_mode = GAME_MODES.TITLE_SCREEN
end

function _init()
    -- use a unique name for your game
    cartdata("santa_catcher_2025")
    init_constants()
    init_profiles()
    enable_title_screen()

    load_all_scores()
    enable_trackpad()
    initialise_gift_variables()

    init_bonuses()

    camera_shake_amount = 0

    init_player()


end




-- ########  ########     ###    ##      ## 
-- ##     ## ##     ##   ## ##   ##  ##  ## 
-- ##     ## ##     ##  ##   ##  ##  ##  ## 
-- ##     ## ########  ##     ## ##  ##  ## 
-- ##     ## ##   ##   ######### ##  ##  ## 
-- ##     ## ##    ##  ##     ## ##  ##  ## 
-- ########  ##     ## ##     ##  ###  ###  

-- Draw functions for rendering game state to the screen
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
    print("score: " .. score, 2, 2, COLOURS.WHITE)
    print("hi-score:  " .. hi_score, 2, 10, COLOURS.LIGHT_GREY)
    -- using light gray for the record
    print("lives: " .. lives, 90, 2, COLOURS.RED)
end

function draw_gift()
    -- draw gift (sprite 2)
    -- 1. Swap Color 8 (Red) for this gift's specific color
    pal(COLOURS.RED, gift_colour)

    -- 2. Swap Color 7 (White) for Color 10 (Yellow) to make a gold ribbon
    pal(COLOURS.WHITE, COLOURS.GOLD)
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

    if active_effects.magnet.active then
        -- draw a pulsing circle
        -- circ(x, y, radius, color)
        local pulse = 2 + sin(time()) * 2
        local magnet_range = bonuses[BONUS_TYPE.MAGNET].range
        circ(player_x + 4, player_y + 4, magnet_range + pulse, COLOURS.BLUE)
    end
end

function draw_bonus()
    if current_bonus != nil then
        local wave = sin(current_bonus.t) * 2

        -- Draw a pulsing yellow circle (Color 10) behind it
        -- local pulse = 1 + sin(time() * 2)
        -- circfill(current_bonus.x + wave + 4, current_bonus.y + 4, 5 + pulse, 10)

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
    local freezing = active_effects.freeze.active
    
    if freezing then
        -- Swap dark colors for blues/purples
        pal(0, 1)  -- Black becomes Dark Blue
        pal(6, 12) -- Gray snow becomes Light Blue
    end    

    cls(0)
    -- clear to black

    draw_snow()
    draw_hud()
    draw_player()
    draw_gift()
    draw_bonus()
    draw_fallen_snow()
end


function draw_title_screen()
    cls(0)
    print("select your player:", 30, 40, COLOURS.LIGHT_GREY)
    
    for i=1,#profiles do
        local color = COLOURS.LIGHT_GREY -- Default gray
        local name_text = profiles[i].name
        
        if i == current_profile_idx then
            color = 10 -- Selected yellow
            name_text = "> " .. name_text .. " <"
        end
        
        -- Center the text (roughly)
        print(name_text, 45, 55 + (i * 10), color)
        print("record: " .. profiles[i].hi, 85, 55 + (i * 10), 5)
    end

    debug_input()

    local space_pressed = stat(30) and stat(31) == " "
    local trackpad_clicked = stat(34) > 0

    if (space_pressed or trackpad_clicked) then
        start_game()
    end

end


function draw_gameover_screen()
    -- Draw Game Over Screen
    print("g a m e   o v e r", 40, 50, COLOURS.WHITE)
    print("final score: " .. score, 42, 60, COLOURS.BLUE)
    print("click to try again", 35, 80, COLOURS.LIGHT_GREY)
end

function _draw()
    camera(0, 0)
    -- reset camera at start of every frame
    cls()
    -- clear screen

    if current_game_mode == GAME_MODES.PLAY then
        draw_camera_shake()
        draw_game_state()
        reset_camera()
    elseif current_game_mode == GAME_MODES.TITLE_SCREEN then
        draw_title_screen()
    elseif current_game_mode == GAME_MODES.GAMEOVER then
        draw_gameover_screen()
    end
end



-- ##     ## ########  ########     ###    ######## ######## 
-- ##     ## ##     ## ##     ##   ## ##      ##    ##       
-- ##     ## ##     ## ##     ##  ##   ##     ##    ##       
-- ##     ## ########  ##     ## ##     ##    ##    ######   
-- ##     ## ##        ##     ## #########    ##    ##       
-- ##     ## ##        ##     ## ##     ##    ##    ##       
 -- #######  ##        ########  ##     ##    ##    ######## 

-- Update functions for game logic and state management

function update_camera_shake()
    -- decrease the shake amount every frame
    if camera_shake_amount > 0 then
        camera_shake_amount *= 0.8 -- shrink by 20% each frame
        if (camera_shake_amount < 0.1) camera_shake_amount = 0
    end
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


-- ##     ## ########  ########     ###    ######## ########     ######   #### ######## ######## 
-- ##     ## ##     ## ##     ##   ## ##      ##    ##          ##    ##   ##  ##          ##    
-- ##     ## ##     ## ##     ##  ##   ##     ##    ##          ##         ##  ##          ##    
-- ##     ## ########  ##     ## ##     ##    ##    ######      ##   ####  ##  ######      ##    
-- ##     ## ##        ##     ## #########    ##    ##          ##    ##   ##  ##          ##    
-- ##     ## ##        ##     ## ##     ##    ##    ##          ##    ##   ##  ##          ##    
 -- #######  ##        ########  ##     ##    ##    ########     ######   #### ##          ##   

function gift_missed()
    lives -= 1
    camera_shake_amount = 4
    -- start the shake!
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


function update_gift()

    -- Calculate current time scale
    local time_scale = 1.0
    if (active_effects.freeze.active) time_scale = 0.4 -- 60% slower!

    -- Use the scale here
    gift_y += (gift_spd * time_scale)
    
    -- Check collision (catching the gift)
    -- simple distance check: if gift is close to player
    if (abs(player_x - gift_x) < 8 and abs(player_y - gift_y) < 8) then
        score += 1
        sfx(0) -- play sound 0 (make sure to draw a sound in sfx editor!)
        reset_gift()
    end

    -- Check miss (gift hit floor)
    if (gift_y > 128) then
        gift_missed()
        sfx(1) -- play sound 1 for miss
        reset_gift()
    end
end

function check_game_over()
    -- 5. game over check
    if (lives < 0) then
        current_game_mode = GAME_MODES.GAMEOVER
    end
end



-- ##     ## ########  ########     ###    ######## ########    ########   #######  ##    ## ##     ##  ######  
-- ##     ## ##     ## ##     ##   ## ##      ##    ##          ##     ## ##     ## ###   ## ##     ## ##    ## 
-- ##     ## ##     ## ##     ##  ##   ##     ##    ##          ##     ## ##     ## ####  ## ##     ## ##       
-- ##     ## ########  ##     ## ##     ##    ##    ######      ########  ##     ## ## ## ## ##     ##  ######  
-- ##     ## ##        ##     ## #########    ##    ##          ##     ## ##     ## ##  #### ##     ##       ## 
-- ##     ## ##        ##     ## ##     ##    ##    ##          ##     ## ##     ## ##   ### ##     ## ##    ## 
 -- #######  ##        ########  ##     ##    ##    ########    ########   #######  ##    ##  #######   ######  

function update_magnet_effect()
    local magnet = active_effects.magnet
    if not magnet.active then return end -- exit early if not active

    -- count down timer
    if magnet.timer > 0 then
        magnet.timer -= 1
    else
        magnet.active = false
        return
    end

    -- center-to-center calculation
    local p_center = player_x + 4
    local g_center = gift_x + 4
    local dx_dist = p_center - g_center
    
    -- pull from the metadata to ensure consistency
    local magnet_range = bonuses[BONUS_TYPE.MAGNET].range 

    if abs(dx_dist) < magnet_range then
        -- move the gift toward the center
        gift_x += dx_dist * 0.1
    end
end

function update_freeze_effect()
    local f = active_effects.freeze
    if f.timer > 0 then
        f.timer -= 1
        f.active = true
    else
        f.active = false
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
        type = picked.type,
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

            sfx(3)
            bonus_actions[current_bonus.type]()
            current_bonus = nil -- Remove after catching
        elseif current_bonus.y > 128 then
            current_bonus = nil -- Remove if missed
        end
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

-- ##     ## ########  ########     ###    ######## ########     ######      ###    ##     ## ########  ######  ########    ###    ######## ######## 
-- ##     ## ##     ## ##     ##   ## ##      ##    ##          ##    ##    ## ##   ###   ### ##       ##    ##    ##      ## ##      ##    ##       
-- ##     ## ##     ## ##     ##  ##   ##     ##    ##          ##         ##   ##  #### #### ##       ##          ##     ##   ##     ##    ##       
-- ##     ## ########  ##     ## ##     ##    ##    ######      ##   #### ##     ## ## ### ## ######    ######     ##    ##     ##    ##    ######   
-- ##     ## ##        ##     ## #########    ##    ##          ##    ##  ######### ##     ## ##             ##    ##    #########    ##    ##       
-- ##     ## ##        ##     ## ##     ##    ##    ##          ##    ##  ##     ## ##     ## ##       ##    ##    ##    ##     ##    ##    ##       
 -- #######  ##        ########  ##     ##    ##    ########     ######   ##     ## ##     ## ########  ######     ##    ##     ##    ##    ######## 

function activate_magnet_bonus()
    -- Activate the magnet effect
    active_effects.magnet.active = true
    active_effects.magnet.timer = bonuses[BONUS_TYPE.MAGNET].duration
end

function activate_freeze_bonus()
    -- Activate the magnet effect
    active_effects.freeze.active = true
    active_effects.freeze.timer = bonuses[BONUS_TYPE.FREEZE].duration
end

function update_active_effects()
    -- Update all currently active effects
    update_magnet_effect()
    update_freeze_effect()
end

function update_game_state()
    update_active_effects()

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

-- Add this to the end of _draw()
function debug_input()
    -- Draw a black box so we can read the text
    rectfill(0, 0, 127, 20, 0)
    
    local debug_str = ""
    -- Check buttons 0 to 5 (Left, Right, Up, Down, Z/Space, X)
    for i=0,5 do
        if (btn(i)) debug_str ..= i.." "
    end
    
    print("held: "..debug_str, 2, 2, 12)
    
    local space_pressed = stat(30) and stat(31) == " "
    if (space_pressed) print("space pressed!", 2, 10, 7)

    local trackpad_clicked = stat(34) > 0
    if (trackpad_clicked) print("trackpad clicked!", 2, 18, 7)
end

function update_title_screen()
    -- Navigate the list
    if (btnp(2)) current_profile_idx -= 1 -- Up
    if (btnp(3)) current_profile_idx += 1 -- Down
    
    -- Keep the selection within the list limits
    if (current_profile_idx < 1) current_profile_idx = #profiles
    if (current_profile_idx > #profiles) current_profile_idx = 1
    
end


function start_game()
    -- Reset HUD and Game State
    score = 0
    lives = 3

    -- this will store our "speed"
    dx = 0

    initialise_snow()

    current_game_mode = GAME_MODES.PLAY
    
    -- Reset the gift to the top
    gift_spd = 2 -- Reset speed to base level
    reset_gift()
    
    -- Ensure all power-ups are off at start
    active_effects.magnet.active = false
    active_effects.magnet.timer = 0
    active_effects.freeze.active = false
    active_effects.freeze.timer = 0
    
    -- Set the high score to the selected profile's record
    hi_score = profiles[current_profile_idx].hi
end


function update_gameover_screen()
    -- Save the score for the CURRENT profile before leaving
    save_current_score()

    -- Check for button press/click to return to menu
    if btn(4) or btn(5) or stat(34) > 0 then
        current_game_mode = GAME_MODES.TITLE_SCREEN
    end
end

function _update()
    print("update mode: " .. tostr(current_game_mode), 0, 0, 7)
    if current_game_mode == GAME_MODES.PLAY then
        update_camera_shake()
        update_game_state()
    elseif current_game_mode == GAME_MODES.GAME_OVER then
        update_gameover_screen()
    elseif current_game_mode == GAME_MODES.TITLE_SCREEN then
        update_title_screen()
    end
end


function shake()
    local sx = 4 - rnd(8)
    local sy = 4 - rnd(8)
    camera(sx, sy)
    -- This pokes the camera memory for you!
end
