fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'sals_kewlholidays'
author 'C. Salvatore'
description "In-game holiday decorating: props, lit inflatables, wreaths, string lights and rope-light figures on any building or on parade floats that drive, spotlights and projectors, Santa's sleigh with real reindeer that players ride and that flies, a New Year's ball drop, synchronized light shows and fireworks displays set to music, countdowns, a season calendar that swaps the decor for you, and every setting edited in game"
version '1.6.2'

shared_scripts {
    'shared/defaults.lua',  -- must load first: defines Config (the defaults) and Schema; there is no config.lua
    'shared/util.lua',
    'shared/settings.lua',  -- applies the in-game settings over the defaults
    'shared/inflatable_models.lua',  -- generated: the inflatables that ship as models; must load before holidays
    'shared/fireworks.lua', -- launchers, shells, choreography; must load before holidays (every holiday gets the launchers)
    'shared/fireworks_scores.lua',  -- generated: a firework score per shipped track (tools/build-fireworks.py)
    'shared/spotlights.lua', -- spotlight fixtures and projector pictures; must load before holidays (every holiday gets the fixtures)
    'shared/sleigh.lua',    -- Santa's sleigh and the ball drop: their settings and the flight path, the same on server and client
    'shared/holidays.lua',  -- the holiday catalog; reads Config.Holidays, Config.CustomProps, InflatableModels and Fireworks
    'shared/figures.lua',   -- rope-light figure templates
    'shared/shapes.lua',    -- wreaths and lit yard pieces, drawn from shapes
    'locales/*.lua',        -- glob so a server owner can drop in a translation
    'locales/init.lua'      -- builds Lang from Config.Locale; must load last
}

client_scripts {
    'client/framework.lua', -- must load before everything: defines Client (notify)
    'client/main.lua',      -- defines Decor: the registry, prop streaming, season state, settings
    'client/floats.lua',    -- floats: decorations riding vehicles; defines Decor.Send, which the tools below use
    'client/lights.lua',    -- the string-light renderer; reads Decor
    'client/shapes.lua',    -- the wreath and yard-piece renderer; reads Decor
    'client/balldrop.lua',  -- the New Year's ball drop: drawn, and dropped by a countdown; uses lights
    'client/show.lua',      -- synchronized shows and the audio player; drives lights and fireworks
    'client/fireworks.lua', -- the fireworks engine: shells, sparks, sky light, sound; draws with the lights' primitives
    'client/spotlights.lua', -- spotlight beams, projector pictures and the aim tool; uses lights and show; placer calls it
    'client/sleigh.lua',    -- Santa's sleigh: the reindeer, rides and flights; main hides a sleigh that is out
    'client/placer.lua',    -- the point-and-click placement tools
    'client/thumbs.lua',    -- /holiday thumbs: photographs the prop catalog (needs screenshot-basic)
    'client/ui.lua'         -- the decorator panel and the /holiday command; uses all of the above
}

server_scripts {
    'server/framework.lua', -- must load before main: defines Framework
    'server/ratelimit.lua', -- every net event in main calls it
    'server/store.lua',     -- owns the registry and both files; main writes through it
    'server/update.lua',    -- version check and self-update from the public repository
    'server/main.lua',
    'server/floats.lua',    -- floats: bindings and the vehicle sweep; uses Access from main
    'server/sleigh.lua'     -- sleigh rides and Santa's flight; uses Access from main
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/bulb.png',        -- the bulb sprite, loaded as a runtime texture by client/lights.lua
    'html/projections.png', -- the projectors' pictures (tools/build-projections.py), a runtime texture and the panel's previews
    'html/thumbs/*.jpg',    -- prop pictures, taken once with /holiday thumbs; new ones are served after a restart
    'audio/*.ogg',          -- every track; a track an owner adds is picked up on restart
    'audio/sfx/*.ogg'       -- the fireworks' sounds (tools/build-fireworks.py)
}

-- Streamed models: the inflatables as real props (built by tools/build-inflatables.py
-- -> tools/blender-inflatables.py -> tools/cwconv). Everything in stream/ is
-- streamed by FiveM; the ytyp registers the archetypes.
data_file 'DLC_ITYP_REQUEST' 'stream/sk_inflatables.ytyp'
-- Santa's sleigh and what rides in it (tools/build-sleigh.py -> tools/blender-sleigh.py -> tools/cwconv).
data_file 'DLC_ITYP_REQUEST' 'stream/sk_sleigh.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/sk_sleigh_fire.ytyp'      -- the sleigh in fire department colors
data_file 'DLC_ITYP_REQUEST' 'stream/sk_sleigh_engine.ytyp'    -- the fire engine on runners

provide 'holiday_decor'

-- No hard dependencies. The framework (qb-core, qbx_core, es_extended or
-- none) is detected at runtime; ensure it BEFORE this resource.

-- ---------------------------------------------------------------------
-- Asset escrow
-- ---------------------------------------------------------------------
-- Cfx escrow encrypts every .lua in the upload. fxmanifest.lua stays
-- readable; everything else has to be named here or it ships encrypted.
escrow_ignore {
    'shared/defaults.lua',  -- the defaults and the settings schema, readable so an owner can see what each setting means
    'shared/holidays.lua',  -- the prop and holiday catalog
    'shared/inflatable_models.lua',  -- the generated list of inflatable models, part of the catalog
    'shared/figures.lua',   -- figure templates; owners may add their own
    'shared/shapes.lua',    -- wreath and yard-piece templates; owners may add their own
    'shared/fireworks.lua', -- the firework effects, launchers and programs; owners may tune them
    'shared/spotlights.lua', -- the spotlight fixtures and projector pictures; owners may add their own
    'shared/sleigh.lua',    -- the sleigh's team and the ball drop's settings; owners may tune them
    'shared/fireworks_scores.lua',
    'locales/*.lua',        -- the strings, and the template for a new language

    -- NUI files must ship unencrypted: the CEF browser cannot read
    -- escrow-encrypted files, and an encrypted html/ means no panel and no music.
    'html/*',
    'audio/*',
    'audio/sfx/*',

    -- The framework seam, readable so a server with its own framework can
    -- fit it without a support ticket.
    'server/framework.lua',

    '*.md',
    'LICENSE',
    '.luarc.json',
}

dependency '/assetpacks'