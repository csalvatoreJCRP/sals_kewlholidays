# Sal's Kewl Holidays

Holiday decorating for FiveM, done entirely in game. Walk up to a building,
string lights along the roofline, stand a tree in the plaza, hang a lantern by
the door, then press play and the whole block dances to the music. Tag each
piece with its holiday and the season calendar turns it on and off by date,
so a city decorated once stays decorated every year.

Runs on **qb-core, qbx_core, ESX and standalone**, detected automatically.
Free, escrow-protected, no dependencies.

## Features

- **Point and click.** `/holiday` opens the decorator panel. Pick a prop, a
  color scheme or a figure with the mouse; the ghost follows your crosshair;
  left click places it, right click ends. Everything within reach is
  listed with Move and Remove buttons. No commands to memorize.
- **Repeat and align.** The tool stays up after each placement for the next
  one, and the ghost snaps to the nearest decoration of the same kind: same
  heading, same height, and the next equal-spacing slot when two already
  form a row. Hold Alt to place free; nudge 5 cm from the tray.
- **String lights on anything.** Aim and left click to drop a point, and
  the string runs point to point: rooflines, railings, door frames, around
  a tree, along a fence. Strings sag between clips like real ones. Each
  has a color scheme, a pattern (steady, twinkle, chase, alternate, fade,
  wave), bulb spacing and a channel. No custom models; it works on every
  MLO and every vanilla building.
- **Six light types.** Mini lights, C9 bulbs, rope light, icicle lights
  (strands drip from the run), festoon globes, and flickering candles.
  Bulbs render as a crisp hot core with a faint colored halo, the way real
  ones read from across the street, and cast a subtle tint on the wall.
- **Inflatables.** Seventy lawn blow-ups that ship as real game models
  (`stream/`), one smooth skin each, lit from inside with an emissive
  shader and a light that falls on the ground around them, solid enough
  to bump into: turkey, snowman and snowman family, Santa, Mrs. Claus,
  Santa in his sleigh, reindeer, nutcracker, penguin, polar bear,
  gingerbread man and house, snow globe, train, jack-o-lantern, ghost,
  witch, cauldron, grim reaper, haunted tree, bunny, cupid, leprechaun,
  menorah, kinara, eagle, bride and groom, wedding cake, graduate, party
  hat, nine walkway arches and thirty more across the sets. Each comes in
  the size shown on its card.
- **Wreaths**, one per holiday: a ring of foliage with lights through it
  and a bow, hung flat on the wall you aim at.
- **Rope-light figures.** Forty-seven of them: star, snowflake, tree, candy
  cane, bell, wreath, menorah, heart, shamrock, egg, pumpkin, bat, ring,
  snowman, reindeer, stocking, gingerbread man, angel, present, dreidel,
  Star of David, champagne glass, turkey, maple leaf, ghost, spider web,
  skull, witch hat and more, hung flat on any wall and sized with the
  scroll wheel.
- **See it before you place it.** Figures, inflatables and wreaths have
  pictures in the panel; point at any row and it appears in the world at
  your crosshair. Props list what they are and how big.
- **Every setting is changed in game.** There is no config.lua. Admins
  open the Settings tab: permissions, caps, season windows per holiday,
  render budgets, music distances, custom props, custom tracks and the
  show choreographies, all validated on the server and pushed live to
  every player. Stored in `data/settings.json`.
- **Props from the game's own catalog**, checked against the object list:
  Christmas trees (four kinds), snowmen, candy canes, gift boxes, a sleigh,
  jack-o-lanterns, skeletons, ghosts, gravestones, coffins, spiders, US
  flags, fireworks, balloons, a confetti cannon, candles, flowers,
  decorated eggs, shamrocks, hay bales, roses, and more. Props the server's
  game build does not have are hidden from the menu with a count, never an
  error. Add your own streamed props with one line in `shared/holidays.lua`.
- **Fireworks set to the music.** Four launchers (mortar rack, rocket,
  cake, fountain), placed like props at a location and loaded with peony,
  chrysanthemum, willow, ring, spiral, crackle, strobe, salute or holiday
  shapes, in the holiday's colors. Start a show and they fire with it:
  **Follow the music** bursts shells on the melody's own notes (every
  shipped track has a score written from its notes), low notes from one
  end of the row and high notes from the other, long notes as big shells,
  salvos on each new verse, and a finale. Or a program on the beat (Grand,
  Steady, Gentle, Rapid, Finale only), or the show's own fireworks steps.
  Light, normal or heavy.
- **Shapes in the sky.** Hearts, stars, shamrocks, pumpkins, a menorah, the
  Star of David, wedding rings, and at New Year's the year itself, spelled
  across the sky. Drawn shapes turn to face whoever is watching.
- **Countdowns.** Count down to a number of seconds, a time of day or
  midnight (server time): everyone nearby sees the clock, the last ten
  seconds big, a salvo bursts on zero, the banner says "HAPPY NEW YEAR!
  2027" (or the holiday's own), and the show starts.
- **A launch board.** Fire by hand for everyone nearby: a shell or a salvo
  per channel, sweeps, cakes, fountains, shapes and the finale, from the
  Shows tab or from the keyboard in launch mode.
- **Real-looking, harmless.** The game's own firework effects, tinted to
  the launcher's colors, with drawn trails rising to each burst, light that
  falls on the buildings below, and booms that arrive late with distance
  (sound travels 343 m a second). Nothing is an explosion: nobody can be
  hurt and nothing catches fire. Players can turn fireworks off, turn them
  down, or ask for fewer flashes.
- **Rehearse.** Run any show with its fireworks for yourself only, nobody
  else sees or hears it, before the city does.
- **Light shows.** Pick a track and a choreography and every string in your
  group dances to it, in sync for everyone nearby. Strings on different
  channels (roof, windows, tree, door) play against each other. Five shows
  ship: Classic, Dance, Build, Gentle, Strobe. Add your own in `config.lua`.
- **35 tracks, nothing to license.** Synthesized renditions of public-domain
  melodies (Jingle Bells, Deck the Halls, Carol of the Bells, Silent Night,
  Auld Lang Syne, Hava Nagila, Yankee Doodle, In the Hall of the Mountain
  King, Bridal Chorus, Wedding March, Happy Birthday, Taps, Amazing Grace,
  and more) plus original pieces for the holidays with no public-domain
  standard. Drop your own `.ogg` in `audio/` and add a line.
  Volume falls off with distance; players can mute it for themselves.
- **A season calendar.** Decorations are tagged by holiday; `auto` mode
  shows each inside its window (Easter is computed per year), and swaps
  them at midnight without a restart. Admins can force a holiday, show
  everything, or show nothing. Overlapping holidays (Christmas, Hanukkah,
  New Year's) overlap on purpose.
- **Sixteen sets:** Christmas, Hanukkah, Kwanzaa, New Year's, Valentine's
  Day, St. Patrick's Day, Easter, Memorial Day, Independence Day, Labor
  Day, Halloween, Thanksgiving, and four dateless sets for events: Party,
  Wedding, Birthday, and Funeral / Memorial.
- **Walkway arches.** Candy cane, top hat, Happy Holidays, rainbow,
  fireworks, Pan-African, balloon, wedding, and a thin lit arch. Place one
  over the sidewalk and the next snaps into a row along the path.
- **Lit yard pieces.** A lit deer, a Star of Bethlehem on a pole, lit
  ornaments and orbs, sunflowers, snowflake stakes, a soldier silhouette, a
  lit cross, lily stands, a candle vigil, a draped casket. Wall pieces:
  window candles, bunting (patriotic and mourning), banners.
- **Stationary objects only.** Strings, figures and every other decoration
  attach to the map and to fixed objects. They do not attach to vehicles
  or to anything that moves (the pier's Ferris wheel included): a string
  clicked onto one stays where it was clicked.
- **Decorating tips** for each holiday, written for the tools in this
  resource (which channel to put the roofline on, which show suits which
  carol), shown in chat and on an on-screen card.
- **No lag.** Props are local, non-networked objects streamed by distance;
  the server never owns an entity. Lights are rendered under a hard
  per-frame budget (bulbs, glow and real light sources) shared by every
  string on screen, nearer strings getting more, that a player can scale
  with `/holiday quality`. A string that gets less than it needs thins out
  evenly along its length instead of going dark. Bulb positions are computed
  once per string, not per frame.
- **Server-authoritative.** Every placement, move, removal and show is
  checked on the server: permission, catalog, reach, caps, rate limits.
  Decorators who are not admins can only edit their own work.
- **Persistence** to a JSON file inside the resource with the same safety
  rules as Sal's Kewl Signage: never saves before it has loaded, backs up
  before every write, verifies the write, refuses a save that would shrink
  the file by more than the removals it was told about.
- **Winter touches** (optional, off by default): tire trails and footprints
  while Christmas is in season. Weather is left alone unless you say
  otherwise, because your weather resource owns it.
- **Localization:** every player-facing string lives in `locales/en.lua`.

## Requirements

None beyond a FiveM server. Everything else is detected at runtime:

| | Supported |
|---|---|
| Framework | `qb-core`, `qbx_core`, `es_extended`, or none |
| Menu | `qb-menu`, `ox_lib` (without either, every action is a `/holiday` subcommand) |
| Notifications | qb-core, ox_lib, ESX, or GTA's own |
| Game build | Any. Props from newer DLCs appear only on builds that have them (`sv_enforceGameBuild`); the catalog notes which |

## Installation

1. Extract into your server's `resources/` folder. The folder must be named
   `sals_kewlholidays`.
2. Add it to `server.cfg` **after** your framework (and after ox_lib or
   qb-menu if you use them):

```cfg
ensure sals_kewlholidays
```

3. Decide who may decorate. By default: anyone holding the `holiday.decorate`
   ACE, or an on-duty `admin`, `realestate` or `cityhall` job. Admins are:
   qb-core / qbx `admin` or `god` permission holders, ESX `admin` /
   `superadmin`, anyone allowed FXServer's `command` ACE, or anyone holding
   `holiday.admin`. To grant it explicitly:

```cfg
add_ace group.admin holiday.admin allow                    # if your admins are in group.admin
add_ace identifier.license:<your license> holiday.admin allow   # or one person by identifier
```

4. Start the server, join as an admin, open `/holiday` and go to
   **Settings**. Everything else (who may decorate, caps, season dates,
   render budgets, music, custom props and tracks, shows) is set there and
   applies to everyone immediately. There is no config.lua.
5. The console prints one line confirming what it found:

```
[sals_kewlholidays] framework: qb  |  decorations: 0 loaded from data/decorations.json  |  season: auto
```

Keep the `data/` folder when you upgrade: it holds every decoration placed on
your server.

## Decorating

`/holiday` or **numpad +** opens the decorator panel (and closes it again).
The key is a FiveM key binding, so each player can change it under Settings
> Key Bindings > FiveM; admins set the default with `Commands.OpenKey`. Tabs:
Props, Lights, Figures, Inflatables, Fireworks, Shows, Edit, Locations, Tips,
Settings.

Point at any row in the panel and it appears in the world where your
crosshair is: a prop turns slowly so every side shows, a figure hangs on
the wall you are aiming at, an inflatable stands there. Inflatables have
photos in the panel; figures and wreaths have pictures drawn from the
same data the game draws; props carry a one-line description and their
height and width.

Recording a video? `/holiday record` hides the chat window and sends this
resource's messages to F8 instead of the screen; `/holiday record off` puts
everything back.

**Props.** Pick a holiday and a prop and click Place. The ghost sits wherever
your crosshair lands. Scroll rotates it, arrow keys fine-rotate and raise or
lower it, Space squares the heading, R toggles snapping to the ground. Left
click places, right click cancels. Wall props (lanterns) sit flat on the
surface you aim at. Tab shows the cursor so the tray at the bottom of the
screen can be clicked instead.

**Lights.** Pick colors, a light type, a pattern, a channel and spacing, then
click Start stringing. Aim and left click to drop each point; the string
previews live, sagging between points. Right click finishes, Backspace undoes
a point, scroll changes the spacing, 1-4 changes the channel. Tab opens the
tray to change any of it mid-string. Up to 48 points and 120 m per string.

Three ways to lay the points (Mode in the tray, or G to cycle): **Click
points** one at a time; **Outline a surface**, where one click on a sign,
a wall or a roof top finds the edges and wraps the string around them;
**Top edge**, where a click on a wall or fascia runs the string along its
upper edge (the roofline); **Building front**, where a click on a front
wall lays the top edge and a frame around every door, opening and
wall-mounted object the tool can find (recesses and holes in the wall,
and objects set against it; flush windows painted into the mesh are not
found). Each outline click adds its own stroke, so a sign and the roof
under it can go in one string.

**Figures.** Pick a figure, colors and a light type, click Hang on a wall,
aim at a wall, scroll to size it, left click to hang it. Up and Down raise
or lower it. A light pole counts as a wall: aim at the side of the pole
that faces the street and the figure lies flat against it, facing out.

**Hanging from a string.** Figures, wreaths and props can hang from a
string of lights that is already placed. String lights across a road from
pole to pole, then pick a figure and aim at the string: it hangs under the
string at that spot, follows the sag, and faces you, so a figure hung from
a span over a road faces the traffic. Up and Down lower it on a longer
drop. **Hang on strings** in the tray turns it off, and holding Alt ignores
strings for that moment. The piece is its own decoration: moving or
removing the string later leaves it where it was hung.

**Inflatables.** The game has no lawn inflatables, so this resource ships
its own: seventy models in `stream/`, each built from lit shapes and
fused into one smooth vinyl skin, with an emissive
shader so it glows at night and a light inside that falls on the ground
around it. They are real props: they cast shadows, take the game's
lighting, and you bump into them. Pick one, click Place, aim: it is placed
like any prop (scroll rotates, Repeat and Align work). Each comes in the
size shown on its card. An inflatable placed with a version before 1.1.1
as a drawn shape becomes its model, in the same place, the first time the
server starts on the new version.

**Wreaths** and other wall pieces (window candles, bunting, banners) sit at
the top of the Props tab and hang flat on the wall you aim at; Page Up /
Page Down set the size.

**Arches** are in the Inflatables tab. Place one over a walkway facing
along it; with Align on, the next one snaps into a row along the path at
the same spacing, so a sidewalk takes three clicks. **Lit yard pieces**
(deer, stakes, orbs, the lily stands and candle vigil of the Funeral set)
are below the inflatables in the same tab and stand where placed.

**Wedding, Birthday, Funeral.** Like Party, these have no dates: they are
in season whenever the Party set is (Settings). Give each event its own
location so one clear takes it down afterward.

**Locations and channels.** Every decoration belongs to a location, your
current one (default `main`). Name locations after the place: `firehouse`,
`hospital`, `247 sandy` (spaces are fine). The Shows, Edit, Locations and
Settings tabs show every location that exists with its counts and
distance, so you pick one or type a new name; `/holiday locations` prints
the list and `/holiday location <name>` sets yours. Every string of
lights has a channel 1-4 (`/holiday channel <n>`). A show runs against one
location and drives its four channels separately, so the roofline on 1,
the windows on 2, the tree on 3 and the door on 4 can play against each
other.

**Locations tab: travel, and layouts for next year.** Every decorated
location is listed with **Travel** (a fade and a teleport, vehicle
included) and one chip per holiday it holds with the count: a location
is a place, and it holds a set per holiday (Christmas at the firehouse,
Halloween at the same firehouse) that the calendar swaps. Admins clear
one holiday's set from its chip, or `/holiday clear firehouse halloween`.
Below the list, admins have **Clear every decoration on the server**: an
armed button (click, then click again within a few seconds) that takes
down every location and holiday at once, same as `/holiday clear all`;
layouts are kept, and the server writes
`data/decorations.json.before-clear-<time>` first so a wrong click can be
undone by renaming that copy over `decorations.json` and restarting.
**Save my location as a layout** copies everything at your
current location under a name with a note ("Firehouse 2026: roofline on
channel 1, check the new awning"). After the holiday, clear the location;
next year **Load** the layout back (adding to the location, or replacing
it), travel there, check it against the building, change what an MLO
update broke, and **Save over**. Rename, edit the note, delete; **Next
location** walks the list. Traveling to a layout stamps it "checked" with
the date, so the list shows what has been reviewed this year.
`/holiday go <layout>` travels from chat. Layouts live in
`data/presets.json`; anyone who may decorate can save and load, and only
the saver or an admin can overwrite, rename or delete one.

**Shows.** `/holiday show` lists the tracks (in-season first); pick one and a
choreography. Everyone within `Config.Music.Far` meters of the group's lights
hears it and sees the same thing. `/holiday stop` ends it; it ends itself when
the track does. Starting a show for a holiday that is out of season is
refused unless you are an admin.

**Editing.** Edit tab → **Aim and click a decoration** (or `/holiday edit`):
aim at anything placed and it lights up with its name, group and owner;
left click opens **Remove**, **Move** (or **Edit the string**, which re-runs
the point tool on it) and **Move to group**; right click leaves the tool.
On a string with several strands, the strand you aim at turns orange and
**Remove this strand** (or the Delete key) takes out just that one. While
still stringing, Delete removes the strand under the crosshair too.
The Edit tab also lists everything within reach with the same buttons and
a group dropdown, plus **Undo my last placement**. `/holiday remove` takes
the nearest decoration, `/holiday undo` the last one you placed. Admins
can clear a whole location from the Edit tab's list.

### Fireworks

**Placing launchers.** The Fireworks tab lists the four launchers. Pick one,
choose what it is **loaded with**, its **colors** (the holiday's own, or
gold, silver or rainbow), a **channel**, how high it **bursts** (low,
medium, high), its **aim** (tilted up to 35 degrees toward its front, to fan
a row of mortars), and whether it is a **hidden launch point** (no prop:
shells rise from a roof or from behind a wall; decorators see a marker
there while preview is on). **Preview** fires that launcher thirty meters
in front of you, for you only. **Place** works like any prop: it joins your
current location, aligns, repeats.

A location's launchers are ordered across it along their longest spread, so
"low notes on the left" means one end of your row and high notes the other.
A good layout: mortars along the back, cakes in a row in front of them,
fountains at the very front, each row on its own channel.

Every firework prop is a launcher, including ones placed before 1.2.0 from
the Props tab; they start loaded Mixed, on channel 1, in the holiday's
first colors. Change a placed launcher's settings from the Edit tab
(**Settings...**), and **Test** fires it for you only. The pick tool has
Test too.

**Shows with fireworks.** In the Shows tab, under the choreography, choose
the **Fireworks** program and **how much** (light, normal, heavy). A show at
a location with launchers fires them; a location with launchers and no
light strings can run a show too.

- **Follow the music**: the track's score (every shipped track has one);
  a track you added gets Grand at its tempo.
- **Grand / Steady / Gentle / Rapid**: programs on the beat.
- **Finale only**: nothing until the last part of the track.
- **From the show**: the show's own fireworks steps. In Settings > Shows,
  each step has a fireworks pattern per channel: beat, double, salvo,
  sweep, cake, fountain, shape or finale. The shipped **Sky Show** is an
  example.

**Rehearse** runs a show and its fireworks for you only. **Countdown** opens
a row on the track: enter seconds (`30`), a time of day in server time
(`23:59:50`, `00:00`) or `midnight`, and start it. Everyone near the
location sees the clock, big for the last ten seconds; a salvo bursts on
zero, the holiday's banner shows, and the show starts. **Stop** cancels a
countdown.

**Firing by hand.** With launchers at your location, the Shows tab has a
**launch board**: Shell and Salvo for each channel, and Salvo, Sweep, Cake,
Fountains, Shape and Finale for all of them. **Launch mode** does the same
from the keyboard with the panel closed: `1`-`4` a shell from that channel
(Shift: a salvo), `5` sweep, `6` cake, `7` fountains, `8` shape, `9` twice
for the finale, Backspace to leave.

**For each player.** Settings > My settings: fireworks on or off, their
volume, **whistles** on or off (off: shells leave with a thump), and
**fewer flashes** (no light from the bursts, no strobes or white salutes)
for anyone who finds flashing hard to watch.

**Whistles.** A whistle is a steady high tone and stands out much farther
than a boom of the same volume, so whistles fade out over their own,
shorter distance: Settings > Fireworks > **Whistles heard within** (250 m).
**Whistles** in the same section turns them off for the whole server.

**Checking a game build.** `/holiday fwtest` fires every effect in turn in
front of you and writes each one's name in F8, with whether its particle
dictionary loaded. The heart, star and face shapes and the large bursts
need a newer game build; on an older one the drawn shapes and the base
game's bursts stand in.

**Tips.** `/holiday tips [holiday]` prints the decorating tips for the holiday
in season (or the one named) and shows them on a card for 45 seconds.

## Commands

| Command | Who | What |
|---|---|---|
| `/holiday` | Anyone | Open or close the decorator panel (default key: numpad +) |
| `/holiday record [on\|off]` | Anyone | Recording mode: hide the chat window and holiday messages |
| `/holiday prop <holiday> <model>` | Decorators | Place a prop by model name |
| `/holiday lights <holiday> [palette] [pattern] [type]` | Decorators | String lights |
| `/holiday figure <holiday> <figure> [palette]` | Decorators | Hang a figure |
| `/holiday inflate <holiday> <name>` | Decorators | Place an inflatable by name (`turkey`, `arch_candy`) |
| `/holiday wreath <holiday> <name> [size]` | Decorators | Place a wreath, wall piece or yard piece by name |
| `/holiday edit` | Decorators | Aim at a decoration: remove, move, edit, regroup it |
| `/holiday remove` / `undo` | Decorators | Remove the nearest / last decoration |
| `/holiday locations` | Anyone | Every location, with counts and distance |
| `/holiday location <name>` | Anyone | Set the location new decorations join (spaces allowed) |
| `/holiday go <layout>` | Decorators | Travel to a saved layout |
| `/holiday channel <1-4>` | Anyone | Set the channel new strings use |
| `/holiday show [track] [show] [fireworks] [light\|normal\|heavy]` | Decorators | Start a show in your group; fireworks is `score`, `grand`, `steady`, `gentle`, `rapid`, `finale`, `show` or `off` (default: `score` where there are launchers) |
| `/holiday rehearse <track> [show] [fireworks]` | Decorators | The show for you only |
| `/holiday countdown <seconds\|HH:MM\|midnight> <track> [show] [fireworks]` | Decorators | Count down, then the show |
| `/holiday stop [group]` | Decorators | Stop the show or the countdown |
| `/holiday launch` | Decorators | Launch mode: fire from the keyboard |
| `/holiday fire <shell\|salvo\|sweep\|cake\|fountain\|shape\|finale> [channel]` | Decorators | Fire by hand |
| `/holiday fireworks on\|off\|calm\|normal\|volume <0-1>\|whistle on\|off` | Anyone | Fireworks, for you only |
| `/holiday fwtest` | Anyone | Every firework effect in front of you, named in F8 |
| `/holiday tips [holiday]` | Anyone | Decorating tips |
| `/holiday mute` / `unmute` | Anyone | Holiday music, for you only |
| `/holiday soundtest [track]` | Anyone | Play a track for a few seconds, no show needed |
| `/holiday quality <low\|medium\|high\|ultra>` | Anyone | Light render budget, for you only |
| `/holiday season [auto\|all\|none\|<holiday>]` | Admins | Show or set the season mode (saved) |
| `/holiday thumbs [holiday]` | Admins | Photograph the props for the panel (needs screenshot-basic; restart to see them) |
| `/holiday clear <location\|all> [holiday]` | Admins | Remove decorations, or only one holiday's set there |
| `/holiday status` | Admins | Saving health and counts |
| `holidayadmin season\|groups\|clear\|status [arg]` | Console | The same, from the server console |

The command name is `Config.Commands.Main`.

## Settings (in game, admins)

Open `/holiday` and the Settings tab. Sections:

- **Who may decorate**: everyone, an ACE, jobs (on duty or not), whether
  decorators may edit others' work, per-player and total caps, reach,
  whether anyone may press play on a show.
- **Season calendar**: mode (`auto` / `all` / `none` / one holiday), the
  Party set, winter touches. Per-holiday dates and on/off; Hanukkah's
  shipped window is wide and worth setting each year.
- **Props / Lights / Music**: stream and render distances, the per-frame
  bulb and light budgets, halo and sag, whether bulbs cast light, hearing
  distances and volume.
- **Inflatables and wreaths**: whether the inflatable models are solid,
  and, for wreaths and yard pieces, render and detail distances and the
  per-frame shape and light budgets.
- **Fireworks**: on or off for everyone; the look (`both`: the game's
  bursts plus drawn trails and shapes; `game`; `drawn`); burst size; only after dark
  (by each player's game clock); launchers per location; shells per
  second and drawn sparks per frame (each player's quality setting scales
  them); how far they are seen and heard; volume; sound arriving late with
  distance; burst light; firing by hand; the longest countdown.
- **Custom props**: add any streamed model to a holiday (model, label, wall
  mount).
- **Custom tracks**: register an `.ogg` you dropped in `audio/`.
- **Shows**: copy a shipped choreography and edit its steps, or build one
  from scratch: beats per step, a light pattern per channel and, optionally,
  a fireworks pattern per channel.
- **Reset** puts everything back to the shipped defaults.

Changes are validated on the server, saved to `data/settings.json`, and
applied to every player at once. The defaults and what each setting means
are in `shared/defaults.lua`.

## For developers

```lua
-- Server
exports['sals_kewlholidays']:GetActiveHolidays()        --> { christmas = true, ... }
exports['sals_kewlholidays']:GetSeasonMode()            --> 'auto'
exports['sals_kewlholidays']:StartShow(group, track, show, fw) --> boolean
-- fw: nil for none, or { mode = 'score' | 'grand' | 'steady' | 'gentle' | 'rapid' | 'finale' | 'show',
--                         intensity = 'light' | 'normal' | 'heavy' }
exports['sals_kewlholidays']:StartCountdown(group, target, track, show, fw) --> boolean
-- target: seconds, 'HH:MM[:SS]' (server time) or 'midnight'
exports['sals_kewlholidays']:FireFireworks(group, action, channel) --> boolean
-- action: 'shell' | 'salvo' | 'sweep' | 'cake' | 'fountain' | 'shape' | 'finale'
exports['sals_kewlholidays']:StopShow(group)            --> boolean
exports['sals_kewlholidays']:IsShowRunning(group)       --> boolean
exports['sals_kewlholidays']:GetDecorations()           --> list of records
```

Records: `{ id, kind = 'prop' | 'lights', holiday, group, by, byName, updated,
model, coords, heading }` for props, plus `fw = { load, palette, channel,
lift, tilt, hidden }` for a launcher; `{ ..., points, palette, pattern,
spacing, channel, length }` for lights.

The firework effects, launchers, loads, holiday shapes and programs are in
`shared/fireworks.lua`, readable and editable: an effect lists the game's
particle effects to try in order, with what to draw where none loads.

## Updates

The resource checks a public GitHub repository for a newer release and can
apply it. The shipped repository is
[csalvatoreJCRP/sals_kewlholidays](https://github.com/csalvatoreJCRP/sals_kewlholidays)
on `main` (Settings → Updates to change it). It fetches `update.json` at start and
every few hours; a newer version is announced in the console and in the
Settings tab, where **Apply update** downloads every file in the manifest,
verifies each by size and CRC32 before writing anything, never touches
`data/`, and asks for a restart. **Apply updates automatically** does that
on its own; **Restart after applying** restarts the resource a minute later
when no show is running. `/holidayadmin update check|apply` does the same
from chat or the server console.

Limits, by design: a resource cannot create folders or delete files, so a
release that adds a new folder reports the files it could not place (create
the folder and apply again), and files a release removed simply stop being
loaded.

### Publishing a release (vendor)

1. Build with `package.ps1`, upload the `-cfx.zip` to Keymaster, wait for
   it to process, download the escrowed build.
2. `.\publish-release.ps1 -Zip <that download>` does the rest: it unpacks
   the zip, refuses to go on if any Lua that should be encrypted is still
   plain text (every `.lua` outside `escrow_ignore` must carry the `FXAP`
   escrow header), checks the version matches this tree, clones or
   updates `..\sals_kewlholidays-public`, replaces its contents with the
   build, writes `update.json` with `tools/make-update-manifest.py`,
   commits `Release <version>`, tags `v<version>`, pushes, attaches the
   zip to a GitHub Release (`gh` CLI), and fetches the published
   `update.json` back to confirm. `-DryRun` does everything but commit,
   push and release.

By hand, the same thing is: `python tools/make-update-manifest.py
<escrowed folder>` (writes `update.json` beside its `fxmanifest.lua`: the
version, the newest CHANGELOG section, every file's size and CRC32, with
`data/`, `tools/`, `docs/` excluded), then commit that folder's contents
with `update.json` to the root of the public repository on the branch
customers' servers are set to.

## Rebuilding the music

`tools/build-audio.py` synthesizes every track from note data (numpy and
ffmpeg required). Edit a tune, run it, and the `.ogg` in `audio/` is
replaced. The public-domain melodies are marked as such in the file; the
rest are original.

`tools/build-fireworks.py` writes the firework scores
(`shared/fireworks_scores.lua`) from the same notes, and synthesizes the
firework sounds in `audio/sfx/`. Run it after changing a tune so its score
still lands on the notes. A track you added has no score; Follow the music
gives it the Grand program at its tempo.

## Support

Discord: https://discord.salskewlkorner.com · Manual:
https://salskewlkorner.com/documentation/

## License

Proprietary. All rights reserved. See [LICENSE](LICENSE).
