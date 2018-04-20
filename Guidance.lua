--config

ActiveMissileTargets = {}

function ActiveMissileUpdate(I)
	ActiveMissiles[0] = nil
	for i=0,I:GetLuaTransceiverCount(), 1 do
		for o=0, I:GetLuaControlledMissileCount(i), 1 do
			local warning = I:GetLuaControlledMissileInfo(i,o)
			-- don't add interceptors or null missiles to the list 
			if warning.Id ~= 0 and I:IsLuaControlledMissileAnInterceptor(i,o) == false then
				ActiveMissileTargets[warning.Id] = nil
				ActiveMissiles[warning.Id] = warning
			end
		end
	end	
end

function AssignMissileTargets(I)
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

function RemoveOldMissileTargets(I)
	for k,v in pairs(ActiveMissileTargets) do
		if ActiveMissiles[k] == nil then
			ActiveMissileTargets[k] = nil
		end
	end
end

function Update(I)
	ActiveMissiles = {} -- clears old missiles that are no longer active
	Targets = {}

	ActiveMissileUpdate(I)
	UpdateTargetList(I)
	AssignMissileTargets(I)
	for k,v in pairs(ActiveMissiles) do
		I:LogToHud("missileid: " .. tostring(k) .. "tgt: " .. ActiveMissileTargets[k])
	end
end