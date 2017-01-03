
autopilot = autopilot or {}
autopilot.Sync = false

if SERVER then
	util.AddNetworkString("autopilot_ent")
	
	concommand.Add("autopilot_begin",function(p,c,a)
		if IsValid(p:GetAutoPilot()) then p:GetAutoPilot():Remove() end
		timer.Simple(.5,function()
			autopilot.Begin(p)
		end)
	end)
end

local meta = FindMetaTable("Entity")
function meta:SetAutoPilot(a)
	self:SetNW2Entity("ass_autopilot",a)
	a:SetNW2Entity("ass_player", self)
end
function meta:GetAutoPilot()
	return self:GetNW2Entity("ass_autopilot",NULL)
end
function meta:GetEnt()
	local ap = self:GetAutoPilot()
	if IsValid(ap) then
		if ap:GetDisabled() then
			return self
		else
			return ap
		end
	else
		return self
	end
end

function autopilot.Interrupt(ply)
	if CLIENT then return end
	if not ply then return end
	
	local npc = ply:GetAutoPilot()
	if IsValid(npc) and not npc:GetDisabled() then
		
		//Spawn and move player
		local angs = ply:EyeAngles()
		ply:UnSpectate()
		ply.UnSpec = true
		ply:Spawn()
		ply.UnSpec = false
		
		local pos = autopilot.Unstuck(ply,npc)
		ply:SetPos(pos)
		
		ply:SetEyeAngles(angs)
		ply:SetCollisionGroup(COLLISION_GROUP_DEBRIS_TRIGGER)
		
		//Change bones
		-- if CLIENT then
			-- for id=0,#npc:GetBoneCount()-1 do
				-- ply:SetBonePosition(id,npc:GetBonePosition(id))
			-- end
		-- end
		
		//Restore state
		-- if ply.AutopilotSpawnInfo then
			-- local t = ply.AutopilotSpawnInfo
			-- ply:SetHealth( t.health )
			-- ply:SetArmor( t.armor )
			-- timer.Simple( 0.1, function() autopilot.RestoreWeapons( ply, t ) end )
			-- ply.AutopilotSpawnInfo = nil
		-- end
		
		//"Remove" NPC
		npc:SetSolid(SOLID_NONE)
		npc:SetDisabled(true)
		-- npc:SetParent(ply)
		-- npc:SetPos(Vector(10000,10000,10000))
		-- npc:SetNoDraw(true)
	end
end

function autopilot.Begin(ply)
	if CLIENT then return end
	if not ply then return end
	grapp.Finish(ply)
	
	local npc = ply:GetAutoPilot()
	//Create npc if not exists
	if not IsValid(npc) then 
		npc = ents.Create("npc_walking")
		ply:SetAutoPilot( npc )
		npc:Spawn()
		npc:Activate()
		npc:SetGender(ply:GetGender())
		npc:SetModel(ply:GetModel())
		
	elseif not npc:GetDisabled() then
		return --we are already in autopilot.
	end
	
	autopilot.Sync = true
	timer.Simple(.5,function()
		net.Start("autopilot_ent")
			net.WriteEntity(ply)
			net.WriteEntity(ply:GetAutoPilot())
		net.Broadcast()
		timer.Simple(.1,function()
			autopilot.Sync = false
		end)
	end)
	
	npc:SetMode(0)
	npc:SetGroupLeader(NULL)
	npc:SetGroupOffset(Vector(0,0,0))
	npc.Pose = nil
	
	//Find group
	local found = GetNearestGroup(ply:GetPos())
	if found then
		npc:SetGroupLeader(found)
		npc:SetMode(1)
		if found:GetPos():DistToSqr(ply:GetPos()) < 40^2 then
			local rand = VectorRand():GetNormalized()
			rand.z = 0
			rand = rand*40
			npc:SetGroupOffset(rand)
		else
			npc:SetGroupOffset(ply:GetPos() - found:GetPos())
		end
	end
	
	//Move npc to player's position
	-- npc:SetNoDraw(false)
	npc:SetPos(ply:GetPos()+Vector(0,0,8))
	npc:SetAngles(ply:GetAngles())
	if npc:GetModel() != ply:GetModel() then
		npc:SetModel(ply:GetModel())
	end
	
	//Add delay to next takecontrol.
	ply.AutopilotBeginTime = CurTime()
	
	//Strip and save weapons
	autopilot.GetSpawnInfo(ply)
	ply:StripWeapons()
	
	//Start spectate
	-- timer.Simple(0,function()
		ply:Spectate(OBS_MODE_CHASE)
		ply:SpectateEntity(npc)
	-- end)
	
	npc:SetSolid(SOLID_BBOX)
	npc:SetDisabled(false)
	
end

//Taken from ULib
function autopilot.GetSpawnInfo( ply )
	local result = {}

	local t = {}
	ply.AutopilotSpawnInfo = t
	t.health = ply:Health()
	t.armor = ply:Armor()
	if ply:GetActiveWeapon():IsValid() then
		t.curweapon = ply:GetActiveWeapon():GetClass()
	end

	local weapons = ply:GetWeapons()
	local data = {}
	for _, weapon in ipairs( weapons ) do
		printname = weapon:GetClass()
		data[ printname ] = {}
		data[ printname ].clip1 = weapon:Clip1()
		data[ printname ].clip2 = weapon:Clip2()
		data[ printname ].ammo1 = ply:GetAmmoCount( weapon:GetPrimaryAmmoType() )
		data[ printname ].ammo2 = ply:GetAmmoCount( weapon:GetSecondaryAmmoType() )
	end
	t.data = data
end
//Taken from ULib
function autopilot.RestoreWeapons( ply, t )
	if not ply:IsValid() then return end -- Drat, missed 'em.

	ply:StripAmmo()
	ply:StripWeapons()

	for printname, data in pairs( t.data ) do
		ply:Give( printname )
		local weapon = ply:GetWeapon( printname )
		weapon:SetClip1( data.clip1 )
		weapon:SetClip2( data.clip2 )
		ply:SetAmmo( data.ammo1, weapon:GetPrimaryAmmoType() )
		ply:SetAmmo( data.ammo2, weapon:GetSecondaryAmmoType() )
	end

	if t.curweapon then
		ply:SelectWeapon( t.curweapon )
	end
end

function autopilot.Unstuck(ply,npc)
	local pos = npc:GetPos()
	local mins,maxs = ply:OBBMins(),ply:OBBMaxs()
	//sphere trace for antistuck
	local hulltr = {start=pos+Vector(0,0,2), endpos=pos+Vector(0,0,2), mask=MASK_PLAYERSOLID, filter={npc,ply}}
	local stuck = util.TraceEntity(hulltr,ply)
	if stuck.StartSolid then
		local dist = 4
		local accuracy = 1
		local found = false
		hulltr.start=pos
		local function unstick()
			for x=1,-1,-accuracy do
				for y=1,-1,-accuracy do
					for z=1,-1,-accuracy do
						
						
						local dir = Vector(x,y,z)
						hulltr.endpos = hulltr.start + dir*dist
						
						local line = util.TraceLine(hulltr)
						if not line.Hit and not line.StartSolid then
							local trace= {start=hulltr.endpos, endpos=hulltr.endpos, mask=MASK_PLAYERSOLID, mins=mins, maxs=maxs, filter={ply,npc}}
							local htr = util.TraceHull(trace)
							
							if not htr.Hit and not htr.StartSolid then
								-- local a = SERVER and debugoverlay.Box(hulltr.endpos,mins,maxs,15,Color(0,255,0,100))
								pos = hulltr.endpos
								found = true
							end
						end
						
						-- local a = SERVER and debugoverlay.Line(hulltr.start,hulltr.endpos,15,Color(255,0,0))
						
						
						if found then break end
					end
					if found then break end
				end
				if found then break end
			end
		end
		repeat 
			unstick()
			dist = dist + 16
		until found or dist > 2000
	end
	
	return pos
end


-- if CLIENT then
	-- net.Receive("autopilot_ent",function()
		-- local ply,npc = net.ReadEntity(),net.ReadEntity()
		-- ply:SetAutoPilot( npc )
	-- end)
-- end

//Scan for player input.
hook.Add("StartCommand","ass_KeyFind",function(ply,cmd)
	
	buttons = cmd:GetButtons()
	
	if SERVER then
		if ply:Team() == TEAM_ASS then
			//Check for autopilot input
			if IsValid(ply:GetAutoPilot()) and !ply:GetAutoPilot():GetDisabled() then
			
				if (ply.AutopilotBeginTime or 0) < CurTime() - .7 then
					//Check if the player is trying to break away.
					if autopilot.FindKeys(cmd) then
						autopilot.Interrupt(ply)
					end
				end
				
			else
				//Alt key initiates autopilot
				if bit.band( buttons, IN_WALK ) == IN_WALK then
					autopilot.Begin(ply)
				end
			end
		end
		
	end
end)

//List of buttons which cause the player to exit autopilot.
local cancelButtons = {
	[IN_BACK] = true,
	[IN_DUCK] = true,
	[IN_FORWARD] = true,
	[IN_JUMP] = true,
	[IN_MOVELEFT] = true,
	[IN_MOVERIGHT] = true,
	-- [IN_SPEED] = true,
	[IN_USE] = true,
	-- [IN_ATTACK2] = true,
}
function autopilot.FindKeys(cmd)
	local btns = cmd:GetButtons()
	for k in pairs(cancelButtons)do
		if bit.band( btns, k ) == k then
			return k
		end
	end
end