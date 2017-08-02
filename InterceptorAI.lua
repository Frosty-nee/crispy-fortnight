-- config
InterceptorWeaponSlot = 5
IncomingMissiles = {}
TargetedMissiles = {}
function Update(I)
	InterceptorLaunchers = GetLaunchers(I)
	IncomingMissiles = GetWarnings(I)
	

	PurgeOldMissiles(I)
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



function PurgeOldMissiles(I)
	for i=0, I:GetLuaTransceiverCount(),1 do
		for n=0, I:GetLuaControlledMissileCount(i), 1 do
			if I:GetLuaControlledMissileInfo(i,n).TimeSinceLaunch > 3.0 then
				if I:IsLuaControlledMissileAnInterceptor(i,n) then
					I:DetonateLuaControlledMissile(i,n)
				end
			end
		end
	end
end


function FireInterceptor(I)
--Fires first available missile interceptor
	Weapons = {}
	for i=0,I:GetWeaponCount()-1, 1 do
		table.insert(Weapons, i, I:GetWeaponInfo(i))
	end
	for i=0, table.getn(Weapons)-1, 1 do
		if Weapons[i].WeaponSlot == InterceptorWeaponSlot then
			if I:FireWeapon(i, InterceptorWeaponSlot) then
				break
			end
		end
	end
end
