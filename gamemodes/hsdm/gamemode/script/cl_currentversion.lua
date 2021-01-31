surface.CreateFont( "Nextoren259", {
    font = "Bauhaus",
    size = 18,
    weight = 100,
    blursize = 0,
    scanlines = 0,
    antialias = false,
    underline = false,
    italic = false,
    strikeout = false,
    symbol = false,
    rotary = false,
    shadow = false,
    additive = false,
    outline = false,
})

local rxsend_nextoren_chance = math.random(1, 100)
hook.Add( "HUDPaint", "rxsend_gamemode_version", function()
    draw.DrawText( "Next version: 0.0.3 (Gameplay improvement)", "Nextoren259", ScrW() * 0.5, ScrH() * 0.98, Color(255, 255, 0), TEXT_ALIGN_CENTER )
    if rxsend_nextoren_chance > 5 then
    	draw.DrawText( "Alpha Stage. Expect a lot of bugs and lua errors.", "Nextoren259", ScrW() * 0.5, ScrH() * 0.96, Color(255, 102, 0), TEXT_ALIGN_CENTER )
    	--draw.DrawText( "RXSEND Headshot DM 0.0.1", "Nextoren259", ScrW() * 0.5, ScrH() * 0.96, color_white, TEXT_ALIGN_CENTER )
	    --draw.DrawText( "RXSEND Headshot DM 0.0.2(Custom gamemode content added)", "Nextoren259", ScrW() * 0.5, ScrH() * 0.96, color_white, TEXT_ALIGN_CENTER )
	    --draw.DrawText( "RXSEND Headshot DM 0.0.3(init.lua:73 LUA ERROR HOTFIX)", "Nextoren259", ScrW() * 0.5, ScrH() * 0.96, color_white, TEXT_ALIGN_CENTER )
	    draw.DrawText( "RXSEND Headshot DM 0.0.4(Attempt to fix scripts folder inclusion)", "Nextoren259", ScrW() * 0.5, ScrH() * 0.96, color_white, TEXT_ALIGN_CENTER )
	end

	if rxsend_nextoren_chance < 6 then
	    draw.DrawText( "NextOren BREACH 2.5.9-C #2 ( Final )", "Nextoren259", ScrW() * 0.5, ScrH() * 0.96, color_white, TEXT_ALIGN_CENTER )
	end
end)