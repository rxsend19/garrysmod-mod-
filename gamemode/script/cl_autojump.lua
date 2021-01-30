local chat = false
local bhop = true
local noclip = false
hook.Add("Think", "bhop", function()
if bhop == true and chat == false and noclip == false then
     if (input.IsKeyDown( KEY_SPACE ) ) then
        if LocalPlayer():IsOnGround() then
            RunConsoleCommand("+jump")
            HasJumped = 1
        else
            RunConsoleCommand("-jump")
            HasJumped = 0
        end
    elseif bhop and LocalPlayer():IsOnGround() then
        if HasJumped == 1 then
            RunConsoleCommand("-jump")
            HasJumped = 0
        end
    end
end
end)
hook.Add("OnPlayerChat", "rxsend_auto_bhop_chat_command", function(adidas, text)
	if ( adidas != LocalPlayer() ) then return end

	text = string.lower(text)

	if text == "!bhop" or text == "!бхоп" or text == "!autojump" then
		if bhop then
    		bhop = false
    		LocalPlayer():ChatPrint("[RXSEND] Вы выключили авто-распрыжку!")
		else
    		bhop = true
    		LocalPlayer():ChatPrint("[RXSEND] Вы включили авто-распрыжку!")
		end
    end
end)

hook.Add("StartChat", "rxsend_is_chat_opened", function()
    chat = true
end)

hook.Add("FinishChat", "rxsend_is_chat_closed_xyecoc_library_powered", function()
    chat = false
end)

hook.Add("HandlePlayerNoClipping", "rxsend_is_noclipping", function(ply, nc_state)
	if nc_state == false then
		noclip = true
	else
		noclip = false
	end
end)

hook.Add( "HUDPaint", "rxsend_speedrun_velocity", function()
if bhop == false then return end
local speed = LocalPlayer():GetVelocity():Unpack(x)
if speed < 0 then
    speed = speed * -1
end

local speed_in_km = speed * 1.905 / 100000 * 3600

speed_in_km = math.Round(speed_in_km, 1)
    draw.RoundedBox( 5, ScrW() * 0.48, ScrH() * 0.88, ScrW() * 0.095, ScrH() * 0.03, Color(0, 0, 0, 100) )
    draw.DrawText( speed_in_km, "CloseCaption_Bold", ScrW() * 0.525, ScrH() * 0.88, Color(255, 255, 0), TEXT_ALIGN_RIGHT )
    draw.DrawText( "КМ/Ч", "CloseCaption_Bold", ScrW() * 0.57, ScrH() * 0.88, Color(255, 255, 0), TEXT_ALIGN_RIGHT )
end)
