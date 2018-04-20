--config

ActiveMissileTargets = {}

function ActiveMissileUpdate(I)
	ActiveMissiles[0] = nil
	for i=0,I:GetLuaTransceiverCount(), 1 do
		for o=0, I:GetLuaControlledMissileCount(i), 1 do
			warning = I:GetLuaControlledMissileInfo(i,o)
			if warning.Id ~= 0 then
				ActiveMissileTargets[warning.Id] = nil
				ActiveMissiles[warning.Id] = warning
			end
		end
	end	
end

function AssignMissileTargets(I)

end

function Update(I)
	ActiveMissiles = {} -- clears old missiles that are no longer active
	ActiveMissileUpdate(I)
	for k,v in pairs(ActiveMissiles) do
		I:LogToHud(k)
	end
end