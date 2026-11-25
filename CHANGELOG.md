# Changelog

## [1.6.1] - 2026-11-24

### Fixed

- **The in-game update works.** *Apply update* in Settings (and
  `/holidayadmin update apply`) had never worked, in any version up to
  1.6.0. Two faults, one behind the other:
  - The release on GitHub did not match its own file list (three files
    were stored there with different line endings), so the update stopped
    with "3 of 332 file(s) could not be downloaded or verified" and
    changed nothing.
  - Behind that, the updater wrote every sound, model, picture and
    encrypted script cut off after its first few bytes. A server that got
    past the first fault was left with a resource that could not start.
  From this version every file is written whole and read back to be sure.
  Before the update writes over anything, it proves that this server
  writes a test file correctly and that every folder it needs is there;
  if either fails, nothing is changed. `fxmanifest.lua` is written last,
  so an update that is interrupted can simply be run again.
- **Versions up to 1.6.0 cannot update themselves, and no longer try.**
  Their *Apply update* now answers "manifest lists no files" and changes
  nothing, and the changelog they show says to download from the Cfx
  portal. Install this version by hand once: download it from your Cfx
  portal, copy it over the old folder (keep your `data` folder), type
  `refresh`, then `restart sals_kewlholidays`. From 1.6.1 on, updates
  apply from the game.
- **If an update on 1.6.0 or older ended with "files could not be
  placed":** the resource folder on that server is damaged and will not
  start again. Copy this version over it as above. The `data` folder, with
  your decorations and settings, was not touched.

### Changed

- **An update that needs a new folder changes nothing.** A resource cannot
  create folders. Up to 1.6.0 the update wrote what it could and reported
  the rest; now it stops before writing over anything, names the folder
  to create, and is run again.
- **An update brings the escrow key file too**, so an updated folder is the
  Cfx download byte for byte.

## [1.6.0] - 2026-11-24

### Fire department sleighs

- **Two new sleighs for the fire department.** The Sleigh tab now asks
  which **Sleigh** you want before you place it:
  - **Santa's sleigh**, as before.
  - **Fire department sleigh**: Santa's sleigh in fire department colors.
    Red and chrome, "NORTH POLE F.D." in gold leaf, a red beacon on each
    side of the dash, a light bar behind the seat, a brass bell, a ladder
    down each side, rolled hose and a discharge outlet on the back.
  - **Fire engine**: a fire engine built as a sleigh. Hood and grille with
    headlights and a bell, a windshield frame with a light bar on it, an
    open cab with a steering wheel, a pump panel with gauges and an outlet
    on each side, roll-up compartments, a ladder down each side, a hose
    bed with hose in it and a beacon on each back corner, all on chrome
    runners.
  All three take the same reindeer, are ridden the same way and fly the
  same way. Both fire styles are also in the Props tab.
- **Who may place a fire sleigh.** By default anyone who may decorate. Turn
  on *Fire sleighs: only fire crews may place them* in Settings and only
  admins, players allowed the `holiday.firesleigh` ACE and players in the
  jobs you list may. They can place and remove their own fire sleigh even
  if they are not decorators. One player:
  `add_ace identifier.license:xxxx holiday.firesleigh allow`.
- **Emergency lights.** The light bars and beacons of the two fire styles
  flash red and white, and light the ground around them. Each sleigh has a
  switch, **Emergency lights flash**, in the Sleigh tab and in the Edit
  list, and on a ride the driver turns them on and off with **G**.
  *Fire sleighs: emergency lights* in Settings turns them off for the
  whole server.
- **A siren.** On a ride, the driver of a fire sleigh turns the game's fire
  truck siren on and off with **J** (each player can move the key in the
  game's key settings, under FiveM). Everyone nearby hears it from the
  sleigh. *Fire sleighs: siren* in Settings turns it off.
- **Working hose lines, with the hose script your server runs.** The hose
  is that script's own: its hose, its water, its rules for who may pull
  one. Without a hose script the hose on the sleighs is for looks.
  *Fire sleighs: hose lines* in Settings turns all of this off.
  - **Sal's Kewl Fire Hose** (`sals_kewlfirehose`): walk up to a parked
    fire sleigh's outlet and press **G** to pull a line from it. A line is
    dropped when its sleigh is ridden away or flies.
  - **Fusion Fire Hose, z_hose, Smart Hose and other hose scripts:** these
    only hand out hose at a vehicle they know as a fire truck. So while one
    of them runs, a parked fire sleigh stands on a hidden fire truck that
    nobody sees or bumps into, and the hose script treats the sleigh as an
    engine: its own prompts, pump panel and hose, at the sleigh. Needs
    OneSync. New settings: *Fire sleighs: hidden fire truck* (auto, on,
    off; set it to on for a hose script not named here), the truck's model
    (`firetruk`, which every hose script lists out of the box) and two
    numbers that move the hidden truck if your hose script puts its
    prompts beside the sleigh instead of at it.
- **Upload the whole `stream/` folder.** Four new files are in it
  (`sk_fire_sleigh.ydr`, `sk_fire_engine.ydr`, `sk_sleigh_fire.ytyp`,
  `sk_sleigh_engine.ytyp`). This update adds files: type `refresh`, then
  `restart sals_kewlholidays`.

### Fixed

- **Updating no longer costs you your decorations.** Everything you place
  is saved in the resource's own `data` folder, so an update done by
  deleting the old `sals_kewlholidays` folder and dropping in the new one
  deleted the decorations, the settings, the saved places and the floats
  with it, and the city had to be decorated again. From this version the
  server also keeps a second copy of all four outside the resource folder.
  When the resource starts and finds its `data` folder empty, it puts
  everything back from that copy by itself and says so in the console.
  **This protects every update after this one.** For the update TO this
  version from an older one, keep your `data` folder: copy it into the new
  folder.

### Changed

- **A sleigh stays where the rider gets out.** Up to 1.5.1 a ridden sleigh
  went back to where it was placed the moment its rider got out. Now it is
  parked where the ride ended, reindeer and all: it can be ridden again
  from there, a fire sleigh's lights keep flashing there and hose is pulled
  from it there. The same when a ride ends by itself (the longest ride, or
  nobody driving). Two new settings under Santa's sleigh:
  *A sleigh stays where the rider gets out* (turn it off for the old
  behavior), and *Send a left sleigh back after* (minutes with nobody near
  it; 0, the default, never sends it back). A decorator can always move it
  back by hand in the Edit list. Santa's flight still takes off and lands
  where the sleigh stands.

## [1.5.1] - 2026-11-23

### A new sleigh

- **Santa's sleigh is our own model now, and it is not broken.** Up to 1.5.0
  the sleigh was the game's own sleigh prop, which is a wreck: splintered
  boards, holes in the body, a broken runner. The new one is red lacquer
  with gold scrollwork, curled gold runners, a green velvet seat with gold
  buttons, a lit lantern on each side of the dash, colored fairy lights
  along the rim and a wreath on the back. It casts a warm light at night.
- **Sleighs already placed change by themselves.** Every sleigh on your
  server becomes the new one, where it stands, with its reindeer, the first
  time the server starts with 1.5.1. Nothing to place again.
- **It works on every game build.** The old sleigh needed build 3095. The
  new one ships in `stream/`, so the Sleigh tab no longer asks for a build.
  Upload the whole `stream/` folder: three new files are in it
  (`sk_santa_sleigh.ydr`, `sk_santa_gifts.ydr`, `sk_sleigh.ytyp`).
- **Presents made for it.** "Presents in the back" is now Santa's sack, a
  stack of wrapped presents, a candy cane and a teddy bear behind the seat,
  and two presents in the footwell clear of the driver's feet.
- **Sparkles.** Gold sparkles twinkle around a sleigh you are near, and
  trail from its runners on a ride. *Sleigh sparkles* in Settings turns
  them off.
- **Two fit on the seat.** The sleigh sits centered on the hidden vehicle,
  so the driver and a passenger ride side by side.

### Changed

- When the resource starts, the server console shows one line recommending
  Sal's Kewl Public Safety Simulator (not on a server that already runs it).
- **BREAKING (settings):** the three *Sleigh on the vehicle* settings
  (`Sleigh.Ride.OffsetX`, `OffsetY`, `OffsetZ`) are gone. The sleigh now
  lines its seat up with the hidden vehicle's own driver seat by itself.
  Three new settings, *Move the sleigh on the vehicle*
  (`Sleigh.Ride.NudgeX`, `NudgeY`, `NudgeZ`, all 0), move it from there, and
  are only needed if you changed the hidden vehicle and the driver ends up
  off the seat. A saved Offset value is ignored.

### Fixed

- **The reindeer's legs no longer stutter at speed.** A ridden sleigh's top
  speed sat right on the line between a canter and a gallop, so the team
  switched between the two over and over, restarting the leg animation each
  time. The gallop now starts sooner, and a team holds its gait until the
  speed has clearly changed.
- **Sleigh rides: the rider and the sleigh no longer vanish.** The hidden
  vehicle under a ridden sleigh was hidden in a way that also hid everything
  attached to it, which is the driver and the sleigh itself. It is now made
  see-through instead, so only the vehicle disappears.
- **Sleigh rides: no golf cart flashing into view.** Other players could see
  the hidden vehicle for a moment when a ride started. It is now hidden the
  instant it reaches each player's game.
- **The presents no longer bury the sleigh.** The presents in the sleigh were
  the 2023 gift box props, which are far bigger than they sound (the "large"
  one is 2.5 m across). See "Presents made for it" above.
- **The rider sits on the seat.** The driver sat too far back, sunk into the
  seat cushion. See the settings change above.
- The Props tab described the 2023 gift boxes as knee and waist high. They
  are 0.9 m, 1.2 m and 2.5 m, and now say so.

## [1.5.0] - 2026-11-18

### Santa's sleigh and the New Year's ball drop

Asked for by server owners: a ball drop like the one in New York at New
Year's, and a Christmas sleigh pulled by reindeer. Both are new, in a new
**Sleigh & ball drop** tab.

- **New Year's ball drop.** A lit ball at the top of a pole, 4 to 40 m tall,
  on a plaza or a roof. The ball is a faceted crystal sphere of colored
  panels (**Rainbow**, **Sparkle**, **Color cycle** or **Steady**, in the
  New Year's colors), turning slowly, with a glow around it that lights up
  the square. Start a countdown at its location (Shows tab, `00:00` counts
  to midnight) and the ball starts down in the last minute (10 to 120
  seconds, your choice) and lands on zero: a flash, a burst of sparkles, the
  ball races through the colors. Nearby players see **Watch the ball drop**
  with the countdown. It stays down for a while after midnight, then rises
  again; a canceled countdown sends it back up. **Test drop** in the Edit
  list drops it for you alone. Every player sees the same ball at the same
  height at the same moment.
- **Santa's sleigh with real reindeer.** The game's own sleigh with a team
  of the game's own deer in front of it, two to eight, in pairs, all with
  antlers: tan and brown, all tan, all brown, or all white. They stand,
  graze or prance while parked. The lead reindeer has a red nose that glows.
  Leather traces run from the sleigh through every collar, with a gold bell
  on each, and there are presents in the back.
- **Ride the sleigh.** Walk up to a parked sleigh and press **E**: you drive
  it, the team walks, trots, canters and gallops with your speed, and the
  bells jingle for everyone nearby. Get out to end the ride; the sleigh is
  back where it was parked. A ride also ends after 10 minutes or when nobody
  drives it for 20 seconds. Each sleigh can be closed to rides, and who may
  ride is a setting (everyone, decorators, admins).
- **Santa's flight.** **Santa's flight** in the tab (or `/holiday sleigh
  fly`): the sleigh at your location runs, takes off, climbs while it
  circles over the location (160 m wide, 55 m up, two laps, all settings),
  comes down and lands where it was parked, with a trail of gold sparkles
  and its bells. Everyone within 1.5 km sees it, in the same place at the
  same moment; a player who arrives mid-flight sees it where it is. A
  countdown at a location with a sleigh ends with Santa's flight (Settings).
- Sleighs placed from the Props tab before this update can be given a team:
  **Add reindeer** in the Edit list.
- New sections in Server settings: **Santa's sleigh** and **Ball drop**.
- `/holiday sleigh fly | land [location]`, `/holiday balldrop test`.
- Exports for other scripts: `FlySleigh(location)`, `LandSleigh(location)`.
- A countdown or a show now starts at a location that has only spotlights, a
  ball drop or a sleigh (it used to need lights or launchers).

**Updating:** this release adds files. Type `refresh`, then
`restart sals_kewlholidays`, as for every update. No config changes; the new
settings have defaults.

## [1.4.2] - 2026-11-15

### Spotlights light trees

Found filming 1.4 on a real server: a spotlight at the foot of a Christmas
tree, pointing up, barely showed. The needles face outward and the light
only grazed them, and a tree's branches have no collision, so clicking the
tree aimed at whatever stood behind it.

- **Aim at a tree and the whole tree lights up.** While aiming, the tool
  now sees the decorations you placed (a Christmas tree, an inflatable, any
  prop) even where the game lets a click pass through. It outlines the one
  under your crosshair and aims at its middle, and the spotlight switches to
  **Light a tree**: the light comes in from the side, far enough out to
  strike the branches face on, wide enough for the whole tree, and stops
  just past it so the building behind stays dark. The fixture stays where
  you set it, and nobody can see where the light really starts.
- **Light a tree** is also a switch in the Spotlights tab (with **Tree
  size**: small, medium, large) for the trees of the map: turn it on, then
  click the trunk.
- **Better default colors.** A spotlight with no palette chosen used
  whichever sorted first, so Halloween came out all red ("blood") and a
  party all blue. It now uses the holiday's richest palette: orange and
  purple, rainbow, multicolor, red white and blue.
- **Projector glow toned down.** The soft light behind a projector's
  pictures defaulted to 0.35 and painted a bright disk that drowned them;
  it is 0.05 now (Settings > Spotlights and projectors > Projector glow).
  Servers that saved their own value keep it.

No config changes.

## [1.4.1] - 2026-11-15

- **Everyone sees the same thing at the same moment.** Spotlights and
  projectors animate on the network clock every player shares, so two
  players side by side see the same color, the same fade and the same
  snowflakes in the same places. (Outside a show they used to run on each
  player's own clock.)

## [1.4.0] - 2026-11-15

### Spotlights and projectors

A new **Spotlights** tab. Asked for by server owners: "a spotlight in the
ground pointing at a tree to light it up", "spotlights to light a building
in different colors", and "projectors that put moving patterns on walls,
like snowflakes, snowmen, or dancing turkeys".

- **Spotlights.** Set a fixture down like a prop, then click the tree,
  wall or building front it should light. The beam is the game's own
  spotlight, in any holiday palette or a color of your own, narrow, wide or
  flood, at the brightness you choose. It can hold one color, **cycle**
  through the palette, or run a pattern (fade, twinkle, chase across a
  location's spotlights, alternate, wave, flicker). **Hide the fixture** for
  the "buried in the ground" uplight look.
- **Projectors.** The same fixture throws moving pictures on the wall it
  points at, like the LED projectors people put on their lawns: falling
  snow, waving snowmen, a Christmas mix, twinkling stars, rising hearts,
  tumbling shamrocks, eggs and hopping bunnies, fireworks bursts, bats past
  the moon, a Halloween mix, **dancing turkeys** in falling leaves, autumn
  leaves, spinning dreidels, candles, and a party of balloons and confetti.
  Fifteen projections, each offered under its holidays, with live previews
  in the tab. Picture size and speed are yours.
- **Aim by clicking.** While aiming you see the light on the spot under
  your crosshair; the scroll wheel changes the beam width or picture size.
  The fixture turns to face what it lights. **Aim** in the Edit list or the
  aim-and-click tool re-aims a placed one; moving a fixture keeps its aim.
- **Shows drive them.** Each spotlight has a channel 1-4 like a string of
  lights. In a show its brightness follows that channel, and dancing
  turkeys dance to the track's beat. A location with only spotlights still
  plays the music.
- **Within budget.** Beams are capped per player (**Beams per frame**, 16);
  shadows are off by default (**Beams that cast shadows**, 0). Projector
  pictures are drawn within a share of the same textured-triangle ceiling
  the bulbs use, split fairly between the projectors in view. A new
  **Spotlights and projectors** section in Server settings holds every knob.
- Spotlights stay put: they cannot ride on a float. At most 24 per location
  (Server settings).

No config changes to existing settings; the new ones have defaults.

## [1.3.3] - 2026-11-13

### Updating: refresh, then restart

Reported by a server that updated to 1.3 in game: opening the panel failed
with `attempt to index a nil value (field 'Floats')`. 1.3.0 added two
scripts (`client/floats.lua`, `server/floats.lua`). FXServer reads a
resource's file list once and keeps it until `refresh`, so an update
followed by `restart` alone ran the new files without the new scripts.

**If you see that error:** type `refresh`, then
`restart sals_kewlholidays`, in the server console or txAdmin.

- **The resource notices.** At start it compares the version on disk with
  the one the server loaded. When they differ it prints what to type in the
  console and tells admins in game when they connect. The panel shows the
  same instruction instead of failing, and the server no longer stops
  partway through starting.
- **Restart after applying** now runs `refresh` before the restart, and
  every "update written" message says to type `refresh` first.

No config changes.

## [1.3.2] - 2026-11-13

### Floats: the right vehicle

- **Standing at a vehicle picks the one you mean.** The Vehicles tab used
  the vehicle whose middle was nearest you (within 8 m), so beside the back
  of a fire engine it could pick a display car parked next to it, or
  nothing. It now measures to each vehicle's body (within 4 m), prefers a
  vehicle everyone can see over one only in your game, and on a near tie
  prefers the one you last drove. Sitting in the vehicle still picks it.
- **Display vehicles can carry a float.** A vehicle a script parks on each
  player's own screen (a display engine at the station, a dealership car)
  is not shared over the network, so making a float from it used to fail
  with "That vehicle exists only on your screen". It now carries the float
  by its spot, the way **On an object** works: every player whose game
  parks the same vehicle there sees the lights on it. The Vehicles tab says
  "Only in your game" under such a vehicle; **Decorate**, **Take it off**
  and **Put it on** (this vehicle) work on it. Plate and whole-model
  bindings still need a shared vehicle, and a spot float stays at its spot,
  so a car only you spawned shows its float only to you.

No config changes.

## [1.3.1] - 2026-11-12

### Locations: one place, one location

Reported by a server that decorated several fire stations without changing
location: every station landed in `main`, so a layout saved as "Station 1"
held all of them, and Travel took you to a different station depending on
where you were standing.

- **Move decorations into a location** (Locations tab, and
  `/holiday claim <meters> [location]`). Stand at a building, name it, pick
  a distance, and everything around you joins that location, which becomes
  yours. **Only from** limits it to one location (say `main`). Only what you
  may edit moves; other players' decorations are left and counted, a
  float's decorations stay on their vehicle, and launchers past the
  per-location cap are left out. Decorators reach as far as they can place
  (`Access.Reach`, 60 m by default); admins can sweep up to 250 m.
- **Travel goes to the same place every time.** A live location travels
  to the middle of its largest area instead of the decoration nearest you.
  A layout saved now centers on its largest area too; layouts saved before
  1.3.1 keep their old spot until you **Save over** them.
- **Spread locations are flagged.** A location (or layout) whose
  decorations sit at several places across the map says "Spread over N
  separate places" in the Locations tab, the save box says which location
  it will save and warns before saving a spread one, and saving one warns
  in chat.
- **Clearer wording.** The save box says the name is the layout's, not the
  location's. **Delete** on a layout says the decorations stay up. A grayed
  **Move**/**Remove** in the Edit list says who placed it.

No config changes.

## [1.3.0] - 2026-11-11

### Floats: decorations on vehicles and moving objects (experimental)

> **Experimental.** Floats are new in 1.3.0 and have not yet been tested
> on a live server. Expect rough edges: lights can trail a vehicle by a
> frame at highway speed, and a garage-spawned vehicle may take a couple of
> seconds to show its float. Turn them off under Settings > Floats if they
> cause trouble, and please report what you see.

- **Decorate a vehicle and the lights go where it goes.** A float is a set
  of decorations that rides a vehicle: string lights along the roofline,
  figures on the doors, inflatables on a flatbed, wreaths on the grille. Make
  one from a parked vehicle in the new **Vehicles** tab, decorate it with the
  Props, Lights, Figures and Inflatables tabs as usual (the vehicle is held
  still while you work), press **Done**, and drive. The strings follow the
  vehicle's every turn and slope in the same frame. Props ride attached, and
  never solid, so they cannot throw the vehicle around.
- **Put a float on as many vehicles as you like.** Pick how:
  - **This vehicle**: this one, also after it goes back to the garage. It
    is matched by plate and model together.
  - **This plate**: any vehicle with the plate.
  - **Every one of this model**: the whole fleet.
  - **On an object**: something in the world that moves by itself, like the
    Ferris wheel. Aim at it and click.
- **Set a plate while you bind.** Give the parade engine its own plate
  (`XMAS01`) and the float follows that plate. A plate already used by a
  vehicle out there, or owned by a player, is refused. A player-owned
  vehicle's plate is never changed unless the server allows it, and then it
  is rewritten in the garage database too (qb/qbx `player_vehicles`, ESX
  `owned_vehicles`, through oxmysql), and the owner gets new keys where the
  keys resource allows it. Removing a binding can put the old plate back.
- **Shows run on floats.** A float is a location like any other, so
  `/holiday show` and the Shows tab drive its lights. The music plays from
  the float as it drives past (server setting).
- **Nothing per frame crosses the network.** Which vehicle wears which float
  rides in the vehicle's state bag. Each client draws the floats near it,
  nearest first, up to **Floats drawn at once**.
- **For other scripts:** server exports `ApplyFloat(vehicle, name)`,
  `ClearFloat(vehicle)`, `GetFloats()` and `GetVehicleFloat(vehicle)`.
  `vehicle` is an entity or a network id. A garage or job script can
  decorate the vehicles it spawns.
- `/holiday float edit` decorates the float on the vehicle you are at, and
  `/holiday float done` finishes.

### Panel

- The tabs wrap onto a second row instead of scrolling out of sight.

### Requirements

- **Floats need OneSync** (which vehicle wears which float travels as an
  entity state bag). Everything else works as before without it.
- Plate lookups (owners decorating their own vehicles, and refusing a plate
  a player owns) use **oxmysql** when it runs. Without it on a qb/qbx/ESX
  server, plates cannot be set and owners cannot decorate. Decorators can
  still make and bind floats.

### Config

- New settings under **Settings > Floats (decorated vehicles, experimental)**:
  `Vehicles.Enabled`, `OwnersMayDecorate` (off), `SaveBindings` (on),
  `FloatMusic` (on), `SetPlates` (on), `OwnedPlates` (off), `MaxDecorated`
  (6), `RenderDistance` (150), `MaxOffset` (12 m), `MaxItems` (80),
  `MaxBulbs` (2500), `MaxFloats` (100), `MaxPerOwner` (2). New rate-limit
  bucket `float`. New file `data/floats.json`. Nothing to change on upgrade.
- A float and a location cannot share a name. Fireworks launchers cannot go
  on a float.

## [1.2.7] - 2026-11-07

### Fireworks

- **Whistles no longer carry across the map.** Every firework sound faded
  out over the same 700 m, and a whistle is a steady high tone that stands
  out far beyond its volume, so it was heard long after the booms had gone
  quiet. Whistles (shells and rockets) now fade out over their own
  distance, 250 m by default.
- **Whistles can be turned off.** Players: Settings > My settings >
  **Whistles**, or `/holiday fireworks whistle off`. The whole server:
  Settings > Fireworks > **Whistles**. With them off, a shell leaves with a
  launch thump.
- **Sharper drawn shapes.** The tree, candy cane, snowflake and other shapes
  drawn in sparks were a blur: the sparks were drawn large with a wide glow,
  every shape had the same number of them however short its outline (the
  candy cane was one smear), and their colors alternated spark by spark. Now
  they are small separate stars spaced along the outline with a faint glow,
  in one color, or in the shape's own: a red and white striped candy cane, a
  green tree on a gold trunk, an ice-blue snowflake, a gold bell, a green
  wreath with a red bow, an orange jack-o'-lantern. The game's own shapes
  (the star, the heart) are unchanged.

### Config

- New: `Config.Fireworks.Whistles` (default `true`) and
  `Config.Fireworks.WhistleRange` (default `250.0`). Nothing to change on
  upgrade.

## [1.2.6] - 2026-11-07

### Inflatables: every one of the 70 reviewed and rebuilt

- **Nothing is see-through any more.** 1.2.5 shipped every inflatable body
  inside-out: the game draws only the outside of a surface, so it skipped
  the near side and showed the far side from within. A bride's hair showed
  through her face, the elephant's trunk looked hollow, balloons looked like
  bowls. The builder now winds every surface outward and refuses to write a
  model that is not.
- **Boxes and cylinders.** The builder only knew rounded blobs, so anything
  square or round-sided came out as a lump. It now builds real boxes and
  cylinders, and these were redesigned with them: the **gingerbread house**
  (walls, a gable, two icing roof slabs, chimney, door, windows with panes,
  gumdrops along the eaves), the **stack of presents** (wrapped boxes, ribbon
  both ways, bows), the **Christmas train** (boiler, stack, cab with windows,
  cowcatcher, gold wheels, a tender of presents), the **dreidel** (a square
  body on its point, a handle, a Hebrew letter on each face), the **Uncle Sam
  hat** (a tall striped crown, starred band, brim), both **cakes** (round
  tiers with icing and drips), the **champagne toast** (two flutes leaning
  in), and the **barbecue grill** (kettle on three legs, grate with burgers
  and hot dogs, lid open behind).
- **Redesigned to look like the product:** the **black cat** sits up with
  green eyes, whiskers, a collar and bell and a tail curled round its paws
  (it was a blob on four paddles); the **cat on the pumpkin** is the same
  cat; the **haunted tree** is a dark gnarled trunk with roots, a face and
  branches that bend up and out; the **cornucopia** is a proper horn with a
  dark mouth and a pile of harvest in front; the **rainbow arch** is six
  smooth bands (it was rows of beads); the **gold star** has a stand.
- **Strings and thin parts** (balloon strings, cupid's bow string) no longer
  come out as dashes.
- **A quarter of the triangles, the same look.** Every model is simplified
  after it is built; the `stream` folder went from 51 MB to 22 MB and the
  download is a third smaller. Same model names: everything already placed
  updates in place.
- **The bunny's and the chick's eyes** were inside their heads. Any feature
  that would be buried in the skin is now moved out to the surface.

### Updater

- **Downloads are retried and paced.** The updater fired every file at once
  (300 of them) and a server updating from 1.0 lost two to GitHub and gave
  up with "2 files could not be verified" and no names. Six at a time now,
  three tries each.
- **Failures say which files and why**, in game and in the console, whether
  a download failed (try again), a file did not match the manifest (report
  it), or a file needs a folder the old version never had (the message
  names the folder to create; a 1.0 server needs `audio/sfx`).

## [1.2.5] - 2026-11-06

### Inflatables

- **Clean colors on every inflatable.** Where two colors met (a beard and a
  coat, a sack and a sleigh) the models showed thin stripes of unrelated
  colors, gold and white, in stair steps. Every model is rebuilt with each
  color cut cleanly along a smooth line.
- **Trims are printed on, not stuck on.** Belts, coat stripes and hems,
  Mrs. Claus's apron, the nutcracker's braid, the pilgrim's collar, the
  worker's reflective stripes, the graduate's stole, the jester's collar, the
  egg's bands, Uncle Sam's stripes, the firecracker's bands and the grill's
  band were thin discs that stood off the body like plates. They are now
  part of the surface.
- **Santa in his sleigh, redesigned.** He sits side-on to the street, facing
  it and waving, with his sack behind him; the sleigh has a tall curled prow,
  a backrest, and two runners on the ground that curl up at the front and
  join the sleigh. (He used to look at the prow, and the runners were loose
  rods that read as yellow plates on the ground.)
- **The eagle's wings** grow from its shoulders and sweep up; they used to
  only touch the body and showed gaps.
- Same model names: everything already placed updates in place, nothing to
  do on a server.

### Lights

- **The strings in front of you stay whole and keep their glow on a fully
  lit house.** The per-frame share of bulbs counted every string within 10 m
  of its CENTER as equally far, so a long string beside you counted as far
  and the strands right in front of you thinned and lost their halos. Shares
  now go by each string's nearest bulb, and the glow leans harder still to
  the strings close to you.
- **Distant bulbs cost half.** Past 25 m (`Lights.FarCoreDistance`) a bulb
  is one diamond instead of two, so a big display keeps more of its bulbs.
- **No bare diamonds.** A bulb that does not get a textured halo this frame
  draws a wider, softer under-glow instead of a hard diamond.

## [1.2.4] - 2026-11-06

- **Icicles stay icicles on a busy street.** Where a lot of strings are in
  view at once, an icicle string handed fewer bulbs than its top run drew a
  sparse run and no icicles at all, so it looked like a plain string with
  the bulbs spaced far apart. A string short of bulbs now shares them
  between the run and its icicles, thinning both evenly. Nothing to redo:
  strings you already put up draw correctly after the update.

## [1.2.3] - 2026-11-06

- **Shapes and trails read from the street.** Drawn sparks (the rising
  trails, the holiday shapes, the year in the sky) were sized like a string's
  bulbs and came out a couple of pixels wide 100 m up. They are now about
  twice the size, and shapes twice that.
- **A salvo fires whole.** The per-player shell budget let through only a
  second and a half of shells at once, so a big salvo lost half its shells.
  It now holds a whole salvo, and `Fireworks.MaxShellsPerSecond` defaults
  to 16 (was 10).

## [1.2.2] - 2026-11-06

- **Bigger bursts, and a setting for it.** Seen in game, the game's firework
  effects at their own size read small from the street (about 12 m across at
  80 m up). They now burst at 1.6 times that by default; Settings >
  Fireworks > **Burst size** (`Fireworks.BurstScale`, 0.5 to 3) changes it.

## [1.2.1] - 2026-11-06

- **Burst light toned down.** Seen in game on the first show: each burst lit
  the square below it like daylight. It now tints the walls and the ground
  in the shell's color instead (a fifth of the strength).

## [1.2.0] - 2026-11-06

### Fireworks

- **Launchers.** A new Fireworks tab places four launchers like props: a
  mortar rack (aerial shells), a rocket, a cake (a fan of small shots) and
  a fountain. Each is loaded with Mixed (follows the music), peony,
  chrysanthemum, willow, ring, spiral, crackle, strobe, salute or holiday
  shapes; colored with the holiday's palettes or gold, silver and rainbow;
  given a channel, a burst height and an aim; and can be a hidden launch
  point with no prop, for roofs. Preview fires one in front of you, for you
  only. Every firework prop is a launcher, including ones already placed
  from the Props tab (they start loaded Mixed, on channel 1).
- **Fireworks set to the music.** A show fires the location's launchers.
  **Follow the music** uses a score written from each track's own notes:
  every shipped track has one, so shells burst on the melody, low notes on
  one end of the row and high notes on the other, long notes as big
  shells, salvos at each new verse, and a finale. Programs on the beat
  (Grand, Steady, Gentle, Rapid, Finale only) suit any track, including
  ones you added. Light, normal or heavy. A location with only launchers
  can run a show.
- **Shapes in the sky**: hearts, stars, shamrocks, pumpkins, bats, the
  menorah, wedding rings, the turkey and more, per holiday; at New Year's,
  the year spelled across the sky.
- **Countdowns** to seconds, a time of day or midnight (server time):
  everyone nearby sees the clock, a salvo bursts on zero, the holiday's
  banner shows and the show starts.
- **Firing by hand**: a launch board in the Shows tab and a keyboard
  launch mode (`/holiday launch`), for everyone nearby.
- **Rehearse** a show and its fireworks for yourself only.
- **Fireworks steps in the Shows editor**: a fireworks pattern per channel
  per step, played by "From the show". The new **Sky Show** is an example.
- The game's own firework effects, tinted, with drawn trails and shapes,
  burst light on the buildings below, and synthesized sounds that arrive
  late with distance. Nothing is an explosion; nobody can be hurt.
  Players can turn fireworks off, down, or to fewer flashes.
- `/holiday fwtest` fires every effect in front of you and names it in F8,
  with whether the game build has it.

### Configuration

- New **Settings > Fireworks** section (`Config.Fireworks`). Nothing to
  change on update: fireworks are on, by day and night, with the shipped
  limits.
- New rate limit bucket `fire` (hand firing).
- Exports: `StartShow` takes an optional fifth argument for fireworks;
  new `StartCountdown` and `FireFireworks`.

### Also

- `/holiday help` listed `/holiday inflate` as placing wreaths; it now
  lists `/holiday wreath` for those.
- Ten panel tabs scroll sideways instead of squeezing.

## [1.1.1] - 2026-11-06

- **Inflatable models are actually solid now.** Their collision was built
  into every model, but with no collision flags, so players and vehicles
  passed straight through whatever "Inflatable models are solid" was set
  to. All 70 models now carry the standard flags. Turning the setting off
  still lets everything pass through.
- **Icicle lights no longer lose their icicles when you turn.** An icicle
  string is its run plus every strand, and when the frame was busy the
  strands were what went (in 1.0, all of them, leaving a bare run that came
  and went with the camera). The run now always draws whole; the strands
  thin first to every second or third bulb down each icicle, then to every
  other icicle. Far away, strand bulbs that would draw on top of each other
  are skipped, which frees bulbs for everything else.
- **The old drawn inflatables are gone.** Every inflatable has been a real
  model since 1.0; the drawn versions they replaced no longer ship, and
  neither do the Edit tray's Deflate / Inflate, the inflate, deflate and
  sway animation, or deflating by day. An inflatable placed as a drawn
  shape with an earlier version becomes its model, in the same place and
  facing the same way, the first time the server starts on 1.1.1; the
  console says how many it converted. `/holiday inflate <holiday> <name>`
  now places the model; wreaths, wall pieces and yard pieces moved to
  `/holiday wreath <holiday> <name> [size]`.
- **High and ultra quality no longer drop the nearest strings.** Their bulb
  budget was more than the engine's triangle buffer can take, and since
  strings paint far to near, the near ones were cut. The budget now stops
  at what the buffer holds.

**Configuration:** `Shapes.InflateSeconds`, `Shapes.DeflateSeconds`,
`Shapes.Sway`, `Shapes.SwayAmount`, `Shapes.DeflateByDay`, `Shapes.DayFrom`
and `Shapes.DayTo` are removed (they only drove the drawn inflatables);
saved values for them are ignored. The settings section is still called
"Inflatables and wreaths". No other breaking changes.

## [1.1.0] - 2026-11-05

- **Strings across an intersection all stay lit.** The per-frame budgets
  (bulbs, glow and cast lights) used to go to the nearest strings first,
  so with three spans over a road the fourth got no glow at all, and with
  icicle lights it was not drawn. Every string on screen now gets a share,
  nearer strings a bigger one, and none gets more than it can use. A
  string handed fewer bulbs than it has thins out evenly along its whole
  length; before, it drew its first stretch and the rest stayed dark. Six
  30 m spans over one intersection stay lit end to end at medium quality.
  Strings beyond the halo distance no longer take any of the glow budget.
- **Hang figures, wreaths and props from a string of lights.** Aim at a
  placed string and the piece hangs under it at that spot, follows the
  sag, and faces you, so a figure on a span over a road faces the traffic.
  **Hang on strings** in the tray turns it off (remembered per player);
  Alt ignores strings for that moment. Anything solid in front of the
  string still wins.
- **Figures go up and down.** Up and Down (and the tray's Raise buttons)
  move a figure from where you aimed: higher on a light pole, lower on a
  longer drop under a string. The figure hint now says a pole works like
  a wall.
- Owner's manual: new sections on light poles and hanging from a string,
  and a few garbled characters (arrows, middle dots) fixed.

No configuration changes. No breaking changes.

## [1.0.0] - 2026-11-04

First release. Everything from the betas below, plus:

- **Every inflatable is now a real game model.** All seventy (the sixty-one
  figures and nine walkway arches) ship in `stream/` as fused one-skin
  drawables with an emissive shader, a point light and sphere collision,
  generated from the same shapes that used to be drawn per frame
  (`tools/build-inflatables.py` → Blender/Sollumz → `tools/cwconv`). They
  cast shadows, take the game's lighting, and you bump into them. The
  Inflatables tab now places the model and shows its picture; each comes
  in the one size on its card. The catalog lists them from the generated
  `shared/inflatable_models.lua`, so only models actually present in
  `stream/` are offered. Download size grows by about 37 MB.
- Inflatables placed with earlier versions are still drawn the old way and
  still inflate, deflate and sway; the Edit tray still toggles them.
- Walkway arch models align their rows along the path, like the drawn
  arches did.
- **Inflatable models are solid** (Settings -> Inflatables and wreaths): on,
  players and vehicles bump into them; off, everything passes through, for
  a server whose doorways and walks keep getting blocked. Applies to every
  client at once.
- **Clear every decoration on the server** (Locations tab, admins): one
  armed control takes down every location and holiday at once, same as
  `/holiday clear all`. Saved layouts are kept, and the server writes
  `data/decorations.json.before-clear-<time>` first so a wrong click can
  be undone.
- Pictures for the seventy models ship rendered from their shapes;
  `/holiday thumbs` replaces them with in-game photographs as before.
- `publish-release.ps1` (vendor): hand it the escrowed zip from Keymaster
  and it checks the escrow, writes `update.json`, commits, tags, pushes
  and attaches the zip to a GitHub Release.
## [0.5.5-beta] - 2026-11-04

- **A lit wall looks the same at 20 m as it does at 2 m.** The glow and the
  cast light on a string no longer swing on and off as you walk up to it:
  - Strings behind the camera, which are often the nearest ones, no longer
    take any of the frame's halo, bulb or cast-light budget; a bulb behind
    the camera is skipped outright.
  - One textured halo per bulb at every distance. The second, near-only
    sprite that switched on at 12 m (and doubled the cost right where the
    budget was tightest) is gone; the glow instead strengthens smoothly as
    you come within `Lights.NearDistance`, now labeled "Glow boost within".
  - A string handed less than it needs spreads it along its length (a halo
    on every other bulb) instead of the first bulbs getting everything.
- Cast light defaults: every fourth bulb, up to 64 sources (were every
  third and 48), so a wall of four door frames is lit end to end.
## [0.5.4-beta] - 2026-11-04

- 0.5.3-beta's manifest carried a UTF-8 byte-order mark and loaded with no metadata. Same content, clean file.

## [0.5.3-beta] - 2026-11-04

- **Near strings keep their glow.** The textured halo cap and the cast-light
  cap were still spent first-come, and strings paint far to near, so with a
  few door strings on screen the one you stood at drew as dim pinpricks
  while the far ones glowed (seen on Fusion with 0.5.2). Both caps are now
  handed out nearest-first, like the bulb budget.

## [0.5.2-beta] - 2026-11-04

- **Strings no longer vanish as you walk up to them.** The per-frame bulb
  budget was handed out to far strings first, so when a big icicle run
  spent it, the strings at the door in front of you drew nothing. The
  budget now goes nearest-first (painting stays far-to-near). Default
  bulbs per frame 1500 â†’ 3000.
- **Door lights no longer disappear when drawn inflatables are near.**
  Strings and drawn shapes share the engine's polygon buffer; shapes now
  take only what the strings left.
- **Santa and the penguin models are one smooth skin** (parts fused with
  soft blending instead of stacked balls), use an emissive shader so they
  glow at night, and carry a light that falls on the ground around them.

## [0.5.1-beta] - 2026-11-04

- The package no longer carries the model converter's build output.

## [0.5.0-beta] - 2026-11-04

- **Inflatables as real models (first two).** Santa (2.6 m) and the
  penguin (2 m) ship as streamed props in `stream/`, generated from the
  same catalog data: smooth meshes, engine lighting and shadows, and
  collision (a sphere per big part). They sit at the top of the
  Christmas prop list as "Santa (inflatable, 2.6 m)" and "Penguin
  (inflatable, 2 m)". The drawn versions stay in the Inflatables tab for
  now. Pipeline: `tools/build-inflatables.py` (meshes from the catalog),
  `tools/blender-inflatables.py` (Blender + Sollumz, headless),
  `tools/cwconv` (CodeWalker XML to binary).

## [0.4.9-beta] - 2026-11-04

- A part set into a bigger part (a penguin's belly, a beard on a head, a
  muzzle, an apron) no longer vanishes when seen from the side: such
  parts are found automatically on every shape and drawn as surface
  features.

## [0.4.8-beta] - 2026-11-04

- Surface features on every inflatable, wreath and yard piece (eyes,
  noses, belts, buckles, buttons, bands, cuffs, brims) are drawn in a
  layer after the body parts and only on the camera's side, so they no
  longer sink into the part they sit on and pop back as you move.
  Santa's front stripe is a flat band.

## [0.4.7-beta] - 2026-11-04

- Parts of an inflatable no longer appear and disappear as you move: the
  triangle budget used to cut a shape short, dropping whichever parts
  sorted last that frame. A shape is now drawn whole or drops a detail
  level whole. Budget default 12000.
- The people's arms are built from joints (shoulder, elbow, wrist) so the
  segments overlap and nothing floats off the body; Santa's hat is
  stacked tighter.

## [0.4.6-beta] - 2026-11-04

- **The people are rebuilt** to the proportions of real lawn inflatables:
  a tall body on short legs, sausage arms bent at the elbow, trim bands,
  a flat belt with a buckle, mittens, boots, and faces with eyes that
  have whites, cheeks and brows. Santa, Mrs. Claus, nutcracker,
  leprechaun, pilgrim, construction worker, graduate, jester, scarecrow
  and witch share one builder, so they match.
- **Vinyl shading** on every inflatable, wreath and yard piece: a finer
  mesh on the big parts within 12 m, darker toward the silhouette, and a
  soft highlight where the light reflects toward you.

## [0.4.5-beta] - 2026-11-04

- **Inflatables, wreaths and yard pieces are real geometry now.** Each
  part is a small triangle mesh drawn with plain polygons, back faces
  culled, parts painted far to near, flat-shaded from the part's own
  color. Marker spheres are gone: the engine blended them after the
  depth pass and never sorted them, so the body showed through the beard
  and arms popped in and out whatever the alpha. Settings: a triangle
  budget per frame (`Shapes.MaxTris`, 6000) and a detail distance
  (`Shapes.DetailDistance`, 30 m) replace the old marker budget.

## [0.4.4-beta] - 2026-11-04

- The hover preview threw an error in F8 when the mouse left a row in the
  same frame the preview started (nil `h` in placer.lua). Fixed.

## [0.4.3-beta] - 2026-11-04

- **Inflatables are drawn opaque.** Translucent parts did not sort
  against each other: the body showed through the beard, the belt floated
  through the chest, arms sank into the body and popped back as the draw
  order was re-sorted. Opaque parts depth-test, hold still and have real
  edges. Eyes and noses are smaller; the breathing wobble is gentler.
- **Lights up close.** The glow around a bulb never shrinks below 12 cm
  (`Lights.HaloMin`), and within 12 m the core is a soft round sprite
  instead of a hard diamond (`Lights.NearDistance`). Cast light defaults
  are stronger: every third bulb, intensity 0.6, range 2 m, 48 sources
  per frame. The wire is dimmer. Admins who set their own values keep
  them.

## [0.4.2-beta] - 2026-11-04

- **A location holds a set per holiday.** The Locations tab shows, for
  each location, one chip per holiday it holds with the count and whether
  that holiday is in season (Christmas 20 Â· Halloween 15 at the firehouse);
  the calendar swaps the sets. Admins clear one holiday's set from its
  chip (click twice) and from chat: `/holiday clear firehouse halloween`
  or `holidayadmin clear firehouse halloween`. Saving a layout with "Only
  this holiday" names it after the holiday by default.

## [0.4.1-beta] - 2026-11-04

- **Prop pictures ship.** 91 photographs of the catalog, taken with
  `/holiday thumbs`, are in `html/thumbs/` and show in the Props tab on
  every server.
- The pictures caught two wrong models: the "picnic bench" was a gun-shop
  workbench (now `prop_table_03`, a real picnic table) and the Halloween
  "spider" was a spider plant (removed).

## [0.4.0-beta] - 2026-11-04

- **Locations and layouts.** What was called a "group" is now a
  **location** everywhere a player reads it (Firehouse, 247 Sandy); the
  data and the `group` setting path are unchanged, and `/holiday location`
  joins `/holiday group`. A new **Locations** tab lists every decorated
  location with **Travel** (a fade and a teleport, vehicle included) and
  lets you **save a layout**: a named copy of a location's decorations
  with a note. After a holiday, save, clear; next year **Load** it back
  (adding to or replacing the location), travel there, check it against
  the building, change it, **Save over**. Rename, edit the note, delete;
  **Next location** walks the list. Traveling to a layout stamps it
  "checked" with the date so the list shows what has been reviewed this
  year. `/holiday go <layout>` travels from chat. Layouts live in
  `data/presets.json`; anyone who may decorate can save and load, and
  only the saver or an admin can overwrite, rename or delete.

## [0.3.3-beta] - 2026-11-04

- Prop pictures were written 4 bytes long: the file write stopped at the
  first zero byte of the JPEG. Fixed (the length is passed explicitly).
  Run `/holiday thumbs` again after updating.

## [0.3.2-beta] - 2026-11-04

- **Lit tree (any size)**, a yard piece for Christmas, Kwanzaa and New
  Year's: an evergreen with forty colored bulbs and a gold star that Page
  Up / Page Down size from a tabletop to a plaza tree. Game props cannot
  be scaled (the engine has no entity scale), so this is the tree to use
  when the fixed-size tree props are too small or too large.

## [0.3.1-beta] - 2026-11-04

- **Prop pictures.** `/holiday thumbs` (admin; needs the free
  screenshot-basic resource) photographs every prop in the catalog once:
  each is spawned against the sky, framed by a scripted camera, cropped
  to a 256 px square and written to `html/thumbs/<model>.jpg`. After a
  restart the Props tab shows them, and they ship with the release so
  nobody else has to take them.
- **A calmer panel.** The holiday is one dropdown (in-season ones marked)
  instead of sixteen pills; the tabs fit one row; the header says how
  many holidays are in season (the names are in its tooltip); the help
  paragraphs under each list are a "?" you hover; prop descriptions are
  the row's tooltip; rows are denser; the panel is a little wider.

## [0.3.0-beta] - 2026-11-04

- **Six more sets.** Kwanzaa (Dec 26 to Jan 1), Memorial Day, Labor Day,
  and three dateless sets beside Party: **Wedding**, **Birthday** and
  **Funeral / Memorial**. Each has palettes, props, tips, inflatables,
  wreaths and music. `Season.PartyAlwaysOn` now governs all four dateless
  sets.
- **Walkway arches** (inflatable): candy cane, top hat, Happy Holidays,
  rainbow, fireworks, Pan-African, balloon, wedding, and a thin lit arch.
  An arch's alignment row runs along the path it spans, so place one and
  the next snaps into line down the sidewalk.
- **31 more inflatables:** Mrs. Claus, snowman family, nutcracker, Santa
  in his sleigh, gingerbread house, snow globe, Christmas train, haunted
  tree, witch and cauldron, cat on a pumpkin, grim reaper, stacked
  pumpkins, pilgrim, cornucopia, cupid, eagle, construction worker,
  barbecue grill, kinara, Mardi Gras jester, graduate, baby elephant,
  bride and groom, wedding cake, doves on a heart, champagne toast, party
  hat, stack of presents, balloon bunch.
- **Lit yard pieces** (a new section of the Inflatables tab; drawn
  matte, no inflation): lit deer, Star of Bethlehem, lit ornaments, lit
  orbs, sunflowers, snowflake stake, soldier silhouette, lit cross, lily
  stand, candle vigil, draped casket.
- **Wall pieces** beside the wreaths: window candle, Kwanzaa banner,
  patriotic bunting, mourning bunting; new wreaths for Memorial Day,
  Kwanzaa, Wedding, Birthday and Funeral.
- **Figures:** digits 0 to 9 (hang "2027" or an age; the align tool
  spaces the row), cross, dove, lily, wedding rings, cake, hard hat.
- **Nine tracks:** Harambee (original), Taps, Battle Hymn of the
  Republic, Bridal Chorus, Wedding March, Happy Birthday, Amazing Grace,
  Nearer My God to Thee. All public domain or original.
- Documented: strings and decorations attach to stationary map objects
  only, never to vehicles or anything that moves.

## [0.2.1-beta] - 2026-11-04

- The hover preview's prop ghost is cleared from the placer's handle when
  it is deleted (0.2.0-beta left a stale handle behind).

## [0.2.0-beta] - 2026-11-04

- **Inflatables.** A new Inflatables tab: lawn blow-ups drawn in game
  from lit shapes (no models to stream, works on every build). Snowman,
  Santa, reindeer, penguin, polar bear, candy cane, tree, gingerbread man,
  menorah, dreidel, gold star, champagne bottle, cake, disco ball, heart,
  bear with a heart, shamrock, leprechaun, bunny, Easter egg, chick,
  Uncle Sam hat, firecracker, jack-o-lantern, ghost, black cat, spider,
  bat, witch, turkey, harvest pumpkin, scarecrow, acorn. They **inflate**
  when placed (rising from a heap over a few seconds), **deflate** when
  removed or switched off (Edit tool â†’ Deflate / Inflate), sway in the
  wind while up, and can lie deflated by day (`Shapes.DeflateByDay`).
  Height is set with Page Up / Page Down or the tray. New settings
  section "Inflatables and wreaths"; new record kind `shape`.
- **Wreaths**, one per holiday, at the top of the Props tab: a ring of
  foliage with lights through it and a bow, hung flat on the wall you aim
  at, sized with Page Up / Page Down.
- **34 more rope-light figures** (47 in all): snowman, reindeer, Santa
  hat, stocking, gingerbread man, angel, present, bow, candle, dreidel,
  Star of David, champagne glass, midnight clock, firework burst, heart
  and arrow, rose, rainbow and pot of gold, leprechaun hat, bunny, chick,
  tulip, US flag, ghost, spider web, skull, witch hat, black cat,
  crescent moon, turkey, maple leaf, pilgrim hat, acorn, balloon, music
  note.
- **See it before you place it.** Figures, inflatables and wreaths have
  pictures in the panel, drawn from the same data the game draws. Point
  at any row (prop, figure, inflatable, wreath) and it appears in the
  world at your crosshair: a prop turns slowly so every side shows. Every
  prop now has a one-line description and its height and width.
- **More props:** hay bales (Thanksgiving, Halloween), roses and a rose
  vase (Valentine's), more ghosts, coffins, porch jack-o-lanterns and bat
  ornaments (Halloween), a 2022 present and a stack of presents
  (Christmas), a single balloon (New Year's).
- `/holiday inflate <holiday> <name> [height]` places an inflatable or
  wreath from chat.

## [0.1.7-beta] - 2026-11-04

- **Numpad + opens the panel** (and closes it). It is a FiveM key binding,
  so players rebind it under Settings > Key Bindings > FiveM; the default
  is the new `Commands.OpenKey` setting (blank disables it).
- **Recording mode.** `/holiday record` hides the chat window (through the
  chat resource's own hide state) and sends this resource's toasts and chat
  lines to F8 instead of the screen; `/holiday record off` restores both.
  Stopping the resource restores the chat too.

## [0.1.6-beta] - 2026-11-03

- **Point at a strand and remove it.** While stringing: the strand under
  the crosshair turns orange; **Delete** (or the tray's "Remove strand
  under crosshair") takes it out. Backspace in an outline mode now undoes
  the whole last outline, not one point. On a placed string: the pick
  tool (`/holiday edit`) highlights the strand you aim at, **Delete**
  removes just that strand (the rest of the string stays), and the tray
  offers "Remove this strand" beside "Remove".
- **Show music heard from the nearest string**, not from the average
  center of the group. A group with strings in two places had its center
  in between and past the "silent beyond" distance: lights danced, no
  music. `/holiday soundtest [track]` plays a track for a few seconds
  with no show involved, and anything the browser refuses to play is
  reported in chat and F8 instead of failing silently.

## [0.1.5-beta] - 2026-11-03

- **Building front** mode in the lights tool: one click on a building's
  front wall lays the string along the wall's top edge and around every
  door, opening and wall-mounted object it finds. Openings are found by
  scanning the wall with probes (a recess or a hole in the face);
  objects by their bounding box against the wall. Flush windows painted
  into the mesh are not found. Default points per string raised 24 â†’ 48
  so a front fits in one string.
- Pick tool: Tab opens the tray even with nothing under the crosshair.

## [0.1.4-beta] - 2026-11-03

- **Outline a surface.** The lights tool has three modes (tray, or G to
  cycle): Click points, **Outline a surface** and **Top edge**. In
  Outline, one click on a sign, a wall or a roof top finds its edges and
  lays a closed string around them; Top edge lays the string along the
  upper edge of a wall or fascia (the eave line). Each click adds its own
  stroke, so a sign and the roof under it go in one string. Backspace
  undoes a point; an outline's points undo one at a time.
- Plain strings now keep their strokes (breaks) when edited.

## [0.1.3-beta] - 2026-11-03

- **Aim and click to edit.** Edit tab â†’ "Aim and click a decoration" (or
  `/holiday edit`): the decoration under the crosshair lights up with its
  name, group and owner; left click opens Remove, Move / Edit the string,
  and Move to group; right click leaves the tool. Strings are picked by the
  crosshair ray, so a string on a roofline is as clickable as a prop.
- **Groups you can see.** Group names may have spaces ("247 sandy",
  "Legion Square"). Every tab that uses a group shows the groups that
  exist as chips with counts and distance; the Edit tab lists them with
  Use and, for admins, Clear. `/holiday groups` prints the same list.
  Decorations can be moved between groups from the list, from the pick
  tool, or by admins at the console (`holidayadmin groups`,
  `holidayadmin clear 247 sandy`).

## [0.1.2-beta] - 2026-11-03

- Lights draw again while stringing: the halo is a textured quad once
  more (the one-triangle variant was back-face culled), with a bright
  guide line over the run and out to the cursor, a reticle at screen
  center in every tool, and tools that reset themselves after an error
  instead of staying "busy" until a restart (`/holiday reset`).
- Bulbs no longer dim at grazing angles (drawn pulled toward the camera)
  and keep their size with distance; a dimmed bulb never drops below a
  third; cores keep their color instead of going pastel.
- A hard per-frame cap on textured polys, with an untextured glow on every
  bulb so nothing past the cap looks dead. Diagnostic renderers (`core`,
  `marker`, `off`) and `Props.Enabled`, all settable from the console with
  `holidayadmin set`. `/holiday rendertest` draws one of each primitive.
- Console `holidayadmin` works from txAdmin (it used to fail silently);
  framework admins and holders of the `command` ACE count as admins.
- Updater: GitHub repository default `csalvatoreJCRP/sals_kewlholidays`.

## [0.1.1-beta] - 2026-11-03

First beta.

- Ten holidays: Christmas, Hanukkah, New Year's, Valentine's Day, St.
  Patrick's Day, Easter, Independence Day, Halloween, Thanksgiving, and a
  dateless Party set.
- A point-and-click decorator panel (NUI): props, lights, figures, shows,
  edit list, tips and settings. Placement follows the crosshair; left click
  places, right click finishes; Tab opens a clickable tray.
- String lights placed point to point on any surface, sagging between
  points, with palettes per holiday, seven patterns, adjustable spacing,
  four channels and six light types (mini, C9, rope, icicle, festoon,
  candle). Bulbs are textured sprites with a hot core and a colored halo.
- Rope-light figures (star, snowflake, tree, candy cane, bell, wreath,
  menorah, heart, shamrock, egg, pumpkin, bat, ring) hung on walls.
- No config.lua: every setting is edited in game from the Settings tab,
  validated on the server, stored in `data/settings.json` and pushed live.
- Props from the game's own catalog, checked at start against the client's
  game build; unavailable ones are hidden, not errors.
- Light shows: a track plus a choreography of the four channels, synchronized
  for everyone in earshot. Five shows ship.
- 27 synthesized tracks, public-domain melodies and originals, generated by
  `tools/build-audio.py`.
- Season calendar with `auto` / `all` / `none` / forced-holiday modes, Easter
  computed per year, midnight rollover without a restart.
- Decorating tips per holiday, in chat and on an on-screen card.
- qb-core, qbx_core, ESX and standalone through a framework adapter; qb-menu
  or ox_lib menus with a full command fallback.
- JSON persistence with load latch, backup, verify and shrink guard.
- Per-player render quality setting; hard per-frame bulb and light budgets.
- Server-side permissions (ACE, jobs, everyone), reach checks, per-player and
  total caps, rate limits.
