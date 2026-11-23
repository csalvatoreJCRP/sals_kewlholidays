--[[
    SPOTLIGHTS AND PROJECTORS (1.4.0)

    A spotlight is a prop (one of the FIXTURES below) whose record carries a
    `spot` table, the way a firework launcher carries `fw`. It is placed like
    a prop, then aimed: the decorator clicks the tree or wall it lights, and
    the target (and that surface's normal) are saved with it.

    Two modes:
      beam       a colored beam from the fixture onto the target (the game's
                 own spotlight), steady, fading, cycling through the colors,
                 or driven by a show on its channel.
      projector  moving shapes on the wall where it points, like the LED
                 projectors people put on their lawns: snowflakes falling,
                 snowmen waving, turkeys dancing, bats flying. The shapes are
                 drawn flat on the wall from html/projections.png (generated
                 by tools/build-projections.py from the CELLS list below), with
                 a soft beam of the same color behind them.

    Everything here is shared: the server cleans a spot table with
    Spot.Clean before it stores it, and the client draws from the same
    definitions. Settings (budgets, brightness) are Config.Spotlights in
    shared/defaults.lua, edited in game.
]]

Spot = {}

-- The fixtures: real game props (each checked against the game's object
-- list). `hidden` on a placed spotlight leaves only the light, for the
-- "in the ground" uplight look.
Spot.Fixtures = {
    { name = 'flood',  model = 'prop_worklight_04a' },
    { name = 'box',    model = 'prop_worklight_04b' },
    { name = 'studio', model = 'prop_studio_light_02' },
    { name = 'tower',  model = 'prop_worklight_03a' },
}
Spot.FixtureByModel, Spot.FixtureByName = {}, {}
for _, f in ipairs(Spot.Fixtures) do
    Spot.FixtureByModel[f.model] = f
    Spot.FixtureByName[f.name] = f
end

--- The fixture a model is, or nil.
function Spot.Fixture(model) return model and Spot.FixtureByModel[model] or nil end

-- Beam widths: the cone in degrees, as the game's spotlight reads it.
Spot.Beams = { narrow = 10.0, wide = 20.0, flood = 34.0 }
Spot.BeamOrder = { 'narrow', 'wide', 'flood' }

-- Tree sizes for a tree of the map (the panel's choice): meters around
-- the spot clicked. A decoration's own size is measured instead.
Spot.TreeSpans = { small = 2.5, medium = 4.5, large = 7.5 }
Spot.TreeSpanOrder = { 'small', 'medium', 'large' }

-- The light patterns a spotlight can run on its own (a show overrides
-- them on its channel). Same names and math as string lights.
Spot.Patterns = { 'on', 'fade', 'twinkle', 'chase', 'alternate', 'wave', 'flicker' }
local patternOk = {}
for _, p in ipairs(Spot.Patterns) do patternOk[p] = true end

-- ---------------------------------------------------------------------
-- The projector's pictures: one atlas, 8 x 4 cells of 128 px, white
-- shapes on transparent, tinted when drawn. tools/build-projections.py
-- draws them IN THIS ORDER; keep the two in step.
-- ---------------------------------------------------------------------
Spot.AtlasCols, Spot.AtlasRows = 8, 4
Spot.Cells = {
    'flake1', 'flake2', 'flake3', 'star', 'sparkle', 'snowman', 'tree', 'candycane',
    'gift', 'bell', 'heart', 'shamrock', 'egg', 'bunny', 'pumpkin', 'ghost',
    'bat1', 'bat2', 'turkey1', 'turkey2', 'leaf', 'burst', 'dreidel', 'balloon',
    'snowman2', 'santahat', 'confetti', 'note', 'moon', 'candle', 'bunny2', 'dot',
}
Spot.CellIndex = {}
for i, n in ipairs(Spot.Cells) do Spot.CellIndex[n] = i - 1 end

-- A motif is one picture or an animation of two (frames alternate).
Spot.Motifs = {
    flake1 = { 'flake1' }, flake2 = { 'flake2' }, flake3 = { 'flake3' },
    star = { 'star' }, sparkle = { 'sparkle' }, tree = { 'tree' }, candycane = { 'candycane' },
    gift = { 'gift' }, bell = { 'bell' }, heart = { 'heart' }, shamrock = { 'shamrock' },
    egg = { 'egg' }, pumpkin = { 'pumpkin' }, ghost = { 'ghost' }, leaf = { 'leaf' },
    burst = { 'burst' }, dreidel = { 'dreidel' }, balloon = { 'balloon' }, santahat = { 'santahat' },
    confetti = { 'confetti' }, note = { 'note' }, moon = { 'moon' }, candle = { 'candle' }, dot = { 'dot' },
    snowman = { 'snowman', 'snowman2' },     -- waves
    bat = { 'bat1', 'bat2' },                -- flaps
    turkey = { 'turkey1', 'turkey2' },       -- steps
    bunny = { 'bunny', 'bunny2' },           -- hops
}

--[[ The projections. Each is layers of motifs, each layer one motion:
       fall     drift down with a sway, turning slowly (snow, leaves)
       rise     drift up with a sway (hearts, balloons)
       drift    cross sideways, bobbing (presents, ghosts)
       twinkle  stay put and sparkle (stars)
       bob      a row that sways and bobs (snowmen, eggs)
       dance    a row that hops and waddles to the beat (turkeys)
       hop      hop across (bunnies)
       fly      fly across, flapping (bats)
       burst    bloom and fade at random spots (fireworks)
       spin     stay put and spin (dreidels)
     count = how many (a far or busy frame may draw fewer), size = from-to,
     as a fraction of the lit circle's radius. ]]
Spot.Arts = {
    { name = 'snowfall', holidays = { 'christmas', 'hanukkah', 'kwanzaa', 'newyear' }, layers = {
        { motifs = { 'flake1', 'flake2', 'flake3' }, motion = 'fall', count = 29, size = { 0.12, 0.24 } },
        { motifs = { 'dot' }, motion = 'fall', count = 21, size = { 0.03, 0.054 } },
    } },
    { name = 'snowmen', holidays = { 'christmas' }, layers = {
        { motifs = { 'snowman' }, motion = 'bob', count = 3, size = { 0.45, 0.45 } },
        { motifs = { 'flake1', 'flake3' }, motion = 'fall', count = 14, size = { 0.075, 0.15 } },
        { motifs = { 'dot' }, motion = 'fall', count = 14, size = { 0.03, 0.05 } },
    } },
    { name = 'christmas', holidays = { 'christmas' }, layers = {
        { motifs = { 'tree', 'gift', 'bell', 'candycane', 'santahat' }, motion = 'drift', count = 7, size = { 0.27, 0.36 } },
        { motifs = { 'star', 'sparkle' }, motion = 'twinkle', count = 13, size = { 0.075, 0.135 } },
    } },
    { name = 'stars', holidays = '*', layers = {
        { motifs = { 'star', 'sparkle' }, motion = 'twinkle', count = 29, size = { 0.09, 0.21 } },
    } },
    { name = 'hearts', holidays = { 'valentines', 'wedding' }, layers = {
        { motifs = { 'heart' }, motion = 'rise', count = 18, size = { 0.15, 0.3 } },
        { motifs = { 'sparkle' }, motion = 'twinkle', count = 10, size = { 0.075, 0.12 } },
    } },
    { name = 'shamrocks', holidays = { 'stpatricks' }, layers = {
        { motifs = { 'shamrock' }, motion = 'fall', count = 18, size = { 0.15, 0.27 } },
        { motifs = { 'sparkle' }, motion = 'twinkle', count = 10, size = { 0.075, 0.12 } },
    } },
    { name = 'easter', holidays = { 'easter' }, layers = {
        { motifs = { 'egg' }, motion = 'bob', count = 4, size = { 0.3, 0.3 } },
        { motifs = { 'bunny' }, motion = 'hop', count = 2, size = { 0.36, 0.36 } },
    } },
    { name = 'fireworks', holidays = { 'july4', 'newyear', 'memorialday', 'laborday', 'party' }, layers = {
        { motifs = { 'burst' }, motion = 'burst', count = 7, size = { 0.375, 0.6 } },
        { motifs = { 'star' }, motion = 'twinkle', count = 13, size = { 0.075, 0.135 } },
    } },
    { name = 'halloween', holidays = { 'halloween' }, layers = {
        { motifs = { 'bat' }, motion = 'fly', count = 6, size = { 0.195, 0.285 } },
        { motifs = { 'ghost' }, motion = 'drift', count = 3, size = { 0.3, 0.36 } },
        { motifs = { 'pumpkin' }, motion = 'bob', count = 3, size = { 0.3, 0.3 } },
    } },
    { name = 'bats', holidays = { 'halloween' }, layers = {
        { motifs = { 'bat' }, motion = 'fly', count = 18, size = { 0.15, 0.27 } },
        { motifs = { 'moon' }, motion = 'twinkle', count = 1, size = { 0.39, 0.39 } },
    } },
    { name = 'turkeys', holidays = { 'thanksgiving' }, layers = {
        { motifs = { 'turkey' }, motion = 'dance', count = 3, size = { 0.45, 0.45 } },
        { motifs = { 'leaf' }, motion = 'fall', count = 16, size = { 0.105, 0.18 } },
    } },
    { name = 'leaves', holidays = { 'thanksgiving', 'laborday' }, layers = {
        { motifs = { 'leaf' }, motion = 'fall', count = 29, size = { 0.12, 0.225 } },
    } },
    { name = 'dreidels', holidays = { 'hanukkah' }, layers = {
        { motifs = { 'dreidel' }, motion = 'spin', count = 5, size = { 0.27, 0.33 } },
        { motifs = { 'star' }, motion = 'twinkle', count = 16, size = { 0.075, 0.135 } },
    } },
    { name = 'candles', holidays = { 'hanukkah', 'kwanzaa', 'funeral', 'wedding' }, layers = {
        { motifs = { 'candle' }, motion = 'bob', count = 5, size = { 0.3, 0.3 } },
        { motifs = { 'dot' }, motion = 'rise', count = 13, size = { 0.03, 0.048 } },
    } },
    { name = 'party', holidays = { 'party', 'birthday', 'newyear' }, layers = {
        { motifs = { 'balloon' }, motion = 'rise', count = 7, size = { 0.24, 0.33 } },
        { motifs = { 'confetti' }, motion = 'fall', count = 34, size = { 0.048, 0.084 } },
        { motifs = { 'note' }, motion = 'drift', count = 4, size = { 0.15, 0.21 } },
    } },
}
Spot.ArtByName = {}
for _, a in ipairs(Spot.Arts) do Spot.ArtByName[a.name] = a end

--- Is a projection offered under a holiday?
function Spot.ArtOffered(art, holiday)
    if not art then return false end
    if art.holidays == '*' then return true end
    for _, h in ipairs(art.holidays) do if h == holiday then return true end end
    return false
end

--- The projections offered under a holiday, holiday-specific ones first.
function Spot.ArtsFor(holiday)
    local mine, any = {}, {}
    for _, a in ipairs(Spot.Arts) do
        if Spot.ArtOffered(a, holiday) then
            if a.holidays == '*' then any[#any + 1] = a else mine[#mine + 1] = a end
        end
    end
    for _, a in ipairs(any) do mine[#mine + 1] = a end
    return mine
end

-- ---------------------------------------------------------------------
-- Cleaning: whatever a client sent, what is stored
-- ---------------------------------------------------------------------
local function num(v, lo, hi, default, step)
    local n = Util.Finite(v)
    if not n then return default end
    n = Util.Clamp(n, lo, hi)
    if step then n = math.floor(n / step + 0.5) * step end
    return n
end

local function unit(v)
    if type(v) ~= 'table' then return nil end
    local x, y, z = Util.Finite(v.x), Util.Finite(v.y), Util.Finite(v.z)
    if not x or not y or not z then return nil end
    local l = math.sqrt(x * x + y * y + z * z)
    if l < 0.01 or l > 1000.0 then return nil end
    return { x = x / l, y = y / l, z = z / l }
end

--- A clean spot table. `coords` (the fixture's position) bounds how far
--- the target may be (Config.Spotlights.MaxThrow); without it the target
--- is only checked for being a real point.
function Spot.Clean(holiday, model, s, coords)
    s = type(s) == 'table' and s or {}
    local C = (Config and Config.Spotlights) or {}
    local out = {
        mode    = s.mode == 'projector' and 'projector' or 'beam',
        beam    = Spot.Beams[s.beam] and s.beam or 'wide',
        bright  = num(s.bright, 0.2, 3.0, 1.0, 0.05),
        pattern = patternOk[s.pattern] and s.pattern or 'on',
        channel = math.floor(num(s.channel, 1, 4, 1)),
        cycle   = s.cycle == true or nil,
        hidden  = s.hidden == true or nil,
        scale   = num(s.scale, 0.5, 2.0, 1.0, 0.05),
        speed   = num(s.speed, 0.25, 3.0, 1.0, 0.05),
        -- Light a tree: the beam comes in from the side (a light at the
        -- foot of a tree only grazes its needles), sized to `span` meters
        -- around the target. Set by the aim tool when it points at a
        -- decoration, or by hand for a tree of the map.
        tree    = s.tree == true or nil,
        span    = num(s.span, 1.0, 15.0, 4.0, 0.1),
    }
    if type(s.palette) == 'string' and Holidays and Holidays.Palette(holiday, s.palette) then out.palette = s.palette end
    if type(s.rgb) == 'table' then
        local r, g, b = Util.Finite(s.rgb[1]), Util.Finite(s.rgb[2]), Util.Finite(s.rgb[3])
        if r and g and b then
            out.rgb = { math.floor(Util.Clamp(r, 0, 255)), math.floor(Util.Clamp(g, 0, 255)), math.floor(Util.Clamp(b, 0, 255)) }
        end
    end
    local art = Spot.ArtByName[s.art]
    if not Spot.ArtOffered(art, holiday) then art = Spot.ArtsFor(holiday)[1] end
    out.art = art and art.name or 'stars'
    local t = Util.CleanPoint and Util.CleanPoint(s.target) or nil
    if t and coords then
        local d = Util.Dist(t.x, t.y, t.z, coords.x, coords.y, coords.z)
        if d > (C.MaxThrow or 40.0) or d < 0.5 then t = nil end
    end
    out.target = t
    out.normal = t and unit(s.normal) or nil
    return out
end

--- The colors a spotlight shows: its own color, else its palette, else
--- the holiday's richest palette (the one with the most colors: orange and
--- purple at Halloween, rainbow at a party, not whichever sorts first,
--- which was "blood" and all red), else warm white.
function Spot.Colors(holiday, s)
    if s and s.rgb then return { s.rgb } end
    if s and s.palette and Holidays then
        local p = Holidays.Palette(holiday, s.palette)
        if p and #p > 0 then return p end
    end
    local h = Holidays and Holidays.Get(holiday)
    if h and h.palettes then
        -- most colors first; between equals, the most saturated (orange and
        -- purple over pale "ghostly"), then the name, so it is always the same
        local function vivid(p)
            local v = 0
            for _, c in ipairs(p) do v = v + math.max(c[1], c[2], c[3]) - math.min(c[1], c[2], c[3]) end
            return v
        end
        local best, bestName, bestV = nil, nil, -1
        for n, p in pairs(h.palettes) do
            if #p > 0 then
                local v = vivid(p)
                if not best or #p > #best or (#p == #best and (v > bestV or (v == bestV and n < bestName))) then
                    best, bestName, bestV = p, n, v
                end
            end
        end
        if best then return best end
    end
    return { { 255, 236, 200 } }
end

--- The heading that turns a fixture toward its target (GTA: 0 = north,
--- counterclockwise).
function Spot.HeadingTo(from, to)
    local dx, dy = to.x - from.x, to.y - from.y
    if dx * dx + dy * dy < 0.0001 then return nil end
    return math.deg(math.atan(-dx, dy)) % 360.0
end
