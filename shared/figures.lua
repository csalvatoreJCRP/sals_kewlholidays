-- Rope-light figures: shapes drawn in bulbs and hung flat on a wall.
--
-- Each figure is one or more strokes in a unit square (-1..1 on both
-- axes, y up). The placer scales it to a size in meters, orients it to
-- the wall it is aimed at, and the result is stored as an ordinary string
-- of lights with `breaks` marking where one stroke ends and the next
-- begins -- so the renderer, the shows and the save file need nothing new.

Figures = {}

local function star(points, outer, inner)
    local out = {}
    for i = 0, points * 2 do
        local r = (i % 2 == 0) and outer or inner
        local a = math.pi / 2 + i * math.pi / points
        out[#out + 1] = { math.cos(a) * r, math.sin(a) * r }
    end
    return out
end

local function circle(r, n, cx, cy)
    local out = {}
    for i = 0, n do
        local a = i * 2 * math.pi / n
        out[#out + 1] = { (cx or 0) + math.cos(a) * r, (cy or 0) + math.sin(a) * r }
    end
    return out
end

local function arc(r, a0, a1, n, cx, cy)
    local out = {}
    for i = 0, n do
        local a = a0 + (a1 - a0) * i / n
        out[#out + 1] = { (cx or 0) + math.cos(a) * r, (cy or 0) + math.sin(a) * r }
    end
    return out
end

local function heart()
    local out = {}
    for i = 0, 40 do
        local t = i * 2 * math.pi / 40
        local x = 16 * math.sin(t) ^ 3
        local y = 13 * math.cos(t) - 5 * math.cos(2 * t) - 2 * math.cos(3 * t) - math.cos(4 * t)
        out[#out + 1] = { x / 17, y / 17 + 0.1 }
    end
    return out
end

local function snowflake()
    local strokes = {}
    for arm = 0, 5 do
        local a = arm * math.pi / 3
        local ca, sa = math.cos(a), math.sin(a)
        -- The arm, then two branches off it at two thirds out.
        strokes[#strokes + 1] = { { 0, 0 }, { ca, sa } }
        local bx, by = ca * 0.62, sa * 0.62
        local b1 = a + math.pi / 3
        local b2 = a - math.pi / 3
        strokes[#strokes + 1] = { { bx, by }, { bx + math.cos(b1) * 0.3, by + math.sin(b1) * 0.3 } }
        strokes[#strokes + 1] = { { bx, by }, { bx + math.cos(b2) * 0.3, by + math.sin(b2) * 0.3 } }
    end
    return strokes
end

local function candyCane()
    local s = arc(0.32, math.pi, 0.0, 12, 0.18, 0.58)
    s[#s + 1] = { 0.50, -0.9 }
    return s
end

local function shamrock()
    local strokes = {}
    for k = 0, 2 do
        local a = math.pi / 2 + k * 2 * math.pi / 3
        strokes[#strokes + 1] = circle(0.32, 16, math.cos(a) * 0.42, math.sin(a) * 0.42)
    end
    strokes[#strokes + 1] = { { 0.05, -0.1 }, { 0.15, -0.95 } }
    return strokes
end

local function pumpkin()
    local body = {}
    for i = 0, 32 do
        local t = i * 2 * math.pi / 32
        body[#body + 1] = { math.cos(t) * 0.95, math.sin(t) * 0.75 - 0.05 }
    end
    return {
        body,
        { { -0.08, 0.7 }, { -0.02, 0.95 }, { 0.12, 0.98 } },                 -- stem
        { { -0.55, 0.25 }, { -0.25, 0.25 }, { -0.4, 0.5 }, { -0.55, 0.25 } },   -- eye
        { { 0.25, 0.25 }, { 0.55, 0.25 }, { 0.4, 0.5 }, { 0.25, 0.25 } },       -- eye
        { { -0.6, -0.25 }, { -0.35, -0.45 }, { -0.2, -0.3 }, { 0.0, -0.5 }, { 0.2, -0.3 }, { 0.35, -0.45 }, { 0.6, -0.25 } }, -- mouth
    }
end

local function bat()
    return { {
        { 0, 0.1 }, { 0.2, 0.4 }, { 0.45, 0.25 }, { 0.75, 0.45 }, { 1.0, 0.1 }, { 0.8, -0.1 }, { 0.75, -0.4 },
        { 0.5, -0.25 }, { 0.3, -0.45 }, { 0.0, -0.3 }, { -0.3, -0.45 }, { -0.5, -0.25 }, { -0.75, -0.4 },
        { -0.8, -0.1 }, { -1.0, 0.1 }, { -0.75, 0.45 }, { -0.45, 0.25 }, { -0.2, 0.4 }, { 0, 0.1 },
    } }
end

local function tree()
    return {
        { { 0, 1 }, { 0.55, 0.3 }, { 0.3, 0.3 }, { 0.8, -0.4 }, { 0.45, -0.4 }, { 0.95, -0.85 }, { -0.95, -0.85 },
          { -0.45, -0.4 }, { -0.8, -0.4 }, { -0.3, 0.3 }, { -0.55, 0.3 }, { 0, 1 } },
        { { -0.15, -0.85 }, { -0.15, -1 }, { 0.15, -1 }, { 0.15, -0.85 } },
    }
end

local function bell()
    return {
        { { -0.3, 0.9 }, { -0.3, 0.6 }, { -0.75, -0.2 }, { -0.85, -0.5 }, { 0.85, -0.5 }, { 0.75, -0.2 }, { 0.3, 0.6 }, { 0.3, 0.9 }, { -0.3, 0.9 } },
        circle(0.16, 10, 0, -0.68),
    }
end

local function egg()
    local out = {}
    for i = 0, 32 do
        local t = i * 2 * math.pi / 32
        local y = math.sin(t)
        local w = 0.72 * (1 - 0.18 * y)
        out[#out + 1] = { math.cos(t) * w, y * 0.95 }
    end
    return { out, { { -0.5, 0.2 }, { -0.2, 0.0 }, { 0.2, 0.2 }, { 0.5, 0.0 } }, { { -0.5, -0.3 }, { -0.2, -0.5 }, { 0.2, -0.3 }, { 0.5, -0.5 } } }
end

local function menorah()
    local strokes = { { { -0.9, 0.0 }, { 0.9, 0.0 } }, { { 0, 0.0 }, { 0, -0.7 } }, { { -0.4, -0.9 }, { 0.4, -0.9 } } }
    for i = -4, 4 do
        local h = (i == 0) and 0.95 or 0.7
        strokes[#strokes + 1] = { { i * 0.22, 0.0 }, { i * 0.22, h } }
    end
    return strokes
end

local function wreath()
    return { circle(0.95, 32), circle(0.55, 24), { { -0.2, 0.95 }, { 0.0, 0.75 }, { 0.2, 0.95 }, { 0.0, 1.0 }, { -0.2, 0.95 } } }
end

local function flagStar()
    return { star(5, 1.0, 0.42) }
end

-- ---- More figures (0.2.0) ----

local function turkeyFig()
    local s = {}
    local cx, cy = 0.0, -0.45
    s[#s + 1] = arc(1.0, math.rad(15), math.rad(165), 20, cx, cy)          -- outer tail
    s[#s + 1] = arc(0.66, math.rad(15), math.rad(165), 14, cx, cy)         -- inner tail
    for _, deg in ipairs({ 15, 40, 65, 90, 115, 140, 165 }) do           -- feathers
        local a = math.rad(deg)
        s[#s + 1] = { { cx + math.cos(a) * 0.66, cy + math.sin(a) * 0.66 }, { cx + math.cos(a) * 1.0, cy + math.sin(a) * 1.0 } }
    end
    s[#s + 1] = circle(0.42, 24, cx, cy)                                   -- body
    s[#s + 1] = { { 0.3, -0.25 }, { 0.42, -0.08 }, { 0.5, 0.02 } }          -- neck
    s[#s + 1] = circle(0.15, 12, 0.56, 0.12)                               -- head
    s[#s + 1] = { { 0.7, 0.1 }, { 0.84, 0.06 }, { 0.7, 0.02 } }             -- beak
    s[#s + 1] = { { 0.62, -0.02 }, { 0.6, -0.16 } }                          -- wattle
    s[#s + 1] = { { -0.12, -0.86 }, { -0.12, -1.0 }, { -0.22, -1.0 } }
    s[#s + 1] = { { -0.12, -1.0 }, { -0.02, -1.0 } }
    s[#s + 1] = { { 0.14, -0.86 }, { 0.14, -1.0 }, { 0.04, -1.0 } }
    s[#s + 1] = { { 0.14, -1.0 }, { 0.24, -1.0 } }
    return s
end

local function reindeerHead()
    return {
        -- head and muzzle
        { { -0.3, 0.1 }, { -0.42, -0.3 }, { -0.3, -0.7 }, { 0.0, -0.95 }, { 0.3, -0.7 }, { 0.42, -0.3 }, { 0.3, 0.1 }, { 0.0, 0.2 }, { -0.3, 0.1 } },
        circle(0.09, 10, 0.0, -0.8),                                  -- the nose
        { { -0.16, -0.25 }, { -0.1, -0.2 } }, { { 0.16, -0.25 }, { 0.1, -0.2 } },   -- eyes
        -- ears
        { { -0.3, 0.1 }, { -0.62, 0.22 }, { -0.38, 0.28 } }, { { 0.3, 0.1 }, { 0.62, 0.22 }, { 0.38, 0.28 } },
        -- antlers
        { { -0.2, 0.2 }, { -0.3, 0.6 }, { -0.45, 0.95 } }, { { -0.3, 0.6 }, { -0.6, 0.72 } }, { { -0.25, 0.4 }, { -0.5, 0.5 } },
        { { 0.2, 0.2 }, { 0.3, 0.6 }, { 0.45, 0.95 } }, { { 0.3, 0.6 }, { 0.6, 0.72 } }, { { 0.25, 0.4 }, { 0.5, 0.5 } },
    }
end

local function santaHat()
    return {
        { { -0.9, -0.5 }, { -0.9, -0.85 }, { 0.6, -0.85 }, { 0.6, -0.5 }, { -0.9, -0.5 } },     -- brim
        { { -0.8, -0.5 }, { -0.2, 0.6 }, { 0.55, 0.9 }, { 0.5, -0.5 } },                        -- the cap
        circle(0.16, 12, 0.72, 0.84),                                                           -- pompom
    }
end

local function stocking()
    return {
        { { -0.45, 1.0 }, { -0.45, -0.1 }, { -0.9, -0.5 }, { -0.75, -0.9 }, { -0.2, -0.95 }, { 0.3, -0.5 }, { 0.3, 1.0 }, { -0.45, 1.0 } },
        { { -0.5, 0.65 }, { 0.35, 0.65 } },            -- the cuff
        { { -0.6, -0.55 }, { -0.2, -0.58 } },          -- the heel
    }
end

local function gingerbreadFig()
    return { {
        { 0, 0.98 }, { 0.3, 0.9 }, { 0.38, 0.62 }, { 0.22, 0.42 }, { 0.75, 0.3 }, { 0.9, 0.05 }, { 0.72, -0.05 }, { 0.3, 0.05 },
        { 0.28, -0.35 }, { 0.5, -0.9 }, { 0.3, -1.0 }, { 0.08, -0.55 }, { -0.08, -0.55 }, { -0.3, -1.0 }, { -0.5, -0.9 }, { -0.28, -0.35 },
        { -0.3, 0.05 }, { -0.72, -0.05 }, { -0.9, 0.05 }, { -0.75, 0.3 }, { -0.22, 0.42 }, { -0.38, 0.62 }, { -0.3, 0.9 }, { 0, 0.98 },
    },
        { { -0.12, 0.72 }, { -0.08, 0.72 } }, { { 0.08, 0.72 }, { 0.12, 0.72 } },          -- eyes
        { { -0.14, 0.56 }, { 0.0, 0.5 }, { 0.14, 0.56 } },                                  -- smile
        circle(0.05, 8, 0, 0.2), circle(0.05, 8, 0, -0.02), circle(0.05, 8, 0, -0.24),       -- buttons
    }
end

local function angel()
    return {
        circle(0.18, 14, 0, 0.72),                                                           -- head
        { { -0.22, 0.98 }, { 0.22, 0.98 } },                                                 -- halo
        { { -0.12, 0.56 }, { -0.5, -0.9 }, { 0.5, -0.9 }, { 0.12, 0.56 } },                  -- robe
        { { -0.14, 0.3 }, { -0.95, 0.72 }, { -0.9, 0.0 }, { -0.4, -0.25 } },                 -- wings
        { { 0.14, 0.3 }, { 0.95, 0.72 }, { 0.9, 0.0 }, { 0.4, -0.25 } },
    }
end

local function present()
    return {
        { { -0.8, 0.3 }, { -0.8, -0.9 }, { 0.8, -0.9 }, { 0.8, 0.3 }, { -0.8, 0.3 } },        -- box
        { { -0.9, 0.3 }, { -0.9, 0.6 }, { 0.9, 0.6 }, { 0.9, 0.3 } },                         -- lid
        { { 0, 0.6 }, { 0, -0.9 } },                                                           -- ribbon
        { { -0.8, -0.3 }, { 0.8, -0.3 } },
        { { 0, 0.6 }, { -0.35, 0.95 }, { -0.5, 0.75 }, { 0, 0.6 }, { 0.35, 0.95 }, { 0.5, 0.75 }, { 0, 0.6 } },   -- bow
    }
end

local function dreidelFig()
    return {
        { { -0.4, 0.35 }, { -0.4, -0.3 }, { 0, -0.85 }, { 0.4, -0.3 }, { 0.4, 0.35 }, { -0.4, 0.35 } },
        { { 0, 0.35 }, { 0, 0.95 } },
        { { -0.12, 0.95 }, { 0.12, 0.95 } },
        { { -0.15, 0.15 }, { 0.15, 0.15 }, { 0.15, -0.15 }, { -0.15, -0.15 }, { -0.15, 0.15 } },   -- the letter block
    }
end

local function starOfDavid()
    local a = {}
    for i = 0, 3 do local t = math.pi / 2 + i * 2 * math.pi / 3 a[#a + 1] = { math.cos(t) * 0.95, math.sin(t) * 0.95 } end
    local b = {}
    for i = 0, 3 do local t = -math.pi / 2 + i * 2 * math.pi / 3 b[#b + 1] = { math.cos(t) * 0.95, math.sin(t) * 0.95 } end
    return { a, b }
end

local function champagneGlass()
    return {
        { { -0.35, 0.95 }, { -0.28, -0.1 }, { 0, -0.3 }, { 0.28, -0.1 }, { 0.35, 0.95 }, { -0.35, 0.95 } },   -- flute
        { { 0, -0.3 }, { 0, -0.8 } }, { { -0.35, -0.9 }, { 0.35, -0.9 } },                                   -- stem and foot
        { { -0.3, 0.3 }, { 0.3, 0.3 } },                                                                       -- the fill line
        circle(0.04, 6, -0.1, 0.55), circle(0.04, 6, 0.12, 0.72), circle(0.04, 6, 0.02, 0.86),                -- bubbles
    }
end

local function clock()
    local s = { circle(0.95, 36) }
    for i = 0, 11 do
        local a = i * math.pi / 6
        local r1 = (i % 3 == 0) and 0.78 or 0.86
        s[#s + 1] = { { math.cos(a) * r1, math.sin(a) * r1 }, { math.cos(a) * 0.95, math.sin(a) * 0.95 } }
    end
    s[#s + 1] = { { 0, -0.1 }, { 0, 0.62 } }           -- both hands on twelve
    s[#s + 1] = { { -0.06, 0 }, { 0.06, 0.4 } }
    return s
end

local function cupid()
    local h = heart()
    return { h, { { -1.0, -0.55 }, { 0.9, 0.55 } }, { { 0.9, 0.55 }, { 0.7, 0.58 } }, { { 0.9, 0.55 }, { 0.82, 0.38 } },
        { { -1.0, -0.55 }, { -0.95, -0.72 } }, { { -1.0, -0.55 }, { -0.82, -0.48 } } }
end

local function rose()
    local s = {}
    local spiral = {}
    for i = 0, 24 do
        local t = i / 24
        local a = t * 3 * math.pi
        local r = 0.08 + t * 0.4
        spiral[#spiral + 1] = { math.cos(a) * r, 0.45 + math.sin(a) * r * 0.85 }
    end
    s[#s + 1] = spiral
    s[#s + 1] = { { -0.5, 0.2 }, { -0.3, -0.1 }, { 0.3, -0.1 }, { 0.5, 0.2 } }                     -- the calyx
    s[#s + 1] = { { 0, -0.1 }, { 0.05, -1.0 } }                                                     -- stem
    s[#s + 1] = { { 0.03, -0.55 }, { 0.35, -0.5 }, { 0.5, -0.7 }, { 0.2, -0.75 }, { 0.03, -0.55 } }  -- leaf
    return s
end

local function rainbowPot()
    local s = {}
    for _, r in ipairs({ 0.95, 0.78, 0.61 }) do s[#s + 1] = arc(r, 0, math.pi, 18, 0, -0.35) end
    s[#s + 1] = { { -0.3, -0.35 }, { -0.38, -0.95 }, { 0.38, -0.95 }, { 0.3, -0.35 } }               -- the pot
    s[#s + 1] = { { -0.4, -0.35 }, { 0.4, -0.35 } }
    s[#s + 1] = { { -0.25, -0.25 }, { -0.1, -0.15 }, { 0.1, -0.15 }, { 0.25, -0.25 } }               -- gold
    return s
end

local function leprechaunHat()
    return {
        { { -0.95, -0.5 }, { 0.95, -0.5 } },                                                      -- brim
        { { -0.6, -0.5 }, { -0.5, 0.9 }, { 0.5, 0.9 }, { 0.6, -0.5 } },                            -- crown
        { { -0.58, -0.15 }, { 0.58, -0.15 } }, { { -0.6, -0.5 }, { -0.58, -0.15 } },                -- band
        { { -0.15, -0.05 }, { 0.15, -0.05 }, { 0.15, -0.3 }, { -0.15, -0.3 }, { -0.15, -0.05 } },   -- buckle
    }
end

local function bunnyFig()
    return {
        circle(0.5, 24, 0, -0.45),                                                                 -- head
        { { -0.4, -0.05 }, { -0.5, 0.5 }, { -0.35, 0.98 }, { -0.15, 0.6 }, { -0.1, 0.02 } },         -- ears
        { { 0.4, -0.05 }, { 0.5, 0.5 }, { 0.35, 0.98 }, { 0.15, 0.6 }, { 0.1, 0.02 } },
        { { -0.22, -0.3 }, { -0.16, -0.3 } }, { { 0.16, -0.3 }, { 0.22, -0.3 } },                   -- eyes
        { { -0.08, -0.5 }, { 0.08, -0.5 }, { 0, -0.6 }, { -0.08, -0.5 } },                           -- nose
        { { -0.42, -0.5 }, { -0.1, -0.56 } }, { { 0.42, -0.5 }, { 0.1, -0.56 } },                    -- whiskers
        { { -0.4, -0.65 }, { -0.1, -0.62 } }, { { 0.4, -0.65 }, { 0.1, -0.62 } },
    }
end

local function chickFig()
    return {
        circle(0.42, 24, 0, -0.35), circle(0.3, 18, 0.1, 0.35),
        { { 0.38, 0.35 }, { 0.6, 0.28 }, { 0.38, 0.22 } },                                         -- beak
        { { 0.18, 0.46 }, { 0.22, 0.46 } },                                                        -- eye
        { { -0.4, -0.2 }, { -0.75, 0.05 }, { -0.55, -0.45 } },                                       -- wing
        { { -0.15, -0.76 }, { -0.15, -0.98 } }, { { -0.28, -0.98 }, { -0.02, -0.98 } },               -- feet
        { { 0.15, -0.76 }, { 0.15, -0.98 } }, { { 0.02, -0.98 }, { 0.28, -0.98 } },
    }
end

local function tulip()
    return {
        { { -0.45, 0.1 }, { -0.5, 0.75 }, { -0.25, 0.5 }, { 0, 0.85 }, { 0.25, 0.5 }, { 0.5, 0.75 }, { 0.45, 0.1 }, { 0.2, -0.1 }, { -0.2, -0.1 }, { -0.45, 0.1 } },
        { { 0, -0.1 }, { 0, -1.0 } },
        { { 0, -0.6 }, { -0.45, -0.5 }, { -0.5, -0.85 }, { -0.05, -0.8 } },
    }
end

local function flag()
    local s = {
        { { -0.95, 0.65 }, { 0.95, 0.65 }, { 0.95, -0.65 }, { -0.95, -0.65 }, { -0.95, 0.65 } },
        { { -0.95, 0.1 }, { -0.2, 0.1 }, { -0.2, 0.65 } },                                           -- canton
    }
    for _, y in ipairs({ 0.45, 0.28, -0.1, -0.28, -0.46 }) do
        local x0 = (y > 0.1) and -0.2 or -0.95
        s[#s + 1] = { { x0, y }, { 0.95, y } }
    end
    s[#s + 1] = star(5, 0.17, 0.07)
    for i, p in ipairs(s[#s]) do s[#s][i] = { p[1] - 0.58, p[2] + 0.38 } end
    return s
end

local function burst()
    local s = {}
    for i = 0, 11 do
        local a = i * math.pi / 6
        local r0, r1 = (i % 2 == 0) and 0.25 or 0.4, (i % 2 == 0) and 1.0 or 0.75
        s[#s + 1] = { { math.cos(a) * r0, math.sin(a) * r0 }, { math.cos(a) * r1, math.sin(a) * r1 } }
    end
    s[#s + 1] = circle(0.12, 10)
    return s
end

local function ghostFig()
    return {
        { { -0.6, -0.95 }, { -0.4, -0.75 }, { -0.2, -0.95 }, { 0, -0.75 }, { 0.2, -0.95 }, { 0.4, -0.75 }, { 0.6, -0.95 },
          { 0.6, 0.1 }, { 0.45, 0.65 }, { 0, 0.95 }, { -0.45, 0.65 }, { -0.6, 0.1 }, { -0.6, -0.95 } },
        circle(0.08, 8, -0.2, 0.35), circle(0.08, 8, 0.2, 0.35),
        { { -0.1, 0.0 }, { -0.08, -0.2 }, { 0.08, -0.2 }, { 0.1, 0.0 }, { -0.1, 0.0 } },
    }
end

local function web()
    local s = {}
    local n = 8
    for i = 0, n - 1 do
        local a = i * 2 * math.pi / n
        s[#s + 1] = { { 0, 0 }, { math.cos(a) * 1.0, math.sin(a) * 1.0 } }
    end
    for _, r in ipairs({ 0.3, 0.55, 0.8 }) do
        local ring = {}
        for i = 0, n do
            local a = i * 2 * math.pi / n
            local mid = a + math.pi / n
            ring[#ring + 1] = { math.cos(a) * r, math.sin(a) * r }
            if i < n then ring[#ring + 1] = { math.cos(mid) * r * 0.88, math.sin(mid) * r * 0.88 } end
        end
        s[#s + 1] = ring
    end
    return s
end

local function skull()
    return {
        { { -0.7, 0.2 }, { -0.55, 0.75 }, { 0, 0.98 }, { 0.55, 0.75 }, { 0.7, 0.2 }, { 0.5, -0.3 }, { 0.5, -0.6 }, { 0.3, -0.6 }, { 0.3, -0.95 },
          { -0.3, -0.95 }, { -0.3, -0.6 }, { -0.5, -0.6 }, { -0.5, -0.3 }, { -0.7, 0.2 } },
        circle(0.18, 12, -0.28, 0.22), circle(0.18, 12, 0.28, 0.22),
        { { -0.1, -0.1 }, { 0, -0.3 }, { 0.1, -0.1 } },
        { { -0.2, -0.6 }, { -0.2, -0.85 } }, { { 0, -0.6 }, { 0, -0.85 } }, { { 0.2, -0.6 }, { 0.2, -0.85 } },
    }
end

local function witchHat()
    return {
        { { -1.0, -0.6 }, { 1.0, -0.6 } },
        { { -0.6, -0.6 }, { -0.35, 0.1 }, { 0.3, 0.95 }, { 0.45, 0.3 }, { 0.6, -0.6 } },
        { { -0.5, -0.3 }, { 0.55, -0.3 } },
        { { -0.08, -0.32 }, { 0.12, -0.32 }, { 0.12, -0.52 }, { -0.08, -0.52 }, { -0.08, -0.32 } },
    }
end

local function catFig()
    return {
        { { -0.45, 0.35 }, { -0.5, 0.9 }, { -0.25, 0.6 }, { 0.25, 0.6 }, { 0.5, 0.9 }, { 0.45, 0.35 }, { 0.3, 0.1 }, { 0.55, -0.4 }, { 0.5, -0.95 },
          { -0.5, -0.95 }, { -0.55, -0.4 }, { -0.3, 0.1 }, { -0.45, 0.35 } },
        { { 0.5, -0.95 }, { 0.85, -0.9 }, { 0.98, -0.5 }, { 0.85, -0.1 } },                        -- tail
        { { -0.22, 0.32 }, { -0.14, 0.36 } }, { { 0.14, 0.36 }, { 0.22, 0.32 } },                   -- eyes
        { { -0.4, 0.2 }, { -0.1, 0.16 } }, { { 0.4, 0.2 }, { 0.1, 0.16 } },                          -- whiskers
        { { -0.4, 0.06 }, { -0.1, 0.1 } }, { { 0.4, 0.06 }, { 0.1, 0.1 } },
    }
end

local function mapleLeaf()
    return { {
        { 0, 1.0 }, { 0.15, 0.6 }, { 0.4, 0.75 }, { 0.3, 0.3 }, { 0.75, 0.45 }, { 0.65, 0.15 }, { 0.95, 0.0 }, { 0.6, -0.3 }, { 0.75, -0.5 },
        { 0.25, -0.4 }, { 0.1, -0.6 }, { 0.1, -1.0 }, { -0.1, -1.0 }, { -0.1, -0.6 }, { -0.25, -0.4 }, { -0.75, -0.5 }, { -0.6, -0.3 }, { -0.95, 0.0 },
        { -0.65, 0.15 }, { -0.75, 0.45 }, { -0.3, 0.3 }, { -0.4, 0.75 }, { -0.15, 0.6 }, { 0, 1.0 },
    } }
end

local function pilgrimHat()
    return {
        { { -1.0, -0.55 }, { 1.0, -0.55 } },
        { { -0.65, -0.55 }, { -0.5, 0.9 }, { 0.5, 0.9 }, { 0.65, -0.55 } },
        { { -0.62, -0.2 }, { 0.62, -0.2 } }, { { -0.65, -0.55 }, { -0.62, -0.2 } },
        { { -0.18, -0.12 }, { 0.18, -0.12 }, { 0.18, -0.45 }, { -0.18, -0.45 }, { -0.18, -0.12 } },
    }
end

local function acornFig()
    local s = {}
    s[#s + 1] = arc(0.62, math.rad(200), math.rad(340), 18, 0, -0.15)                            -- the nut
    s[#s + 1] = { { -0.58, -0.36 }, { -0.4, 0.15 }, { 0.4, 0.15 }, { 0.58, -0.36 } }
    s[#s + 1] = { { -0.72, 0.15 }, { -0.6, 0.6 }, { 0, 0.8 }, { 0.6, 0.6 }, { 0.72, 0.15 }, { -0.72, 0.15 } }   -- the cap
    s[#s + 1] = { { 0, 0.8 }, { 0.1, 1.0 } }
    return s
end

local function balloon()
    local s = {}
    local o = {}
    for i = 0, 28 do
        local t = i * 2 * math.pi / 28
        o[#o + 1] = { math.cos(t) * 0.55, 0.3 + math.sin(t) * 0.65 }
    end
    s[#s + 1] = o
    s[#s + 1] = { { -0.08, -0.35 }, { 0.08, -0.35 }, { 0, -0.25 }, { -0.08, -0.35 } }
    s[#s + 1] = { { 0, -0.35 }, { -0.1, -0.6 }, { 0.1, -0.85 }, { 0, -1.0 } }
    return s
end

local function musicNote()
    return {
        circle(0.22, 14, -0.45, -0.7),
        { { -0.25, -0.65 }, { -0.25, 0.9 }, { 0.5, 0.65 }, { 0.5, 0.0 } },
        { { 0.5, 0.65 }, { 0.5, -0.4 } }, circle(0.22, 14, 0.3, -0.45),
        { { -0.25, 0.55 }, { 0.5, 0.3 } },
    }
end

local function candleFig()
    return {
        { { -0.3, -1.0 }, { -0.3, 0.3 }, { 0.3, 0.3 }, { 0.3, -1.0 }, { -0.3, -1.0 } },
        { { 0, 0.3 }, { 0, 0.45 } },
        { { 0, 0.45 }, { 0.2, 0.65 }, { 0, 1.0 }, { -0.2, 0.65 }, { 0, 0.45 } },
        { { -0.3, -0.2 }, { -0.1, -0.35 } },
    }
end

local function moon()
    -- A crescent: the outer circle's left side, closed by the left side
    -- of a second circle pushed to the right.
    local out = {}
    for i = 0, 20 do
        local a = math.rad(63.4 + i * (296.6 - 63.4) / 20)
        out[#out + 1] = { math.cos(a) * 0.95, math.sin(a) * 0.95 }
    end
    for i = 0, 16 do
        local a = math.rad(271.7 - i * (271.7 - 88.3) / 16)
        out[#out + 1] = { 0.4 + math.cos(a) * 0.85, math.sin(a) * 0.85 }
    end
    return { out }
end

local function snowmanFig()
    return {
        circle(0.42, 24, 0, -0.55), circle(0.3, 18, 0, 0.1), circle(0.22, 14, 0, 0.55),
        { { -0.35, 0.77 }, { 0.35, 0.77 } }, { { -0.22, 0.77 }, { -0.2, 1.0 }, { 0.2, 1.0 }, { 0.22, 0.77 } },
        { { -0.08, 0.6 }, { -0.04, 0.6 } }, { { 0.04, 0.6 }, { 0.08, 0.6 } },
        { { 0, 0.52 }, { 0.3, 0.48 } },
        { { -0.3, 0.1 }, { -0.9, 0.4 } }, { { 0.3, 0.1 }, { 0.9, 0.4 } },
        circle(0.04, 6, 0, 0.15), circle(0.04, 6, 0, 0.0),
    }
end

local function bow()
    return {
        { { 0, 0 }, { -0.5, 0.5 }, { -0.95, 0.35 }, { -0.85, -0.3 }, { -0.4, -0.35 }, { 0, 0 } },
        { { 0, 0 }, { 0.5, 0.5 }, { 0.95, 0.35 }, { 0.85, -0.3 }, { 0.4, -0.35 }, { 0, 0 } },
        circle(0.14, 10),
        { { -0.08, -0.12 }, { -0.35, -0.95 }, { -0.1, -0.8 } }, { { 0.08, -0.12 }, { 0.35, -0.95 }, { 0.1, -0.8 } },
    }
end

-- Digits, for "2027" over a door or an age on a birthday wall: hang
-- them one at a time and the align tool spaces the row.
local DIGITS = {
    [0] = { { { -0.5, 0.55 }, { -0.3, 0.9 }, { 0.3, 0.9 }, { 0.5, 0.55 }, { 0.5, -0.55 }, { 0.3, -0.9 }, { -0.3, -0.9 }, { -0.5, -0.55 }, { -0.5, 0.55 } } },
    [1] = { { { -0.3, 0.6 }, { 0.05, 0.9 }, { 0.05, -0.9 } }, { { -0.3, -0.9 }, { 0.4, -0.9 } } },
    [2] = { { { -0.5, 0.55 }, { -0.3, 0.9 }, { 0.3, 0.9 }, { 0.5, 0.55 }, { 0.5, 0.2 }, { -0.5, -0.9 }, { 0.5, -0.9 } } },
    [3] = { { { -0.5, 0.9 }, { 0.5, 0.9 }, { 0.0, 0.15 }, { 0.3, 0.15 }, { 0.5, -0.2 }, { 0.5, -0.55 }, { 0.3, -0.9 }, { -0.3, -0.9 }, { -0.5, -0.6 } } },
    [4] = { { { 0.3, -0.9 }, { 0.3, 0.9 }, { -0.5, -0.3 }, { 0.5, -0.3 } } },
    [5] = { { { 0.5, 0.9 }, { -0.45, 0.9 }, { -0.5, 0.1 }, { 0.2, 0.2 }, { 0.5, -0.1 }, { 0.5, -0.55 }, { 0.25, -0.9 }, { -0.3, -0.9 }, { -0.5, -0.6 } } },
    [6] = { { { 0.4, 0.9 }, { -0.2, 0.6 }, { -0.5, 0.0 }, { -0.5, -0.55 }, { -0.25, -0.9 }, { 0.25, -0.9 }, { 0.5, -0.55 }, { 0.5, -0.15 }, { 0.25, 0.15 }, { -0.25, 0.15 }, { -0.5, -0.15 } } },
    [7] = { { { -0.5, 0.9 }, { 0.5, 0.9 }, { -0.1, -0.9 } } },
    [8] = { circle(0.4, 18, 0, 0.48), circle(0.45, 20, 0, -0.45) },
    [9] = { { { -0.4, -0.9 }, { 0.2, -0.6 }, { 0.5, 0.0 }, { 0.5, 0.55 }, { 0.25, 0.9 }, { -0.25, 0.9 }, { -0.5, 0.55 }, { -0.5, 0.15 }, { -0.25, -0.15 }, { 0.25, -0.15 }, { 0.5, 0.15 } } },
}

-- Which holiday each belongs to decides where it shows in the panel; a
-- figure can be used with any holiday's palette.
Figures.List = {
    { name = 'star',       label = 'Star',         size = 1.2, holidays = { 'christmas', 'july4', 'newyear', 'party' },  strokes = flagStar() },
    { name = 'snowflake',  label = 'Snowflake',    size = 1.4, holidays = { 'christmas', 'newyear', 'hanukkah' }, strokes = snowflake() },
    { name = 'tree',       label = 'Tree',         size = 1.6, holidays = { 'christmas' },        strokes = tree() },
    { name = 'candy_cane', label = 'Candy cane',   size = 1.2, holidays = { 'christmas' },        strokes = { candyCane() } },
    { name = 'bell',       label = 'Bell',         size = 1.0, holidays = { 'christmas', 'newyear' }, strokes = bell() },
    { name = 'wreath',     label = 'Wreath',       size = 1.2, holidays = { 'christmas' },        strokes = wreath() },
    { name = 'menorah',    label = 'Menorah',      size = 1.4, holidays = { 'hanukkah' },         strokes = menorah() },
    { name = 'heart',      label = 'Heart',        size = 1.0, holidays = { 'valentines', 'party' }, strokes = { heart() } },
    { name = 'shamrock',   label = 'Shamrock',     size = 1.1, holidays = { 'stpatricks' },       strokes = shamrock() },
    { name = 'egg',        label = 'Egg',          size = 1.0, holidays = { 'easter' },           strokes = egg() },
    { name = 'pumpkin',    label = 'Pumpkin',      size = 1.2, holidays = { 'halloween' },        strokes = pumpkin() },
    { name = 'bat',        label = 'Bat',          size = 1.4, holidays = { 'halloween' },        strokes = bat() },
    { name = 'circle',     label = 'Ring',         size = 1.0, holidays = { 'party', 'newyear', 'thanksgiving' }, strokes = { circle(1.0, 32) } },
    -- 0.2.0
    { name = 'snowman',    label = 'Snowman',      size = 1.6, holidays = { 'christmas' },        strokes = snowmanFig() },
    { name = 'reindeer',   label = 'Reindeer',     size = 1.4, holidays = { 'christmas' },        strokes = reindeerHead() },
    { name = 'santa_hat',  label = 'Santa hat',    size = 1.0, holidays = { 'christmas' },        strokes = santaHat() },
    { name = 'stocking',   label = 'Stocking',     size = 1.2, holidays = { 'christmas' },        strokes = stocking() },
    { name = 'gingerbread', label = 'Gingerbread man', size = 1.4, holidays = { 'christmas' },    strokes = gingerbreadFig() },
    { name = 'angel',      label = 'Angel',        size = 1.4, holidays = { 'christmas', 'easter' }, strokes = angel() },
    { name = 'present',    label = 'Present',      size = 1.0, holidays = { 'christmas', 'hanukkah', 'party' }, strokes = present() },
    { name = 'bow',        label = 'Bow',          size = 1.0, holidays = { 'christmas', 'valentines', 'party' }, strokes = bow() },
    { name = 'candle',     label = 'Candle',       size = 1.0, holidays = { 'christmas', 'hanukkah', 'thanksgiving' }, strokes = candleFig() },
    { name = 'dreidel',    label = 'Dreidel',      size = 1.0, holidays = { 'hanukkah' },         strokes = dreidelFig() },
    { name = 'star_david', label = 'Star of David', size = 1.2, holidays = { 'hanukkah' },        strokes = starOfDavid() },
    { name = 'champagne',  label = 'Champagne glass', size = 1.2, holidays = { 'newyear', 'party', 'valentines' }, strokes = champagneGlass() },
    { name = 'clock',      label = 'Midnight clock', size = 1.2, holidays = { 'newyear' },        strokes = clock() },
    { name = 'burst',      label = 'Firework burst', size = 1.4, holidays = { 'newyear', 'july4', 'party' }, strokes = burst() },
    { name = 'cupid',      label = 'Heart and arrow', size = 1.2, holidays = { 'valentines' },    strokes = cupid() },
    { name = 'rose',       label = 'Rose',         size = 1.2, holidays = { 'valentines' },       strokes = rose() },
    { name = 'rainbow',    label = 'Rainbow and pot of gold', size = 1.4, holidays = { 'stpatricks' }, strokes = rainbowPot() },
    { name = 'leprechaun_hat', label = 'Leprechaun hat', size = 1.0, holidays = { 'stpatricks' }, strokes = leprechaunHat() },
    { name = 'bunny',      label = 'Bunny',        size = 1.2, holidays = { 'easter' },           strokes = bunnyFig() },
    { name = 'chick',      label = 'Chick',        size = 1.0, holidays = { 'easter' },           strokes = chickFig() },
    { name = 'tulip',      label = 'Tulip',        size = 1.2, holidays = { 'easter', 'valentines' }, strokes = tulip() },
    { name = 'flag',       label = 'US flag',      size = 1.2, holidays = { 'july4' },            strokes = flag() },
    { name = 'ghost',      label = 'Ghost',        size = 1.4, holidays = { 'halloween' },        strokes = ghostFig() },
    { name = 'web',        label = 'Spider web',   size = 1.6, holidays = { 'halloween' },        strokes = web() },
    { name = 'skull',      label = 'Skull',        size = 1.2, holidays = { 'halloween' },        strokes = skull() },
    { name = 'witch_hat',  label = 'Witch hat',    size = 1.2, holidays = { 'halloween' },        strokes = witchHat() },
    { name = 'cat',        label = 'Black cat',    size = 1.2, holidays = { 'halloween' },        strokes = catFig() },
    { name = 'moon',       label = 'Crescent moon', size = 1.2, holidays = { 'halloween', 'party' }, strokes = moon() },
    { name = 'turkey',     label = 'Turkey',       size = 1.4, holidays = { 'thanksgiving' },     strokes = turkeyFig() },
    { name = 'leaf',       label = 'Maple leaf',   size = 1.2, holidays = { 'thanksgiving' },     strokes = mapleLeaf() },
    { name = 'pilgrim_hat', label = 'Pilgrim hat', size = 1.0, holidays = { 'thanksgiving' },     strokes = pilgrimHat() },
    { name = 'acorn',      label = 'Acorn',        size = 1.0, holidays = { 'thanksgiving' },     strokes = acornFig() },
    { name = 'balloon',    label = 'Balloon',      size = 1.2, holidays = { 'party', 'newyear' }, strokes = balloon() },
    { name = 'note',       label = 'Music note',   size = 1.2, holidays = { 'party' },            strokes = musicNote() },
    -- 0.3.0
    { name = 'cross',      label = 'Cross',        size = 1.2, holidays = { 'funeral', 'memorialday', 'easter' }, strokes = { { { 0, 1 }, { 0, -1 } }, { { -0.6, 0.45 }, { 0.6, 0.45 } } } },
    { name = 'dove',       label = 'Dove',         size = 1.0, holidays = { 'funeral', 'wedding', 'easter' }, strokes = {
        { { -0.9, -0.1 }, { -0.5, 0.1 }, { -0.1, 0.0 }, { 0.3, -0.2 }, { 0.7, -0.1 }, { 0.95, 0.05 }, { 0.75, 0.15 } },
        { { -0.1, 0.0 }, { 0.1, 0.6 }, { 0.5, 0.95 }, { 0.55, 0.5 }, { 0.3, -0.2 } },
        { { -0.9, -0.1 }, { -1.0, -0.35 }, { -0.6, -0.3 } }, { { 0.78, 0.1 }, { 0.8, 0.12 } } } },
    { name = 'lily',       label = 'Lily',         size = 1.0, holidays = { 'funeral', 'easter' }, strokes = {
        { { -0.5, 0.9 }, { -0.2, 0.3 }, { 0, -0.2 }, { 0.2, 0.3 }, { 0.5, 0.9 } }, { { -0.9, 0.5 }, { -0.35, 0.1 }, { 0, -0.2 } }, { { 0.9, 0.5 }, { 0.35, 0.1 }, { 0, -0.2 } },
        { { 0, -0.2 }, { 0, -1.0 } }, { { 0, -0.65 }, { -0.4, -0.5 } } } },
    { name = 'rings',      label = 'Wedding rings', size = 1.0, holidays = { 'wedding' }, strokes = { circle(0.5, 24, -0.3, 0.1), circle(0.5, 24, 0.3, -0.1), circle(0.08, 8, -0.3, 0.62) } },
    { name = 'cake',       label = 'Cake',         size = 1.2, holidays = { 'birthday', 'wedding', 'party' }, strokes = {
        { { -0.9, -0.3 }, { -0.9, -0.9 }, { 0.9, -0.9 }, { 0.9, -0.3 }, { -0.9, -0.3 } }, { { -0.55, -0.3 }, { -0.55, 0.3 }, { 0.55, 0.3 }, { 0.55, -0.3 } },
        { { -0.25, 0.3 }, { -0.25, 0.7 } }, { { 0, 0.3 }, { 0, 0.75 } }, { { 0.25, 0.3 }, { 0.25, 0.7 } },
        { { -0.25, 0.7 }, { -0.2, 0.9 }, { -0.3, 0.9 }, { -0.25, 0.7 } }, { { 0, 0.75 }, { 0.05, 0.95 }, { -0.05, 0.95 }, { 0, 0.75 } }, { { 0.25, 0.7 }, { 0.3, 0.9 }, { 0.2, 0.9 }, { 0.25, 0.7 } } } },
    { name = 'hardhat',    label = 'Hard hat',     size = 1.0, holidays = { 'laborday' }, strokes = { arc(0.8, 0, math.pi, 16, 0, -0.3), { { -1.0, -0.3 }, { 1.0, -0.3 } }, { { -0.25, -0.3 }, { -0.25, 0.4 } }, { { 0.25, -0.3 }, { 0.25, 0.4 } } } },
    { name = 'digit_0', label = '0', size = 1.0, holidays = { 'newyear', 'birthday', 'party' }, strokes = DIGITS[0] },
    { name = 'digit_1', label = '1', size = 1.0, holidays = { 'newyear', 'birthday', 'party' }, strokes = DIGITS[1] },
    { name = 'digit_2', label = '2', size = 1.0, holidays = { 'newyear', 'birthday', 'party' }, strokes = DIGITS[2] },
    { name = 'digit_3', label = '3', size = 1.0, holidays = { 'newyear', 'birthday', 'party' }, strokes = DIGITS[3] },
    { name = 'digit_4', label = '4', size = 1.0, holidays = { 'newyear', 'birthday', 'party' }, strokes = DIGITS[4] },
    { name = 'digit_5', label = '5', size = 1.0, holidays = { 'newyear', 'birthday', 'party' }, strokes = DIGITS[5] },
    { name = 'digit_6', label = '6', size = 1.0, holidays = { 'newyear', 'birthday', 'party' }, strokes = DIGITS[6] },
    { name = 'digit_7', label = '7', size = 1.0, holidays = { 'newyear', 'birthday', 'party' }, strokes = DIGITS[7] },
    { name = 'digit_8', label = '8', size = 1.0, holidays = { 'newyear', 'birthday', 'party' }, strokes = DIGITS[8] },
    { name = 'digit_9', label = '9', size = 1.0, holidays = { 'newyear', 'birthday', 'party' }, strokes = DIGITS[9] },
}

function Figures.Get(name)
    for _, f in ipairs(Figures.List) do
        if f.name == name then return f end
    end
    return nil
end

--- Figures offered for a holiday, in list order.
function Figures.For(holiday)
    local out = {}
    for _, f in ipairs(Figures.List) do
        for _, h in ipairs(f.holidays) do
            if h == holiday then out[#out + 1] = f break end
        end
    end
    return out
end

--- Projects a figure onto a wall. `origin` is the aimed point, `right`
--- and `up` unit vectors in the wall's plane, `size` the figure's height
--- in meters. Returns points (flat list) and breaks (set of indices
--- after which the string lifts off the wall).
function Figures.Project(fig, origin, right, up, size)
    local points, breaks = {}, {}
    local half = size * 0.5
    for _, stroke in ipairs(fig.strokes) do
        for _, p in ipairs(stroke) do
            local sx, sy = p[1] * half, p[2] * half
            points[#points + 1] = {
                x = origin.x + right.x * sx + up.x * sy,
                y = origin.y + right.y * sx + up.y * sy,
                z = origin.z + right.z * sx + up.z * sy,
            }
        end
        breaks[#points] = true
    end
    breaks[#points] = nil     -- the last stroke needs no break after it
    return points, breaks
end
