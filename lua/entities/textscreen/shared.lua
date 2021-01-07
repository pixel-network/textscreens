ENT.Type = "anim"
ENT.Base = "base_entity"
ENT.PrintName = "Textscreen"
ENT.Author = "SammyServers & Tom.bat"
ENT.Spawnable = false
ENT.AdminSpawnable = false
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

function ENT:SetupDataTables()
	self:NetworkVar("Bool", 0, "IsPersisted")
end

hook.Add("CanTool", "TextScreens.PreventTools", function(ply, tr, tool)
	-- only allow textscreen, remover, and permaprops tool
	local ent = tr.Entity
	if not IsValid(ent) then return end
	if ent:GetClass() == "textscreen" and not TextScreens.AllowedTools[tool] then
		return false
	end
end)
