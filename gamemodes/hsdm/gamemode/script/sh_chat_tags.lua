--[[
CTag Chat Tags by Yezetee
http://steamcommunity.com/id/yezetee/
Version 2.0.1 (05/21/18)
--]]

CTag = {}
CTag.Enabled = true -- Enable/disable the entire script (requires server restart).

CTag.CustomTags = {}
CTag.CustomTags.Enabled = true -- Enable/disable custom player chat tags.
CTag.CustomTags.BracketDefaultColor = Color( 255, 255, 255 ) -- Sets default color of brackets.
CTag.CustomTags.BracketLeft = "[" -- Sets what comes before the tag (to the left).
CTag.CustomTags.BracketRight = "] " -- Sets what comes after the tag (to the right).

CTag.CustomTags["STEAM_0:1:511088169"] = { -- Player's SteamID32 (You can find using http://steamidfinder.com/ )
  "Root", -- Text to display in the tag
  Color( 3, 252, 3 ), -- Color of the tag
  Color( 3, 252, 3 ) -- Color of the tag's brackets (Set to 'nil' to use default color)
}

CTag.GroupTags = {}
CTag.GroupTags.Enabled = true -- Enable/disable user group-based player chat tags.
CTag.GroupTags.BracketDefaultColor = Color( 255, 255, 255 ) -- Sets default color of brackets.
CTag.GroupTags.BracketLeft = "[" -- Sets what comes before the tag (to the left).
CTag.GroupTags.BracketRight = "] " -- Sets what comes after the tag (to the right).

CTag.GroupTags["usergroup"] = { -- User group's name
  "CTag", -- Text to display in the tag
  Color( 255, 255, 255 ), -- Color of the tag
  Color( 255, 255, 255 ) -- Color of the tag's brackets (Set to 'nil' to use default color)
}

CTag.GroupTags["superadmin"] = {
  "Admin",
  Color( 255, 0, 0 ),
  Color( 255, 0, 0 )
}

CTag.GroupTags["admin"] = {
  "Admin",
  Color( 255, 0, 0 ),
  Color( 255, 0, 0 )
}

CTag.GroupTags["premium"] = {
  "Premium",
  Color( 245, 238, 27 ),
  Color( 245, 238, 27 )
}

CTag.CustomColors = {}
CTag.CustomColors.Enabled = true -- Enable/disable custom chat colors.
CTag.CustomColors.DefaultColor = Color( 255, 255, 255 ) -- Sets default color of custom colored chats.

CTag.CustomColors["STEAM_0:X:XXXXXX"] = { -- Player's SteamID32 (You can find using http://steamidfinder.com/ )
  Color( 255, 255, 255 ), -- Color of the player's text (Set to 'nil' to use default color)
  Color( 255, 255, 255 ) -- Color of the player's name (Set to 'nil' to ignore)
}
