--config
--set this to the subconstruct ID of the spin block you place to control heading
heading_spinner_id = 5

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
	vel_vector = Mathf.Sign(I:GetForwardsVelocityMagnitude())
    roll = I:GetConstructRoll()
    if roll > 180 then
        roll = -1.0 * math.abs(360.0-roll)
    end
    for a=0, 3, 1 do
        --for each table
        for i=1, table.getn(axes[a]), 1 do
            --set each hydrofoil to the appropriate angle multiplied by the appropriate mod
            if a%2 == 1 then
                mod = -1
            else
 
                mod = 1
            end
            I:Component_SetFloatLogic(8, axes[a][i], mod * vel_vector * roll * 4)
        end
    end
end

function MaintainHeading(I)
	if I:Component_GetCount(1) > 0 then
		-- gets a value from the first drive maintainer (-1 to 1) and maps it to a requested headin
		requested_heading = (I:GetSubConstructInfo(heading_spinner_id).LocalRotation.w / 2 + 0.5) * 360
		actual_heading = I:GetConstructYaw()
	end
	I:LogToHud(string.format('Requested: %.2f', requested_heading))
	
	magnitude = math.abs(requested_heading - actual_heading)
	--positive is a right turn, negative is a left turn
	direction = Mathf.Sign(requested_heading - actual_heading)
	if magnitude > 180 then
		magnitude = math.abs(magnitude - 360)
		direction = direction * -1
	end
	--invert direction if moving backwards
	if Mathf.Sign(I:GetForwardsVelocityMagnitude()) < 0 then
		direction = direction * -1
	end
	if direction > 0 then
		I:RequestControl(0, 1, magnitude/180)
	else
		I:RequestControl(0,0, magnitude/180)
	end
end

	function Update(I)
    if HydrofoilCount ~= I:Component_GetCount(8) then
        HydrofoilAxes = AssignHydrofoilAxes(I)
        HydrofoilCount = I:Component_GetCount(8)
    end

	BalanceRoll(I, HydrofoilAxes)
	MaintainHeading(I)
end
