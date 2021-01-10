
TextScreens = TextScreens or {}

local meta = FindMetaTable("Player")

function meta:CanUseTextscreenRainbow()
	return self:IsUserGroup("vip") or self:IsUserGroup("vip+")
end

if SERVER then
	AddCSLuaFile()
	AddCSLuaFile("textscreens_config.lua")

	CreateConVar("sbox_maxtextscreens", "300", {FCVAR_NOTIFY, FCVAR_REPLICATED})

	-- Add to pocket blacklist for DarkRP
	-- Not using gamemode == "darkrp" because there are lots of flavours of darkrp
	hook.Add("loadCustomDarkRPItems", "TextScreens.PocketBlacklist", function()
		GAMEMODE.Config.PocketBlacklist["textscreen"] = true
	end)
end

include("textscreens_config.lua")