
moat_fireworks = moat_fireworks or {}
local mf = moat_fireworks

function ShowScores()
	local scores = player.GetScoreSorted()
	
	local frame = vgui.Create("DFrame")
	frame:SetTitle("")
	-- frame:SetTitle("Round Results")
	frame:SetSize(600,500)
	frame:Center()
	frame:MakePopup()
	frame.lblTitle:SetFont("bobbleTitle22")
	frame.lblTitle:SetTextColor(color_white)
	frame:DockPadding( 1,24,1,1 )
	function frame:Paint(w,h)
		surface.SetDrawColor(color_black)
		surface.DrawRect(0,0,w,h)
		surface.SetDrawColor(Color(57,57,57))
		surface.DrawRect(1,1,w-2,24)
	end
	
	local fw = vgui.Create("moat_fireworks",frame)
	fw:Dock(FILL)
	fw:SetSound(true)
	-- timer.Simple(0,function()
		-- local w = fw:GetWide()
		-- for i=-2, 2 do
			-- local x = w/2 + i*w/6
			-- mf.newfirework(fw, x, fw:GetTall()+5-i, 3+math.cos(i)*2)
		-- end
	-- end)
	
	frame.btnClose:MoveToFront()
	frame.btnMinim:SetVisible(false)
	frame.btnMaxim:SetVisible(false)
	
	local fla = vgui.Create("DLabel",frame)
	fla:SetFont("bobbleTitle32")
	fla:SetTextColor(color_white)
	fla:SetText("Winner")
	fla:SizeToContents()
	fla:SetExpensiveShadow(2,color_black)
	fla:CenterHorizontal()
	fla:AlignTop(100)
	local first = vgui.Create("DLabel",frame)
	first:SetFont("bobbleTitle64")
	first:SetTextColor(color_white)
	first:SetExpensiveShadow(2,color_black)
	first:SetText(scores[1]:Nick())
	first:SizeToContents()
	first:CenterHorizontal()
	first:AlignTop(130)
	local fpts = vgui.Create("DLabel",frame)
	fpts:SetFont("bobbleTitle36")
	fpts:SetTextColor(color_white)
	fpts:SetText(scores[1]:Frags().." points")
	fpts:SetExpensiveShadow(2,color_black)
	fpts:SizeToContents()
	fpts:CenterHorizontal()
	fpts:AlignTop(185)
	
	local sla = vgui.Create("DLabel",frame)
	sla:SetFont("bobbleTitle24")
	sla:SetTextColor(color_white)
	sla:SetText("2nd Place")
	sla:SizeToContents()
	sla:SetExpensiveShadow(2,color_black)
	sla:AlignLeft(frame:GetWide()*.25-sla:GetWide()/2)
	sla:AlignTop(290)
	local second = vgui.Create("DLabel",frame)
	second:SetFont("bobbleTitle50")
	second:SetTextColor(color_white)
	second:SetExpensiveShadow(2,color_black)
	second:SetText(scores[2]:Nick())
	second:SizeToContents()
	second:SetPos(frame:GetWide()*.25-second:GetWide()/2,312)
	local spts = vgui.Create("DLabel",frame)
	spts:SetFont("bobbleTitle24")
	spts:SetTextColor(color_white)
	spts:SetText(scores[2]:Frags().." points")
	spts:SetExpensiveShadow(2,color_black)
	spts:SizeToContents()
	spts:AlignLeft(frame:GetWide()*.25-spts:GetWide()/2)
	spts:AlignTop(358)
	
	local tla = vgui.Create("DLabel",frame)
	tla:SetFont("bobbleTitle24")
	tla:SetTextColor(color_white)
	tla:SetText("3rd Place")
	tla:SizeToContents()
	tla:SetExpensiveShadow(2,color_black)
	tla:AlignLeft(frame:GetWide()*.75-tla:GetWide()/2)
	tla:AlignTop(290)
	local third = vgui.Create("DLabel",frame)
	third:SetFont("bobbleTitle50")
	third:SetTextColor(color_white)
	third:SetExpensiveShadow(2,color_black)
	third:SetText(scores[3]:Nick())
	third:SizeToContents()
	third:SetPos(frame:GetWide()*.75-third:GetWide()/2,312)
	local tpts = vgui.Create("DLabel",frame)
	tpts:SetFont("bobbleTitle24")
	tpts:SetTextColor(color_white)
	tpts:SetText(scores[3]:Frags().." points")
	tpts:SetExpensiveShadow(2,color_black)
	tpts:SizeToContents()
	tpts:AlignLeft(frame:GetWide()*.75-spts:GetWide()/2)
	tpts:AlignTop(358)
	
	local ply = LocalPlayer()
	local place = table.KeyFromValue(scores,ply)
	if place > 3 then
		local you = vgui.Create("DLabel",frame)
		you:SetFont("bobbleTitle28")
		you:SetTextColor(color_white)
		you:SetText(("You finished ".. place .. STNDRD(place) .. " with "..ply:GetScore().." points."):upper())
		you:SizeToContents()
		you:SetExpensiveShadow(2,color_black)
		you:CenterHorizontal()
		you:AlignBottom(15)
	end
	
end


mf.peak = {min = 2, max = 5}
mf.particlepeak = {min = -40, max = 40}
mf.fireworkamt = {min = 70, max = 100}
mf.speed = 4
mf.particlespeed = 10
mf.color = Color(255, 255, 255)
mf.size = 6
mf.particlesize = 2
mf.explosionsize = 150

function mf.newfirework(p, x, y, peak)
    local firework = {}
    firework.pos = {x, y, {}}
    firework.peak = peak or math.Rand(mf.peak.min, mf.peak.max)
    firework.particlesize = math.random(40, mf.explosionsize)
    firework.particlenum = firework.particlesize
    firework.particles = {}
    firework.color = HSVToColor(math.random(360), 1, 1)
    firework.peaked = false
    table.insert(p.fireworks, firework)
end

function mf.newparticle(f, x, y)
    local particle = {}
    local a = math.rad(math.random(360))
    particle.pos = {x, y, math.sin(a) * math.random(10, f.particlesize), math.cos(a) * math.random(10, f.particlesize)}
    particle.peaked = false
    table.insert(f.particles, particle)
end


mf.panel = {}

AccessorFunc(mf.panel,"BackgroundColor","BackgroundColor")
AccessorFunc(mf.panel,"Sound","Sound",FORCE_BOOL)
mf.panel.Init = function(s)
	s:SetBackgroundColor(Color(57,57,57))
	s.fireworks = {}
end

mf.panel.Paint = function(s, w, h)
    surface.SetDrawColor(s:GetBackgroundColor())
    surface.DrawRect(0, 0, w, h)

    for k, v in pairs(s.fireworks) do
        if (not v.peaked) then
            draw.RoundedBox(mf.size / 2, v.pos[1], v.pos[2], mf.size, mf.size, v.color)
        else
            local part = v.particles
			surface.SetDrawColor(v.color)
            for i = 1, #part do
                -- draw.RoundedBox(mf.particlesize/2, part[i].pos[1], part[i].pos[2], mf.particlesize, mf.particlesize, v.color)
				
                surface.DrawRect(part[i].pos[1], part[i].pos[2], mf.particlesize, mf.particlesize)
            end
        end
    end
end

mf.panel.OnMousePressed = function(s)
	mf.newfirework(s, math.random(0, s:GetWide()), s:GetTall() + 5)
end

mf.panel.Think = function(s)
    if (math.random(0, 100) < 3 and #s.fireworks <= 5) then
        mf.newfirework(s, math.random(0, s:GetWide()), s:GetTall() + 5)
    end

    for k, v in pairs(s.fireworks) do
        if (v.color.a <= 5) then
            s.fireworks[k] = nil
            continue
        end

        if (not v.peaked) then
            v.pos[2] = Lerp(mf.speed * FrameTime(), v.pos[2], s:GetTall() / v.peak)
        else
            if (v.particlenum ~= #v.particles) then
                for i = 1, v.particlenum do
                    mf.newparticle(v, v.pos[1], v.pos[2])
                end
            else
                local part = v.particles

                for i = 1, v.particlenum do
                    if (part[i].peaked) then
                        part[i].pos[2] = part[i].pos[4] + v.pos[2]
                        part[i].pos[1] = part[i].pos[3] + v.pos[1]
                    else
                        if (part[i].pos[1] >= part[i].pos[3] + v.pos[1]) and (part[i].pos[2] >= part[i].pos[4] + v.pos[2]) then
                            part[i].peaked = true
                        else
                            part[i].pos[2] = Lerp(mf.particlespeed * FrameTime(), part[i].pos[2], part[i].pos[4] + v.pos[2])
                            part[i].pos[1] = Lerp(mf.particlespeed * FrameTime(), part[i].pos[1], part[i].pos[3] + v.pos[1])
                        end
                    end
                end
            end

            v.color.a = v.color.a - 2
            v.pos[2] = v.pos[2] + 0.5
        end

        if (v.pos[2] <= ((s:GetTall() / v.peak) + 5)) then
			if s.Sound then
				surface.PlaySound("assassins/pff"..math.random(1,3)..".mp3")
			end
            v.peaked = true
        end
    end
end
vgui.Register("moat_fireworks",mf.panel,"Panel")
