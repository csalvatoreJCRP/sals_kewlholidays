// The decorator panel, the placement tray, the tips card and the music.
// Every click posts one small message to the Lua side; the page holds no
// state the game does not already know.

(function () {
    'use strict';
    const RES = (typeof GetParentResourceName === 'function') ? GetParentResourceName() : 'sals_kewlholidays';
    const $ = id => document.getElementById(id);

    function post(name, data) {
        return fetch(`https://${RES}/${name}`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(data || {}) }).catch(() => {});
    }
    function el(tag, cls, text) {
        const e = document.createElement(tag);
        if (cls) e.className = cls;
        if (text !== undefined) e.textContent = text;
        return e;
    }
    function rgb(c) { return `rgb(${c[0]},${c[1]},${c[2]})`; }

    // ------------------------------------------------------------------
    // State
    // ------------------------------------------------------------------
    const S = {
        data: null, tab: 'props', holiday: null, search: '',
        lights: { palette: null, pattern: 'twinkle', style: 'mini', channel: 1, spacing: 0.2, sag: true },
        figure: { name: null, palette: null, pattern: 'on', style: 'rope', channel: 1, size: 1.2 },
        show: { track: null, show: 'classic', fwMode: 'score', fwIntensity: 'normal' },
        fw: { rack: 'mortar', load: 'mixed', palette: null, channel: 1, lift: 1.0, tilt: 0, hidden: false },
        spot: { fixture: 'flood', mode: 'beam', beam: 'wide', bright: 1.0, palette: null, rgb: null, cycle: false, pattern: 'on', channel: 1, hidden: false, art: null, scale: 1.0, speed: 1.0 },
        countdown: { target: '10', open: false },
        sleigh: { pairs: 2, coat: 'mixed', pose: 'stand', nose: true, ride: true, presents: true },
        ball: { height: 14, ball: 2.4, seconds: 60, pattern: 'rainbow', palette: null },
        editing: null,
        settings: null, tipsInline: null,
    };
    const T = key => (S.data && S.data.strings && S.data.strings[key]) || key;

    // ------------------------------------------------------------------
    // Panel
    // ------------------------------------------------------------------
    const TABS = ['props', 'lights', 'figures', 'inflatables', 'fireworks', 'spotlights', 'extras', 'shows', 'edit', 'places', 'vehicles', 'tips', 'settings'];
    const PLACING = ['props', 'lights', 'figures', 'inflatables', 'fireworks', 'spotlights', 'extras'];

    // ------------------------------------------------------------------
    // Thumbnails and hover previews
    // ------------------------------------------------------------------
    const SVG = 'http://www.w3.org/2000/svg';
    function svgEl(tag, attrs) {
        const e = document.createElementNS(SVG, tag);
        for (const k in attrs) e.setAttribute(k, attrs[k]);
        return e;
    }
    // A shape drawn from its parts: a front view, far parts first, each
    // ellipsoid an ellipse with a highlight so it reads as round. The
    // same data the game draws, so what is in the list is what is placed.
    function shapeThumb(parts, kind) {
        const svg = svgEl('svg', { viewBox: '-0.62 -1.06 1.24 1.14', class: 'thumb' });
        const alpha = kind === 'wreath' ? 1 : 0.9;
        const sorted = parts.slice().sort((a, b) => a.p[1] - b.p[1]);
        for (const p of sorted) {
            const [x, y, z, rx, ry, rz] = p.p;
            const c = p.c;
            const rot = p.rot || [0, 0, 0];
            // A tilt about y shows as a rotation in the picture; a tilt about
            // x shortens the vertical radius a little.
            const tx = Math.abs(rot[0]) * Math.PI / 180;
            const ryy = rz * Math.cos(tx) + ry * Math.sin(tx);
            const g = svgEl('g', { transform: `translate(${x} ${-z}) rotate(${-rot[1]})` });
            g.appendChild(svgEl('ellipse', { cx: 0, cy: 0, rx: rx, ry: ryy, fill: `rgb(${c[0]},${c[1]},${c[2]})`, 'fill-opacity': p.a ? 1 : alpha }));
            g.appendChild(svgEl('ellipse', { cx: -rx * 0.3, cy: -ryy * 0.3, rx: rx * 0.45, ry: ryy * 0.45, fill: '#fff', 'fill-opacity': 0.22 }));
            g.appendChild(svgEl('ellipse', { cx: 0, cy: 0, rx: rx, ry: ryy, fill: 'none', stroke: '#000', 'stroke-opacity': 0.25, 'stroke-width': 0.006 }));
            svg.appendChild(g);
        }
        return svg;
    }
    // A figure drawn from its strokes, in the holiday's first color with a glow.
    function figureThumb(strokes, color) {
        const svg = svgEl('svg', { viewBox: '-1.15 -1.15 2.3 2.3', class: 'thumb fig' });
        const col = rgb(color || [255, 210, 90]);
        for (const s of strokes) {
            const pts = s.map(p => `${p[0]},${-p[1]}`).join(' ');
            svg.appendChild(svgEl('polyline', { points: pts, fill: 'none', stroke: col, 'stroke-opacity': 0.35, 'stroke-width': 0.16, 'stroke-linejoin': 'round', 'stroke-linecap': 'round' }));
            svg.appendChild(svgEl('polyline', { points: pts, fill: 'none', stroke: '#fff', 'stroke-width': 0.05, 'stroke-linejoin': 'round', 'stroke-linecap': 'round' }));
        }
        return svg;
    }
    // The row under the mouse is shown in the world. One message in, one
    // out; moving between rows re-posts with the new key.
    function hoverable(node, kind, holiday, key) {
        node.addEventListener('mouseenter', () => post('hover', { kind, holiday, key }));
        node.addEventListener('mouseleave', () => post('hoverEnd'));
    }
    function dimsText(d) {
        if (!d) return '';
        return `${d.h} m ${T('ui_tall')} · ${d.w} m ${T('ui_wide')}`;
    }

    function holiday() {
        return S.data.holidays.find(h => h.name === S.holiday) || S.data.holidays[0];
    }
    function setAccent(c) {
        document.documentElement.style.setProperty('--accent', rgb(c));
        document.documentElement.style.setProperty('--accent-soft', `rgba(${c[0]},${c[1]},${c[2]},0.18)`);
    }

    function openPanel(data) {
        S.data = data;
        S.lights.channel = data.settings.channel;
        S.figure.channel = data.settings.channel;
        if (!S.holiday || !data.holidays.some(h => h.name === S.holiday)) {
            const first = data.holidays.find(h => h.inSeason && !['party', 'wedding', 'birthday', 'funeral'].includes(h.name)) || data.holidays[0];
            S.holiday = first.name;
        }
        $('p-title').textContent = T('ui_title');
        $('panel').classList.remove('hidden');
        render();
    }
    function closePanel() { $('panel').classList.add('hidden'); }

    function render() {
        const d = S.data;
        const h = holiday();
        setAccent(h.accent || [224, 58, 58]);
        const active = Object.keys(d.season.active || {}).map(n => (d.holidays.find(x => x.name === n) || {}).label || n).sort();
        const seasonEl = $('p-season');
        seasonEl.textContent = `${T('ui_season')}: ${d.season.mode} · ${T('ui_in_season_count').replace('%{count}', active.length)}`;
        seasonEl.title = active.length ? active.join(', ') : '-';

        const tabs = $('p-tabs');
        tabs.innerHTML = '';
        for (const t of TABS) {
            const b = el('button', 'tab', T('ui_tab_' + t));
            b.setAttribute('role', 'tab');
            b.setAttribute('aria-selected', S.tab === t);
            b.addEventListener('click', () => { S.tab = t; render(); if (t === 'settings' && d.who.admin && !S.settings) post('settingsGet'); if (t === 'tips') post('tips', { holiday: S.holiday }); });
            tabs.appendChild(b);
        }
        const body = $('p-body');
        body.innerHTML = '';
        const editingFloat = d.floats && d.floats.editing;
        if (!d.who.decorator && PLACING.includes(S.tab) && !editingFloat) {
            body.appendChild(el('div', 'note', T('ui_not_decorator')));
        }
        if (editingFloat && PLACING.includes(S.tab)) {
            // Everything placed now rides on the float: say so, with Done.
            const bar = el('div', 'item active');
            const main = el('div', 'main');
            main.appendChild(el('div', 't', T('ui_fl_editing').replace('%{name}', editingFloat.name)));
            main.appendChild(el('div', 'd', T('ui_fl_editing_help')));
            bar.appendChild(main);
            const done = el('button', 'btn small primary', T('ui_fl_done'));
            done.addEventListener('click', () => post('floatDone'));
            bar.appendChild(done);
            body.appendChild(bar);
        }
        if (PLACING.includes(S.tab) && S.tab !== 'extras' && !h.inSeason) {
            body.appendChild(el('div', 'note', T('ui_off_season_note').replace('%{holiday}', h.label).replace('%{mode}', d.season.mode)));
        }
        stopArtPreviews();
        ({ props: renderProps, lights: renderLights, figures: renderFigures, inflatables: renderInflatables, fireworks: renderFireworks, spotlights: renderSpotlights, extras: renderExtras, shows: renderShows, edit: renderEdit, places: renderPlaces, vehicles: renderVehicles, tips: renderTips, settings: renderSettings })[S.tab](body);

        const foot = $('p-foot');
        foot.innerHTML = '';
        foot.appendChild(el('span', '', `${T('ui_group')}: ${d.settings.group}  ·  ${T('ui_channel')} ${d.settings.channel}`));
        foot.appendChild(el('span', '', d.nowPlaying ? `${T('ui_now_playing')}: ${trackLabel(d.nowPlaying.track)}` : ''));
    }

    function trackLabel(name) { const t = S.data.tracks.find(x => x.name === name); return t ? t.label : name; }

    // The holiday picker: one dropdown, in-season ones marked, instead of
    // a wall of sixteen chips.
    function holidayChips(container, onPick, includeAll) {
        const row = el('div', 'holiday-row');
        const sel = el('select', 'input holiday-select');
        sel.title = T('ui_pick_holiday');
        const list = includeAll ? [{ name: '*', label: T('ui_all_holidays') }].concat(S.data.holidays) : S.data.holidays;
        for (const h of list) {
            const o = el('option', '', (h.name !== '*' && h.inSeason ? '● ' : '') + h.label + (h.name !== '*' && !h.inSeason ? '  (' + T('ui_off_season') + ')' : ''));
            o.value = h.name;
            if (S.holiday === h.name) o.selected = true;
            sel.appendChild(o);
        }
        sel.addEventListener('change', () => { S.holiday = sel.value; onPick(); });
        row.appendChild(sel);
        container.appendChild(row);
    }
    // A small "?" that holds the help text, instead of a paragraph under
    // every list.
    function help(container, text) {
        const q = el('span', 'q', '?');
        q.title = text;
        container.appendChild(q);
        return q;
    }
    function section(container, label, helpText) {
        const box = el('div');
        const head = el('div', 'label');
        head.appendChild(document.createTextNode(label));
        if (helpText) help(head, helpText);
        box.appendChild(head);
        container.appendChild(box);
        return box;
    }
    // A prop's picture, if /holiday thumbs has taken one; hidden otherwise.
    function propThumb(model) {
        const img = el('img', 'thumb photo');
        img.alt = '';
        img.src = `thumbs/${model}.jpg`;
        img.addEventListener('error', () => { img.classList.add('missing'); });
        return img;
    }

    // ---- Props ----
    function renderProps(body) {
        holidayChips(body, render);
        const h = holiday();
        if (h.wreaths && h.wreaths.length) {
            const box = section(body, T('ui_wreaths'), T('ui_wreaths_help') + ' ' + T('ui_hover_hint'));
            const wl = el('div', 'list');
            for (const s of h.wreaths) wl.appendChild(shapeRow(h, s));
            box.appendChild(wl);
        }
        const pbox = section(body, T('ui_tab_props'), T('ui_hover_hint'));
        const search = el('input', 'input');
        search.type = 'text'; search.id = 'prop-search'; search.placeholder = T('ui_search'); search.value = S.search;
        search.addEventListener('input', () => { S.search = search.value; renderPropList(list, h); });
        pbox.appendChild(search);
        const list = el('div', 'list');
        pbox.appendChild(list);
        renderPropList(list, h);
        if (h.hidden > 0) body.appendChild(el('div', 'note', T('ui_hidden_props').replace('%{count}', h.hidden)));
    }
    function renderPropList(list, h) {
        list.innerHTML = '';
        const q = S.search.trim().toLowerCase();
        for (const p of h.props) {
            if (q && !(p.label.toLowerCase().includes(q) || p.model.includes(q) || (p.desc || '').toLowerCase().includes(q))) continue;
            const it = el('div', 'item');
            it.appendChild(propThumb(p.model));
            const main = el('div', 'main');
            main.appendChild(el('div', 't', p.label));
            const meta = [dimsText(p.dims), p.wall ? T('ui_wall') : '', p.custom ? 'custom' : ''].filter(Boolean).join('  ·  ');
            main.appendChild(el('div', 'd', meta || p.model));
            it.title = (p.desc ? p.desc + '\n' : '') + p.model;
            it.appendChild(main);
            const b = el('button', 'btn small primary', T('ui_place'));
            b.disabled = !S.data.who.decorator;
            b.addEventListener('click', () => post('placeProp', { holiday: h.name, model: p.model }));
            it.appendChild(b);
            hoverable(it, 'prop', h.name, p.model);
            list.appendChild(it);
        }
    }
    // One inflatable, wreath or yard piece: thumbnail, name, what it is,
    // default size, Place. An inflatable is a model (s.model): it places
    // that prop and shows its photo. Wreaths and yard pieces are drawn
    // from their parts.
    function shapeRow(h, s) {
        const it = el('div', 'item');
        it.appendChild(s.model ? propThumb(s.model) : shapeThumb(s.parts, s.kind));
        const main = el('div', 'main');
        main.appendChild(el('div', 't', s.label));
        main.appendChild(el('div', 'd', `${s.size.toFixed(1)} m ${s.kind === 'wreath' ? T('ui_wide') : T('ui_tall')}`));
        if (s.desc) it.title = s.desc + (s.model ? '\n' + s.model : '');
        it.appendChild(main);
        const b = el('button', 'btn small primary', T('ui_place'));
        b.disabled = !S.data.who.decorator;
        b.addEventListener('click', () => s.model
            ? post('placeProp', { holiday: h.name, model: s.model })
            : post('placeShape', { holiday: h.name, shape: s.name, size: s.size }));
        it.appendChild(b);
        hoverable(it, s.model ? 'prop' : 'shape', h.name, s.model || s.name);
        return it;
    }
    function renderInflatables(body) {
        holidayChips(body, render);
        const h = holiday();
        if ((h.inflatables || []).length) {
            const ibox = section(body, T('ui_tab_inflatables'), T('ui_inflatables_help') + ' ' + T('ui_hover_hint'));
            const list = el('div', 'list');
            for (const s of h.inflatables) list.appendChild(shapeRow(h, s));
            ibox.appendChild(list);
        }
        if ((h.yard || []).length) {
            const box = section(body, T('ui_yard'), T('ui_yard_help'));
            const yl = el('div', 'list');
            for (const s of h.yard) yl.appendChild(shapeRow(h, s));
            box.appendChild(yl);
        }
        if (!(h.inflatables || []).length && !(h.yard || []).length) body.appendChild(el('div', 'note', '-'));
    }

    // ---- Shared light controls ----
    function paletteSwatches(container, h, state, onChange) {
        if (!state.palette || !h.palettes.some(p => p.name === state.palette)) state.palette = h.palettes[0] && h.palettes[0].name;
        const wrap = el('div', 'swatches');
        for (const p of h.palettes) {
            const b = el('button', 'sw');
            for (const c of p.colors) { const i = el('i'); i.style.background = rgb(c); i.style.color = rgb(c); b.appendChild(i); }
            b.appendChild(document.createTextNode(p.name.replace(/_/g, ' ')));
            b.setAttribute('aria-pressed', state.palette === p.name);
            b.addEventListener('click', () => { state.palette = p.name; onChange(); });
            wrap.appendChild(b);
        }
        container.appendChild(wrap);
    }
    function segment(container, options, value, onPick, labelFn) {
        const seg = el('div', 'seg');
        for (const o of options) {
            const b = el('button', '', labelFn ? labelFn(o) : o);
            b.setAttribute('aria-pressed', String(value) === String(o));
            b.addEventListener('click', () => onPick(o));
            seg.appendChild(b);
        }
        container.appendChild(seg);
    }
    function labeled(container, label) {
        const box = el('div');
        box.appendChild(el('div', 'label', label));
        container.appendChild(box);
        return box;
    }

    function renderLights(body) {
        holidayChips(body, render);
        const h = holiday();
        paletteSwatches(labeled(body, T('ui_palette')), h, S.lights, render);
        segment(labeled(body, T('ui_style')), S.data.styles.map(s => s.name), S.lights.style, v => {
            S.lights.style = v; const st = S.data.styles.find(s => s.name === v); if (st && st.spacing) S.lights.spacing = st.spacing; render();
        }, v => (S.data.styles.find(s => s.name === v) || {}).label || v);
        segment(labeled(body, T('ui_pattern')), S.data.patterns, S.lights.pattern, v => { S.lights.pattern = v; render(); }, v => T('pattern_' + v));
        const row = el('div', 'row');
        const chBox = labeled(row, T('ui_channel'));
        segment(chBox, [1, 2, 3, 4], S.lights.channel, v => { S.lights.channel = v; render(); });
        const spBox = labeled(row, `${T('ui_spacing')}: ${S.lights.spacing.toFixed(2)}`);
        spBox.classList.add('grow');
        const range = el('input'); range.type = 'range'; range.id = 'spacing'; range.min = S.data.lights.minSpacing; range.max = S.data.lights.maxSpacing; range.step = 0.01; range.value = S.lights.spacing;
        range.addEventListener('input', () => { S.lights.spacing = parseFloat(range.value); spBox.firstChild.textContent = `${T('ui_spacing')}: ${S.lights.spacing.toFixed(2)}`; });
        spBox.appendChild(range);
        body.appendChild(row);
        const sagRow = el('div', 'row');
        sagRow.appendChild(el('span', '', T('ui_sag')));
        const sagSw = el('button', 'switch'); sagSw.setAttribute('role', 'switch'); sagSw.setAttribute('aria-checked', S.lights.sag);
        sagSw.addEventListener('click', () => { S.lights.sag = !S.lights.sag; sagSw.setAttribute('aria-checked', S.lights.sag); });
        sagRow.appendChild(sagSw);
        help(sagRow, T('ui_sag_help'));
        body.appendChild(sagRow);
        const go = el('button', 'btn primary', T('ui_string'));
        go.disabled = !S.data.who.decorator;
        go.title = T('ui_tray_hint_lights');
        go.addEventListener('click', () => post('placeLights', { holiday: h.name, palette: S.lights.palette, pattern: S.lights.pattern, style: S.lights.style, channel: S.lights.channel, spacing: S.lights.spacing, sag: S.lights.sag }));
        body.appendChild(go);
    }

    function renderFigures(body) {
        holidayChips(body, render);
        const h = holiday();
        const list = el('div', 'figgrid');
        if (!h.figures.some(f => f.name === S.figure.name)) S.figure.name = h.figures[0] && h.figures[0].name;
        const pal = h.palettes.find(p => p.name === S.figure.palette) || h.palettes[0];
        const color = pal && pal.colors && pal.colors[0];
        for (const f of h.figures) {
            const b = el('button', 'figcell');
            b.appendChild(figureThumb(f.strokes || [], color));
            b.appendChild(el('span', '', f.label));
            b.setAttribute('aria-pressed', S.figure.name === f.name);
            b.addEventListener('click', () => { S.figure.name = f.name; S.figure.size = f.size; render(); });
            hoverable(b, 'figure', h.name, f.name);
            list.appendChild(b);
        }
        const fbox = section(body, T('ui_tab_figures'), T('ui_figures_help'));
        fbox.appendChild(list);
        paletteSwatches(labeled(body, T('ui_palette')), h, S.figure, render);
        segment(labeled(body, T('ui_style')), S.data.styles.map(s => s.name), S.figure.style, v => { S.figure.style = v; render(); }, v => (S.data.styles.find(s => s.name === v) || {}).label || v);
        segment(labeled(body, T('ui_pattern')), S.data.patterns, S.figure.pattern, v => { S.figure.pattern = v; render(); }, v => T('pattern_' + v));
        const row = el('div', 'row');
        segment(labeled(row, T('ui_channel')), [1, 2, 3, 4], S.figure.channel, v => { S.figure.channel = v; render(); });
        const szBox = labeled(row, `${T('ui_size')}: ${S.figure.size.toFixed(1)}`); szBox.classList.add('grow');
        const range = el('input'); range.type = 'range'; range.id = 'figsize'; range.min = 0.3; range.max = 8; range.step = 0.1; range.value = S.figure.size;
        range.addEventListener('input', () => { S.figure.size = parseFloat(range.value); szBox.firstChild.textContent = `${T('ui_size')}: ${S.figure.size.toFixed(1)}`; });
        szBox.appendChild(range);
        body.appendChild(row);
        const go = el('button', 'btn primary', T('ui_hang'));
        go.disabled = !S.data.who.decorator || !S.figure.name;
        go.title = T('ui_tray_hint_figure');
        go.addEventListener('click', () => post('placeFigure', { holiday: h.name, figure: S.figure.name, palette: S.figure.palette, pattern: S.figure.pattern, style: S.figure.style, channel: S.figure.channel, size: S.figure.size }));
        body.appendChild(go);
    }

    // ---- Groups ----
    // The group picker: every group that exists, as a chip with its
    // counts and how far away it is, the current one pressed, plus a box
    // for a new name. Used on Shows, Edit and Settings so a decorator
    // never has to remember what the groups are called.
    function setGroup(name) {
        const d = S.data;
        name = (name || '').trim().replace(/\s+/g, ' ');
        if (!name) return;
        d.settings.group = name;
        post('setGroup', { group: name });
        render();
    }
    function groupPicker(container, opts) {
        opts = opts || {};
        const d = S.data;
        const box = labeled(container, T('ui_group'));
        const chips = el('div', 'chips');
        const groups = d.groups || [];
        if (!groups.some(g => g.name === d.settings.group)) groups.unshift({ name: d.settings.group, count: 0, props: 0, lights: 0, dist: null, running: false, mine: true });
        for (const g of groups) {
            const b = el('button', 'chip');
            if (g.running) b.appendChild(el('span', 'dot on'));
            b.appendChild(document.createTextNode(g.name));
            if (g.count) b.appendChild(el('span', 'cnt', ` ${g.count}${g.dist !== null && g.dist !== undefined ? ` · ${g.dist} m` : ''}`));
            b.setAttribute('aria-pressed', d.settings.group === g.name);
            b.title = `${g.props || 0} ${T('ui_props')}, ${g.lights || 0} ${T('ui_lights')}`;
            b.addEventListener('click', () => setGroup(g.name));
            chips.appendChild(b);
        }
        box.appendChild(chips);
        const row = el('div', 'row');
        const gIn = el('input', 'input grow'); gIn.type = 'text'; gIn.placeholder = T('ui_group_new'); gIn.maxLength = 32;
        const use = el('button', 'btn small', T('ui_group_use'));
        use.addEventListener('click', () => setGroup(gIn.value));
        gIn.addEventListener('keydown', ev => { if (ev.key === 'Enter') setGroup(gIn.value); });
        row.appendChild(gIn); row.appendChild(use);
        box.appendChild(row);
        if (!opts.compact) box.appendChild(el('div', 'note', T('ui_group_help')));
        return box;
    }

    // ---- Spotlights and projectors ----
    // Pick a fixture, beam or projector, colors, pattern; Place, then aim
    // at the tree or wall in the world. Projections animate here from the
    // same pictures and motions the game draws (client/spotlights.lua).
    const ART = { img: null, tints: {}, timers: [] };
    function artImage() {
        if (!ART.img) { ART.img = new Image(); ART.img.src = 'projections.png'; }
        return ART.img;
    }
    function stopArtPreviews() { for (const id of ART.timers) cancelAnimationFrame(id); ART.timers = []; }
    function tinted(c) {
        const key = c.join(',');
        if (ART.tints[key]) return ART.tints[key];
        const img = artImage();
        if (!img.complete || !img.naturalWidth) return null;
        const cv = document.createElement('canvas'); cv.width = img.naturalWidth; cv.height = img.naturalHeight;
        const g = cv.getContext('2d');
        g.drawImage(img, 0, 0);
        g.globalCompositeOperation = 'source-in';
        g.fillStyle = `rgb(${c[0]},${c[1]},${c[2]})`;
        g.fillRect(0, 0, cv.width, cv.height);
        ART.tints[key] = cv;
        return cv;
    }
    function hh(seed, i, k) {
        let n = Math.imul((seed + i * 31 + k * 7919) | 0, 374761393) ^ Math.imul(k * 131 + i, 668265263);
        n = Math.imul(n ^ (n >>> 13), 1274126177);
        return ((n ^ (n >>> 16)) >>> 0) % 10007 / 10007;
    }
    const TAU = Math.PI * 2;
    const slotX = (i, n) => n <= 1 ? 0 : -0.72 + 1.44 * (i - 1) / (n - 1);
    const MOTIONS = {
        fall(i, t, s) { const ph = hh(s, i, 3), v = 0.7 + 0.6 * hh(s, i, 6), dir = hh(s, i, 5) < 0.5 ? -1 : 1;
            return [hh(s, i, 1) * 1.9 - 0.95 + 0.07 * Math.sin(t * 0.8 * v + ph * TAU), 1.2 - ((t * 0.11 * v + ph * 2.4) % 2.4), dir * t * 0.5 * v + ph * TAU, 1, 1, 1, false, 1]; },
        rise(i, t, s) { const ph = hh(s, i, 3), v = 0.7 + 0.6 * hh(s, i, 6);
            return [hh(s, i, 1) * 1.8 - 0.9 + 0.08 * Math.sin(t * 0.9 * v + ph * TAU), -1.2 + ((t * 0.1 * v + ph * 2.4) % 2.4), 0.25 * Math.sin(t * 0.9 + ph * TAU), 1, 1, 1, false, 1]; },
        drift(i, t, s) { const ph = hh(s, i, 3), v = 0.7 + 0.6 * hh(s, i, 6), dir = i % 2 === 0 ? -1 : 1;
            let x = -1.25 + ((t * 0.07 * v + ph * 2.5) % 2.5); if (dir < 0) x = -x;
            return [x, hh(s, i, 2) * 1.4 - 0.7 + 0.06 * Math.sin(t * 1.1 * v + ph * TAU), 0.15 * Math.sin(t * 0.8 + ph * TAU), 1, 1, 1, dir < 0, 1]; },
        twinkle(i, t, s, n) { const ph = hh(s, i, 3); let rr = Math.sqrt(hh(s, i, 1)) * 0.9, a = hh(s, i, 2) * TAU; if (n === 1) { rr = 0.45; a = 0.8; }
            const tw = 0.5 + 0.5 * Math.sin(t * (1.5 + 2 * hh(s, i, 4)) + ph * TAU), dir = hh(s, i, 5) < 0.5 ? -1 : 1;
            return [rr * Math.cos(a), rr * Math.sin(a), dir * t * 0.2, 0.3 + 0.7 * tw, 0.85 + 0.15 * tw, 1, false, 1]; },
        bob(i, t, s, n) { const ph = hh(s, i, 3);
            return [slotX(i, n), -0.3 + 0.1 * (hh(s, i, 2) - 0.5) + 0.05 * Math.sin(t * 1.7 + ph * TAU), 0.12 * Math.sin(t * 1.3 + ph * TAU), 1, 1, (Math.floor(t * 1.2 + ph * 3) % 2) + 1, false, 1]; },
        dance(i, t, s, n) { const beat = t * 2 + (i % 2) * 0.5;
            return [slotX(i, n) + 0.06 * Math.sin(beat * Math.PI * 0.5), -0.3 + 0.1 * Math.abs(Math.sin(beat * Math.PI)), 0.22 * Math.sin(beat * Math.PI), 1, 1, (Math.floor(beat) % 2) + 1, Math.floor(beat / 4) % 2 === 1, 1]; },
        hop(i, t, s) { const ph = hh(s, i, 3), v = 0.8 + 0.4 * hh(s, i, 6), dir = i % 2 === 0 ? -1 : 1;
            let x = -1.3 + ((t * 0.12 * v + ph * 2.6) % 2.6); if (dir < 0) x = -x; const up = Math.abs(Math.sin(t * 2.6 * v + ph * TAU));
            return [x, -0.45 + 0.22 * up + 0.3 * (hh(s, i, 2) - 0.5), 0, 1, 1, up > 0.3 ? 2 : 1, dir < 0, 1]; },
        fly(i, t, s) { const ph = hh(s, i, 3), v = 0.8 + 0.5 * hh(s, i, 6), dir = i % 2 === 0 ? -1 : 1;
            let x = -1.3 + ((t * 0.16 * v + ph * 2.6) % 2.6); if (dir < 0) x = -x;
            return [x, hh(s, i, 2) * 1.3 - 0.5 + 0.12 * Math.sin(t * 1.3 * v + ph * TAU), 0.1 * Math.sin(t * 2 + ph * TAU), 1, 1, (Math.floor(t * 7 + ph * 7) % 2) + 1, false, 1]; },
        burst(i, t, s) { const ph = hh(s, i, 3), v = 0.8 + 0.4 * hh(s, i, 6), P = 2.6 / v, tt = t + ph * P, cyc = Math.floor(tt / P), u = (tt % P) / P;
            const rr = Math.sqrt(hh(s + cyc * 17, i, 1)) * 0.75, a = hh(s + cyc * 17, i, 2) * TAU, grow = 1 - Math.pow(1 - u, 3);
            return [rr * Math.cos(a), rr * Math.sin(a), ph * TAU, u < 0.12 ? u / 0.12 : Math.pow(1 - (u - 0.12) / 0.88, 1.3), 0.25 + 0.75 * grow, 1, false, 1]; },
        spin(i, t, s, n) { const ph = hh(s, i, 3), v = 0.8 + 0.4 * hh(s, i, 6), c = Math.cos(t * 3 * v + ph * TAU);
            return [slotX(i, n), -0.2 + 0.4 * (hh(s, i, 2) - 0.5) + 0.04 * Math.sin(t * 1.5 + ph * TAU), 0.15 * Math.sin(t * 1.5 + ph * TAU), 1, 1, 1, c < 0, 0.35 + 0.65 * Math.abs(c)]; },
    };
    // Draws a projection on a canvas, looping, until the tab redraws.
    function artPreview(cv, art, colors, st) {
        const g = cv.getContext('2d');
        const W = cv.width, H = cv.height, R = Math.min(W, H) * 0.46;
        const cols = S.data.spotlights.cols, cell = 128;
        const start = performance.now();
        const step = () => {
            const t = (performance.now() - start) / 1000 * (st.speed || 1);
            g.fillStyle = '#15161d'; g.fillRect(0, 0, W, H);
            const glow = g.createRadialGradient(W / 2, H / 2, 0, W / 2, H / 2, R * 1.1);
            const c0 = colors[0];
            glow.addColorStop(0, `rgba(${c0[0]},${c0[1]},${c0[2]},0.16)`); glow.addColorStop(1, 'rgba(0,0,0,0)');
            g.fillStyle = glow; g.fillRect(0, 0, W, H);
            art.layers.forEach((L, li) => {
                const fn = MOTIONS[L.motion] || MOTIONS.twinkle;
                const sd = 4242 + (li + 1) * 101;
                for (let i = 1; i <= L.count; i++) {
                    const [x, y, rot, alpha, sc, frame, mirror, sx] = fn(i, t, sd, L.count);
                    const rr = Math.hypot(x, y), fade = Math.max(0, Math.min(1, (1.08 - rr) / 0.3));
                    const a = alpha * fade; if (a < 0.02) continue;
                    const motif = L.motifs[Math.floor(hh(sd, i, 7) * L.motifs.length)];
                    const cellIdx = motif[(frame - 1) % motif.length];
                    const size = (L.size[0] + (L.size[1] - L.size[0]) * hh(sd, i, 4)) * R * sc;
                    const col = colors[(i + li) % colors.length];
                    const src = tinted(col); if (!src) continue;
                    g.save();
                    g.globalAlpha = a; g.globalCompositeOperation = 'lighter';
                    g.translate(W / 2 + x * R, H / 2 - y * R); g.rotate(-rot); g.scale((mirror ? -1 : 1) * sx, 1);
                    g.drawImage(src, (cellIdx % cols) * cell, Math.floor(cellIdx / cols) * cell, cell, cell, -size / 2, -size / 2, size, size);
                    g.restore();
                }
            });
            ART.timers.push(requestAnimationFrame(step));
        };
        const img = artImage();
        if (img.complete && img.naturalWidth) step(); else img.addEventListener('load', step, { once: true });
    }
    function spotColors(h, st) {
        if (st.rgb) return [st.rgb];
        const p = h.palettes.find(x => x.name === st.palette) || h.palettes.slice().sort((a, b) => b.colors.length - a.colors.length)[0];
        return p ? p.colors : [[255, 236, 200]];
    }
    function hexOf(c) { return '#' + c.map(v => Math.round(v).toString(16).padStart(2, '0')).join(''); }
    // The settings of one spotlight: used to place one and to edit one.
    function spotSettings(container, h, st, onChange) {
        const SP = S.data.spotlights;
        const mode = labeled(container, T('ui_spot_mode'));
        help(mode.firstChild, T('ui_spot_mode_help'));
        segment(mode, ['beam', 'projector'], st.mode, v => { st.mode = v; onChange(); }, v => T('ui_spot_mode_' + v));
        if (st.mode === 'projector') {
            const arts = SP.arts.filter(a => a.holidays.includes('*') || a.holidays.includes(h.name))
                .sort((a, b) => (a.holidays.includes('*') ? 1 : 0) - (b.holidays.includes('*') ? 1 : 0));
            if (!arts.some(a => a.name === st.art)) st.art = arts[0] && arts[0].name;
            const ab = labeled(container, T('ui_spot_art'));
            help(ab.firstChild, T('ui_spot_art_help'));
            const grid = el('div', 'art-grid');
            for (const a of arts) {
                const card = el('button', 'art-card');
                card.setAttribute('aria-pressed', a.name === st.art);
                card.title = a.desc;
                const cv = el('canvas'); cv.width = 168; cv.height = 112;
                card.appendChild(cv);
                card.appendChild(el('span', '', a.label));
                card.addEventListener('click', () => { st.art = a.name; onChange(); });
                grid.appendChild(card);
                artPreview(cv, a, spotColors(h, st), st);
            }
            ab.appendChild(grid);
        }
        // Color: a palette of the holiday, or one color of your own.
        const cb = labeled(container, T('ui_spot_color'));
        const sw = el('div', 'swatches');
        // No palette yet: the holiday's richest one (most colors), as the game does.
        if (!st.rgb && (!st.palette || !h.palettes.some(p => p.name === st.palette))) {
            const vivid = p => p.colors.reduce((s, c) => s + Math.max(...c) - Math.min(...c), 0);
            const rich = h.palettes.slice().sort((a, b) => (b.colors.length - a.colors.length) || (vivid(b) - vivid(a)) || a.name.localeCompare(b.name))[0];
            st.palette = rich && rich.name;
        }
        for (const p of h.palettes) {
            const b = el('button', 'sw');
            for (const c of p.colors) { const i = el('i'); i.style.background = rgb(c); i.style.color = rgb(c); b.appendChild(i); }
            b.appendChild(document.createTextNode(p.name.replace(/_/g, ' ')));
            b.setAttribute('aria-pressed', !st.rgb && st.palette === p.name);
            b.addEventListener('click', () => { st.palette = p.name; st.rgb = null; onChange(); });
            sw.appendChild(b);
        }
        const custom = el('label', 'sw custom');
        const pick = el('input'); pick.type = 'color'; pick.value = st.rgb ? hexOf(st.rgb) : '#ffd9a0';
        pick.addEventListener('change', () => { const v = pick.value; st.rgb = [parseInt(v.slice(1, 3), 16), parseInt(v.slice(3, 5), 16), parseInt(v.slice(5, 7), 16)]; onChange(); });
        custom.appendChild(pick); custom.appendChild(document.createTextNode(T('ui_spot_custom')));
        custom.setAttribute('aria-pressed', !!st.rgb);
        sw.appendChild(custom);
        cb.appendChild(sw);
        const cyc = el('div', 'row');
        cyc.appendChild(el('span', '', T('ui_spot_cycle')));
        const cs = el('button', 'switch'); cs.setAttribute('role', 'switch'); cs.setAttribute('aria-checked', !!st.cycle);
        cs.addEventListener('click', () => { st.cycle = !st.cycle; onChange(); });
        cyc.appendChild(cs); help(cyc, T('ui_spot_cycle_help'));
        container.appendChild(cyc);
        // Beam, brightness, size and speed.
        segment(labeled(container, T('ui_spot_beam')), SP.beams, st.beam, v => { st.beam = v; onChange(); }, v => T('spot_beam_' + v));
        if (st.mode !== 'projector') {
            // A tree: lit from the side so the whole tree shows. Aiming at a
            // tree you placed turns this on by itself.
            const tr = el('div', 'row');
            tr.appendChild(el('span', '', T('ui_spot_tree')));
            const ts = el('button', 'switch'); ts.setAttribute('role', 'switch'); ts.setAttribute('aria-checked', !!st.tree);
            ts.addEventListener('click', () => { st.tree = !st.tree; if (st.tree && !st.span) st.span = SP.treeSpans.medium; onChange(); });
            tr.appendChild(ts); help(tr, T('ui_spot_tree_help'));
            container.appendChild(tr);
            if (st.tree) {
                const names = SP.treeSpanOrder;
                const cur = names.reduce((a, n) => Math.abs(SP.treeSpans[n] - (st.span || 0)) < Math.abs(SP.treeSpans[a] - (st.span || 0)) ? n : a, names[1]);
                segment(labeled(container, T('ui_spot_tree_size')), names, cur, v => { st.span = SP.treeSpans[v]; onChange(); }, v => T('spot_tree_' + v));
            }
        }
        const slider = (label, key, min, max, step, fmt) => {
            const box = labeled(container, `${label}: ${fmt(st[key])}`);
            const r = el('input'); r.type = 'range'; r.min = min; r.max = max; r.step = step; r.value = st[key];
            r.addEventListener('input', () => { st[key] = parseFloat(r.value); box.firstChild.textContent = `${label}: ${fmt(st[key])}`; });
            box.appendChild(r);
        };
        const pct = v => `${Math.round(v * 100)}%`;
        slider(T('ui_spot_bright'), 'bright', 0.2, 3, 0.05, pct);
        if (st.mode === 'projector') {
            slider(T('ui_spot_scale'), 'scale', 0.5, 2, 0.05, pct);
            slider(T('ui_spot_speed'), 'speed', 0.25, 3, 0.05, pct);
        }
        // Pattern and channel: a show overrides the pattern on its channel.
        segment(labeled(container, T('ui_pattern')), SP.patterns, st.pattern, v => { st.pattern = v; onChange(); }, v => T('pattern_' + v));
        container.lastChild.lastChild.classList.add('wrap');
        segment(labeled(container, T('ui_channel')), [1, 2, 3, 4], st.channel, v => { st.channel = v; onChange(); });
        const hr = el('div', 'row');
        hr.appendChild(el('span', '', T('ui_spot_hidden')));
        const hs = el('button', 'switch'); hs.setAttribute('role', 'switch'); hs.setAttribute('aria-checked', !!st.hidden);
        hs.addEventListener('click', () => { st.hidden = !st.hidden; onChange(); });
        hr.appendChild(hs); help(hr, T('ui_spot_hidden_help'));
        container.appendChild(hr);
    }
    // What is sent: forEdit sends false to clear a color, palette or flag.
    function spotOut(st, forEdit) {
        const o = { mode: st.mode, beam: st.beam, bright: st.bright, pattern: st.pattern, channel: st.channel, art: st.art, scale: st.scale, speed: st.speed };
        o.cycle = st.cycle ? true : (forEdit ? false : undefined);
        o.tree = st.tree ? true : (forEdit ? false : undefined);
        if (st.tree && st.span) o.span = st.span;
        o.hidden = st.hidden ? true : (forEdit ? false : undefined);
        if (st.rgb) { o.rgb = st.rgb; if (forEdit) o.palette = false; }
        else { o.palette = st.palette; if (forEdit) o.rgb = false; }
        return o;
    }
    function renderSpotlights(body) {
        const d = S.data, SP = d.spotlights;
        holidayChips(body, render);
        const h = holiday();
        if (!SP || !SP.enabled) { body.appendChild(el('div', 'note', T('ui_spot_disabled'))); return; }
        if (!SP.fixtures.length) { body.appendChild(el('div', 'note', T('ui_spot_none'))); return; }
        if (!SP.fixtures.some(f => f.name === S.spot.fixture)) S.spot.fixture = SP.fixtures[0].name;
        const box = section(body, T('ui_spot_fixtures'), T('ui_spot_help') + ' ' + T('ui_hover_hint'));
        const list = el('div', 'list');
        for (const f of SP.fixtures) {
            const it = el('div', 'item' + (f.name === S.spot.fixture ? ' active' : ''));
            it.appendChild(propThumb(f.model));
            const main = el('div', 'main');
            main.appendChild(el('div', 't', f.label));
            main.appendChild(el('div', 'd', f.desc));
            it.appendChild(main);
            it.addEventListener('click', () => { S.spot.fixture = f.name; render(); });
            hoverable(it, 'prop', h.name, f.model);
            list.appendChild(it);
        }
        box.appendChild(list);
        spotSettings(body, h, S.spot, () => render());
        const row = el('div', 'row');
        const go = el('button', 'btn primary', T('ui_spot_place'));
        go.disabled = !d.who.decorator;
        go.addEventListener('click', () => post('placeSpot', { holiday: h.name, fixture: S.spot.fixture, spot: spotOut(S.spot, false) }));
        row.appendChild(go);
        body.appendChild(row);
        body.appendChild(el('div', 'note', T('ui_spot_place_hint').replace('%{max}', Math.round(SP.maxThrow))));
    }

    // ---- Sleigh & ball drop ----
    function switchRow(container, label, value, onFlip, helpText) {
        const r = el('div', 'row');
        r.appendChild(el('span', '', label));
        const sw = el('button', 'switch'); sw.setAttribute('role', 'switch'); sw.setAttribute('aria-checked', !!value);
        sw.addEventListener('click', () => onFlip(!value));
        r.appendChild(sw);
        if (helpText) help(r, helpText);
        container.appendChild(r);
    }
    function rangeRow(container, label, st, key, min, max, step, fmt) {
        const box = labeled(container, `${label}: ${fmt(st[key])}`);
        const r = el('input'); r.type = 'range'; r.min = min; r.max = max; r.step = step; r.value = st[key];
        r.addEventListener('input', () => { st[key] = parseFloat(r.value); box.firstChild.textContent = `${label}: ${fmt(st[key])}`; });
        box.appendChild(r);
    }
    // A team: how many pairs, their coats, what they do while parked, the
    // red nose, rides, presents.
    function sleighSettings(container, st, onChange) {
        const X = S.data.extras.sleigh;
        const nums = []; for (let i = 1; i <= X.maxPairs; i++) nums.push(i);
        segment(labeled(container, T('ui_sl_pairs')), nums, st.pairs, v => { st.pairs = v; onChange(); }, v => `${v * 2}`);
        segment(labeled(container, T('ui_sl_coat')), X.coats, st.coat, v => { st.coat = v; onChange(); }, v => T('sl_coat_' + v));
        segment(labeled(container, T('ui_sl_pose')), X.poses, st.pose, v => { st.pose = v; onChange(); }, v => T('sl_pose_' + v));
        switchRow(container, T('ui_sl_nose'), st.nose, v => { st.nose = v; onChange(); });
        switchRow(container, T('ui_sl_presents'), st.presents, v => { st.presents = v; onChange(); });
        switchRow(container, T('ui_sl_ride'), st.ride, v => { st.ride = v; onChange(); }, X.ride ? T('ui_sl_ride_help') : T('ui_sl_ride_off_server'));
    }
    // A ball: its size, how long it takes to drop, its colors and pattern;
    // with the pole's height when it is being placed.
    function ballSettings(container, st, onChange, withHeight) {
        const X = S.data.extras.balldrop;
        if (withHeight) rangeRow(container, T('ui_bd_height'), st, 'height', X.minHeight, X.maxHeight, 1, v => `${v} m`);
        rangeRow(container, T('ui_bd_ball'), st, 'ball', 0.8, 6, 0.1, v => `${Number(v).toFixed(1)} m`);
        rangeRow(container, T('ui_bd_seconds'), st, 'seconds', 10, 120, 5, v => `${v} s`);
        segment(labeled(container, T('ui_bd_pattern')), X.patterns, st.pattern, v => { st.pattern = v; onChange(); }, v => T('bd_pattern_' + v));
        const h = S.data.holidays.find(x => x.name === X.holiday);
        if (h && st.pattern !== 'rainbow') {
            const cb = labeled(container, T('ui_bd_colors'));
            const sw = el('div', 'swatches');
            const auto = el('button', 'sw', T('ui_bd_colors_auto'));
            auto.setAttribute('aria-pressed', !st.palette);
            auto.addEventListener('click', () => { st.palette = null; onChange(); });
            sw.appendChild(auto);
            for (const p of h.palettes) {
                const b = el('button', 'sw');
                for (const c of p.colors) { const i = el('i'); i.style.background = rgb(c); i.style.color = rgb(c); b.appendChild(i); }
                b.appendChild(document.createTextNode(p.name.replace(/_/g, ' ')));
                b.setAttribute('aria-pressed', st.palette === p.name);
                b.addEventListener('click', () => { st.palette = p.name; onChange(); });
                sw.appendChild(b);
            }
            cb.appendChild(sw);
        }
    }
    function ballOut(st, forEdit) {
        const o = { ball: st.ball, seconds: st.seconds, pattern: st.pattern };
        if (st.palette) o.palette = st.palette; else if (forEdit) o.palette = false;
        return o;
    }
    function renderExtras(body) {
        const d = S.data, X = d.extras;
        // The ball drop.
        const bbox = section(body, T('ui_bd_title'), T('ui_bd_help'));
        if (!X.balldrop.enabled) bbox.appendChild(el('div', 'note', T('ui_bd_disabled')));
        else {
            ballSettings(bbox, S.ball, () => render(), true);
            const row = el('div', 'row');
            const go = el('button', 'btn primary', T('ui_bd_place'));
            go.disabled = !d.who.decorator;
            go.title = T('ui_tray_hint_shape');
            go.addEventListener('click', () => post('placeBallDrop', { height: S.ball.height, drop: ballOut(S.ball, false) }));
            row.appendChild(go);
            bbox.appendChild(row);
            bbox.appendChild(el('div', 'note', T('ui_bd_how').replace('%{seconds}', S.ball.seconds)));
            if (X.balldrop.here) bbox.appendChild(el('div', 'note', T('ui_bd_here').replace('%{count}', X.balldrop.here).replace('%{group}', d.settings.group)));
        }
        // Santa's sleigh.
        const sbox = section(body, T('ui_sl_title'), T('ui_sl_help'));
        if (!X.sleigh.enabled) { sbox.appendChild(el('div', 'note', T('ui_sl_disabled'))); return; }
        if (!X.sleigh.available) { sbox.appendChild(el('div', 'note', T('ui_sl_unavailable'))); return; }
        sleighSettings(sbox, S.sleigh, () => render());
        const row = el('div', 'row');
        const go = el('button', 'btn primary', T('ui_sl_place'));
        go.disabled = !d.who.decorator;
        go.title = T('ui_tray_hint_prop');
        go.addEventListener('click', () => post('placeSleigh', { sleigh: Object.assign({}, S.sleigh) }));
        row.appendChild(go);
        sbox.appendChild(row);
        // Santa's flight from this location.
        const here = X.sleigh.here || { count: 0 };
        const fbox = section(body, T('ui_sl_fly'), T('ui_sl_fly_help'));
        if (!X.sleigh.flight) fbox.appendChild(el('div', 'note', T('ui_sl_flight_off')));
        else {
            fbox.appendChild(el('div', 'note', here.count ? T('ui_sl_here').replace('%{count}', here.count).replace('%{group}', d.settings.group)
                : T('ui_sl_none_here').replace('%{group}', d.settings.group)));
            const fr = el('div', 'row');
            const fly = el('button', 'btn primary', T('ui_sl_fly'));
            fly.disabled = !here.count;
            fly.addEventListener('click', () => { post('sleighFly'); });
            const land = el('button', 'btn', T('ui_sl_land'));
            land.disabled = !here.flying;
            land.addEventListener('click', () => { post('sleighLand'); });
            fr.appendChild(fly); fr.appendChild(land);
            fbox.appendChild(fr);
            if (here.flying) fbox.appendChild(el('div', 'note', T('ui_sl_flying')));
        }
    }

    // ---- Fireworks ----
    // Pick a launcher, load it, color it, give it a channel and a height,
    // and place it like a prop. Preview fires one in front of you.
    function fwPalettes(container, h, state, onChange) {
        const list = h.fwPalettes || h.palettes;
        if (state.palette && !list.some(p => p.name === state.palette)) state.palette = null;
        const wrap = el('div', 'swatches');
        for (const p of list) {
            const b = el('button', 'sw');
            for (const c of p.colors) { const i = el('i'); i.style.background = rgb(c); i.style.color = rgb(c); b.appendChild(i); }
            b.appendChild(document.createTextNode(p.name.replace(/_/g, ' ')));
            b.setAttribute('aria-pressed', (state.palette || list[0].name) === p.name);
            b.addEventListener('click', () => { state.palette = p.name; onChange(); });
            wrap.appendChild(b);
        }
        container.appendChild(wrap);
    }
    function launcherSettings(container, h, rack, st, onChange) {
        if (!rack.loads.includes(st.load)) st.load = rack.loads[0];
        const lb = labeled(container, T('ui_fw_load'));
        help(lb.firstChild, T('ui_fw_load_help'));
        segment(lb, rack.loads, st.load, v => { st.load = v; onChange(); }, v => T('fw_load_' + v));
        lb.lastChild.classList.add('wrap');
        fwPalettes(labeled(container, T('ui_palette')), h, st, onChange);
        const row = el('div', 'row');
        segment(labeled(row, T('ui_channel')), [1, 2, 3, 4], st.channel, v => { st.channel = v; onChange(); });
        const lifts = S.data.fireworks.lifts;
        const cur = (lifts.reduce((a, l) => Math.abs(l[1] - st.lift) < Math.abs(a[1] - st.lift) ? l : a, lifts[1]))[0];
        segment(labeled(row, T('ui_fw_lift')), lifts.map(l => l[0]), cur, v => { st.lift = lifts.find(l => l[0] === v)[1]; onChange(); }, v => T('fw_lift_' + v));
        container.appendChild(row);
        const tBox = labeled(container, `${T('ui_fw_tilt')}: ${st.tilt}°`);
        const range = el('input'); range.type = 'range'; range.min = -35; range.max = 35; range.step = 5; range.value = st.tilt;
        range.addEventListener('input', () => { st.tilt = parseInt(range.value, 10); tBox.firstChild.textContent = `${T('ui_fw_tilt')}: ${st.tilt}°`; });
        range.addEventListener('change', () => onChange(true));
        tBox.appendChild(range);
        const hr = el('div', 'row');
        hr.appendChild(el('span', '', T('ui_fw_hidden')));
        const hs = el('button', 'switch'); hs.setAttribute('role', 'switch'); hs.setAttribute('aria-checked', !!st.hidden);
        hs.addEventListener('click', () => { st.hidden = !st.hidden; onChange(); });
        hr.appendChild(hs);
        help(hr, T('ui_fw_hidden_help'));
        container.appendChild(hr);
    }
    function renderFireworks(body) {
        const d = S.data;
        holidayChips(body, render);
        const h = holiday();
        if (!d.fireworks.enabled) body.appendChild(el('div', 'note', T('ui_fw_disabled')));
        const racks = h.launchers || [];
        if (!racks.length) { body.appendChild(el('div', 'note', '-')); return; }
        if (!racks.some(r => r.name === S.fw.rack)) S.fw.rack = racks[0].name;
        const box = section(body, T('ui_fw_racks'), T('ui_fw_help') + ' ' + T('ui_hover_hint'));
        const list = el('div', 'list');
        for (const r of racks) {
            const it = el('div', 'item' + (r.name === S.fw.rack ? ' active' : ''));
            it.appendChild(propThumb(r.model));
            const main = el('div', 'main');
            main.appendChild(el('div', 't', r.label));
            main.appendChild(el('div', 'd', r.desc));
            it.appendChild(main);
            it.addEventListener('click', () => { S.fw.rack = r.name; render(); });
            hoverable(it, 'prop', h.name, r.model);
            list.appendChild(it);
        }
        box.appendChild(list);
        const rack = racks.find(r => r.name === S.fw.rack);
        launcherSettings(body, h, rack, S.fw, () => render());
        const fwOf = () => ({ load: S.fw.load, palette: S.fw.palette || (h.fwPalettes || h.palettes)[0].name, channel: S.fw.channel, lift: S.fw.lift, tilt: S.fw.tilt, hidden: S.fw.hidden });
        const row = el('div', 'row');
        const go = el('button', 'btn primary', T('ui_place'));
        go.disabled = !d.who.decorator;
        go.title = T('ui_tray_hint_prop');
        go.addEventListener('click', () => post('placeLauncher', { holiday: h.name, rack: rack.name, fw: fwOf() }));
        const pv = el('button', 'btn', T('ui_fw_preview'));
        pv.addEventListener('click', () => post('previewLoad', { holiday: h.name, rack: rack.name, fw: fwOf() }));
        row.appendChild(go); row.appendChild(pv);
        body.appendChild(row);
        const here = d.fireworks.here || 0;
        body.appendChild(el('div', 'note', here ? T('ui_fw_here').replace('%{count}', here).replace('%{group}', d.settings.group)
            .replace('%{channels}', d.fireworks.counts.map((n, i) => `${i + 1}: ${n}`).join(' · ')) : T('ui_fw_none_here').replace('%{group}', d.settings.group)));
        if (d.fireworks.nightOnly) body.appendChild(el('div', 'note', T('ui_fw_night').replace('%{from}', d.fireworks.nightFrom).replace('%{to}', d.fireworks.nightTo)));
    }

    // The launch board: fire by hand, for everyone nearby.
    function launchBoard(container) {
        const d = S.data;
        const box = section(container, T('ui_fw_board'), T('ui_fw_board_help'));
        const grid = el('div', 'board');
        for (let c = 1; c <= 4; c++) {
            const col = el('div', 'board-col');
            col.appendChild(el('div', 'label', `${T('ui_channel')} ${c} · ${d.fireworks.counts[c - 1]}`));
            const sh = el('button', 'btn small', T('ui_fw_shell')); sh.addEventListener('click', () => post('fire', { action: 'shell', channel: c }));
            const sv = el('button', 'btn small', T('ui_fw_salvo')); sv.addEventListener('click', () => post('fire', { action: 'salvo', channel: c }));
            sh.disabled = sv.disabled = !d.fireworks.counts[c - 1];
            col.appendChild(sh); col.appendChild(sv);
            grid.appendChild(col);
        }
        box.appendChild(grid);
        const row = el('div', 'row');
        for (const a of ['salvo', 'sweep', 'cake', 'fountain', 'shape']) {
            const b = el('button', 'btn small', T('ui_fw_' + a)); b.addEventListener('click', () => post('fire', { action: a, channel: 0 })); row.appendChild(b);
        }
        const fin = el('button', 'btn small danger', T('ui_fw_finale'));
        fin.addEventListener('click', () => {
            if (fin.dataset.armed) { post('fire', { action: 'finale', channel: 0 }); delete fin.dataset.armed; fin.textContent = T('ui_fw_finale'); }
            else { fin.dataset.armed = '1'; fin.textContent = T('ui_fw_finale_arm'); setTimeout(() => { delete fin.dataset.armed; fin.textContent = T('ui_fw_finale'); }, 3000); }
        });
        row.appendChild(fin);
        box.appendChild(row);
        const lm = el('button', 'btn', T('ui_fw_launch_mode'));
        lm.addEventListener('click', () => post('launchMode'));
        box.appendChild(lm);
    }

    // ---- Shows ----
    function renderShows(body) {
        const d = S.data;
        groupPicker(body, { compact: true });
        if (d.nowPlaying) {
            const np = el('div', 'item active');
            const main = el('div', 'main'); main.appendChild(el('div', 't', `${d.nowPlaying.rehearsal ? T('ui_fw_rehearsal') : T('ui_now_playing')}: ${trackLabel(d.nowPlaying.track)}`));
            main.appendChild(el('div', 'd', d.nowPlaying.show + (d.nowPlaying.fw ? ` · ${T('ui_tab_fireworks')}: ${T('fw_mode_' + d.nowPlaying.fw)}` : '')));
            np.appendChild(main);
            const stop = el('button', 'btn small', T('ui_stop')); stop.addEventListener('click', () => post('stopShow'));
            np.appendChild(stop);
            body.appendChild(np);
        }
        holidayChips(body, render, true);
        const h = holiday();
        const shows = (S.holiday !== '*' && h.shows && h.shows.length) ? h.shows.concat(d.shows.map(s => s.name).filter(n => !h.shows.includes(n))) : d.shows.map(s => s.name);
        if (!shows.includes(S.show.show)) S.show.show = shows[0];
        segment(labeled(body, T('ui_choose_show')), shows, S.show.show, v => { S.show.show = v; render(); }, v => (d.shows.find(s => s.name === v) || {}).label || v);
        // Fireworks for the show: which program, how much.
        const F = d.fireworks;
        const showDef = d.shows.find(x => x.name === S.show.show) || {};
        const fwBox = section(body, `${T('ui_fw_mode')} · ${T('ui_fw_launchers').replace('%{count}', F.here || 0)}`, T('fw_mode_' + (S.show.fwMode === 'off' ? 'score' : S.show.fwMode) + '_help'));
        const modes = ['off'].concat(F.modes.filter(m => m !== 'show' || showDef.fw));
        if (!modes.includes(S.show.fwMode)) S.show.fwMode = 'score';
        segment(fwBox, modes, S.show.fwMode, v => { S.show.fwMode = v; render(); }, v => v === 'off' ? T('ui_fw_off') : T('fw_mode_' + v));
        fwBox.lastChild.classList.add('wrap');
        if (S.show.fwMode !== 'off') segment(labeled(fwBox, T('ui_fw_intensity')), F.intensities, S.show.fwIntensity, v => { S.show.fwIntensity = v; render(); }, v => T('fw_intensity_' + v));
        if (!F.enabled) fwBox.appendChild(el('div', 'note', T('ui_fw_disabled')));
        else if (!F.here) fwBox.appendChild(el('div', 'note', T('ui_fw_none_here').replace('%{group}', d.settings.group)));
        const fwSend = () => ({ mode: S.show.fwMode, intensity: S.show.fwIntensity });
        const list = el('div', 'list');
        const tracks = d.tracks.filter(t => S.holiday === '*' || t.holiday === S.holiday || !t.holiday).sort((a, b) => (b.inSeason - a.inSeason) || a.label.localeCompare(b.label));
        for (const t of tracks) {
            const it = el('div', 'item');
            const main = el('div', 'main');
            main.appendChild(el('div', 't', t.label));
            const hl = (d.holidays.find(x => x.name === t.holiday) || {}).label || '';
            main.appendChild(el('div', 'd', `${hl}${t.holiday ? ' · ' + (t.inSeason ? T('ui_in_season') : T('ui_off_season')) : ''} · ${t.bpm} bpm · ${t.duration}s`));
            it.appendChild(main);
            if (F.scored.includes(t.name) && S.show.fwMode !== 'off') main.lastChild.textContent += ` · ${T('ui_fw_count')}`;
            const rh = el('button', 'btn small', T('ui_fw_rehearse')); rh.title = T('ui_fw_rehearse_help');
            rh.addEventListener('click', () => post('rehearse', { track: t.name, show: S.show.show, fw: fwSend() }));
            const cd = el('button', 'btn small', T('ui_fw_countdown'));
            cd.addEventListener('click', () => { S.countdown.track = t.name; S.countdown.open = true; render(); });
            const b = el('button', 'btn small primary', T('ui_play'));
            b.addEventListener('click', () => post('startShow', { track: t.name, show: S.show.show, fw: fwSend() }));
            it.appendChild(rh); it.appendChild(cd); it.appendChild(b);
            list.appendChild(it);
            if (S.countdown.open && S.countdown.track === t.name) {
                // A countdown to this track: seconds, a time of day, or midnight.
                const cbx = el('div', 'item active wrap');
                const cm = el('div', 'main');
                cm.appendChild(el('div', 't', `${T('ui_fw_countdown')}: ${t.label}`));
                cm.appendChild(el('div', 'd', T('ui_fw_countdown_help')));
                cbx.appendChild(cm);
                const inp = el('input', 'input'); inp.type = 'text'; inp.value = S.countdown.target; inp.style.width = '110px';
                inp.addEventListener('input', () => { S.countdown.target = inp.value.trim(); });
                cbx.appendChild(inp);
                for (const q of ['10', '30', '60', 'midnight']) {
                    const qb = el('button', 'btn small', q === 'midnight' ? '00:00' : q + 's');
                    qb.addEventListener('click', () => { S.countdown.target = q; inp.value = q; });
                    cbx.appendChild(qb);
                }
                const go = el('button', 'btn small primary', T('ui_fw_countdown_start'));
                go.addEventListener('click', () => { post('countdown', { target: S.countdown.target, track: t.name, show: S.show.show, fw: fwSend() }); S.countdown.open = false; render(); });
                const x = el('button', 'btn small', '×'); x.addEventListener('click', () => { S.countdown.open = false; render(); });
                cbx.appendChild(go); cbx.appendChild(x);
                list.appendChild(cbx);
            }
        }
        labeled(body, T('ui_track')).appendChild(list);
        if (F.enabled && F.manual && F.here) launchBoard(body);
    }

    // ---- Edit ----
    function renderEdit(body) {
        const d = S.data;
        // Point and click first: aim at the thing itself.
        const pick = el('button', 'btn primary', T('ui_pick'));
        pick.disabled = !d.who.decorator && !d.who.admin && !(d.floats && d.floats.ownersMay);
        pick.addEventListener('click', () => post('pick'));
        body.appendChild(pick);
        body.appendChild(el('div', 'note', T('ui_pick_help')));
        const row = el('div', 'row');
        const undo = el('button', 'btn', T('ui_undo')); undo.addEventListener('click', () => post('undo'));
        const refresh = el('button', 'btn', T('ui_refresh')); refresh.addEventListener('click', () => post('refreshNearby'));
        row.appendChild(undo); row.appendChild(refresh);
        body.appendChild(row);
        const groups = el('div', 'list'); groups.id = 'groups';
        labeled(body, T('ui_groups')).appendChild(groups);
        renderGroups(groups, d.groups);
        const list = el('div', 'list');
        list.id = 'nearby';
        labeled(body, T('ui_nearby')).appendChild(list);
        renderNearby(list, d.nearby);
    }
    // Every group on the server: counts, distance, whether a show is on,
    // Use (make it mine) and, for admins, Clear with a second click to arm.
    function renderGroups(list, groups) {
        list.innerHTML = '';
        const d = S.data;
        if (!groups || !groups.length) { list.appendChild(el('div', 'note', T('ui_group_none'))); return; }
        for (const g of groups) {
            const it = el('div', 'item' + (g.name === d.settings.group ? ' active' : ''));
            const main = el('div', 'main');
            main.appendChild(el('div', 't', g.name));
            main.appendChild(el('div', 'd', `${g.props} ${T('ui_props')} · ${g.lights} ${T('ui_lights')}${g.launchers ? ` · ${g.launchers} ${T('ui_tab_fireworks').toLowerCase()}` : ''} · ${g.dist} m${g.running ? ` · ${T('ui_group_show_on')}` : ''}`));
            it.appendChild(main);
            const use = el('button', 'btn small', T('ui_group_use')); use.disabled = g.name === d.settings.group;
            use.addEventListener('click', () => setGroup(g.name));
            it.appendChild(use);
            if (d.who.admin) {
                const clr = el('button', 'btn small danger', T('ui_group_clear'));
                clr.addEventListener('click', () => {
                    if (clr.dataset.armed) { post('clearGroup', { group: g.name }); clr.disabled = true; }
                    else { clr.dataset.armed = '1'; clr.textContent = `${T('ui_group_clear')} ${g.count}?`; }
                });
                it.appendChild(clr);
            }
            list.appendChild(it);
        }
    }
    function renderNearby(list, nearby) {
        list.innerHTML = '';
        if (!nearby || !nearby.length) { list.appendChild(el('div', 'note', T('ui_none_nearby'))); return; }
        const can = S.data.who;
        const groups = (S.data.groups || []).map(g => g.name);
        for (const n of nearby) {
            const it = el('div', 'item');
            const main = el('div', 'main');
            main.appendChild(el('div', 't', `${n.label}  ·  ${n.dist} m`));
            main.appendChild(el('div', 'd', `${n.holidayLabel} · ${n.group} · ${T('ui_by')} ${n.by}${n.kind === 'lights' ? ` · ${n.palette} · ${T('pattern_' + n.pattern)} · ${T('ui_channel')} ${n.channel}` : ''}`));
            it.appendChild(main);
            const ownersMay = !!(S.data.floats && S.data.floats.ownersMay);
            const editable = can.admin || ((can.decorator || (n.float && ownersMay)) && n.mine);
            if (editable && groups.length > 1 && !n.float) {   // a float's decorations stay on their float
                // Move it to another group without leaving the list.
                const sel = el('select', 'input small'); sel.title = T('ui_change_group');
                for (const g of groups) { const o = el('option', '', g); o.value = g; o.selected = g === n.group; sel.appendChild(o); }
                sel.addEventListener('change', () => post('regroup', { id: n.id, group: sel.value }));
                it.appendChild(sel);
            }
            if (n.fw) {
                main.lastChild.textContent += ` · ${T('fw_load_' + n.fw.load)} · ${T('ui_channel')} ${n.fw.channel}${n.fw.hidden ? ' · ' + T('ui_fw_hidden') : ''}`;
                const test = el('button', 'btn small', T('ui_fw_test')); test.addEventListener('click', () => post('testLauncher', { id: n.id }));
                it.appendChild(test);
                if (editable) {
                    const set = el('button', 'btn small', T('ui_fw_save') + '…');
                    set.addEventListener('click', () => { S.editing = S.editing === n.id ? null : n.id; renderNearby(list, nearby); });
                    it.appendChild(set);
                }
            }
            if (n.spot && editable) {
                const aim = el('button', 'btn small', T('ui_spot_aim')); aim.addEventListener('click', () => post('aimSpot', { id: n.id }));
                it.appendChild(aim);
                const set = el('button', 'btn small', T('ui_spot_settings') + '…');
                set.addEventListener('click', () => { S.editing = S.editing === n.id ? null : n.id; renderNearby(list, nearby); });
                it.appendChild(set);
                if (!n.spot.target) main.lastChild.textContent += ` · ${T('ui_spot_unaimed')}`;
            }
            if (n.isSleigh && editable) {
                // A sleigh's team: give it one, change it, or take it away.
                const set = el('button', 'btn small', (n.sleigh ? T('ui_sl_team') : T('ui_sl_add_team')) + '…');
                set.addEventListener('click', () => { S.editing = S.editing === n.id ? null : n.id; renderNearby(list, nearby); });
                it.appendChild(set);
                if (n.sleigh) main.lastChild.textContent += ` · ${n.sleigh.pairs * 2} ${T('ui_sl_team').toLowerCase()} · ${T('sl_coat_' + n.sleigh.coat)}`;
            }
            if (n.drop) {
                main.lastChild.textContent += ` · ${T('bd_pattern_' + n.drop.pattern)} · ${n.drop.seconds} s`;
                const test = el('button', 'btn small', T('ui_bd_test')); test.title = T('ui_bd_test_help');
                test.addEventListener('click', () => post('testBallDrop', { id: n.id }));
                it.appendChild(test);
                if (editable) {
                    const set = el('button', 'btn small', T('ui_bd_settings') + '…');
                    set.addEventListener('click', () => { S.editing = S.editing === n.id ? null : n.id; renderNearby(list, nearby); });
                    it.appendChild(set);
                }
            }
            const mv = el('button', 'btn small', T('ui_move')); mv.disabled = !editable; mv.addEventListener('click', () => post('move', { id: n.id }));
            const rm = el('button', 'btn small danger', T('ui_remove')); rm.disabled = !editable; rm.addEventListener('click', () => post('remove', { id: n.id }));
            if (!editable) { mv.title = rm.title = T('ui_not_yours_tip').replace('%{name}', n.by); }
            it.appendChild(mv); it.appendChild(rm);
            list.appendChild(it);
            if (n.spot && S.editing === n.id) {
                const h = S.data.holidays.find(x => x.name === n.holiday);
                if (h) {
                    const st = Object.assign({}, n.spot);
                    const ed = el('div', 'item editor wrap');
                    const inner = el('div', 'main');
                    const redraw = () => { inner.innerHTML = ''; stopArtPreviews(); spotSettings(inner, h, st, redraw); };
                    redraw();
                    ed.appendChild(inner);
                    const save = el('button', 'btn small primary', T('ui_save'));
                    save.addEventListener('click', () => {
                        post('restyle', { id: n.id, changes: { spot: spotOut(st, true) } });
                        S.editing = null;
                        setTimeout(() => post('refreshNearby'), 400);
                    });
                    ed.appendChild(save);
                    list.appendChild(ed);
                }
            }
            if (n.isSleigh && S.editing === n.id) {
                const st = Object.assign({}, S.sleigh, n.sleigh || {});
                const ed = el('div', 'item editor wrap');
                const inner = el('div', 'main');
                const redraw = () => { inner.innerHTML = ''; sleighSettings(inner, st, redraw); };
                redraw();
                ed.appendChild(inner);
                const save = el('button', 'btn small primary', T('ui_save'));
                save.addEventListener('click', () => {
                    post('restyle', { id: n.id, changes: { sleigh: { pairs: st.pairs, coat: st.coat, pose: st.pose, nose: !!st.nose, ride: !!st.ride, presents: !!st.presents } } });
                    S.editing = null;
                    setTimeout(() => post('refreshNearby'), 400);
                });
                ed.appendChild(save);
                if (n.sleigh) {
                    const off = el('button', 'btn small danger', T('ui_sl_remove_team'));
                    off.addEventListener('click', () => { post('restyle', { id: n.id, changes: { sleigh: false } }); S.editing = null; setTimeout(() => post('refreshNearby'), 400); });
                    ed.appendChild(off);
                }
                list.appendChild(ed);
            }
            if (n.drop && S.editing === n.id) {
                const st = Object.assign({}, n.drop, { palette: n.drop.palette || null });
                const ed = el('div', 'item editor wrap');
                const inner = el('div', 'main');
                const redraw = () => { inner.innerHTML = ''; ballSettings(inner, st, redraw, false); };
                redraw();
                ed.appendChild(inner);
                const save = el('button', 'btn small primary', T('ui_save'));
                save.addEventListener('click', () => {
                    post('restyle', { id: n.id, changes: { drop: ballOut(st, true) } });
                    S.editing = null;
                    setTimeout(() => post('refreshNearby'), 400);
                });
                ed.appendChild(save);
                list.appendChild(ed);
            }
            if (n.fw && S.editing === n.id) {
                // A placed launcher's settings, edited in place.
                const h = S.data.holidays.find(x => x.name === n.holiday);
                const rack = h && (h.launchers || []).find(r => r.name === n.rack);
                if (h && rack) {
                    const st = Object.assign({}, n.fw, { palette: n.fw.palette || null });
                    const ed = el('div', 'item editor wrap');
                    const inner = el('div', 'main');
                    const redraw = () => { inner.innerHTML = ''; launcherSettings(inner, h, rack, st, redraw); };
                    redraw();
                    ed.appendChild(inner);
                    const save = el('button', 'btn small primary', T('ui_save'));
                    save.addEventListener('click', () => {
                        post('restyle', { id: n.id, changes: { fw: { load: st.load, palette: st.palette || false, channel: st.channel, lift: st.lift, tilt: st.tilt, hidden: !!st.hidden } } });
                        S.editing = null;
                        setTimeout(() => post('refreshNearby'), 400);
                    });
                    ed.appendChild(save);
                    list.appendChild(ed);
                }
            }
        }
    }

    // ---- Locations and layouts ----
    function when(ts) {
        if (!ts) return '';
        const d = new Date(ts * 1000);
        return d.toLocaleDateString(undefined, { month: 'short', day: 'numeric', year: 'numeric' });
    }
    function holidayLabel(name) { return (S.data.holidays.find(x => x.name === name) || {}).label || name; }
    function renderPlaces(body) {
        const d = S.data;
        const can = d.who.decorator || d.who.admin;

        // Live locations, each with Travel and Use, and the holiday sets it holds.
        const live = section(body, T('ui_place_live_groups'), T('ui_location_sets_help') + ' ' + T('ui_group_help'));
        const gl = el('div', 'list'); gl.id = 'live-groups';
        live.appendChild(gl);
        renderLiveGroups(gl, d.groups);

        // Move everything around me into one location: how a city
        // decorated under one name gets a location per building.
        if (can) renderClaim(body);

        // Save the current location as a layout. Say which location that
        // is, and warn when it is spread over several places.
        const sv = section(body, T('ui_place_save'), T('ui_place_save_help'));
        const cur = (d.groups || []).find(g => g.name === d.settings.group);
        sv.appendChild(el('div', 'note', T('ui_place_saving').replace('%{group}', d.settings.group).replace('%{count}', cur ? cur.count : 0)));
        if (cur && cur.areas > 1) sv.appendChild(el('div', 'note warn', T('ui_place_spread').replace('%{group}', cur.name).replace('%{areas}', cur.areas)));
        const row = el('div', 'row');
        const nm = el('input', 'input grow'); nm.type = 'text'; nm.placeholder = T('ui_place_name'); nm.maxLength = 48; nm.value = d.settings.group;
        row.appendChild(nm);
        sv.appendChild(row);
        const note = el('input', 'input'); note.type = 'text'; note.placeholder = T('ui_place_note'); note.maxLength = 240;
        sv.appendChild(note);
        const row2 = el('div', 'row');
        const onlyH = el('label', 'check'); const cb = el('input'); cb.type = 'checkbox'; onlyH.appendChild(cb); onlyH.appendChild(document.createTextNode(` ${T('ui_place_only_holiday')} (${holidayLabel(S.holiday)})`));
        cb.addEventListener('change', () => { if (cb.checked && nm.value.trim() === d.settings.group) nm.value = `${d.settings.group} ${holidayLabel(S.holiday)}`; });
        row2.appendChild(onlyH);
        const save = el('button', 'btn small primary', T('ui_save'));
        save.disabled = !can;
        save.addEventListener('click', () => { if (!nm.value.trim()) return; post('presetSave', { name: nm.value, note: note.value, group: d.settings.group, holiday: cb.checked ? S.holiday : null }); });
        row2.appendChild(save);
        sv.appendChild(row2);

        // Saved layouts.
        const sl = section(body, T('ui_place_saved'), T('ui_places_help'));
        const next = el('button', 'btn small', T('ui_place_next'));
        next.title = T('ui_place_travel');
        next.addEventListener('click', () => {
            const list = d.presets || [];
            if (!list.length) return;
            S.tour = ((S.tour === undefined ? -1 : S.tour) + 1) % list.length;
            post('travelPreset', { name: list[S.tour].name });
        });
        sl.firstChild.appendChild(next);
        const pl = el('div', 'list'); pl.id = 'presets';
        sl.appendChild(pl);
        renderPresets(pl, d.presets);
    }
    function renderClaim(body) {
        const d = S.data;
        const sec = section(body, T('ui_claim'), T('ui_claim_help'));
        const row = el('div', 'row');
        const into = el('input', 'input grow'); into.type = 'text'; into.maxLength = 32;
        into.placeholder = T('ui_group_new'); into.value = d.settings.group;
        into.title = T('ui_claim_into');
        row.appendChild(into);
        sec.appendChild(row);
        const row2 = el('div', 'row');
        // Distances up to the server's reach; admins can sweep a whole lot.
        const reach = Math.round(d.reach || 60);
        const steps = [10, 20, 30, 45, 60, 90, 150, 250].filter(m => m < reach || (d.who.admin && m <= 250));
        if (!steps.includes(reach)) steps.push(reach);
        steps.sort((a, b) => a - b);
        const rad = el('select', 'input small'); rad.title = T('ui_claim_within');
        for (const m of steps) { const o = el('option', '', `${T('ui_claim_within')} ${m} m`); o.value = m; o.selected = m === Math.min(30, reach); rad.appendChild(o); }
        row2.appendChild(rad);
        const from = el('select', 'input small'); from.title = T('ui_claim_from');
        const any = el('option', '', T('ui_claim_any')); any.value = ''; from.appendChild(any);
        for (const g of d.groups || []) { const o = el('option', '', `${T('ui_claim_from')} ${g.name}`); o.value = g.name; from.appendChild(o); }
        row2.appendChild(from);
        const go = el('button', 'btn small primary', T('ui_claim_go'));
        let timer = null;
        const disarm = () => { delete go.dataset.armed; go.textContent = T('ui_claim_go'); go.classList.remove('danger'); };
        go.addEventListener('click', () => {
            const name = into.value.trim().replace(/\s+/g, ' ');
            if (!name) return;
            if (go.dataset.armed) {
                clearTimeout(timer); disarm();
                post('claim', { group: name, radius: Number(rad.value), from: from.value });
                d.settings.group = name;
                // Redraw once the server has moved them: new counts, the
                // save box on the new location.
                setTimeout(() => render(), 900);
                return;
            }
            go.dataset.armed = '1';
            go.classList.add('danger');
            go.textContent = T('ui_claim_arm').replace('%{radius}', rad.value).replace('%{group}', name);
            timer = setTimeout(disarm, 6000);
        });
        row2.appendChild(go);
        sec.appendChild(row2);
    }
    function renderLiveGroups(list, groups) {
        list.innerHTML = '';
        const d = S.data;
        if (!groups || !groups.length) { list.appendChild(el('div', 'note', T('ui_group_none'))); return; }
        for (const g of groups) {
            const it = el('div', 'item preset' + (g.name === d.settings.group ? ' active' : ''));
            const main = el('div', 'main');
            main.appendChild(el('div', 't', g.name));
            main.appendChild(el('div', 'd', `${g.props} ${T('ui_props')} · ${g.lights} ${T('ui_lights')} · ${g.dist} m${g.running ? ` · ${T('ui_group_show_on')}` : ''}`));
            if (g.areas > 1) main.appendChild(el('div', 'd warn', T('ui_group_spread').replace('%{areas}', g.areas)));
            // One chip per holiday set at this location; admins clear a set from it.
            const sets = el('div', 'chips sets');
            for (const h of g.holidays || []) {
                const c = el(d.who.admin ? 'button' : 'span', 'chip small');
                c.appendChild(el('span', 'dot' + (h.inSeason ? ' on' : '')));
                c.appendChild(document.createTextNode(`${holidayLabel(h.name)} `));
                c.appendChild(el('span', 'cnt', String(h.count)));
                if (d.who.admin) {
                    c.title = T('ui_clear_holiday').replace('%{holiday}', holidayLabel(h.name));
                    c.addEventListener('click', () => {
                        if (c.dataset.armed) { post('clearGroup', { group: g.name, holiday: h.name }); c.disabled = true; }
                        else { c.dataset.armed = '1'; c.textContent = `${T('ui_group_clear')} ${holidayLabel(h.name)} (${h.count})?`; c.classList.add('danger'); }
                    });
                }
                sets.appendChild(c);
            }
            main.appendChild(sets);
            it.appendChild(main);
            const acts = el('div', 'acts');
            const go = el('button', 'btn small primary', T('ui_place_travel')); go.disabled = !(d.who.decorator || d.who.admin);
            go.addEventListener('click', () => post('travelGroup', { group: g.name }));
            acts.appendChild(go);
            const use = el('button', 'btn small', T('ui_group_use')); use.disabled = g.name === d.settings.group;
            use.addEventListener('click', () => setGroup(g.name));
            acts.appendChild(use);
            it.appendChild(acts);
            list.appendChild(it);
        }
        // Admins: one control that takes down everything on the server.
        // Armed by a first click, disarms itself after a few seconds, and
        // the server files a backup of the decorations before it clears.
        if (d.who.admin) {
            const total = groups.reduce((n, g) => n + (g.count || 0), 0);
            const row = el('div', 'item preset danger-row');
            const main = el('div', 'main');
            main.appendChild(el('div', 't', T('ui_clear_all')));
            main.appendChild(el('div', 'd', T('ui_clear_all_help')));
            row.appendChild(main);
            const btn = el('button', 'btn small danger', T('ui_group_clear'));
            let timer = null;
            btn.addEventListener('click', () => {
                if (btn.dataset.armed) {
                    post('clearGroup', { group: '*' });
                    btn.disabled = true;
                    clearTimeout(timer);
                } else {
                    btn.dataset.armed = '1';
                    btn.textContent = T('ui_clear_all_arm').replace('%{count}', total);
                    timer = setTimeout(() => { delete btn.dataset.armed; btn.textContent = T('ui_group_clear'); }, 6000);
                }
            });
            row.appendChild(btn);
            list.appendChild(row);
        }
    }
    function renderPresets(list, presets) {
        list.innerHTML = '';
        const d = S.data;
        const can = d.who.decorator || d.who.admin;
        if (!presets || !presets.length) { list.appendChild(el('div', 'note', T('ui_places_none'))); return; }
        for (const p of presets) {
            const it = el('div', 'item preset');
            const main = el('div', 'main');
            main.appendChild(el('div', 't', `${p.name}${p.dist !== null && p.dist !== undefined ? `  ·  ${p.dist} m` : ''}`));
            if (p.note) main.appendChild(el('div', 'desc', p.note));
            if (p.areas > 1) main.appendChild(el('div', 'd warn', T('ui_group_spread').replace('%{areas}', p.areas)));
            const hs = (p.holidays || []).map(holidayLabel).join(', ');
            main.appendChild(el('div', 'd', `${p.count} ${T('ui_place_count')} · ${hs} · ${T('ui_group')} ${p.group} · ${T('ui_place_saved')} ${when(p.savedAt)} ${T('ui_by')} ${p.byName} · ${p.checkedAt ? T('ui_place_checked') + ' ' + when(p.checkedAt) : T('ui_place_never_checked')}`));
            it.appendChild(main);
            const acts = el('div', 'acts');
            const go = el('button', 'btn small primary', T('ui_place_travel')); go.disabled = !can;
            go.addEventListener('click', () => post('travelPreset', { name: p.name }));
            acts.appendChild(go);
            const ld = el('button', 'btn small', T('ui_place_load_add')); ld.disabled = !can;
            ld.addEventListener('click', () => post('presetLoad', { name: p.name, mode: 'add' }));
            acts.appendChild(ld);
            const lr = el('button', 'btn small', T('ui_place_load_replace')); lr.disabled = !can;
            lr.addEventListener('click', () => { if (lr.dataset.armed) { post('presetLoad', { name: p.name, mode: 'replace' }); lr.dataset.armed = ''; lr.textContent = T('ui_place_load_replace'); } else { lr.dataset.armed = '1'; lr.textContent = T('ui_place_load_replace') + '?'; } });
            acts.appendChild(lr);
            if (p.mine) {
                const so = el('button', 'btn small', T('ui_place_save_over'));
                so.addEventListener('click', () => { if (so.dataset.armed) { post('presetSave', { name: p.name, group: p.group }); so.dataset.armed = ''; so.textContent = T('ui_place_save_over'); } else { so.dataset.armed = '1'; so.textContent = T('ui_place_save_over') + '?'; } });
                acts.appendChild(so);
                const rn = el('button', 'btn small', T('ui_place_rename'));
                rn.addEventListener('click', () => {
                    if (it.querySelector('.rename')) return;
                    const f = el('div', 'rename row');
                    const n2 = el('input', 'input grow'); n2.type = 'text'; n2.value = p.name; n2.maxLength = 48;
                    const t2 = el('input', 'input grow'); t2.type = 'text'; t2.value = p.note || ''; t2.placeholder = T('ui_place_note'); t2.maxLength = 240;
                    const ok = el('button', 'btn small primary', T('ui_save'));
                    ok.addEventListener('click', () => post('presetUpdate', { name: p.name, newName: n2.value, note: t2.value }));
                    f.appendChild(n2); f.appendChild(t2); f.appendChild(ok);
                    it.appendChild(f);
                });
                acts.appendChild(rn);
                const del = el('button', 'btn small danger', T('ui_place_delete'));
                del.title = T('ui_place_delete_help');
                del.addEventListener('click', () => { if (del.dataset.armed) post('presetDelete', { name: p.name }); else { del.dataset.armed = '1'; del.textContent = T('ui_place_delete_arm'); } });
                acts.appendChild(del);
            }
            it.appendChild(acts);
            list.appendChild(it);
        }
    }

    // ---- Vehicles (floats) ----
    // A float is a location that rides on a vehicle. Make one from the
    // vehicle you are at, decorate it with the other tabs, put it on more
    // vehicles (this one, a plate, a whole model) or on a moving object.
    function bindingLabel(b) {
        if (b.kind === 'plate') return `${T('ui_fl_kind_plate')} ${b.plate}`;
        if (b.kind === 'model') return `${T('ui_fl_kind_model')}: ${b.modelName || b.model}`;
        if (b.kind === 'object') return `${T('ui_fl_kind_object')}: ${b.modelName || b.model}`;
        return `${T('ui_fl_kind_vehicle')} ${b.plate || ''}${b.session ? ' (' + T('ui_fl_session') + ')' : ''}`;
    }
    function renderVehicles(body) {
        const d = S.data;
        const F = d.floats || {};
        body.appendChild(el('div', 'note experimental', T('ui_fl_experimental')));
        if (!F.enabled) { body.appendChild(el('div', 'note', T('ui_fl_off'))); return; }
        const can = d.who.decorator || d.who.admin;
        const owner = !can && F.ownersMay;
        S.fl = S.fl || { kind: 'vehicle', float: null, plate: '' };
        const st = S.fl;
        body.appendChild(el('div', 'note', T('ui_fl_help')));
        if (owner) body.appendChild(el('div', 'note', T('ui_fl_owner_note')));

        if (F.editing) {
            const bar = el('div', 'item active');
            const main = el('div', 'main');
            main.appendChild(el('div', 't', T('ui_fl_editing').replace('%{name}', F.editing.name)));
            main.appendChild(el('div', 'd', T('ui_fl_editing_help')));
            bar.appendChild(main);
            const done = el('button', 'btn small primary', T('ui_fl_done'));
            done.addEventListener('click', () => post('floatDone'));
            bar.appendChild(done);
            body.appendChild(bar);
        }

        // The vehicle the player is in or next to.
        const hb = section(body, T('ui_fl_here'));
        const h = F.here;
        if (!h) {
            hb.appendChild(el('div', 'note', T('ui_fl_none_here')));
        } else {
            const it = el('div', 'item');
            const main = el('div', 'main');
            main.appendChild(el('div', 't', `${h.label}  ·  ${T('ui_fl_plate')} ${h.plate || '-'}`));
            main.appendChild(el('div', 'd', `${h.inside ? T('ui_fl_inside') : T('ui_fl_nearby')} · ${T('ui_fl_wearing')}: ${h.wearing || T('ui_fl_wearing_none')}`));
            // A vehicle only this player's game has (a display car a script
            // parks on each screen): it carries a float by its spot.
            if (h.localOnly) main.appendChild(el('div', 'd warn', T('ui_fl_local_only')));
            it.appendChild(main);
            if (h.wearing && (can || owner)) {
                const ed = el('button', 'btn small primary', T('ui_fl_edit'));
                ed.disabled = !!(F.editing && F.editing.name === h.wearing);
                ed.addEventListener('click', () => post('floatEdit', { name: h.wearing }));
                it.appendChild(ed);
                const off = el('button', 'btn small', T('ui_fl_take_off'));
                off.addEventListener('click', () => post('floatClear'));
                it.appendChild(off);
            }
            hb.appendChild(it);

            if (can || owner) {
                const mk = section(body, T('ui_fl_new'), T('ui_fl_new_help'));
                const row = el('div', 'row');
                const nm = el('input', 'input grow'); nm.type = 'text'; nm.placeholder = T('ui_fl_name'); nm.maxLength = 32;
                const go = el('button', 'btn small primary', T('ui_fl_create'));
                const create = () => { if (nm.value.trim()) post('floatCreate', { name: nm.value.trim() }); };
                go.addEventListener('click', create);
                nm.addEventListener('keydown', ev => { if (ev.key === 'Enter') create(); });
                row.appendChild(nm); row.appendChild(go);
                mk.appendChild(row);

                const floats = F.floats || [];
                if (floats.length) {
                    const pu = section(body, T('ui_fl_put_on'), T('ui_fl_put_on_help'));
                    if (!st.float || !floats.some(f => f.name === st.float)) st.float = floats[0].name;
                    const sel = el('select', 'input');
                    for (const f of floats) { const o = el('option', '', f.name); o.value = f.name; o.selected = st.float === f.name; sel.appendChild(o); }
                    sel.addEventListener('change', () => { st.float = sel.value; });
                    labeled(pu, T('ui_fl_pick_float')).appendChild(sel);
                    // A vehicle only in this game is bound by its spot: no plate, no fleet.
                    const kinds = (can && !h.localOnly) ? ['vehicle', 'plate', 'model'] : ['vehicle'];
                    if (!kinds.includes(st.kind)) st.kind = 'vehicle';
                    segment(pu, kinds, st.kind, v => { st.kind = v; render(); }, v => T('ui_fl_kind_' + v));
                    let plateIn = null;
                    if (can && F.setPlates && st.kind !== 'model' && !h.localOnly) {
                        const pb = labeled(pu, T('ui_fl_new_plate'));
                        help(pb.firstChild, T('ui_fl_new_plate_help'));
                        plateIn = el('input', 'input'); plateIn.type = 'text'; plateIn.maxLength = 8; plateIn.placeholder = h.plate || ''; plateIn.value = st.plate || '';
                        plateIn.addEventListener('input', () => { plateIn.value = plateIn.value.toUpperCase().replace(/[^A-Z0-9 ]/g, ''); st.plate = plateIn.value; });
                        pb.appendChild(plateIn);
                    }
                    const ap = el('button', 'btn small primary', T('ui_fl_apply'));
                    ap.addEventListener('click', () => { post('floatBind', { name: st.float, kind: st.kind, plate: plateIn ? plateIn.value.trim() : '' }); st.plate = ''; });
                    pu.appendChild(ap);
                    pu.appendChild(el('div', 'note', F.saveBindings ? T('ui_fl_saved_note') : T('ui_fl_unsaved_note')));
                }
            }
        }

        // A float on an object in the world (decorators).
        if (can) {
            const ob = section(body, T('ui_fl_object'), T('ui_fl_object_help'));
            const row = el('div', 'row');
            const nm = el('input', 'input grow'); nm.type = 'text'; nm.placeholder = T('ui_fl_name'); nm.maxLength = 32;
            const mk = el('button', 'btn small', T('ui_fl_object_new'));
            mk.addEventListener('click', () => { if (nm.value.trim()) post('floatObject', { what: 'create', name: nm.value.trim() }); });
            row.appendChild(nm); row.appendChild(mk);
            ob.appendChild(row);
        }

        // Every float, and what wears it.
        const fl = section(body, T('ui_fl_floats'));
        const refresh = el('button', 'btn small', T('ui_refresh'));
        refresh.addEventListener('click', () => post('floatRefresh'));
        fl.firstChild.appendChild(refresh);
        fl.appendChild(el('div', 'note', T('ui_fl_drawn').replace('%{count}', F.drawn || 0)));
        const list = el('div', 'list');
        fl.appendChild(list);
        const floats = F.floats || [];
        if (!floats.length) list.appendChild(el('div', 'note', T('ui_fl_floats_none')));
        for (const f of floats) {
            const it = el('div', 'item preset' + (F.editing && F.editing.name === f.name ? ' active' : ''));
            const main = el('div', 'main');
            main.appendChild(el('div', 't', `${f.name}${f.modelName ? '  ·  ' + f.modelName : ''}`));
            main.appendChild(el('div', 'd', `${f.items} ${T('ui_fl_items')} · ${f.bulbs} ${T('ui_fl_bulbs')} · ${T('ui_fl_wearing_count').replace('%{count}', f.wearing || 0)} · ${T('ui_by')} ${f.byName || '?'}`));
            const binds = (F.bindings || []).filter(b => b.float === f.name);
            const chips = el('div', 'chips sets');
            if (!binds.length) chips.appendChild(el('span', 'note', T('ui_fl_bindings_none')));
            for (const b of binds) {
                const label = bindingLabel(b);
                const c = el(can ? 'button' : 'span', 'chip small', label);
                if (can) {
                    c.title = T('ui_fl_unbind');
                    c.addEventListener('click', () => {
                        if (c.dataset.armed) { post('floatUnbind', { id: b.id, restore: false }); c.disabled = true; }
                        else { c.dataset.armed = '1'; c.textContent = `${T('ui_fl_unbind')} ${label}?`; c.classList.add('danger'); }
                    });
                }
                chips.appendChild(c);
                if (can && b.oldPlate) {
                    const r = el('button', 'chip small', T('ui_fl_restore_plate').replace('%{plate}', b.oldPlate));
                    r.addEventListener('click', () => { post('floatUnbind', { id: b.id, restore: true }); r.disabled = true; });
                    chips.appendChild(r);
                }
            }
            main.appendChild(chips);
            it.appendChild(main);
            const acts = el('div', 'acts');
            if (can) {
                if (binds.some(b => b.kind === 'object')) {
                    const oe = el('button', 'btn small', T('ui_fl_object_edit'));
                    oe.addEventListener('click', () => post('floatObject', { what: 'edit', name: f.name }));
                    acts.appendChild(oe);
                }
                const ob = el('button', 'btn small', T('ui_fl_object_bind'));
                ob.addEventListener('click', () => post('floatObject', { what: 'bind', name: f.name }));
                acts.appendChild(ob);
            }
            if (can || (owner && f.owner)) {
                const del = el('button', 'btn small danger', T('ui_fl_delete'));
                del.addEventListener('click', () => {
                    if (del.dataset.armed) { post('floatDelete', { name: f.name }); del.disabled = true; }
                    else { del.dataset.armed = '1'; del.textContent = `${T('ui_fl_delete')} (${f.items})?`; }
                });
                acts.appendChild(del);
            }
            it.appendChild(acts);
            list.appendChild(it);
        }
    }

    // ---- Tips ----
    function renderTips(body) {
        holidayChips(body, () => { render(); post('tips', { holiday: S.holiday }); });
        const ol = el('ol', 'tips-inline'); ol.id = 'tips-inline';
        if (S.tipsInline && S.tipsInline.holiday === S.holiday) for (const t of S.tipsInline.items) ol.appendChild(el('li', '', t));
        body.appendChild(ol);
    }

    // ---- Settings ----
    function renderSettings(body) {
        const d = S.data;
        const mine = labeled(body, T('ui_my_settings'));
        groupPicker(mine);
        const kv = el('div', 'kv');
        kv.appendChild(el('span', '', T('ui_channel')));
        const chWrap = el('div'); segment(chWrap, [1, 2, 3, 4], d.settings.channel, v => { d.settings.channel = v; S.lights.channel = v; S.figure.channel = v; post('setChannel', { channel: v }); render(); }); kv.appendChild(chWrap);
        kv.appendChild(el('span', '', T('ui_quality')));
        const qWrap = el('div'); segment(qWrap, ['low', 'medium', 'high', 'ultra'], d.settings.quality, v => { d.settings.quality = v; post('setQuality', { quality: v }); render(); }); kv.appendChild(qWrap);
        if (d.allowMute) {
            kv.appendChild(el('span', '', d.settings.muted ? T('ui_unmute') : T('ui_mute')));
            const sw = el('button', 'switch'); sw.setAttribute('role', 'switch'); sw.setAttribute('aria-checked', !d.settings.muted);
            sw.addEventListener('click', () => { d.settings.muted = !d.settings.muted; post('setMuted', { muted: d.settings.muted }); render(); });
            kv.appendChild(sw);
        }
        kv.appendChild(el('span', '', T('ui_view_time')));
        const tWrap = el('div');
        const presets = [['server', T('ui_time_server')], ['dusk', T('ui_time_dusk')], ['night', T('ui_time_night')], ['midnight', T('ui_time_midnight')], ['day', T('ui_time_day')]];
        const curT = d.settings.viewTime ? ({ '19:45': 'dusk', '22:30': 'night', '00:00': 'midnight', '12:00': 'day' })[d.settings.viewTime] || d.settings.viewTime : 'server';
        segment(tWrap, presets.map(p => p[0]), curT, v => { d.settings.viewTime = v === 'server' ? null : v; post('setViewTime', { time: v }); render(); }, v => (presets.find(p => p[0] === v) || [v, v])[1]);
        kv.appendChild(tWrap);
        if (d.who.decorator || d.who.admin) {
            kv.appendChild(el('span', '', T('ui_preview')));
            const pv = el('button', 'switch'); pv.setAttribute('role', 'switch'); pv.setAttribute('aria-checked', d.settings.preview !== false);
            pv.addEventListener('click', () => { d.settings.preview = !(d.settings.preview !== false); post('setPreview', { preview: d.settings.preview }); render(); });
            kv.appendChild(pv);
        }
        // Fireworks, for this player only.
        kv.appendChild(el('span', '', T('ui_fw_mine')));
        const fo = el('button', 'switch'); fo.setAttribute('role', 'switch'); fo.setAttribute('aria-checked', !d.settings.fwOff);
        fo.addEventListener('click', () => { d.settings.fwOff = !d.settings.fwOff; post('setFw', { off: d.settings.fwOff }); render(); });
        kv.appendChild(fo);
        kv.appendChild(el('span', '', `${T('ui_fw_volume')}: ${Math.round((d.settings.fwVolume ?? 1) * 100)}%`));
        const fv = el('input'); fv.type = 'range'; fv.min = 0; fv.max = 1; fv.step = 0.05; fv.value = d.settings.fwVolume ?? 1;
        fv.addEventListener('change', () => { d.settings.fwVolume = parseFloat(fv.value); post('setFw', { volume: d.settings.fwVolume }); render(); });
        kv.appendChild(fv);
        kv.appendChild(el('span', '', T('ui_fw_whistle')));
        const fw = el('button', 'switch'); fw.setAttribute('role', 'switch'); fw.setAttribute('aria-checked', d.settings.fwWhistle !== false); fw.title = T('ui_fw_whistle_help');
        fw.addEventListener('click', () => { d.settings.fwWhistle = d.settings.fwWhistle === false; post('setFw', { whistle: d.settings.fwWhistle }); render(); });
        kv.appendChild(fw);
        kv.appendChild(el('span', '', T('ui_fw_calm')));
        const fc = el('button', 'switch'); fc.setAttribute('role', 'switch'); fc.setAttribute('aria-checked', !!d.settings.fwCalm); fc.title = T('ui_fw_calm_help');
        fc.addEventListener('click', () => { d.settings.fwCalm = !d.settings.fwCalm; post('setFw', { calm: d.settings.fwCalm }); render(); });
        kv.appendChild(fc);
        mine.appendChild(kv);
        mine.appendChild(el('div', 'note', T('ui_view_time_help')));
        mine.appendChild(el('div', 'note', T('ui_fw_calm_help')));
        if (d.who.decorator || d.who.admin) mine.appendChild(el('div', 'note', T('ui_preview_help')));

        const srv = labeled(body, T('ui_server_settings'));
        if (!d.who.admin) { srv.appendChild(el('div', 'note', T('ui_admin_only'))); return; }
        if (!S.settings) { srv.appendChild(el('div', 'note', '...')); return; }
        renderServerSettings(srv, S.settings);
    }

    function renderServerSettings(root, snap) {
        const pending = { values: {} };
        const status = snap.status || {};
        root.appendChild(el('div', 'note', `${T('ui_status')}: ${status.count} ${T('ui_decorations')} · ${status.enabled ? (status.loaded ? 'saving ok' : 'NOT LOADED') : 'saving disabled'}${status.lastSave && !status.lastSave.ok ? ' · last save FAILED: ' + status.lastSave.reason : ''}`));

        // Updates.
        const up = snap.update || {};
        const ub = el('div', 'item' + (up.available ? ' active' : ''));
        const um = el('div', 'main');
        um.appendChild(el('div', 't', `${T('ui_updates')}: ${T('ui_update_running')} ${up.current}${up.latest ? ` · ${T('ui_update_latest')} ${up.latest}` : ''}${up.available ? '' : (up.latest ? ` · ${T('ui_update_none')}` : '')}`));
        let detail = up.enabled ? (up.lastError || (up.applied ? `${up.applied} ${T('ui_update_restart')}` : (up.published ? up.published : ''))) : T('ui_update_off');
        um.appendChild(el('div', 'd', detail));
        if (up.available && up.changelog && up.changelog.length) {
            const ul = el('ul', 'tips-inline'); for (const c of up.changelog) ul.appendChild(el('li', '', c)); um.appendChild(ul);
        }
        ub.appendChild(um);
        const chk = el('button', 'btn small', T('ui_update_check')); chk.disabled = !up.enabled;
        chk.addEventListener('click', () => { post('admin', { action: 'update', arg: 'check' }); setTimeout(() => post('settingsGet'), 2500); });
        ub.appendChild(chk);
        if (up.available) {
            const ap = el('button', 'btn small primary', T('ui_update_apply'));
            ap.addEventListener('click', () => { post('admin', { action: 'update', arg: 'apply' }); setTimeout(() => post('settingsGet'), 6000); });
            ub.appendChild(ap);
        }
        root.appendChild(ub);

        for (const section of snap.schema) {
            const box = labeled(root, section.label);
            for (const item of section.items) {
                const row = el('div', 'setting');
                const head = el('div', 'h');
                head.appendChild(el('span', '', item.label));
                const cur = snap.values[item.path];
                let input;
                if (item.type === 'bool') {
                    input = el('button', 'switch'); input.setAttribute('role', 'switch'); input.setAttribute('aria-checked', cur === true);
                    input.addEventListener('click', () => { const v = input.getAttribute('aria-checked') !== 'true'; input.setAttribute('aria-checked', v); pending.values[item.path] = v; });
                } else if (item.type === 'select') {
                    input = el('select', 'input');
                    for (const o of item.options) { const op = el('option', '', o); op.value = o; if (o === cur) op.selected = true; input.appendChild(op); }
                    input.addEventListener('change', () => pending.values[item.path] = input.value);
                } else {
                    input = el('input', 'input');
                    input.type = (item.type === 'int' || item.type === 'number') ? 'number' : 'text';
                    if (item.min !== undefined) input.min = item.min;
                    if (item.max !== undefined) input.max = item.max;
                    if (item.type === 'number') input.step = 'any';
                    input.value = item.type === 'list' ? (cur || []).join(', ') : (cur === undefined || cur === null ? '' : cur);
                    input.addEventListener('change', () => pending.values[item.path] = (item.type === 'list') ? input.value : (input.type === 'number' ? parseFloat(input.value) : input.value));
                }
                input.id = 'set-' + item.path.replace(/\./g, '-');
                head.appendChild(input);
                row.appendChild(head);
                if (item.help) row.appendChild(el('div', 'help', item.help));
                box.appendChild(row);
            }
        }

        // Holiday dates.
        const hd = labeled(root, T('ui_holiday_dates'));
        const table = el('table', 'grid');
        table.innerHTML = `<tr><th>${T('ui_holiday')}</th><th>${T('ui_enabled')}</th><th>${T('ui_from')}</th><th>${T('ui_to')}</th></tr>`;
        const holidaysDoc = JSON.parse(JSON.stringify(snap.doc.holidays || {}));
        for (const h of S.data.holidays) {
            const tr = el('tr');
            tr.appendChild(el('td', '', h.label));
            const o = holidaysDoc[h.name] || {};
            const en = el('input'); en.type = 'checkbox'; en.checked = o.enabled !== false; en.addEventListener('change', () => { holidaysDoc[h.name] = holidaysDoc[h.name] || {}; holidaysDoc[h.name].enabled = en.checked; pending.holidays = holidaysDoc; });
            const td1 = el('td'); td1.appendChild(en); tr.appendChild(td1);
            for (const k of ['from', 'to']) {
                const inp = el('input'); inp.type = 'text'; inp.placeholder = 'MM-DD'; inp.value = o[k] || '';
                inp.addEventListener('change', () => { holidaysDoc[h.name] = holidaysDoc[h.name] || {}; holidaysDoc[h.name][k] = inp.value.trim(); pending.holidays = holidaysDoc; });
                const td = el('td'); td.appendChild(inp); tr.appendChild(td);
            }
            table.appendChild(tr);
        }
        hd.appendChild(table);
        hd.appendChild(el('div', 'help', 'Blank keeps the shipped window. Easter and Party have no dates.'));

        // Custom props.
        const cp = labeled(root, T('ui_custom_props'));
        const props = JSON.parse(JSON.stringify(snap.doc.customProps || []));
        const ptable = el('table', 'grid');
        function drawProps() {
            ptable.innerHTML = `<tr><th>${T('ui_holiday')}</th><th>${T('ui_model')}</th><th>${T('ui_label')}</th><th>${T('ui_wall')}</th><th></th></tr>`;
            props.forEach((p, i) => {
                const tr = el('tr');
                tr.appendChild(el('td', '', (S.data.holidays.find(x => x.name === p.holiday) || {}).label || p.holiday));
                tr.appendChild(el('td', '', p.model));
                tr.appendChild(el('td', '', p.label));
                tr.appendChild(el('td', '', p.wall ? 'yes' : ''));
                const del = el('button', 'btn small danger', T('ui_delete')); del.addEventListener('click', () => { props.splice(i, 1); pending.customProps = props; drawProps(); });
                const td = el('td'); td.appendChild(del); tr.appendChild(td);
                ptable.appendChild(tr);
            });
            const tr = el('tr');
            const sel = el('select'); for (const h of S.data.holidays) { const op = el('option', '', h.label); op.value = h.name; sel.appendChild(op); }
            const model = el('input'); model.type = 'text'; model.placeholder = 'prop_model_name';
            const label = el('input'); label.type = 'text'; label.placeholder = T('ui_label');
            const wall = el('input'); wall.type = 'checkbox';
            const add = el('button', 'btn small primary', T('ui_add'));
            add.addEventListener('click', () => { if (!model.value.trim()) return; props.push({ holiday: sel.value, model: model.value.trim().toLowerCase(), label: label.value.trim() || model.value.trim(), wall: wall.checked }); pending.customProps = props; drawProps(); });
            for (const c of [sel, model, label, wall, add]) { const td = el('td'); td.appendChild(c); tr.appendChild(td); }
            ptable.appendChild(tr);
        }
        drawProps();
        cp.appendChild(ptable);

        // Custom tracks.
        const ct = labeled(root, T('ui_tracks'));
        const tracks = JSON.parse(JSON.stringify(snap.doc.tracks || {}));
        const ttable = el('table', 'grid');
        function drawTracks() {
            ttable.innerHTML = `<tr><th>${T('ui_name')}</th><th>${T('ui_label')}</th><th>${T('ui_file')}</th><th>${T('ui_duration')}</th><th>${T('ui_bpm')}</th><th>${T('ui_holiday')}</th><th></th></tr>`;
            for (const [name, t] of Object.entries(tracks)) {
                const tr = el('tr');
                for (const v of [name, t.label, t.file, t.duration, t.bpm, t.holiday || '']) tr.appendChild(el('td', '', v));
                const del = el('button', 'btn small danger', T('ui_delete')); del.addEventListener('click', () => { delete tracks[name]; pending.tracks = tracks; drawTracks(); });
                const td = el('td'); td.appendChild(del); tr.appendChild(td);
                ttable.appendChild(tr);
            }
            const tr = el('tr');
            const name = el('input'); name.placeholder = 'my_track';
            const label = el('input'); label.placeholder = T('ui_label');
            const file = el('input'); file.placeholder = 'my_track.ogg';
            const dur = el('input'); dur.type = 'number'; dur.placeholder = '60';
            const bpm = el('input'); bpm.type = 'number'; bpm.placeholder = '120';
            const sel = el('select'); { const op = el('option', '', '-'); op.value = ''; sel.appendChild(op); } for (const h of S.data.holidays) { const op = el('option', '', h.label); op.value = h.name; sel.appendChild(op); }
            const add = el('button', 'btn small primary', T('ui_add'));
            add.addEventListener('click', () => { const n = name.value.trim(); if (!n || !file.value.trim()) return; tracks[n] = { label: label.value.trim() || n, file: file.value.trim(), duration: parseFloat(dur.value) || 60, bpm: parseFloat(bpm.value) || 120, holiday: sel.value || null }; pending.tracks = tracks; drawTracks(); });
            for (const c of [name, label, file, dur, bpm, sel, add]) { const td = el('td'); td.appendChild(c); tr.appendChild(td); }
            ttable.appendChild(tr);
        }
        drawTracks();
        ct.appendChild(ttable);
        ct.appendChild(el('div', 'help', 'Drop the .ogg in the resource\'s audio/ folder and restart the resource for a new file to be served.'));

        // Shows editor.
        const se = labeled(root, T('ui_shows_editor'));
        const shows = JSON.parse(JSON.stringify(snap.doc.shows || {}));
        const PAT = ['on', 'off', 'twinkle', 'chase', 'alternate', 'fade', 'wave', 'flicker'];
        const FWP = (S.data && S.data.fireworks && S.data.fireworks.stepPatterns) || ['none'];
        const showsBox = el('div', 'list');
        function drawShows() {
            showsBox.innerHTML = '';
            const all = Object.assign({}, snap.shows, shows);
            for (const [name, s] of Object.entries(all)) {
                const custom = !!shows[name];
                const it = el('div');
                const head = el('div', 'row');
                head.appendChild(el('b', '', `${s.label || name} (${name})${custom ? '' : ' · shipped'}`));
                const editBtn = el('button', 'btn small', custom ? T('ui_delete') : 'Copy to edit');
                editBtn.addEventListener('click', () => { if (custom) delete shows[name]; else shows[name + '_2'] = JSON.parse(JSON.stringify({ label: (s.label || name) + ' 2', steps: s.steps })); pending.shows = shows; drawShows(); });
                head.appendChild(editBtn);
                it.appendChild(head);
                if (custom) {
                    const tbl = el('table', 'grid');
                    tbl.innerHTML = `<tr><th>${T('ui_beats')}</th><th>1</th><th>2</th><th>3</th><th>4</th><th>${T('ui_fw_steps')} 1</th><th>2</th><th>3</th><th>4</th><th></th></tr>`;
                    s.steps.forEach((step, i) => {
                        const tr = el('tr');
                        const beats = el('input'); beats.type = 'number'; beats.step = 0.25; beats.value = step.beats;
                        beats.addEventListener('change', () => { step.beats = parseFloat(beats.value) || 1; pending.shows = shows; });
                        const td0 = el('td'); td0.appendChild(beats); tr.appendChild(td0);
                        for (let c = 0; c < 4; c++) {
                            const sel = el('select'); for (const p of PAT) { const op = el('option', '', T('pattern_' + p)); op.value = p; if (step.ch[c] === p) op.selected = true; sel.appendChild(op); }
                            sel.addEventListener('change', () => { step.ch[c] = sel.value; pending.shows = shows; });
                            const td = el('td'); td.appendChild(sel); tr.appendChild(td);
                        }
                        // The fireworks each channel fires over the step.
                        for (let c = 0; c < 4; c++) {
                            const fwv = (step.fw && step.fw[c]) || 'none';
                            const sel = el('select'); for (const p of FWP) { const op = el('option', '', T('fw_step_' + p)); op.value = p; if (fwv === p) op.selected = true; sel.appendChild(op); }
                            sel.addEventListener('change', () => { step.fw = step.fw || ['none', 'none', 'none', 'none']; step.fw[c] = sel.value; pending.shows = shows; });
                            const td = el('td'); td.appendChild(sel); tr.appendChild(td);
                        }
                        const del = el('button', 'btn small danger', '×'); del.addEventListener('click', () => { s.steps.splice(i, 1); pending.shows = shows; drawShows(); });
                        const tdd = el('td'); tdd.appendChild(del); tr.appendChild(tdd);
                        tbl.appendChild(tr);
                    });
                    it.appendChild(tbl);
                    const addStep = el('button', 'btn small', '+ ' + T('ui_steps'));
                    addStep.addEventListener('click', () => { s.steps.push({ beats: 1, ch: ['on', 'on', 'on', 'on'] }); pending.shows = shows; drawShows(); });
                    it.appendChild(addStep);
                }
                showsBox.appendChild(it);
            }
            const nr = el('div', 'row');
            const nm = el('input', 'input'); nm.placeholder = 'new_show'; nm.style.maxWidth = '160px';
            const add = el('button', 'btn small primary', T('ui_add'));
            add.addEventListener('click', () => { const n = nm.value.trim(); if (!n) return; shows[n] = { label: n, steps: [{ beats: 4, ch: ['twinkle', 'twinkle', 'twinkle', 'twinkle'] }] }; pending.shows = shows; drawShows(); });
            nr.appendChild(nm); nr.appendChild(add);
            showsBox.appendChild(nr);
        }
        drawShows();
        se.appendChild(showsBox);

        const actions = el('div', 'row');
        const save = el('button', 'btn primary', T('ui_save'));
        save.addEventListener('click', () => { post('settingsSet', pending); S.settings = null; setTimeout(() => post('settingsGet'), 400); });
        const reset = el('button', 'btn danger', T('ui_reset'));
        reset.addEventListener('click', () => { if (reset.dataset.armed) { post('settingsSet', { reset: true }); S.settings = null; setTimeout(() => post('settingsGet'), 400); } else { reset.dataset.armed = '1'; reset.textContent = T('ui_reset') + '?'; } });
        actions.appendChild(save); actions.appendChild(reset);
        root.appendChild(actions);
    }

    // ------------------------------------------------------------------
    // Tray
    // ------------------------------------------------------------------
    function trayBtn(label, action, value, cls) {
        const b = el('button', 'btn small ' + (cls || ''), label);
        b.addEventListener('click', () => post('tray', { action, value }));
        return b;
    }
    function renderTray(mode, st) {
        const hint = $('tray-hint'), row = $('tray-row');
        row.innerHTML = '';
        const t = k => T(k);
        if (mode === 'pick') {
            renderPickTray(hint, row, st);
        } else if (mode === 'launch') {
            // Launch mode: the keys fire, the buttons do the same.
            hint.textContent = `${t('ui_fw_board')}: ${st.group} · ${t('ui_tray_hint_launch')}`;
            const fire = (action, channel) => { const b = el('button', 'btn small', `${t('ui_fw_' + action)}${channel ? ' ' + channel : ''}`); b.addEventListener('click', () => post('launchAction', { action: 'fire', value: { action, channel: channel || 0 } })); return b; };
            for (let c = 1; c <= 4; c++) {
                const g = el('div', 'group'); g.appendChild(el('span', 'label', `${c} · ${st.counts[c - 1]}`));
                const a = fire('shell', c); a.disabled = !st.counts[c - 1]; g.appendChild(a);
                const b = fire('salvo', c); b.disabled = !st.counts[c - 1]; g.appendChild(b);
                row.appendChild(g);
            }
            for (const a of ['sweep', 'cake', 'fountain', 'shape']) row.appendChild(fire(a));
            const fin = fire('finale'); fin.classList.add('danger'); row.appendChild(fin);
            const leave = el('button', 'btn small danger', t('ui_tray_leave_launch'));
            leave.addEventListener('click', () => post('launchAction', { action: 'leave' }));
            row.appendChild(leave);
        } else if (mode === 'prop') {
            hint.textContent = `${st.moving ? 'Moving' : 'Placing'}: ${st.label}  ·  ${t(st.shape ? 'ui_tray_hint_shape' : 'ui_tray_hint_prop')}`;
            const g = el('div', 'group');
            g.appendChild(el('span', 'stat', `${t('ui_rotate')} `)); g.appendChild(trayBtn('-45°', 'rotate', -45)); g.appendChild(trayBtn('-5°', 'rotate', -5)); g.appendChild(el('span', 'stat', `${st.heading}°`)); g.appendChild(trayBtn('+5°', 'rotate', 5)); g.appendChild(trayBtn('+45°', 'rotate', 45));
            row.appendChild(g);
            if (st.size) {
                const gs = el('div', 'group');
                gs.appendChild(el('span', 'label', st.wall ? t('ui_width') : t('ui_height')));
                gs.appendChild(trayBtn('-', 'size', (parseFloat(st.size) - (st.wall ? 0.1 : 0.2)).toFixed(1)));
                gs.appendChild(el('span', 'stat', `${st.size} m`));
                gs.appendChild(trayBtn('+', 'size', (parseFloat(st.size) + (st.wall ? 0.1 : 0.2)).toFixed(1)));
                row.appendChild(gs);
            }
            const g2 = el('div', 'group'); g2.appendChild(trayBtn('↑', 'raise', 0.05)); g2.appendChild(el('span', 'stat', `z ${st.z}`)); g2.appendChild(trayBtn('↓', 'raise', -0.05)); row.appendChild(g2);
            const g3 = el('div', 'group'); g3.appendChild(el('span', 'label', t('ui_nudge')));
            for (const [lbl, axis, v] of [['◀', 'r', -0.05], ['▶', 'r', 0.05], ['▲', 'f', 0.05], ['▼', 'f', -0.05]]) {
                const b = el('button', 'btn small', lbl); b.addEventListener('click', () => post('tray', { action: 'nudge', axis, value: v })); g3.appendChild(b);
            }
            row.appendChild(g3);
            if (!st.wall) row.appendChild(trayBtn((st.snap ? '✓ ' : '') + 'Snap to ground', 'snap'));
            row.appendChild(trayBtn((st.pinned ? '✓ ' : '') + t('ui_pinned'), 'pin'));
            row.appendChild(trayBtn((st.align ? '✓ ' : '') + t('ui_align'), 'align'));
            if (st.canHang) row.appendChild(trayBtn((st.hang ? '✓ ' : '') + t('ui_hang'), 'hang'));
            row.appendChild(trayBtn((st.repeat ? '✓ ' : '') + t('ui_repeat'), 'repeat'));
            if (st.hanging) row.appendChild(el('span', 'stat', t('ui_hanging')));
            if (st.aligned) { const s = el('span', 'stat'); s.innerHTML = `${t('ui_aligned')} <b>${st.aligned}</b>`; row.appendChild(s); }
            if (st.count) row.appendChild(el('span', 'stat', `${st.count} ${t('ui_placed')}`));
            row.appendChild(trayBtn(t('ui_tray_place'), 'place', null, 'primary'));
            row.appendChild(trayBtn(st.count ? t('ui_tray_done') : t('ui_tray_cancel'), 'cancel', null, st.count ? '' : 'danger'));
        } else {
            const isFig = mode === 'figure';
            hint.textContent = isFig ? `${st.label}  ·  ${t('ui_tray_hint_figure')}`
                : st.mode === 'outline' ? t('ui_tray_hint_outline') : st.mode === 'edge' ? t('ui_tray_hint_edge')
                : st.mode === 'facade' ? t('ui_tray_hint_facade') : t('ui_tray_hint_lights');
            if (!isFig && st.modes) {
                // How a click lays points: one at a time, or a whole surface.
                const md = el('div', 'group'); md.appendChild(el('span', 'label', t('ui_mode')));
                const mseg = el('div', 'seg');
                for (const m of st.modes) { const b = el('button', '', t('ui_mode_' + m)); b.setAttribute('aria-pressed', st.mode === m); b.addEventListener('click', () => post('tray', { action: 'mode', value: m })); mseg.appendChild(b); }
                md.appendChild(mseg); row.appendChild(md);
            }
            const pal = el('div', 'group'); pal.appendChild(el('span', 'label', t('ui_palette')));
            const h = S.data && S.data.holidays.find(x => x.name === st.holiday);
            for (const p of st.palettes) {
                const b = el('button', 'sw', p.replace(/_/g, ' '));
                if (h) { const pp = h.palettes.find(x => x.name === p); if (pp) { b.textContent = ''; for (const c of pp.colors) { const i = el('i'); i.style.background = rgb(c); i.style.color = rgb(c); b.appendChild(i); } b.appendChild(document.createTextNode(p.replace(/_/g, ' '))); } }
                b.setAttribute('aria-pressed', st.palette === p);
                b.addEventListener('click', () => post('tray', { action: 'palette', value: p }));
                pal.appendChild(b);
            }
            row.appendChild(pal);
            const pat = el('div', 'group'); pat.appendChild(el('span', 'label', t('ui_pattern')));
            const seg = el('div', 'seg');
            for (const p of st.patterns) { const b = el('button', '', T('pattern_' + p)); b.setAttribute('aria-pressed', st.pattern === p); b.addEventListener('click', () => post('tray', { action: 'pattern', value: p })); seg.appendChild(b); }
            pat.appendChild(seg); row.appendChild(pat);
            const ch = el('div', 'group'); ch.appendChild(el('span', 'label', t('ui_channel')));
            const cseg = el('div', 'seg');
            for (const n of [1, 2, 3, 4]) { const b = el('button', '', n); b.setAttribute('aria-pressed', st.channel === n); b.addEventListener('click', () => post('tray', { action: 'channel', value: n })); cseg.appendChild(b); }
            ch.appendChild(cseg); row.appendChild(ch);
            if (S.data) {
                const sty = el('div', 'group'); sty.appendChild(el('span', 'label', t('ui_style')));
                const sseg = el('div', 'seg');
                for (const s of S.data.styles) { const b = el('button', '', s.label); b.setAttribute('aria-pressed', st.style === s.name); b.addEventListener('click', () => post('tray', { action: 'style', value: s.name })); sseg.appendChild(b); }
                sty.appendChild(sseg); row.appendChild(sty);
            }
            if (isFig) {
                const g = el('div', 'group'); g.appendChild(trayBtn('-', 'size', parseFloat(st.size) - 0.2)); g.appendChild(el('span', 'stat', `${st.size} m`)); g.appendChild(trayBtn('+', 'size', parseFloat(st.size) + 0.2)); row.appendChild(g);
                const gz = el('div', 'group'); gz.appendChild(el('span', 'label', t('ui_raise'))); gz.appendChild(trayBtn('↑', 'raise', 0.05)); gz.appendChild(el('span', 'stat', `${st.z} m`)); gz.appendChild(trayBtn('↓', 'raise', -0.05)); row.appendChild(gz);
                row.appendChild(trayBtn((st.pinned ? '✓ ' : '') + t('ui_pinned'), 'pin'));
                row.appendChild(trayBtn((st.align ? '✓ ' : '') + t('ui_align'), 'align'));
                row.appendChild(trayBtn((st.hang ? '✓ ' : '') + t('ui_hang'), 'hang'));
                row.appendChild(trayBtn((st.repeat ? '✓ ' : '') + t('ui_repeat'), 'repeat'));
                if (st.hanging) row.appendChild(el('span', 'stat', t('ui_hanging')));
                if (st.aligned) { const s = el('span', 'stat'); s.innerHTML = `${t('ui_aligned')} <b>${st.aligned}</b>`; row.appendChild(s); }
                if (st.count) row.appendChild(el('span', 'stat', `${st.count} ${t('ui_placed')}`));
                row.appendChild(trayBtn(t('ui_tray_place'), 'place', null, 'primary'));
            } else {
                const g = el('div', 'group'); g.appendChild(trayBtn('-', 'spacing', (st.spacing - 0.05).toFixed(2))); g.appendChild(el('span', 'stat', `${Number(st.spacing).toFixed(2)} m`)); g.appendChild(trayBtn('+', 'spacing', (st.spacing + 0.05).toFixed(2))); row.appendChild(g);
                const stat = el('span', 'stat'); stat.innerHTML = `<b>${st.points}</b> ${t('ui_points')} · <b>${st.length}</b> ${t('ui_length')} · <b>${st.bulbs}</b> ${t('ui_bulbs')}`; row.appendChild(stat);
                row.appendChild(trayBtn((st.sag ? '✓ ' : '') + t('ui_sag'), 'sag'));
                row.appendChild(trayBtn(t('ui_tray_undo'), 'undo'));
                if (st.strands > 1 || st.mode !== 'points') row.appendChild(trayBtn(t('ui_tray_undo_strand'), 'undoStrand'));
                const rs = trayBtn(t('ui_tray_remove_strand'), 'removeStrand', null, 'danger'); rs.disabled = !st.hover; row.appendChild(rs);
                row.appendChild(trayBtn(t('ui_tray_finish'), 'finish', null, 'primary'));
            }
            row.appendChild(trayBtn((isFig && st.count) ? t('ui_tray_done') : t('ui_tray_cancel'), 'cancel', null, (isFig && st.count) ? '' : 'danger'));
        }
        if (mode !== 'pick') {
            const resume = el('button', 'btn small', T('ui_tray_resume'));
            resume.addEventListener('click', () => post('trayResume'));
            row.appendChild(resume);
        }
    }

    // The pick tool's tray: what is under the crosshair, and once it is
    // clicked, what can be done to it.
    function renderPickTray(hint, row, st) {
        const t = k => T(k);
        const tg = st.target;
        hint.textContent = t('ui_tray_hint_pick');
        if (!tg) {
            row.appendChild(el('span', 'stat', t('ui_pick_aim')));
            row.appendChild(trayBtn(t('ui_tray_leave'), 'cancel', null, 'danger'));
            return;
        }
        const who = el('span', 'stat');
        who.innerHTML = `<b>${tg.label}</b> · ${tg.holiday} · ${t('ui_group')} <b>${tg.group}</b> · ${t('ui_by')} ${tg.by} · ${tg.dist} m`;
        row.appendChild(who);
        if (!st.chosen) {
            row.appendChild(el('span', 'stat', tg.editable ? (tg.strands > 1 && st.strand ? `${t('ui_pick_click')} · ${t('ui_pick_strand_hint')}` : t('ui_pick_click')) : t('ui_pick_locked')));
            row.appendChild(trayBtn(t('ui_tray_leave'), 'cancel', null, 'danger'));
            return;
        }
        if (!tg.editable) {
            row.appendChild(el('span', 'stat', t('ui_pick_locked')));
        } else {
            if (tg.strands > 1 && st.strand) row.appendChild(trayBtn(`${t('ui_pick_remove_strand')} (1/${tg.strands})`, 'removeStrand', null, 'danger'));
            row.appendChild(trayBtn(t('ui_remove'), 'remove', null, 'danger'));
            if (tg.launcher) row.appendChild(trayBtn(t('ui_fw_test'), 'test'));
            if (tg.spotlight) row.appendChild(trayBtn(t('ui_spot_aim'), 'aim'));
            row.appendChild(trayBtn((tg.kind === 'lights' && !tg.figure) ? t('ui_pick_edit') : t('ui_move'), 'move', null, 'primary'));
            const grp = el('div', 'group'); grp.appendChild(el('span', 'label', t('ui_pick_group')));
            for (const g of st.groups || []) {
                const b = el('button', 'chip', g);
                b.setAttribute('aria-pressed', g === tg.group);
                if (g !== tg.group) b.addEventListener('click', () => post('tray', { action: 'group', value: g }));
                grp.appendChild(b);
            }
            const gIn = el('input', 'input'); gIn.type = 'text'; gIn.placeholder = t('ui_group_new'); gIn.maxLength = 32; gIn.style.width = '190px';
            const set = el('button', 'btn small', t('ui_pick_set'));
            set.addEventListener('click', () => { if (gIn.value.trim()) post('tray', { action: 'group', value: gIn.value }); });
            gIn.addEventListener('keydown', ev => { if (ev.key === 'Enter' && gIn.value.trim()) post('tray', { action: 'group', value: gIn.value }); });
            grp.appendChild(gIn); grp.appendChild(set);
            row.appendChild(grp);
        }
        row.appendChild(trayBtn(t('ui_tray_resume'), 'resume'));
        row.appendChild(trayBtn(t('ui_tray_leave'), 'cancel', null, 'danger'));
    }

    // ------------------------------------------------------------------
    // Tips card and music
    // ------------------------------------------------------------------
    function showTips(data) {
        if (!$('panel').classList.contains('hidden') && S.tab === 'tips') {
            S.tipsInline = { holiday: S.holiday, items: data.items || [] };
            const ol = $('tips-inline'); if (ol) { ol.innerHTML = ''; for (const t of data.items || []) ol.appendChild(el('li', '', t)); }
            return;
        }
        $('tips-title').textContent = data.title || 'Decorating tips';
        const c = data.accent || [255, 255, 255];
        $('tips').style.borderLeftColor = rgb(c);
        $('tips-dot').style.background = rgb(c);
        $('tips-dot').style.color = rgb(c);
        const list = $('tips-list'); list.innerHTML = '';
        for (const t of data.items || []) list.appendChild(el('li', '', t));
        $('tips').classList.remove('hidden');
    }

    const player = $('player');
    let current = null;
    function clamp(v) { v = Number(v); return isFinite(v) ? Math.max(0, Math.min(1, v)) : 0.5; }
    // Anything that stops a track from playing is reported back to Lua,
    // where it reaches F8 and the player: a silent failure here looks
    // exactly like "the show never started".
    function audioError(what, file) { post('audioError', { error: String(what), file: file || '' }); }
    player.addEventListener('error', () => {
        const e = player.error;
        audioError(`media error ${e ? e.code : '?'}${e && e.message ? ' ' + e.message : ''}`, current);
    });
    function play(file, seek, volume) {
        if (!file) return;
        const src = '../audio/' + file;
        if (current !== src) { current = src; player.src = src; player.load(); }
        player.volume = clamp(volume);
        const start = () => {
            try { if (seek > 0 && seek < (player.duration || 1e9)) player.currentTime = seek; } catch (e) {}
            const p = player.play();
            if (p && p.catch) p.catch(err => audioError((err && err.name ? err.name + ': ' : '') + (err && err.message ? err.message : 'play() refused'), file));
        };
        if (player.readyState >= 1) start(); else player.addEventListener('loadedmetadata', start, { once: true });
    }
    function stop() { try { player.pause(); } catch (e) {} current = null; player.removeAttribute('src'); player.load(); }

    // ------------------------------------------------------------------
    // Fireworks sounds. Lua works out how loud, which side and how late
    // (sound travels 343 m/s: a far boom arrives after its flash); this
    // plays it through WebAudio with a low-pass for distance. Without
    // WebAudio, a pool of <audio> elements plays it flat.
    // ------------------------------------------------------------------
    const SFX = {};
    let ctx = null, sfxPool = [], voices = 0;
    function audioCtx() {
        if (ctx) return ctx;
        const AC = window.AudioContext || window.webkitAudioContext;
        if (!AC) return null;
        try { ctx = new AC(); } catch (e) { ctx = null; }
        return ctx;
    }
    function sfxBuffer(name) {
        const c = audioCtx();
        if (!c) return null;
        if (SFX[name]) return SFX[name];
        SFX[name] = fetch(`../audio/sfx/${name}.ogg`).then(r => r.arrayBuffer()).then(b => c.decodeAudioData(b)).catch(() => null);
        return SFX[name];
    }
    function playSfx(d) {
        const c = audioCtx();
        if (c && c.state === 'suspended') c.resume().catch(() => {});
        if (c && c.state !== 'closed') {
            if (voices >= 24) return;
            const p = sfxBuffer(d.name);
            if (!p) return;
            p.then(buf => {
                if (!buf) return;
                voices++;
                const src = c.createBufferSource(); src.buffer = buf;
                src.playbackRate.value = 0.94 + Math.random() * 0.12;
                const lp = c.createBiquadFilter(); lp.type = 'lowpass'; lp.frequency.value = Math.max(400, Math.min(20000, d.cutoff || 16000));
                const g = c.createGain(); g.gain.value = Math.max(0, Math.min(1.5, d.gain || 0));
                let node = src.connect(lp).connect(g);
                if (c.createStereoPanner) { const pn = c.createStereoPanner(); pn.pan.value = Math.max(-1, Math.min(1, d.pan || 0)); node = node.connect(pn); }
                node.connect(c.destination);
                src.onended = () => { voices--; };
                src.start(c.currentTime + Math.max(0, d.delay || 0));
            });
            return;
        }
        // The flat fallback.
        setTimeout(() => {
            let a = sfxPool.find(x => x.paused || x.ended);
            if (!a) { if (sfxPool.length >= 12) return; a = new Audio(); sfxPool.push(a); }
            a.src = `../audio/sfx/${d.name}.ogg`; a.volume = Math.max(0, Math.min(1, d.gain || 0));
            a.play().catch(() => {});
        }, Math.max(0, (d.delay || 0) * 1000));
    }

    // The countdown: the clock runs here, from the moment Lua said how
    // long was left; Lua says whether this player is near enough to see it.
    const CD = {};
    let cdTimer = null;
    function cdTick() {
        const box = $('countdown');
        const now = performance.now();
        let shown = null;
        for (const [g, c] of Object.entries(CD)) {
            const left = c.endsAt - now;
            if (left < -7000) { delete CD[g]; continue; }
            if (c.near && (!shown || c.endsAt < shown.endsAt)) shown = c;
        }
        if (!shown) { box.classList.add('hidden'); if (!Object.keys(CD).length) { clearInterval(cdTimer); cdTimer = null; } return; }
        box.classList.remove('hidden');
        const left = shown.endsAt - now;
        const secs = Math.ceil(left / 1000);
        if (left <= 0) {
            box.className = 'countdown banner';
            $('cd-num').textContent = shown.banner;
            if (!shown.chimed) { shown.chimed = true; playSfx({ name: 'chime', gain: 0.8, pan: 0, delay: 0, cutoff: 18000 }); }
        } else if (secs <= 10) {
            box.className = 'countdown big';
            $('cd-num').textContent = String(secs);
            if (shown.lastTick !== secs) { shown.lastTick = secs; playSfx({ name: 'tick', gain: secs <= 3 ? 0.9 : 0.6, pan: 0, delay: 0, cutoff: 18000 }); }
        } else {
            box.className = 'countdown small';
            const h = Math.floor(secs / 3600), m = Math.floor(secs % 3600 / 60), s2 = secs % 60;
            $('cd-num').textContent = (h ? `${h}:${String(m).padStart(2, '0')}` : `${m}`) + `:${String(s2).padStart(2, '0')}`;
        }
        $('cd-label').textContent = shown.label;
    }
    function countdown(d) {
        if (d.cancel) {
            if (d.group) delete CD[d.group]; else for (const k of Object.keys(CD)) delete CD[k];
            cdTick();
            return;
        }
        CD[d.group] = { endsAt: performance.now() + (d.remaining || 0), banner: d.banner, label: d.label, near: !!(CD[d.group] && CD[d.group].near) || !!d.near };
        if (!cdTimer) cdTimer = setInterval(cdTick, 100);
        cdTick();
    }

    // ------------------------------------------------------------------
    // Messages from Lua
    // ------------------------------------------------------------------
    window.addEventListener('message', ev => {
        const d = ev.data || {};
        switch (d.action) {
            case 'open': openPanel(d.data); break;
            case 'close': closePanel(); break;
            case 'who': if (S.data) { S.data.who = d.who; S.data.nearby = d.nearby || S.data.nearby; render(); } break;
            case 'nearby':
                if (S.data) {
                    S.data.nearby = d.nearby;
                    if (d.groups) S.data.groups = d.groups;
                    const l = $('nearby'); if (l) renderNearby(l, d.nearby);
                    const g = $('groups'); if (g && d.groups) renderGroups(g, d.groups);
                    const lg = $('live-groups'); if (lg && d.groups) renderLiveGroups(lg, d.groups);
                }
                break;
            case 'floats':
                if (S.data) {
                    S.data.floats = d.floats;
                    if (d.settings && d.settings.group) S.data.settings.group = d.settings.group;
                    // Not while the decorator is typing a name: a redraw would eat it.
                    const typing = document.activeElement && document.activeElement.tagName === 'INPUT';
                    if (!typing && !$('panel').classList.contains('hidden')) render();
                }
                break;
            case 'presets':
                if (S.data) {
                    S.data.presets = d.presets || [];
                    if (d.groups) S.data.groups = d.groups;
                    const pl = $('presets'); if (pl) renderPresets(pl, S.data.presets);
                    const lg = $('live-groups'); if (lg && d.groups) renderLiveGroups(lg, d.groups);
                }
                break;
            case 'nowPlaying':
                if (S.data) {
                    S.data.nowPlaying = d.nowPlaying;
                    if (d.group) S.data.settings.group = d.group;
                    if (d.fwCounts) { S.data.fireworks.here = d.fwHere; S.data.fireworks.counts = d.fwCounts; }
                    if (S.tab === 'shows' || S.tab === 'fireworks') render();
                }
                break;
            case 'extras': if (S.data && d.extras) { S.data.extras = d.extras; if (d.group) S.data.settings.group = d.group; if (S.tab === 'extras') render(); } break;
            case 'settings': S.settings = d.data; if (S.tab === 'settings') render(); break;
            case 'viewTime': if (S.data) { S.data.settings.viewTime = d.viewTime || null; } break;
            case 'tray':
                if (d.show) { $('tray').classList.remove('hidden'); renderTray(d.mode, d.state || {}); }
                else { $('tray').classList.add('hidden'); $('tray').classList.remove('focused'); }
                break;
            case 'trayFocus': $('tray').classList.toggle('focused', !!d.focused); break;
            case 'play': play(d.file, d.seek, d.volume); break;
            case 'volume': player.volume = clamp(d.volume); break;
            case 'stop': stop(); break;
            case 'tips': showTips(d); break;
            case 'hideTips': $('tips').classList.add('hidden'); break;
            case 'thumb': cropThumb(d.model, d.data); break;
            case 'sfx': playSfx(d); break;
            case 'countdown': countdown(d); break;
            case 'countdownNear': if (CD[d.group]) { CD[d.group].near = !!d.near; cdTick(); } break;
        }
    });

    // /holiday thumbs: the Lua side sends a full screenshot with the prop
    // centered; crop a square around the center and shrink it to 256 px.
    function cropThumb(model, dataUrl) {
        const img = new Image();
        img.onload = () => {
            try {
                const side = Math.min(img.width, img.height) * 0.78;
                const sx = (img.width - side) / 2, sy = (img.height - side) / 2;
                const c = document.createElement('canvas');
                c.width = 256; c.height = 256;
                c.getContext('2d').drawImage(img, sx, sy, side, side, 0, 0, 256, 256);
                post('thumbReady', { model, data: c.toDataURL('image/jpeg', 0.86) });
            } catch (e) { post('thumbReady', { model, data: null }); }
        };
        img.onerror = () => post('thumbReady', { model, data: null });
        img.src = dataUrl;
    }

    $('p-close').addEventListener('click', () => post('close'));
    document.addEventListener('keydown', ev => {
        if (ev.key === 'Escape') {
            if (!$('tray').classList.contains('hidden') && $('tray').classList.contains('focused')) post('trayResume');
            else if (!$('panel').classList.contains('hidden')) post('close');
        }
        if (ev.key === 'Tab' && $('tray').classList.contains('focused')) { ev.preventDefault(); post('trayResume'); }
    });
})();
