--config


--setup
HydrofoilCount = 0

function AssignHydrofoilAxes(I)
	-- frontleft, frontright, backleft, backright
	axes = {}
	axes[0], axes[1], axes[2], axes[3] = {}, {}, {}, {}

	for i=0, I:Component_GetCount(8), 1 do
		right, front = true, true
		pos = I:Component_GetBlockInfo(8, i).LocalPositionRelativeToCom
		if pos.x < 0 then
			right = false
		end
		if pos.z < 0 then
			front = false
		end

		if right and front then
			table.insert(axes[1], i)
		end
		if right and not front then
			table.insert(axes[3], i)
		end
		if not right and front then
			table.insert(axes[0], i)
		end
		if not right and not front then
			table.insert(axes[2], i)
		end
	end
	return axes
end

function BalanceRoll(I, axes)
	-- roll to right counts down from 360, to left counts up from 0
	roll = I:GetConstructRoll()
	if roll > 180 then
		roll = -1.0 * math.abs(360-roll)
	end
	for a=0, 3, 1 do
		--for each table
		for i=0, table.getn(axes[a]), 1 do
			--set each hydrofoil to the appropriate angle multiplied by the appropriate mod
			if a%2 == 1 then
				mod = -1
			else
				mod = 1
			end
			
			I:Component_SetFloatLogic(8, axes[a][i], mod * roll * 4)
		end
	end
end
			
		


function Update(I)
	if HydrofoilCount ~= I:Component_GetCount(8) then
		HydrofoilAxes = AssignHydrofoilAxes(I)
		HydrofoilCount = I:Component_GetCount(8)
	end

	AttitudeControl(I)
end
