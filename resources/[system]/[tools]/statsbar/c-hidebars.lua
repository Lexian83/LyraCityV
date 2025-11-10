-- c-hidebars.lua
-- Hides the health/armor/stamina bars that live under the minimap
-- by forcing the minimap scaleform into the 'GOLF' health layout, which has no bars.
-- Source idea: Cfx.re tutorial (Method 2: Lua overwrite of SETUP_HEALTH_ARMOUR).

CreateThread(function()
    local minimap = RequestScaleformMovie("minimap")  -- load minimap scaleform
    -- Nudge big map to avoid glitches when messing with scaleform state
    SetRadarBigmapEnabled(true, false)
    Wait(0)
    SetRadarBigmapEnabled(false, false)

    while true do
        Wait(0) -- run every frame to keep other scripts from restoring bars
        BeginScaleformMovieMethod(minimap, "SETUP_HEALTH_ARMOUR")
        -- 3 == golf layout (no bars). We constantly overwrite healthType.
        ScaleformMovieMethodAddParamInt(3)
        EndScaleformMovieMethod()
    end
end)
