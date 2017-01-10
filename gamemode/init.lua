
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("cl_gui.lua")
AddCSLuaFile("cl_stencil.lua")
AddCSLuaFile("cl_hud.lua")
AddCSLuaFile("cl_halos.lua")
AddCSLuaFile("cl_music.lua")
AddCSLuaFile("cl_fireworks.lua")
AddCSLuaFile("sh_rounds.lua")
AddCSLuaFile("sh_autopilot.lua")
AddCSLuaFile("sh_thirdperson.lua")
AddCSLuaFile("sh_grapple_hook.lua")
AddCSLuaFile("sh_chase.lua")
AddCSLuaFile("sh_animmodel.lua")
AddCSLuaFile("shared.lua")

include('shared.lua')
include("sh_rounds.lua")
include("sh_chase.lua")
include("sh_animmodel.lua")
include("sh_autopilot.lua")
include("sh_thirdperson.lua")
include("sh_grapple_hook.lua")

include("sv_player.lua")
include("sv_resources.lua")


// Serverside only stuff goes here

util.AddNetworkString("ass_assassinated")
util.AddNetworkString("ass_stunned")
util.AddNetworkString("ass_glassbreak")
util.AddNetworkString("ass_syncroundstates")
util.AddNetworkString("ass_intensity")

function CleanupEverything()
	game.CleanUpMap()
	
end

function GM:InitPostEntity()
	
end

function GM:CheckPassword( steamID64, ipAddress,svpw,clpw,name )
	if clpw == svpw then
		if #player.GetAll() + 1 >= game.MaxPlayers() and #player.GetBots() > 0 then
			player.GetBots()[1]:Kick()
		end
		return true
	else
		return false
	end
end

function GM:PlayerSay( ply, text, teamchat)
	
	//TEST:
	if text == "/bot" then
		if #player.GetAll()+2 >= game.MaxPlayers() then return "" end
		RunConsoleCommand("bot_zombie",1)
		RunConsoleCommand("bot")
		PrintMessage(HUD_PRINTTALK,"Added a bot to the game.")
		return ""
	end
	
	return text
end
concommand.Add("add_bot",function()
	RunConsoleCommand("bot")
	PrintMessage(HUD_PRINTTALK,"Added a bot to the game.")
	return ""
end)

function SpawnAllBystands()
	CLEAN_UP = true
	for k,v in pairs(ents.FindByClass("npc_*")) do v:Remove() end
	-- for k,v in pairs(ALL_CIVS) do v:Remove() end
	CLEAN_UP = false
	ALL_CIVS = {}
	
	print("Spawning all bystanders for the round.")
	
	local max = ConVars.Server.civCount:GetInt()
	local wander = math.floor(max*.80)
	-- local groups = math.floor(max*.20)
	local standgroups = math.floor(max*.20)
	for i=1, wander do
		local pos = FindBystandSpawnPos()
		if pos then
			local npc = ents.Create("npc_walking")--make a nextbot bystander.
			npc:SetGender(RandomGender())
			npc:SetModel( RandomModel(npc:GetGender()) )
			npc:SetPos(pos)
			npc:Spawn()
			npc:Activate()
		end
	end
	
	-- for i=1, groups do
	
		-- local pos = FindBystandSpawnPos("npc_group_leader")
		-- if pos then
			-- local lead = ents.Create("npc_group_leader")
			-- lead:SetMode(0)
			-- lead:SetPos(pos)
			-- lead:Spawn()
			-- lead:Activate()
			
			
			-- for j=1, math.random(3,ConVars.Server.groupSize:GetInt()) do
				-- local pos = FindBystandSpawnPos(100,nil,lead:GetPos())
				-- if pos then
					-- local npc = ents.Create("npc_walking")
					-- npc:SetGroupLeader(lead)
					-- local offset = VectorRand():GetNormalized() * 40 //Group spacing is 40 units.
					-- offset.z = 0
					-- npc:SetMode(1) //Make follow group.
					-- npc:SetGroupOffset(offset)
					-- npc:SetPos(pos)
					-- npc:SetGender(RandomGender())
					-- npc:SetModel(RandomModel(npc:GetGender()) )
					-- npc:Spawn()
					-- npc:Activate()
				-- end
			-- end
		-- end
	-- end
	
	for i=1, standgroups do
	
		local pos = FindBystandSpawnPos()
		if pos then
			local lead = ents.Create("npc_group_leader")
			lead:SetPos(pos)
			lead:Spawn()
			lead:Activate()
			lead:SetMode(1)
			
			
			for j=1, math.random(3,ConVars.Server.groupSize:GetInt()) do
				local pos = FindBystandSpawnPos(100,nil,lead:GetPos())
				if pos then
					local npc = ents.Create("npc_walking")
					npc:SetGroupLeader(lead)
					npc:SetGender(RandomGender())
					npc:SetModel(RandomModel(npc:GetGender()) )
					npc:Spawn()
					npc:Activate()
					local offset = VectorRand():GetNormalized() * 60 //Group spacing is 60 units.
					offset.z = 0
					npc:SetGroupOffset(offset)
					npc:SetPos(pos)
					npc:SetMode(1) //Make follow group.
				end
			end
		end
	end
	
	print("Spawned all bystanders for the round. Count: "..#ALL_CIVS..". (This will be different than ass_bystand_count due to group sizes.)")
end

function SpawnBystand()
	local pos = FindBystandSpawnPos()
	if pos then
		local npc = ents.Create("npc_walking")--make a nextbot bystander.
		npc:SetGender( RandomGender() )
		npc:SetModel( RandomModel(npc:GetGender()) )
		npc:SetPos(pos)
		npc:Spawn()
		npc:Activate()
	end
end

if not navmesh.IsLoaded() then
	NAV_AREAS = NAV_AREAS or {}
	timer.Create("navmesh_cache",.1,0,function()
		if navmesh.IsLoaded() then
			NAV_AREAS = navmesh.GetAllNavAreas()
			timer.Remove("navmesh_cache")
			hook.Run("PostNavmeshLoaded",NAV_AREAS)
		end
	end)
end
function FindBystandSpawnPos(spawnSpread,spreadOthers,pos)
	local newpos
	
	local fail = true
	
	local i = 1
	while fail and i<100 do
		if pos then
			newpos = VectorRand():GetNormalized()
			newpos.z = 0
			newpos = pos + newpos * math.random(spawnSpread/2, spawnSpread*2)
		else
			newpos = table.RandomSeq(NAV_AREAS):GetRandomPoint()
		end
		fail = not util.IsInWorld(newpos)
		if not fail then
			local a = navmesh.GetNearestNavArea(newpos)
			fail = fail or not IsValid(a)
			fail = fail or a:IsUnderwater()
			fail = fail or a:HasAttributes(NAV_MESH_AVOID)
			fail = fail or a:HasAttributes(NAV_MESH_STAIRS)
			
			if isstring(spawnSpread) and spawnSpread == "npc_group_leader" then
				fail = fail or a:HasAttributes(NAV_MESH_NO_HOSTAGES)
			end
			
			if not fail then
				newpos = a:GetRandomPoint()+Vector(0,0,3)
				fail = fail or not bit.band( util.PointContents( newpos ), CONTENTS_EMPTY ) == CONTENTS_EMPTY
				
				if not fail then
					if spreadOthers then
						for k,v in pairs(ents.FindInSphere(newpos,spreadOthers))do
							if v:GetClass()=="npc_group_leader" then
								fail = true
							end
						end
					end
					
					if not fail then
						local hull = {mins=Vector(-16,-16,0),maxs=Vector(16,16,72),mask=MASK_SOLID}
						local traces = {}
						if not fail then
							hull.start = newpos
							hull.endpos = newpos
							
							trace = util.TraceHull(hull)
							
							fail = fail or trace.Hit
							-- if outsideOnly then
								-- fail = fail or not trace.HitSky
							-- end
						end
					end
				end
			end
		end
		i=i+1
	end
	
	if i>=100 then return false end
	
	return newpos
	
end
