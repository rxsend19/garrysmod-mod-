hook.Add( "InitPostEntity", "flashwindowwhenclientspawns", function()
	if not system.HasFocus() then
		system.FlashWindow()
	end
end