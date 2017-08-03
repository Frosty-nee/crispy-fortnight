-- config
InterceptorWeaponSlot = 5
MissileTimeout = 6.0
IncomingMissiles = {}
AssignedMissiles = {}
TargetedMissiles = {}
function Update(I)
	IncomingMissiles = GetWarnings(I)
	LaunchedMissileCount = MissileCount(I)
	if I:GetNumberOfWarnings(0) > 0 then
		for i=LaunchedMissileCount, I:GetNumberOfWarnings(0)-1, 1 do
			FireInterceptor(I)
		end
	end
	if LaunchedMissileCount>table.getn(AssignedMissiles) then
		GiveMissilesTargets(I)
	end

	PurgeOldMissiles(I)
	PurgeInterceptorTargets(I)
end 


function GiveMissilesTargets(I)
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
						I:Log(I:GetLuaControlledMissileInfo(i,n).Id .. " -> " .. IncomingMissiles[u].Id)
						break
					end
				end
			end
		end	
	end
end


function GetWarnings(I)
--Returns an array of all missile warnings
	warnings = {}
	count = I:GetNumberOfWarnings(0)
	if count > 0 then
		for i=0 , count, 1 do
			warnings[i] = I:GetMissileWarning(0,i)
		end
	end
	return warnings
end


function PurgeInterceptorTargets(I)

end


function PurgeOldMissiles(I)
	for i=0, I:GetLuaTransceiverCount(),1 do
		for n=0, I:GetLuaControlledMissileCount(i), 1 do
			if I:GetLuaControlledMissileInfo(i,n).TimeSinceLaunch > MissileTimeout and I:IsLuaControlledMissileAnInterceptor(i,n) then
				AssignedMissiles[I:GetLuaControlledMissileInfo(i,n).Id] = nil
				I:DetonateLuaControlledMissile(i,n)
			end
		end
	end
end

function MissileCount(I)
	Count = 0
	for i=0, I:GetLuaTransceiverCount(), 1 do
		Count = Count + I:GetLuaControlledMissileCount(i)
	end
	return Count
end


function FireInterceptor(I)
--Fires first available missile interceptor
	for i=0, I:GetWeaponCount(),1 do
		if I:GetWeaponInfo(i).WeaponSlot == InterceptorWeaponSlot and I:FireWeapon(i, InterceptorWeaponSlot) then
			break
		end
	end
end
