-- resources/playerManager/client/c_spawn.lua
-- LyraCityV: Integrierter Player-Spawn (aus playerspawn migriert)

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

-- ======= Appearance =======

local function applyHeadBlend(ped, a)
  if not a then return end
  local faceFather = a.faceFather or a.faceF or 0
  local faceMother = a.faceMother or a.faceM or 0
  local skinFather = a.skinFather or faceFather
  local skinMother = a.skinMother or faceMother
  local faceMix = a.faceMix or 0.5
  local skinMix = a.skinMix or faceMix

  SetPedHeadBlendData(
    ped,
    faceFather, faceMother, 0,
    skinFather, skinMother, 0,
    faceMix, skinMix, 0.0,
    false
  )
end

local function applyFaceFeatures(ped, a)
  if not a or not a.structure then return end
  for i = 1, #a.structure do
    local val = a.structure[i]
    if val ~= nil then SetPedFaceFeature(ped, i - 1, val + 0.0) end
  end
end

local function applyOverlays(ped, a)
  if not a then return end

  if a.eyes ~= nil then SetPedEyeColor(ped, a.eyes) end

  if a.eyebrows ~= nil then
    local opacity = a.eyebrowsOpacity or 1.0
    local color1  = a.eyebrowsColor1 or 0
    SetPedHeadOverlay(ped, 2, a.eyebrows, opacity)
    SetPedHeadOverlayColor(ped, 2, 1, color1, color1)
  end

  if a.facialHair ~= nil then
    local opacity = a.facialHairOpacity or 1.0
    local color1  = a.facialHairColor1 or 0
    SetPedHeadOverlay(ped, 1, a.facialHair, opacity)
    SetPedHeadOverlayColor(ped, 1, 1, color1, color1)
  end

  if a.opacityOverlays then
    for _, o in ipairs(a.opacityOverlays) do
      if o.id and o.value and o.opacity then
        SetPedHeadOverlay(ped, o.id, o.value, o.opacity)
      end
    end
  end

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
  local hair = a.hair or a.hairStyle
  if hair ~= nil then SetPedComponentVariation(ped, 2, hair, 0, 0) end
  if a.hairColor1 or a.hairColor2 then
    SetPedHairColor(ped, a.hairColor1 or 0, a.hairColor2 or (a.hairColor1 or 0))
  end
  if a.hairOverlay and a.hairOverlay.overlay and a.hairOverlay.collection then
    AddPedDecorationFromHashes(ped, GetHashKey(a.hairOverlay.collection), GetHashKey(a.hairOverlay.overlay))
  end
end

-- ======= Clothes =======

local function applyClothes(ped, c)
  c = c or {}
  local function comp(idx, drawable, tex) if drawable ~= nil then SetPedComponentVariation(ped, idx, drawable, tex or 0, 0) end end
  local function prop(idx, drawable, tex)  if drawable ~= nil then SetPedPropIndex(ped, idx, drawable, tex or 0, true) end end

  if c.torso       ~= nil then comp(3,  c.torso,       0) end
  if c.undershirt  ~= nil then comp(8,  c.undershirt,  c.undershirtColor or 0) end
  if c.top         ~= nil then comp(11, c.top,         c.topcolor or 0) end
  if c.pants       ~= nil then comp(4,  c.pants,       c.pantsColor or 0) end
  if c.shoes       ~= nil then comp(6,  c.shoes,       c.shoesColor or 0) end
  if c.mask        ~= nil then comp(1,  c.mask,        c.maskColor or 0) end
  if c.bag         ~= nil then comp(5,  c.bag,         c.bagColor or 0) end
  if c.accessories ~= nil then comp(7,  c.accessories, c.accessoriesColor or 0) end
  if c.armor       ~= nil then comp(7,  c.armor,       c.armorColor or 0) end

  if c.hats  ~= nil then prop(0, c.hats,  c.hatsColor  or 0) end
  if c.glass ~= nil then prop(1, c.glass, c.glassColor or 0) end
  if c.ears  ~= nil then prop(2, c.ears,  c.earsColor  or 0) end
  if c.watch ~= nil then prop(6, c.watch, c.watchColor or 0) end
  if c.watch ~= nil then prop(7, c.watch, c.watchColor or 0) end
end

-- ======= Core Spawn =======

local function spawnPlayer(data)
  if not data then log("Kein Spawn-Data erhalten."); return end

  local appearance = data.appearances or data.appearance or {}
  local clothes    = data.clothes or {}

  -- Geschlechtswahl: appearance.sex (0=f,1=m) bevorzugt, sonst data.gender (0=f,1=m)
  local isMale
  if appearance.sex ~= nil then
    isMale = (tonumber(appearance.sex) == 1)
  elseif data.gender ~= nil then
    isMale = (tonumber(data.gender) == 1)
  else
    isMale = false
  end

  local modelName = isMale and 'mp_m_freemode_01' or 'mp_f_freemode_01'
  local pos     = data.pos or { x = 0.0, y = 0.0, z = 0.0 }
  local heading = data.heading or 0.0
  local dim     = data.dimension or 0

  local modelHash = loadModel(modelName) or loadModel('mp_m_freemode_01')
  if not modelHash then log("Fatal: Kein gültiges Model ladbar."); return end

  local player = PlayerId()
  local ped    = PlayerPedId()

  if dim and dim ~= 0 then SetPlayerRoutingBucket(player, dim) end

  if not IsScreenFadedOut() then
    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do Wait(0) end
  end

  FreezeEntityPosition(ped, true)
  SetEntityInvincible(ped, true)
  ClearPedTasksImmediately(ped)

  SetPlayerModel(player, modelHash)
  ped = PlayerPedId()
  SetPedDefaultComponentVariation(ped)
  ClearAllPedProps(ped)
  SetModelAsNoLongerNeeded(modelHash)

  SetEntityCoordsNoOffset(ped, pos.x + 0.0, pos.y + 0.0, pos.z + 0.0, false, false, false)
  SetEntityHeading(ped, heading + 0.0)

  ClearPedBloodDamage(ped)
  ClearPedDecorations(ped)

  applyHeadBlend(ped, appearance)
  applyFaceFeatures(ped, appearance)
  applyOverlays(ped, appearance)
  applyHair(ped, appearance)
  applyClothes(ped, clothes)

  SetEntityHealth(ped, data.health or 200)
  SetPedArmour(ped, 0)
  FreezeEntityPosition(ped, false)
  SetEntityInvincible(ped, false)

  DoScreenFadeIn(500)
end

-- Event vom playerManager-Server
RegisterNetEvent('LCV:spawn', function(data)
  spawnPlayer(data)
end)
