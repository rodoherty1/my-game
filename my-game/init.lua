-- Initialization functions for game setup

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
