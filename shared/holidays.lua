--[[
    The holiday catalog.

    One entry per holiday: when it is in season, what colors its lights
    come in, which props it offers, and which shows suit it. Decorating
    tips live in the locale file (tip_<holiday>_1, _2, ...) so they can be
    translated.

    PROPS
    Every model here was checked against the game's object list. The ones
    marked `build` only exist on servers running at least that game build
    (sv_enforceGameBuild). The client checks every model at start and
    hides from the menu anything the server's build does not have -- so a
    missing prop is a shorter menu, never an error.

    Add your own streamed props to any holiday's list:
        { model = 'my_wreath_01', label = 'Wreath', wall = true }

    Fields:
      model   the model name
      label   what the menu shows
      wall    true: hangs on a wall (the placer aims at a surface);
              otherwise it stands on the ground
      far     true: a large piece that should stream from further away
      collision  false to let players walk through it (default true)
      build   minimum game build; omit for base game
      zoff    vertical offset in meters when the model's origin is not
              at its base (a few casino and DLC props float otherwise)
      desc    one line for the panel: what it looks like, where it suits

    COLORS
    Named palettes a string of lights can use. Bulbs cycle through the
    list along the string.
]]

Holidays = {}

-- Order the menu shows them in.
Holidays.Order = {
    'christmas', 'hanukkah', 'kwanzaa', 'newyear', 'valentines', 'stpatricks',
    'easter', 'memorialday', 'july4', 'laborday', 'halloween', 'thanksgiving',
    'party', 'wedding', 'birthday', 'funeral',
}

Holidays.Catalog = {
    christmas = {
        from = { 11, 25 }, to = { 12, 26 },
        accent = { 200, 30, 40 },
        palettes = {
            classic    = { { 255, 30, 30 }, { 30, 220, 60 } },
            multicolor = { { 255, 30, 30 }, { 30, 220, 60 }, { 40, 90, 255 }, { 255, 210, 40 }, { 255, 255, 255 } },
            warm_white = { { 255, 214, 150 } },
            cool_white = { { 220, 235, 255 } },
            icicle     = { { 220, 235, 255 }, { 120, 180, 255 } },
            candy_cane = { { 255, 40, 40 }, { 255, 255, 255 } },
            gold       = { { 255, 190, 60 } },
        },
        shows = { 'classic', 'dance', 'build', 'gentle' },
        props = {
            { model = 'prop_xmas_tree_int',          label = 'Christmas tree (decorated, indoor)', desc = 'A decorated indoor tree, about head height, with ornaments and a star. Lobbies and living rooms.' },
            { model = 'prop_xmas_ext',               label = 'Christmas tree (large, outdoor)', far = true, desc = 'The big outdoor tree, plain green: wind a string of lights up it. Plazas and parking lots.' },
            { model = 'xm_prop_x17_xmas_tree_int',   label = 'Christmas tree (lit, lounge)', build = 1290, desc = 'A slim lounge tree with its own lights built in.' },
            { model = 'ch_prop_ch_diamond_xmastree', label = 'Christmas tree (casino, grand)', far = true, build = 1868, desc = 'The casino lobby tree: tall, gold and glittering. Grand entrances.' },
            { model = 'm25_2_prop_m52_xmas_tree',    label = 'Christmas tree (2025)', build = 3570, desc = 'A full decorated tree with ornaments and a topper, the newest in the game.' },
            { model = 'm25_2_prop_m52_snowman_01a',  label = 'Snowman', build = 3570, desc = 'A snowman with a scarf and hat, about chest height.' },
            { model = 'xm3_prop_xm3_snowman_01a',    label = 'Snowman (classic)', build = 2802, desc = 'A plain snowman: three snowballs, coal eyes, a carrot nose.' },
            { model = 'xm3_prop_xm3_snowman_01b',    label = 'Snowman (scarf)', build = 2802, desc = 'The snowman in a knitted scarf.' },
            { model = 'xm3_prop_xm3_snowman_01c',    label = 'Snowman (hat)', build = 2802, desc = 'The snowman in a hat.' },
            { model = 'm23_2_prop_m32_candycane_01a', label = 'Candy cane (giant)', build = 3095, desc = 'A giant striped candy cane, about a person tall. Two frame a doorway.' },
            { model = 'm23_2_prop_m32_sleigh_01a',   label = 'Sleigh', far = true, build = 3095, desc = 'Santa\'s sleigh, full size. Lawns and rooftops; put reindeer in front of it.' },
            { model = 'm23_2_prop_m32_giftbox_small_01a', label = 'Gift box (small)', build = 3095, desc = 'A small wrapped gift with a bow.' },
            { model = 'm23_2_prop_m32_giftbox_med_01a',   label = 'Gift box (medium)', build = 3095, desc = 'A wrapped gift, knee high.' },
            { model = 'm23_2_prop_m32_giftbox_lar_01a',   label = 'Gift box (large)', build = 3095, desc = 'A large wrapped gift, waist high.' },
            { model = 'm23_2_prop_m32_giftbox_long_01a',  label = 'Gift box (long)', build = 3095, desc = 'A long, flat wrapped box.' },
            { model = 'm23_2_prop_m32_giftbox_xlar_01a',  label = 'Gift box (huge)', build = 3095, desc = 'A huge wrapped gift, taller than a child.' },
            { model = 'm23_2_prop_m32_present_pallet_01a', label = 'Pallet of presents', build = 3095, desc = 'A pallet stacked with wrapped presents. Under the big tree.' },
            { model = 'm25_2_prop_m52_present_01a',  label = 'Wrapped present', build = 3570, desc = 'A single wrapped present with a ribbon.' },
            { model = 'm23_2_prop_m32_snowfort_01a', label = 'Snow fort', far = true, build = 3095, desc = 'A snow fort with walls and a flag. Yards and parks.' },
            { model = 'm23_2_prop_m32_snowwall_s_01a', label = 'Snow wall (short)', build = 3095, desc = 'A short wall of packed snow.' },
            { model = 'm23_2_prop_m32_snowwall_l_01a', label = 'Snow wall (long)', build = 3095, desc = 'A long wall of packed snow.' },
            { model = 'prop_prlg_snowpile',          label = 'Snow pile', desc = 'A pile of plowed snow. Curbs and corners.' },
            { model = 'prop_snow_xmas_cards_01',     label = 'Christmas cards (table)', desc = 'Christmas cards standing on a table.' },
            { model = 'prop_snow_xmas_cards_02',     label = 'Christmas cards (shelf)', desc = 'Christmas cards in a row on a shelf.' },
            { model = 'v_res_fa_candle01',           label = 'Candle (tall)', collision = false, desc = 'A tall pillar candle in a holder.' },
            { model = 'prop_mem_candle_combo',       label = 'Candle cluster', collision = false, desc = 'A cluster of small candles, lit. Steps and windowsills.' },
            { model = 'xm3_prop_xm3_present_01a',     label = 'Wrapped present (2022)', build = 2802, desc = 'A wrapped present from the 2022 set.' },
            { model = 'xs_prop_trophy_presents_01a',  label = 'Stack of presents (small)', collision = false, build = 1604, desc = 'A small stack of presents on a base.' },
        },
    },

    hanukkah = {
        -- Hanukkah moves with the Hebrew calendar. The shipped window
        -- covers every year's dates; set the exact eight nights each year
        -- in Config.Holidays.hanukkah if you want it tighter.
        from = { 11, 25 }, to = { 1, 2 },
        accent = { 40, 90, 220 },
        palettes = {
            blue_white = { { 40, 90, 255 }, { 255, 255, 255 } },
            blue       = { { 40, 90, 255 } },
            silver     = { { 220, 230, 255 } },
            gold_blue  = { { 255, 190, 60 }, { 40, 90, 255 } },
        },
        shows = { 'gentle', 'classic', 'build' },
        props = {
            { model = 'v_res_fa_candle01',       label = 'Candle (tall)', collision = false, desc = 'A tall pillar candle in a holder.' },
            { model = 'v_res_fa_candle02',       label = 'Candle (medium)', collision = false, desc = 'A medium pillar candle in a holder.' },
            { model = 'v_res_fa_candle03',       label = 'Candle (short)', collision = false, desc = 'A short pillar candle in a holder.' },
            { model = 'prop_mem_candle_combo',   label = 'Candle cluster', collision = false, desc = 'A cluster of small candles, lit. Steps and windowsills.' },
            { model = 'apa_mp_h_acc_candles_01', label = 'Candle set (tray)', collision = false, build = 944, desc = 'A tray of candles. Tables and sideboards.' },
            { model = 'm25_2_prop_m52_present_01a', label = 'Wrapped present', build = 3570, desc = 'A single wrapped present with a ribbon.' },
            { model = 'm23_2_prop_m32_giftbox_small_01a', label = 'Gift box (small)', build = 3095, desc = 'A small wrapped gift with a bow.' },
            { model = 'm23_2_prop_m32_giftbox_med_01a',   label = 'Gift box (medium)', build = 3095, desc = 'A wrapped gift, knee high.' },
        },
    },

    newyear = {
        from = { 12, 27 }, to = { 1, 7 },
        accent = { 255, 200, 60 },
        palettes = {
            gold_silver = { { 255, 190, 60 }, { 230, 235, 255 } },
            gold        = { { 255, 190, 60 } },
            silver      = { { 230, 235, 255 } },
            champagne   = { { 255, 225, 170 }, { 255, 190, 60 }, { 255, 255, 255 } },
        },
        shows = { 'build', 'dance', 'strobe', 'classic' },
        props = {
            { model = 'm25_2_prop_m52_balloons_01a', label = 'Balloon bunch', build = 3570, desc = 'A bunch of helium balloons on ribbons.' },
            { model = 'm25_2_prop_m52_balloons_02a', label = 'Balloon bunch (alt)', build = 3570, desc = 'A second bunch of balloons in other colors.' },
            { model = 'xs_prop_arena_confetti_cannon', label = 'Confetti cannon', build = 1604, desc = 'A confetti cannon on a stand. Entrances and stages.' },
            { model = 'ba_prop_battle_champ_01',     label = 'Champagne bottle', collision = false, build = 1493, desc = 'A champagne bottle.' },
            { model = 'ba_prop_club_champset',       label = 'Champagne service', collision = false, build = 1493, desc = 'Champagne in a bucket with glasses.' },
            { model = 'ind_prop_firework_01',        label = 'Firework (box)', desc = 'A box of fireworks, fused.' },
            { model = 'ind_prop_firework_02',        label = 'Firework (rocket)', desc = 'A firework rocket on a stick.' },
            { model = 'ind_prop_firework_03',        label = 'Firework (fountain)', desc = 'A fountain firework.' },
            { model = 'ind_prop_firework_04',        label = 'Firework (cake)', desc = 'A firework cake with many tubes.' },
            { model = 'prop_egg_clock_01',           label = 'Clock', collision = false, desc = 'A small egg-shaped clock. Tables.' },
            { model = 'xm3_prop_xm3_balloon_01a',     label = 'Balloon (single)', collision = false, build = 2802, desc = 'A single balloon on a string.' },
        },
    },

    valentines = {
        from = { 2, 1 }, to = { 2, 15 },
        accent = { 230, 60, 120 },
        palettes = {
            red_pink  = { { 255, 30, 60 }, { 255, 110, 170 } },
            pink      = { { 255, 110, 170 } },
            red_white = { { 255, 30, 60 }, { 255, 255, 255 } },
            rose      = { { 255, 60, 100 }, { 255, 180, 200 }, { 255, 255, 255 } },
        },
        shows = { 'gentle', 'classic' },
        props = {
            { model = 'apa_mp_h_acc_vase_flowers_01', label = 'Vase of flowers', collision = false, build = 944, desc = 'A vase of flowers.' },
            { model = 'apa_mp_h_acc_vase_flowers_02', label = 'Vase of flowers (tall)', collision = false, build = 944, desc = 'A tall vase of flowers.' },
            { model = 'apa_mp_h_acc_vase_flowers_03', label = 'Vase of flowers (bowl)', collision = false, build = 944, desc = 'A low bowl of flowers.' },
            { model = 'v_res_fa_candle01',            label = 'Candle (tall)', collision = false, desc = 'A tall pillar candle in a holder.' },
            { model = 'prop_mem_candle_combo',        label = 'Candle cluster', collision = false, desc = 'A cluster of small candles, lit. Steps and windowsills.' },
            { model = 'v_prop_floatcandle',           label = 'Floating candle', collision = false, desc = 'A floating candle in a glass.' },
            { model = 'ch_prop_champagne_01a',        label = 'Champagne', collision = false, build = 1868, desc = 'A bottle of champagne.' },
            { model = 'v_res_cakedome',               label = 'Cake under glass', collision = false, desc = 'A cake under a glass dome.' },
            { model = 'm25_2_prop_m52_balloons_01a',  label = 'Balloon bunch', build = 3570, desc = 'A bunch of helium balloons on ribbons.' },
            { model = 'prop_single_rose',             label = 'Single rose', collision = false, desc = 'A single long-stemmed rose.' },
            { model = 'v_res_rosevase',               label = 'Roses in a vase', collision = false, desc = 'Red roses in a vase.' },
            { model = 'prop_wine_rose',               label = 'Bottle of rose wine', collision = false, desc = 'A bottle of rose wine.' },
        },
    },

    stpatricks = {
        from = { 3, 10 }, to = { 3, 18 },
        accent = { 30, 160, 60 },
        palettes = {
            green      = { { 30, 220, 60 } },
            green_gold = { { 30, 220, 60 }, { 255, 190, 60 } },
            irish      = { { 30, 220, 60 }, { 255, 255, 255 }, { 255, 140, 40 } },
            rainbow    = { { 255, 40, 40 }, { 255, 140, 40 }, { 255, 220, 40 }, { 40, 220, 60 }, { 40, 90, 255 }, { 160, 60, 220 } },
        },
        shows = { 'dance', 'classic', 'build' },
        props = {
            { model = 'm25_2_prop_m52_clovergreen_01a', label = 'Shamrock (green)', build = 3570, desc = 'A big green shamrock on a stand.' },
            { model = 'm25_2_prop_m52_clovergold_01a',  label = 'Shamrock (gold)', build = 3570, desc = 'A big gold shamrock on a stand.' },
            { model = 'prop_plant_clover_01',           label = 'Clover patch', collision = false, desc = 'A patch of clover, ground cover.' },
            { model = 'prop_plant_clover_02',           label = 'Clover patch (wide)', collision = false, desc = 'A wide patch of clover.' },
            { model = 'm25_2_prop_m52_balloons_01a',    label = 'Balloon bunch', build = 3570, desc = 'A bunch of helium balloons on ribbons.' },
        },
    },

    easter = {
        -- Computed: Easter Sunday, two weeks either side. `easter = true`
        -- makes the season engine do that; from/to are ignored.
        easter = true, span = 14,
        accent = { 180, 120, 230 },
        palettes = {
            pastel = { { 255, 190, 220 }, { 190, 230, 255 }, { 255, 250, 180 }, { 200, 255, 200 }, { 230, 200, 255 } },
            spring = { { 255, 250, 180 }, { 200, 255, 200 } },
            lilac  = { { 230, 200, 255 }, { 255, 255, 255 } },
        },
        shows = { 'gentle', 'classic' },
        props = {
            { model = 'm24_2_prop_m42_oegg_01a',       label = 'Decorated egg', build = 3323, desc = 'A decorated ornamental egg, about knee high.' },
            { model = 'm24_2_prop_m42_oeggtrophy_01a', label = 'Decorated egg (trophy)', build = 3323, desc = 'A decorated egg on a trophy base.' },
            { model = 'ex_prop_crate_oegg',            label = 'Ornate egg (crated)', build = 944, desc = 'An ornate egg in an open crate.' },
            { model = 'apa_mp_h_acc_vase_flowers_01',  label = 'Vase of flowers', collision = false, build = 944, desc = 'A vase of flowers.' },
            { model = 'apa_mp_h_acc_vase_flowers_04',  label = 'Vase of flowers (spray)', collision = false, build = 944, desc = 'A spray of flowers in a vase.' },
            { model = 'prop_snow_flower_01',           label = 'Flower bed', desc = 'A bed of flowers.' },
            { model = 'prop_snow_flower_02',           label = 'Flower bed (wide)', desc = 'A wide bed of flowers.' },
            { model = 'm25_2_prop_m52_balloons_02a',   label = 'Balloon bunch', build = 3570, desc = 'A second bunch of balloons in other colors.' },
        },
    },

    july4 = {
        from = { 6, 25 }, to = { 7, 6 },
        accent = { 200, 40, 60 },
        palettes = {
            usa       = { { 255, 30, 30 }, { 255, 255, 255 }, { 40, 90, 255 } },
            red_white = { { 255, 30, 30 }, { 255, 255, 255 } },
            blue_white = { { 40, 90, 255 }, { 255, 255, 255 } },
            sparkler  = { { 255, 255, 255 }, { 255, 220, 120 } },
        },
        shows = { 'dance', 'build', 'classic', 'strobe' },
        props = {
            { model = 'prop_flag_us',            label = 'US flag (pole)', far = true, desc = 'A US flag on a full-height pole.' },
            { model = 'prop_flag_us_s',          label = 'US flag (small pole)', desc = 'A US flag on a short pole.' },
            { model = 'prop_flag_us_r',          label = 'US flag (rooftop)', far = true, desc = 'A US flag on a rooftop pole.' },
            { model = 'reh_prop_reh_deskflag_us_01a', label = 'US desk flag', collision = false, build = 3258, desc = 'A small US flag on a desk stand.' },
            { model = 'ind_prop_firework_01',    label = 'Firework (box)', desc = 'A box of fireworks, fused.' },
            { model = 'ind_prop_firework_02',    label = 'Firework (rocket)', desc = 'A firework rocket on a stick.' },
            { model = 'ind_prop_firework_03',    label = 'Firework (fountain)', desc = 'A fountain firework.' },
            { model = 'ind_prop_firework_04',    label = 'Firework (cake)', desc = 'A firework cake with many tubes.' },
            { model = 'm25_2_prop_m52_balloons_01a', label = 'Balloon bunch', build = 3570, desc = 'A bunch of helium balloons on ribbons.' },
            { model = 'prop_table_03',            label = 'Picnic table', desc = 'A wooden picnic table with benches.' },
        },
    },

    halloween = {
        from = { 10, 1 }, to = { 11, 1 },
        accent = { 255, 120, 20 },
        palettes = {
            orange        = { { 255, 120, 20 } },
            orange_purple = { { 255, 120, 20 }, { 160, 40, 220 } },
            purple_green  = { { 160, 40, 220 }, { 60, 255, 60 } },
            ghostly       = { { 180, 255, 200 }, { 220, 235, 255 } },
            blood         = { { 200, 10, 10 } },
        },
        shows = { 'classic', 'build', 'strobe', 'gentle' },
        props = {
            { model = 'm25_2_prop_m52_lantern_pk_01a', label = 'Jack-o-lantern', collision = false, build = 3570, desc = 'A carved jack-o-lantern, candle lit.' },
            { model = 'm25_2_prop_m52_lantern_pk_01b', label = 'Jack-o-lantern (grin)', collision = false, build = 3570, desc = 'A jack-o-lantern with a wide grin.' },
            { model = 'm25_2_prop_m52_lantern_pk_01c', label = 'Jack-o-lantern (scream)', collision = false, build = 3570, desc = 'A jack-o-lantern with a screaming face.' },
            { model = 'reh_prop_reh_lantern_pk_01a',   label = 'Jack-o-lantern (porch)', collision = false, build = 3258, desc = 'A porch jack-o-lantern.' },
            { model = 'm25_2_prop_m52_skeleton_01a',   label = 'Skeleton', build = 3570, desc = 'A standing skeleton.' },
            { model = 'reh_prop_reh_skeleton_01a',     label = 'Skeleton (seated)', build = 3258, desc = 'A skeleton sitting down. Benches and porches.' },
            { model = 'm23_1_prop_m31_ghostzombie_01a', label = 'Ghost (zombie)', collision = false, build = 3095, desc = 'A translucent zombie ghost.' },
            { model = 'm23_1_prop_m31_ghostjohnny_01a', label = 'Ghost (drifter)', collision = false, build = 3095, desc = 'A translucent drifter ghost.' },
            { model = 'm24_1_prop_m41_ghost_cop_01a',   label = 'Ghost (officer)', collision = false, build = 3258, desc = 'A translucent police officer ghost.' },
            { model = 'prop_coffin_01',               label = 'Coffin', desc = 'A wooden coffin, closed.' },
            { model = 'prop_coffin_02',               label = 'Coffin (plain)', desc = 'A plain coffin.' },
            { model = 'prop_coffin_02b',              label = 'Coffin (open)', desc = 'An open coffin.' },
            { model = 'm23_1_prop_m31_coffin_pile_01a', label = 'Coffin pile', far = true, build = 3095, desc = 'A pile of coffins.' },
            { model = 'prop_gravestones_01a',         label = 'Gravestone (cross)', desc = 'A gravestone with a cross.' },
            { model = 'prop_gravestones_02a',         label = 'Gravestone (rounded)', desc = 'A rounded gravestone.' },
            { model = 'prop_gravestones_03a',         label = 'Gravestone (tall)', desc = 'A tall gravestone.' },
            { model = 'prop_gravestones_05a',         label = 'Gravestone (leaning)', desc = 'A gravestone leaning off square.' },
            { model = 'prop_gravestones_09a',         label = 'Gravestone (slab)', desc = 'A flat grave slab.' },
            { model = 'prop_gravetomb_01a',           label = 'Tomb', desc = 'A stone tomb.' },
            { model = 'prop_gravetomb_02a',           label = 'Tomb (large)', far = true, desc = 'A large stone tomb.' },
            { model = 'v_ret_ta_skull',               label = 'Skull', collision = false, desc = 'A skull.' },
            { model = 'vw_prop_casino_art_skull_01a', label = 'Skull (crystal)', collision = false, build = 2060, desc = 'A crystal skull.' },
            { model = 'm24_1_prop_m41_candlelrg_01a', label = 'Candle (large, dripping)', collision = false, build = 3258, desc = 'A large dripping candle.' },
            { model = 'prop_mem_candle_combo',        label = 'Candle cluster', collision = false, desc = 'A cluster of small candles, lit. Steps and windowsills.' },
            { model = 'm24_1_prop_m41_candypile_01a', label = 'Candy pile', collision = false, build = 3258, desc = 'A pile of Halloween candy.' },
            { model = 'm24_2_prop_m42_lantern_01a',   label = 'Lantern (hanging)', wall = true, collision = false, build = 3323, desc = 'A hanging lantern, lit. Mounts on the wall you aim at.' },
            { model = 'm23_1_prop_m31_ghostrurmeth_01a', label = 'Ghost (cook)', collision = false, build = 3095, desc = 'A translucent ghost in a cook\'s apron.' },
            { model = 'm23_1_prop_m31_ghostsalton_01a', label = 'Ghost (Salton)', collision = false, build = 3095, desc = 'A translucent ghost from the Salton shore.' },
            { model = 'm23_1_prop_m31_ghostskidrow_01a', label = 'Ghost (downtown)', collision = false, build = 3095, desc = 'A translucent downtown ghost.' },
            { model = 'm24_1_prop_m41_ghost_dom_01a',   label = 'Ghost (pilot)', collision = false, build = 3258, desc = 'A translucent ghost in a flight suit.' },
            { model = 'm25_1_prop_m51_ghostjay_01a',    label = 'Ghost (suit)', collision = false, build = 3407, desc = 'A translucent ghost in a suit.' },
            { model = 'm23_1_prop_m31_coffin_01a',      label = 'Coffin (ornate)', build = 3095, desc = 'An ornate coffin.' },
            { model = 'm25_2_prop_m52_coffin_01a',      label = 'Coffin (2025)', build = 3570, desc = 'A dark coffin, newest in the game.' },
            { model = 'm23_1_prop_m31_orn_bat_01a',     label = 'Bat (hanging ornament)', wall = true, collision = false, build = 3095, desc = 'A bat ornament, hung from the surface you aim at.' },
            { model = 'm25_2_prop_m52_orn_bat_01a',     label = 'Bat (hanging ornament, 2025)', wall = true, collision = false, build = 3570, desc = 'A bat ornament from the 2025 set, hung from the surface you aim at.' },
            { model = 'reh_prop_reh_lantern_pk_01b',    label = 'Jack-o-lantern (porch, 2)', collision = false, build = 3258, desc = 'A porch jack-o-lantern, second face.' },
            { model = 'reh_prop_reh_lantern_pk_01c',    label = 'Jack-o-lantern (porch, 3)', collision = false, build = 3258, desc = 'A porch jack-o-lantern, third face.' },
            { model = 'prop_haybale_01',                label = 'Hay bale', desc = 'A single hay bale.' },
            { model = 'prop_haybale_stack_01',          label = 'Hay bale stack', desc = 'A stack of hay bales. Porches and lawns.' },
            { model = 'm23_1_prop_m31_haybales_01a',    label = 'Hay bales (stacked)', build = 3095, desc = 'A stack of hay bales.' },
        },
    },

    thanksgiving = {
        from = { 11, 2 }, to = { 11, 30 },
        accent = { 200, 110, 30 },
        palettes = {
            harvest = { { 255, 140, 30 }, { 255, 200, 60 }, { 180, 60, 20 } },
            amber   = { { 255, 170, 60 } },
            autumn  = { { 200, 60, 20 }, { 255, 140, 30 }, { 255, 220, 120 } },
        },
        shows = { 'gentle', 'classic' },
        props = {
            { model = 'prop_turkey_leg_01',           label = 'Turkey leg', collision = false, desc = 'A roast turkey leg.' },
            { model = 'v_res_cakedome',               label = 'Pie under glass', collision = false, desc = 'A cake under a glass dome.' },
            { model = 'apa_mp_h_acc_vase_flowers_02', label = 'Vase of flowers (tall)', collision = false, build = 944, desc = 'A tall vase of flowers.' },
            { model = 'v_res_fa_candle01',            label = 'Candle (tall)', collision = false, desc = 'A tall pillar candle in a holder.' },
            { model = 'prop_mem_candle_combo',        label = 'Candle cluster', collision = false, desc = 'A cluster of small candles, lit. Steps and windowsills.' },
            { model = 'm24_2_prop_m42_lantern_01a',   label = 'Lantern (hanging)', wall = true, collision = false, build = 3323, desc = 'A hanging lantern, lit. Mounts on the wall you aim at.' },
            { model = 'prop_table_03',            label = 'Picnic table', desc = 'A wooden picnic table with benches.' },
            { model = 'prop_snow_woodpile_04a',       label = 'Woodpile', desc = 'A stacked woodpile.' },
            { model = 'prop_haybale_01',                label = 'Hay bale', desc = 'A single hay bale.' },
            { model = 'prop_haybale_02',                label = 'Hay bale (2)', desc = 'A hay bale, second shape.' },
            { model = 'prop_haybale_03',                label = 'Hay bale (3)', desc = 'A hay bale, third shape.' },
            { model = 'prop_haybale_stack_01',          label = 'Hay bale stack', desc = 'A stack of hay bales. Porches and lawns.' },
            { model = 'm23_1_prop_m31_haybales_01a',    label = 'Hay bales (stacked)', build = 3095, desc = 'A stack of hay bales.' },
            { model = 'm23_1_prop_m31_haybales_01b',    label = 'Hay bales (stacked, 2)', build = 3095, desc = 'A stack of hay bales, second arrangement.' },
            { model = 'm23_1_prop_m31_haybales_01c',    label = 'Hay bales (stacked, 3)', build = 3095, desc = 'A stack of hay bales, third arrangement.' },
        },
    },

    kwanzaa = {
        from = { 12, 26 }, to = { 1, 1 },
        accent = { 200, 30, 30 },
        palettes = {
            kwanzaa   = { { 220, 30, 30 }, { 255, 200, 80 }, { 30, 200, 60 } },
            red_green = { { 220, 30, 30 }, { 30, 200, 60 } },
            gold      = { { 255, 190, 60 } },
            candle    = { { 255, 214, 150 } },
        },
        shows = { 'gentle', 'classic', 'build' },
        props = {
            { model = 'v_res_fa_candle01',       label = 'Candle (tall)', collision = false, desc = 'A tall pillar candle in a holder.' },
            { model = 'v_res_fa_candle02',       label = 'Candle (medium)', collision = false, desc = 'A medium pillar candle in a holder.' },
            { model = 'v_res_fa_candle03',       label = 'Candle (short)', collision = false, desc = 'A short pillar candle in a holder.' },
            { model = 'prop_mem_candle_combo',   label = 'Candle cluster', collision = false, desc = 'A cluster of small candles, lit. Steps and windowsills.' },
            { model = 'apa_mp_h_acc_candles_01', label = 'Candle set (tray)', collision = false, build = 944, desc = 'A tray of candles. Tables and sideboards.' },
            { model = 'm25_2_prop_m52_present_01a', label = 'Wrapped present', build = 3570, desc = 'A single wrapped present with a ribbon.' },
            { model = 'apa_mp_h_acc_vase_flowers_01', label = 'Vase of flowers', collision = false, build = 944, desc = 'A vase of flowers.' },
            { model = 'prop_snow_woodpile_04a',  label = 'Woodpile', desc = 'A stacked woodpile.' },
            { model = 'prop_table_03',            label = 'Picnic table', desc = 'A wooden picnic table with benches.' },
        },
    },

    memorialday = {
        -- Last Monday of May; the window covers it every year.
        from = { 5, 20 }, to = { 6, 1 },
        accent = { 40, 60, 160 },
        palettes = {
            usa        = { { 255, 30, 30 }, { 255, 255, 255 }, { 40, 90, 255 } },
            red_white  = { { 255, 30, 30 }, { 255, 255, 255 } },
            blue_white = { { 40, 90, 255 }, { 255, 255, 255 } },
            white      = { { 255, 255, 255 } },
            candle     = { { 255, 214, 150 } },
        },
        shows = { 'gentle', 'classic' },
        props = {
            { model = 'prop_flag_us',            label = 'US flag (pole)', far = true, desc = 'A US flag on a full-height pole.' },
            { model = 'prop_flag_us_s',          label = 'US flag (small pole)', desc = 'A US flag on a short pole.' },
            { model = 'prop_flag_us_r',          label = 'US flag (rooftop)', far = true, desc = 'A US flag on a rooftop pole.' },
            { model = 'reh_prop_reh_deskflag_us_01a', label = 'US desk flag', collision = false, build = 3258, desc = 'A small US flag on a desk stand.' },
            { model = 'prop_mem_candle_combo',   label = 'Candle cluster', collision = false, desc = 'A cluster of small candles, lit. Steps and windowsills.' },
            { model = 'v_res_fa_candle01',       label = 'Candle (tall)', collision = false, desc = 'A tall pillar candle in a holder.' },
            { model = 'apa_mp_h_acc_vase_flowers_01', label = 'Vase of flowers', collision = false, build = 944, desc = 'A vase of flowers.' },
            { model = 'apa_mp_h_acc_vase_flowers_02', label = 'Vase of flowers (tall)', collision = false, build = 944, desc = 'A tall vase of flowers.' },
            { model = 'prop_snow_flower_01',     label = 'Flower bed', desc = 'A bed of flowers.' },
            { model = 'prop_single_rose',        label = 'Single rose', collision = false, desc = 'A single long-stemmed rose.' },
        },
    },

    laborday = {
        -- First Monday of September.
        from = { 8, 28 }, to = { 9, 8 },
        accent = { 230, 120, 30 },
        palettes = {
            usa       = { { 255, 30, 30 }, { 255, 255, 255 }, { 40, 90, 255 } },
            warm      = { { 255, 214, 150 } },
            red_white = { { 255, 30, 30 }, { 255, 255, 255 } },
            orange    = { { 255, 140, 30 } },
        },
        shows = { 'classic', 'dance', 'gentle' },
        props = {
            { model = 'prop_table_03',            label = 'Picnic table', desc = 'A wooden picnic table with benches.' },
            { model = 'prop_flag_us_s',          label = 'US flag (small pole)', desc = 'A US flag on a short pole.' },
            { model = 'ind_prop_firework_01',    label = 'Firework (box)', desc = 'A box of fireworks, fused.' },
            { model = 'ind_prop_firework_04',    label = 'Firework (cake)', desc = 'A firework cake with many tubes.' },
            { model = 'm25_2_prop_m52_balloons_01a', label = 'Balloon bunch', build = 3570, desc = 'A bunch of helium balloons on ribbons.' },
            { model = 'xs_prop_arena_confetti_cannon', label = 'Confetti cannon', build = 1604, desc = 'A confetti cannon on a stand. Entrances and stages.' },
            { model = 'prop_snow_woodpile_04a',  label = 'Woodpile', desc = 'A stacked woodpile.' },
            { model = 'prop_haybale_stack_01',   label = 'Hay bale stack', desc = 'A stack of hay bales. Porches and lawns.' },
        },
    },

    wedding = {
        -- No dates: on whenever the Party set is (Config.Season.PartyAlwaysOn).
        always = true,
        accent = { 240, 200, 220 },
        palettes = {
            white      = { { 255, 255, 255 } },
            warm_white = { { 255, 214, 150 } },
            blush      = { { 255, 255, 255 }, { 255, 190, 220 } },
            gold       = { { 255, 190, 60 } },
            rose       = { { 255, 60, 100 }, { 255, 180, 200 }, { 255, 255, 255 } },
        },
        shows = { 'gentle', 'classic', 'build' },
        props = {
            { model = 'apa_mp_h_acc_vase_flowers_01', label = 'Vase of flowers', collision = false, build = 944, desc = 'A vase of flowers.' },
            { model = 'apa_mp_h_acc_vase_flowers_02', label = 'Vase of flowers (tall)', collision = false, build = 944, desc = 'A tall vase of flowers.' },
            { model = 'apa_mp_h_acc_vase_flowers_03', label = 'Vase of flowers (bowl)', collision = false, build = 944, desc = 'A low bowl of flowers.' },
            { model = 'apa_mp_h_acc_vase_flowers_04', label = 'Vase of flowers (spray)', collision = false, build = 944, desc = 'A spray of flowers in a vase.' },
            { model = 'v_res_rosevase',          label = 'Roses in a vase', collision = false, desc = 'Red roses in a vase.' },
            { model = 'prop_single_rose',        label = 'Single rose', collision = false, desc = 'A single long-stemmed rose.' },
            { model = 'ch_prop_champagne_01a',   label = 'Champagne', collision = false, build = 1868, desc = 'A bottle of champagne.' },
            { model = 'ba_prop_club_champset',   label = 'Champagne service', collision = false, build = 1493, desc = 'Champagne in a bucket with glasses.' },
            { model = 'v_res_cakedome',          label = 'Cake under glass', collision = false, desc = 'A cake under a glass dome.' },
            { model = 'v_prop_floatcandle',      label = 'Floating candle', collision = false, desc = 'A floating candle in a glass.' },
            { model = 'v_res_fa_candle01',       label = 'Candle (tall)', collision = false, desc = 'A tall pillar candle in a holder.' },
            { model = 'prop_mem_candle_combo',   label = 'Candle cluster', collision = false, desc = 'A cluster of small candles, lit. Steps and windowsills.' },
            { model = 'm25_2_prop_m52_balloons_01a', label = 'Balloon bunch', build = 3570, desc = 'A bunch of helium balloons on ribbons.' },
            { model = 'prop_table_03',            label = 'Picnic table', desc = 'A wooden picnic table with benches.' },
        },
    },

    birthday = {
        always = true,
        accent = { 255, 120, 200 },
        palettes = {
            rainbow = { { 255, 40, 40 }, { 255, 140, 40 }, { 255, 220, 40 }, { 40, 220, 60 }, { 40, 90, 255 }, { 160, 60, 220 } },
            pastel  = { { 255, 190, 220 }, { 190, 230, 255 }, { 255, 250, 180 }, { 200, 255, 200 } },
            neon    = { { 255, 40, 200 }, { 40, 255, 255 } },
            pink    = { { 255, 110, 170 } },
            blue    = { { 40, 90, 255 } },
        },
        shows = { 'dance', 'strobe', 'build', 'classic' },
        props = {
            { model = 'm25_2_prop_m52_balloons_01a', label = 'Balloon bunch', build = 3570, desc = 'A bunch of helium balloons on ribbons.' },
            { model = 'm25_2_prop_m52_balloons_02a', label = 'Balloon bunch (alt)', build = 3570, desc = 'A second bunch of balloons in other colors.' },
            { model = 'xm3_prop_xm3_balloon_01a', label = 'Balloon (single)', collision = false, build = 2802, desc = 'A single balloon on a string.' },
            { model = 'xs_prop_arena_confetti_cannon', label = 'Confetti cannon', build = 1604, desc = 'A confetti cannon on a stand. Entrances and stages.' },
            { model = 'v_res_cakedome',          label = 'Cake under glass', collision = false, desc = 'A cake under a glass dome.' },
            { model = 'm23_2_prop_m32_giftbox_small_01a', label = 'Gift box (small)', build = 3095, desc = 'A small wrapped gift with a bow.' },
            { model = 'm23_2_prop_m32_giftbox_med_01a',   label = 'Gift box (medium)', build = 3095, desc = 'A wrapped gift, knee high.' },
            { model = 'm23_2_prop_m32_giftbox_lar_01a',   label = 'Gift box (large)', build = 3095, desc = 'A large wrapped gift, waist high.' },
            { model = 'm25_2_prop_m52_present_01a', label = 'Wrapped present', build = 3570, desc = 'A single wrapped present with a ribbon.' },
            { model = 'ba_prop_club_champset',   label = 'Champagne service', collision = false, build = 1493, desc = 'Champagne in a bucket with glasses.' },
            { model = 'prop_table_03',            label = 'Picnic table', desc = 'A wooden picnic table with benches.' },
        },
    },

    funeral = {
        always = true,
        accent = { 120, 110, 140 },
        palettes = {
            white      = { { 255, 255, 255 } },
            candle     = { { 255, 214, 150 } },
            soft       = { { 230, 225, 240 } },
            purple     = { { 160, 120, 220 }, { 255, 255, 255 } },
        },
        shows = { 'gentle', 'classic' },
        props = {
            { model = 'prop_mem_candle_combo',   label = 'Candle cluster', collision = false, desc = 'A cluster of small candles, lit. Steps and windowsills.' },
            { model = 'v_res_fa_candle01',       label = 'Candle (tall)', collision = false, desc = 'A tall pillar candle in a holder.' },
            { model = 'v_res_fa_candle02',       label = 'Candle (medium)', collision = false, desc = 'A medium pillar candle in a holder.' },
            { model = 'v_prop_floatcandle',      label = 'Floating candle', collision = false, desc = 'A floating candle in a glass.' },
            { model = 'apa_mp_h_acc_vase_flowers_01', label = 'Vase of flowers', collision = false, build = 944, desc = 'A vase of flowers.' },
            { model = 'apa_mp_h_acc_vase_flowers_02', label = 'Vase of flowers (tall)', collision = false, build = 944, desc = 'A tall vase of flowers.' },
            { model = 'apa_mp_h_acc_vase_flowers_04', label = 'Vase of flowers (spray)', collision = false, build = 944, desc = 'A spray of flowers in a vase.' },
            { model = 'v_res_rosevase',          label = 'Roses in a vase', collision = false, desc = 'Red roses in a vase.' },
            { model = 'prop_single_rose',        label = 'Single rose', collision = false, desc = 'A single long-stemmed rose. Lay one on the casket.' },
            { model = 'prop_snow_flower_01',     label = 'Flower bed', desc = 'A bed of flowers.' },
            { model = 'prop_coffin_01',          label = 'Casket (wood)', desc = 'A wooden casket, closed.' },
            { model = 'prop_coffin_02',          label = 'Casket (plain)', desc = 'A plain casket.' },
            { model = 'prop_flag_us_s',          label = 'US flag (small pole)', desc = 'A US flag on a short pole. For a service with honors.' },
        },
    },

    party = {
        -- No dates. Config.Season.PartyAlwaysOn decides (also Wedding,
        -- Birthday and Funeral).
        always = true,
        accent = { 60, 180, 255 },
        palettes = {
            rainbow = { { 255, 40, 40 }, { 255, 140, 40 }, { 255, 220, 40 }, { 40, 220, 60 }, { 40, 90, 255 }, { 160, 60, 220 } },
            white   = { { 255, 255, 255 } },
            warm    = { { 255, 214, 150 } },
            neon    = { { 255, 40, 200 }, { 40, 255, 255 } },
            blue    = { { 40, 90, 255 } },
            red     = { { 255, 30, 30 } },
            green   = { { 30, 220, 60 } },
        },
        shows = { 'dance', 'strobe', 'build', 'classic', 'gentle' },
        props = {
            { model = 'm25_2_prop_m52_balloons_01a', label = 'Balloon bunch', build = 3570, desc = 'A bunch of helium balloons on ribbons.' },
            { model = 'm25_2_prop_m52_balloons_02a', label = 'Balloon bunch (alt)', build = 3570, desc = 'A second bunch of balloons in other colors.' },
            { model = 'xs_prop_arena_confetti_cannon', label = 'Confetti cannon', build = 1604, desc = 'A confetti cannon on a stand. Entrances and stages.' },
            { model = 'v_res_cakedome',              label = 'Cake under glass', collision = false, desc = 'A cake under a glass dome.' },
            { model = 'ba_prop_club_champset',       label = 'Champagne service', collision = false, build = 1493, desc = 'Champagne in a bucket with glasses.' },
            { model = 'prop_table_03',            label = 'Picnic table', desc = 'A wooden picnic table with benches.' },
            { model = 'ind_prop_firework_04',        label = 'Firework (cake)', desc = 'A firework cake with many tubes.' },
        },
    },
}

-- The shipped catalog, kept apart so a rebuild starts from it rather than
-- from whatever the last rebuild left.
local base = {}
for name, h in pairs(Holidays.Catalog) do
    local props = {}
    -- The inflatables that ship as real models come first, under each of
    -- their holidays (shared/inflatable_models.lua, generated by the
    -- build). The panel's Inflatables tab places them; the server treats
    -- them like any catalog prop.
    for _, m in ipairs(InflatableModels or {}) do
        for _, hol in ipairs(m.holidays or {}) do
            if hol == name then
                props[#props + 1] = { model = m.model, label = ('%s (inflatable, %.1f m)'):format(m.label, m.size),
                    desc = m.desc, inflatable = true, shape = m.shape, arch = m.arch == true, far = m.size >= 2.4 }
            end
        end
    end
    for _, p in ipairs(h.props or {}) do props[#props + 1] = p end
    base[name] = { props = props, from = h.from, to = h.to, enabled = h.enabled }
end

local function parseDate(s)
    if type(s) == 'table' and tonumber(s[1]) and tonumber(s[2]) then return { tonumber(s[1]), tonumber(s[2]) } end
    if type(s) ~= 'string' then return nil end
    local m, d = s:match('^(%d%d?)%-(%d%d?)$')
    m, d = tonumber(m), tonumber(d)
    if not m or not d or m < 1 or m > 12 or d < 1 or d > 31 then return nil end
    return { m, d }
end

--- Rebuilds the live catalog from the shipped one plus the settings:
--- Config.Holidays (date windows, enabled) and Config.CustomProps. Called
--- at load and whenever settings change.
function Holidays.Rebuild()
    for name, h in pairs(Holidays.Catalog) do
        local b = base[name]
        local props = {}
        for i, p in ipairs(b.props) do props[i] = p end
        h.props = props
        h.from, h.to, h.enabled = b.from, b.to, b.enabled
        local over = (Config.Holidays or {})[name]
        if type(over) == 'table' then
            if over.enabled ~= nil then h.enabled = over.enabled ~= false end
            local f, t = parseDate(over.from), parseDate(over.to)
            if f and t and not h.easter and not h.always then h.from, h.to = f, t end
        end
    end
    for _, p in ipairs(Config.CustomProps or {}) do
        local h = type(p) == 'table' and Holidays.Catalog[p.holiday]
        if h and type(p.model) == 'string' then
            h.props[#h.props + 1] = { model = p.model, label = p.label or p.model, wall = p.wall == true, custom = true,
                far = p.far == true, collision = p.collision ~= false }
        end
    end
end

Holidays.Rebuild()

function Holidays.Get(name)
    local h = Holidays.Catalog[name]
    if h and h.enabled == false then return nil end
    return h
end

function Holidays.IsValid(name)
    return Holidays.Get(name) ~= nil
end

--- The palette's color list, or nil.
function Holidays.Palette(holiday, palette)
    local h = Holidays.Get(holiday)
    if not h then return nil end
    return h.palettes and h.palettes[palette] or nil
end

--- The catalog entry for a model under a holiday, or nil. The server uses
--- this to refuse a model that is not in the catalog: the catalog is the
--- allowlist.
function Holidays.Prop(holiday, model)
    local h = Holidays.Get(holiday)
    if not h then return nil end
    for _, p in ipairs(h.props or {}) do
        if p.model == model then return p end
    end
    return nil
end

--- Which holidays are in season on a given date, under a mode. Returns a
--- set { christmas = true, ... }. Pure, so the server and a test agree.
function Holidays.Active(mode, year, month, day)
    local out = {}
    if mode == 'none' then return out end
    if mode == 'all' then
        for name, h in pairs(Holidays.Catalog) do
            if h.enabled ~= false then out[name] = true end
        end
        return out
    end
    if mode ~= 'auto' then
        if Holidays.IsValid(mode) then out[mode] = true end
        return out
    end

    local doy = Util.DayOfYear(year, month, day)
    for name, h in pairs(Holidays.Catalog) do
        if h.enabled ~= false then
            if h.always then
                -- The dateless sets (Party, Wedding, Birthday, Funeral) are
                -- on whenever PartyAlwaysOn is.
                if Config.Season.PartyAlwaysOn ~= false then out[name] = true end
            elseif h.easter then
                local em, ed = Util.EasterDate(year)
                local e = Util.DayOfYear(year, em, ed)
                local span = tonumber(h.span) or 14
                if doy >= e - span and doy <= e + span then out[name] = true end
            elseif h.from and h.to then
                if Util.InWindow(year, doy, h.from, h.to) then out[name] = true end
            end
        end
    end
    return out
end
