-- config
InterceptorWeaponSlot = 5
IncomingMissiles = {}
TargetedMissiles = {}
function Update(I)

	InterceptorLaunchers = GetLaunchers(I)
	IncomingMissiles = GetWarnings(I)
	ControlledMissiles = GetControlledMissiles(I)

	if table.getn(IncomingMissiles) > 0 then
		for i=0, table.getn(IncomingMissiles)-1, 1 do
			FireInterceptor(I)
			ControlledMissiles = GetControlledMissiles(I)
			I:SetLuaControlledMissileInterceptorTarget(0, table.getn(ControlledMissiles)-1 , 0, IncomingMissiles[i].Id)

		end
	end
end


function GetWarnings(I)
--Returns an array of all missile warnings
	warnings = {}
	count = I:GetNumberOfWarnings(0)
	if count > 0 then
		for i=0 , count-1, 1 do
			warnings[i] = I:GetMissileWarning(0,i)
		end
	end
	return warnings
end

function CheckWarningStatus(I)
--Checks each specific incoming missile and updates hostile missile array accordingly
end


function GetControlledMissiles(I)
	count = I:GetLuaControlledMissileCount(0)
 	missiles = {}
	for i=0, count-1, 1 do
		if I:IsLuaControlledMissileAnInterceptor(0,i) then
			table.insert(missiles, i,I:GetLuaControlledMissileInfo) 
			
		end
	end
	return missiles
			
end



function FireInterceptor(I)
--Fires first available missile interceptor
	Count = I:GetWeaponCount()
	Weapons = {}
	for i=0,Count-1 do
		table.insert(Weapons, i, I:GetWeaponInfo(i))
	end
	for i=0,table.getn(Weapons)-1, 1 do
		if Weapons[i].WeaponSlot == 5 then
			if I:FireWeapon(i,5) == then
				break
			end
		end
	end
end
