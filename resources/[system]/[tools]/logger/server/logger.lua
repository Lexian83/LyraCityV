-- ==========================================
-- LyraCityV - Bootstrap (Basis/Helper)
-- ==========================================
LCV = LCV or {}
LCV.Util = LCV.Util or {}
LCV.DB   = LCV.DB or {}

-- ==== LOGGING ====
function LCV.Util.log(level, msg)
    print(("[LyraCityV][%s] %s"):format(level, msg))
end

