--[[
    Fireworks: the launchers, the shells they fire, and the choreography
    that fires them to the music.

    A LAUNCHER is one of the game's four firework props placed like any
    other decoration (it is a prop record with a `fw` table: what it is
    loaded with, its colors, its channel, how high it fires, how it is
    aimed). Every firework prop is a launcher, including ones placed
    before 1.2.0 from the Props tab; they get the defaults below.

      mortar    aerial shells: peony, chrysanthemum, willow, ring, spiral,
                crackle, strobe, salute, and holiday SHAPES (a heart, a
                star, a shamrock, a pumpkin) bursting high over the show
      rocket    rockets on a wobbling trail, bursting lower and quicker
      cake      a fan of small shots in quick succession
      fountain  a shower of sparks on the ground

    A HIDDEN launcher has no prop: a launch point on a roof or behind a
    wall. Decorators see a marker for it; nobody else sees anything until
    it fires.

    A SHOW with fireworks runs one of these against the location's
    launchers:

      score     "Follow the music": every shipped track has a firework
                score written from its notes (shared/fireworks_scores.lua,
                made by tools/build-fireworks.py). Shells burst on the
                melody, low notes on the left launchers and high notes on
                the right, long notes as big shells, salvos on the phrase
                starts, and a finale. A track without a score (one an
                owner added) gets the Grand program at its tempo.
      grand, steady, gentle, rapid, finale
                programs built on the track's beat
      show      the light show's own fireworks steps (the Shows editor)

    Every client builds the same cue list from the same numbers and the
    same seed, so a show needs no traffic after its start.

    Nothing here is an explosion. The game's explosion natives damage,
    set fires and trip anticheats; every firework is a particle effect, a
    light and a sound, and nobody can be hurt by one.
]]

Fireworks = {}

-- ---------------------------------------------------------------------
-- Particle effects (verified against the game's particle dictionaries)
-- ---------------------------------------------------------------------
local IND  = 'scr_indep_fireworks'       -- base game: the tintable ones
local V2   = 'proj_indep_firework_v2'    -- red, white and blue, baked in
local XMAS = 'proj_xmas_firework'        -- red, green and white, baked in
local PROJ = 'proj_indep_firework'
local WPN  = 'wpn_indep_firework'
local MICH = 'scr_rcpaparazzo1'
local LNY  = 'scr_hr_lny_races'          -- shapes and big bursts; newer game builds only

-- Holidays whose colors the baked-in effects suit.
local RWB  = { july4 = true, memorialday = true, laborday = true }
local RGW  = { christmas = true }

--[[
    One shell effect. `fx` lists candidates; the first one whose
    dictionary loaded on this client, and whose `holidays` (if any)
    includes the show's holiday, is fired. `tint` colors it with the
    shell's color (the baked ones ignore it). `drawn` is the spark
    pattern drawn by the script itself: always for trails and figure
    shapes, and in place of the game effect when no candidate is
    available (an older build, or Renderer 'drawn'). `sound` is a file in
    audio/sfx/ without the extension.
]]
Fireworks.Effects = {
    small = { label = 'Small burst', radius = 9, sound = 'pop', flash = 0.5,
        fx = { { LNY, 'scr_hr_lny_firework_burst_small', 1.0, tint = true }, { IND, 'scr_indep_firework_starburst', 0.6, tint = true } },
        drawn = 'peony' },
    peony = { label = 'Peony', radius = 14, sound = 'boom', flash = 1.0,
        fx = { { IND, 'scr_indep_firework_starburst', 1.0, tint = true } },
        drawn = 'peony' },
    chrysanthemum = { label = 'Chrysanthemum', radius = 18, sound = 'boom_big', flash = 1.2,
        fx = { { LNY, 'scr_hr_lny_firework_burst_large', 1.0, tint = true }, { IND, 'scr_indep_firework_starburst', 1.4, tint = true } },
        drawn = 'chrys' },
    willow = { label = 'Willow', radius = 16, sound = 'boom_soft', flash = 0.8,
        fx = { { IND, 'scr_indep_firework_trailburst', 1.3, tint = true } },
        drawn = 'willow' },
    ring = { label = 'Ring', radius = 14, sound = 'boom', flash = 1.0,
        fx = { { XMAS, 'scr_firework_xmas_ring_burst_rgw', 1.0, holidays = RGW }, { V2, 'scr_firework_indep_ring_burst_rwb', 1.0, holidays = RWB } },
        drawn = 'ring' },
    spiral = { label = 'Spiral', radius = 14, sound = 'boom', flash = 1.0,
        fx = { { XMAS, 'scr_firework_xmas_spiral_burst_rgw', 1.0, holidays = RGW }, { V2, 'scr_firework_indep_spiral_burst_rwb', 1.0, holidays = RWB } },
        drawn = 'spiral' },
    crackle = { label = 'Crackle', radius = 13, sound = 'boom', tail = 'crackle', flash = 0.9,
        fx = { { XMAS, 'scr_firework_xmas_repeat_burst_rgw', 1.0, holidays = RGW }, { V2, 'scr_firework_indep_repeat_burst_rwb', 1.0, holidays = RWB },
               { MICH, 'scr_mich4_firework_starburst', 0.9, tint = true } },
        drawn = 'crackle' },
    strobe = { label = 'Strobe', radius = 12, sound = 'pop', tail = 'crackle', flash = 0.6, strobe = true,
        fx = { { V2, 'scr_xmas_firework_burst_fizzle', 1.0 } },
        drawn = 'strobe' },
    salute = { label = 'Salute', radius = 6, sound = 'salute', flash = 2.2, white = true, strobe = true,
        fx = { { PROJ, 'scr_indep_firework_air_burst', 1.0 } },
        drawn = 'flash' },
    shot = { label = 'Cake shot', radius = 7, sound = 'pop', flash = 0.4,
        fx = { { LNY, 'scr_hr_lny_firework_burst_small', 0.8, tint = true }, { IND, 'scr_indep_firework_starburst', 0.45, tint = true } },
        drawn = 'peony' },
    fountain = { label = 'Fountain', sound = 'fountain', ground = true,
        fx = { { IND, 'scr_indep_firework_fountain', 1.0, tint = true } },
        drawn = 'fountain' },
    fountain_tall = { label = 'Tall fountain', sound = 'fountain', ground = true,
        fx = { { LNY, 'scr_hr_lny_firework_fountain_tall', 1.0, tint = true }, { IND, 'scr_indep_firework_fountain', 1.4, tint = true } },
        drawn = 'fountain' },
}

-- How loud each sound is against the others. The files are all made to
-- the same peak; a held whistle at that peak is far louder to the ear than
-- a boom that is over in a moment, so the steady ones are turned down.
Fireworks.SoundGain = {
    boom = 1.0, boom_big = 1.0, boom_soft = 1.0, salute = 1.15, pop = 0.9, crackle = 1.0,
    launch = 0.8, whistle = 0.22, rocket = 0.4, fountain = 0.45, tick = 1.0, chime = 1.0,
}

-- The sounds that are a steady high tone rather than a bang. Outside, a
-- boom carries across town and a whistle is lost under the traffic a few
-- hundred meters off; faded over the booms' whole range, a quiet whistle
-- still stood out a long way from the show. These fade out over
-- Config.Fireworks.WhistleRange instead, and are the ones the Whistles
-- switches (server and player) turn into a plain launch thump.
Fireworks.Whistles = { whistle = true, rocket = true }

-- Colors for shapes that have one of their own: a candy cane is red and
-- white whatever the launcher is loaded with. `colors` run along the
-- outline in bands `band` long (in the figure's own units, where it spans
-- -1..1), or one per stroke with `perStroke` (strokes past the end of the
-- list take its last color). `width` draws a thin figure
-- as two parallel lines so it reads as a cane, not a scribble. A shape
-- not listed here is drawn in the launcher's first color.
local RED, WHITE, GREEN, GOLDC = { 235, 30, 40 }, { 255, 255, 255 }, { 40, 205, 70 }, { 255, 196, 90 }
Fireworks.FigureStyle = {
    candy_cane = { colors = { RED, WHITE }, band = 0.2, width = 0.14 },
    tree       = { colors = { GREEN, GOLDC }, perStroke = true },
    snowflake  = { colors = { { 200, 235, 255 } } },
    bell       = { colors = { GOLDC } },
    wreath     = { colors = { GREEN, GREEN, RED }, perStroke = true },          -- two rings, then the bow
    shamrock   = { colors = { GREEN } },
    pumpkin    = { colors = { { 255, 130, 20 }, GREEN, { 255, 220, 80 } }, perStroke = true }, -- body, stem, face
}

-- The flash and sparkle at the mouth of a launcher as a shell leaves it.
Fireworks.Launch = { { WPN, 'muz_indep_firework', 1.0 }, { PROJ, 'scr_indep_launcher_sparkle_spawn', 0.8 } }

-- Shapes the game can burst into (newer builds; the drawn figure is used
-- where the dictionary is missing). Any figure from shared/figures.lua
-- can be a shape too: 'figure:<name>' below.
Fireworks.GameShapes = {
    heart = 'scr_hr_lny_firework_burst_heart', star = 'scr_hr_lny_firework_burst_star',
    face = 'scr_hr_lny_firework_burst_face', dragon = 'scr_hr_lny_firework_burst_dragon',
    rabbit = 'scr_hr_lny_firework_burst_rabbit', cat = 'scr_hr_lny_firework_burst_cat',
    horse = 'scr_hr_lny_firework_burst_horse', snake = 'scr_hr_lny_firework_burst_snake',
}
Fireworks.ShapeDict = LNY

-- What the shape shells of each holiday burst into, in turn. 'game:x'
-- is a game shape, 'figure:x' a rope-light figure drawn in sparks and
-- turned to face whoever is watching. 'year' spells the year across the
-- launchers (the year that is starting, at New Year's).
Fireworks.HolidayShapes = {
    christmas    = { 'game:star', 'figure:tree', 'figure:snowflake', 'figure:bell', 'figure:candy_cane' },
    hanukkah     = { 'figure:star_david', 'figure:dreidel', 'figure:menorah', 'figure:snowflake' },
    kwanzaa      = { 'game:star', 'figure:circle', 'game:heart' },
    newyear      = { 'year', 'figure:clock', 'figure:champagne', 'game:star', 'figure:bell' },
    valentines   = { 'game:heart', 'figure:heart', 'figure:cupid', 'figure:rose' },
    stpatricks   = { 'figure:shamrock', 'figure:leprechaun_hat', 'figure:rainbow' },
    easter       = { 'figure:egg', 'figure:bunny', 'figure:tulip', 'figure:chick' },
    memorialday  = { 'game:star', 'figure:flag', 'figure:dove' },
    july4        = { 'game:star', 'figure:flag', 'figure:star', 'figure:burst' },
    laborday     = { 'game:star', 'figure:hardhat', 'figure:flag' },
    halloween    = { 'figure:pumpkin', 'figure:bat', 'figure:skull', 'game:face', 'figure:ghost', 'figure:cat' },
    thanksgiving = { 'figure:leaf', 'figure:turkey', 'figure:acorn' },
    party        = { 'game:face', 'game:star', 'figure:note', 'figure:balloon', 'game:heart' },
    wedding      = { 'game:heart', 'figure:rings', 'figure:dove', 'figure:heart' },
    birthday     = { 'figure:cake', 'game:face', 'figure:balloon', 'figure:present' },
    funeral      = { 'figure:dove', 'figure:cross', 'figure:lily' },
}

-- ---------------------------------------------------------------------
-- Launchers
-- ---------------------------------------------------------------------
-- role: aerial (fires shells), cake, fountain. loads: what it can be
-- loaded with; 'mixed' picks by the music (small notes small shells, long
-- notes big ones, accents rings and crackle).
Fireworks.Racks = {
    { name = 'mortar', model = 'ind_prop_firework_01', role = 'aerial', label = 'Mortar rack',
      desc = 'Aerial shells that burst high over the show. The backbone of a display.',
      loads = { 'mixed', 'peony', 'chrysanthemum', 'willow', 'ring', 'spiral', 'crackle', 'strobe', 'salute', 'shapes' },
      height = { 45, 95 } },
    { name = 'rocket', model = 'ind_prop_firework_02', role = 'aerial', label = 'Rocket',
      desc = 'Rockets on a wobbling trail with a whistle, bursting lower and sooner than shells.',
      loads = { 'mixed', 'peony', 'crackle', 'strobe', 'willow' }, rocket = true,
      height = { 30, 60 } },
    { name = 'cake', model = 'ind_prop_firework_04', role = 'cake', label = 'Cake',
      desc = 'A fan of small shots in quick succession. Good in a row along a roofline.',
      loads = { 'mixed', 'peony', 'crackle', 'strobe' },
      height = { 22, 40 } },
    { name = 'fountain', model = 'ind_prop_firework_03', role = 'fountain', label = 'Fountain',
      desc = 'A shower of sparks on the ground, running for a few seconds at a time.',
      loads = { 'gold', 'color', 'tall' },
      height = { 4, 8 } },
}
Fireworks.RackByName, Fireworks.RackByModel = {}, {}
for _, r in ipairs(Fireworks.Racks) do
    Fireworks.RackByName[r.name] = r
    Fireworks.RackByModel[r.model] = r
end

--- The rack a prop model is, or nil when it is not a launcher.
function Fireworks.Rack(model) return Fireworks.RackByModel[model] end

-- Color schemes every holiday's launchers may use, beside its own.
Fireworks.Palettes = {
    gold    = { { 255, 196, 90 } },
    silver  = { { 235, 240, 255 } },
    rainbow = { { 255, 40, 40 }, { 255, 150, 20 }, { 255, 235, 60 }, { 60, 255, 100 }, { 60, 150, 255 }, { 190, 80, 255 } },
}

--- The colors of a launcher's palette under its holiday.
function Fireworks.Colors(holiday, palette)
    local c = Fireworks.Palettes[palette]
    if c then return c end
    if Holidays and Holidays.Palette then c = Holidays.Palette(holiday, palette) end
    if c then return c end
    local h = Holidays and Holidays.Get and Holidays.Get(holiday)
    if h and h.palettes then
        local names = {}
        for n in pairs(h.palettes) do names[#names + 1] = n end
        table.sort(names)
        if names[1] then return h.palettes[names[1]] end
    end
    return Fireworks.Palettes.rainbow
end

local LIFTS = { low = 0.7, medium = 1.0, high = 1.35 }
Fireworks.Lifts = LIFTS

--- A clean launcher table for a record: anything missing or wrong gets
--- the default. Used by the server on every place and restyle, and by the
--- client for props placed before launchers had settings.
function Fireworks.Clean(holiday, model, fw)
    local rack = Fireworks.RackByModel[model]
    if not rack then return nil end
    fw = type(fw) == 'table' and fw or {}
    local load = rack.loads[1]
    for _, l in ipairs(rack.loads) do if l == fw.load then load = l end end
    local palette = nil
    if type(fw.palette) == 'string' and (Fireworks.Palettes[fw.palette] or (Holidays and Holidays.Palette and Holidays.Palette(holiday, fw.palette))) then
        palette = fw.palette
    end
    local channel = math.floor(tonumber(fw.channel) or 1)
    if channel < 1 or channel > 4 then channel = 1 end
    local lift = tonumber(fw.lift) or 1.0
    if lift ~= lift then lift = 1.0 end
    lift = math.max(0.5, math.min(1.6, lift))
    local tilt = tonumber(fw.tilt) or 0.0
    if tilt ~= tilt then tilt = 0.0 end
    tilt = math.max(-35.0, math.min(35.0, tilt))
    return { load = load, palette = palette, channel = channel, lift = math.floor(lift * 100 + 0.5) / 100,
        tilt = math.floor(tilt + 0.5), hidden = fw.hidden == true or nil }
end

-- ---------------------------------------------------------------------
-- Choreography
-- ---------------------------------------------------------------------
-- A cue is { t, lane, h, size, kind, p, ch }:
--   t     when it BURSTS, in seconds from the start of the track
--   lane  0..1, which launcher across the location (left to right as
--         the launchers are laid out); -1 = every launcher
--   h     0..1, how high in the launcher's range it bursts
--   size  1..4
--   kind  one of Fireworks.Kind
--   p     1 always, 2 normal and heavy, 3 heavy only
--   ch    0 any launcher, 1..4 only that channel's
Fireworks.Kind = { shell = 1, salvo = 2, cake = 3, shape = 4, fountain = 5, accent = 6, sweep = 7 }
local K = Fireworks.Kind

Fireworks.Modes = { 'score', 'grand', 'steady', 'gentle', 'rapid', 'finale', 'show' }
Fireworks.Intensities = { light = 1, normal = 2, heavy = 3 }

-- A small deterministic generator: every client gets the same numbers.
local function rng(seed)
    local s = (math.floor(tonumber(seed) or 1) % 2147483646) + 1
    return function()
        s = (s * 48271) % 2147483647
        return (s - 1) / 2147483646
    end
end
Fireworks.Rng = rng

local function push(out, t, lane, h, size, kind, p, ch)
    out[#out + 1] = { t, lane, h, size, kind, p or 1, ch or 0 }
end

--- The finale: everything at once over the last `secs` of the track.
local function finale(out, bpm, duration, secs, rnd, gentle)
    local beat = 60.0 / bpm
    local endT = duration - 1.6           -- the tracks fade over their last 1.5 s
    local start = endT - secs
    if start < 2.0 then start = 2.0 end
    local step = gentle and beat or beat * 0.5
    local t, i = start, 0
    while t < endT - 0.3 do
        local lane = (i % 2 == 0) and rnd() * 0.5 or 0.5 + rnd() * 0.5
        push(out, t, lane, 0.5 + rnd() * 0.5, gentle and 4 or (2 + math.floor(rnd() * 3)), gentle and K.shell or (i % 6 == 5 and K.accent or K.shell), 1)
        if not gentle then
            push(out, t + step * 0.5, 1 - lane, 0.3 + rnd() * 0.4, 1 + math.floor(rnd() * 2), K.shell, 2)
            if i % 4 == 0 then push(out, t, rnd(), 0.4, 2, K.cake, 2) end
            if i % 3 == 0 then push(out, t, rnd(), 0.6, 3, K.shell, 3) end
        end
        i = i + 1
        t = t + step
    end
    -- The last word: a salvo, and on a grand finale two more under it.
    push(out, endT, -1, 1.0, 4, K.salvo, 1)
    if not gentle then
        push(out, endT - beat, -1, 0.5, 3, K.salvo, 2)
        push(out, endT - beat * 2, -1, 0.3, 2, K.sweep, 1)
        push(out, start, -1, 0.0, 3, K.fountain, 1)
    end
end
Fireworks.Finale = finale

--- A program on the beat, for any track: the same numbers on every client.
function Fireworks.Program(name, bpm, duration, seed)
    bpm = math.max(30, math.min(300, tonumber(bpm) or 120))
    duration = math.max(5, tonumber(duration) or 60)
    local out, rnd = {}, rng(seed)
    local beat = 60.0 / bpm
    local secs = math.min(15.0, math.max(6.0, duration * 0.18))
    local finaleAt = duration - 1.6 - secs
    local b = 0
    local function lane(i) return 0.5 + 0.45 * math.sin(i * 0.61 + (seed or 0) % 7) end
    if name == 'finale' then
        finale(out, bpm, duration, math.min(24.0, duration * 0.4), rnd, false)
    else
        while true do
            local t = 1.5 + b * beat
            if t >= finaleAt then break end
            if name == 'grand' then
                push(out, t, lane(b), rnd(), (b % 4 == 0) and 3 or 2, K.shell, (b % 2 == 0) and 1 or 2)
                if b % 8 == 4 then push(out, t, rnd(), 0.5, 2, K.cake, 2) end
                if b % 16 == 15 then push(out, t, -1, 0.7, 3, K.salvo, 1) end
                if b % 8 == 7 then push(out, t, lane(b + 3), 0.8, 3, K.accent, 2) end
                if b % 32 == 24 then push(out, t, 0.5, 1.0, 4, K.shape, 1) end
                if b % 24 == 12 then push(out, t, -1, 0.4, 2, K.sweep, 2) end
                if b % 16 == 0 then push(out, t, -1, 0.0, 2, K.fountain, 3) end
                if b % 2 == 1 then push(out, t + beat * 0.5, 1 - lane(b), rnd() * 0.5, 1, K.shell, 3) end
            elseif name == 'steady' then
                if b % 2 == 0 then push(out, t, lane(b), rnd(), (b % 8 == 0) and 3 or 2, K.shell, 1) end
                if b % 2 == 1 then push(out, t, 1 - lane(b), rnd() * 0.6, 1, K.shell, 3) end
                if b % 16 == 8 then push(out, t, rnd(), 0.8, 3, K.accent, 2) end
                if b % 32 == 31 then push(out, t, -1, 0.7, 3, K.salvo, 2) end
                if b % 32 == 16 then push(out, t, 0.5, 1.0, 4, K.shape, 2) end
            elseif name == 'gentle' then
                if b % 4 == 0 then push(out, t, lane(b), 0.6 + rnd() * 0.4, 4, K.shell, 1) end
                if b % 4 == 2 then push(out, t, 1 - lane(b), 0.4 + rnd() * 0.4, 3, K.shell, 3) end
                if b % 16 == 12 then push(out, t, 0.5, 1.0, 4, K.shape, 2) end
                if b % 32 == 0 then push(out, t, -1, 0.0, 1, K.fountain, 2) end
            elseif name == 'rapid' then
                push(out, t, lane(b * 2), rnd(), 1, K.shell, 1)
                push(out, t + beat * 0.5, lane(b * 2 + 1), rnd(), 1, K.shell, 2)
                if b % 4 == 0 then push(out, t, rnd(), 0.6, 2, K.shell, 1) end
                if b % 8 == 0 then push(out, t, -1, 0.5, 2, K.sweep, 1) end
                if b % 8 == 6 then push(out, t, rnd(), 0.5, 2, K.cake, 2) end
                if b % 16 == 15 then push(out, t, -1, 0.8, 3, K.salvo, 2) end
                if b % 4 == 2 then push(out, t, rnd(), 0.9, 3, K.accent, 3) end
            end
            b = b + 1
        end
        finale(out, bpm, duration, secs, rnd, name == 'gentle')
    end
    table.sort(out, function(a, c) return a[1] < c[1] end)
    return out
end

-- Fireworks patterns a show's step can give each channel (the Shows
-- editor), and what they do over the step.
Fireworks.StepPatterns = { 'none', 'beat', 'double', 'salvo', 'sweep', 'cake', 'fountain', 'shape', 'finale' }
local STEP = {}
for _, p in ipairs(Fireworks.StepPatterns) do STEP[p] = true end
function Fireworks.IsStepPattern(p) return type(p) == 'string' and STEP[p] == true end

--- The cues of a show's own fireworks steps, looped like its lights
--- until the track ends. nil when the show has no fireworks steps.
function Fireworks.FromSteps(steps, bpm, duration, seed)
    if type(steps) ~= 'table' then return nil end
    local any = false
    for _, s in ipairs(steps) do
        if type(s.fw) == 'table' then
            for c = 1, 4 do if s.fw[c] and s.fw[c] ~= 'none' then any = true end end
        end
    end
    if not any then return nil end
    bpm = math.max(30, math.min(300, tonumber(bpm) or 120))
    duration = math.max(5, tonumber(duration) or 60)
    local beat = 60.0 / bpm
    local rnd = rng(seed)
    local out = {}
    local endT = duration - 1.6
    -- Nothing bursts in the track's fade, however long the last step is.
    local function push(_, t, ...) if t <= endT then out[#out + 1] = { t, ... } end end
    local b0, n = 0.0, 0
    while b0 * beat < endT and n < 4000 do
        for _, s in ipairs(steps) do
            local beats = math.max(0.25, tonumber(s.beats) or 1)
            local t0 = b0 * beat
            if t0 >= duration - 1.6 then break end
            for c = 1, 4 do
                local p = type(s.fw) == 'table' and s.fw[c] or 'none'
                if p == 'beat' or p == 'double' or p == 'finale' then
                    local stepB = (p == 'beat') and 1.0 or 0.5
                    local k = 0.0
                    while k < beats - 1e-6 do
                        push(out, t0 + k * beat, (n + k * 2) % 4 / 3, rnd(), p == 'finale' and (2 + math.floor(rnd() * 3)) or 2, K.shell, 1, c)
                        k = k + stepB
                    end
                elseif p == 'salvo' then push(out, t0, -1, 0.7, 3, K.salvo, 1, c)
                elseif p == 'sweep' then push(out, t0, -1, 0.5, 2, K.sweep, 1, c)
                elseif p == 'cake' then push(out, t0, rnd(), 0.5, 2, K.cake, 1, c)
                elseif p == 'fountain' then push(out, t0, -1, 0.0, math.max(1, math.min(4, beats * beat / 2)), K.fountain, 1, c)
                elseif p == 'shape' then push(out, t0, 0.5, 1.0, 4, K.shape, 1, c)
                end
            end
            b0 = b0 + beats
            n = n + 1
        end
    end
    table.sort(out, function(a, c) return a[1] < c[1] end)
    return out
end

--- The score of a shipped track as cues, or nil (FireworkScores holds
--- flat lists of six numbers per cue).
function Fireworks.Score(track)
    local s = FireworkScores and FireworkScores[track]
    if not s or type(s.e) ~= 'table' then return nil end
    local out, e = {}, s.e
    for i = 1, #e - 5, 6 do
        out[#out + 1] = { e[i], e[i + 1], e[i + 2], e[i + 3], e[i + 4], e[i + 5], 0 }
    end
    return out, s.style
end

--- The cue list for a show: by mode, thinned to the intensity. Same
--- arguments, same list, on every client.
function Fireworks.Cues(mode, track, trackDef, showDef, intensity, seed)
    local bpm = trackDef and trackDef.bpm or 120
    local duration = trackDef and trackDef.duration or 60
    local cues
    if mode == 'show' then cues = showDef and Fireworks.FromSteps(showDef.steps, bpm, duration, seed) end
    if not cues and (mode == 'score' or mode == 'show') then
        cues = Fireworks.Score(track)
        -- A track without a score, or a score written for a different
        -- length (an owner replaced the file): the Grand program instead.
        if cues and FireworkScores[track].duration and math.abs(FireworkScores[track].duration - duration) > 3 then cues = nil end
    end
    if not cues then
        local prog = (mode == 'score' or mode == 'show') and 'grand' or mode
        cues = Fireworks.Program(prog, bpm, duration, seed)
    end
    local keep = Fireworks.Intensities[intensity] or 2
    local out = {}
    for _, c in ipairs(cues) do
        if (c[6] or 1) <= keep then out[#out + 1] = c end
    end
    return out
end

--- How many cues a list has of each kind, for the panel and the tests.
function Fireworks.Summary(cues)
    local n, kinds = 0, {}
    for _, c in ipairs(cues or {}) do
        n = n + 1
        kinds[c[5]] = (kinds[c[5]] or 0) + 1
    end
    return n, kinds
end
