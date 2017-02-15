
equip = equip or {}
equip.list = equip.list or {}


//Keyslot must be a number key.
function equip.AddEquipment(id, cooldown, key, iconPath)
	
	local eq = {}
	eq.id = id
	eq.key = key
	eq.cooldown = cooldown
	eq.iconPath = iconPath
	eq.playerCooldowns = {}
	
	equip.list[id] = eq
	
	if CLIENT then
		hud.AddEquipment(id,cooldown,key,iconPath)
	end
end

function equip.OnCooldown(ply,id)
	return equip.GetCooldown(ply,id) > CurTime()
end

function equip.GetCooldown(ply,id)
	return equip.list[id].playerCooldowns[ply] or CurTime()
end

function equip.SetCooldown(ply,id,new)
	local eq = equip.list[id]
	local time = new or (CurTime() + eq.cooldown)
	eq.playerCooldowns[ply] = time
	
	if CLIENT and ply == LocalPlayer() then
		hud.StartEquipmentCD(id, time)
	end
end

if SERVER then
	
    //Server:
    util.AddNetworkString("ass_equipment")
	AddCSLuaFile( )
   
    net.Receive("ass_equipment",function(len,ply)
        local id = net.ReadString()
		if equip.list[id] then
			hook.Run("PlayerUseEquipment",ply,id)
		else
			ErrorNoHalt(ply, "tried to use an invalid equipment: "..id.."\n")
		end
    end)
	
	
else
 
   
end
