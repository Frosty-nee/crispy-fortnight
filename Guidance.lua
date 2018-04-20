--config

ActiveMissileTargets = {}

function ActiveMissileUpdate(I)
	ActiveMissiles[0] = nil
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

function AssignMissileTargets()
--not sure how to do this well yet
--might need config options to set how much to spread missiles among targets
	for k,_ in pairs(ActiveMissiles) do
		ActiveMissileTargets[k] = 15486		
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

function RemoveOldMissileTargets()
	for k,v in pairs(ActiveMissileTargets) do
		if ActiveMissiles[k] == nil then
			ActiveMissileTargets[k] = nil
		end
	end
end

function AimpointUpdate(I,TIndex, MIndex)
	local missile = I:GetLuaControlledMissileInfo(TIndex,MIndex)
	local tgt = Targets[ActiveMissileTargets[missile.Id]]
	if tgt ~= nil then
		I:Log(tgt.Id .. tgt.Position.x .. tgt.Position.y .. tgt.Position.z)
		I:SetLuaControlledMissileAimPoint(TIndex,MIndex,tgt.Position.x,tgt.Position.y,tgt.Position.z)
	end
end

function Update(I)
	ActiveMissiles = {} -- clears old missiles that are no longer active
	Targets = {}

	UpdateTargetList(I)
	ActiveMissileUpdate(I) --has to be called before AssignMissileTargets
	AssignMissileTargets()
	for i=0, I:GetLuaTransceiverCount(), 1 do
		for o=0, I:GetLuaControlledMissileCount(i), 1 do
			AimpointUpdate(I,i,o)
		end
	end
end