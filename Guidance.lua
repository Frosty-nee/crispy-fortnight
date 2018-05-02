--config

ActiveMissileTargets = {}
ActiveMissileDistance = {}
HistoricalTargetLocations = {}

function ActiveMissileUpdate(I)
	for i=0,I:GetLuaTransceiverCount(), 1 do
		for o=0, I:GetLuaControlledMissileCount(i), 1 do
			local warning = I:GetLuaControlledMissileInfo(i,o)
			-- don't add interceptors or null missiles to the list 
			if warning.Id ~= 0 and I:IsLuaControlledMissileAnInterceptor(i,o) == false then
				ActiveMissiles[warning.Id] = warning
			end
		end
	end	
end

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
			local missile = I:GetLuaControlledMissileInfo(i,o)
			if ActiveMissileTargets[missile.Id] == nil then
				ActiveMissileTargets[missile.Id] = HighScoreId
			end
		end
	end
end

function UpdateTargetList(I)
	for i=0,I:GetNumberOfMainframes(),1 do
		for o=0, I:GetNumberOfTargets(i),1 do
			local tgt = I:GetTargetInfo(i,o)
			if tgt.Id ~= 0 then
				Targets[tgt.Id] = tgt
			end
		end
	end
end

function UpdateTargetLocations(I, Targets)
	for k,v in pairs(Targets) do
		if HistoricalTargetLocations[k] == nil then
			HistoricalTargetLocations[k] = {}
			HistoricalTargetLocations[k][0] = 0
			--I:Log(HistoricalTargetLocations[k][0])
			--I:Log(#HistoricalTargetLocations[k])
		end
		local index = HistoricalTargetLocations[k][0] % 40 + 1
		HistoricalTargetLocations[k][index] = v
		HistoricalTargetLocations[k][0] = HistoricalTargetLocations[k][0] + 1
	end
end

function AimpointUpdate(I, TIndex, MIndex)
	local missile = I:GetLuaControlledMissileInfo(TIndex,MIndex)
	local tgt = Targets[ActiveMissileTargets[missile.Id]]
	if tgt ~= nil then
		local x,y,z = TargetNavigationPrediction(I,tgt, EstimateTimeToImpact(I,tgt,missile))
		I:SetLuaControlledMissileAimPoint(TIndex,MIndex, x, y, z)
		if Vector3.Distance(missile.Position, tgt.Position) < 10 then
			distance = Vector3.Distance(tgt.Position, missile.Position)
			if ActiveMissileDistance[missile.Id] ~= nil and distance > ActiveMissileDistance[missile.Id] then
				I:DetonateLuaControlledMissile(TIndex,MIndex)
			end
			ActiveMissileDistance[missile.Id] =	distance
		end
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

function EstimateTimeToImpact(I,TargetInfo, missile)
	-- distances are in meters, velocities are in m/s
	local rvel = TargetInfo.Velocity - missile.Velocity
	return Vector3.Distance(TargetInfo.Position, missile.Position)
	/ Mathf.Sqrt(Mathf.Pow(rvel.x,2) + Mathf.Pow(rvel.y,2) + Mathf.Pow(rvel.z,2))
end

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

function Update(I)
	Targets = {}
	UpdateTargetList(I)
	UpdateTargetLocations(I, Targets)
	AssignMissileTargets(I)
	for i=0, I:GetLuaTransceiverCount(), 1 do
		for o=0, I:GetLuaControlledMissileCount(i), 1 do
			AimpointUpdate(I,i,o)
		end
	end
	RemoveOldVelocityData()
end