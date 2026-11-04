# Changelog

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
