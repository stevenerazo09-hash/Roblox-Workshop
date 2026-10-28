-- Small helpers for uploaded assets. Every function falls back to something
-- plain when an id is empty or fails to load, so a missing asset never breaks
-- the world (it only looks simpler).

local AssetService = game:GetService("AssetService")

local Assets = {}

-- True when a Config asset id has been filled in.
function Assets.has(id: string?): boolean
	return type(id) == "string" and id ~= ""
end

-- A MeshPart built from an uploaded mesh id (works at runtime through
-- AssetService). Returns the part and whether the real mesh loaded; on failure
-- returns a plain Part of `fallbackShape` instead.
function Assets.meshPart(meshId: string?, fallbackShape: Enum.PartType?): (BasePart, boolean)
	if Assets.has(meshId) then
		local ok, result = pcall(function()
			return AssetService:CreateMeshPartAsync(meshId)
		end)
		if ok and result then
			return result, true
		end
		warn("[Sandbox] mesh failed to load, using a placeholder:", meshId, result)
	end
	local part = Instance.new("Part")
	part.Shape = fallbackShape or Enum.PartType.Block
	return part, false
end

-- Common settings for decorative parts that should never be touched or hit.
function Assets.decor(part: BasePart): BasePart
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = false
	part.Locked = true
	return part
end

return Assets
