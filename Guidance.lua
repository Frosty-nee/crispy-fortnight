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
		end
		table.insert(HistoricalTargetLocations[k], v)
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

function GetTargetInfoById(I, Id)
	for indx=0, I:GetNumberOfMainframes(), 1 do
		for o=0, I:GetNumberOfTargets(indx), 1 do
			local target = I:GetTargetInfo(indx,o)
			if target.Id == Id then
				return indx, o
			end
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
	local ttl = Mathf.Min(5,TimeToImpact)
	local mainframe, targetindex = GetTargetInfoById(I, Id)
	local x,y,z = TargetInfo.Position.x + TargetInfo.Velocity.x*ttl, TargetInfo.Position.y + TargetInfo.Velocity.y*ttl, TargetInfo.Position.z + TargetInfo.Velocity.z*ttl
	return x,y,z
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
end