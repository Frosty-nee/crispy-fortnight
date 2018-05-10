--config

ActiveMissileDistance = {}
--both of these next two map Missile Id's to Target Id's
ActiveMissileTargets = {}
ActiveInterceptorTargets = {}

HistoricalTargetLocations = {}

function AssignMissileTargets(I)
--not sure how to do this well yet
--might need config options to set how much to spread missiles among targets
	local MaxScore = 0
	local HighScoreId = nil
	for k,v in pairs(Targets) do
		if v.Score > MaxScore then
			MaxScore = v.Score
			HighScoreId = v.Id
		end
	end
	for i=0, I:GetLuaTransceiverCount(), 1 do
		for o=0, I:GetLuaControlledMissileCount(i), 1 do
			local Missile = I:GetLuaControlledMissileInfo(i,o)
			if ActiveMissileTargets[Missile.Id] == nil and I:IsLuaControlledMissileAnInterceptor(i,o) == false then
				ActiveMissileTargets[Missile.Id] = HighScoreId
			end
			-- only target one interceptor per Missile warning
			if I:IsLuaControlledMissileAnInterceptor(i,o) and ActiveInterceptorTargets[Missile.Id] == nil then
				--find a warning without an associated interceptor
				for _,warn in pairs(Warnings) do
					local T = false
					for _,v in pairs(ActiveInterceptorTargets) do 
						if warn.Id == v then
							T = true
						end
					end
					-- if T is false we know this warning hasn't been assigned an interceptor yet
					if T == false then
						ActiveInterceptorTargets[Missile.Id] = warn
						break
					end
				end
			end
		end
	end
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


function GetWarningIndexById(I, Id)
	local MIndex = nil
	local WIndex = nil
	for i=0, I:GetNumberOfMainframes(), 1 do
		for o=0, I:GetNumberOfWarnings(i), 1 do
			local Warn = I:GetMissileWarning(i,o)
			if Warn.Id == Id then
				MIndex, WIndex = i, o 
				break
			end
		end
	end
	return MIndex, WIndex
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
	local ttl = Mathf.Min(6,TimeToImpact)
	averagex, averagey, averagez = AverageTargetVelocity(TargetInfo)
	local mainframe, targetindex = GetTargetIndexById(I, Id)
	local x,y,z = TargetInfo.Position.x + averagex*ttl, TargetInfo.Position.y + averagey*ttl, TargetInfo.Position.z + averagez*ttl
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

function AimpointUpdate(I, TIndex, MIndex, Target)
	local Missile = I:GetLuaControlledMissileInfo(TIndex, MIndex)
	if I:IsLuaControlledMissileAnInterceptor(TIndex, MIndex) then
		Target = Warnings[ActiveInterceptorTargets[Missile.Id]]
		I:SetLuaControlledMissileInterceptorStandardGuidanceOnOff(TIndex, MIndex, false)
	else
		Target = Targets[ActiveMissileTargets[Missile.Id]]
	end
	if Target ~= nil then
		local x,y,z = TargetNavigationPrediction(I,Target, EstimateTimeToImpact(I,Target,Missile))
		I:Log(x)
		I:SetLuaControlledMissileAimPoint(TIndex, MIndex, x, y, z)
		if Vector3.Distance(Missile.Position, Target.Position) < 10 then
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
	UpdateTargetLocations(I, Targets)
	Warnings = UpdateMissileWarnings(I)
	AssignMissileTargets(I)
	for i=0, I:GetLuaTransceiverCount(), 1 do
		for o=0, I:GetLuaControlledMissileCount(i), 1 do
			if I:IsLuaControlledMissileAnInterceptor(i,o) then
				AimpointUpdate(I, i, o, ActiveInterceptorTargets[I:GetLuaControlledMissileInfo(i,o)].Id)
			else
				AimpointUpdate(I, i, o, Targets[ActiveMissileTargets[I:GetLuaControlledMissileInfo(i,o).Id]])
			end
		end
	end
	RemoveOldVelocityData()
end