
do return end --Disable this until I can finish it.

--[[
	This file overrides SetModel and GetModel on all entities, but it only affects players.
	
	The player's real model is set to models/player/assassins/animationbase.mdl
	Their fake model is set to whatever you set it to.
	
	To manipulate the player's appearance (for instance, to change their color) make changes to the player's `animmdl` field.
	`ply.animmdl` is a clientside model. You can modify it directly.
	
	When the player's model is changed, it's removed and replaced.
	Make sure you reference it directly for this reason, rather than caching it.
	
	You can retrieve the player's literal model name with `ply:GetModelNoAnim()`
	You can also change the player's literal model with `ply:SetModelNoAnim(newModelName)`
	These are the new names for the original Set/GetModel functions.
]]


if SERVER then
	util.AddNetworkString("player_model")
end

local animmodel = Model("models/player/assassins/animationbase.mdl")
local meta = FindMetaTable("Entity")
meta.SetModelNoAnim = meta.SetModelNoAnim or meta.SetModel
meta.GetModelNoAnim = meta.GetModelNoAnim or meta.GetModel
function meta:SetModel(a,b,c)
	if self:IsPlayer() then
		self:SetModelNoAnim(animmodel,b,c)
		self.getmdl = a
		if SERVER then
			net.Start("player_model")
				net.WriteEntity(self)
				net.WriteString(a)
			net.Broadcast()
		else
		   self:clientSetModel(a)
		end
	else
		self:SetModelNoAnim(a,b,c)
	end
end
function meta:GetModel()
	return self.getmdl or self:GetModelNoAnim()
end

if CLIENT then
    net.Receive("player_model",function()
        local ply = net.ReadEntity()
        local mdl = net.ReadString()
		if IsValid(ply) then
			ply:clientSetModel(mdl)
		else
			timer.Simple(1,function()
				if IsValid(ply) then
					ply:clientSetModel(mdl)
				end
			end)
		end
    end)
	function meta:clientSetModel(mdl)
		if IsValid(self.animmdl) then 
			self.animmdl:Remove()
		end
		self.animmdl = ClientsideModel(mdl)
		self.animmdl:SetParent(self)
		self.animmdl:AddEffects(EF_BONEMERGE)
		self.animmdl:SetNoDraw(true)
		self.animmdl.GetPlayerColor = function(e)
			return self:GetPlayerColor()
		end
		
		self.getmdl = mdl
	end
	
	hook.Add("PrePlayerDraw","ass_animmodel",function(ply)
		if IsValid(ply.animmdl) and !ply.animmdl.drawing then
			ply.animmdl.drawing = true
			ply.animmdl:DrawModel()
			render.SetBlend(0)
		end
	end)
	hook.Add("PostPlayerDraw","ass_animmodel",function(ply)
		if IsValid(ply.animmdl) and ply.animmdl.drawing then
			ply.animmdl.drawing = false
			render.SetBlend(1)
		end
	end)
else
	hook.Add("DoPlayerDeath","ass_animmdl",function(ply)
		if ply.getmdl then
			ply:SetModelNoAnim(ply.getmdl)
		end
	end)
end

