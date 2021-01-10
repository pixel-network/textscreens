
TextScreens.AllowedTools = {
	["textscreen"] = true,
	["remover"] = true,
	["permaprops"] = true
}

TextScreens.Fonts = {}

local function addFont(font, t)
	if CLIENT then
		t.size = 100
		surface.CreateFont(font, t)
		t.size = 50
		surface.CreateFont(font .. "_MENU", t)
	end

	table.insert(TextScreens.Fonts, font)
end

--[[
---------------------------------------------------------------------------
Custom fonts - requires server restart to take affect -- "Screens_" will be removed from the font name in spawnmenu
---------------------------------------------------------------------------
--]]

-- Default textscreens font
addFont("Screens_Open Sans SemiBold", {
	font = "Open Sans SemiBold",
	weight = 500,
	antialias = true
})

addFont("Screens_Open Sans Bold", {
	font = "Open Sans Bold",
	weight = 500,
	antialias = true
})

addFont("Screens_Comic Sans MS", {
	font = "Comic Sans MS",
	weight = 500,
	antialias = true
})

addFont("Screens_Trebuchet", {
	font = "Trebuchet MS",
	weight = 400,
	antialias = true
})

addFont("Screens_Arial", {
	font = "Arial",
	weight = 600,
	antialias = true
})

-- Roboto
addFont("Screens_Roboto", {
	font = "Roboto Medium",
	weight = 500,
	antialias = true
})

-- Helvetica
addFont("Screens_Helvetica", {
	font = "Helvetica",
	weight = 400,
	antialias = true
})

-- akbar
addFont("Screens_Akbar", {
	font = "akbar",
	weight = 400,
	antialias = true
})


if CLIENT then

	local function addFonts(path)
		local files, folders = file.Find("resource/fonts/" .. path .. "*", "MOD")

		for k, v in ipairs(files) do
			if string.GetExtensionFromFilename(v) == "ttf" then
				local font = string.StripExtension(v)
				if table.HasValue(TextScreens.Fonts, "Screens_" .. font) then continue end
print("-- "  .. font .. "\n" .. [[
addFont("Screens_ ]] .. font .. [[", {
	font = font,
	weight = 400,
	antialias = false,
	outline = true
})
				]])
			end
		end

		for k, v in ipairs(folders) do
			addFonts(path .. v .. "/")
		end
	end

	concommand.Add("get_fonts", function(ply)
		addFonts("")
	end)

end
