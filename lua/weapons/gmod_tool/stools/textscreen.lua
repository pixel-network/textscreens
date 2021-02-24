TOOL.Category = "Construction"
TOOL.Name = "#tool.textscreen.name"
TOOL.Command = nil
TOOL.ConfigName = ""
local textBox = {}
local lineLabels = {}
local labels = {}
local sliders = {}
local rainbowCheckboxes = {}
local textscreenFonts = TextScreens.Fonts

local colors = {}

for i = 1, 5 do
	TOOL.ClientConVar["text" .. i] = ""
	TOOL.ClientConVar["size" .. i] = 20
	TOOL.ClientConVar["r" .. i] = 255
	TOOL.ClientConVar["g" .. i] = 255
	TOOL.ClientConVar["b" .. i] = 255
	TOOL.ClientConVar["a" .. i] = 255
	TOOL.ClientConVar["font" .. i] = 1
	TOOL.ClientConVar["rainbow" .. i] = 0
end

TOOL.ClientConVar["original_ui"] = 0 
cleanup.Register("textscreens")

if (CLIENT) then
	TOOL.Information = {
		{ name = "left" },
		{ name = "right" },
		{ name = "reload" },
	}

	language.Add("tool.textscreen.name", "3D2D Textscreens")
	language.Add("tool.textscreen.desc", "Create a Textscreen with multiple lines, font colours and sizes.")
	language.Add("tool.textscreen.left", "Spawn a Textscreen.")
	language.Add("tool.textscreen.right", "Update Textscreen with settings.")
	language.Add("tool.textscreen.reload", "Copy Textscreen.")
	language.Add("Undone.textscreens", "Undone Textscreen")
	language.Add("Undone_textscreens", "Undone Textscreen")
	language.Add("Cleanup.textscreens", "Textscreens")
	language.Add("Cleanup_textscreens", "Textscreens")
	language.Add("Cleaned.textscreens", "Cleaned up all Textscreens")
	language.Add("Cleaned_textscreens", "Cleaned up all Textscreens")
	language.Add("SBoxLimit.textscreens", "You've hit the Textscreen limit!")
	language.Add("SBoxLimit_textscreens", "You've hit the Textscreen limit!")
end

function TOOL:LeftClick(tr)
	if (tr.Entity:GetClass() == "player") then return false end
	if (CLIENT) then return true end

	local ply = self:GetOwner()
	local shouldRun = hook.Run("PlayerSpawnTextscreen", ply)
	if shouldRun == false then return false end

	if not (self:GetWeapon():CheckLimit("textscreens")) then return false end
	-- ensure at least 1 line of the textscreen has text before creating entity
	local hasText = false
	for i = 1, 5 do
		local text = self:GetClientInfo("text" .. i) or ""
		if text ~= "" then
			hasText = true
		end
	end
	if not hasText then return false end
	local textScreen = ents.Create("textscreen")
	textScreen:SetPos(tr.HitPos)
	local angle = tr.HitNormal:Angle()
	angle:RotateAroundAxis(tr.HitNormal:Angle():Right(), -90)
	angle:RotateAroundAxis(tr.HitNormal:Angle():Forward(), 90)
	textScreen:SetAngles(angle)
	textScreen:Spawn()
	textScreen:Activate()

	undo.Create("textscreens")
	undo.AddEntity(textScreen)
	undo.SetPlayer(ply)
	undo.Finish()
	ply:AddCount("textscreens", textScreen)
	ply:AddCleanup("textscreens", textScreen)

	for i = 1, 5 do
		textScreen:SetLine(
			i, -- Line
			self:GetClientInfo("text" .. i) or "", -- text
			Color( -- Color
				tonumber(self:GetClientInfo("r" .. i)) or 255,
				tonumber(self:GetClientInfo("g" .. i)) or 255,
				tonumber(self:GetClientInfo("b" .. i)) or 255,
				tonumber(self:GetClientInfo("a" .. i)) or 255
			),
			tonumber(self:GetClientInfo("size" .. i)) or 20,
			-- font
			tonumber(self:GetClientInfo("font" .. i)) or 1,

			ply:CanUseTextscreenRainbow() and (tonumber(self:GetClientInfo("rainbow" .. i)) or 0) or 0
		)
	end

	return true
end

function TOOL:RightClick(tr)
	if (tr.Entity:GetClass() == "player") then return false end
	if (CLIENT) then return true end
	local TraceEnt = tr.Entity

	if (IsValid(TraceEnt) and TraceEnt:GetClass() == "textscreen") then
		for i = 1, 5 do
			TraceEnt:SetLine(
				i, -- Line
				tostring(self:GetClientInfo("text" .. i)), -- text
				Color( -- Color
					tonumber(self:GetClientInfo("r" .. i)) or 255,
					tonumber(self:GetClientInfo("g" .. i)) or 255,
					tonumber(self:GetClientInfo("b" .. i)) or 255,
					tonumber(self:GetClientInfo("a" .. i)) or 255
				),
				tonumber(self:GetClientInfo("size" .. i)) or 20,
				-- font
				tonumber(self:GetClientInfo("font" .. i)) or 1,

				tonumber(self:GetClientInfo("rainbow" .. i)) or 0
			)
		end

		TraceEnt:Broadcast()

		return true
	end
end

function TOOL:Reload(tr)
	local TraceEnt = tr.Entity
	if (not isentity(TraceEnt) or TraceEnt:GetClass() ~= "textscreen") then return false end

	for i = 1, 5 do
		local linedata = TraceEnt.lines[i]
		RunConsoleCommand("textscreen_r" .. i, linedata.color.r)
		RunConsoleCommand("textscreen_g" .. i, linedata.color.g)
		RunConsoleCommand("textscreen_b" .. i, linedata.color.b)
		RunConsoleCommand("textscreen_a" .. i, linedata.color.a)
		RunConsoleCommand("textscreen_size" .. i, linedata.size)
		RunConsoleCommand("textscreen_text" .. i, linedata.text)
		RunConsoleCommand("textscreen_font" .. i, linedata.font)
		RunConsoleCommand("textscreen_rainbow" .. i, linedata.rainbow)
	end

	return true
end

local ConVarsDefault = TOOL:BuildConVarList()

local function originalCPanel(CPanel,tool)
	local localPly = LocalPlayer()

	CPanel:AddControl("Header", {
		Text = "#tool.textscreen.name",
		Description = "#tool.textscreen.desc"
	})

	local function TrimFontName(fontnum)
		return string.Left(textscreenFonts[fontnum], 8) == "Screens_" and string.TrimLeft(textscreenFonts[fontnum], "Screens_") or textscreenFonts[fontnum]
	end

	local changefont
	local fontnum = textscreenFonts[GetConVar("textscreen_font1"):GetInt()] ~= nil and GetConVar("textscreen_font1"):GetInt() or 1

	cvars.AddChangeCallback("textscreen_font1", function(convar_name, value_old, value_new)
		fontnum = textscreenFonts[tonumber(value_new)] ~= nil and tonumber(value_new) or 1
		local font = TrimFontName(fontnum)
		if not IsValid(changefont) then return end
		changefont:SetText("Change font (" .. font .. ")")
	end)

	local function ResetFont(lines, text)
		if #lines >= 5 then
			fontnum = 1
			for i = 1, 5 do
				RunConsoleCommand("textscreen_font" .. i, 1)
			end
		end
		for k, i in pairs(lines) do
			if text then
				RunConsoleCommand("textscreen_text" .. i, "")
				labels[i]:SetText("")
			end
			labels[i]:SetFont(textscreenFonts[fontnum] .. "_MENU")
		end
	end

	resetall = vgui.Create("DButton", resetbuttons)
	resetall:SetSize(100, 25)
	resetall:SetText("Reset all")

	resetall.DoClick = function()
		local menu = DermaMenu()

		menu:AddOption("Reset colors", function()
			for i = 1, 5 do
				RunConsoleCommand("textscreen_r" .. i, 255)
				RunConsoleCommand("textscreen_g" .. i, 255)
				RunConsoleCommand("textscreen_b" .. i, 255)
				RunConsoleCommand("textscreen_a" .. i, 255)
				RunConsoleCommand("textscreen_rainbow" .. i, 0)
			end
		end)

		menu:AddOption("Reset sizes", function()
			for i = 1, 5 do
				RunConsoleCommand("textscreen_size" .. i, 20)
				sliders[i]:SetValue(20)
				labels[i]:SetFont(textscreenFonts[fontnum] .. "_MENU")
			end
		end)

		menu:AddOption("Reset textboxes", function()
			for i = 1, 5 do
				RunConsoleCommand("textscreen_text" .. i, "")
				textBox[i]:SetValue("")
			end
		end)

		menu:AddOption("Reset rainbows", function()
			for i = 1, 5 do
				RunConsoleCommand("textscreen_rainbow" .. i, 0)
				rainbowCheckboxes[i]:OnChange(false)
			end
		end)

		menu:AddOption("Reset fonts", function()
			ResetFont({1, 2, 3, 4, 5}, false)
		end)

		menu:AddOption("Reset rainbows", function()
			for i = 1, 5 do
				rainbowCheckboxes[i]:SetValue(0)
			end
		end)

		menu:AddOption("Reset everything", function()
			for i = 1, 5 do
				RunConsoleCommand("textscreen_r" .. i, 255)
				RunConsoleCommand("textscreen_g" .. i, 255)
				RunConsoleCommand("textscreen_b" .. i, 255)
				RunConsoleCommand("textscreen_a" .. i, 255)
				RunConsoleCommand("textscreen_size" .. i, 20)
				sliders[i]:SetValue(20)
				rainbowCheckboxes[i]:SetValue(0)
				RunConsoleCommand("textscreen_rainbow" .. i, "")
				rainbowCheckboxes[i]:OnChange(false)
				RunConsoleCommand("textscreen_font" .. i, 1)
				textBox[i]:SetValue("")
			end
			ResetFont({1, 2, 3, 4, 5}, true)
		end)

		menu:Open()
	end

	CPanel:AddItem(resetall)
	resetline = vgui.Create("DButton")
	resetline:SetSize(100, 25)
	resetline:SetText("Reset line")

	resetline.DoClick = function()
		local menu = DermaMenu()

		for i = 1, 5 do
			menu:AddOption("Reset line " .. i, function()
				RunConsoleCommand("textscreen_r" .. i, 255)
				RunConsoleCommand("textscreen_g" .. i, 255)
				RunConsoleCommand("textscreen_b" .. i, 255)
				RunConsoleCommand("textscreen_a" .. i, 255)
				RunConsoleCommand("textscreen_size" .. i, 20)
				sliders[i]:SetValue(20)
				RunConsoleCommand("textscreen_text" .. i, "")
				RunConsoleCommand("textscreen_rainbow" .. i, 0)
				rainbowCheckboxes[i]:OnChange(false)
				textBox[i]:SetValue("")
				ResetFont({i}, true)
			end)
		end

		menu:AddOption("Reset all lines", function()
			for i = 1, 5 do
				RunConsoleCommand("textscreen_r" .. i, 255)
				RunConsoleCommand("textscreen_g" .. i, 255)
				RunConsoleCommand("textscreen_b" .. i, 255)
				RunConsoleCommand("textscreen_a" .. i, 255)
				RunConsoleCommand("textscreen_size" .. i, 20)
				sliders[i]:SetValue(20)
				RunConsoleCommand("textscreen_rainbow" .. i, 0)
				rainbowCheckboxes[i]:OnChange(false)
				RunConsoleCommand("textscreen_text" .. i, "")
				RunConsoleCommand("textscreen_font" .. i, 1)
				textBox[i]:SetValue("")
			end
			ResetFont({1, 2, 3, 4, 5}, true)
		end)

		menu:Open()
	end

	CPanel:AddItem(resetline)

	-- Change font
	changefont = vgui.Create("DButton")
	changefont:SetSize(100, 25)
	changefont:SetText("Change font (" .. TrimFontName(fontnum) .. ")" )

	changefont.DoClick = function()
		local menu = DermaMenu()

		for i = 1, #textscreenFonts do
			local font = TrimFontName(i)
			menu:AddOption(font, function()
				fontnum = i
				for o = 1, 5 do
					RunConsoleCommand("textscreen_font" .. o, i)
					labels[o]:SetFont(textscreenFonts[fontnum] .. "_MENU")
				end
				changefont:SetText("Change font (" .. font .. ")")
			end)
		end

		menu:Open()
	end

	CPanel:AddItem(changefont)

	CPanel:AddControl("ComboBox", {
		MenuButton = 1,
		Folder = "textscreen",
		Options = {
			["#preset.default"] = ConVarsDefault
		},
		CVars = table.GetKeys(ConVarsDefault)
	})

	--wlocal mat = Material("vgui/gradient-u")
	--local matd = Material("vgui/gradient-d")
	PIXEL.RegisterFont("TS.LineText", "Open Sans Bold", 22)
	PIXEL.RegisterFont("TS.EmptyText", "Open Sans Bold", 12)
	PIXEL.RegisterFont("TS.RBDisText", "Open Sans Bold", 45)

	for i = 1, 5 do
		lineLabels[i] = vgui.Create("DPanel",CPanel)
		lineLabels[i].Paint = function(s,w,h)
			draw.Text({
				text="Line "..i,
				pos={w/2,h},
				xalign=1,
				yalign=TEXT_ALIGN_BOTTOM,
				font="PIXEL.TS.LineText",
				color=PIXEL.Colors.Header
			})
		end
		lineLabels[i].PaintOver = function(s,w,h)
			surface.SetDrawColor(PIXEL.Colors.Header)
			surface.DrawRect(0,h-2,w,2)
		--	surface.SetMaterial(mat)
		--	surface.DrawTexturedRect(0,0,2,50)
		--	surface.DrawTexturedRect(w-2,0,2,50)
		end
		CPanel:AddPanel(lineLabels[i])

		local ctrl = vgui.Create("CtrlColor",CPanel)
		ctrl:SetLabel("")
		ctrl:SetConVarR("textscreen_r"..i)
		ctrl:SetConVarG("textscreen_g"..i)
		ctrl:SetConVarB("textscreen_b"..i)
		ctrl:SetConVarA("textscreen_a"..i)
		ctrl.PaintOver = function(s,w,h)
			if s:GetDisabled() then
				draw.Text({
					text="RAINBOW ENABLED",
					pos={w/2,h/2},
					xalign=1,
					yalign=1,
					color=PIXEL.Colors.Background,
					font="PIXEL.TS.RBDisText"
				})
			end
		end


		CPanel:AddPanel( ctrl )

		rainbowCheckboxes[i] = vgui.Create("DCheckBoxLabel")
		rainbowCheckboxes[i]:SetText("Rainbow Text")
		rainbowCheckboxes[i]:SetTextColor(Color(0,0,0,255))
		
		rainbowCheckboxes[i]:SetTooltip("Enable for rainbow text")
		rainbowCheckboxes[i]:SetValue(GetConVar("textscreen_rainbow" .. i))
		rainbowCheckboxes[i].OnChange = function(s,t)
			GetConVar("textscreen_rainbow" .. i):SetInt(t and 1 or 0)
			ctrl:SetDisabled(t)
		end
		rainbowCheckboxes[i]:OnChange(GetConVar("textscreen_rainbow" .. i):GetInt())
		if not (IsValid(localPly) and localPly:CanUseTextscreenRainbow()) then
			rainbowCheckboxes[i]:SetTall(0)
			rainbowCheckboxes[i]:SetVisible(false)
		end

		CPanel:AddItem(rainbowCheckboxes[i])

		sliders[i] = vgui.Create("DNumSlider")
		sliders[i]:SetText("Font size")
		sliders[i]:SetMinMax(20, 100)
		sliders[i]:SetDecimals(0)
		sliders[i]:SetValue(GetConVar("textscreen_size" .. i))
		sliders[i]:SetConVar("textscreen_size" .. i)

		CPanel:AddItem(sliders[i])
		textBox[i] = vgui.Create("DTextEntry")
		textBox[i]:SetUpdateOnType(true)
		textBox[i]:SetEnterAllowed(true)
		textBox[i]:SetConVar("textscreen_text" .. i)
		textBox[i]:SetValue(GetConVar("textscreen_text" .. i):GetString())
		textBox[i]._ovText = {}
		textBox[i]._rawText = ""
		
		textBox[i].OnTextChanged = function()
			local xpos = 5
			local txt = textBox[i]:GetValue()
			textBox[i]._rawText = txt
			GetConVar("textscreen_text" .. i):SetString(txt)
			surface.SetFont(textscreenFonts[fontnum] .. "_MENU")
			textBox[i]._ovText = {}
			for char=1,#txt do 
				local charr = txt:sub(char,char)
				local ww,hh = surface.GetTextSize(charr)
				textBox[i]._ovText[char] = {
					text=charr,
					posx=xpos,
					high=hh
				} 
				xpos=xpos+ww
			end
		end
		textBox[i].OnTextChanged()

		CPanel:AddItem(textBox[i])

		labels[i] = CPanel:AddControl("Label", {
			Text = #GetConVar("textscreen_text" .. i):GetString() >= 1 and GetConVar("textscreen_text" .. i):GetString() or "Line " .. i,
			Description = "Line " .. i
		})

		labels[i]:SetFont(textscreenFonts[fontnum] .. "_MENU")
		labels[i]:SetAutoStretchVertical(true)
		labels[i]:SetDisabled(true)
		labels[i]:SetHeight(50)
		labels[i]:SetText("")
		labels[i].Paint = function(s,w,h)
			surface.SetFont(textscreenFonts[fontnum] .. "_MENU")
			if GetConVar("textscreen_rainbow"..i):GetInt()==1 then
				if (#textBox[i]._rawText==0)then
					draw.Text({
						text="Its feeling kind of empty...",
						color=Color(204,204,204),
						font="PIXEL.TS.EmptyText",
						pos={w/2,h-10},
						xalign=1,

					})
					return
				end
				for index,v in ipairs(textBox[i]._ovText) do 
					surface.SetTextPos(v.posx,h/2-(v.high/2))
					surface.SetTextColor(HSVToColor((CurTime() * 60 + (index * 5)) % 360, 1, 1))
					surface.DrawText(v.text)
				end 
			else
				if (#textBox[i]._rawText==0)then
					draw.Text({
						text="Its feeling kind of empty...",
						color=Color(204,204,204),
						font="PIXEL.TS.EmptyText",
						pos={w/2,h-10},
						xalign=1,

					})
				end
				local _,hh = surface.GetTextSize(textBox[i]._rawText)
				surface.SetTextPos(5,h/2-(hh/2))
				surface.SetTextColor(s:GetColor())
				surface.DrawText(textBox[i]._rawText)
				
			end
		end
		--labels[i].PaintOver = function(s,w,h)
		--	surface.SetDrawColor(PIXEL.Colors.Header)
		--	surface.DrawRect(0,h-2,w,h)
		--	surface.SetMaterial(matd)
		--	surface.DrawTexturedRect(0,(h-h)-2,2,h)
		--	surface.DrawTexturedRect(w-2,(h-h)-2,2,h)
		--end
		labels[i].Think = function()
			labels[i]:SetColor(
				Color(
					GetConVar("textscreen_r" .. i):GetInt(),
					GetConVar("textscreen_g" .. i):GetInt(),
					GetConVar("textscreen_b" .. i):GetInt(),
					GetConVar("textscreen_a" .. i):GetInt()
				)
			)
		end
	end
end

function TOOL.BuildCPanel(CPanel)
	originalCPanel(CPanel,TOOL)
end

PIXEL.RegisterFont("TS.HUDFont","Open Sans Bold",45)
function TOOL:DrawHUD()
	for i=1,5 do
			draw.Text({
				text=GetConVar("textscreen_text" .. i):GetString(),
				pos={ScrW()/2,ScrH()/2+20+(i*50)},
				xalign=1,
				yalign=1,
				font="PIXEL.TS.HUDFont",
				color=Either(GetConVar("textscreen_rainbow"..i):GetInt()==1,HSVToColor((CurTime() * 60 + (i * 5)) % 360, 1, 1),Color(GetConVar("textscreen_r"..i):GetInt(),GetConVar("textscreen_g"..i):GetInt(),GetConVar("textscreen_b"..i):GetInt(),GetConVar("textscreen_a"..i):GetInt()))				
			})
			-- draw.Text({
			-- 	text=GetConVar("textscreen_text" .. i):GetString(),
			-- 	pos={(ScrW()/2)-2,ScrH()/2+20+(i*50)-2},
			-- 	xalign=1,
			-- 	yalign=1,
			-- 	font="PIXEL.TS.HUDFont",
			-- 	color=PIXEL.Colors.Background
			-- })

		--if  then 
	----	else
	--	end
	end
end