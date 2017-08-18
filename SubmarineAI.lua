--config
local MAX_ROLL = 10


local AngularVelocity = {}
local Attitude = {}
local Control = {
		Pitch= {
			Positive= {},
			Negative= {},
		},
		Roll= {
			Positive= {},
			Negative= {},
		},
		Yaw= {
			Positive= {},
			Negative= {},
		}
	}

function SetHydrofoilControlType(I)
--makes a best guess as to which hydrofoils should be used for what, and assigns them to the correct control group
	local HydrofoilCount = I:Component_GetCount(8)
	local Extents = GetHydrofoilExtents(I)
	for i=0, HydrofoilCount -1, 1 do
		local BI = I:Component_GetBlockInfo(8,i)
		if BI.LocalRotation.z > 0 then
			if BI.LocalPositionRelativeToCom.z > 0 then
				Control["Yaw"]["Positive"][i] = i
			else
				Control["Yaw"]["Negative"][i] = i
			end
		end

		if BI.LocalPositionRelativeToCom.z == Extents["Positive"] then
			Control["Pitch"]["Positive"][i] = i
			break
		end
		if BI.LocalPositionRelativeToCom.z == Extents["Negative"] then
			Control["Pitch"]["Negative"][i] = i
			break
		end
		if !BI.LocalPositionRelativeToCom.z == Extents["Negative"] or !BI.LocalPositionRelativeToCom.z == Extents["Positive"] then 
			if BI.LocalPositionRelativeToCom.x > 0 then
				Control["Roll"]["Positive"][i] = i
			end
			if BI.LocalPositionRelativeToCom.x < 0 then
				Control["Roll"]["Negative"][i] = i
			end
		end
	end
		
	
end

function RollControl(I)
--Attempts to minimize roll during normal operation, and keep roll below the MAX_ROLL value during turning maneuvers.
	local roll = Attitude["Roll"]
	if roll > 180 then
		roll = roll - 360
	end
	local dot = 1
	if I:GetForwardsVelocityMagnitude() < 0 then
		dot = -1
	end
	for _,v in pairs(Control["Roll"]["Positive"]) do
		I:Component_SetFloatLogic(8,v, -roll*dot)
	end
	for _,v in pairs(Control["Roll"]["Negative"]) do
		I:Component_SetFloatLogic(8,v, roll*dot)
	end

end

function GetHydrofoilExtents(I)
-- returns the distance fore/aft of the furthest hydrofoils from CoM
	local Positive = 0
	local Negative = 0
	for i=0, I:Component_GetCount(8)-1, 1 do
		local position = I:Component_GetBlockInfo(8,i).LocalPositionRelativeToCom.z
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
--Returns an array containing the current pitch, roll, and yaw of the construct, in degrees
	Attitude["Pitch"] = I:GetConstructPitch()
	Attitude["Roll"] = I:GetConstructRoll()
	Attitude["Yaw"] = I:GetConstructYaw()
	return Attitude
end


function Update(I)
	--AngularVelocity is an array of angular velocities in radians/s
	-- X = Pitch, Y = Yaw, Z = Roll
	AngularVelocity = I:GetLocalAngularVelocity(I)
	Attitude = GetPitchRollYaw(I)
	SetHydrofoilControlType(I)
	RollControl(I)
	I:Log(I:Component_GetBlockInfo(8,0).LocalPositionRelativeToCom.x)
end
