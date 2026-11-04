fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'sals_kewlholidays'
author 'C. Salvatore'
description 'In-game holiday decorating: props, inflatables that inflate and deflate, wreaths, string lights and rope-light figures on any building, synchronized light shows with music, a season calendar that swaps the decor for you, decorating tips, and every setting edited in game'
version '1.0.0'

shared_scripts {
    'shared/defaults.lua',  -- must load first: defines Config (the defaults) and Schema; there is no config.lua
    'shared/util.lua',
    'shared/settings.lua',  -- applies the in-game settings over the defaults
    'shared/inflatable_models.lua',  -- generated: the inflatables that ship as models; must load before holidays
    'shared/holidays.lua',  -- the holiday catalog; reads Config.Holidays, Config.CustomProps and InflatableModels
    'shared/figures.lua',   -- rope-light figure templates
    'shared/shapes.lua',    -- inflatables and wreaths, built from shapes
    'locales/*.lua',        -- glob so a server owner can drop in a translation
    'locales/init.lua'      -- builds Lang from Config.Locale; must load last
}

client_scripts {
    'client/framework.lua', -- must load before everything: defines Client (notify)
    'client/main.lua',      -- defines Decor: the registry, prop streaming, season state, settings
    'client/lights.lua',    -- the string-light renderer; reads Decor
    'client/shapes.lua',    -- the inflatable and wreath renderer (inflate, deflate, sway); reads Decor
    'client/show.lua',      -- synchronized shows and the audio player; drives lights
    'client/placer.lua',    -- the point-and-click placement tools
    'client/thumbs.lua',    -- /holiday thumbs: photographs the prop catalog (needs screenshot-basic)
    'client/ui.lua'         -- the decorator panel and the /holiday command; uses all of the above
}

server_scripts {
    'server/framework.lua', -- must load before main: defines Framework
    'server/ratelimit.lua', -- every net event in main calls it
    'server/store.lua',     -- owns the registry and both files; main writes through it
    'server/update.lua',    -- version check and self-update from the public repository
    'server/main.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/bulb.png',        -- the bulb sprite, loaded as a runtime texture by client/lights.lua
    'html/thumbs/*.jpg',    -- prop pictures, taken once with /holiday thumbs; new ones are served after a restart
    'audio/*.ogg'           -- every track; a track an owner adds is picked up on restart
}

-- Streamed models: the inflatables as real props (built by tools/build-inflatables.py
-- -> tools/blender-inflatables.py -> tools/cwconv). Everything in stream/ is
-- streamed by FiveM; the ytyp registers the archetypes.
data_file 'DLC_ITYP_REQUEST' 'stream/sk_inflatables.ytyp'

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
    'shared/shapes.lua',    -- inflatable and wreath templates; owners may add their own
    'locales/*.lua',        -- the strings, and the template for a new language

    -- NUI files must ship unencrypted: the CEF browser cannot read
    -- escrow-encrypted files, and an encrypted html/ means no panel and no music.
    'html/*',
    'audio/*',

    -- The framework seam, readable so a server with its own framework can
    -- fit it without a support ticket.
    'server/framework.lua',

    '*.md',
    'LICENSE',
    '.luarc.json',
}

dependency '/assetpacks'