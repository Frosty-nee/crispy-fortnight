-- config
local InterceptorWeaponSlot = 5
local MissileTimeout = 6.0
local IncomingMissiles = {}
local AssignedMissiles = {}
local TargetedMissiles = {}

local function GiveMissilesTargets(I)
	for i=0, I:GetLuaTransceiverCount(),1 do
		for n=0, I:GetLuaControlledMissileCount(i),1 do

			--If a Missile has already been targeted by us, skip it
			if not AssignedMissiles[I:GetLuaControlledMissileInfo(i,n).Id] then
				for u=0, table.getn(IncomingMissiles)-1, 1 do

					--don't target multiple interceptors at the same thing
					if not TargetedMissiles[IncomingMissiles[u].Id] then
						I:SetLuaControlledMissileInterceptorTarget(i,n,0,u)
						TargetedMissiles[IncomingMissiles[u].Id] = IncomingMissiles[u]
						AssignedMissiles[I:GetLuaControlledMissileInfo(i,n).Id] = IncomingMissiles[u].Id
						break
					end
				end
			end
		end
	end
end

local function GetWarnings(I)
	--Returns an array of all missile warnings
	local warnings = {}
	local count = I:GetNumberOfWarnings(0)
	if count > 0 then
		for i=0 , count, 1 do
			warnings[i] = I:GetMissileWarning(0,i)
		end
	end
	return warnings
end

local function PurgeInterceptorTargets(I)
	--Remove targets that no longer exist
	for k,_ in pairs(TargetedMissiles) do
		for i=0,table.getn(IncomingMissiles)-1,1 do
			if k == IncomingMissiles[i].Id then
				break
			end
		I:Log("removing: ".. IncomingMissiles[i].Id)
		table.remove(TargetedMissiles, IncomingMissiles[i].Id)
		end
	end
end

local function PurgeOldMissiles(I)
	for i=0, I:GetLuaTransceiverCount(),1 do
		for n=0, I:GetLuaControlledMissileCount(i), 1 do
			local timedOut = I:GetLuaControlledMissileInfo(i,n).TimeSinceLaunch > MissileTimeout
			if timedOut and I:IsLuaControlledMissileAnInterceptor(i,n) then
				AssignedMissiles[I:GetLuaControlledMissileInfo(i,n).Id] = nil
				I:DetonateLuaControlledMissile(i,n)
			end
		end
	end
end

local function MissileCount(I)
	local count = 0
	for i=0, I:GetLuaTransceiverCount(), 1 do
		count = count + I:GetLuaControlledMissileCount(i)
	end
	return count
end

local function FireInterceptor(I)
	--Fires first available missile interceptor
	for i=0, I:GetWeaponCount(),1 do
		if I:GetWeaponInfo(i).WeaponSlot == InterceptorWeaponSlot and I:FireWeapon(i, InterceptorWeaponSlot) then
			break
		end
	end
end

function Update(I)
	IncomingMissiles = GetWarnings(I)
	local LaunchedMissileCount = MissileCount(I)
	if I:GetNumberOfWarnings(0) > 0 then
		for _=LaunchedMissileCount, I:GetNumberOfWarnings(0)-1, 1 do
			FireInterceptor(I)
		end
	end
	if LaunchedMissileCount>table.getn(AssignedMissiles) then
		GiveMissilesTargets(I)
	end

	PurgeOldMissiles(I)
	PurgeInterceptorTargets(I)
	I:Log(table.getn(TargetedMissiles))
end
