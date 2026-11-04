--[[
    Defaults and the settings schema.

    There is no config.lua. Every setting has a default here, and the live
    value is whatever an admin set in game (the Settings tab of /holiday),
    kept in data/settings.json and pushed to every client. The schema
    below is what the Settings tab renders from and what the server
    validates against -- add a setting here and it appears in game.

    HOW IT FITS TOGETHER

    A DECORATION is one thing placed in the world. Three kinds:

      prop    a model from the catalog, on the ground or on a wall.
      lights  a string of bulbs run point to point along any surface, or
              a rope-light FIGURE (star, snowflake...) placed on a wall.
      shape   an INFLATABLE (a lit lawn blow-up: turkey, snowman, ghost...)
              or a WREATH, drawn in game from shapes (shared/shapes.lua),
              no model needed. Inflatables inflate when placed, deflate
              when removed or switched off, and sway while they are up.

    Every decoration belongs to a HOLIDAY (decides WHEN it shows; the
    season calendar turns each holiday on and off by date) and a GROUP
    (what a SHOW drives: a track plus a choreography of the four light
    CHANNELS, run against every string in one group).
]]

Config = {}

Config.Locale = 'en'
Config.Debug = { Enabled = false, Prefix = '[sals_kewlholidays]' }

Config.Access = {
    Everyone           = false,
    Ace                = 'holiday.decorate',
    AdminAce           = 'holiday.admin',
    Jobs               = { 'admin', 'realestate', 'cityhall' },
    RequireDuty        = true,
    OwnOnly            = true,
    MaxPerPlayer       = 80,
    MaxTotal           = 2000,
    AnyoneCanStartShow = false,
    Reach              = 60.0,
}

-- Mode 'all' shows every decoration all year. 'auto' turns each holiday's
-- decorations on and off by its dates (Easter computed) -- opt into it
-- from Settings once the city is decorated. Decorators always see their
-- own holiday's work while placing (the preview switch in My settings).
Config.Season = {
    Mode          = 'all',
    PartyAlwaysOn = true,
    Snow = { Enabled = false, Holidays = { 'christmas', 'newyear' }, Trails = true, Weather = false },
}

-- Per-holiday overrides of the catalog: { enabled, from = 'MM-DD', to = 'MM-DD' }.
Config.Holidays = {}

-- Props a server owner added in game: { holiday, model, label, wall }.
Config.CustomProps = {}

Config.Props = {
    Enabled           = true,     -- kill switch: false spawns no props on any client
    StreamDistance    = 150.0,
    FarStreamDistance = 400.0,
    LoadTimeout       = 5000,
}

Config.Lights = {
    -- 'sprite' is the real look: an untextured core plus a textured halo.
    -- 'core' is the same without the halo (no textured drawing at all),
    -- 'marker' plain marker spheres, 'off' nothing. The last three exist
    -- to bisect a client crash from the server console.
    Renderer        = 'sprite',
    RenderDistance  = 120.0,
    Spacing         = 0.25,
    MinSpacing      = 0.08,
    MaxSpacing      = 1.00,
    MaxPoints       = 48,     -- a Building front click uses 2 + 5 per door or window
    MaxLength       = 120.0,
    DrawWire        = true,
    WireDistance    = 35.0,
    HaloScale       = 3.2,
    HaloAlpha       = 110,
    HaloMin         = 0.12,     -- the glow never shrinks below this radius (m), however close you stand
    HaloDistance    = 60.0,     -- the textured halo is spent on bulbs this close; farther ones keep the cheap glow
    NearDistance    = 12.0,     -- the glow strengthens a little as you come within this (m), ramping smoothly
    SagRatio        = 0.03,
    SagMax          = 0.30,
    MaxBulbs        = 3000,     -- nearest strings first; a four-door barn front with icicles is about 2000
    MaxBulbsPerString = 2500,   -- a single string (icicle strands included) never computes more than this
    PreviewBulbs    = 1200,     -- the placer preview's own budget
    MaxTrisPerFrame = 9000,     -- the hard stop: untextured script triangles per frame, all strings and previews together
    MaxSpritePolys  = 800,      -- the hard stop for TEXTURED polys (halos) per frame; the textured buffer is far smaller and overflowing it crashes the client
    EmitLight       = true,
    LightEvery      = 4,        -- a cast light on every fourth bulb
    MaxLightSources = 64,
    LightRange      = 2.0,
    LightIntensity  = 0.6,
    DefaultPattern  = 'twinkle',

    -- Bulb styles. size = core diameter in meters; spacing = default bulb
    -- spacing; halo = multiplier on HaloScale; sag = multiplier on SagRatio.
    -- icicle: strands hang from the run. festoon: big warm globes.
    -- candle: a flame flicker instead of the chosen pattern.
    Styles = {
        mini    = { label = 'Mini lights',   size = 0.035, spacing = 0.20, halo = 1.0, sag = 1.0 },
        c9      = { label = 'C9 bulbs',      size = 0.060, spacing = 0.30, halo = 1.2, sag = 1.0 },
        rope    = { label = 'Rope light',    size = 0.028, spacing = 0.08, halo = 0.8, sag = 0.0 },
        icicle  = { label = 'Icicle lights', size = 0.030, spacing = 0.25, halo = 1.0, sag = 1.0,
                    strands = true, strandEvery = 1, strandMin = 0.25, strandMax = 0.65, strandSpacing = 0.07 },
        festoon = { label = 'Festoon globes', size = 0.090, spacing = 0.50, halo = 1.6, sag = 1.6 },
        candle  = { label = 'Candle flicker', size = 0.045, spacing = 0.30, halo = 1.3, sag = 0.0, pattern = 'flicker' },
    },
}

Config.Render = { Winding = 'b' }

-- Inflatables and wreaths (shared/shapes.lua). Drawn every frame as lit
-- shapes, nearest first, under a per-frame budget like the lights.
Config.Shapes = {
    Enabled        = true,
    Solid          = true,    -- the inflatable models block players and vehicles; false: everything walks and drives through them
    RenderDistance = 120.0,
    LodDistance    = 70.0,    -- beyond this a shape is one blob of its main color
    DetailDistance = 30.0,    -- within this a shape gets the fine mesh
    LightDistance  = 60.0,    -- the light inside is cast only this close
    MaxTris        = 6000,    -- triangles per frame for drawn shapes, and never more than the strings leave of Lights.MaxTrisPerFrame
    MaxLights      = 12,      -- lights inside, per frame
    EmitLight      = true,
    LightIntensity = 1.2,
    InflateSeconds = 4.0,     -- a newly placed inflatable takes this long to stand up
    DeflateSeconds = 3.0,     -- and this long to go down when removed or switched off
    Sway           = true,    -- a little lean in the wind while up
    SwayAmount     = 0.02,
    DeflateByDay   = false,   -- true: every inflatable lies deflated between DayFrom and DayTo (game clock)
    DayFrom        = 8,
    DayTo          = 17,
}

Config.Music = {
    Near      = 15.0,
    Far       = 70.0,
    Volume    = 0.6,
    AllowMute = true,
    -- Tracks: an .ogg in audio/ with its length and tempo. Owners add their
    -- own in game (the file still has to be dropped in audio/).
    Tracks = {
        jingle_bells          = { label = 'Jingle Bells',                  file = 'jingle_bells.ogg',          duration = 62, bpm = 132, holiday = 'christmas' },
        deck_the_halls        = { label = 'Deck the Halls',                file = 'deck_the_halls.ogg',        duration = 58, bpm = 126, holiday = 'christmas' },
        we_wish_you           = { label = 'We Wish You a Merry Christmas', file = 'we_wish_you.ogg',           duration = 54, bpm = 150, holiday = 'christmas' },
        carol_of_the_bells    = { label = 'Carol of the Bells',            file = 'carol_of_the_bells.ogg',    duration = 66, bpm = 160, holiday = 'christmas' },
        up_on_the_housetop    = { label = 'Up on the Housetop',            file = 'up_on_the_housetop.ogg',    duration = 56, bpm = 130, holiday = 'christmas' },
        joy_to_the_world      = { label = 'Joy to the World',              file = 'joy_to_the_world.ogg',      duration = 60, bpm = 104, holiday = 'christmas' },
        o_christmas_tree      = { label = 'O Christmas Tree',              file = 'o_christmas_tree.ogg',      duration = 60, bpm = 96,  holiday = 'christmas' },
        silent_night          = { label = 'Silent Night',                  file = 'silent_night.ogg',          duration = 72, bpm = 72,  holiday = 'christmas' },
        maoz_tzur             = { label = "Ma'oz Tzur",                    file = 'maoz_tzur.ogg',             duration = 60, bpm = 108, holiday = 'hanukkah' },
        dreidel               = { label = 'The Dreidel Song',              file = 'dreidel.ogg',               duration = 54, bpm = 126, holiday = 'hanukkah' },
        hava_nagila           = { label = 'Hava Nagila',                   file = 'hava_nagila.ogg',           duration = 60, bpm = 140, holiday = 'hanukkah' },
        auld_lang_syne        = { label = 'Auld Lang Syne',                file = 'auld_lang_syne.ogg',        duration = 62, bpm = 84,  holiday = 'newyear' },
        midnight_chimes       = { label = 'Midnight Chimes',               file = 'midnight_chimes.ogg',       duration = 48, bpm = 60,  holiday = 'newyear' },
        valentine_waltz       = { label = 'Valentine Waltz',               file = 'valentine_waltz.ogg',       duration = 60, bpm = 90,  holiday = 'valentines' },
        irish_washerwoman     = { label = 'The Irish Washerwoman',         file = 'irish_washerwoman.ogg',     duration = 56, bpm = 140, holiday = 'stpatricks' },
        shamrock_reel         = { label = 'Shamrock Reel',                 file = 'shamrock_reel.ogg',         duration = 60, bpm = 120, holiday = 'stpatricks' },
        morning_mood          = { label = 'Morning Mood',                  file = 'morning_mood.ogg',          duration = 62, bpm = 80,  holiday = 'easter' },
        easter_bells          = { label = 'Easter Bells',                  file = 'easter_bells.ogg',          duration = 50, bpm = 90,  holiday = 'easter' },
        star_spangled_banner  = { label = 'The Star-Spangled Banner',      file = 'star_spangled_banner.ogg',  duration = 60, bpm = 76,  holiday = 'july4' },
        yankee_doodle         = { label = 'Yankee Doodle',                 file = 'yankee_doodle.ogg',         duration = 52, bpm = 126, holiday = 'july4' },
        america_the_beautiful = { label = 'America the Beautiful',         file = 'america_the_beautiful.ogg', duration = 62, bpm = 84,  holiday = 'july4' },
        mountain_king         = { label = 'In the Hall of the Mountain King', file = 'mountain_king.ogg',      duration = 64, bpm = 120, holiday = 'halloween' },
        graveyard_waltz       = { label = 'Graveyard Waltz',               file = 'graveyard_waltz.ogg',       duration = 60, bpm = 120, holiday = 'halloween' },
        spooky_drone          = { label = 'Haunted Ambience',              file = 'spooky_drone.ogg',          duration = 60, bpm = 60,  holiday = 'halloween' },
        over_the_river        = { label = 'Over the River and Through the Wood', file = 'over_the_river.ogg',  duration = 56, bpm = 120, holiday = 'thanksgiving' },
        harvest_home          = { label = 'Harvest Home',                  file = 'harvest_home.ogg',          duration = 60, bpm = 92,  holiday = 'thanksgiving' },
        party_loop            = { label = 'Block Party',                   file = 'party_loop.ogg',            duration = 60, bpm = 124, holiday = 'party' },
        harambee              = { label = 'Harambee',                      file = 'harambee.ogg',              duration = 60, bpm = 100, holiday = 'kwanzaa' },
        taps                  = { label = 'Taps',                          file = 'taps.ogg',                  duration = 48, bpm = 56,  holiday = 'memorialday' },
        battle_hymn           = { label = 'Battle Hymn of the Republic',   file = 'battle_hymn.ogg',           duration = 60, bpm = 112, holiday = 'laborday' },
        bridal_chorus         = { label = 'Bridal Chorus',                 file = 'bridal_chorus.ogg',         duration = 60, bpm = 92,  holiday = 'wedding' },
        wedding_march         = { label = 'Wedding March',                 file = 'wedding_march.ogg',         duration = 58, bpm = 112, holiday = 'wedding' },
        happy_birthday        = { label = 'Happy Birthday',                file = 'happy_birthday.ogg',        duration = 42, bpm = 120, holiday = 'birthday' },
        amazing_grace         = { label = 'Amazing Grace',                 file = 'amazing_grace.ogg',         duration = 64, bpm = 66,  holiday = 'funeral' },
        nearer_my_god         = { label = 'Nearer, My God, to Thee',       file = 'nearer_my_god.ogg',         duration = 60, bpm = 72,  holiday = 'funeral' },
    },
}

-- Shows: steps of { beats, ch = { pattern x4 } }, looping until the track ends.
-- Patterns: on, off, twinkle, chase, alternate, fade, wave, flicker.
Config.Shows = {
    classic = { label = 'Classic', steps = { { beats = 8, ch = { 'twinkle', 'twinkle', 'twinkle', 'twinkle' } } } },
    dance = { label = 'Dance', steps = {
        { beats = 1, ch = { 'on',  'off', 'on',  'off' } }, { beats = 1, ch = { 'off', 'on',  'off', 'on'  } },
        { beats = 1, ch = { 'on',  'off', 'on',  'off' } }, { beats = 1, ch = { 'off', 'on',  'off', 'on'  } },
        { beats = 2, ch = { 'chase', 'chase', 'chase', 'chase' } }, { beats = 2, ch = { 'wave', 'wave', 'wave', 'wave' } },
        { beats = 1, ch = { 'on',  'on',  'off', 'off' } }, { beats = 1, ch = { 'off', 'off', 'on',  'on'  } },
        { beats = 1, ch = { 'on',  'on',  'off', 'off' } }, { beats = 1, ch = { 'off', 'off', 'on',  'on'  } },
        { beats = 4, ch = { 'twinkle', 'twinkle', 'twinkle', 'twinkle' } } } },
    build = { label = 'Build', steps = {
        { beats = 4, ch = { 'on', 'off', 'off', 'off' } }, { beats = 4, ch = { 'on', 'on', 'off', 'off' } },
        { beats = 4, ch = { 'on', 'on', 'on', 'off' } }, { beats = 4, ch = { 'on', 'on', 'on', 'on' } },
        { beats = 8, ch = { 'chase', 'chase', 'chase', 'chase' } }, { beats = 4, ch = { 'fade', 'fade', 'fade', 'fade' } },
        { beats = 2, ch = { 'off', 'off', 'off', 'off' } } } },
    gentle = { label = 'Gentle', steps = {
        { beats = 8, ch = { 'fade', 'wave', 'fade', 'wave' } }, { beats = 8, ch = { 'wave', 'fade', 'wave', 'fade' } },
        { beats = 8, ch = { 'on', 'on', 'on', 'on' } } } },
    strobe = { label = 'Strobe', steps = {
        { beats = 0.5, ch = { 'on', 'off', 'on', 'off' } }, { beats = 0.5, ch = { 'off', 'on', 'off', 'on' } } } },
}

Config.Persistence = { Enabled = true, File = 'data/decorations.json', SettingsFile = 'data/settings.json', PresetsFile = 'data/presets.json', SaveDelay = 5, Snapshots = 3 }
Config.Limits = { Enabled = true, Log = true, place = { 20, 30 }, edit = { 30, 30 }, show = { 6, 60 }, state = { 6, 60 }, settings = { 20, 60 }, thumb = { 400, 60 } }
-- OpenKey is the default key that opens the panel (FiveM key name: 'ADD' is
-- numpad +, 'F7', 'HOME', 'NUMPAD5' ...). It is only the DEFAULT: each player
-- can rebind it under Settings > Key Bindings > FiveM, and a change here only
-- reaches players who never touched the binding. Blank disables the key.
Config.Commands = { Main = 'holiday', OpenKey = 'ADD' }
Config.Integrations = { Notify = 'auto' }   -- 'auto' | 'qb' | 'ox_lib' | 'esx' | 'native'

-- Updates from a public GitHub repository that holds the released resource
-- and an update.json manifest at its root (made by tools/make-update-manifest.py).
-- Repo is 'owner/name'. Blank = no checking. AutoApply downloads and writes
-- the new files itself; the resource still has to be restarted to load them
-- (AutoRestart does that too, a minute later, if nobody is decorating).
Config.Update = {
    Enabled     = true,
    Repo        = 'csalvatoreJCRP/sals_kewlholidays',
    Branch      = 'main',
    CheckHours  = 6,
    AutoApply   = false,
    AutoRestart = false,
}

-- ---------------------------------------------------------------------
-- The schema: what the Settings tab shows, in order, and how each value
-- is checked. path is a dotted key into Config. Types: bool, int, number,
-- string, select (options), list (comma-separated strings), date (MM-DD).
-- ---------------------------------------------------------------------
Schema = {
    { section = 'access', label = 'Who may decorate', items = {
        { path = 'Access.Everyone',           type = 'bool',   label = 'Everyone may decorate', help = 'Off: only the ACE, the jobs below, or admins.' },
        { path = 'Access.Ace',                type = 'string', label = 'Decorator ACE', help = 'add_ace group.x holiday.decorate allow' },
        { path = 'Access.AdminAce',           type = 'string', label = 'Admin ACE', help = 'Also admins: anyone allowed the "command" ACE, and qb/ESX admins.' },
        { path = 'Access.Jobs',               type = 'list',   label = 'Decorator jobs', help = 'Comma-separated job names.' },
        { path = 'Access.RequireDuty',        type = 'bool',   label = 'Jobs must be on duty' },
        { path = 'Access.OwnOnly',            type = 'bool',   label = 'Decorators edit only their own', help = 'Admins always edit everything.' },
        { path = 'Access.MaxPerPlayer',       type = 'int',    label = 'Decorations per player', min = 1, max = 5000 },
        { path = 'Access.MaxTotal',           type = 'int',    label = 'Decorations on the server', min = 1, max = 50000 },
        { path = 'Access.AnyoneCanStartShow', type = 'bool',   label = 'Anyone may start a show' },
        { path = 'Access.Reach',              type = 'number', label = 'Reach (m)', min = 5, max = 500, help = 'How far a player may be from what they place or edit.' },
    } },
    { section = 'season', label = 'Season calendar', items = {
        { path = 'Season.Mode',          type = 'select', label = 'Season mode', options = { 'all', 'auto', 'none', 'christmas', 'hanukkah', 'kwanzaa', 'newyear', 'valentines', 'stpatricks', 'easter', 'memorialday', 'july4', 'laborday', 'halloween', 'thanksgiving', 'party', 'wedding', 'birthday', 'funeral' },
          help = 'all: everything shows year-round. auto: each holiday shows only in its date window. A holiday name forces just that one.' },
        { path = 'Season.PartyAlwaysOn', type = 'bool',   label = 'Party, Wedding, Birthday and Funeral sets always in season', help = 'The four dateless sets. Off: they show only when the season mode names them or is "all".' },
        { path = 'Season.Snow.Enabled',  type = 'bool',   label = 'Winter touches while Christmas is in season', help = 'Tire trails and footprints.' },
        { path = 'Season.Snow.Weather',  type = 'bool',   label = 'Force snow weather (only if nothing else sets weather)' },
    } },
    { section = 'props', label = 'Props', items = {
        { path = 'Props.Enabled',           type = 'bool',   label = 'Spawn props', help = 'Off: no client spawns any prop (diagnostic).' },
        { path = 'Props.StreamDistance',    type = 'number', label = 'Prop stream distance (m)', min = 30, max = 1000 },
        { path = 'Props.FarStreamDistance', type = 'number', label = 'Large prop stream distance (m)', min = 50, max = 2000 },
    } },
    { section = 'lights', label = 'Lights', items = {
        { path = 'Lights.Renderer',        type = 'select', label = 'Light renderer', options = { 'sprite', 'core', 'marker', 'off' }, help = 'sprite is the real look. core drops the halo (no textured drawing); marker and off are diagnostics.' },
        { path = 'Lights.MaxSpritePolys',  type = 'int',    label = 'Halo polys per frame (hard cap)', min = 0, max = 4000, help = 'Textured polys per frame. Bulbs past the cap draw without a halo. Lower it if the client ever crashes near a lot of lights.' },
        { path = 'Lights.RenderDistance',  type = 'number', label = 'Light render distance (m)', min = 20, max = 500 },
        { path = 'Lights.MaxBulbs',        type = 'int',    label = 'Bulbs per frame (budget)', min = 100, max = 20000, help = 'Nearest strings first; the rest wait. Players scale this with their quality setting.' },
        { path = 'Lights.MaxPoints',       type = 'int',    label = 'Points per string', min = 2, max = 64 },
        { path = 'Lights.MaxLength',       type = 'number', label = 'Max string length (m)', min = 5, max = 1000 },
        { path = 'Lights.HaloScale',       type = 'number', label = 'Halo size (x core)', min = 1, max = 8 },
        { path = 'Lights.HaloAlpha',       type = 'int',    label = 'Halo strength', min = 0, max = 255 },
        { path = 'Lights.HaloMin',         type = 'number', label = 'Halo minimum radius (m)', min = 0, max = 1, help = 'The glow never shrinks below this, however close you stand.' },
        { path = 'Lights.NearDistance',    type = 'number', label = 'Glow boost within (m)', min = 0, max = 100, help = 'The glow strengthens a little as you come within this distance, ramping smoothly. 0 turns it off.' },
        { path = 'Lights.SagRatio',        type = 'number', label = 'Sag between points (ratio)', min = 0, max = 0.2, help = '0 for dead-straight strings.' },
        { path = 'Lights.DrawWire',        type = 'bool',   label = 'Draw the wire' },
        { path = 'Lights.EmitLight',       type = 'bool',   label = 'Bulbs cast light on walls' },
        { path = 'Lights.LightIntensity',  type = 'number', label = 'Cast light intensity', min = 0, max = 5 },
        { path = 'Lights.LightRange',      type = 'number', label = 'Cast light range (m)', min = 0.2, max = 10 },
        { path = 'Lights.MaxLightSources', type = 'int',    label = 'Cast lights per frame', min = 0, max = 200 },
        { path = 'Render.Winding',         type = 'select', label = 'Triangle winding', options = { 'b', 'a', 'both' }, help = 'If bulbs are invisible, try the other; "both" always works at twice the cost.' },
    } },
    { section = 'shapes', label = 'Inflatables and wreaths', items = {
        { path = 'Shapes.Enabled',        type = 'bool',   label = 'Draw inflatables and wreaths', help = 'Off: none are drawn on any client (diagnostic).' },
        { path = 'Shapes.Solid',          type = 'bool',   label = 'Inflatable models are solid', help = 'On: players and vehicles bump into the inflatable models. Off: everything passes through them, for a server whose doorways and walks keep getting blocked.' },
        { path = 'Shapes.RenderDistance', type = 'number', label = 'Render distance (m)', min = 20, max = 500 },
        { path = 'Shapes.LodDistance',    type = 'number', label = 'Detail distance (m)', min = 10, max = 300, help = 'Beyond this a shape is drawn as one blob of its main color.' },
        { path = 'Shapes.DetailDistance', type = 'number', label = 'Fine detail within (m)', min = 5, max = 200, help = 'Closer than this a shape gets the fine mesh; beyond it the coarse one.' },
        { path = 'Shapes.MaxTris',        type = 'int',    label = 'Triangles per frame (budget)', min = 500, max = 40000, help = 'A Santa is about 1500 up close and 450 beyond the detail distance. Nearest first; the rest are blobs. Players scale it with their quality setting.' },
        { path = 'Shapes.MaxLights',      type = 'int',    label = 'Lights inside, per frame', min = 0, max = 100 },
        { path = 'Shapes.LightIntensity', type = 'number', label = 'Light inside, intensity', min = 0, max = 10 },
        { path = 'Shapes.InflateSeconds', type = 'number', label = 'Inflate time (s)', min = 0.5, max = 30 },
        { path = 'Shapes.DeflateSeconds', type = 'number', label = 'Deflate time (s)', min = 0.5, max = 30 },
        { path = 'Shapes.Sway',           type = 'bool',   label = 'Sway in the wind' },
        { path = 'Shapes.DeflateByDay',   type = 'bool',   label = 'Deflate during the day', help = 'Every inflatable lies in a heap between the hours below (game clock) and stands up again at dusk.' },
        { path = 'Shapes.DayFrom',        type = 'int',    label = 'Day starts (hour)', min = 0, max = 23 },
        { path = 'Shapes.DayTo',          type = 'int',    label = 'Day ends (hour)', min = 0, max = 23 },
    } },
    { section = 'music', label = 'Music', items = {
        { path = 'Music.Near',      type = 'number', label = 'Full volume within (m)', min = 1, max = 200 },
        { path = 'Music.Far',       type = 'number', label = 'Silent beyond (m)', min = 5, max = 500 },
        { path = 'Music.Volume',    type = 'number', label = 'Volume ceiling (0-1)', min = 0, max = 1 },
        { path = 'Music.AllowMute', type = 'bool',   label = 'Players may mute' },
    } },
    { section = 'update', label = 'Updates', items = {
        { path = 'Update.Enabled',     type = 'bool',   label = 'Check for updates', help = 'Fetches update.json from the repository below at start and every few hours.' },
        { path = 'Update.Repo',        type = 'string', label = 'GitHub repository (owner/name)', help = 'Public repository holding the released resource and its update.json.' },
        { path = 'Update.Branch',      type = 'string', label = 'Branch' },
        { path = 'Update.CheckHours',  type = 'number', label = 'Check every (hours)', min = 1, max = 168 },
        { path = 'Update.AutoApply',   type = 'bool',   label = 'Apply updates automatically', help = 'Downloads and writes the new files, verified by size and checksum, never touching data/. A restart loads them.' },
        { path = 'Update.AutoRestart', type = 'bool',   label = 'Restart after applying', help = 'Restarts this resource one minute after an update is applied, if nobody is mid-placement.' },
    } },
    { section = 'misc', label = 'Other', items = {
        { path = 'Persistence.SaveDelay', type = 'int',    label = 'Save delay (s)', min = 1, max = 300 },
        { path = 'Limits.Enabled',        type = 'bool',   label = 'Rate limits' },
        { path = 'Commands.Main',         type = 'string', label = 'Command name', help = 'Takes effect after a resource restart.' },
        { path = 'Commands.OpenKey',      type = 'string', label = 'Panel key (default binding)', help = "FiveM key name, e.g. ADD (numpad +), F7, HOME. Players rebind it themselves under Settings > Key Bindings; blank disables. Takes effect after a restart." },
        { path = 'Debug.Enabled',         type = 'bool',   label = 'Debug logging' },
    } },
}
