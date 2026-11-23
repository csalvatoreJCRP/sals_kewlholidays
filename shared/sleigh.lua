-- Santa's sleigh and the New Year's ball drop: what they are made of, how
-- their settings are cleaned (the server and the panel follow the same
-- rules), and the path of Santa's flight, which the server and every
-- client work out the same way from the same numbers.
--
-- THE SLEIGH
-- Our own sleigh model (stream/sk_santa_sleigh.ydr: red lacquer, gold
-- scrollwork and runners, a green velvet seat, lanterns, fairy lights)
-- pulled by a team of the game's own deer, with antlers, in pairs. The
-- lead deer can wear a red nose. A sleigh record is a prop record whose
-- `sleigh` table describes its team; a sleigh placed from the Props tab
-- has no table and no team until one is given to it in the Edit list.
--
-- Up to 1.5.0 the sleigh was the game's own prop from the 2023 winter
-- update, which turned out to be a wreck (splintered boards, a broken
-- runner) and needed game build 3095. Ours works on any build; a sleigh
-- placed with the old model becomes the new one when the server loads it.
--
-- The model keeps the old one's layout: its long axis is x and its FRONT,
-- the curled runner tips, is -x; +y is its right; its origin is on the
-- ground. A deer's origin is 1.51 m above its hooves and it faces +y, so a
-- deer in front of the sleigh is turned +90 degrees. The numbers below
-- are the model's own (tools/build-sleigh.py prints them).
--
-- THE BALL DROP
-- A lit ball on a pole, drawn (no model): a shape record named
-- 'balldrop' whose size is the pole's height and whose `drop` table holds
-- the ball's size, colors, pattern and how long the drop takes. During the
-- last seconds of a countdown at its location the ball slides down the
-- pole and lands on zero.

Sleigh = {}

Sleigh.Model = 'sk_santa_sleigh'
Sleigh.OldModel = 'm23_2_prop_m32_sleigh_01a'     -- the game's wrecked sleigh, used up to 1.5.0
Sleigh.Deer = 'a_c_deer'

-- The team, in the sleigh's own space (x toward its back, y to its right, z up).
Sleigh.FrontX     = -1.65      -- the front of the runner curls
-- The traces start at the bar between the runner curls.
Sleigh.TraceX, Sleigh.TraceY, Sleigh.TraceZ = -1.61, 0.42, 0.42
-- Where a driver's hips belong: on the seat cushion, clear of its back.
-- Two sit side by side, so the sleigh is centered on the ride vehicle.
Sleigh.SeatX      = 0.47
Sleigh.DeerZ      = 1.53       -- a deer's origin above the ground
Sleigh.PairWidth  = 0.55       -- each deer this far either side of the middle
Sleigh.FirstPair  = 1.0        -- the first pair's middle is this far past the front
Sleigh.PairStep   = 2.1        -- and each next pair this much further
Sleigh.MaxPairs   = 4

-- Deer looks: component 8 drawable 1 is the antlers (some spawn without);
-- component 0's three textures are tan, white and dark brown.
Sleigh.AntlerComponent = 8
Sleigh.AntlerDrawable = 1
Sleigh.Coats = { mixed = { 0, 2 }, tan = { 0 }, brown = { 2 }, white = { 1 } }
Sleigh.CoatOrder = { 'mixed', 'tan', 'brown', 'white' }

-- What a parked team does, and the gaits a moving one runs through.
Sleigh.Poses = { 'stand', 'graze', 'prance' }
Sleigh.Anims = {
    stand  = { 'creatures@deer@move', 'idle' },
    graze  = { 'creatures@deer@amb@world_deer_grazing@base', 'base' },
    prance = { 'creatures@deer@move', 'trot' },
    walk   = { 'creatures@deer@move', 'walk' },
    trot   = { 'creatures@deer@move', 'trot' },
    canter = { 'creatures@deer@move', 'canter' },
    gallop = { 'creatures@deer@move', 'gallop' },
}

-- What rides in the sleigh when "presents" is on (sleigh space; heading in
-- degrees): one model of our own, made to fit: Santa's sack, a stack of
-- presents and a teddy bear behind the seat, two presents in the footwell
-- clear of the driver's feet. NOT the game's 2023 "gift box" props: the
-- smallest of those is a meter across and the large one 2.5 m, and three
-- of them buried the sleigh and its rider (1.5.0 did that).
Sleigh.Gifts = 'sk_santa_gifts'
Sleigh.Presents = {
    { model = Sleigh.Gifts, x = 0.0, y = 0.0, z = 0.0, h = 0.0 },
}

--- Where deer `side` (-1 right, 1 left) of pair `pair` stands, in the
--- sleigh's space. Pair 1 is the one nearest the sleigh.
function Sleigh.DeerOffset(pair, side)
    return Sleigh.FrontX - Sleigh.FirstPair - (pair - 1) * Sleigh.PairStep, side * Sleigh.PairWidth, Sleigh.DeerZ
end

local function bool(v, default)
    if v == nil then return default end
    return v == true
end

--- A clean team: pairs 1..4, a coat, the red nose, what the team does
--- while parked, whether players may ride it, and presents in the back.
function Sleigh.Clean(t)
    t = type(t) == 'table' and t or {}
    local pairs_ = math.floor(tonumber(t.pairs) or 2)
    if pairs_ < 1 then pairs_ = 1 elseif pairs_ > Sleigh.MaxPairs then pairs_ = Sleigh.MaxPairs end
    local pose = 'stand'
    for _, p in ipairs(Sleigh.Poses) do if t.pose == p then pose = p end end
    return {
        pairs    = pairs_,
        coat     = Sleigh.Coats[t.coat] and t.coat or 'mixed',
        nose     = bool(t.nose, true),
        pose     = pose,
        ride     = bool(t.ride, true),
        presents = bool(t.presents, true),
    }
end

--- The coat texture of deer `i` (1-based, counting pair by pair).
function Sleigh.CoatOf(team, i)
    local list = Sleigh.Coats[team and team.coat] or Sleigh.Coats.mixed
    return list[((i - 1) % #list) + 1]
end

-- ---------------------------------------------------------------------
-- Santa's flight
-- ---------------------------------------------------------------------
-- The sleigh takes off from where it is parked, climbs while it circles,
-- flies its laps, comes down and lands where it started, facing the way it
-- was parked. The circle passes through the parked spot, so the take-off
-- and the landing run along it; it turns to the sleigh's right.
--
-- Everything is a pure function of the parked position, heading and the
-- flight's numbers, so the server knows how long a flight lasts and every
-- client draws the same sleigh in the same place at the same moment.

local function smooth(u)
    if u <= 0.0 then return 0.0 elseif u >= 1.0 then return 1.0 end
    return u * u * (3.0 - 2.0 * u)
end

--- A flight's numbers, cleaned, from the server's settings.
function Sleigh.FlightParams(F)
    F = F or {}
    local function n(v, lo, hi, d)
        v = tonumber(v) or d
        if v ~= v then v = d end
        if v < lo then v = lo elseif v > hi then v = hi end
        return v + 0.0
    end
    return {
        radius   = n(F.Radius, 40, 2000, 160),
        altitude = n(F.Altitude, 10, 400, 55),
        laps     = math.floor(n(F.Laps, 1, 10, 2)),
        speed    = n(F.Speed, 5, 80, 22),
        ramp     = 4.0,               -- seconds to reach speed, and to stop
    }
end

--- The path: a table with everything Sleigh.At needs.
--- coords: the parked position; heading: the parked sleigh's heading.
function Sleigh.Path(coords, heading, params)
    local h = math.rad(heading or 0.0)
    -- The sleigh's x axis in the world is (cos h, sin h); its front is -x.
    local fx, fy = -math.cos(h), -math.sin(h)
    local rx, ry = fy, -fx                    -- its right
    local R = params.radius
    local L = 2.0 * math.pi * R * params.laps
    local V, Ta = params.speed, params.ramp
    if L < V * Ta then Ta = L / V end         -- a very short flight never reaches full speed
    return {
        sx = coords.x + 0.0, sy = coords.y + 0.0, sz = coords.z + 0.0,
        fx = fx, fy = fy, rx = rx, ry = ry,
        cx = coords.x + rx * R, cy = coords.y + ry * R,
        R = R, L = L, V = V, Ta = Ta, A = params.altitude,
        duration = L / V + Ta,
    }
end

--- Distance flown after t seconds: up to speed over Ta, cruise, down over Ta.
local function distanceAt(P, t)
    local V, Ta, D = P.V, P.Ta, P.duration
    if t <= 0.0 then return 0.0 end
    if t >= D then return P.L end
    if Ta <= 0.0 then return math.min(P.L, V * t) end
    if t < Ta then return 0.5 * V * t * t / Ta end
    if t > D - Ta then
        local u = D - t
        return P.L - 0.5 * V * u * u / Ta
    end
    return 0.5 * V * Ta + V * (t - Ta)
end

--- Height above the parked spot after `s` meters: it runs along the ground
--- for a few meters, climbs over the first part of the first lap, cruises,
--- and comes down over the last part of the last lap.
local function heightAt(P, s)
    local climb = math.min(P.L * 0.35, math.max(60.0, P.L * 0.15))
    local up = smooth((s - 8.0) / climb)
    local down = smooth((P.L - 6.0 - s) / (climb * 1.2))
    return P.A * math.min(up, down)
end

--- Where the sleigh is t seconds into the flight: x, y, z, the heading of
--- the sleigh entity, its pitch (nose up positive) and its bank (degrees),
--- and its speed. Past the end, it is parked again.
function Sleigh.At(P, t)
    local s = distanceAt(P, t)
    local th = s / P.R
    local c, sn = math.cos(th), math.sin(th)
    -- center + R * (-right * cos + front * sin): at th = 0 the parked spot
    local x = P.cx + P.R * (-P.rx * c + P.fx * sn)
    local y = P.cy + P.R * (-P.ry * c + P.fy * sn)
    local z = P.sz + heightAt(P, s)
    -- Direction of travel, and the entity heading that puts the front (-x) on it.
    local tx, ty = P.rx * sn + P.fx * c, P.ry * sn + P.fy * c
    local heading = math.deg(math.atan(-ty, -tx)) % 360.0
    local ds = 1.0
    local climb = (heightAt(P, s + ds) - heightAt(P, s - ds)) / (2.0 * ds)
    local pitch = math.deg(math.atan(climb))
    if pitch > 14.0 then pitch = 14.0 elseif pitch < -14.0 then pitch = -14.0 end
    local v = 0.0
    if t > 0.0 and t < P.duration then
        v = (distanceAt(P, t + 0.05) - distanceAt(P, t - 0.05)) / 0.1
    end
    -- A turn banks with speed: v^2 / R against gravity, capped.
    local bank = math.deg(math.atan(v * v / (P.R * 9.81)))
    if bank > 18.0 then bank = 18.0 end
    -- Not while still on the ground.
    local airborne = smooth(heightAt(P, s) / 3.0)
    return x, y, z, heading, pitch * airborne, bank * airborne, v
end

-- ---------------------------------------------------------------------
-- The ball drop
-- ---------------------------------------------------------------------
BallDrop = {}
BallDrop.Shape = 'balldrop'
BallDrop.MinHeight, BallDrop.MaxHeight, BallDrop.Height = 4.0, 40.0, 14.0
BallDrop.Patterns = { 'rainbow', 'sparkle', 'cycle', 'solid' }
BallDrop.Holidays = { 'newyear' }

local patternOk = {}
for _, p in ipairs(BallDrop.Patterns) do patternOk[p] = true end

--- A clean drop table: the ball's diameter, its palette (nil: the
--- holiday's richest), its pattern, and how long the drop takes.
function BallDrop.Clean(holiday, t)
    t = type(t) == 'table' and t or {}
    local function n(v, lo, hi, d, per)
        v = tonumber(v) or d
        if v ~= v then v = d end
        if v < lo then v = lo elseif v > hi then v = hi end
        if per then v = math.floor(v * per + 0.5) / per end     -- per = 10: tenths, exactly
        return v + 0.0
    end
    local out = {
        ball    = n(t.ball, 0.8, 6.0, 2.4, 10),
        pattern = patternOk[t.pattern] and t.pattern or 'rainbow',
        seconds = math.floor(n(t.seconds, 10, 120, 60)),
    }
    if type(t.palette) == 'string' and Holidays and Holidays.Palette(holiday, t.palette) then out.palette = t.palette end
    return out
end
