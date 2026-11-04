--[[
    Inflatables and wreaths: decorations built in game from lit shapes.

    GTA has no inflatable lawn decorations and no wreaths, and this
    resource ships no custom models (it has to work on every server
    build). So each of these is a composition of ellipsoids the client
    draws every frame: a turkey is a brown body, a fanned tail, a head, a
    wattle. Drawn opaque with a light inside, that reads from across a
    lawn like the vinyl blow-up it is standing in for; a wreath is
    the same thing drawn matte, as a ring of foliage with a bow and a
    string of bulbs through it.

    Inflatables INFLATE when placed (they rise out of a heap on the
    ground over a few seconds), DEFLATE when removed or switched off, and
    sway in the wind while they are up.

    UNIT SPACE
    Every shape is drawn in a box 1 unit tall: z runs 0 (the ground, or
    the wall point for a wreath) to 1 (the top). x is to the shape's
    right, y is toward the viewer (the way it faces). The placer scales
    the whole thing to a height in meters. `norm` at the end rescales
    whatever the generator produced so the tallest point is at z = 1.

    A part: { x, y, z, rx, ry, rz, c = {r,g,b}, a = alpha, rot = {rx,ry,rz} }
    rx/ry/rz are RADII. `a` defaults to the shape's alpha; parts with
    `a = 255` are opaque (eyes, noses, buttons). rot is degrees about each
    axis, for a tilted arm or a fanned tail feather.

    Add your own: append to Shapes.List with the same fields. The NUI
    panel draws a thumbnail from the same parts, so a new one shows up
    with a picture and no other work.
]]

Shapes = {}

-- Colors.
local C = {
    white   = { 245, 245, 250 }, snow = { 250, 250, 255 }, black = { 20, 20, 24 },
    red     = { 220, 30, 36 },   darkred = { 150, 20, 26 }, pink = { 255, 120, 170 },
    hotpink = { 240, 60, 130 },  orange = { 255, 125, 20 }, pumpkin = { 245, 110, 25 },
    yellow  = { 255, 215, 40 },  gold = { 235, 180, 50 },   amber = { 255, 170, 60 },
    green   = { 40, 150, 55 },   darkgreen = { 25, 95, 40 }, lime = { 110, 200, 70 },
    pine    = { 30, 110, 50 },   fir = { 20, 80, 38 },       blue = { 40, 90, 230 },
    navy    = { 25, 45, 120 },   skyblue = { 120, 180, 255 }, purple = { 130, 50, 190 },
    violet  = { 170, 90, 230 },  brown = { 120, 75, 40 },   darkbrown = { 85, 50, 25 },
    tan     = { 205, 160, 110 }, skin = { 245, 205, 170 },  gray = { 150, 150, 160 },
    silver  = { 215, 220, 235 }, straw = { 230, 200, 110 }, cream = { 250, 240, 215 },
    pastelpink = { 255, 190, 220 }, pastelblue = { 190, 225, 255 }, pastelyellow = { 255, 245, 170 },
    pastelgreen = { 200, 245, 200 }, lilac = { 225, 200, 255 },
    rust = { 190, 70, 25 }, leaf = { 215, 130, 30 }, ochre = { 200, 150, 40 },
}
Shapes.Colors = C

-- ---------------------------------------------------------------------
-- The part builders
-- ---------------------------------------------------------------------
local function P(x, y, z, rx, ry, rz, c, o)
    local p = { x, y, z, rx, ry or rx, rz or rx, c = c }
    if o then
        if o.a then p.a = o.a end
        if o.rot then p.rot = o.rot end
        if o.lit ~= nil then p.lit = o.lit end
        if o.over then p.over = true end
    end
    return p
end
local function sphere(x, y, z, r, c, o) return P(x, y, z, r, r, r, c, o) end
-- A surface feature (eye, nose, belt, button, band): drawn in a layer
-- after the body parts, so it never sinks into the part it sits on.
local function opaque(x, y, z, rx, ry, rz, c) return P(x, y, z, rx, ry, rz, c, { a = 255, over = true }) end
local function eyes(y, z, dx, r, c)
    r = r * 0.7          -- in game the markers read larger than the sheet; eyes stay beads
    return { opaque(-dx, y, z, r, r * 0.7, r, c or C.black), opaque(dx, y, z, r, r * 0.7, r, c or C.black) }
end
local function cat(t, ...)
    for _, list in ipairs({ ... }) do
        if list[1] and type(list[1]) == 'table' and list[1].c then
            for _, p in ipairs(list) do t[#t + 1] = p end
        elseif list.c then
            t[#t + 1] = list
        end
    end
    return t
end

--- Rescales a part list so its top is at z = 1 and its base at z = 0.
local function norm(parts)
    local lo, hi = math.huge, -math.huge
    for _, p in ipairs(parts) do
        if p[3] - p[6] < lo then lo = p[3] - p[6] end
        if p[3] + p[6] > hi then hi = p[3] + p[6] end
    end
    local h = hi - lo
    if h <= 0 then return parts end
    for _, p in ipairs(parts) do
        p[1], p[2], p[3] = p[1] / h, p[2] / h, (p[3] - lo) / h
        p[4], p[5], p[6] = p[4] / h, p[5] / h, p[6] / h
    end
    return parts
end

-- ---------------------------------------------------------------------
-- Inflatables
-- ---------------------------------------------------------------------
-- ---------------------------------------------------------------------
-- People: one builder for every human figure, proportioned like the real
-- lawn inflatables (a tall body on short legs, sausage arms bent at the
-- elbow, trim bands, a flat belt, mittens, boots, a face with eyes that
-- have whites). Unit space, about 1.1 tall before norm.
--
-- spec: coat, trim (bands and cuffs; nil for none), legs (color; nil =
-- the coat reaches the boots), belt, buckle, mitten, skin, beard, hair,
-- hat ('santa','top','hard','mortar','pointed','straw','jester','bun',
-- 'none'), hatColor, band (hat band color), pose ('wave','down','up'),
-- buttons (color), extras(t) adds whatever the figure carries.
-- ---------------------------------------------------------------------
local function person(s)
    local t = {}
    local coat, trim, skin = s.coat, s.trim, s.skin or C.skin
    local legs = s.legs
    local boots = s.boots or C.black
    local a = { a = 255 }
    -- Legs or coat skirt, boots.
    if legs then
        cat(t, P(-0.09, 0, 0.17, 0.085, 0.09, 0.18, legs, a), P(0.09, 0, 0.17, 0.085, 0.09, 0.18, legs, a))
        cat(t, P(0, 0, 0.42, 0.21, 0.18, 0.24, coat, a))
        if trim then cat(t, opaque(0, 0, 0.2, 0.215, 0.185, 0.03, trim)) end
    else
        cat(t, P(0, 0, 0.36, 0.21, 0.18, 0.3, coat, a), P(0, 0, 0.1, 0.2, 0.17, 0.08, coat, a))
        if trim then cat(t, opaque(0, 0, 0.07, 0.205, 0.175, 0.035, trim)) end
    end
    cat(t, opaque(-0.09, 0.04, 0.04, 0.08, 0.13, 0.045, boots), opaque(0.09, 0.04, 0.04, 0.08, 0.13, 0.045, boots))
    -- Chest, front stripe, belt, buckle, buttons.
    cat(t, P(0, 0, 0.56, 0.2, 0.17, 0.12, coat, a))
    if trim and s.stripe ~= false then cat(t, opaque(0, 0.18, 0.45, 0.045, 0.012, 0.2, trim)) end
    if s.belt then
        cat(t, opaque(0, 0, 0.33, 0.215, 0.185, 0.03, s.belt))
        if s.buckle then cat(t, opaque(0, 0.19, 0.33, 0.035, 0.012, 0.035, s.buckle)) end
    end
    if s.buttons then
        for _, z in ipairs({ 0.52, 0.44 }) do cat(t, opaque(0, 0.19, z, 0.018, 0.01, 0.018, s.buttons)) end
    end
    -- Arms: built from joints so the segments overlap at the shoulder,
    -- the elbow and the wrist and nothing floats.
    local pose = s.pose or 'wave'
    local mitten = s.mitten or C.black
    local function limb(ax, ay, az, bx, by, bz, r, col)
        local dx, dy, dz = bx - ax, by - ay, bz - az
        local len = math.sqrt(dx * dx + dy * dy + dz * dz)
        local ux, uy, uz = dx / len, dy / len, dz / len
        local tilt = math.deg(math.acos(math.max(-1, math.min(1, uz))))
        local yaw = math.deg(math.atan(ux, -uy))
        cat(t, P((ax + bx) * 0.5, (ay + by) * 0.5, (az + bz) * 0.5, r, r, len * 0.5 + r * 0.6, col, { a = 255, rot = { tilt, 0, yaw } }))
    end
    local function arm(side, up)
        local sx = side
        local S = { sx * 0.19, 0.02, 0.57 }
        local E, W
        if up then E, W = { sx * 0.32, 0.06, 0.6 }, { sx * 0.36, 0.09, 0.82 }
        else E, W = { sx * 0.29, 0.08, 0.4 }, { sx * 0.3, 0.15, 0.24 } end
        limb(S[1], S[2], S[3], E[1], E[2], E[3], 0.06, coat)
        cat(t, sphere(E[1], E[2], E[3], 0.06, coat, a))
        limb(E[1], E[2], E[3], W[1], W[2], W[3], 0.055, coat)
        if trim then
            local dx, dy, dz = W[1] - E[1], W[2] - E[2], W[3] - E[3]
            local len = math.sqrt(dx * dx + dy * dy + dz * dz)
            local tilt = math.deg(math.acos(math.max(-1, math.min(1, dz / len))))
            local yaw = math.deg(math.atan(dx / len, -dy / len))
            cat(t, P(W[1], W[2], W[3], 0.068, 0.068, 0.03, trim, { a = 255, over = true, rot = { tilt, 0, yaw } }))
        end
        local mx, my, mz = W[1] + (W[1] - E[1]) * 0.25, W[2] + (W[2] - E[2]) * 0.25, W[3] + (W[3] - E[3]) * 0.25
        cat(t, sphere(mx, my, mz, 0.065, mitten, a))
    end
    arm(-1, pose == 'wave' or pose == 'up')
    arm(1, pose == 'up')
    -- Head and face.
    cat(t, sphere(0, 0.02, 0.76, 0.12, skin, a))
    cat(t, opaque(-0.07, 0.1, 0.73, 0.03, 0.02, 0.025, C.pink), opaque(0.07, 0.1, 0.73, 0.03, 0.02, 0.025, C.pink))   -- cheeks
    cat(t, opaque(-0.045, 0.115, 0.79, 0.024, 0.01, 0.028, C.white), opaque(0.045, 0.115, 0.79, 0.024, 0.01, 0.028, C.white))
    cat(t, opaque(-0.045, 0.125, 0.79, 0.012, 0.008, 0.015, C.black), opaque(0.045, 0.125, 0.79, 0.012, 0.008, 0.015, C.black))
    local brow = s.brows or (s.beard and C.white) or (s.hair or C.darkbrown)
    cat(t, opaque(-0.045, 0.118, 0.825, 0.03, 0.008, 0.01, brow), opaque(0.045, 0.118, 0.825, 0.03, 0.008, 0.01, brow))
    cat(t, opaque(0, 0.135, 0.76, 0.022, 0.018, 0.02, s.nose or C.pink))
    if s.beard then
        cat(t,
            P(0, 0.08, 0.67, 0.125, 0.085, 0.1, s.beard, a), P(0, 0.07, 0.6, 0.09, 0.07, 0.07, s.beard, a),
            P(-0.04, 0.125, 0.725, 0.04, 0.015, 0.014, s.beard, { a = 255, over = true, rot = { 0, 0, 20 } }),
            P(0.04, 0.125, 0.725, 0.04, 0.015, 0.014, s.beard, { a = 255, over = true, rot = { 0, 0, -20 } }))
    else
        cat(t, opaque(0, 0.125, 0.715, 0.04, 0.01, 0.01, C.red))
    end
    if s.hair then cat(t, P(0, -0.03, 0.82, 0.13, 0.12, 0.08, s.hair, a)) end
    -- Hats.
    local hat, hc, band = s.hat or 'none', s.hatColor or C.red, s.band
    if hat == 'santa' then
        cat(t, P(0, 0, 0.86, 0.135, 0.135, 0.035, trim or C.white, { a = 255, over = true }), P(0, 0, 0.9, 0.12, 0.12, 0.07, hc, a),
            P(0.02, 0, 0.96, 0.1, 0.1, 0.06, hc, a), P(0.055, -0.01, 1.01, 0.075, 0.075, 0.05, hc, a),
            P(0.1, -0.02, 1.05, 0.05, 0.05, 0.04, hc, a), sphere(0.14, -0.03, 1.07, 0.045, trim or C.white, a))
    elseif hat == 'top' then
        cat(t, opaque(0, 0, 0.86, 0.19, 0.19, 0.02, hc), P(0, 0, 0.97, 0.12, 0.12, 0.11, hc, a))
        if band then cat(t, opaque(0, 0, 0.89, 0.125, 0.125, 0.02, band), opaque(0, 0.12, 0.89, 0.035, 0.012, 0.035, s.buckle or C.gold)) end
    elseif hat == 'hard' then
        cat(t, P(0, 0, 0.86, 0.14, 0.13, 0.08, hc, a), opaque(0, 0.1, 0.83, 0.12, 0.07, 0.015, hc))
    elseif hat == 'mortar' then
        cat(t, P(0, 0, 0.85, 0.12, 0.12, 0.05, hc, a), opaque(0, 0, 0.9, 0.2, 0.2, 0.012, hc),
            P(0.15, 0.08, 0.84, 0.01, 0.01, 0.06, C.gold, a), sphere(0.15, 0.08, 0.78, 0.022, C.gold, a))
    elseif hat == 'pointed' then
        cat(t, opaque(0, 0, 0.86, 0.22, 0.22, 0.02, hc), P(0, 0, 0.93, 0.12, 0.12, 0.08, hc, a), P(0.03, 0, 1.02, 0.08, 0.08, 0.07, hc, a), P(0.09, 0, 1.11, 0.045, 0.045, 0.06, hc, a))
        if band then cat(t, opaque(0, 0, 0.88, 0.125, 0.125, 0.018, band)) end
    elseif hat == 'straw' then
        cat(t, opaque(0, 0, 0.86, 0.22, 0.22, 0.02, hc), P(0, 0, 0.92, 0.12, 0.12, 0.07, hc, a))
        if band then cat(t, opaque(0, 0, 0.88, 0.125, 0.125, 0.018, band)) end
    elseif hat == 'jester' then
        cat(t, P(0, 0, 0.86, 0.14, 0.13, 0.07, hc, a),
            P(-0.2, 0, 0.95, 0.12, 0.05, 0.05, C.green, { a = 255, rot = { 0, 40, 0 } }), sphere(-0.3, 0, 1.03, 0.04, C.gold, a),
            P(0.2, 0, 0.95, 0.12, 0.05, 0.05, C.gold, { a = 255, rot = { 0, -40, 0 } }), sphere(0.3, 0, 1.03, 0.04, C.gold, a),
            P(0, 0, 1.0, 0.05, 0.05, 0.12, hc, a), sphere(0, 0, 1.13, 0.04, C.gold, a))
    elseif hat == 'bun' then
        cat(t, sphere(0, -0.1, 0.9, 0.07, s.hair or C.gray, a))
    end
    if s.extras then s.extras(t) end
    return norm(t)
end

local function santa()
    return person({ coat = C.red, trim = C.white, belt = C.black, buckle = C.gold, mitten = C.black, beard = C.white, hat = 'santa', pose = 'wave' })
end

local function mrsClaus()
    return person({ coat = C.red, trim = C.white, belt = nil, mitten = C.skin, hair = C.gray, hat = 'bun', pose = 'down', stripe = false,
        extras = function(t)
            cat(t, P(0, 0.17, 0.3, 0.14, 0.02, 0.17, C.white, { a = 255 }),                        -- apron
                opaque(-0.045, 0.14, 0.79, 0.036, 0.008, 0.036, C.gold), opaque(0.045, 0.14, 0.79, 0.036, 0.008, 0.036, C.gold),   -- glasses
                P(0.42, 0.14, 0.2, 0.07, 0.07, 0.02, C.tan, { a = 255 }))                            -- a plate of cookies
        end })
end

local function nutcracker()
    return person({ coat = C.red, trim = nil, legs = C.blue, belt = C.black, buckle = C.gold, mitten = C.white, beard = C.white, hair = C.black,
        hat = 'top', hatColor = C.black, band = C.gold, pose = 'down', buttons = C.gold,
        extras = function(t)
            cat(t, P(0, 0.18, 0.5, 0.06, 0.02, 0.16, C.gold, { a = 255 }), sphere(0, 0, 1.12, 0.045, C.red, { a = 255 }))   -- braid, plume
        end })
end

local function leprechaun()
    return person({ coat = C.green, trim = nil, legs = C.green, belt = C.black, buckle = C.gold, mitten = C.skin, beard = C.orange, hair = C.orange,
        hat = 'top', hatColor = C.green, band = C.black, pose = 'wave', buttons = C.gold,
        extras = function(t)
            cat(t, P(0.46, 0.12, 0.12, 0.13, 0.13, 0.11, C.black, { a = 255 }), P(0.46, 0.12, 0.23, 0.11, 0.11, 0.045, C.gold, { a = 255 }))   -- pot of gold
        end })
end

local function pilgrim()
    return person({ coat = C.black, trim = nil, legs = C.black, belt = C.black, buckle = C.gold, mitten = C.skin, hair = C.brown,
        hat = 'top', hatColor = C.black, band = C.darkbrown, pose = 'down', buttons = C.gold,
        extras = function(t) cat(t, P(0, 0.16, 0.62, 0.15, 0.04, 0.05, C.white, { a = 255 })) end })   -- the collar
end

local function worker()
    return person({ coat = C.orange, trim = C.silver, legs = C.navy, belt = C.brown, buckle = C.silver, mitten = C.skin, hair = C.darkbrown,
        hat = 'hard', hatColor = C.yellow, pose = 'down', stripe = false,
        extras = function(t)
            cat(t, P(0, 0.19, 0.42, 0.16, 0.02, 0.03, C.silver, { a = 255 }), P(0, 0.19, 0.52, 0.16, 0.02, 0.03, C.silver, { a = 255 }),
                P(0.4, 0.14, 0.4, 0.018, 0.018, 0.3, C.darkbrown, { a = 255 }), P(0.4, 0.14, 0.08, 0.07, 0.02, 0.08, C.silver, { a = 255 }))   -- shovel
        end })
end

local function graduate()
    return person({ coat = C.black, trim = nil, mitten = C.skin, hair = C.darkbrown, hat = 'mortar', hatColor = C.black, pose = 'wave', stripe = false,
        extras = function(t)
            cat(t, P(0, 0.17, 0.46, 0.05, 0.02, 0.2, C.gold, { a = 255 }),                                   -- stole
                P(-0.37, 0.08, 0.98, 0.035, 0.035, 0.09, C.white, { a = 255, rot = { 0, -30, 0 } }), opaque(-0.37, 0.11, 0.98, 0.04, 0.012, 0.012, C.red))   -- diploma
        end })
end

local function jester()
    return person({ coat = C.purple, trim = C.gold, legs = C.green, mitten = C.gold, hair = C.black, hat = 'jester', hatColor = C.purple, pose = 'up',
        extras = function(t)
            cat(t, P(0, 0, 0.62, 0.21, 0.18, 0.045, C.gold, { a = 255 }), P(0.1, 0, 0.42, 0.11, 0.17, 0.22, C.green, { a = 255 }),   -- collar, motley
                opaque(-0.045, 0.13, 0.79, 0.04, 0.008, 0.028, C.black))                                   -- the mask
        end })
end

local function scarecrow()
    return person({ coat = C.blue, trim = nil, legs = C.brown, belt = C.darkbrown, mitten = C.straw, skin = C.straw, hair = C.straw, nose = C.orange,
        hat = 'straw', hatColor = C.brown, band = C.red, pose = 'up', stripe = false,
        extras = function(t)
            cat(t, P(0, 0, 0.02, 0.025, 0.025, 0.3, C.darkbrown, { a = 255 }),                                 -- the post
                P(0, -0.1, 0.6, 0.5, 0.025, 0.025, C.darkbrown, { a = 255 }),                               -- the crossbar
                opaque(0.09, 0.17, 0.5, 0.06, 0.01, 0.05, C.red), opaque(-0.08, 0.17, 0.36, 0.05, 0.01, 0.04, C.yellow),   -- patches
                P(0, 0.1, 0.64, 0.1, 0.08, 0.035, C.straw, { a = 255 }))                                   -- straw at the neck
        end })
end

local function witch()
    return person({ coat = C.purple, trim = nil, mitten = C.lime, skin = C.lime, hair = C.black, nose = C.green, brows = C.black,
        hat = 'pointed', hatColor = C.black, band = C.orange, pose = 'wave', stripe = false,
        extras = function(t)
            cat(t, P(0, 0, 0.1, 0.3, 0.26, 0.09, C.purple, { a = 255 }),                                    -- the hem
                P(-0.12, -0.06, 0.66, 0.07, 0.09, 0.18, C.black, { a = 255 }), P(0.12, -0.06, 0.66, 0.07, 0.09, 0.18, C.black, { a = 255 }),   -- hair
                P(0.44, 0.12, 0.5, 0.02, 0.02, 0.5, C.brown, { a = 255 }), P(0.44, 0.12, 0.1, 0.09, 0.07, 0.13, C.straw, { a = 255 }))   -- broom
        end })
end

local function turkey()
    local t = {}
    cat(t,
        P(0, 0, 0.42, 0.33, 0.36, 0.31, C.brown),               -- body
        P(0, 0.2, 0.40, 0.23, 0.18, 0.22, C.tan),               -- chest
        P(-0.3, 0, 0.44, 0.11, 0.2, 0.15, C.darkbrown),         -- wings
        P(0.3, 0, 0.44, 0.11, 0.2, 0.15, C.darkbrown),
        P(0, 0.3, 0.63, 0.11, 0.11, 0.16, C.brown),             -- neck
        sphere(0, 0.36, 0.80, 0.13, C.brown),                   -- head
        opaque(0, 0.50, 0.80, 0.045, 0.085, 0.04, C.orange),    -- beak
        opaque(0, 0.47, 0.71, 0.04, 0.05, 0.08, C.red),         -- wattle
        eyes(0.46, 0.84, 0.065, 0.028),
        opaque(-0.11, 0.14, 0.05, 0.06, 0.11, 0.035, C.orange), -- feet
        opaque(0.11, 0.14, 0.05, 0.06, 0.11, 0.035, C.orange)
    )
    -- The tail: seven feathers fanned behind the body.
    local cols = { C.rust, C.orange, C.yellow, C.darkred, C.yellow, C.orange, C.rust }
    for i = 1, 7 do
        local a = math.rad(-75 + (i - 1) * 25)
        t[#t + 1] = P(math.sin(a) * 0.4, -0.3, 0.5 + math.cos(a) * 0.36, 0.1, 0.04, 0.24, cols[i], { rot = { 0, -math.deg(a), 0 } })
    end
    return norm(t)
end

local function snowman()
    local t = {}
    cat(t,
        sphere(0, 0, 0.27, 0.28, C.snow), sphere(0, 0, 0.64, 0.21, C.snow), sphere(0, 0, 0.92, 0.15, C.snow),
        opaque(0, 0, 1.03, 0.17, 0.17, 0.02, C.black),          -- hat brim
        opaque(0, 0, 1.11, 0.11, 0.11, 0.08, C.black),          -- hat crown
        opaque(0, 0, 1.05, 0.115, 0.115, 0.015, C.red),         -- hat band
        opaque(0, 0.14, 0.92, 0.03, 0.09, 0.03, C.orange),      -- carrot
        eyes(0.12, 0.96, 0.055, 0.025),
        opaque(0, 0.2, 0.70, 0.022, 0.022, 0.022, C.black), opaque(0, 0.21, 0.63, 0.022, 0.022, 0.022, C.black), opaque(0, 0.2, 0.56, 0.022, 0.022, 0.022, C.black),
        P(0, 0, 0.79, 0.2, 0.2, 0.035, C.red),                  -- scarf
        P(0.1, 0.15, 0.70, 0.05, 0.04, 0.1, C.red),             -- scarf tail
        P(-0.33, 0, 0.7, 0.18, 0.02, 0.02, C.darkbrown, { a = 255, rot = { 0, 30, 0 } }),   -- stick arms
        P(0.33, 0, 0.7, 0.18, 0.02, 0.02, C.darkbrown, { a = 255, rot = { 0, -30, 0 } })
    )
    -- Smile: five little coals.
    for i = -2, 2 do
        t[#t + 1] = opaque(i * 0.035, 0.135, 0.875 - math.abs(i) * 0.012, 0.014, 0.014, 0.014, C.black)
    end
    return norm(t)
end


local function reindeer()
    local t = {}
    cat(t,
        P(0, 0, 0.55, 0.2, 0.36, 0.21, C.brown),                 -- body
        P(0, 0.3, 0.72, 0.11, 0.11, 0.19, C.brown, { rot = { -25, 0, 0 } }),   -- neck
        P(0, 0.44, 0.88, 0.11, 0.16, 0.1, C.brown),               -- head
        opaque(0, 0.6, 0.86, 0.055, 0.055, 0.055, C.red),         -- the nose
        eyes(0.52, 0.94, 0.06, 0.025),
        P(-0.1, 0.4, 0.98, 0.045, 0.03, 0.06, C.tan, { rot = { 0, 30, 0 } }),  -- ears
        P(0.1, 0.4, 0.98, 0.045, 0.03, 0.06, C.tan, { rot = { 0, -30, 0 } }),
        P(-0.08, 0.38, 1.1, 0.02, 0.02, 0.16, C.tan, { a = 255, rot = { 0, 15, 0 } }),   -- antlers
        P(0.08, 0.38, 1.1, 0.02, 0.02, 0.16, C.tan, { a = 255, rot = { 0, -15, 0 } }),
        P(-0.17, 0.38, 1.16, 0.1, 0.02, 0.02, C.tan, { a = 255, rot = { 0, 40, 0 } }),
        P(0.17, 0.38, 1.16, 0.1, 0.02, 0.02, C.tan, { a = 255, rot = { 0, -40, 0 } }),
        P(-0.12, 0.38, 1.24, 0.02, 0.02, 0.07, C.tan, { a = 255 }),
        P(0.12, 0.38, 1.24, 0.02, 0.02, 0.07, C.tan, { a = 255 }),
        P(0, -0.36, 0.62, 0.04, 0.05, 0.08, C.tan),               -- tail
        P(0, 0.12, 0.45, 0.14, 0.28, 0.12, C.tan)                 -- belly
    )
    for _, x in ipairs({ -0.11, 0.11 }) do
        for _, y in ipairs({ -0.22, 0.2 }) do
            t[#t + 1] = P(x, y, 0.2, 0.055, 0.06, 0.2, C.brown)
            t[#t + 1] = opaque(x, y, 0.03, 0.06, 0.065, 0.03, C.black)
        end
    end
    -- A red collar with a bell.
    t[#t + 1] = P(0, 0.3, 0.62, 0.12, 0.12, 0.03, C.red)
    t[#t + 1] = opaque(0, 0.42, 0.6, 0.035, 0.035, 0.035, C.gold)
    return norm(t)
end

local function penguin()
    local t = {}
    cat(t,
        P(0, 0, 0.45, 0.28, 0.26, 0.42, C.black),
        P(0, 0.13, 0.4, 0.19, 0.16, 0.31, C.white),
        P(0, 0, 0.87, 0.19, 0.18, 0.17, C.black),
        P(0, 0.11, 0.86, 0.12, 0.09, 0.1, C.white),
        opaque(0, 0.2, 0.84, 0.04, 0.08, 0.03, C.orange),
        eyes(0.17, 0.9, 0.055, 0.03, C.white),
        opaque(-0.055, 0.195, 0.9, 0.016, 0.014, 0.016, C.black), opaque(0.055, 0.195, 0.9, 0.016, 0.014, 0.016, C.black),
        P(-0.3, 0, 0.5, 0.05, 0.1, 0.22, C.black, { rot = { 0, 20, 0 } }),
        P(0.3, 0, 0.5, 0.05, 0.1, 0.22, C.black, { rot = { 0, -20, 0 } }),
        opaque(-0.09, 0.14, 0.035, 0.08, 0.13, 0.03, C.orange),
        opaque(0.09, 0.14, 0.035, 0.08, 0.13, 0.03, C.orange),
        P(0, 0, 0.71, 0.21, 0.19, 0.035, C.red),                  -- scarf
        P(0.12, 0.16, 0.62, 0.05, 0.04, 0.09, C.red),
        P(0, 0, 1.0, 0.13, 0.13, 0.035, C.white),                 -- santa hat
        P(0, 0, 1.06, 0.1, 0.1, 0.07, C.red),
        P(0.08, 0, 1.13, 0.06, 0.06, 0.05, C.red),
        sphere(0.15, 0, 1.16, 0.04, C.white)
    )
    return norm(t)
end

local function candyCane()
    local t = {}
    for i = 0, 11 do
        t[#t + 1] = sphere(0, 0, 0.09 + i * 0.075, 0.085, (i % 2 == 0) and C.red or C.white)
    end
    for i = 0, 8 do
        local a = math.pi - i * math.pi / 8
        t[#t + 1] = sphere(0.19 + math.cos(a) * 0.19, 0, 0.915 + math.sin(a) * 0.19, 0.085, (i % 2 == 0) and C.red or C.white)
    end
    return norm(t)
end

local function pumpkin(face)
    local t = {}
    t[#t + 1] = P(0, 0, 0.42, 0.44, 0.42, 0.38, C.pumpkin)
    for i = 0, 5 do
        local a = i * math.pi / 3
        t[#t + 1] = P(math.sin(a) * 0.17, math.cos(a) * 0.16, 0.4, 0.31, 0.3, 0.37, C.pumpkin)
    end
    cat(t,
        P(0, 0, 0.84, 0.06, 0.06, 0.1, C.darkgreen, { a = 255 }),
        P(0.1, 0.04, 0.84, 0.09, 0.05, 0.02, C.green, { a = 255, rot = { 0, -20, 0 } })
    )
    if face then
        cat(t,
            opaque(-0.15, 0.41, 0.52, 0.08, 0.04, 0.08, C.black),
            opaque(0.15, 0.41, 0.52, 0.08, 0.04, 0.08, C.black),
            opaque(0, 0.43, 0.41, 0.045, 0.03, 0.05, C.black),
            opaque(0, 0.4, 0.27, 0.24, 0.035, 0.06, C.black),
            opaque(-0.2, 0.41, 0.31, 0.06, 0.03, 0.05, C.black),
            opaque(0.2, 0.41, 0.31, 0.06, 0.03, 0.05, C.black),
            opaque(-0.06, 0.45, 0.3, 0.025, 0.02, 0.03, C.pumpkin),   -- teeth
            opaque(0.08, 0.45, 0.24, 0.025, 0.02, 0.03, C.pumpkin)
        )
    end
    return norm(t)
end

local function ghost()
    local t = {}
    cat(t,
        P(0, 0, 0.55, 0.28, 0.26, 0.38, C.snow),
        sphere(0, 0, 0.85, 0.21, C.snow),
        sphere(-0.17, 0, 0.18, 0.12, C.snow), sphere(0.17, 0, 0.18, 0.12, C.snow), sphere(0, 0.04, 0.14, 0.13, C.snow),
        P(-0.32, 0.06, 0.62, 0.13, 0.1, 0.11, C.snow, { rot = { 0, 20, 0 } }),
        P(0.32, 0.06, 0.62, 0.13, 0.1, 0.11, C.snow, { rot = { 0, -20, 0 } }),
        opaque(-0.075, 0.19, 0.9, 0.05, 0.03, 0.065, C.black),
        opaque(0.075, 0.19, 0.9, 0.05, 0.03, 0.065, C.black),
        opaque(0, 0.2, 0.76, 0.05, 0.03, 0.075, C.black)
    )
    return norm(t)
end

local function blackCat()
    local t = {}
    cat(t,
        P(0, -0.05, 0.42, 0.16, 0.3, 0.2, C.black),
        P(0, 0.05, 0.52, 0.14, 0.18, 0.17, C.black),              -- the arch
        sphere(0, 0.32, 0.6, 0.14, C.black),
        P(-0.09, 0.32, 0.74, 0.045, 0.03, 0.07, C.black), P(0.09, 0.32, 0.74, 0.045, 0.03, 0.07, C.black),
        opaque(-0.06, 0.44, 0.62, 0.03, 0.015, 0.035, C.lime), opaque(0.06, 0.44, 0.62, 0.03, 0.015, 0.035, C.lime),
        opaque(0, 0.455, 0.56, 0.02, 0.015, 0.015, C.pink),
        P(0, -0.34, 0.62, 0.04, 0.04, 0.25, C.black, { rot = { -20, 0, 0 } }),   -- tail up
        P(-0.08, 0.2, 0.14, 0.05, 0.05, 0.15, C.black), P(0.08, 0.2, 0.14, 0.05, 0.05, 0.15, C.black),
        P(-0.08, -0.22, 0.14, 0.05, 0.05, 0.15, C.black), P(0.08, -0.22, 0.14, 0.05, 0.05, 0.15, C.black),
        P(0, 0.32, 0.46, 0.09, 0.09, 0.025, C.orange)             -- collar
    )
    return norm(t)
end

local function spider()
    local t = {}
    cat(t,
        P(0, -0.05, 0.32, 0.3, 0.34, 0.24, C.black),
        P(0, 0.36, 0.3, 0.16, 0.15, 0.14, C.black),
        opaque(0, -0.08, 0.56, 0.1, 0.07, 0.03, C.red),           -- the mark
        opaque(-0.06, 0.49, 0.36, 0.03, 0.02, 0.03, C.red), opaque(0.06, 0.49, 0.36, 0.03, 0.02, 0.03, C.red),
        opaque(-0.1, 0.46, 0.3, 0.02, 0.015, 0.02, C.red), opaque(0.1, 0.46, 0.3, 0.02, 0.015, 0.02, C.red),
        opaque(-0.05, 0.5, 0.24, 0.025, 0.03, 0.05, C.white), opaque(0.05, 0.5, 0.24, 0.025, 0.03, 0.05, C.white)
    )
    for side = -1, 1, 2 do
        for i = 1, 4 do
            local y = 0.3 - (i - 1) * 0.2
            local spread = 15 + (i - 2.5) * 12 * side
            t[#t + 1] = P(side * 0.38, y, 0.44, 0.18, 0.04, 0.04, C.black, { rot = { 0, -side * 35, spread } })
            t[#t + 1] = P(side * 0.58, y + (i - 2.5) * 0.06, 0.24, 0.035, 0.035, 0.22, C.black, { rot = { 0, -side * 15, 0 } })
        end
    end
    return norm(t)
end

local function bat()
    local t = {}
    cat(t,
        P(0, 0, 0.5, 0.15, 0.13, 0.2, C.purple),
        sphere(0, 0.04, 0.74, 0.13, C.purple),
        P(-0.08, 0.04, 0.88, 0.05, 0.03, 0.07, C.purple), P(0.08, 0.04, 0.88, 0.05, 0.03, 0.07, C.purple),
        opaque(-0.05, 0.15, 0.76, 0.03, 0.015, 0.03, C.yellow), opaque(0.05, 0.15, 0.76, 0.03, 0.015, 0.03, C.yellow),
        opaque(-0.03, 0.16, 0.69, 0.012, 0.012, 0.025, C.white), opaque(0.03, 0.16, 0.69, 0.012, 0.012, 0.025, C.white),
        P(-0.14, 0, 0.3, 0.06, 0.05, 0.1, C.purple), P(0.14, 0, 0.3, 0.06, 0.05, 0.1, C.purple)
    )
    for side = -1, 1, 2 do
        t[#t + 1] = P(side * 0.28, -0.02, 0.6, 0.17, 0.04, 0.13, C.purple, { rot = { 0, -side * 25, 0 } })
        t[#t + 1] = P(side * 0.5, -0.02, 0.55, 0.13, 0.035, 0.1, C.purple, { rot = { 0, side * 10, 0 } })
        t[#t + 1] = P(side * 0.66, -0.02, 0.45, 0.08, 0.03, 0.08, C.purple, { rot = { 0, side * 30, 0 } })
    end
    return norm(t)
end


local function heart()
    local t = {}
    cat(t,
        P(-0.2, 0, 0.66, 0.26, 0.2, 0.26, C.red), P(0.2, 0, 0.66, 0.26, 0.2, 0.26, C.red),
        P(0, 0, 0.42, 0.37, 0.19, 0.32, C.red),
        P(0, 0, 0.16, 0.16, 0.12, 0.17, C.red),
        P(-0.1, 0.1, 0.74, 0.08, 0.05, 0.06, C.pink)              -- the shine
    )
    return norm(t)
end

local function loveBear()
    local t = {}
    cat(t,
        P(0, 0, 0.36, 0.26, 0.24, 0.3, C.tan),
        sphere(0, 0.04, 0.78, 0.2, C.tan),
        sphere(-0.16, 0, 0.94, 0.07, C.tan), sphere(0.16, 0, 0.94, 0.07, C.tan),
        sphere(-0.16, 0.03, 0.94, 0.04, C.pink), sphere(0.16, 0.03, 0.94, 0.04, C.pink),
        P(0, 0.19, 0.72, 0.09, 0.07, 0.07, C.cream),              -- muzzle
        opaque(0, 0.26, 0.75, 0.03, 0.02, 0.025, C.darkbrown),
        eyes(0.21, 0.83, 0.065, 0.025),
        P(-0.28, 0.1, 0.48, 0.08, 0.08, 0.15, C.tan, { rot = { 0, 30, 0 } }),
        P(0.28, 0.1, 0.48, 0.08, 0.08, 0.15, C.tan, { rot = { 0, -30, 0 } }),
        P(-0.14, 0.14, 0.1, 0.1, 0.13, 0.09, C.tan), P(0.14, 0.14, 0.1, 0.1, 0.13, 0.09, C.tan),
        P(-0.08, 0.3, 0.48, 0.1, 0.06, 0.1, C.red), P(0.08, 0.3, 0.48, 0.1, 0.06, 0.1, C.red),   -- the heart it holds
        P(0, 0.3, 0.38, 0.14, 0.06, 0.12, C.red),
        P(0, 0.3, 0.27, 0.06, 0.05, 0.07, C.red)
    )
    return norm(t)
end

local function shamrock()
    local t = {}
    for k = 0, 2 do
        local a = math.pi / 2 + k * 2 * math.pi / 3
        local cx, cz = math.cos(a) * 0.3, 0.6 + math.sin(a) * 0.3
        t[#t + 1] = P(cx, 0, cz, 0.26, 0.13, 0.26, C.green)
        t[#t + 1] = P(cx * 1.15 - 0.1, 0, cz + 0.04, 0.14, 0.12, 0.14, C.green)
        t[#t + 1] = P(cx * 1.15 + 0.1, 0, cz + 0.04, 0.14, 0.12, 0.14, C.green)
    end
    t[#t + 1] = P(0.08, 0, 0.2, 0.05, 0.05, 0.22, C.darkgreen, { rot = { 0, -15, 0 } })
    return norm(t)
end


local function bunny()
    local t = {}
    cat(t,
        P(0, 0, 0.34, 0.28, 0.3, 0.3, C.snow),
        sphere(0, 0.08, 0.7, 0.21, C.snow),
        P(-0.1, 0, 0.99, 0.06, 0.04, 0.2, C.snow, { rot = { 0, 12, 0 } }),
        P(0.1, 0, 0.99, 0.06, 0.04, 0.2, C.snow, { rot = { 0, -12, 0 } }),
        P(-0.1, 0.03, 0.99, 0.03, 0.02, 0.14, C.pink, { rot = { 0, 12, 0 } }),
        P(0.1, 0.03, 0.99, 0.03, 0.02, 0.14, C.pink, { rot = { 0, -12, 0 } }),
        opaque(0, 0.28, 0.7, 0.03, 0.02, 0.025, C.pink),
        eyes(0.25, 0.76, 0.07, 0.028),
        P(-0.08, 0.25, 0.65, 0.07, 0.05, 0.05, C.snow), P(0.08, 0.25, 0.65, 0.07, 0.05, 0.05, C.snow),
        sphere(0, -0.3, 0.3, 0.09, C.snow),                         -- tail
        P(-0.14, 0.2, 0.1, 0.1, 0.16, 0.08, C.snow), P(0.14, 0.2, 0.1, 0.1, 0.16, 0.08, C.snow),
        P(-0.26, 0.14, 0.44, 0.07, 0.07, 0.12, C.snow, { rot = { 0, 25, 0 } }),
        P(0.26, 0.14, 0.44, 0.07, 0.07, 0.12, C.snow, { rot = { 0, -25, 0 } }),
        P(0.3, 0.2, 0.3, 0.04, 0.04, 0.16, C.orange, { a = 255 }),    -- carrot
        P(0.3, 0.2, 0.48, 0.05, 0.03, 0.05, C.green, { a = 255 })
    )
    return norm(t)
end

local function easterEgg()
    local t = {}
    cat(t,
        P(0, 0, 0.5, 0.34, 0.34, 0.5, C.pastelyellow),
        P(0, 0, 0.64, 0.33, 0.33, 0.05, C.pink),
        P(0, 0, 0.44, 0.35, 0.35, 0.05, C.skyblue),
        P(0, 0, 0.3, 0.3, 0.3, 0.04, C.lime)
    )
    for i = 0, 7 do
        local a = i * math.pi / 4
        t[#t + 1] = sphere(math.sin(a) * 0.3, math.cos(a) * 0.3, 0.54, 0.05, (i % 2 == 0) and C.violet or C.hotpink)
        t[#t + 1] = sphere(math.sin(a + 0.4) * 0.25, math.cos(a + 0.4) * 0.25, 0.8, 0.04, C.skyblue)
    end
    return norm(t)
end

local function chick()
    local t = {}
    cat(t,
        P(0, 0, 0.36, 0.3, 0.3, 0.32, C.yellow),
        sphere(0, 0.06, 0.78, 0.22, C.yellow),
        opaque(0, 0.28, 0.76, 0.05, 0.08, 0.035, C.orange),
        eyes(0.24, 0.84, 0.07, 0.03),
        P(-0.3, 0, 0.42, 0.07, 0.14, 0.17, C.yellow, { rot = { 0, 20, 0 } }),
        P(0.3, 0, 0.42, 0.07, 0.14, 0.17, C.yellow, { rot = { 0, -20, 0 } }),
        opaque(-0.1, 0.1, 0.03, 0.07, 0.13, 0.03, C.orange), opaque(0.1, 0.1, 0.03, 0.07, 0.13, 0.03, C.orange),
        P(0, 0, 1.0, 0.05, 0.04, 0.05, C.yellow), P(0.07, 0, 0.97, 0.04, 0.03, 0.04, C.yellow),
        P(0, 0.02, 0.55, 0.14, 0.13, 0.06, C.pastelpink)             -- a bow
    )
    return norm(t)
end

local function unclesamHat()
    local t = {}
    t[#t + 1] = P(0, 0, 0.6, 0.31, 0.31, 0.4, C.white)
    for i = 0, 5 do
        local a = i * math.pi / 3
        t[#t + 1] = P(math.sin(a) * 0.27, math.cos(a) * 0.27, 0.62, 0.05, 0.05, 0.35, C.red)
    end
    t[#t + 1] = P(0, 0, 0.3, 0.325, 0.325, 0.09, C.blue)
    for i = 0, 7 do
        local a = i * math.pi / 4
        t[#t + 1] = opaque(math.sin(a) * 0.325, math.cos(a) * 0.325, 0.3, 0.035, 0.035, 0.035, C.white)
    end
    t[#t + 1] = opaque(0, 0, 0.14, 0.42, 0.42, 0.03, C.blue)
    return norm(t)
end

local function firecracker()
    local t = {}
    cat(t,
        P(0, 0, 0.45, 0.2, 0.2, 0.42, C.red),
        P(0, 0, 0.28, 0.21, 0.21, 0.05, C.white), P(0, 0, 0.62, 0.21, 0.21, 0.05, C.white),
        P(0, 0, 0.45, 0.21, 0.21, 0.07, C.blue),
        P(0, 0, 0.88, 0.2, 0.2, 0.04, C.navy),
        P(0.06, 0, 1.0, 0.02, 0.02, 0.1, C.tan, { a = 255, rot = { 0, -20, 0 } }),   -- fuse
        sphere(0.1, 0, 1.1, 0.045, C.yellow), sphere(0.13, 0.02, 1.16, 0.03, C.orange)   -- the spark
    )
    for i = 0, 4 do
        local a = i * 2 * math.pi / 5
        t[#t + 1] = opaque(math.sin(a) * 0.21, math.cos(a) * 0.21, 0.45, 0.03, 0.03, 0.03, C.white)
    end
    return norm(t)
end

local function menorah()
    local t = {}
    cat(t,
        P(0, 0, 0.06, 0.34, 0.14, 0.06, C.blue),
        P(0, 0, 0.3, 0.05, 0.05, 0.24, C.blue),
        P(0, 0, 0.48, 0.44, 0.045, 0.045, C.blue)
    )
    for i = -4, 4 do
        local x = i * 0.1
        local h = (i == 0) and 0.24 or 0.17
        local base = (i == 0) and 0.5 or 0.48
        t[#t + 1] = P(x, 0, base + h, 0.028, 0.028, h, (i % 2 == 0) and C.white or C.skyblue)
        t[#t + 1] = P(x, 0, base + h * 2 + 0.05, 0.03, 0.03, 0.05, C.yellow, { a = 255 })
        t[#t + 1] = P(x, 0, base + h * 2 + 0.09, 0.018, 0.018, 0.03, C.white, { a = 255 })
    end
    return norm(t)
end

local function dreidel()
    local t = {}
    cat(t,
        P(0, 0, 0.5, 0.24, 0.24, 0.24, C.blue),
        P(0, 0, 0.5, 0.2, 0.26, 0.2, C.blue),
        P(0, 0, 0.5, 0.26, 0.2, 0.2, C.blue),
        P(0, 0, 0.22, 0.12, 0.12, 0.14, C.blue),
        P(0, 0, 0.06, 0.04, 0.04, 0.06, C.white, { a = 255 }),
        P(0, 0, 0.86, 0.045, 0.045, 0.14, C.white, { a = 255 }),
        opaque(0, 0.26, 0.5, 0.09, 0.02, 0.09, C.white),
        opaque(0, 0.27, 0.5, 0.05, 0.015, 0.05, C.blue)
    )
    return norm(t)
end

local function goldStar()
    local t = {}
    t[#t + 1] = sphere(0, 0, 0.5, 0.14, C.gold)
    for i = 0, 4 do
        local a = math.pi / 2 + i * 2 * math.pi / 5
        t[#t + 1] = P(math.cos(a) * 0.26, 0, 0.5 + math.sin(a) * 0.26, 0.065, 0.08, 0.3, C.gold, { rot = { 0, 90 - math.deg(a), 0 } })
    end
    t[#t + 1] = P(0, 0, 0.1, 0.08, 0.08, 0.1, C.gold)
    return norm(t)
end

local function champagne()
    local t = {}
    cat(t,
        P(0, 0, 0.36, 0.18, 0.18, 0.34, C.darkgreen),
        P(0, 0, 0.1, 0.18, 0.18, 0.08, C.darkgreen),
        P(0, 0, 0.72, 0.1, 0.1, 0.12, C.darkgreen),
        P(0, 0, 0.84, 0.07, 0.07, 0.08, C.gold),
        P(0, 0, 0.93, 0.08, 0.08, 0.04, C.gold),
        opaque(0, 0.17, 0.42, 0.11, 0.02, 0.14, C.cream),          -- the label
        sphere(0.1, 0, 1.06, 0.05, C.tan),                          -- cork, on its way
        sphere(0.2, 0.02, 1.16, 0.035, C.white), sphere(-0.12, 0.04, 1.1, 0.03, C.white), sphere(0.02, -0.03, 1.2, 0.025, C.white)
    )
    return norm(t)
end

local function cake()
    local t = {}
    cat(t,
        P(0, 0, 0.14, 0.4, 0.4, 0.14, C.pink), P(0, 0, 0.27, 0.41, 0.41, 0.03, C.white),
        P(0, 0, 0.4, 0.3, 0.3, 0.12, C.pink), P(0, 0, 0.51, 0.31, 0.31, 0.03, C.white),
        P(0, 0, 0.62, 0.2, 0.2, 0.1, C.pink), P(0, 0, 0.71, 0.21, 0.21, 0.03, C.white)
    )
    for i = 0, 4 do
        local a = i * 2 * math.pi / 5
        local x, y = math.sin(a) * 0.11, math.cos(a) * 0.11
        t[#t + 1] = P(x, y, 0.82, 0.02, 0.02, 0.09, (i % 2 == 0) and C.blue or C.red, { a = 255 })
        t[#t + 1] = P(x, y, 0.94, 0.025, 0.025, 0.04, C.yellow, { a = 255 })
    end
    for i = 0, 9 do
        local a = i * math.pi / 5
        t[#t + 1] = sphere(math.sin(a) * 0.4, math.cos(a) * 0.4, 0.27, 0.035, (i % 2 == 0) and C.red or C.skyblue)
    end
    return norm(t)
end

local function tree()
    local t = {}
    cat(t,
        P(0, 0, 0.07, 0.08, 0.08, 0.08, C.darkbrown, { a = 255 }),
        P(0, 0, 0.26, 0.4, 0.4, 0.24, C.pine), P(0, 0, 0.48, 0.32, 0.32, 0.2, C.pine),
        P(0, 0, 0.67, 0.24, 0.24, 0.17, C.pine), P(0, 0, 0.83, 0.15, 0.15, 0.13, C.pine),
        sphere(0, 0, 0.99, 0.07, C.gold)
    )
    local cols = { C.red, C.blue, C.gold, C.hotpink, C.white }
    for i = 0, 11 do
        local a = i * 2.1
        local z = 0.18 + (i / 11) * 0.72
        local r = 0.42 - z * 0.33
        t[#t + 1] = sphere(math.sin(a) * r, math.cos(a) * r, z, 0.045, cols[i % 5 + 1], { a = 255 })
    end
    return norm(t)
end

local function gingerbread()
    local t = {}
    cat(t,
        sphere(0, 0, 0.8, 0.17, C.tan),
        P(0, 0, 0.45, 0.2, 0.11, 0.26, C.tan),
        P(-0.3, 0, 0.56, 0.14, 0.09, 0.08, C.tan, { rot = { 0, -25, 0 } }),
        P(0.3, 0, 0.56, 0.14, 0.09, 0.08, C.tan, { rot = { 0, 25, 0 } }),
        P(-0.12, 0, 0.14, 0.09, 0.09, 0.16, C.tan, { rot = { 0, 10, 0 } }),
        P(0.12, 0, 0.14, 0.09, 0.09, 0.16, C.tan, { rot = { 0, -10, 0 } }),
        opaque(-0.4, 0.02, 0.6, 0.045, 0.07, 0.04, C.white), opaque(0.4, 0.02, 0.6, 0.045, 0.07, 0.04, C.white),
        opaque(-0.15, 0.02, 0.04, 0.08, 0.08, 0.03, C.white), opaque(0.15, 0.02, 0.04, 0.08, 0.08, 0.03, C.white),
        eyes(0.16, 0.84, 0.06, 0.025),
        opaque(0, 0.11, 0.58, 0.035, 0.035, 0.035, C.red),
        opaque(0, 0.11, 0.47, 0.035, 0.035, 0.035, C.green),
        opaque(0, 0.11, 0.36, 0.035, 0.035, 0.035, C.red)
    )
    for i = -2, 2 do
        t[#t + 1] = opaque(i * 0.035, 0.165, 0.745 - math.abs(i) * 0.012, 0.014, 0.014, 0.014, C.white)
    end
    return norm(t)
end

local function polarBear()
    local t = {}
    cat(t,
        P(0, 0, 0.38, 0.3, 0.36, 0.32, C.snow),
        sphere(0, 0.28, 0.72, 0.17, C.snow),
        sphere(-0.12, 0.22, 0.86, 0.05, C.snow), sphere(0.12, 0.22, 0.86, 0.05, C.snow),
        P(0, 0.42, 0.68, 0.08, 0.07, 0.06, C.cream),
        opaque(0, 0.49, 0.7, 0.03, 0.02, 0.025, C.black),
        eyes(0.42, 0.77, 0.06, 0.022),
        P(0, 0.26, 0.56, 0.14, 0.14, 0.03, C.red),
        P(0.13, 0.36, 0.48, 0.05, 0.04, 0.08, C.red),
        P(-0.2, 0.2, 0.12, 0.1, 0.14, 0.12, C.snow), P(0.2, 0.2, 0.12, 0.1, 0.14, 0.12, C.snow),
        P(-0.2, -0.22, 0.12, 0.1, 0.14, 0.12, C.snow), P(0.2, -0.22, 0.12, 0.1, 0.14, 0.12, C.snow)
    )
    return norm(t)
end


local function acorn()
    local t = {}
    cat(t,
        P(0, 0, 0.42, 0.32, 0.32, 0.4, C.tan),
        P(0, 0, 0.75, 0.36, 0.36, 0.16, C.darkbrown),
        P(0, 0, 0.9, 0.2, 0.2, 0.08, C.darkbrown),
        P(0, 0, 1.0, 0.04, 0.04, 0.08, C.darkbrown, { a = 255 })
    )
    for i = 0, 9 do
        local a = i * math.pi / 5
        t[#t + 1] = sphere(math.sin(a) * 0.32, math.cos(a) * 0.32, 0.72, 0.07, C.brown)
    end
    return norm(t)
end

local function discoBall()
    local t = {}
    t[#t + 1] = P(0, 0, 0.5, 0.36, 0.36, 0.36, C.silver)
    t[#t + 1] = P(0, 0, 0.1, 0.14, 0.14, 0.1, C.gray, { a = 255 })
    t[#t + 1] = P(0, 0, 0.3, 0.05, 0.05, 0.1, C.gray, { a = 255 })
    for i = 0, 15 do
        local a = i * math.pi / 8
        local z = 0.5 + math.sin(i * 1.7) * 0.22
        local r = math.sqrt(math.max(0.02, 0.36 * 0.36 - (z - 0.5) * (z - 0.5)))
        t[#t + 1] = sphere(math.sin(a) * r, math.cos(a) * r, z, 0.05, (i % 3 == 0) and C.white or (i % 3 == 1) and C.skyblue or C.hotpink, { a = 255 })
    end
    return norm(t)
end

-- ---------------------------------------------------------------------
-- Arches: two pillars and a half circle over a walkway. Wide enough to
-- walk through at the default height. `arch = true` on the entry makes
-- the placer's alignment run the row ALONG the path, so three clicks
-- line them up over a sidewalk.
-- ---------------------------------------------------------------------
local function archFrame(t, colorAt, r, o)
    o = o or {}
    local px, top = o.px or 0.42, o.top or 0.55
    local i = 0
    for _, side in ipairs({ -1, 1 }) do
        local n = 7
        for k = 0, n do
            local z = 0.04 + (top / n) * k
            t[#t + 1] = sphere(side * px, 0, z, r, colorAt(i), { a = o.a })
            i = i + 1
        end
    end
    local n = 12
    for k = 0, n do
        local a = math.pi - k * math.pi / n
        t[#t + 1] = sphere(math.cos(a) * px, 0, top + math.sin(a) * px, r, colorAt(i), { a = o.a })
        i = i + 1
    end
    return t
end

local function candyArch()
    return norm(archFrame({}, function(i) return (i % 2 == 0) and C.red or C.white end, 0.075))
end

local function topHatArch()
    local t = archFrame({}, function(i) return (i % 2 == 0) and C.red or C.white end, 0.07)
    cat(t,
        opaque(0, 0, 1.0, 0.24, 0.24, 0.025, C.black),                 -- Frosty's hat on top
        P(0, 0, 1.1, 0.15, 0.15, 0.1, C.black, { a = 255 }),
        opaque(0, 0, 1.03, 0.155, 0.155, 0.02, C.red),
        sphere(-0.42, 0.08, 0.32, 0.09, C.white), sphere(0.42, 0.08, 0.32, 0.09, C.white)   -- snowballs on the posts
    )
    return norm(t)
end

local function holidaysArch()
    local t = archFrame({}, function(i) return (i % 5 == 0) and C.darkgreen or C.pine end, 0.08)
    for _, side in ipairs({ -1, 1 }) do
        cat(t,
            P(side * 0.42 - 0.07, 0.09, 0.5, 0.08, 0.04, 0.05, C.red, { a = 255, rot = { 0, 15, 0 } }),
            P(side * 0.42 + 0.07, 0.09, 0.5, 0.08, 0.04, 0.05, C.red, { a = 255, rot = { 0, -15, 0 } }),
            sphere(side * 0.42, 0.11, 0.5, 0.035, C.red, { a = 255 })
        )
    end
    for k = 0, 12 do
        local a = math.pi - k * math.pi / 12
        t[#t + 1] = sphere(math.cos(a) * 0.42, 0.09, 0.55 + math.sin(a) * 0.42, 0.025, (k % 2 == 0) and C.gold or C.white, { a = 255, lit = true })
    end
    return norm(t)
end

local function weddingArch()
    local t = archFrame({}, function() return C.white end, 0.06)
    local flowers = { C.pastelpink, C.white, C.pink, C.cream }
    for k = 0, 14 do
        local a = math.pi - k * math.pi / 14
        local x, z = math.cos(a) * 0.42, 0.55 + math.sin(a) * 0.42
        t[#t + 1] = sphere(x, 0.07, z + 0.03, 0.045, flowers[k % 4 + 1], { a = 255 })
        if k % 3 == 1 then t[#t + 1] = P(x + 0.05, 0.06, z - 0.03, 0.05, 0.02, 0.025, C.green, { a = 255, rot = { 0, -30, 0 } }) end
    end
    for _, side in ipairs({ -1, 1 }) do
        for k = 0, 3 do
            t[#t + 1] = sphere(side * 0.42 + (k % 2) * 0.05 * side, 0.07, 0.12 + k * 0.1, 0.045, flowers[(k + 1) % 4 + 1], { a = 255 })
        end
    end
    return norm(t)
end

local function rainbowArch()
    local t = {}
    local bands = { C.red, C.orange, C.yellow, C.green, C.blue, C.violet }
    for b, col in ipairs(bands) do
        local r = 0.5 - (b - 1) * 0.06
        local n = 14
        for k = 0, n do
            local a = math.pi - k * math.pi / n
            t[#t + 1] = sphere(math.cos(a) * r, 0, 0.2 + math.sin(a) * r, 0.035, col)
        end
    end
    for _, side in ipairs({ -1, 1 }) do
        t[#t + 1] = P(side * 0.36, 0, 0.1, 0.13, 0.13, 0.1, C.black, { a = 255 })
        t[#t + 1] = P(side * 0.36, 0, 0.2, 0.11, 0.11, 0.04, C.gold, { a = 255 })
    end
    return norm(t)
end

local function fireworksArch()
    local t = archFrame({}, function(i) local k = i % 3 return (k == 0) and C.red or (k == 1) and C.white or C.blue end, 0.075)
    for k = 0, 6 do
        local a = math.pi - k * math.pi / 6
        t[#t + 1] = opaque(math.cos(a) * 0.42, 0.08, 0.55 + math.sin(a) * 0.42, 0.03, 0.02, 0.03, C.white)
    end
    return norm(t)
end

local function panAfricanArch()
    local t = archFrame({}, function(i) local k = (i // 3) % 3 return (k == 0) and C.red or (k == 1) and C.black or C.green end, 0.075)
    return norm(t)
end

local function balloonArch()
    local t = {}
    local cols = { C.red, C.yellow, C.blue, C.green, C.hotpink, C.orange, C.violet, C.skyblue }
    local i = 0
    local function at(x, z)
        for _, off in ipairs({ { 0, 0.0 }, { 0.05, 0.06 }, { -0.04, -0.05 } }) do
            t[#t + 1] = sphere(x + off[1], (i % 2) * 0.05 - 0.02, z + off[2], 0.055 + (i % 3) * 0.008, cols[i % #cols + 1])
            i = i + 1
        end
    end
    for _, side in ipairs({ -1, 1 }) do
        for k = 0, 6 do at(side * 0.42, 0.06 + k * 0.085) end
    end
    for k = 1, 11 do
        local a = math.pi - k * math.pi / 12
        at(math.cos(a) * 0.42, 0.55 + math.sin(a) * 0.42)
    end
    return norm(t)
end

local function litArch()
    local t = archFrame({}, function() return C.white end, 0.035, { a = 255 })
    for k = 0, 24 do
        local a = math.pi - k * math.pi / 24
        t[#t + 1] = sphere(math.cos(a) * 0.42, 0.05, 0.55 + math.sin(a) * 0.42, 0.022, { 255, 235, 190 }, { a = 255, lit = true })
    end
    for _, side in ipairs({ -1, 1 }) do
        for k = 0, 7 do t[#t + 1] = sphere(side * 0.42, 0.05, 0.05 + k * 0.07, 0.022, { 255, 235, 190 }, { a = 255, lit = true }) end
    end
    return norm(t)
end

-- ---------------------------------------------------------------------
-- More inflatables (0.3.0)
-- ---------------------------------------------------------------------

local function snowmanFamily()
    local t = {}
    local function one(x, s, scarf)
        cat(t,
            sphere(x, 0, 0.27 * s, 0.28 * s, C.snow), sphere(x, 0, 0.64 * s, 0.21 * s, C.snow), sphere(x, 0, 0.92 * s, 0.15 * s, C.snow),
            opaque(x, 0.14 * s, 0.92 * s, 0.03 * s, 0.09 * s, 0.03 * s, C.orange),
            opaque(x - 0.055 * s, 0.12 * s, 0.96 * s, 0.025 * s, 0.02 * s, 0.025 * s, C.black),
            opaque(x + 0.055 * s, 0.12 * s, 0.96 * s, 0.025 * s, 0.02 * s, 0.025 * s, C.black),
            P(x, 0, 0.79 * s, 0.2 * s, 0.2 * s, 0.035 * s, scarf),
            opaque(x, 0.2 * s, 0.64 * s, 0.022 * s, 0.022 * s, 0.022 * s, C.black)
        )
    end
    one(-0.42, 1.0, C.red)
    one(0.38, 0.8, C.green)
    one(0.0, 0.55, C.blue)
    cat(t,
        opaque(-0.42, 0, 1.03, 0.17, 0.17, 0.02, C.black), P(-0.42, 0, 1.11, 0.11, 0.11, 0.08, C.black, { a = 255 }),
        P(0.38, 0, 0.84, 0.13, 0.13, 0.03, C.red), P(0.38, 0, 0.9, 0.1, 0.1, 0.07, C.red), sphere(0.46, 0, 0.96, 0.04, C.white),
        P(0.0, 0, 0.56, 0.1, 0.1, 0.04, C.skyblue)                      -- earmuffs for the little one
    )
    return norm(t)
end


local function santaSleigh()
    local t = {}
    cat(t,
        P(0, 0, 0.3, 0.5, 0.26, 0.17, C.red),                            -- the sleigh body
        P(-0.5, 0, 0.45, 0.1, 0.22, 0.2, C.red),                          -- the curl at the front
        sphere(-0.55, 0, 0.66, 0.08, C.gold),
        P(0.45, 0, 0.42, 0.08, 0.22, 0.14, C.red),
        P(0, 0, 0.1, 0.58, 0.03, 0.03, C.gold, { a = 255 }),              -- runners
        P(0, -0.2, 0.1, 0.58, 0.03, 0.03, C.gold, { a = 255 }), P(0, 0.2, 0.1, 0.58, 0.03, 0.03, C.gold, { a = 255 }),
        P(0.05, 0, 0.56, 0.2, 0.17, 0.2, C.red),                          -- Santa, seated
        opaque(0.05, 0, 0.55, 0.205, 0.175, 0.03, C.black),
        sphere(0.05, 0.02, 0.84, 0.13, C.skin), P(0.05, 0.1, 0.76, 0.12, 0.08, 0.1, C.white),
        P(0.05, 0, 0.96, 0.12, 0.12, 0.07, C.red), sphere(0.16, 0, 1.03, 0.045, C.white),
        eyes(0.13, 0.88, 0.05, 0.02),
        P(0.35, 0, 0.6, 0.18, 0.16, 0.2, C.darkgreen),                    -- the sack
        sphere(0.35, 0.06, 0.78, 0.07, C.blue), sphere(0.42, -0.04, 0.8, 0.06, C.gold), sphere(0.28, 0, 0.82, 0.05, C.red)
    )
    return norm(t)
end

local function gingerbreadHouse()
    local t = {}
    cat(t,
        P(0, 0, 0.32, 0.42, 0.34, 0.32, C.tan),                            -- walls
        P(0, 0, 0.68, 0.46, 0.38, 0.14, C.white),                          -- icing roof
        P(0, 0, 0.8, 0.3, 0.3, 0.12, C.white),
        P(0, 0, 0.9, 0.12, 0.12, 0.08, C.white),
        P(0, 0.34, 0.22, 0.1, 0.03, 0.14, C.darkbrown, { a = 255 }),       -- door
        opaque(-0.22, 0.34, 0.4, 0.07, 0.02, 0.07, C.skyblue), opaque(0.22, 0.34, 0.4, 0.07, 0.02, 0.07, C.skyblue),   -- windows
        P(0.25, 0.1, 0.98, 0.06, 0.06, 0.1, C.tan),                        -- chimney
        sphere(0.25, 0.1, 1.08, 0.07, C.white)
    )
    local gum = { C.red, C.green, C.hotpink, C.yellow, C.blue }
    for i = 0, 9 do
        local a = i * 0.63
        t[#t + 1] = sphere(math.cos(a) * 0.4, math.sin(a) * 0.32, 0.66 + (i % 2) * 0.1, 0.045, gum[i % 5 + 1], { a = 255 })
    end
    for i = -2, 2 do t[#t + 1] = sphere(i * 0.15, 0.36, 0.58, 0.035, gum[(i + 2) % 5 + 1], { a = 255 }) end
    return norm(t)
end

local function snowGlobe()
    local t = {}
    cat(t,
        P(0, 0, 0.12, 0.42, 0.42, 0.12, C.red),                            -- base
        P(0, 0, 0.2, 0.36, 0.36, 0.04, C.gold),
        P(0, 0, 0.3, 0.3, 0.3, 0.06, C.white),                             -- snow inside
        P(0, 0, 0.42, 0.14, 0.12, 0.14, C.tan), P(0, 0, 0.56, 0.17, 0.15, 0.06, C.red),   -- the little house
        P(0, 0.12, 0.38, 0.03, 0.02, 0.05, C.darkbrown, { a = 255 }),
        P(0.22, -0.05, 0.42, 0.08, 0.08, 0.1, C.pine), P(0.22, -0.05, 0.52, 0.05, 0.05, 0.08, C.pine),
        P(-0.22, 0.05, 0.4, 0.07, 0.07, 0.09, C.pine),
        P(0, 0, 0.58, 0.38, 0.38, 0.38, { 200, 230, 255 }, { a = 70 })     -- the glass
    )
    for i = 0, 11 do
        local a = i * 2.3
        local r = 0.1 + (i % 4) * 0.07
        t[#t + 1] = sphere(math.cos(a) * r, math.sin(a) * r, 0.4 + (i % 5) * 0.09, 0.018, C.white, { a = 255 })
    end
    return norm(t)
end

local function train()
    local t = {}
    cat(t,
        P(-0.25, 0, 0.42, 0.3, 0.17, 0.17, C.black),                       -- boiler
        sphere(-0.55, 0, 0.42, 0.17, C.black),
        P(-0.4, 0, 0.66, 0.06, 0.06, 0.1, C.black, { a = 255 }),            -- stack
        sphere(-0.4, 0, 0.82, 0.08, C.gray), sphere(-0.34, 0.03, 0.94, 0.06, C.gray),
        P(0.12, 0, 0.5, 0.17, 0.19, 0.26, C.red),                           -- cab
        P(0.12, 0, 0.78, 0.2, 0.22, 0.04, C.darkred),
        opaque(0.12, 0.19, 0.58, 0.08, 0.015, 0.08, C.skyblue),
        P(-0.58, 0, 0.3, 0.06, 0.14, 0.06, C.red),                          -- cowcatcher
        sphere(-0.69, 0, 0.42, 0.05, C.yellow, { a = 255 }),                -- headlight
        P(0.62, 0, 0.42, 0.22, 0.17, 0.14, C.green),                        -- a car with presents
        sphere(0.55, 0.02, 0.62, 0.08, C.blue), sphere(0.7, -0.02, 0.6, 0.07, C.gold), sphere(0.62, 0.05, 0.7, 0.05, C.red)
    )
    for _, x in ipairs({ -0.45, -0.1, 0.22, 0.52, 0.74 }) do
        t[#t + 1] = P(x, 0.17, 0.2, 0.1, 0.03, 0.1, C.gold, { a = 255 })
        t[#t + 1] = P(x, -0.17, 0.2, 0.1, 0.03, 0.1, C.gold, { a = 255 })
    end
    return norm(t)
end

local function hauntedTree()
    local t = {}
    cat(t,
        P(0, 0, 0.3, 0.16, 0.14, 0.32, C.purple),                          -- trunk
        P(0, 0, 0.08, 0.26, 0.22, 0.08, C.purple),                         -- roots
        P(-0.3, 0, 0.75, 0.28, 0.06, 0.06, C.purple, { rot = { 0, 40, 0 } }),   -- branches
        P(0.3, 0, 0.78, 0.28, 0.06, 0.06, C.purple, { rot = { 0, -45, 0 } }),
        P(-0.5, 0, 1.0, 0.14, 0.05, 0.05, C.purple, { rot = { 0, 70, 0 } }),
        P(0.52, 0, 1.02, 0.14, 0.05, 0.05, C.purple, { rot = { 0, -60, 0 } }),
        P(0.05, 0, 0.85, 0.06, 0.06, 0.25, C.purple, { rot = { 0, -10, 0 } }),
        P(-0.1, 0, 0.9, 0.05, 0.05, 0.18, C.purple, { rot = { 0, 20, 0 } }),
        opaque(-0.06, 0.14, 0.42, 0.04, 0.02, 0.05, C.yellow), opaque(0.06, 0.14, 0.42, 0.04, 0.02, 0.05, C.yellow),   -- eyes
        opaque(0, 0.14, 0.26, 0.08, 0.02, 0.04, C.black),                   -- mouth
        opaque(-0.04, 0.15, 0.29, 0.015, 0.015, 0.02, C.white), opaque(0.04, 0.15, 0.29, 0.015, 0.015, 0.02, C.white)
    )
    return norm(t)
end

local function cauldronWitch()
    local t = {}
    cat(t,
        P(0, 0.12, 0.26, 0.3, 0.3, 0.24, C.black),                          -- cauldron
        P(0, 0.12, 0.46, 0.3, 0.3, 0.04, C.black, { a = 255 }),
        P(0, 0.12, 0.47, 0.25, 0.25, 0.05, C.lime),                          -- the brew
        sphere(0.1, 0.2, 0.56, 0.05, C.lime), sphere(-0.12, 0.05, 0.6, 0.04, C.lime), sphere(0.02, 0.1, 0.68, 0.03, C.lime),
        opaque(-0.2, 0.12, 0.04, 0.04, 0.04, 0.05, C.black), opaque(0.2, 0.12, 0.04, 0.04, 0.04, 0.05, C.black),
        P(0, -0.22, 0.55, 0.24, 0.18, 0.28, C.purple),                       -- the witch behind it
        sphere(0, -0.18, 0.9, 0.14, C.lime),
        opaque(0, -0.04, 0.88, 0.03, 0.05, 0.03, C.green),
        opaque(-0.055, -0.06, 0.93, 0.025, 0.02, 0.025, C.black), opaque(0.055, -0.06, 0.93, 0.025, 0.02, 0.025, C.black),
        opaque(0, -0.22, 1.03, 0.25, 0.25, 0.025, C.black),
        P(0, -0.22, 1.1, 0.13, 0.13, 0.08, C.black, { a = 255 }), P(0.05, -0.22, 1.2, 0.08, 0.08, 0.07, C.black, { a = 255 }), P(0.12, -0.22, 1.28, 0.045, 0.045, 0.05, C.black, { a = 255 }),
        P(-0.28, -0.1, 0.62, 0.07, 0.07, 0.14, C.purple, { rot = { 0, 40, 0 } }), sphere(-0.36, 0, 0.52, 0.05, C.lime),
        P(0.28, -0.1, 0.62, 0.07, 0.07, 0.14, C.purple, { rot = { 0, -40, 0 } }), sphere(0.36, 0, 0.52, 0.05, C.lime),
        P(0.36, 0.02, 0.5, 0.02, 0.02, 0.2, C.brown, { a = 255, rot = { 0, 20, 0 } })   -- the spoon
    )
    return norm(t)
end

local function catInPumpkin()
    local t = {}
    t[#t + 1] = P(0, 0, 0.3, 0.42, 0.4, 0.3, C.pumpkin)
    for i = 0, 5 do
        local a = i * math.pi / 3
        t[#t + 1] = P(math.sin(a) * 0.16, math.cos(a) * 0.15, 0.28, 0.3, 0.28, 0.29, C.pumpkin)
    end
    cat(t,
        opaque(-0.14, 0.39, 0.36, 0.07, 0.04, 0.07, C.black), opaque(0.14, 0.39, 0.36, 0.07, 0.04, 0.07, C.black),
        opaque(0, 0.39, 0.2, 0.2, 0.03, 0.05, C.black),
        P(0, -0.05, 0.72, 0.17, 0.2, 0.2, C.black),                          -- the cat
        sphere(0, 0.1, 0.95, 0.14, C.black),
        P(-0.09, 0.1, 1.09, 0.045, 0.03, 0.07, C.black), P(0.09, 0.1, 1.09, 0.045, 0.03, 0.07, C.black),
        opaque(-0.06, 0.22, 0.97, 0.03, 0.015, 0.035, C.lime), opaque(0.06, 0.22, 0.97, 0.03, 0.015, 0.035, C.lime),
        opaque(0, 0.235, 0.91, 0.02, 0.015, 0.015, C.pink),
        P(-0.12, 0.12, 0.6, 0.05, 0.05, 0.12, C.black), P(0.12, 0.12, 0.6, 0.05, 0.05, 0.12, C.black),
        P(0.2, -0.2, 0.7, 0.04, 0.04, 0.22, C.black, { rot = { 0, -25, 0 } }),
        P(0, 0.1, 0.82, 0.09, 0.09, 0.025, C.orange)
    )
    return norm(t)
end

local function reaper()
    local t = {}
    cat(t,
        P(0, 0, 0.36, 0.28, 0.24, 0.36, C.black),                           -- robe
        P(0, 0, 0.06, 0.32, 0.28, 0.06, C.black),
        P(0, 0, 0.85, 0.2, 0.18, 0.2, C.black),                              -- hood
        P(0, 0.1, 0.82, 0.11, 0.08, 0.12, C.white),                          -- the skull in it
        opaque(-0.045, 0.17, 0.85, 0.03, 0.02, 0.035, C.black), opaque(0.045, 0.17, 0.85, 0.03, 0.02, 0.035, C.black),
        opaque(0, 0.18, 0.78, 0.015, 0.015, 0.02, C.black),
        opaque(0, 0.17, 0.72, 0.05, 0.012, 0.012, C.black),
        P(-0.3, 0.08, 0.55, 0.07, 0.07, 0.16, C.black, { rot = { 0, 30, 0 } }),
        P(0.36, 0.1, 0.5, 0.07, 0.07, 0.18, C.black, { rot = { 0, -20, 0 } }),
        sphere(-0.38, 0.12, 0.38, 0.045, C.white),
        sphere(0.42, 0.14, 0.3, 0.045, C.white),
        P(0.46, 0.14, 0.62, 0.02, 0.02, 0.6, C.darkbrown, { a = 255 }),      -- scythe
        P(0.3, 0.14, 1.22, 0.2, 0.025, 0.05, C.silver, { a = 255, rot = { 0, 15, 0 } }),
        P(0.15, 0.14, 1.14, 0.08, 0.025, 0.04, C.silver, { a = 255, rot = { 0, 45, 0 } })
    )
    return norm(t)
end

local function pumpkinStack()
    local t = {}
    local function pk(z, s, face)
        t[#t + 1] = P(0, 0, z, 0.42 * s, 0.4 * s, 0.34 * s, C.pumpkin)
        for i = 0, 4 do
            local a = i * 2 * math.pi / 5
            t[#t + 1] = P(math.sin(a) * 0.16 * s, math.cos(a) * 0.15 * s, z, 0.3 * s, 0.28 * s, 0.33 * s, C.pumpkin)
        end
        t[#t + 1] = P(0, 0, z + 0.36 * s, 0.05 * s, 0.05 * s, 0.08 * s, C.darkgreen, { a = 255 })
        if face then
            cat(t,
                opaque(-0.14 * s, 0.39 * s, z + 0.1 * s, 0.07 * s, 0.04, 0.07 * s, C.black),
                opaque(0.14 * s, 0.39 * s, z + 0.1 * s, 0.07 * s, 0.04, 0.07 * s, C.black),
                opaque(0, 0.39 * s, z - 0.12 * s, 0.2 * s, 0.03, 0.05 * s, C.black)
            )
        end
    end
    pk(0.34, 1.0, true)
    pk(0.92, 0.75, true)
    pk(1.36, 0.52, true)
    return norm(t)
end


local function cornucopia()
    local t = {}
    -- The horn: spheres shrinking along a curve that rises and curls back.
    for i = 0, 9 do
        local u = i / 9
        local r = 0.2 * (1 - u) + 0.03
        t[#t + 1] = P(-0.3 + u * 0.75, -0.02 + u * 0.08, r + 0.03 + u * 0.3 + (u > 0.7 and (u - 0.7) * 0.5 or 0), r * 1.15, r, r, C.tan)
    end
    cat(t,
        P(-0.3, 0, 0.23, 0.04, 0.22, 0.22, C.darkbrown, { a = 255 }),       -- the dark mouth
        sphere(-0.42, 0.06, 0.16, 0.13, C.pumpkin),                            -- the spill
        sphere(-0.56, -0.06, 0.1, 0.09, C.red), sphere(-0.46, 0.22, 0.09, 0.08, C.yellow),
        sphere(-0.64, 0.1, 0.08, 0.06, C.violet), sphere(-0.7, 0.02, 0.14, 0.05, C.violet), sphere(-0.66, 0.16, 0.16, 0.05, C.violet),
        sphere(-0.34, -0.1, 0.4, 0.07, C.green), sphere(-0.5, 0.0, 0.32, 0.06, C.red)
    )
    return norm(t)
end

local function cupid()
    local t = {}
    cat(t,
        P(0, 0, 0.4, 0.22, 0.2, 0.26, C.skin),                                -- a round little body
        P(0, 0.03, 0.26, 0.24, 0.21, 0.08, C.white),                          -- the cloth
        sphere(0, 0.03, 0.78, 0.19, C.skin),
        P(0, -0.03, 0.9, 0.2, 0.17, 0.1, C.gold),                             -- curls
        eyes(0.19, 0.82, 0.065, 0.025),
        opaque(0, 0.21, 0.76, 0.02, 0.02, 0.02, C.pink),
        opaque(-0.07, 0.19, 0.7, 0.04, 0.012, 0.012, C.red), opaque(0.07, 0.19, 0.7, 0.04, 0.012, 0.012, C.red),
        P(-0.32, -0.12, 0.6, 0.22, 0.05, 0.14, C.white, { rot = { 0, -25, 0 } }),   -- wings
        P(0.32, -0.12, 0.6, 0.22, 0.05, 0.14, C.white, { rot = { 0, 25, 0 } }),
        P(-0.12, 0.14, 0.1, 0.09, 0.12, 0.08, C.skin), P(0.12, 0.14, 0.1, 0.09, 0.12, 0.08, C.skin),
        P(-0.3, 0.15, 0.5, 0.06, 0.06, 0.14, C.skin, { rot = { 0, 50, 0 } }),
        P(0.3, 0.15, 0.5, 0.06, 0.06, 0.14, C.skin, { rot = { 0, -50, 0 } })
    )
    for i = 0, 10 do                                                         -- the bow
        local a = math.rad(-60 + i * 12)
        t[#t + 1] = sphere(-0.42 + math.cos(a) * 0.1 - 0.1, 0.22, 0.5 + math.sin(a) * 0.3, 0.02, C.gold, { a = 255 })
    end
    t[#t + 1] = P(-0.3, 0.24, 0.5, 0.25, 0.015, 0.015, C.white, { a = 255 })     -- arrow
    t[#t + 1] = P(-0.06, 0.24, 0.5, 0.05, 0.02, 0.05, C.red, { a = 255 })
    return norm(t)
end

local function eagle()
    local t = {}
    cat(t,
        P(0, 0, 0.1, 0.4, 0.3, 0.1, C.red), P(0, 0, 0.18, 0.38, 0.28, 0.03, C.white), P(0, 0, 0.23, 0.36, 0.26, 0.03, C.blue),   -- the base
        P(0, 0, 0.5, 0.2, 0.22, 0.26, C.darkbrown),                           -- body
        sphere(0, 0.1, 0.82, 0.14, C.white),                                   -- head
        opaque(0, 0.24, 0.8, 0.045, 0.08, 0.04, C.yellow),
        eyes(0.21, 0.86, 0.06, 0.025),
        P(-0.45, -0.05, 0.62, 0.32, 0.06, 0.1, C.darkbrown, { rot = { 0, -20, 0 } }),   -- wings
        P(0.45, -0.05, 0.62, 0.32, 0.06, 0.1, C.darkbrown, { rot = { 0, 20, 0 } }),
        P(-0.72, -0.05, 0.75, 0.1, 0.05, 0.06, C.white, { rot = { 0, -30, 0 } }),
        P(0.72, -0.05, 0.75, 0.1, 0.05, 0.06, C.white, { rot = { 0, 30, 0 } }),
        P(0, -0.2, 0.36, 0.08, 0.14, 0.05, C.white),                            -- tail
        opaque(-0.08, 0.1, 0.27, 0.05, 0.08, 0.03, C.yellow), opaque(0.08, 0.1, 0.27, 0.05, 0.08, 0.03, C.yellow)
    )
    return norm(t)
end

local function soldier()
    local t = {}
    local K = { 30, 30, 36 }
    cat(t,
        P(0, 0, 0.1, 0.3, 0.2, 0.05, K, { a = 255 }),                           -- base
        P(-0.08, 0, 0.3, 0.07, 0.08, 0.22, K, { a = 255 }), P(0.08, 0, 0.3, 0.07, 0.08, 0.22, K, { a = 255 }),
        P(0, 0, 0.62, 0.17, 0.12, 0.17, K, { a = 255 }),
        P(-0.2, 0, 0.62, 0.06, 0.06, 0.14, K, { a = 255, rot = { 0, 15, 0 } }), P(0.22, 0.04, 0.6, 0.06, 0.06, 0.14, K, { a = 255, rot = { 0, -25, 0 } }),
        sphere(0, 0, 0.88, 0.1, K, { a = 255 }),
        P(0, 0, 0.94, 0.13, 0.12, 0.07, K, { a = 255 }),                         -- helmet
        P(0.32, 0.06, 0.62, 0.025, 0.025, 0.36, K, { a = 255, rot = { 0, -10, 0 } }),   -- the rifle, down
        sphere(0, 0.14, 0.14, 0.03, { 255, 220, 150 }, { a = 255, lit = true })     -- one candle at its feet
    )
    return norm(t)
end

local function cross()
    local t = {}
    local W = { 255, 250, 235 }
    t[#t + 1] = P(0, 0, 0.5, 0.07, 0.05, 0.5, W, { a = 255, lit = true })
    t[#t + 1] = P(0, 0, 0.72, 0.34, 0.05, 0.07, W, { a = 255, lit = true })
    t[#t + 1] = P(0, 0, 0.03, 0.14, 0.1, 0.03, C.gray, { a = 255 })
    return norm(t)
end


local function grill()
    local t = {}
    cat(t,
        P(0, 0, 0.5, 0.34, 0.3, 0.16, C.black),                                 -- bowl
        P(0, 0, 0.66, 0.34, 0.3, 0.03, C.silver, { a = 255 }),                   -- grate
        P(0, 0, 0.74, 0.32, 0.28, 0.1, C.black),                                 -- lid, open behind
        P(-0.2, 0, 0.22, 0.025, 0.025, 0.22, C.black, { a = 255, rot = { 0, 12, 0 } }),
        P(0.2, 0, 0.22, 0.025, 0.025, 0.22, C.black, { a = 255, rot = { 0, -12, 0 } }),
        P(0, -0.22, 0.22, 0.025, 0.025, 0.22, C.black, { a = 255, rot = { -12, 0, 0 } }),
        sphere(-0.1, 0.05, 0.7, 0.07, C.orange), sphere(0.08, -0.03, 0.74, 0.06, C.yellow), sphere(0.0, 0.08, 0.8, 0.05, C.orange),   -- flames
        P(-0.14, 0.12, 0.69, 0.08, 0.025, 0.025, C.darkred, { a = 255 }), P(0.14, 0.12, 0.69, 0.08, 0.025, 0.025, C.darkred, { a = 255 }),
        P(0, 0, 0.9, 0.06, 0.06, 0.04, C.gray, { a = 70 }), P(0.04, 0, 0.98, 0.07, 0.07, 0.05, C.gray, { a = 60 })
    )
    return norm(t)
end

local function kinara()
    local t = {}
    cat(t,
        P(0, 0, 0.1, 0.46, 0.12, 0.05, C.darkbrown, { a = 255 }),
        P(0, 0, 0.2, 0.44, 0.06, 0.06, C.brown, { a = 255 })
    )
    local cols = { C.red, C.red, C.red, C.black, C.green, C.green, C.green }
    for i = 1, 7 do
        local x = (i - 4) * 0.14
        local h = (i == 4) and 0.3 or 0.24
        t[#t + 1] = P(x, 0, 0.24 + h, 0.035, 0.035, h, cols[i])
        t[#t + 1] = P(x, 0, 0.24 + h * 2 + 0.06, 0.035, 0.035, 0.06, C.yellow, { a = 255 })
        t[#t + 1] = P(x, 0, 0.24 + h * 2 + 0.1, 0.02, 0.02, 0.035, C.white, { a = 255 })
    end
    return norm(t)
end



local function elephant()
    local t = {}
    local E = { 150, 160, 185 }
    cat(t,
        P(0, 0, 0.36, 0.32, 0.3, 0.3, E),
        sphere(0, 0.14, 0.72, 0.24, E),
        P(-0.3, 0.02, 0.76, 0.14, 0.05, 0.16, E), P(0.3, 0.02, 0.76, 0.14, 0.05, 0.16, E),      -- ears
        P(-0.3, 0.05, 0.76, 0.09, 0.03, 0.11, C.pink), P(0.3, 0.05, 0.76, 0.09, 0.03, 0.11, C.pink),
        P(0, 0.4, 0.55, 0.07, 0.08, 0.2, E, { rot = { 20, 0, 0 } }),                           -- trunk
        sphere(0, 0.46, 0.38, 0.07, E),
        eyes(0.35, 0.78, 0.09, 0.03),
        P(-0.16, 0.14, 0.08, 0.1, 0.12, 0.08, E), P(0.16, 0.14, 0.08, 0.1, 0.12, 0.08, E),
        P(-0.12, 0.3, 0.84, 0.08, 0.04, 0.05, C.pink, { rot = { 0, 20, 0 } }), P(0.12, 0.3, 0.84, 0.08, 0.04, 0.05, C.pink, { rot = { 0, -20, 0 } }),   -- a bow
        sphere(0, 0.32, 0.84, 0.035, C.pink)
    )
    return norm(t)
end

local function brideGroom()
    local t = {}
    cat(t,
        P(-0.25, 0, 0.3, 0.26, 0.22, 0.3, C.white),                                -- the dress
        P(-0.25, 0, 0.6, 0.14, 0.12, 0.14, C.white),
        P(-0.25, 0, 0.06, 0.3, 0.26, 0.06, C.white),
        sphere(-0.25, 0.02, 0.86, 0.13, C.skin),
        P(-0.25, -0.06, 0.9, 0.16, 0.14, 0.12, C.brown),                          -- hair
        P(-0.25, -0.1, 0.72, 0.2, 0.08, 0.3, C.white, { a = 150 }),               -- veil
        opaque(-0.3, 0.13, 0.88, 0.02, 0.015, 0.02, C.black), opaque(-0.2, 0.13, 0.88, 0.02, 0.015, 0.02, C.black),
        opaque(-0.25, 0.14, 0.81, 0.03, 0.012, 0.012, C.red),
        sphere(-0.42, 0.14, 0.52, 0.08, C.pastelpink), sphere(-0.36, 0.16, 0.48, 0.05, C.white), sphere(-0.48, 0.16, 0.46, 0.05, C.pink),   -- bouquet
        P(0.28, 0, 0.38, 0.2, 0.18, 0.36, C.black),                                -- the groom
        P(0.28, 0.17, 0.48, 0.07, 0.03, 0.22, C.white),
        P(0.28, 0.19, 0.6, 0.04, 0.02, 0.03, C.red),
        P(0.2, 0, 0.1, 0.07, 0.07, 0.12, C.black), P(0.36, 0, 0.1, 0.07, 0.07, 0.12, C.black),
        sphere(0.28, 0.02, 0.88, 0.13, C.skin),
        P(0.28, -0.03, 0.96, 0.14, 0.12, 0.06, C.darkbrown),
        opaque(0.23, 0.13, 0.9, 0.02, 0.015, 0.02, C.black), opaque(0.33, 0.13, 0.9, 0.02, 0.015, 0.02, C.black),
        opaque(0.28, 0.14, 0.83, 0.03, 0.012, 0.012, C.red),
        P(0.0, 0.04, 0.5, 0.1, 0.05, 0.05, C.skin)                                 -- holding hands
    )
    return norm(t)
end

local function weddingCake()
    local t = {}
    cat(t,
        P(0, 0, 0.14, 0.42, 0.42, 0.14, C.white), P(0, 0, 0.28, 0.43, 0.43, 0.03, C.cream),
        P(0, 0, 0.42, 0.32, 0.32, 0.13, C.white), P(0, 0, 0.55, 0.33, 0.33, 0.03, C.cream),
        P(0, 0, 0.67, 0.22, 0.22, 0.11, C.white), P(0, 0, 0.78, 0.23, 0.23, 0.03, C.cream),
        sphere(-0.05, 0.02, 0.88, 0.05, C.white), sphere(0.05, 0.02, 0.88, 0.05, C.black)       -- the topper
    )
    local fl = { C.pastelpink, C.pink, C.white }
    for i = 0, 7 do
        local a = i * math.pi / 4
        t[#t + 1] = sphere(math.sin(a) * 0.42, math.cos(a) * 0.42, 0.26, 0.04, fl[i % 3 + 1], { a = 255 })
        t[#t + 1] = sphere(math.sin(a + 0.4) * 0.32, math.cos(a + 0.4) * 0.32, 0.54, 0.035, fl[(i + 1) % 3 + 1], { a = 255 })
        t[#t + 1] = sphere(math.sin(a + 0.8) * 0.22, math.cos(a + 0.8) * 0.22, 0.78, 0.03, fl[(i + 2) % 3 + 1], { a = 255 })
    end
    return norm(t)
end

local function doves()
    local t = {}
    cat(t,
        P(-0.2, 0, 0.66, 0.26, 0.2, 0.26, C.red), P(0.2, 0, 0.66, 0.26, 0.2, 0.26, C.red),      -- a heart to stand on
        P(0, 0, 0.42, 0.37, 0.19, 0.32, C.red), P(0, 0, 0.16, 0.16, 0.12, 0.17, C.red)
    )
    local function dove(x, dir)
        cat(t,
            P(x, 0.1, 0.98, 0.1, 0.14, 0.08, C.white),
            sphere(x + dir * 0.12, 0.14, 1.06, 0.06, C.white),
            opaque(x + dir * 0.19, 0.15, 1.05, 0.02, 0.03, 0.015, C.orange),
            opaque(x + dir * 0.13, 0.19, 1.08, 0.012, 0.01, 0.012, C.black),
            P(x - dir * 0.05, 0.02, 1.08, 0.14, 0.04, 0.05, C.white, { rot = { 0, dir * 35, 0 } }),
            P(x - dir * 0.16, 0.1, 0.96, 0.08, 0.05, 0.03, C.white)
        )
    end
    dove(-0.22, 1)
    dove(0.22, -1)
    return norm(t)
end

local function champagneGlasses()
    local t = {}
    for _, side in ipairs({ -1, 1 }) do
        local x = side * 0.22
        cat(t,
            P(x, 0, 0.06, 0.16, 0.16, 0.03, C.silver, { a = 255 }),
            P(x, 0, 0.3, 0.03, 0.03, 0.24, C.silver, { a = 255, rot = { 0, -side * 8, 0 } }),
            P(x - side * 0.06, 0, 0.78, 0.17, 0.15, 0.3, { 255, 240, 200 }, { a = 160, rot = { 0, -side * 8, 0 } }),
            P(x - side * 0.06, 0, 0.7, 0.14, 0.12, 0.18, C.gold, { rot = { 0, -side * 8, 0 } }),
            sphere(x - side * 0.08, 0.05, 1.0, 0.03, C.white, { a = 255 }), sphere(x - side * 0.02, -0.03, 1.08, 0.025, C.white, { a = 255 })
        )
    end
    return norm(t)
end

local function partyHat()
    local t = {}
    local cols = { C.hotpink, C.yellow, C.skyblue, C.lime }
    for i = 0, 9 do
        local u = i / 9
        t[#t + 1] = P(0, 0, 0.08 + u * 0.84, 0.38 * (1 - u * 0.9) + 0.03, 0.38 * (1 - u * 0.9) + 0.03, 0.07, cols[i % 4 + 1])
    end
    t[#t + 1] = sphere(0, 0, 1.0, 0.09, C.white)
    for i = 0, 5 do
        local a = i * math.pi / 3
        t[#t + 1] = sphere(math.sin(a) * 0.3, math.cos(a) * 0.3, 0.3, 0.05, C.white, { a = 255 })
    end
    return norm(t)
end

local function presentStack()
    local t = {}
    local function box(x, y, z, w, d, h, c, rib)
        t[#t + 1] = P(x, y, z, w, d, h, c)
        t[#t + 1] = P(x, y, z + 0.003, 0.06, d + 0.01, h + 0.005, rib, { a = 255 })
        t[#t + 1] = P(x, y, z + 0.003, w + 0.01, 0.06, h + 0.005, rib, { a = 255 })
        t[#t + 1] = P(x - 0.06, y, z + h + 0.03, 0.07, 0.04, 0.04, rib, { a = 255, rot = { 0, 20, 0 } })
        t[#t + 1] = P(x + 0.06, y, z + h + 0.03, 0.07, 0.04, 0.04, rib, { a = 255, rot = { 0, -20, 0 } })
    end
    box(0, 0, 0.22, 0.42, 0.36, 0.22, C.red, C.gold)
    box(0.04, 0.02, 0.6, 0.3, 0.26, 0.17, C.blue, C.white)
    box(-0.02, 0, 0.9, 0.18, 0.16, 0.13, C.hotpink, C.yellow)
    return norm(t)
end

local function balloonBunch()
    local t = {}
    local cols = { C.red, C.yellow, C.blue, C.hotpink, C.lime }
    for i = 1, 5 do
        local a = i * 2 * math.pi / 5
        local x, y = math.cos(a) * 0.22, math.sin(a) * 0.12
        local z = 0.78 + (i % 2) * 0.1
        t[#t + 1] = P(x, y, z, 0.16, 0.14, 0.2, cols[i])
        t[#t + 1] = P(x * 0.5, y * 0.5, 0.38, 0.008, 0.008, 0.3, C.white, { a = 255, rot = { 0, -math.deg(math.atan(x / 0.6)), 0 } })
    end
    t[#t + 1] = P(0, 0, 0.08, 0.14, 0.14, 0.08, C.gold)        -- the weight
    return norm(t)
end

-- ---------------------------------------------------------------------
-- Lit yard pieces (kind 'yard'): drawn matte and bright, no inflation.
-- ---------------------------------------------------------------------
local LED = { 255, 245, 215 }

local function litDeer()
    local t = {}
    local r = 0.035
    local function seg(x0, z0, x1, z1, y)
        local n = math.max(2, math.floor(math.sqrt((x1 - x0) ^ 2 + (z1 - z0) ^ 2) / 0.07))
        for i = 0, n do
            local u = i / n
            t[#t + 1] = sphere(x0 + (x1 - x0) * u, y or 0, z0 + (z1 - z0) * u, r, LED, { a = 255, lit = true })
        end
    end
    -- body as a lit frame: back, belly, chest, rump, neck, head, legs, antlers
    seg(-0.4, 0.72, 0.3, 0.72) seg(-0.4, 0.5, 0.3, 0.5) seg(-0.4, 0.5, -0.4, 0.72) seg(0.3, 0.5, 0.3, 0.72)
    seg(-0.4, 0.72, -0.4, 0.5, 0.12) seg(0.3, 0.72, 0.3, 0.5, 0.12)
    seg(0.3, 0.72, 0.42, 1.0) seg(0.42, 1.0, 0.62, 1.02) seg(0.62, 1.02, 0.6, 0.9) seg(0.6, 0.9, 0.42, 0.88) seg(0.42, 0.88, 0.3, 0.72)
    seg(0.46, 1.02, 0.4, 1.24) seg(0.4, 1.24, 0.3, 1.3) seg(0.4, 1.24, 0.5, 1.32) seg(0.42, 1.14, 0.3, 1.18)
    seg(-0.3, 0.5, -0.32, 0.05) seg(-0.2, 0.5, -0.2, 0.05, 0.12) seg(0.18, 0.5, 0.18, 0.05) seg(0.26, 0.5, 0.3, 0.05, 0.12)
    seg(-0.4, 0.72, -0.5, 0.82)
    return norm(t)
end

local function starBethlehem()
    local t = {}
    t[#t + 1] = P(0, 0, 0.36, 0.02, 0.02, 0.36, C.gray, { a = 255 })
    local G = { 255, 220, 120 }
    t[#t + 1] = P(0, 0, 0.78, 0.1, 0.05, 0.3, G, { a = 255, lit = true })
    t[#t + 1] = P(0, 0, 0.84, 0.26, 0.05, 0.08, G, { a = 255, lit = true })
    t[#t + 1] = P(0, 0, 0.82, 0.12, 0.05, 0.12, G, { a = 255, lit = true, rot = { 0, 45, 0 } })
    t[#t + 1] = P(0, 0, 0.82, 0.12, 0.05, 0.12, G, { a = 255, lit = true, rot = { 0, -45, 0 } })
    for i = 1, 6 do t[#t + 1] = sphere(0.3 + i * 0.07, 0, 0.84 - i * 0.05, 0.03 - i * 0.003, G, { a = 255, lit = true }) end
    return norm(t)
end

local function windowCandle()
    local t = {}
    cat(t,
        P(0, 0.05, 0.08, 0.14, 0.09, 0.03, C.gold, { a = 255 }),
        P(0, 0.05, 0.4, 0.05, 0.05, 0.32, C.cream, { a = 255 }),
        P(0, 0.05, 0.78, 0.03, 0.03, 0.06, C.yellow, { a = 255, lit = true }),
        P(0, 0.05, 0.84, 0.018, 0.018, 0.035, C.white, { a = 255, lit = true })
    )
    return norm(t)
end

local function litOrnaments()
    local t = {}
    cat(t,
        P(-0.42, 0, 0.36, 0.36, 0.36, 0.36, C.red, { a = 235, lit = true }), P(-0.42, 0, 0.74, 0.08, 0.08, 0.04, C.gold, { a = 255 }),
        P(0.3, 0.1, 0.3, 0.3, 0.3, 0.3, C.blue, { a = 235, lit = true }), P(0.3, 0.1, 0.62, 0.07, 0.07, 0.035, C.gold, { a = 255 }),
        P(0.05, -0.3, 0.22, 0.22, 0.22, 0.22, C.gold, { a = 235, lit = true }), P(0.05, -0.3, 0.46, 0.05, 0.05, 0.03, C.silver, { a = 255 })
    )
    return norm(t)
end

local function litOrbs()
    local t = {}
    for i = 0, 6 do
        local a = i * 0.9
        local r = 0.07 + (i % 3) * 0.04
        local d = 0.22 + (i % 2) * 0.18
        t[#t + 1] = sphere(math.cos(a) * d, math.sin(a) * d * 0.8, r + (i % 2) * 0.12, r, LED, { a = 235, lit = true })
    end
    return norm(t)
end

local function sunflowers()
    local t = {}
    for i, x in ipairs({ -0.32, 0.0, 0.3 }) do
        local h = 0.7 + (i % 2) * 0.2
        t[#t + 1] = P(x, 0, h * 0.5, 0.02, 0.02, h * 0.5, C.green, { a = 255 })
        t[#t + 1] = P(x + 0.08, 0.02, h * 0.4, 0.09, 0.03, 0.05, C.green, { a = 255, rot = { 0, -30, 0 } })
        for k = 0, 9 do
            local a = k * math.pi / 5
            t[#t + 1] = P(x + math.cos(a) * 0.14, 0.03, h + math.sin(a) * 0.14, 0.05, 0.02, 0.03, C.yellow, { a = 255, rot = { 0, 90 - math.deg(a), 0 } })
        end
        t[#t + 1] = sphere(x, 0.04, h, 0.08, C.darkbrown, { a = 255 })
    end
    return norm(t)
end

local function snowflakeStake()
    local t = {}
    t[#t + 1] = P(0, 0, 0.3, 0.015, 0.015, 0.3, C.gray, { a = 255 })
    local B = { 200, 230, 255 }
    for arm = 0, 2 do
        local a = arm * math.pi / 3
        t[#t + 1] = P(0, 0, 0.82, 0.03, 0.03, 0.3, B, { a = 255, lit = true, rot = { 0, math.deg(a), 0 } })
        for _, s in ipairs({ -1, 1 }) do
            for _, d in ipairs({ 0.16, 0.26 }) do
                local bx, bz = math.sin(a) * d, 0.82 + math.cos(a) * d
                t[#t + 1] = P(bx, 0, bz, 0.025, 0.025, 0.08, B, { a = 255, lit = true, rot = { 0, math.deg(a) + s * 60, 0 } })
                t[#t + 1] = P(-bx, 0, 0.82 - (bz - 0.82), 0.025, 0.025, 0.08, B, { a = 255, lit = true, rot = { 0, math.deg(a) - s * 60, 0 } })
            end
        end
    end
    return norm(t)
end

-- A lit tree in any size (the game's tree props come in fixed sizes).
-- Layers of foliage with bulbs scattered over them and a star on top.
local function litTree()
    local t = {}
    cat(t,
        P(0, 0, 0.06, 0.07, 0.07, 0.07, C.darkbrown, { a = 255 }),
        P(0, 0, 0.24, 0.4, 0.4, 0.22, C.pine, { a = 255 }), P(0, 0, 0.44, 0.33, 0.33, 0.19, C.fir, { a = 255 }),
        P(0, 0, 0.62, 0.26, 0.26, 0.16, C.pine, { a = 255 }), P(0, 0, 0.78, 0.18, 0.18, 0.13, C.fir, { a = 255 }),
        P(0, 0, 0.9, 0.1, 0.1, 0.1, C.pine, { a = 255 }),
        P(0, 0, 1.0, 0.06, 0.03, 0.06, C.gold, { a = 255, lit = true }), P(0, 0, 1.0, 0.03, 0.03, 0.09, C.gold, { a = 255, lit = true })
    )
    local cols = { { 255, 60, 60 }, { 60, 220, 90 }, { 70, 110, 255 }, { 255, 220, 80 }, { 255, 255, 255 } }
    for i = 0, 39 do
        local a = i * 2.39996
        local z = 0.12 + (i / 39) * 0.82
        local r = (0.42 - z * 0.36) + 0.01
        t[#t + 1] = sphere(math.sin(a) * r, math.cos(a) * r, z, 0.022, cols[i % 5 + 1], { a = 255, lit = true })
    end
    return norm(t)
end

-- Funeral pieces: subdued, white and black, candlelight.
local function lilyStand()
    local t = {}
    cat(t,
        P(0, 0, 0.04, 0.2, 0.2, 0.04, C.black, { a = 255 }),
        P(0, 0, 0.4, 0.02, 0.02, 0.36, C.black, { a = 255 }),
        P(0, 0, 0.74, 0.16, 0.16, 0.05, C.black, { a = 255 })
    )
    for i = 0, 8 do
        local a = i * 2 * math.pi / 9
        local r = 0.12 + (i % 2) * 0.08
        t[#t + 1] = P(math.cos(a) * r, math.sin(a) * r * 0.7, 0.86 + (i % 3) * 0.05, 0.07, 0.05, 0.09, C.white, { a = 255 })
        t[#t + 1] = sphere(math.cos(a) * r, math.sin(a) * r * 0.7, 0.9 + (i % 3) * 0.05, 0.02, C.yellow, { a = 255 })
        t[#t + 1] = P(math.cos(a + 0.35) * r, math.sin(a + 0.35) * r * 0.7, 0.8, 0.09, 0.03, 0.03, C.darkgreen, { a = 255, rot = { 0, 90 - math.deg(a), 0 } })
    end
    cat(t,
        P(-0.06, 0.17, 0.72, 0.08, 0.02, 0.04, C.black, { a = 255, rot = { 0, 15, 0 } }),
        P(0.06, 0.17, 0.72, 0.08, 0.02, 0.04, C.black, { a = 255, rot = { 0, -15, 0 } }),
        P(-0.04, 0.17, 0.6, 0.025, 0.012, 0.1, C.black, { a = 255 }), P(0.04, 0.17, 0.6, 0.025, 0.012, 0.1, C.black, { a = 255 })
    )
    return norm(t)
end

local function vigil()
    local t = {}
    for i = 0, 10 do
        local a = i * 1.9
        local r = 0.1 + (i % 4) * 0.09
        local h = 0.12 + (i % 3) * 0.08
        local x, y = math.cos(a) * r, math.sin(a) * r * 0.8
        t[#t + 1] = P(x, y, h * 0.5, 0.035, 0.035, h * 0.5, C.cream, { a = 255 })
        t[#t + 1] = P(x, y, h + 0.04, 0.02, 0.02, 0.04, C.yellow, { a = 255, lit = true })
        t[#t + 1] = P(x, y, h + 0.07, 0.012, 0.012, 0.025, C.white, { a = 255, lit = true })
    end
    return norm(t)
end

local function casketDrape()
    -- A draped casket on a bier: a long low box under a dark cloth with
    -- a spray of white flowers on top.
    local t = {}
    cat(t,
        P(0, 0, 0.12, 0.24, 0.12, 0.12, C.black, { a = 255 }),
        P(0, 0, 0.38, 0.52, 0.22, 0.16, C.darkbrown, { a = 255 }),
        P(0, 0, 0.44, 0.54, 0.24, 0.12, { 40, 30, 60 }, { a = 255 }),      -- the drape
        P(0, 0.22, 0.3, 0.5, 0.02, 0.2, { 40, 30, 60 }, { a = 255 }),
        P(0, -0.22, 0.3, 0.5, 0.02, 0.2, { 40, 30, 60 }, { a = 255 })
    )
    for i = -3, 3 do
        t[#t + 1] = sphere(i * 0.1, 0.02 * (i % 2), 0.6, 0.05, (i % 2 == 0) and C.white or C.cream, { a = 255 })
        t[#t + 1] = P(i * 0.1 + 0.03, -0.04, 0.56, 0.06, 0.025, 0.02, C.darkgreen, { a = 255 })
    end
    return norm(t)
end

local function banner(stripes, o)
    -- A wall banner: horizontal bands with a rod across the top.
    local t = {}
    local n = #stripes
    for i, c in ipairs(stripes) do
        local z = 0.9 - (i - 0.5) * (0.8 / n)
        t[#t + 1] = P(0, 0.03, z, 0.5, 0.015, 0.4 / n, c, { a = 255 })
    end
    t[#t + 1] = P(0, 0.03, 0.94, 0.56, 0.02, 0.02, C.gold, { a = 255 })
    if o and o.stars then
        for i = -2, 2 do t[#t + 1] = opaque(i * 0.18, 0.05, 0.5, 0.04, 0.012, 0.04, C.white) end
    end
    return norm(t)
end

-- ---------------------------------------------------------------------
-- Wreaths: a ring of foliage with bulbs through it and a bow. Drawn
-- matte, hung on a wall (z up, y out from the wall), 1 unit across.
-- ---------------------------------------------------------------------
local function wreath(o)
    local t = {}
    local R, n = 0.36, o.n or 22
    local fol = o.foliage
    for i = 0, n - 1 do
        local a = i * 2 * math.pi / n
        local j = (i * 7) % 5
        local r = 0.1 + j * 0.012
        local c = fol[(i % #fol) + 1]
        t[#t + 1] = P(math.cos(a) * R, 0.02 + (j % 2) * 0.03, 0.5 + math.sin(a) * R, r, r * 0.75, r, c, { a = 255 })
        if j == 2 or j == 4 then
            t[#t + 1] = P(math.cos(a + 0.12) * (R + 0.05), 0.05, 0.5 + math.sin(a + 0.12) * (R + 0.05), r * 0.7, r * 0.55, r * 0.7, fol[((i + 1) % #fol) + 1], { a = 255 })
        end
    end
    if o.ornaments then
        for i = 0, 7 do
            local a = i * math.pi / 4 + 0.3
            t[#t + 1] = sphere(math.cos(a) * R, 0.12, 0.5 + math.sin(a) * R, 0.035, o.ornaments[(i % #o.ornaments) + 1], { a = 255 })
        end
    end
    if o.bulbs then
        for i = 0, 15 do
            local a = i * math.pi / 8 + 0.15
            t[#t + 1] = sphere(math.cos(a) * (R + 0.02), 0.13, 0.5 + math.sin(a) * (R + 0.02), 0.018, o.bulbs, { a = 255, lit = true })
        end
    end
    if o.bow then
        local b = o.bow
        cat(t,
            P(-0.1, 0.14, 0.12, 0.1, 0.05, 0.06, b, { a = 255, rot = { 0, 15, 0 } }),
            P(0.1, 0.14, 0.12, 0.1, 0.05, 0.06, b, { a = 255, rot = { 0, -15, 0 } }),
            sphere(0, 0.17, 0.12, 0.04, b, { a = 255 }),
            P(-0.06, 0.13, 0.03, 0.03, 0.03, 0.08, b, { a = 255, rot = { 0, -15, 0 } }),
            P(0.06, 0.13, 0.03, 0.03, 0.03, 0.08, b, { a = 255, rot = { 0, 15, 0 } })
        )
    end
    return norm(t)
end

-- ---------------------------------------------------------------------
-- The list
-- ---------------------------------------------------------------------
-- kind: 'inflatable' stands on the ground, inflates and sways;
--       'yard' stands on the ground, drawn matte and bright (a lit deer);
--       'wreath' hangs flat on a wall, drawn matte (wreaths, banners,
--       window candles).
-- arch: true on a walkway arch: the placer runs its row along the path.
-- size: default height (inflatable) or diameter (wreath) in meters.
-- light: { z, color, range } -- the glow inside, at height z (unit).
-- alpha: per part; everything is opaque (see Shapes.Alpha).
Shapes.List = {
    -- Christmas
    { name = 'snowman',     kind = 'inflatable', label = 'Snowman',              size = 2.4, holidays = { 'christmas' },            parts = snowman(),    light = { z = 0.4, color = { 220, 235, 255 } },
      desc = 'Three snowballs, a top hat, a scarf and stick arms. The one every yard has.' },
    { name = 'santa',       kind = 'inflatable', label = 'Santa',                size = 2.6, holidays = { 'christmas' },            parts = santa(),      light = { z = 0.4, color = { 255, 120, 110 } },
      desc = 'Waving, with a belt buckle and green mittens.' },
    { name = 'reindeer',    kind = 'inflatable', label = 'Reindeer',             size = 2.4, holidays = { 'christmas' },            parts = reindeer(),   light = { z = 0.45, color = { 255, 200, 150 } },
      desc = 'Antlers, a collar bell and a red nose. Put a few in a row and the sleigh prop behind them.' },
    { name = 'penguin',     kind = 'inflatable', label = 'Penguin',              size = 2.0, holidays = { 'christmas', 'newyear' }, parts = penguin(),    light = { z = 0.4, color = { 200, 230, 255 } },
      desc = 'In a Santa hat and a scarf.' },
    { name = 'polarbear',   kind = 'inflatable', label = 'Polar bear',           size = 1.8, holidays = { 'christmas' },            parts = polarBear(),  light = { z = 0.4, color = { 220, 235, 255 } },
      desc = 'On all fours, with a red scarf. Low and wide; good under a window.' },
    { name = 'candycane',   kind = 'inflatable', label = 'Candy cane',           size = 2.8, holidays = { 'christmas' },            parts = candyCane(),  light = { z = 0.5, color = { 255, 150, 150 } },
      desc = 'Tall and thin. Two of them frame a doorway.' },
    { name = 'tree',        kind = 'inflatable', label = 'Christmas tree',       size = 3.0, holidays = { 'christmas' },            parts = tree(),       light = { z = 0.4, color = { 255, 220, 160 } },
      desc = 'Green, with ornaments and a gold star. Lights up from inside like a lantern.' },
    { name = 'gingerbread', kind = 'inflatable', label = 'Gingerbread man',      size = 2.2, holidays = { 'christmas' },            parts = gingerbread(), light = { z = 0.45, color = { 255, 200, 140 } },
      desc = 'Icing cuffs and gumdrop buttons.' },
    -- Hanukkah
    { name = 'menorah',     kind = 'inflatable', label = 'Menorah',              size = 2.2, holidays = { 'hanukkah' },             parts = menorah(),    light = { z = 0.8, color = { 255, 230, 160 } },
      desc = 'Nine candles, lit. Wide; it wants a lawn or a plaza.' },
    { name = 'dreidel',     kind = 'inflatable', label = 'Dreidel',              size = 1.8, holidays = { 'hanukkah' },             parts = dreidel(),    light = { z = 0.5, color = { 120, 160, 255 } },
      desc = 'Blue and white, standing on its point.' },
    -- New Year's and party
    { name = 'star',        kind = 'inflatable', label = 'Gold star',            size = 2.2, holidays = { 'newyear', 'party', 'july4' }, parts = goldStar(), light = { z = 0.5, color = { 255, 210, 100 } },
      desc = 'A five-pointed star on a stand.' },
    { name = 'champagne',   kind = 'inflatable', label = 'Champagne bottle',     size = 3.0, holidays = { 'newyear', 'party' },     parts = champagne(),  light = { z = 0.4, color = { 160, 255, 160 } },
      desc = 'Cork on its way out, bubbles behind it.' },
    { name = 'cake',        kind = 'inflatable', label = 'Birthday cake',        size = 2.0, holidays = { 'party', 'valentines' },  parts = cake(),       light = { z = 0.4, color = { 255, 180, 220 } },
      desc = 'Three tiers and five candles.' },
    { name = 'discoball',   kind = 'inflatable', label = 'Disco ball',           size = 2.2, holidays = { 'party', 'newyear' },     parts = discoBall(),  light = { z = 0.55, color = { 200, 220, 255 } },
      desc = 'On a short stand. Looks best with a strobe show on the strings around it.' },
    -- Valentine's
    { name = 'heart',       kind = 'inflatable', label = 'Heart',                size = 2.0, holidays = { 'valentines', 'party' },  parts = heart(),      light = { z = 0.5, color = { 255, 90, 120 } },
      desc = 'Big and red, standing on its point.' },
    { name = 'lovebear',    kind = 'inflatable', label = 'Bear with a heart',    size = 2.2, holidays = { 'valentines' },           parts = loveBear(),   light = { z = 0.4, color = { 255, 170, 190 } },
      desc = 'A teddy bear hugging a heart.' },
    -- St. Patrick's
    { name = 'shamrock',    kind = 'inflatable', label = 'Shamrock',             size = 2.0, holidays = { 'stpatricks' },           parts = shamrock(),   light = { z = 0.55, color = { 120, 255, 120 } },
      desc = 'Three leaves on a stem.' },
    { name = 'leprechaun',  kind = 'inflatable', label = 'Leprechaun',           size = 2.4, holidays = { 'stpatricks' },           parts = leprechaun(), light = { z = 0.4, color = { 150, 255, 150 } },
      desc = 'Green suit, orange beard, a pot of gold at his feet.' },
    -- Easter
    { name = 'bunny',       kind = 'inflatable', label = 'Bunny',                size = 2.2, holidays = { 'easter' },               parts = bunny(),      light = { z = 0.4, color = { 255, 220, 240 } },
      desc = 'Holding a carrot.' },
    { name = 'egg',         kind = 'inflatable', label = 'Easter egg',           size = 1.8, holidays = { 'easter' },               parts = easterEgg(),  light = { z = 0.5, color = { 255, 240, 180 } },
      desc = 'Pastel, with bands and dots. Several in different sizes make a hunt.' },
    { name = 'chick',       kind = 'inflatable', label = 'Chick',                size = 1.8, holidays = { 'easter' },               parts = chick(),      light = { z = 0.4, color = { 255, 240, 120 } },
      desc = 'Yellow, with a pink bow.' },
    -- Independence Day
    { name = 'unclesam',    kind = 'inflatable', label = 'Uncle Sam hat',        size = 2.2, holidays = { 'july4' },                parts = unclesamHat(), light = { z = 0.5, color = { 200, 220, 255 } },
      desc = 'Stars and stripes, lit from inside.' },
    { name = 'firecracker', kind = 'inflatable', label = 'Firecracker',          size = 2.6, holidays = { 'july4', 'newyear' },     parts = firecracker(), light = { z = 0.45, color = { 255, 120, 120 } },
      desc = 'Red, white and blue, fuse lit.' },
    -- Halloween
    { name = 'jackolantern', kind = 'inflatable', label = 'Jack-o-lantern',      size = 2.0, holidays = { 'halloween' },            parts = pumpkin(true), light = { z = 0.4, color = { 255, 140, 40 } },
      desc = 'A grinning pumpkin, lit orange from inside.' },
    { name = 'ghost',       kind = 'inflatable', label = 'Ghost',                size = 2.4, holidays = { 'halloween' },            parts = ghost(),      light = { z = 0.5, color = { 180, 255, 200 } },
      desc = 'Arms out. Lit pale green.' },
    { name = 'blackcat',    kind = 'inflatable', label = 'Black cat',            size = 1.8, holidays = { 'halloween' },            parts = blackCat(),   light = { z = 0.35, color = { 170, 90, 255 } },
      desc = 'Arched back, green eyes, purple glow.' },
    { name = 'spider',      kind = 'inflatable', label = 'Spider',               size = 1.6, holidays = { 'halloween' },            parts = spider(),     light = { z = 0.3, color = { 255, 60, 60 } },
      desc = 'Low and wide, eight legs out. Wants a lawn or a roof.' },
    { name = 'bat',         kind = 'inflatable', label = 'Bat',                  size = 1.6, holidays = { 'halloween' },            parts = bat(),        light = { z = 0.5, color = { 170, 90, 255 } },
      desc = 'Wings spread, yellow eyes.' },
    { name = 'witch',       kind = 'inflatable', label = 'Witch',                size = 2.6, holidays = { 'halloween' },            parts = witch(),      light = { z = 0.4, color = { 160, 255, 120 } },
      desc = 'Green face, purple dress, a broom at her side.' },
    -- Thanksgiving
    { name = 'turkey',      kind = 'inflatable', label = 'Turkey',               size = 2.4, holidays = { 'thanksgiving' },         parts = turkey(),     light = { z = 0.4, color = { 255, 170, 80 } },
      desc = 'A tom with a fanned tail and a wattle. The lawn classic.' },
    { name = 'pumpkin',     kind = 'inflatable', label = 'Harvest pumpkin',      size = 1.6, holidays = { 'thanksgiving', 'halloween' }, parts = pumpkin(false), light = { z = 0.4, color = { 255, 160, 60 } },
      desc = 'A plain pumpkin, no face.' },
    { name = 'scarecrow',   kind = 'inflatable', label = 'Scarecrow',            size = 2.6, holidays = { 'thanksgiving', 'halloween' }, parts = scarecrow(), light = { z = 0.4, color = { 255, 200, 120 } },
      desc = 'On a post, straw at the cuffs, a patched shirt.' },
    { name = 'acorn',       kind = 'inflatable', label = 'Acorn',                size = 1.6, holidays = { 'thanksgiving' },         parts = acorn(),      light = { z = 0.4, color = { 255, 190, 110 } },
      desc = 'Brown, with a cap. Small; good by a door.' },

    -- 0.3.0: more inflatables
    { name = 'mrsclaus',    kind = 'inflatable', label = 'Mrs. Claus',           size = 2.4, holidays = { 'christmas' },            parts = mrsClaus(),   light = { z = 0.4, color = { 255, 130, 120 } },
      desc = 'Red dress, white apron, glasses, a plate of cookies.' },
    { name = 'snowfamily',  kind = 'inflatable', label = 'Snowman family',       size = 2.4, holidays = { 'christmas' },            parts = snowmanFamily(), light = { z = 0.4, color = { 220, 235, 255 } },
      desc = 'Three snowmen side by side: top hat, Santa hat, earmuffs. Wide.' },
    { name = 'nutcracker',  kind = 'inflatable', label = 'Nutcracker',           size = 2.8, holidays = { 'christmas' },            parts = nutcracker(), light = { z = 0.45, color = { 255, 150, 140 } },
      desc = 'A toy soldier in a red jacket and a tall black hat. Two guard a door.' },
    { name = 'santasleigh', kind = 'inflatable', label = 'Santa in his sleigh',  size = 2.2, holidays = { 'christmas' },            parts = santaSleigh(), light = { z = 0.4, color = { 255, 160, 130 } },
      desc = 'Santa seated with a sack of presents. Put reindeer in front of it.' },
    { name = 'gbhouse',     kind = 'inflatable', label = 'Gingerbread house',    size = 2.2, holidays = { 'christmas' },            parts = gingerbreadHouse(), light = { z = 0.4, color = { 255, 200, 140 } },
      desc = 'Icing roof, gumdrops, a chimney with snow on it.' },
    { name = 'snowglobe',   kind = 'inflatable', label = 'Snow globe',           size = 2.4, holidays = { 'christmas' },            parts = snowGlobe(),  light = { z = 0.55, color = { 200, 230, 255 } },
      desc = 'A glass globe on a red base with a house and trees inside, snow falling.' },
    { name = 'train',       kind = 'inflatable', label = 'Christmas train',      size = 1.8, holidays = { 'christmas' },            parts = train(),      light = { z = 0.4, color = { 255, 200, 150 } },
      desc = 'An engine with a car of presents behind it. Long and low.' },
    { name = 'hauntedtree', kind = 'inflatable', label = 'Haunted tree',         size = 3.0, holidays = { 'halloween' },            parts = hauntedTree(), light = { z = 0.4, color = { 170, 90, 255 } },
      desc = 'A purple tree with a face and reaching branches.' },
    { name = 'cauldron',    kind = 'inflatable', label = 'Witch and cauldron',   size = 2.4, holidays = { 'halloween' },            parts = cauldronWitch(), light = { z = 0.45, color = { 120, 255, 120 } },
      desc = 'A witch stirring a cauldron that glows green.' },
    { name = 'catpumpkin',  kind = 'inflatable', label = 'Cat on a pumpkin',     size = 2.0, holidays = { 'halloween' },            parts = catInPumpkin(), light = { z = 0.3, color = { 255, 140, 40 } },
      desc = 'A black cat sitting on a jack-o-lantern.' },
    { name = 'reaper',      kind = 'inflatable', label = 'Grim reaper',          size = 2.8, holidays = { 'halloween' },            parts = reaper(),     light = { z = 0.5, color = { 140, 255, 160 } },
      desc = 'Hooded, with a scythe.' },
    { name = 'pumpkinstack', kind = 'inflatable', label = 'Stacked pumpkins',    size = 2.4, holidays = { 'halloween', 'thanksgiving' }, parts = pumpkinStack(), light = { z = 0.4, color = { 255, 140, 40 } },
      desc = 'Three jack-o-lanterns stacked, biggest at the bottom.' },
    { name = 'pilgrim',     kind = 'inflatable', label = 'Pilgrim',              size = 2.4, holidays = { 'thanksgiving' },         parts = pilgrim(),    light = { z = 0.4, color = { 255, 200, 140 } },
      desc = 'Black coat and buckled hat, white collar.' },
    { name = 'cornucopia',  kind = 'inflatable', label = 'Cornucopia',           size = 1.4, holidays = { 'thanksgiving' },         parts = cornucopia(), light = { z = 0.35, color = { 255, 180, 90 } },
      desc = 'A horn of plenty spilling a pumpkin, apples and grapes. Low and wide.' },
    { name = 'cupid',       kind = 'inflatable', label = 'Cupid',                size = 2.0, holidays = { 'valentines' },           parts = cupid(),      light = { z = 0.45, color = { 255, 170, 190 } },
      desc = 'Wings, a gold bow and an arrow with a heart on it.' },
    { name = 'eagle',       kind = 'inflatable', label = 'Eagle',                size = 2.0, holidays = { 'july4', 'memorialday', 'laborday' }, parts = eagle(), light = { z = 0.4, color = { 220, 230, 255 } },
      desc = 'Wings spread, on a red, white and blue base.' },
    { name = 'worker',      kind = 'inflatable', label = 'Construction worker',  size = 2.4, holidays = { 'laborday' },             parts = worker(),     light = { z = 0.4, color = { 255, 180, 100 } },
      desc = 'Hard hat, orange vest, a shovel.' },
    { name = 'grill',       kind = 'inflatable', label = 'Barbecue grill',       size = 1.6, holidays = { 'laborday', 'july4', 'party' }, parts = grill(),  light = { z = 0.5, color = { 255, 150, 60 } },
      desc = 'Lid open, flames up, two sausages on.' },
    { name = 'kinara',      kind = 'inflatable', label = 'Kinara',               size = 2.0, holidays = { 'kwanzaa' },              parts = kinara(),     light = { z = 0.8, color = { 255, 220, 150 } },
      desc = 'Seven candles: three red, one black, three green, lit. Wide.' },
    { name = 'jester',      kind = 'inflatable', label = 'Mardi Gras jester',    size = 2.6, holidays = { 'party' },                parts = jester(),     light = { z = 0.45, color = { 200, 150, 255 } },
      desc = 'Purple, green and gold, a three-pointed hat with bells.' },
    { name = 'graduate',    kind = 'inflatable', label = 'Graduate',             size = 2.4, holidays = { 'party', 'birthday' },    parts = graduate(),   light = { z = 0.4, color = { 255, 220, 150 } },
      desc = 'Cap and gown, gold tassel, a diploma held up.' },
    { name = 'elephant',    kind = 'inflatable', label = 'Baby elephant',        size = 1.8, holidays = { 'birthday', 'party' },    parts = elephant(),   light = { z = 0.4, color = { 220, 220, 255 } },
      desc = 'Gray-blue with pink ears and a pink bow. Baby showers.' },
    { name = 'bridegroom',  kind = 'inflatable', label = 'Bride and groom',      size = 2.4, holidays = { 'wedding' },              parts = brideGroom(), light = { z = 0.4, color = { 255, 240, 230 } },
      desc = 'Holding hands; veil, bouquet, red tie.' },
    { name = 'weddingcake', kind = 'inflatable', label = 'Wedding cake',         size = 2.0, holidays = { 'wedding' },              parts = weddingCake(), light = { z = 0.4, color = { 255, 230, 235 } },
      desc = 'Three white tiers ringed with pink flowers, a couple on top.' },
    { name = 'doves',       kind = 'inflatable', label = 'Doves on a heart',     size = 2.0, holidays = { 'wedding', 'valentines' }, parts = doves(),     light = { z = 0.5, color = { 255, 120, 140 } },
      desc = 'Two white doves facing each other on a red heart.' },
    { name = 'toast',       kind = 'inflatable', label = 'Champagne toast',      size = 2.0, holidays = { 'wedding', 'newyear', 'party' }, parts = champagneGlasses(), light = { z = 0.6, color = { 255, 230, 160 } },
      desc = 'Two flutes tilted together, bubbles rising.' },
    { name = 'partyhat',    kind = 'inflatable', label = 'Party hat',            size = 2.0, holidays = { 'birthday', 'party' },    parts = partyHat(),   light = { z = 0.4, color = { 255, 200, 230 } },
      desc = 'A striped cone with a pompom and polka dots.' },
    { name = 'presents',    kind = 'inflatable', label = 'Stack of presents',    size = 2.0, holidays = { 'birthday', 'christmas', 'party' }, parts = presentStack(), light = { z = 0.4, color = { 255, 200, 200 } },
      desc = 'Three wrapped boxes stacked, each with a bow.' },
    { name = 'balloons',    kind = 'inflatable', label = 'Balloon bunch',        size = 2.2, holidays = { 'birthday', 'party' },    parts = balloonBunch(), light = { z = 0.7, color = { 255, 220, 230 } },
      desc = 'Five balloons on strings tied to a gold weight.' },

    -- 0.3.0: arches over a walkway (inflatable). Place one, then the
    -- next snaps into a row along the path.
    { name = 'arch_candy',  kind = 'inflatable', arch = true, label = 'Candy cane arch',     size = 2.6, holidays = { 'christmas' },            parts = candyArch(),   light = { z = 0.6, color = { 255, 150, 150 } },
      desc = 'Red and white stripes over the walk. Several in a row make a tunnel.' },
    { name = 'arch_tophat', kind = 'inflatable', arch = true, label = 'Top hat arch',        size = 2.8, holidays = { 'christmas' },            parts = topHatArch(),  light = { z = 0.6, color = { 220, 235, 255 } },
      desc = 'A candy-stripe arch with a snowman\'s top hat on top.' },
    { name = 'arch_holidays', kind = 'inflatable', arch = true, label = 'Happy Holidays arch', size = 2.6, holidays = { 'christmas', 'kwanzaa' }, parts = holidaysArch(), light = { z = 0.6, color = { 255, 220, 160 } },
      desc = 'Green with red bows and gold lights along the top.' },
    { name = 'arch_rainbow', kind = 'inflatable', arch = true, label = 'Rainbow arch',       size = 2.4, holidays = { 'stpatricks', 'party', 'birthday' }, parts = rainbowArch(), light = { z = 0.5, color = { 255, 230, 160 } },
      desc = 'Six bands of color with a pot of gold at each foot.' },
    { name = 'arch_fireworks', kind = 'inflatable', arch = true, label = 'Fireworks arch',   size = 2.6, holidays = { 'july4', 'memorialday', 'laborday' }, parts = fireworksArch(), light = { z = 0.6, color = { 220, 230, 255 } },
      desc = 'Red, white and blue with stars along the top.' },
    { name = 'arch_kwanzaa', kind = 'inflatable', arch = true, label = 'Pan-African arch',   size = 2.6, holidays = { 'kwanzaa' },              parts = panAfricanArch(), light = { z = 0.6, color = { 255, 200, 120 } },
      desc = 'Red, black and green bands.' },
    { name = 'arch_balloon', kind = 'inflatable', arch = true, label = 'Balloon arch',       size = 2.6, holidays = { 'birthday', 'party', 'wedding' }, parts = balloonArch(), light = { z = 0.6, color = { 255, 220, 230 } },
      desc = 'Clusters of balloons in every color over the walk.' },
    { name = 'arch_wedding', kind = 'inflatable', arch = true, label = 'Wedding arch',       size = 2.6, holidays = { 'wedding', 'valentines' }, parts = weddingArch(), light = { z = 0.6, color = { 255, 240, 235 } },
      desc = 'White, with pink and white flowers and greenery.' },
    { name = 'arch_lit',    kind = 'yard', arch = true, label = 'Lit arch',                 size = 2.6, holidays = { 'christmas', 'newyear', 'wedding', 'hanukkah' }, parts = litArch(), light = { z = 0.7, color = { 255, 235, 190 } },
      desc = 'A thin white arch strung with warm white lights. A row makes a lit walkway.' },

    -- 0.3.0: lit yard pieces (ground, no inflation)
    { name = 'littree',     kind = 'yard', label = 'Lit tree (any size)',       size = 3.0, holidays = { 'christmas', 'kwanzaa', 'newyear' }, parts = litTree(), light = { z = 0.45, color = { 255, 220, 160 } },
      desc = 'An evergreen with forty colored bulbs and a gold star. Page Up and Page Down make it any height from a tabletop to a plaza tree; the tree props come in fixed sizes.' },
    { name = 'litdeer',     kind = 'yard', label = 'Lit deer',                  size = 1.6, holidays = { 'christmas', 'newyear' }, parts = litDeer(),     light = { z = 0.5, color = { 255, 240, 210 } },
      desc = 'A standing deer in white lights, antlers up. Two or three make a herd.' },
    { name = 'starpole',    kind = 'yard', label = 'Star of Bethlehem',          size = 2.6, holidays = { 'christmas' },            parts = starBethlehem(), light = { z = 0.85, color = { 255, 220, 120 } },
      desc = 'A gold four-pointed star with a tail, on a tall pole.' },
    { name = 'ornaments',   kind = 'yard', label = 'Lit ornaments',              size = 1.2, holidays = { 'christmas' },            parts = litOrnaments(), light = { z = 0.4, color = { 255, 200, 160 } },
      desc = 'Three big ornaments, red, blue and gold, lit from inside. Lawns and planters.' },
    { name = 'orbs',        kind = 'yard', label = 'Lit orbs',                   size = 0.9, holidays = { 'christmas', 'newyear', 'wedding', 'party' }, parts = litOrbs(), light = { z = 0.3, color = { 255, 240, 210 } },
      desc = 'A cluster of glowing spheres in warm white. Flower beds and steps.' },
    { name = 'sunflowers',  kind = 'yard', label = 'Sunflowers',                 size = 1.3, holidays = { 'thanksgiving', 'laborday' }, parts = sunflowers(), light = { z = 0.6, color = { 255, 210, 80 } },
      desc = 'Three sunflowers on stakes.' },
    { name = 'snowflake',   kind = 'yard', label = 'Snowflake stake',            size = 1.4, holidays = { 'christmas', 'newyear', 'hanukkah' }, parts = snowflakeStake(), light = { z = 0.8, color = { 200, 230, 255 } },
      desc = 'A lit snowflake on a stake. Line a walk with them.' },
    { name = 'soldier',     kind = 'yard', label = 'Soldier silhouette',         size = 2.0, holidays = { 'memorialday' },          parts = soldier(),     light = { z = 0.1, color = { 255, 220, 150 } },
      desc = 'A dark standing soldier, rifle down, one candle at his feet.' },
    { name = 'cross',       kind = 'yard', label = 'Lit cross',                  size = 1.6, holidays = { 'memorialday', 'easter', 'christmas' }, parts = cross(), light = { z = 0.5, color = { 255, 250, 235 } },
      desc = 'A white cross, lit.' },

    -- 0.3.0: wall pieces (kind wreath = hangs flat on the wall you aim at)
    { name = 'windowcandle', kind = 'wreath', label = 'Window candle',           size = 0.5, holidays = { 'christmas', 'hanukkah', 'kwanzaa', 'memorialday' }, parts = windowCandle(), light = { z = 0.8, color = { 255, 220, 150 }, range = 1.0 },
      desc = 'A single lit candle in a gold holder. Put one in every window.' },
    { name = 'banner_kwanzaa', kind = 'wreath', label = 'Kwanzaa banner',        size = 1.2, holidays = { 'kwanzaa' },              parts = banner({ C.red, C.black, C.green }), light = { z = 0.5, color = { 255, 200, 120 }, range = 1.0 },
      desc = 'Red, black and green bands on a rod.' },
    { name = 'bunting',     kind = 'wreath', label = 'Patriotic bunting',        size = 1.2, holidays = { 'july4', 'memorialday', 'laborday' }, parts = banner({ C.red, C.white, C.red, C.white, C.blue }, { stars = true }), light = { z = 0.5, color = { 220, 230, 255 }, range = 1.0 },
      desc = 'Red and white stripes with a starred blue band. Railings and porch fronts.' },

    -- 0.3.0: funeral
    { name = 'lilies',      kind = 'yard', label = 'Lily stand',                 size = 1.4, holidays = { 'funeral', 'memorialday', 'easter' }, parts = lilyStand(), light = { z = 0.7, color = { 255, 240, 220 } },
      desc = 'White lilies on a black stand with a black ribbon. Either side of a door or a casket.' },
    { name = 'vigil',       kind = 'yard', label = 'Candle vigil',               size = 0.5, holidays = { 'funeral', 'memorialday' }, parts = vigil(),      light = { z = 0.3, color = { 255, 210, 140 } },
      desc = 'A cluster of lit candles at different heights. Steps and curbs.' },
    { name = 'casket',      kind = 'yard', label = 'Draped casket',              size = 1.0, holidays = { 'funeral' },               parts = casketDrape(), light = { z = 0.6, color = { 255, 240, 230 } },
      desc = 'A casket on a bier under a dark drape, white flowers on top.' },
    { name = 'bunting_funeral', kind = 'wreath', label = 'Mourning bunting',      size = 1.2, holidays = { 'funeral' },               parts = banner({ C.black, { 60, 50, 80 }, C.black, C.white, C.black }), light = { z = 0.5, color = { 200, 200, 220 }, range = 1.0 },
      desc = 'Black bands with one white, on a rod. Railings, porch fronts, the station door.' },
    { name = 'wreath_funeral', kind = 'wreath', label = 'Mourning wreath', size = 0.9, holidays = { 'funeral' }, light = { z = 0.5, color = { 255, 240, 220 }, range = 1.2 },
      parts = wreath({ foliage = { C.white, C.cream, C.darkgreen, C.white }, bow = C.black, bulbs = { 255, 240, 220 } }),
      desc = 'White lilies and greenery with a black ribbon.' },

    -- Wreaths (wall)
    { name = 'wreath_memorial', kind = 'wreath', label = 'Memorial wreath', size = 0.9, holidays = { 'memorialday' }, light = { z = 0.5, color = { 220, 230, 255 }, range = 1.2 },
      parts = wreath({ foliage = { C.red, C.white, C.blue, C.white }, bow = C.navy, bulbs = { 255, 255, 255 }, ornaments = { C.white, C.red } }),
      desc = 'Red, white and blue with a navy bow.' },
    { name = 'wreath_wedding', kind = 'wreath', label = 'Wedding wreath', size = 0.8, holidays = { 'wedding' }, light = { z = 0.5, color = { 255, 240, 235 }, range = 1.0 },
      parts = wreath({ foliage = { C.white, C.pastelpink, C.cream, C.green }, bow = C.white, bulbs = { 255, 245, 230 } }),
      desc = 'White and blush flowers with greenery and a white bow.' },
    { name = 'wreath_birthday', kind = 'wreath', label = 'Birthday wreath', size = 0.8, holidays = { 'birthday' }, light = { z = 0.5, color = { 255, 255, 255 }, range = 1.0 },
      parts = wreath({ foliage = { C.hotpink, C.yellow, C.skyblue, C.lime, C.orange }, bow = C.white, bulbs = { 255, 255, 255 } }),
      desc = 'Balloon colors, white bow.' },
    { name = 'wreath_kwanzaa', kind = 'wreath', label = 'Kwanzaa wreath', size = 0.9, holidays = { 'kwanzaa' }, light = { z = 0.5, color = { 255, 200, 120 }, range = 1.2 },
      parts = wreath({ foliage = { C.darkgreen, C.green, C.pine }, bow = C.red, bulbs = { 255, 200, 120 }, ornaments = { C.red, C.black, C.green } }),
      desc = 'Evergreen with red, black and green ornaments.' },
    { name = 'wreath_xmas', kind = 'wreath', label = 'Christmas wreath', size = 0.9, holidays = { 'christmas' }, light = { z = 0.5, color = { 255, 214, 150 }, range = 1.2 },
      parts = wreath({ foliage = { C.pine, C.fir, C.darkgreen, C.green }, bow = C.red, bulbs = { 255, 225, 170 }, ornaments = { C.red, C.gold } }),
      desc = 'Evergreen, warm white lights, red ornaments and a red bow.' },
    { name = 'wreath_hanukkah', kind = 'wreath', label = 'Hanukkah wreath', size = 0.9, holidays = { 'hanukkah' }, light = { z = 0.5, color = { 160, 190, 255 }, range = 1.2 },
      parts = wreath({ foliage = { C.pine, C.fir, C.darkgreen }, bow = C.blue, bulbs = { 200, 220, 255 }, ornaments = { C.blue, C.silver, C.white } }),
      desc = 'Evergreen with blue and silver ornaments, cool white lights.' },
    { name = 'wreath_newyear', kind = 'wreath', label = "New Year's wreath", size = 0.9, holidays = { 'newyear' }, light = { z = 0.5, color = { 255, 220, 140 }, range = 1.2 },
      parts = wreath({ foliage = { C.gold, C.ochre, C.silver, C.gold }, bow = C.silver, bulbs = { 255, 235, 180 } }),
      desc = 'Gold and silver, lit warm.' },
    { name = 'wreath_valentines', kind = 'wreath', label = 'Rose wreath', size = 0.8, holidays = { 'valentines' }, light = { z = 0.5, color = { 255, 150, 180 }, range = 1.0 },
      parts = wreath({ foliage = { C.red, C.hotpink, C.darkred, C.pink, C.red }, bow = C.white, bulbs = { 255, 220, 230 } }),
      desc = 'Red and pink roses with a white bow.' },
    { name = 'wreath_stpatricks', kind = 'wreath', label = "St. Patrick's wreath", size = 0.9, holidays = { 'stpatricks' }, light = { z = 0.5, color = { 150, 255, 150 }, range = 1.2 },
      parts = wreath({ foliage = { C.green, C.lime, C.darkgreen, C.green }, bow = C.gold, bulbs = { 200, 255, 200 }, ornaments = { C.gold } }),
      desc = 'Bright green with a gold bow and gold ornaments.' },
    { name = 'wreath_easter', kind = 'wreath', label = 'Easter wreath', size = 0.8, holidays = { 'easter' }, light = { z = 0.5, color = { 255, 240, 220 }, range = 1.0 },
      parts = wreath({ foliage = { C.lime, C.pastelgreen, C.green }, bow = C.pastelpink, bulbs = { 255, 250, 220 }, ornaments = { C.pastelpink, C.pastelblue, C.pastelyellow, C.lilac } }),
      desc = 'Spring green with pastel eggs and a pink bow.' },
    { name = 'wreath_july4', kind = 'wreath', label = 'Patriotic wreath', size = 0.9, holidays = { 'july4' }, light = { z = 0.5, color = { 220, 230, 255 }, range = 1.2 },
      parts = wreath({ foliage = { C.red, C.white, C.blue, C.white }, bow = C.navy, bulbs = { 255, 255, 255 }, ornaments = { C.white, C.red } }),
      desc = 'Red, white and blue with a navy bow.' },
    { name = 'wreath_halloween', kind = 'wreath', label = 'Halloween wreath', size = 0.9, holidays = { 'halloween' }, light = { z = 0.5, color = { 255, 140, 40 }, range = 1.2 },
      parts = wreath({ foliage = { C.black, C.darkbrown, C.black, C.purple }, bow = C.orange, bulbs = { 255, 150, 50 }, ornaments = { C.orange, C.violet } }),
      desc = 'Black branches, orange lights, a purple-and-orange touch.' },
    { name = 'wreath_thanksgiving', kind = 'wreath', label = 'Harvest wreath', size = 0.9, holidays = { 'thanksgiving' }, light = { z = 0.5, color = { 255, 180, 90 }, range = 1.2 },
      parts = wreath({ foliage = { C.leaf, C.rust, C.ochre, C.brown, C.orange }, bow = C.tan, bulbs = { 255, 200, 120 }, ornaments = { C.darkred, C.gold } }),
      desc = 'Autumn leaves in orange, rust and gold, with a burlap bow.' },
    { name = 'wreath_party', kind = 'wreath', label = 'Party wreath', size = 0.8, holidays = { 'party' }, light = { z = 0.5, color = { 255, 255, 255 }, range = 1.0 },
      parts = wreath({ foliage = { C.red, C.yellow, C.green, C.blue, C.hotpink, C.orange }, bow = C.white, bulbs = { 255, 255, 255 } }),
      desc = 'Every color, white bow.' },
}

-- Every part is OPAQUE. Translucent markers do not sort against each
-- other: the body showed through the beard, the belt floated through the
-- chest, and arms sank into the body and popped back as the draw order
-- was re-sorted (seen in game 2026-11-04). Opaque parts depth-test, so a
-- shape has real edges and holds still. The light inside still glows.
Shapes.Alpha = { inflatable = 255, wreath = 255, yard = 255 }

local byName = {}
for _, s in ipairs(Shapes.List) do byName[s.name] = s end

function Shapes.Get(name)
    return type(name) == 'string' and byName[name] or nil
end

--- Shapes of a kind offered for a holiday, in list order.
function Shapes.For(holiday, kind)
    local out = {}
    for _, s in ipairs(Shapes.List) do
        if not kind or s.kind == kind then
            for _, h in ipairs(s.holidays) do
                if h == holiday then out[#out + 1] = s break end
            end
        end
    end
    return out
end

--- Is this shape offered under this holiday?
function Shapes.Allowed(name, holiday)
    local s = byName[name]
    if not s then return false end
    for _, h in ipairs(s.holidays) do if h == holiday then return true end end
    return false
end

--- The half-extents of a shape in unit space: how far it reaches in x
--- and y from its origin. Cached. Used for picking and the heap.
function Shapes.Extent(s)
    if s.extent then return s.extent end
    local ex, ey = 0.0, 0.0
    for _, p in ipairs(s.parts) do
        local x = math.abs(p[1]) + p[4]
        local y = math.abs(p[2]) + p[5]
        if x > ex then ex = x end
        if y > ey then ey = y end
    end
    s.extent = { x = ex, y = ey }
    return s.extent
end

--- Size limits, in meters.
function Shapes.ClampSize(s, size)
    local v = tonumber(size) or s.size
    local lo, hi = 0.4, 8.0
    if s.kind == 'wreath' then lo, hi = 0.3, 4.0 end
    if v < lo then v = lo elseif v > hi then v = hi end
    return v
end
