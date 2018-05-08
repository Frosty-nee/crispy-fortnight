--config
InterceptorWeaponGroup = 5 -- set this to whatever weapon group your anti-missile systems are on
InterceptorTimeout = 3 -- seconds until interceptor auto-destructs.


function MissileWarnings(I)
	Warnings = {}
	for i=0, I:GetNumberOfMainframes(), 1 do
		if I:GetNumberOfWarnings(i) > 0 then
			for o=0, I:GetNumberOfWarnings(i), 1 do
				if I:GetMissileWarning(i,o).Valid then
					table.insert(Warnings, I:GetMissileWarning(i,o))
				end
			end
		end
	end
	return Warnings
end

function GetActiveInterceptors(I)
	Interceptors = {}
	for i=0, I:GetLuaTransceiverCount(), 1 do
		for o=0, I:GetLuaControlledMissileCount(i), 1 do 
			if I:IsLuaControlledMissileAnInterceptor(i,o) then
				table.insert(Interceptors, {i, o, I:GetLuaControlledMissileInfo(i,o)})
			end
		end
	end
	return Interceptors
end

function FireInterceptor(I)
	for i=0 ,I:GetWeaponCount(), 1 do
		WInfo = I:GetWeaponInfo(i)
		if WInfo.WeaponSlot == InterceptorWeaponGroup then
			if I:FireWeapon(i,InterceptorWeaponGroup) then
				break
			end
		end
	end
		
end

function KillOldInterceptors(I)
	for i=0,I:GetLuaTransceiverCount(), 1 do
		for o=0, I:GetLuaControlledMissileCount(i), 1 do
			if I:IsLuaControlledMissileAnInterceptor(i,o) and I:GetLuaControlledMissileInfo(i,o).TimeSinceLaunch > InterceptorTimeout then
				I:DetonateLuaControlledMissile(i,o)
			end
		end
	end
end

function Update(I) 
	KillOldInterceptors(I)
	Warnings = MissileWarnings(I)
	Interceptors = GetActiveInterceptors(I)
	for i=#Interceptors, #Warnings, 1 do
		FireInterceptor(I)
	end
end