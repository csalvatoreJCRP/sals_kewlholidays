-- Builds the active language table after every locale file has registered itself.
-- Loaded last in fxmanifest shared_scripts, so Locales[...] and Config are ready.
Lang = Lang or {}
Lang.phrases = Locales[Config.Locale] or Locales['en'] or {}

-- Lang:t('key', { name = 'Bob' })  ->  substitutes %{name} placeholders
function Lang:t(key, subs)
    local str = self.phrases[key] or (Locales['en'] and Locales['en'][key]) or key
    if subs then
        str = str:gsub('%%{(.-)}', function(k)
            local v = subs[k]
            if v == nil then return '' end
            return tostring(v)
        end)
    end
    return str
end

--- Does the active locale (or English) have this key at all? Used for the
--- tip lists, which are numbered until one is missing.
function Lang:has(key)
    return self.phrases[key] ~= nil or (Locales['en'] and Locales['en'][key] ~= nil)
end
