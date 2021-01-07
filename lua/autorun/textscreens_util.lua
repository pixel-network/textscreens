
if SERVER then
	AddCSLuaFile()
	AddCSLuaFile("textscreens_config.lua")

	CreateConVar("sbox_maxtextscreens", "1", {FCVAR_NOTIFY, FCVAR_REPLICATED})

	-- Add to pocket blacklist for DarkRP
	-- Not using gamemode == "darkrp" because there are lots of flavours of darkrp
	hook.Add("loadCustomDarkRPItems", "sammyservers_pocket_blacklist", function()
		GAMEMODE.Config.PocketBlacklist["sammyservers_textscreen"] = true
	end)
end

include("textscreens_config.lua")