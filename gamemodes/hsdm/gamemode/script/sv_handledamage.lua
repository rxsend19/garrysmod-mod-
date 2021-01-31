hook.Add("PostEntityTakeDamage", "hsdm_only_headshots", function(target, dmg, took)
	if target:IsPlayer() or target:IsBot() and target:Alive() then

		if target:LastHitGroup() != 1 then
			took = false
			dmg:ScaleDamage(0) -- я параноик просто			
		elseif target:LastHitGroup() == 1 and dmg:IsBulletDamage() then
			target:EmitSound("headshot_tp_pumpkin_"..math.random(1, 9)..".wav", 75, 100, 1)
			dmg:ScaleDamage(100)
			took = true
			local particle = ents.Create( "env_blood" )
			particle:SetPos( dmginfo:GetDamagePosition() or Vector( 0 , 0 , 0 ) )
			particle:SetKeyValue( "spraydir" , "90 0 0" )
			particle:SetKeyValue( "color" , "0" )
			particle:SetKeyValue( "spawnflags" , "8" )
			particle:SetKeyValue( "amount" , "100" )
			particle:Spawn()
			if IsValid( particle ) then				
				particle:Fire( "EmitBlood" , 0 , 0 )
				particle:Fire( "EmitBlood" , 0 , 0 )
				particle:Fire( "EmitBlood" , 0 , 0 )
				particle:Fire( "EmitBlood" , 0 , 0 )
				particle:EmitSound( Sound( "ambient/levels/canals/drip" .. math.random( 1 , 4 ) .. ".wav" ) , 72 , math.random( 60 , 140 ) , 1 )
						
			end
		elseif dmg:IsFallDamage() then
			took = true
		else
			took = false
		end

	end
end)