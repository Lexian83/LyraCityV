-- resources/playerspawn/c-playerspawn.lua
-- LyraCityV - Einheitlicher Spawn, kompatibel mit PlayerManager + Charakter-Editor

local function log(msg)
    print(('[LCV:Spawn] %s'):format(tostring(msg)))
end

local function loadModel(hashOrName)
    local hash = type(hashOrName) == "number" and hashOrName or GetHashKey(hashOrName)
    if not IsModelInCdimage(hash) or not IsModelValid(hash) then
        log(("Ungültiges Modell: %s"):format(tostring(hashOrName)))
        return nil
    end

    RequestModel(hash)
    local timeout = GetGameTimer() + 5000
    while not HasModelLoaded(hash) do
        Wait(0)
        if GetGameTimer() > timeout then
            log("Model-Load Timeout")
            return nil
        end
    end

    return hash
end

-- ======= Appearance Helper =======

local function applyHeadBlend(ped, a)
    if not a then return end

    -- Editor-Varianten unterstützen
    local faceFather = a.faceFather or a.faceF or 0
    local faceMother = a.faceMother or a.faceM or 0
    local skinFather = a.skinFather or faceFather
    local skinMother = a.skinMother or faceMother

    local faceMix = a.faceMix or 0.5
    local skinMix = a.skinMix or faceMix

    SetPedHeadBlendData(
        ped,
        faceFather,
        faceMother,
        0,
        skinFather,
        skinMother,
        0,
        faceMix,
        skinMix,
        0.0,
        false
    )
end

local function applyFaceFeatures(ped, a)
    if not a or not a.structure then return end
    for i = 1, #a.structure do
        local val = a.structure[i]
        if val ~= nil then
            SetPedFaceFeature(ped, i - 1, val + 0.0)
        end
    end
end

local function applyOverlays(ped, a)
    if not a then return end

    -- Augenfarbe
    if a.eyes ~= nil then
        SetPedEyeColor(ped, a.eyes)
    end

    -- Augenbrauen
    if a.eyebrows ~= nil then
        local opacity = a.eyebrowsOpacity or 1.0
        local color1  = a.eyebrowsColor1 or 0
        SetPedHeadOverlay(ped, 2, a.eyebrows, opacity)
        SetPedHeadOverlayColor(ped, 2, 1, color1, color1)
    end

    -- Bart
    if a.facialHair ~= nil then
        local opacity = a.facialHairOpacity or 1.0
        local color1  = a.facialHairColor1 or 0
        SetPedHeadOverlay(ped, 1, a.facialHair, opacity)
        SetPedHeadOverlayColor(ped, 1, 1, color1, color1)
    end

    -- Generische Overlays (mit Opacity)
    if a.opacityOverlays then
        for _, o in ipairs(a.opacityOverlays) do
            if o.id and o.value and o.opacity then
                SetPedHeadOverlay(ped, o.id, o.value, o.opacity)
            end
        end
    end

    -- Farbige Overlays
    if a.colorOverlays then
        for _, o in ipairs(a.colorOverlays) do
            if o.id and o.color1 then
                SetPedHeadOverlayColor(ped, o.id, 1, o.color1 or 0, o.color2 or (o.color1 or 0))
            end
        end
    end
end

local function applyHair(ped, a)
    if not a then return end

    -- Frisur
    local hair = a.hair or a.hairStyle
    if hair ~= nil then
        SetPedComponentVariation(ped, 2, hair, 0, 0)
    end

    -- Haarfarben
    if a.hairColor1 or a.hairColor2 then
        SetPedHairColor(ped, a.hairColor1 or 0, a.hairColor2 or (a.hairColor1 or 0))
    end

    -- Hair-Overlay (Deko)
    if a.hairOverlay and a.hairOverlay.overlay and a.hairOverlay.collection then
        local col = GetHashKey(a.hairOverlay.collection)
        local ov  = GetHashKey(a.hairOverlay.overlay)
        AddPedDecorationFromHashes(ped, col, ov)
    end
end

-- ======= Clothes Helper =======

local function applyClothes(ped, c)
    c = c or {}

    local function comp(idx, drawable, texture)
        if drawable ~= nil then
            SetPedComponentVariation(ped, idx, drawable, texture or 0, 0)
        end
    end

    local function prop(idx, drawable, texture)
        if drawable ~= nil then
            SetPedPropIndex(ped, idx, drawable, texture or 0, true)
        end
    end

    -- Arme
    if c.torso ~= nil then
        comp(3, c.torso, 0)
    end

    -- Undershirt
    if c.undershirt ~= nil then
        comp(8, c.undershirt, c.undershirtColor or 0)
    end

    -- Oberteil
    if c.top ~= nil then
        comp(11, c.top, c.topcolor or 0)
    end

    -- Hosen
    if c.pants ~= nil then
        comp(4, c.pants, c.pantsColor or 0)
    end

    -- Schuhe
    if c.shoes ~= nil then
        comp(6, c.shoes, c.shoesColor or 0)
    end

    -- Brille
    if c.glass ~= nil then
        prop(1, c.glass, c.glassColor or 0)
    end

    -- Watch
    if c.watch ~= nil then
        prop(6, c.watch, c.watchColor or 0)
    end
end

-- ======= Core Spawn =======

local function spawnPlayer(data)
    if not data then
        log("Kein Spawn-Data erhalten.")
        return
    end

    -- Kompatible Felder
    local appearance = data.appearances or data.appearance or {}
    local clothes    = data.clothes or {}

    -- 🔥 Geschlechtslogik:
    -- Editor schreibt zuverlässig appearance.sex:
    --  sex = 0 → weiblich
    --  sex = 1 → männlich
    local sex = appearance.sex
    local gender = data.gender

    local isMale

    if sex ~= nil then
        isMale = (tonumber(sex) == 1)
    elseif gender ~= nil then
        -- Fallback, falls sex nicht vorhanden:
        -- 0 = weiblich, 1 = männlich (deine DB)
        isMale = (tonumber(gender) == 1)
    else
        -- ganz hartes Fallback
        isMale = false
    end

    local modelName = isMale and 'mp_m_freemode_01' or 'mp_f_freemode_01'

    local pos     = data.pos or { x = 0.0, y = 0.0, z = 0.0 }
    local heading = data.heading or 0.0
    local dim     = data.dimension or 0

    log(("Spawn %s: isMale=%s | gender=%s | sex=%s")
        :format(tostring(data.name or "?"), tostring(isMale), tostring(gender), tostring(sex)))

    local modelHash = loadModel(modelName)
    if not modelHash then
        log("Konnte gewünschtes Modell nicht laden, versuche mp_m_freemode_01")
        modelHash = loadModel('mp_m_freemode_01')
        if not modelHash then
            log("Fatal: Kein gültiges Model ladbar.")
            return
        end
    end

    local player = PlayerId()
    local ped    = PlayerPedId()

    -- Dimension übernehmen (Server ist führend, hier nur optisch mitziehen)
    if dim and dim ~= 0 then
        SetPlayerRoutingBucket(player, dim)
    end

    -- Vorbereitung
    if not IsScreenFadedOut() then
        DoScreenFadeOut(500)
        while not IsScreenFadedOut() do Wait(0) end
    end

    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    ClearPedTasksImmediately(ped)

    -- Model setzen
    SetPlayerModel(player, modelHash)
    ped = PlayerPedId()
    SetPedDefaultComponentVariation(ped)
    ClearAllPedProps(ped)
    SetModelAsNoLongerNeeded(modelHash)

    -- Position & Heading
    SetEntityCoordsNoOffset(ped, pos.x + 0.0, pos.y + 0.0, pos.z + 0.0, false, false, false)
    SetEntityHeading(ped, heading + 0.0)

    -- Clean
    ClearPedBloodDamage(ped)
    ClearPedDecorations(ped)

    -- Appearance
    applyHeadBlend(ped, appearance)
    applyFaceFeatures(ped, appearance)
    applyOverlays(ped, appearance)
    applyHair(ped, appearance)

    -- Clothes
    applyClothes(ped, clothes)

    -- Health usw.
    SetEntityHealth(ped, data.health or 200)
    SetPedArmour(ped, 0)
    FreezeEntityPosition(ped, false)
    SetEntityInvincible(ped, false)

    DoScreenFadeIn(500)

    log(("Spawn fertig: %s @ (%.2f, %.2f, %.2f)")
        :format(tostring(data.name or "?"), pos.x or 0.0, pos.y or 0.0, pos.z or 0.0))
end

-- ======= Event Binding =======

RegisterNetEvent('LCV:spawn', function(data)
    spawnPlayer(data)
end)
