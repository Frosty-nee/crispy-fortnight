local Attitude = {Pitch=0, Roll=0, Yaw=0}
local Control = {
		Pitch: {
			Positive: {}
			Negative: {}
		}
		Roll: {
			Positive: {}
			Negative: {}
		}
		Yaw: {
			Positive: {}
			Negative: {}
		}
	}

function SetHydrofoilControlType(I)
	local HydrofoilCount = I:Component_GetCount(8)
	local Extents = GetHydrofoilExtents(I)
	for i=0, HydrofoilCount -1, 1 do
		local BlockInfo = I:GetComponent_BlockInfo(8,i)
		if BlockInfo.LocalRotation.z > 0 then
			if I:GetComponent_BlockInfo.LocalPositionRelativeToCom.z > 0 then
				Control[Yaw[Positive[i]]] = i
			else
				Control[Yaw[Negative[i]]] = i
			end
		end
		if BlockInfo.LocalPositionRelativeToCom.z == Extents[Positive] then
			Control[Pitch[Positive[i]]] = i
		end
		if BlockInfo.LocalPositionRelativeToCom.z == Extents[Negative] then
			Control[Pitch[Positive[i]]] = i
		end
		if BlockInfo.LocalPositionRelativeToCom.x > 0 then
			Control[Roll[Positive[i]]] = i
		end
		if BlockInfo.LocalPositionRelativeToCom.x < 0 then
			Control[Roll[Negative[i]]] = i
		end
	end
		
	
end

function GetHydrofoilExtents(I)
	local Positive = 0
	local Negative = 0
	for i=0, I:Component_GetCount(8)-1, 1 do
		local position = I:GetComponent_BlockInfo(8,i).LocalPositionRelativeToCom.z
		if pos > Positive then
			Positive = position
		end
		if position < Negative then
			Negative = position
		end
	end
	return {Positive, Negative}
end

function GetPitchRollYaw(I) 
	Attitude["Pitch"] = I:GetConstructPitch()
	Attitude["Roll"] = I:GetConstructRoll()
	Attitude["Yaw"] = I:GetConstructYaw()
	return Attitude
end


function Update(I)
	Attitude = GetPitchRollYaw(I)
	I:LogToHud(Attitude["Yaw"])
end
