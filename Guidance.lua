--config
MaxLookaheadTime = 6 	-- max time to project missile target position forward in time
MultiTargetFactor = nil -- how much to spread missiles among valid targets, not implemented yet
--end config

ActiveMissileDistance = {}
ActiveMissileTargets = {}
ActiveInterceptorTargets = {}

HistoricalTargetLocations = {}

function AssignMissileTargets(I)
--not sure how to do this well yet
--might need config options to set how much to spread missiles among targets
	local MaxScore = 0
	local HighScore = nil
	for k,v in pairs(Targets) do
		if v.Score > MaxScore then
			MaxScore = v.Score
			HighScore = v
		end
	end
	for i=0, I:GetLuaTransceiverCount(), 1 do
		for o=0, I:GetLuaControlledMissileCount(i), 1 do
			local Missile = I:GetLuaControlledMissileInfo(i,o)
			if ActiveMissileTargets[Missile.Id] == nil and not I:IsLuaControlledMissileAnInterceptor(i,o) then
				ActiveMissileTargets[Missile.Id] = HighScore
			end
			-- only target one interceptor per Missile warning
			if I:IsLuaControlledMissileAnInterceptor(i,o) and ActiveInterceptorTargets[Missile.Id] == nil then
				--find a warning without an associated interceptor
				warn = GetTargetForInterceptor()
				if warn ~= nil then 
					ActiveInterceptorTargets[Missile.Id] = warn
				end
			end
		end
	end
end

function GetTargetForInterceptor()
	for _,warn in pairs(Warnings) do
		if not WarningAlreadyAssignedInterceptor(warn) then
			return warn
		end
	end
end

function WarningAlreadyAssignedInterceptor(Warning)
	for k,v in pairs(ActiveInterceptorTargets) do
		if v.Id == Warning.Id then
			return true
		end
	end
	return false
end

function UpdateTargetList(I)
	for i=0,I:GetNumberOfMainframes(),1 do
		for o=0, I:GetNumberOfTargets(i),1 do
			local Target = I:GetTargetInfo(i,o)
			if Target.Id ~= 0 then
				Targets[Target.Id] = Target
			end
		end
	end
end

function UpdateMissileWarnings(I) 
	local Warnings = {}
	for i=0, I:GetNumberOfMainframes(), 1 do 
		for o=0, I:GetNumberOfWarnings(i), 1 do
			local Warn = I:GetMissileWarning(i,o)
			if Warn.Valid then
				Warnings[Warn.Id] = Warn
			end
		end
	end
	return Warnings	
end

function UpdateTargetLocations(I, Targets)
	for k,v in pairs(Targets) do
		if HistoricalTargetLocations[k] == nil then
			HistoricalTargetLocations[k] = {}
			HistoricalTargetLocations[k][0] = 0
		end
		local Index = HistoricalTargetLocations[k][0] % 40 + 1
		HistoricalTargetLocations[k][Index] = v
		HistoricalTargetLocations[k][0] = HistoricalTargetLocations[k][0] + 1
	end
end


function GetTargetIndexById(I, Id)
	for indx=0, I:GetNumberOfMainframes(), 1 do
		for o=0, I:GetNumberOfTargets(indx), 1 do
			local target = I:GetTargetInfo(indx,o)
			if target.Id == Id then
				return indx, o
			end
		end
	end
end

function RemoveOldVelocityData()
	for k,_ in pairs(HistoricalTargetLocations) do
		if Targets[k] == nil then
			HistoricalTargetLocations[k] = nil
		end
	end
end

function EstimateTimeToImpact(I,TargetInfo, Missile)
	-- distances are in meters, velocities are in m/s
	local rvel = TargetInfo.Velocity - Missile.Velocity
	return Vector3.Distance(TargetInfo.Position, Missile.Position)
	/ Mathf.Sqrt(Mathf.Pow(rvel.x,2) + Mathf.Pow(rvel.y,2) + Mathf.Pow(rvel.z,2))
end

--still need to scale the timeframe we're averaging over based on time to impact
--to reduce the effect of long periods of straight flight followed by a sudden turn
function TargetNavigationPrediction(I, TargetInfo, TimeToImpact)
	local ttl = Mathf.Min(MaxLookaheadTime,TimeToImpact)
	averagex, averagey, averagez = AverageTargetVelocity(TargetInfo)
	local x,y,z = TargetInfo.Position.x + averagex*ttl, TargetInfo.Position.y + averagey*ttl, TargetInfo.Position.z + averagez*ttl
	return x,y,z
end

function InterceptorNavigationPrediction(I, TargetInfo, TimeToImpact)
	local ttl = Mathf.Min(MaxLookaheadTime, TimeToImpact)
	local x,y,z = TargetInfo.Position.x + TargetInfo.Velocity.x*ttl, TargetInfo.Position.y + TargetInfo.Velocity.y*ttl, TargetInfo.Position.z + TargetInfo.Velocity.z*ttl
	return x,y,z
end

function AverageTargetVelocity(TargetInfo)
	local x,y,z = 0,0,0
	if #HistoricalTargetLocations[TargetInfo.Id] > 0 then
		for i = 1, #HistoricalTargetLocations[TargetInfo.Id] - 1, 1 do
			v = HistoricalTargetLocations[TargetInfo.Id][i].Velocity
			x,y,z = x + v.x, y + v.y, z + v.z
		end
		return x/40, y/40, z/40
	end
end

function AimpointUpdate(I, TIndex, MIndex, Target, Interceptor)
	local Missile = I:GetLuaControlledMissileInfo(TIndex, MIndex)

	if Target ~= nil then
		local x,y,z = nil
		if Interceptor then 
			x,y,z = InterceptorNavigationPrediction(I, Target, EstimateTimeToImpact(I,Target,Missile))
		else
			x,y,z = TargetNavigationPrediction(I,Target, EstimateTimeToImpact(I,Target,Missile))
		end
		I:SetLuaControlledMissileAimPoint(TIndex, MIndex, x, y, z)
		-- only detonate for near misses on non-interceptors	
		if Vector3.Distance(Missile.Position, Target.Position) < 10 and not Interceptor then
			distance = Vector3.Distance(Target.Position, Missile.Position)
			if ActiveMissileDistance[Missile.Id] ~= nil and distance > ActiveMissileDistance[Missile.Id] then
				I:DetonateLuaControlledMissile(TIndex, MIndex)
			end
			ActiveMissileDistance[Missile.Id] =	distance
		end
	end
end

function Update(I)
	Targets = {}
	UpdateTargetList(I)
	Warnings = UpdateMissileWarnings(I)
	UpdateTargetLocations(I, Targets)
	AssignMissileTargets(I)

	for i=0, I:GetLuaTransceiverCount(), 1 do
		for o=0, I:GetLuaControlledMissileCount(i), 1 do
			if I:IsLuaControlledMissileAnInterceptor(i,o) then
				I:SetLuaControlledMissileInterceptorStandardGuidanceOnOff(i,o, false)
				--this is dumb fix this convoluted nested tables thing later
				--go back to just tracking Id's, basically.
				if ActiveInterceptorTargets[I:GetLuaControlledMissileInfo(i,o).Id] ~= nil then
					AimpointUpdate(I, i, o, Warnings[ActiveInterceptorTargets[I:GetLuaControlledMissileInfo(i,o).Id].Id], true)
				end
			else
				if ActiveMissileTargets[I:GetLuaControlledMissileInfo(i,o).Id] ~= nil then
					AimpointUpdate(I, i, o, Targets[ActiveMissileTargets[I:GetLuaControlledMissileInfo(i,o).Id].Id], false)
				end
			end
		end
	end
	RemoveOldVelocityData()
end