-- буржуй, мой код не воруй
hook.Add("PlayerDeath", "dzhambolat_nocollide_ragdoll_for_server_optimization_with_xyecoc_library", function(victim, inflictor, attacker)
	for k, v in ipairs (ents.GetAll()) do
		if v:IsRagdoll() and v:GetCollisionGroup() != 20 then
				v:SetCollisionGroup(20)
                print("[RXSEND: DEBUG] Успешно изменена коллизия трупа")
		end
        if v:IsWeapon() and v:GetCollisionGroup() != 20 then
            v:SetCollisionGroup(20)
            print("[RXSEND: DEBUG] Успешно изменена коллизия оружий")
        end
	end
end)
hook.Add("PlayerDeath", "xyecoc_nocollide_weapons", function()
    for k, v in ipairs (ents.GetAll()) do
        if v:IsWeapon() and v:GetCollisionGroup() != 20 then
            v:SetCollisionGroup(20)
        end
	end
end)
