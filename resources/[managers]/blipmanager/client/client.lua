-- blipmanager/client/client.lua

local blips = {}          -- [id] = handle
local blipDataCache = {}  -- Export / Debug

local function deleteOne(id)
    local handle = blips[id]
    if handle and DoesBlipExist(handle) then
        RemoveBlip(handle)
    end
    blips[id] = nil
    blipDataCache[id] = nil
end

local function clearAll()
    for id, handle in pairs(blips) do
        if handle and DoesBlipExist(handle) then
            RemoveBlip(handle)
        end
    end
    blips = {}
    blipDataCache = {}
end

local function createOne(entry)
    if not entry or not entry.coords then
        print("[BLIP] SKIP: invalid entry (no coords)")
        return
    end

    local id    = tonumber(entry.id) or 0
    local x     = tonumber(entry.coords.x) or 0.0
    local y     = tonumber(entry.coords.y) or 0.0
    local z     = tonumber(entry.coords.z) or 0.0
    local name  = entry.name or ("Blip " .. id)

    local sprite = tonumber(entry.sprite) or 1
    local color  = tonumber(entry.color) or 0

    -- 🚨 Hier nutzen wir jetzt safeScale
    local scale  = 1.0

    local display = tonumber(entry.display) or 2
    if display ~= 2 and display ~= 3 and display ~= 4 then
        display = 2
    end

    local shortRange = (entry.shortRange == true or entry.shortRange == 1 or entry.shortRange == "1")

    deleteOne(id)

    local blip = AddBlipForCoord(x, y, z)
    if not blip or blip == 0 then
        print(("[BLIP] Failed to create #%s at %.2f %.2f %.2f"):format(id, x, y, z))
        return
    end

    SetBlipSprite(blip, sprite)
    SetBlipColour(blip, color)
    SetBlipScale(blip, scale)
    SetBlipDisplay(blip, display)
    SetBlipAsShortRange(blip, shortRange)
    SetBlipAlpha(blip, 255)
    SetBlipBright(blip, true)

    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(name)
    EndTextCommandSetBlipName(blip)

    blips[id] = blip
    blipDataCache[id] = {
        id         = id,
        name       = name,
        coords     = vector3(x, y, z),
        sprite     = sprite,
        color      = color,
        scale      = scale,
        shortRange = shortRange,
        display    = display,
        category   = entry.category,
        visiblefor = tonumber(entry.visiblefor) or 0
    }

    print(("[BLIP] CREATED #%d '%s' scale=%.2f display=%d shortRange=%s"):
        format(id, name, scale, display, tostring(shortRange)))
end






RegisterNetEvent("lcv:blip:client:load", function(payload)
    clearAll()
    if type(payload) == "table" and type(payload.list) == "table" then
        print("[BLIP] CLIENT LOAD:", #payload.list, "entries")
        for _, e in ipairs(payload.list) do
            createOne(e)
        end
    else
        print("[BLIP] CLIENT LOAD: invalid payload")
    end
end)

RegisterNetEvent("lcv:blip:client:spawnOne", function(entry)
    createOne(entry)
end)

RegisterNetEvent("lcv:blip:client:deleteOne", function(id)
    deleteOne(id)
end)

RegisterNetEvent("lcv:blip:client:clearAll", function()
    clearAll()
end)

local function requestAll()
    TriggerServerEvent("lcv:blip:server:requestAll")
end

AddEventHandler("onClientResourceStart", function(res)
    if res == GetCurrentResourceName() then
        requestAll()
    end
end)

AddEventHandler("playerSpawned", function()
    if next(blips) == nil then
        requestAll()
    end
end)

exports("GetBlips", function()
    return blipDataCache
end)
