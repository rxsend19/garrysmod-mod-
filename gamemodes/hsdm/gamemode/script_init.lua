local rootDir = "script"

local function AddFile(File, dir)
    local fileSide = string.lower(string.Left(File , 3))

    if SERVER and fileSide == "sv_" then
        include(dir..File)
        print("[HSDM: INCLUDE] Серверный файл: " .. File)
    elseif fileSide == "sh_" then
        if SERVER then 
            AddCSLuaFile(dir..File)
            print("[HSDM: ADDCS] Общий файл: " .. File)
            for k, v in ipairs(player.GetAll()) do
                v:PrintMessage(HUD_PRINTCONSOLE, "[HSDM: ADDCS] Общий файл: "..File)
            end
        end
        include(dir..File)
        print("[HSDM: INCLUDE] Общий файл: " .. File)
    elseif fileSide == "cl_" then
        if SERVER then 
            AddCSLuaFile(dir..File)
            print("[HSDM: ADDCS] Клиентский файл: " .. File)
            for k, v in ipairs(player.GetAll()) do
                v:PrintMessage(HUD_PRINTCONSOLE, "[HSDM: ADDCS] Клиентский файл: "..File)
            end
        elseif CLIENT then
            include(dir..File)
            print("[HSDM: INCLUDE] Клиентский файл: " .. File)
        end
    end
end

local function IncludeDir(dir)
    dir = dir .. "/"
    local File, Directory = file.Find(dir.."*", "LUA")

    for k, v in ipairs(File) do
        if string.EndsWith(v, ".lua") then
            AddFile(v, dir)
        end
    end

    for k, v in ipairs(Directory) do
        print("[HSDM: INCLUDE] Папка: " .. v)
        IncludeDir(dir..v)
    end

end

IncludeDir(rootDir)

concommand.Add("init", function()
if (SERVER) == false then return end
    print("[HSDM] Перезагружаем Lua файлы...")
    include("script_init.lua")
    for k, v in ipairs(player.GetAll()) do
        v:ChatPrint("[HSDM] Были перезагружены Lua файлы.")
        v:ChatPrint("Могут возникнуть баги!")
    end
end)
