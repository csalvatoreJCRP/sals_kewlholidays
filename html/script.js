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
        show: { track: null, show: 'classic' },
        settings: null, tipsInline: null,
    };
    const T = key => (S.data && S.data.strings && S.data.strings[key]) || key;

    // ------------------------------------------------------------------
    // Panel
    // ------------------------------------------------------------------
    const TABS = ['props', 'lights', 'figures', 'inflatables', 'shows', 'edit', 'places', 'tips', 'settings'];

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
        if (!d.who.decorator && ['props', 'lights', 'figures', 'inflatables'].includes(S.tab)) {
            body.appendChild(el('div', 'note', T('ui_not_decorator')));
        }
        if (['props', 'lights', 'figures', 'inflatables'].includes(S.tab) && !h.inSeason) {
            body.appendChild(el('div', 'note', T('ui_off_season_note').replace('%{holiday}', h.label).replace('%{mode}', d.season.mode)));
        }
        ({ props: renderProps, lights: renderLights, figures: renderFigures, inflatables: renderInflatables, shows: renderShows, edit: renderEdit, places: renderPlaces, tips: renderTips, settings: renderSettings })[S.tab](body);

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
    // One inflatable or wreath: thumbnail, name, what it is, default size, Place.
    // An inflatable that ships as a model (s.model) places that prop and
    // shows its photo; the rest are drawn from their parts.
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

    // ---- Shows ----
    function renderShows(body) {
        const d = S.data;
        groupPicker(body, { compact: true });
        if (d.nowPlaying) {
            const np = el('div', 'item active');
            const main = el('div', 'main'); main.appendChild(el('div', 't', `${T('ui_now_playing')}: ${trackLabel(d.nowPlaying.track)}`)); main.appendChild(el('div', 'd', d.nowPlaying.show));
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
        const list = el('div', 'list');
        const tracks = d.tracks.filter(t => S.holiday === '*' || t.holiday === S.holiday || !t.holiday).sort((a, b) => (b.inSeason - a.inSeason) || a.label.localeCompare(b.label));
        for (const t of tracks) {
            const it = el('div', 'item');
            const main = el('div', 'main');
            main.appendChild(el('div', 't', t.label));
            const hl = (d.holidays.find(x => x.name === t.holiday) || {}).label || '';
            main.appendChild(el('div', 'd', `${hl}${t.holiday ? ' · ' + (t.inSeason ? T('ui_in_season') : T('ui_off_season')) : ''} · ${t.bpm} bpm · ${t.duration}s`));
            it.appendChild(main);
            const b = el('button', 'btn small primary', T('ui_play'));
            b.addEventListener('click', () => post('startShow', { track: t.name, show: S.show.show }));
            it.appendChild(b);
            list.appendChild(it);
        }
        labeled(body, T('ui_track')).appendChild(list);
    }

    // ---- Edit ----
    function renderEdit(body) {
        const d = S.data;
        // Point and click first: aim at the thing itself.
        const pick = el('button', 'btn primary', T('ui_pick'));
        pick.disabled = !d.who.decorator && !d.who.admin;
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
            main.appendChild(el('div', 'd', `${g.props} ${T('ui_props')} · ${g.lights} ${T('ui_lights')} · ${g.dist} m${g.running ? ` · ${T('ui_group_show_on')}` : ''}`));
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
            const editable = can.admin || (can.decorator && n.mine);
            if (editable && groups.length > 1) {
                // Move it to another group without leaving the list.
                const sel = el('select', 'input small'); sel.title = T('ui_change_group');
                for (const g of groups) { const o = el('option', '', g); o.value = g; o.selected = g === n.group; sel.appendChild(o); }
                sel.addEventListener('change', () => post('regroup', { id: n.id, group: sel.value }));
                it.appendChild(sel);
            }
            const mv = el('button', 'btn small', T('ui_move')); mv.disabled = !editable; mv.addEventListener('click', () => post('move', { id: n.id }));
            const rm = el('button', 'btn small danger', T('ui_remove')); rm.disabled = !editable; rm.addEventListener('click', () => post('remove', { id: n.id }));
            it.appendChild(mv); it.appendChild(rm);
            list.appendChild(it);
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

        // Save the current location as a layout.
        const sv = section(body, T('ui_place_save'), T('ui_place_save_help'));
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
    function renderLiveGroups(list, groups) {
        list.innerHTML = '';
        const d = S.data;
        if (!groups || !groups.length) { list.appendChild(el('div', 'note', T('ui_group_none'))); return; }
        for (const g of groups) {
            const it = el('div', 'item preset' + (g.name === d.settings.group ? ' active' : ''));
            const main = el('div', 'main');
            main.appendChild(el('div', 't', g.name));
            main.appendChild(el('div', 'd', `${g.props} ${T('ui_props')} · ${g.lights} ${T('ui_lights')} · ${g.dist} m${g.running ? ` · ${T('ui_group_show_on')}` : ''}`));
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
                del.addEventListener('click', () => { if (del.dataset.armed) post('presetDelete', { name: p.name }); else { del.dataset.armed = '1'; del.textContent = T('ui_place_delete') + '?'; } });
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
        mine.appendChild(kv);
        mine.appendChild(el('div', 'note', T('ui_view_time_help')));
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
                    tbl.innerHTML = `<tr><th>${T('ui_beats')}</th><th>1</th><th>2</th><th>3</th><th>4</th><th></th></tr>`;
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
            row.appendChild(trayBtn((st.repeat ? '✓ ' : '') + t('ui_repeat'), 'repeat'));
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
                row.appendChild(trayBtn((st.pinned ? '✓ ' : '') + t('ui_pinned'), 'pin'));
                row.appendChild(trayBtn((st.align ? '✓ ' : '') + t('ui_align'), 'align'));
                row.appendChild(trayBtn((st.repeat ? '✓ ' : '') + t('ui_repeat'), 'repeat'));
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
        who.innerHTML = `<b>${tg.label}</b>${tg.inflatable ? ` (${tg.down ? t('ui_down') : t('ui_up')})` : ''} · ${tg.holiday} · ${t('ui_group')} <b>${tg.group}</b> · ${t('ui_by')} ${tg.by} · ${tg.dist} m`;
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
            if (tg.inflatable) row.appendChild(trayBtn(tg.down ? t('ui_inflate') : t('ui_deflate'), 'toggle', null, tg.down ? 'primary' : ''));
            row.appendChild(trayBtn(t('ui_remove'), 'remove', null, 'danger'));
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
            case 'nowPlaying': if (S.data) { S.data.nowPlaying = d.nowPlaying; if (d.group) S.data.settings.group = d.group; if (S.tab === 'shows') render(); } break;
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
