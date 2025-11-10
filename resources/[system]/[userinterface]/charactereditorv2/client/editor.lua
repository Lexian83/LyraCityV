-- client/editor_client.lua
-- Port von alt:V editor.js zu FiveM
-- Abhängigkeit: camera_client.lua (createPedEditCamera, destroyPedEditCamera, setFov, setZPos)

local oldData = {}
local prevData = {}
local tempData = {}
local readyTick = nil
local editorOpen = false

local tempClothes = {}

local accountid = 0

-- ========= Utils =========

local function ensureAtCoordAndCollision(x, y, z)
    local ped = PlayerPedId()
    -- Entity sofort versetzen (ohne Physik-Offset)
    SetEntityCoordsNoOffset(ped, x, y, z, false, false, false)
    -- Heading bleibt ggf. separat
    RequestCollisionAtCoord(x, y, z)
    local timeout = GetGameTimer() + 5000
    while not HasCollisionLoadedAroundEntity(ped) do
        if GetGameTimer() > timeout then break end
        Wait(0)
    end
end

local function teleportTo(x, y, z, heading)
    local ped = PlayerPedId()
    SetEntityCoordsNoOffset(ped, x, y, z, false, false, false)
    if heading then
        SetEntityHeading(ped, heading)
    end
end

local function showCursor(state)
    -- NUI-Fokus ersetzt alt.showCursor
    SetNuiFocus(state, state)
    SetNuiFocusKeepInput(state and true or false)  -- erlaubt Spiel-Input trotz UI-Fokus
    if state then SetMouseCursorActiveThisFrame() end
end

local function loadModelByName(name)
    local hash = joaat(name)
    if not IsModelInCdimage(hash) or not IsModelValid(hash) then
       -- print(('[char] Ungültiges Modell: %s'):format(name))
        return nil
    end
    RequestModel(hash)
    local timeout = GetGameTimer() + 8000
    while not HasModelLoaded(hash) do
        if GetGameTimer() > timeout then
           -- print(('[char] Model-Load Timeout: %s'):format(name))
            return nil
        end
        Wait(0)
    end
    return hash
end

-- Sicheres Model-Apply mit Sichtbarkeits-/Default-Resets
local function applyModelSafe(modelName)
    local hash = loadModelByName(modelName)
    if not hash then return false end

    -- sicht-/netzwerk-relevante Resets vorher
    local ped = PlayerPedId()
    ResetEntityAlpha(ped)
    SetEntityAlpha(ped, 255, false)
    SetEntityVisible(ped, true, false)
    NetworkSetEntityInvisibleToNetwork(ped, false)

    -- Model setzen
    SetPlayerModel(PlayerId(), hash)
    SetModelAsNoLongerNeeded(hash)

    -- nach SetPlayerModel: neue Ped-Referenz holen
    ped = PlayerPedId()

    -- Default-Komponenten setzen, sonst kann Freemode "leer" sein
    SetPedDefaultComponentVariation(ped)

    -- safer Resets
    ClearPedTasksImmediately(ped)
    ClearAllPedProps(ped)
    RemoveAllPedWeapons(ped, true)

    -- noch einmal Sichtbarkeit sicherstellen
    ResetEntityAlpha(ped)
    SetEntityAlpha(ped, 255, false)
    SetEntityVisible(ped, true, false)
    NetworkSetEntityInvisibleToNetwork(ped, false)

    -- einen Frame warten, bevor weitere Manipulationen kommen
    Wait(0)

    -- Debug
    -- print(('[char] applyModelSafe OK: %s  vis=%s alpha=%d'):format(modelName, tostring(IsEntityVisible(ped)), GetEntityAlpha(ped)))
    return true
end

-- ========= Editor-Funktionen =========

local function openEditor()
    if editorOpen then return end
    editorOpen = true
       exports.inputmanager:LCV_OpenUI('chareditor', { nui = true, keepInput = false })
    showCursor(true)

    -- 1) Position & Collision sauber laden
    local x, y, z, h = -1037.5, -2737.8, 20.2, 90.0
    teleportTo(x, y, z, h)
    ensureAtCoordAndCollision(x, y, z)

    -- 2) Modell robust setzen (Standard: männlicher Freemode; UI kann später wechseln)
    local ok = applyModelSafe('mp_f_freemode_01')
    if not ok then
       -- print('[char] applyModelSafe fehlgeschlagen (mp_f_freemode_01)')
    end

    -- 3) Jetzt erst einfrieren & Kamera starten (Reihenfolge ist wichtig!)
    FreezeEntityPosition(PlayerPedId(), true)

    createPedEditCamera()
    setFov(50.0)
    setZPos(0.6)

    SendNUIMessage({ action = "openEditor" })
end

local function closeEditor()
    if not editorOpen then return end
    editorOpen = false
    exports.inputmanager:LCV_CloseUI('chareditor')
    


    -- UI-Defocus
    showCursor(false)

    -- Ped freigeben
    FreezeEntityPosition(PlayerPedId(), false)

    -- Kamera schließen
    destroyPedEditCamera()

    SendNUIMessage({ action = "closeEditor" })

end

-- ===== Server -> Client Events =====

RegisterNetEvent('character:Edit', function(_oldData,account_id)
    oldData = _oldData or {}
    openEditor()
    accountid = account_id
    -- print('CLIENT:NetEvent:character:Edit - ACOOUNTID:',accountid)
end)

RegisterNetEvent('character:Sync', function(data, clothes)
    -- Daten zwischenpuffern
    tempData = data or {}
    tempClothes = clothes or {}

    -- Einen Frame warten, damit Model/Scene/Kamera sicher vollständig sind
    Wait(0)
    TriggerEvent('character:FinishSync')
    -- print('CLIENT:NetEvent:character:Sync -> Trigger FinishSync')
end)

RegisterNetEvent('character:SetModel', function(modelName)
    local currentModel = GetEntityModel(PlayerPedId())
    local targetHash = joaat(modelName)

    if currentModel == targetHash then
        -- print(('[char] Modell %s bereits aktiv – kein Wechsel nötig.'):format(modelName))
        return
    end

    local ok = applyModelSafe(modelName)
    if ok then
        -- print(('[char] Modell gewechselt auf %s (safe)'):format(modelName))
    end
end)

RegisterNUICallback('saveCharacter', function(data, cb)
    -- print('Name:', data.name)
    -- print('Gender:', data.gender)
    -- print('Haare:', data.appearance.hair)
    -- print('Augen:', data.appearance.eyes)
    -- print('Hautton:', data.appearance.skinTone)

    -- z.B. an Server weitergeben
    TriggerServerEvent('LCV:char:save', data)

    cb({ success = true, message = 'Gespeichert!' })
end)

RegisterNetEvent('character:FinishSync', function()
    local ped = PlayerPedId()

    -- Safety: Sichtbarkeit/Alpha
    ResetEntityAlpha(ped)
    SetEntityAlpha(ped, 255, false)
    SetEntityVisible(ped, true, false)
    NetworkSetEntityInvisibleToNetwork(ped, false)

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

    -- Kleidung (nur wenn vorhanden; sonst nicht setzen)
    if tempClothes and next(tempClothes) ~= nil then
        if tempClothes.torso     then SetPedComponentVariation(ped, 3,  tempClothes.torso,      0, 0) end
        if tempClothes.pants     then SetPedComponentVariation(ped, 4,  tempClothes.pants,      tempClothes.pantsColor, 0) end
        if tempClothes.shoes     then SetPedComponentVariation(ped, 6,  tempClothes.shoes,      tempClothes.shoesColor, 0) end
        if tempClothes.undershirt then SetPedComponentVariation(ped, 8,  tempClothes.undershirt, tempClothes.undershirtColor, 0) end
        if tempClothes.top       then SetPedComponentVariation(ped, 11, tempClothes.top, tempClothes.topcolor, 0) end
    end

-- GetNumberOfPedPropTextureVariations(ped, propId, drawableId) -- Für Hut, Brille,Uhr etc..

    local topTextures = GetNumberOfPedTextureVariations(ped, 11, tempClothes.top)
    local undershirtTextures = GetNumberOfPedTextureVariations(ped, 8, tempClothes.undershirt)
    local shoesTextures = GetNumberOfPedTextureVariations(ped, 6, tempClothes.shoes)
    local pantsTextures = GetNumberOfPedTextureVariations(ped, 4, tempClothes.pants)

    SendNUIMessage({ action = 'Editor:updateTopColors', value = topTextures })
    SendNUIMessage({ action = 'Editor:updateUndershirtColors', value = undershirtTextures })
    SendNUIMessage({ action = 'Editor:updateShoesColors', value = shoesTextures })
    SendNUIMessage({ action = 'Editor:updatePantsColors', value = pantsTextures })

    prevData = tempData
    -- print('CLIENT:NetEvent:character:FinishSync')
    -- print('Hosenfarbe: ',tempClothes.pantsColor)
end)

-- ===== NUI-Callbacks =====

RegisterNUICallback('character:ReadyDone', function(_, cb)
    -- Ready-Poll beenden
    readyTick = false
    -- alte Daten an UI senden
    SendNUIMessage({ type = 'alt-event', name = 'character:SetData', payload = oldData })
    -- print('CLIENT:NUI Callback:character:ReadyDone')
    cb({ ok = true })
end)

RegisterNUICallback('character:Done', function(data, cb)
    TriggerServerEvent('character:Done', data or {},accountid)
    closeEditor()
    -- print('CLIENT:NUI Callback:character:Done - ACCID:',accountid)
    cb({ ok = true })
end)

RegisterNUICallback('character:Cancel', function(_, cb)
    TriggerServerEvent('character:Done', oldData or {})
    closeEditor()
    -- print('CLIENT:NUI Callback:character:Chancel')
    cb({ ok = true })
end)

RegisterNUICallback('character:Sync', function(data, cb)
    tempData = data.data or {}
    tempClothes = data.clothes or {}
    TriggerServerEvent('character:Sync', tempData, tempClothes)
    -- print('CLIENT:NUI Callback:character:Sync')
    cb({ ok = true })
end)
