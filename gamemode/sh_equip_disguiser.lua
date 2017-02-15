
// Thanks to Ndo360 (STEAM_0:0:30324945) for the help.

equip.AddEquipment("disguiser",ConVars.Server.disguiserCD:GetFloat(),1,"assassins/disguise.png")

if SERVER then
	// Server:
	util.AddNetworkString("ass_disguise")
	AddCSLuaFile( )
   
	net.Receive("ass_equipment",function(len,ply)
		local id = net.ReadString()
		hook.Run("PlayerUseEquipment",ply,id)
	end)
   
	// This is run when a player uses an equipment. id is the name of the equipment.
	hook.Add("PlayerUseEquipment","ass_disguiser",function(ply,id)
		if !equip.OnCooldown(ply,id) then
		
			if id == "disguiser" and ConVars.Server.disguiser:GetBool() then
				Disguise(ply,ConVars.Server.disguiserTime:GetFloat())
			end
			
		end
	   
	end)
   
	//Broadcast to clients.
	function SetDisguised(ply,bool)
		ply.Disguised = bool
		net.Start("ass_disguise")
			net.WriteEntity(ply)
			net.WriteBool(bool)
		net.Broadcast()
	end
   
	function Disguise(ply, time)
		
		if !IsValid(ply) then return end
		equip.SetCooldown(ply,"disguiser")
		
		local curMdl = ply:GetModel()
		local newMdl = RandomModel()
		while (curMdl == newMdl) do
			newMdl = RandomModel()
		end
   
		// Set the temp model
		SetDisguised(ply,true)
		ply:SetModel(newMdl)
		if IsValid(ply:GetAutoPilot()) then
			ply:GetAutoPilot():SetModel(newMdl)
		end
 
		// Reset the model after x seconds.
		timer.Create("disguiserTimer"..ply:EntIndex(), time, 1, function()
			if ply:IsValid() then
		 
				SetDisguised(ply,false)
				ply:SetModel(curMdl)
				if IsValid(ply:GetAutoPilot()) then
					ply:GetAutoPilot():SetModel(curMdl)
				end
			end
		end)
   
	end
 
	
	hook.Add("DoPlayerDeath","disguiserReset",function(ply)
		timer.Remove("disguiserTimer"..ply:EntIndex())
		SetDisguised(ply,false)
	end)
else
 
	local disguiserSlot = 1 // Which number key to press to enable the disguiser.
   
	net.Receive("ass_disguise",function(len)
		local ply = net.ReadEntity()
		local bool = net.ReadBool()
	   
		if IsValid(ply) then
			local effectdata = EffectData()
			effectdata:SetEntity( ply )
			util.Effect( "propspawn", effectdata )
			
			if IsValid(ply:GetAutoPilot()) then
				local effectdata = EffectData()
				effectdata:SetEntity( ply:GetAutoPilot() )
				util.Effect( "propspawn", effectdata )
			end
			
			ply.Disguised = bool
			
			if bool then //start cooldown
				equip.SetCooldown(ply,"disguiser")
			end
		end
	end)
   
	// Clientside:
	hook.Add("PlayerBindPress","EquipmentHook",function(ply,bind,down)
	   
		if bind == "slot"..disguiserSlot then
			hook.Run("PlayerUseEquipment",LocalPlayer(),"disguiser")
			net.Start("ass_equipment")
				net.WriteString("disguiser")
			net.SendToServer()
		end
	   
	end)
	
end
