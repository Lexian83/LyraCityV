-- client/editor_client.lua
-- Character Editor Client für LyraCityV

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
    SetEntityCoordsNoOffset(ped, x, y, z, false, false, false)
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
    SetNuiFocus(state, state)
    SetNuiFocusKeepInput(state and true or false)
    if state then SetMouseCursorActiveThisFrame() end
end

local function loadModelByName(name)
    local hash = joaat(name)
    if not IsModelInCdimage(hash) or not IsModelValid(hash) then
        return nil
    end
    RequestModel(hash)
    local timeout = GetGameTimer() + 8000
    while not HasModelLoaded(hash) do
        if GetGameTimer() > timeout then
            return nil
        end
        Wait(0)
    end
    return hash
end

local function applyModelSafe(modelName)
    local hash = loadModelByName(modelName)
    if not hash then return false end

    local ped = PlayerPedId()
    ResetEntityAlpha(ped)
    SetEntityAlpha(ped, 255, false)
    SetEntityVisible(ped, true, false)
    NetworkSetEntityInvisibleToNetwork(ped, false)

    SetPlayerModel(PlayerId(), hash)
    SetModelAsNoLongerNeeded(hash)

    ped = PlayerPedId()
    SetPedDefaultComponentVariation(ped)

    ClearPedTasksImmediately(ped)
    ClearAllPedProps(ped)
    RemoveAllPedWeapons(ped, true)

    ResetEntityAlpha(ped)
    SetEntityAlpha(ped, 255, false)
    SetEntityVisible(ped, true, false)
    NetworkSetEntityInvisibleToNetwork(ped, false)

    Wait(0)
    return true
end

-- ========= Editor-Funktionen =========

local function openEditor()
    if editorOpen then return end
    editorOpen = true

    exports.inputmanager:LCV_OpenUI('chareditor', { nui = true, keepInput = false })
    showCursor(true)

    local x, y, z, h = -1037.5, -2737.8, 20.2, 90.0
    teleportTo(x, y, z, h)
    ensureAtCoordAndCollision(x, y, z)

    -- Default Model (wird durch Sync/SetModel überschrieben)
    applyModelSafe('mp_f_freemode_01')

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
    showCursor(false)

    FreezeEntityPosition(PlayerPedId(), false)
    destroyPedEditCamera()

    SendNUIMessage({ action = "closeEditor" })
end

-- ===== Server -> Client Events =====

RegisterNetEvent('character:Edit', function(_oldData, acc_id)
    oldData   = _oldData or {}
    accountid = acc_id or 0
    openEditor()
end)

RegisterNetEvent('character:Sync', function(data, clothes)
    tempData    = data or {}
    tempClothes = clothes or {}

    Wait(0)
    TriggerEvent('character:FinishSync')
end)

RegisterNetEvent('character:SetModel', function(modelName)
    local currentModel = GetEntityModel(PlayerPedId())
    local targetHash   = joaat(modelName)

    if currentModel ~= targetHash then
        applyModelSafe(modelName)
    end
end)

RegisterNetEvent('character:FinishSync', function()
    local ped = PlayerPedId()

    ResetEntityAlpha(ped)
    SetEntityAlpha(ped, 255, false)
    SetEntityVisible(ped, true, false)
    NetworkSetEntityInvisibleToNetwork(ped, false)

    ClearPedBloodDamage(ped)
    ClearPedDecorations(ped)

    SetPedHeadBlendData(ped, 0, 0, 0, 0, 0, 0, 0.0, 0.0, 0, false)

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

    if tempData.structure then
        for i = 1, #tempData.structure do
            SetPedFaceFeature(ped, i - 1, tempData.structure[i] or 0.0)
        end
    end

    if tempData.opacityOverlays then
        for _, ov in ipairs(tempData.opacityOverlays) do
            SetPedHeadOverlay(
                ped,
                ov.id or 0,
                ov.value or 0,
                tonumber(ov.opacity or 1.0) or 1.0
            )
        end
    end

    if tempData.hairOverlay then
        local collection = GetHashKey(tempData.hairOverlay.collection or '')
        local overlay    = GetHashKey(tempData.hairOverlay.overlay or '')
        AddPedDecorationFromHashes(ped, collection, overlay)
    end

    SetPedComponentVariation(ped, 2, tempData.hair or 0, 0, 0)
    SetPedHairColor(ped, tempData.hairColor1 or 0, tempData.hairColor2 or 0)

    SetPedHeadOverlay(ped, 1, tempData.facialHair or 0, tempData.facialHairOpacity or 0.0)
    SetPedHeadOverlayColor(ped, 1, 1, tempData.facialHairColor1 or 0, tempData.facialHairColor1 or 0)

    SetPedHeadOverlay(ped, 2, tempData.eyebrows or 0, 1.0)
    SetPedHeadOverlayColor(ped, 2, 1, tempData.eyebrowsColor1 or 0, tempData.eyebrowsColor1 or 0)

    if tempData.colorOverlays then
        for _, ov in ipairs(tempData.colorOverlays) do
            local c2 = ov.color2 or ov.color1 or 0
            SetPedHeadOverlay(
                ped,
                ov.id or 0,
                ov.value or 0,
                tonumber(ov.opacity or 1.0) or 1.0
            )
            SetPedHeadOverlayColor(ped, ov.id or 0, 1, ov.color1 or 0, c2 or 0)
        end
    end

    if tempData.eyes then
        SetPedEyeColor(ped, tempData.eyes)
    end

    if tempClothes and next(tempClothes) ~= nil then
        if tempClothes.torso      then SetPedComponentVariation(ped, 3,  tempClothes.torso, 0, 0) end
        if tempClothes.pants      then SetPedComponentVariation(ped, 4,  tempClothes.pants, tempClothes.pantsColor or 0, 0) end
        if tempClothes.shoes      then SetPedComponentVariation(ped, 6,  tempClothes.shoes, tempClothes.shoesColor or 0, 0) end
        if tempClothes.undershirt then SetPedComponentVariation(ped, 8,  tempClothes.undershirt, tempClothes.undershirtColor or 0, 0) end
        if tempClothes.top        then SetPedComponentVariation(ped, 11, tempClothes.top, tempClothes.topcolor or 0, 0) end
    end

    local topTextures        = GetNumberOfPedTextureVariations(ped, 11, tempClothes.top or 0)
    local undershirtTextures = GetNumberOfPedTextureVariations(ped, 8,  tempClothes.undershirt or 0)
    local shoesTextures      = GetNumberOfPedTextureVariations(ped, 6,  tempClothes.shoes or 0)
    local pantsTextures      = GetNumberOfPedTextureVariations(ped, 4,  tempClothes.pants or 0)

    SendNUIMessage({ action = 'Editor:updateTopColors',         value = topTextures })
    SendNUIMessage({ action = 'Editor:updateUndershirtColors',  value = undershirtTextures })
    SendNUIMessage({ action = 'Editor:updateShoesColors',       value = shoesTextures })
    SendNUIMessage({ action = 'Editor:updatePantsColors',       value = pantsTextures })

    prevData = tempData
end)

-- ===== NUI-Callbacks =====

RegisterNUICallback('character:ReadyDone', function(_, cb)
    readyTick = false
    SendNUIMessage({ type = 'alt-event', name = 'character:SetData', payload = oldData })
    cb({ ok = true })
end)

RegisterNUICallback('character:Done', function(data, cb)
    -- NUI sendet { data, clothes, identity }
    TriggerServerEvent('character:Done', data or {}, accountid)
    closeEditor()
    cb({ ok = true })
end)

RegisterNUICallback('character:Cancel', function(_, cb)
    -- Kein Speichern, einfach zurück ins Charselect
    TriggerServerEvent('character:Cancel', accountid)
    closeEditor()
    cb({ ok = true })
end)

RegisterNUICallback('character:Sync', function(data, cb)
    tempData    = data.data or {}
    tempClothes = data.clothes or {}
    TriggerServerEvent('character:Sync', tempData, tempClothes)
    cb({ ok = true })
end)
