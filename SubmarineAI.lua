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
		--If hydrofoil is vertical, we know it's used for yaw
		if BI.LocalRotation.z > 0 then
			if BI.LocalPositionRelativeToCom.z > 0 then
				Control["Yaw"]["Positive"][i] = i
			else
				Control["Yaw"]["Negative"][i] = i
			end
		
		--if not, check to see if its distance from CoM is the same as the furthest hydrofoils from CoM
		--if yes, we know it's used for pitch control
		--I have no idea why these are off by 1, but at least this is an "easy" fix?
		elseif BI.LocalPositionRelativeToCom.z == Extents["Positive"]-1 or BI.LocalPositionRelativeToCom.z == Extents["Negative"]+1 then
			if BI.LocalPositionRelativeToCom.z == Extents["Positive"]-1 then
				Control["Pitch"]["Positive"][i] = i
			else
				Control["Pitch"]["Negative"][i] = i
			end
		--if not, it has to be roll control
		else 
			if BI.LocalPositionRelativeToCom.x > 0 then
				Control["Roll"]["Positive"][i] = i
			else
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
	local PE = 0
	local NE = 0
	for i=0, I:Component_GetCount(8)-1, 1 do
		local position = I:Component_GetBlockInfo(8,i).LocalPositionRelativeToCom.z
		if position > PE then
			PE = position
		end
		if position < NE then
			NE = position
		end
	end
	return {Positive=PE, Negative=NE}
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
