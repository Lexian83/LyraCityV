-- Hilfsfunktion: Modell laden
local function loadModel(hash)
    if not IsModelInCdimage(hash) or not IsModelValid(hash) then return false end
    RequestModel(hash)
    local timeout = GetGameTimer() + 5000
    while not HasModelLoaded(hash) and GetGameTimer() < timeout do
        Wait(0)
    end
    return HasModelLoaded(hash)
end

-- Sanfter Spawn nach Auswahl
RegisterNetEvent('LCV:spawn', function(data)
    -- normalize critical fields
data = data or {}
data.past = tonumber(data.past) or 0
data.residence_permit = tonumber(data.residence_permit) or 0
data.clothes = data.clothes or {}
data.appearances = data.appearances or {}

   -- print('[LCV][charui] spawn event received', data and data.id or 'nil')
    TriggerEvent('LCV:characterSelectedFinish')

    -- Fade-Out
    if not IsScreenFadedOut then
        -- safety: in manchen Builds ist die native nicht gebunden
        DoScreenFadeOut(500)
        while not IsScreenFadedOut() do Wait(0) end
    else
        if not IsScreenFadedOut() then
            DoScreenFadeOut(500)
            while not IsScreenFadedOut() do Wait(0) end
        end
    end

    local ped = PlayerPedId()


    -- Freeze & Invincible während Setup
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)

    -- 1) Free-mode Modell anhand Gender wählen (1 = m, 0 = f)
    local modelName = (tonumber(data.gender) == 1) and 'mp_m_freemode_01' or 'mp_f_freemode_01'
    local modelHash = joaat(modelName)
    -- 2) Modell wechseln (falls nötig) VOR dem Teleport, während Fade-Out

        if loadModel(modelHash) then
            ClearPedTasksImmediately(ped)
            RemoveAllPedWeapons(ped, true)
            SetEntityVisible(ped, false, false)

            SetPlayerModel(PlayerId(), modelHash)
            ped = PlayerPedId() -- nach SetPlayerModel neu referenzieren

            -- Standard-Variationen, keine Props
            SetPedDefaultComponentVariation(ped)
            ClearAllPedProps(ped)


            -- FACIAL etc..    
            local tempData = data.appearances
-- Reset
    ClearPedBloodDamage(ped)
    ClearPedDecorations(ped)
    -- Head blend reset auf definierte Basis, dann setzen
    SetPedHeadBlendData(ped, 0, 0, 0, 0, 0, 0, 0.0, 0.0, 0, false)

    -- Head blend
    SetPedHeadBlendData(
        ped,
        tempData.faceFather or 0,
        tempData.faceMother or 0,
        0,
        tempData.skinFather or 0,
        tempData.skinMother or 0,
        0,
        tonumber(tempData.faceMix or 0.0) or 0.0,
        tonumber(tempData.skinMix or 0.0) or 0.0,
        0,
        false
    )

    -- Facial features
    if tempData.structure then
        for i = 1, #tempData.structure do
            SetPedFaceFeature(ped, i - 1, tempData.structure[i] or 0.0)
        end
    end

    -- Overlays (ohne Farben)
    if tempData.opacityOverlays then
        for i = 1, #tempData.opacityOverlays do
            local ov = tempData.opacityOverlays[i]
            if ov then
                SetPedHeadOverlay(ped, ov.id or 0, ov.value or 0, tonumber(ov.opacity or 1.0) or 1.0)
            end
        end
    end

    -- Hair
    if tempData.hairOverlay then
        local collection = GetHashKey(tempData.hairOverlay.collection or '')
        local overlay = GetHashKey(tempData.hairOverlay.overlay or '')
        AddPedDecorationFromHashes(ped, collection, overlay)
    end
    SetPedComponentVariation(ped, 2, tempData.hair or 0, 0, 0)
    SetPedHairColor(ped, tempData.hairColor1 or 0, tempData.hairColor2 or 0)

    -- Facial Hair
    SetPedHeadOverlay(ped, 1, tempData.facialHair or 0, tempData.facialHairOpacity or 0.0)
    SetPedHeadOverlayColor(ped, 1, 1, tempData.facialHairColor1 or 0, tempData.facialHairColor1 or 0)

    -- Eyebrows
    SetPedHeadOverlay(ped, 2, tempData.eyebrows or 0, 1.0)
    SetPedHeadOverlayColor(ped, 2, 1, tempData.eyebrowsColor1 or 0, tempData.eyebrowsColor1 or 0)

    -- Color Overlays (Makeup etc.)
    if tempData.colorOverlays then
        for i = 1, #tempData.colorOverlays do
            local ov = tempData.colorOverlays[i]
            if ov then
                local c2 = ov.color2 or ov.color1 or 0
                SetPedHeadOverlay(ped, ov.id or 0, ov.value or 0, tonumber(ov.opacity or 1.0) or 1.0)
                SetPedHeadOverlayColor(ped, ov.id or 0, 1, ov.color1 or 0, c2 or 0)
            end
        end
    end

    -- Eyes
    if tempData.eyes then
        SetPedEyeColor(ped, tempData.eyes)
    end
-- print(('[SPAWN]Torso ID: %s | tonumber: %s | UNDERSHIRT: %s'):format(data.clothes.torso, tonumber(data.clothes.torso), data.clothes.undershirt))

            -- Clothes

                SetPedComponentVariation(ped, 11, data.clothes.top, data.clothes.topcolor, 0) -- Jacke/Top
                SetPedComponentVariation(ped, 3,  data.clothes.torso, 0, 0) -- Torso
                SetPedComponentVariation(ped, 4,  data.clothes.pants, data.clothes.pantsColor, 0) -- Hose
                SetPedComponentVariation(ped, 6,  data.clothes.shoes, data.clothes.shoesColor, 0) -- Schuhe
                SetPedComponentVariation(ped, 8,  data.clothes.undershirt, data.clothes.undershirtColor, 0) -- Unterhemd
   

            ResetPedMovementClipset(ped, 0.0)
            ResetPedWeaponMovementClipset(ped)
            ResetPedStrafeClipset(ped)
            SetPedArmour(ped, 0)
            SetPedCanLosePropsOnDamage(ped, false, 0)
            SetModelAsNoLongerNeeded(modelHash)
            SetEntityVisible(ped, true, false)
        else
           -- print(('[LCV][charui] WARN: Model %s konnte nicht geladen werden, verwende aktuelles.'):format(modelName))
        end
  

    -- past: 0 = Zivi | 1 = Crime
    -- residence_permit:  0 = kein Visum | 1 = Vorläufig | 2 = Bürger

local x = 0
local y = 0
local z = 0
local heading = 0

-- print(('[LCV][charui] PAST: %s | Residence Permit: %s'):format(data.past, data.residence_permit))
if (data.residence_permit >= 1 ) then -- Normaler Spawn
    -- 3) Koordinaten vorbereiten (+ Fallback)
    x = tonumber(data and data.pos and data.pos.x) or 0.0
    y = tonumber(data and data.pos and data.pos.y) or 0.0
    z = tonumber(data and data.pos and data.pos.z) or 0.0
    heading = tonumber(data and data.heading or 0.0) or 0.0
elseif(data.residence_permit == 0 and data.past == 0) then -- Zivil Spawn Airport
x, y, z, heading = -1111.24, -2843.37, 14.89, 267.78
elseif(data.residence_permit == 0 and data.past == 1) then -- Crime Spawn Jail
x, y, z, heading = 1690.70, 2606.72, 45.56, 281.05
end


    if ShutdownLoadingScreen then ShutdownLoadingScreen() end
    if ShutdownLoadingScreenNui then ShutdownLoadingScreenNui() end

    -- 4) Teleport + Collision
    SetEntityCoordsNoOffset(ped, x, y, z, false, false, false)
    SetEntityHeading(ped, heading)
    -- print(('[LCV][PLAYERSPAWN] X: %s | Y: %s | Z: %s | Heading: %s.'):format(x,y,z,heading))
    RequestCollisionAtCoord(x, y, z)
    local timeout = GetGameTimer() + 5000
    while not HasCollisionLoadedAroundEntity(ped) and GetGameTimer() < timeout do
        Wait(0)
    end

-- 5) Health setzen (relativ zum echten Max-Health)
local ped = PlayerPedId()
local maxH = GetEntityMaxHealth(ped)
if maxH < 200 then SetPedMaxHealth(ped, 200); maxH = 200 end

-- Falls du gespeicherte HP aus 'data.health' nutzt, nimm sie – sonst volle HP
local saved = tonumber(data and data.health)
local hp = saved and math.max(1, math.min(saved, maxH)) or maxH

SetEntityHealth(ped, hp)

    -- 6) Unfreeze & Fade-In
    FreezeEntityPosition(ped, false)
    SetEntityInvincible(ped, false)
    DoScreenFadeIn(600)
end)
