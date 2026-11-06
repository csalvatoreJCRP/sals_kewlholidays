--[[
    Wreaths and lit yard pieces: decorations built in game from lit shapes.

    Each is a composition of ellipsoids the client draws every frame: a
    wreath is a ring of foliage with a bow and a string of bulbs through
    it, a lit deer is a deer in white lights. Drawn matte with a light
    inside.

    Inflatables are not here. Every one ships as a real model
    (stream/*.ydr, listed in shared/inflatable_models.lua) and is placed
    as a prop. The shapes they were built from live in
    tools/inflatable_shapes.lua, which is not part of the resource.

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
-- Yard pieces
-- ---------------------------------------------------------------------

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
-- kind: 'yard' stands on the ground, drawn matte and bright (a lit deer);
--       'wreath' hangs flat on a wall, drawn matte (wreaths, banners,
--       window candles).
-- arch: true on a walkway arch: the placer runs its row along the path.
-- size: default height (yard) or diameter (wreath) in meters.
-- light: { z, color, range } -- the glow inside, at height z (unit).
-- alpha: per part; everything is opaque (see Shapes.Alpha).
Shapes.List = {
    -- An arch over a walkway. Place one, then the next snaps into a row
    -- along the path.
    { name = 'arch_lit',    kind = 'yard', arch = true, label = 'Lit arch',                 size = 2.6, holidays = { 'christmas', 'newyear', 'wedding', 'hanukkah' }, parts = litArch(), light = { z = 0.7, color = { 255, 235, 190 } },
      desc = 'A thin white arch strung with warm white lights. A row makes a lit walkway.' },

    -- Lit yard pieces (on the ground)
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
Shapes.Alpha = { wreath = 255, yard = 255 }

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
