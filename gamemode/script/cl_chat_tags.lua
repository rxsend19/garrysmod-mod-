include( "sh_config.lua" )

if not ( CTag or CTag.Enabled ) then return end

hook.Add( "OnPlayerChat", "CTag", function( ply, strText, bTeamOnly, bPlayerIsDead )
  local tab = {}

  if bPlayerIsDead then
    table.insert( tab, Color( 255, 30, 40 ) )
    table.insert( tab, "*DEAD* " )
  end

  if bTeamOnly then
    table.insert( tab, Color( 30, 160, 40 ) )
    table.insert( tab, "(TEAM) " )
  end

  if ( IsValid( ply ) ) then
    local bracketColor = CTag.CustomTags.BracketDefaultColor
    local customTag = CTag.CustomTags[ply:SteamID()]
    local groupTag = CTag.GroupTags[ply:GetUserGroup()]
    local playerColor = CTag.CustomColors[ply:SteamID()]

    if CTag.CustomTags.Enabled then
      if customTag ~= nil then
        if customTag[3] ~= nil then
          bracketColor = customTag[3]
        end

        table.insert( tab, bracketColor )
        table.insert( tab, CTag.CustomTags.BracketLeft )

        table.insert( tab, customTag[2] )
        table.insert( tab, customTag[1] )

        table.insert( tab, bracketColor )
        table.insert( tab, CTag.CustomTags.BracketRight )
      end
    end

    if CTag.GroupTags.Enabled then
      if groupTag ~= nil then
        if groupTag[3] ~= nil then
          bracketColor = groupTag[3]
        else
          bracketColor = CTag.GroupTags.BracketDefaultColor
        end

        table.insert( tab, bracketColor )
        table.insert( tab, CTag.GroupTags.BracketLeft )

        table.insert( tab, groupTag[2] )
        table.insert( tab, groupTag[1] )

        table.insert( tab, bracketColor )
        table.insert( tab, CTag.GroupTags.BracketRight )
      end
    end

    if CTag.CustomColors.Enabled and playerColor ~= nil and playerColor[2] ~= nil then
      table.insert( tab, playerColor[2] )
      table.insert( tab, ply:GetName() )
    else
      table.insert( tab, ply )
    end

  else
    table.insert( tab, "Console" )
  end

  table.insert( tab, Color( 255, 255, 255 ) )
  table.insert( tab, ": " )

  if ( IsValid( ply ) ) then
    local textColor = CTag.CustomColors[ply:SteamID()]

    if CTag.CustomColors.Enabled then
      if textColor ~= nil then
        if textColor[1] ~= nil then
          table.insert( tab, textColor[1] )
        else
          table.insert( tab, CTag.CustomColors.DefaultColor )
        end
      end
    end
  end
  table.insert( tab, strText )

  chat.AddText( unpack( tab ) )

  return true
end )
