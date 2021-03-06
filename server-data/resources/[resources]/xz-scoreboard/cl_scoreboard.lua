local XRP = XRP or {}
XRP.Scoreboard = {}
XRP._Scoreboard = {}

XRP.Scoreboard.Menu = {}

XRP._Scoreboard.Players = {}
XRP._Scoreboard.Recent = {}
XRP._Scoreboard.SelectedPlayer = nil
XRP._Scoreboard.MenuOpen = false
XRP._Scoreboard.Menus = {}

local function spairs(t, order)
    local keys = {}
    for k in pairs(t) do keys[#keys+1] = k end

    if order then
        table.sort(keys, function(a,b) return order(t, a, b) end)
    else
        table.sort(keys)
    end

    local i = 0
    return function()
        i = i + 1
        if keys[i] then
            return keys[i], t[keys[i]]
        end
    end
end

function XRP.Scoreboard.AddPlayer(self, data)
    XRP._Scoreboard.Players[data.src] = data
end

function XRP.Scoreboard.RemovePlayer(self, data)
    XRP._Scoreboard.Players[data.src] = nil
    XRP._Scoreboard.Recent[data.src] = data
end

function XRP.Scoreboard.RemoveRecent(self, src)
    XRP._Scoreboard.Recent[src] = nil
end

function XRP.Scoreboard.AddAllPlayers(self, data, recentData)
    XRP._Scoreboard.Players[data.src] = data
    XRP._Scoreboard.Recent[recentData.src] = recentData
end

function XRP.Scoreboard.GetPlayerCount(self)
    local count = 0

    for i = 0, 255 do
        if NetworkIsPlayerActive(i) then count = count + 1 end
    end

    return count
end

Citizen.CreateThread(function()
    local function DrawMain()
        if WarMenu.Button("Total:", tostring(XRP.Scoreboard:GetPlayerCount()), {r = 135, g = 206, b = 250, a = 150}) then end

        for k,v in spairs(XRP._Scoreboard.Players, function(t, a, b) return t[a].src < t[b].src end) do
            local playerId = GetPlayerFromServerId(v.src)

            if NetworkIsPlayerActive(playerId) or GetPlayerPed(playerId) == PlayerPedId() then
                if WarMenu.MenuButton("[" .. v.src .. "] " .. v.steamid .. " ", "options") then XRP._Scoreboard.SelectedPlayer = v end
            else
                if WarMenu.MenuButton("[" .. v.src .. "] - instanced?", "options", {r = 255, g = 0, b = 0, a = 255}) then XRP._Scoreboard.SelectedPlayer = v end
            end
        end

        

        if WarMenu.MenuButton("Recent D/C's", "recent") then
        end
    end

    local function DrawRecent()
        for k,v in spairs(XRP._Scoreboard.Recent, function(t, a, b) return t[a].src < t[b].src end) do
            if WarMenu.MenuButton("[" .. v.src .. "] " .. v.name, "options") then XRP._Scoreboard.SelectedPlayer = v end
        end
    end

    local function DrawOptions()
        if WarMenu.Button("Steam ID:", XRP._Scoreboard.SelectedPlayer.steamid) then end
        if WarMenu.Button("Community ID:", XRP._Scoreboard.SelectedPlayer.comid) then end
        if WarMenu.Button("Server ID:", XRP._Scoreboard.SelectedPlayer.src) then end
    end

    XRP._Scoreboard.Menus = {
        ["scoreboard"] = DrawMain,
        ["recent"] = DrawRecent,
        ["options"] = DrawOptions
    }

    local function Init()
        WarMenu.CreateMenu("scoreboard", "Player List")
        WarMenu.SetSubTitle("scoreboard", "Players")

        WarMenu.SetMenuWidth("scoreboard", 0.5)
        WarMenu.SetMenuX("scoreboard", 0.71)
        WarMenu.SetMenuY("scoreboard", 0.017)
        WarMenu.SetMenuMaxOptionCountOnScreen("scoreboard", 30)
        WarMenu.SetTitleColor("scoreboard", 135, 206, 250, 255)
        WarMenu.SetTitleBackgroundColor("scoreboard", 0 , 0, 0, 150)
        WarMenu.SetMenuBackgroundColor("scoreboard", 0, 0, 0, 100)
        WarMenu.SetMenuSubTextColor("scoreboard", 255, 255, 255, 255)

        WarMenu.CreateSubMenu("recent", "scoreboard", "Recent D/C's")
        WarMenu.SetMenuWidth("recent", 0.5)
        WarMenu.SetTitleColor("recent", 135, 206, 250, 255)
        WarMenu.SetTitleBackgroundColor("recent", 0 , 0, 0, 150)
        WarMenu.SetMenuBackgroundColor("recent", 0, 0, 0, 100)
        WarMenu.SetMenuSubTextColor("recent", 255, 255, 255, 255)

        WarMenu.CreateSubMenu("options", "scoreboard", "User Info")
        WarMenu.SetMenuWidth("options", 0.5)
        WarMenu.SetTitleColor("options", 135, 206, 250, 255)
        WarMenu.SetTitleBackgroundColor("options", 0 , 0, 0, 150)
        WarMenu.SetMenuBackgroundColor("options", 0, 0, 0, 100)
        WarMenu.SetMenuSubTextColor("options", 255, 255, 255, 255)
    end

    Init()
    timed = 0
    while true do
        for k,v in pairs(XRP._Scoreboard.Menus) do
            if WarMenu.IsMenuOpened(k) then
                v()
                WarMenu.Display()
            else
                if timed > 0 then
                    timed = timed - 1
                end
            end
        end

        Citizen.Wait(1)
    end


end)

function XRP.Scoreboard.Menu.Open(self)
    XRP._Scoreboard.SelectedPlayer = nil
    WarMenu.OpenMenu("scoreboard")
    shouldDraw = true
end

function XRP.Scoreboard.Menu.Close(self)
    for k,v in pairs(XRP._Scoreboard.Menus) do
        WarMenu.CloseMenu(K)        shouldDraw =false    end
end

Citizen.CreateThread(function()
    local function IsAnyMenuOpen()
        for k,v in pairs(XRP._Scoreboard.Menus) do
            if WarMenu.IsMenuOpened(k) then return true end
        end

        return false
    end

    while true do
        Citizen.Wait(0)
        if IsControlPressed(0, 303) then
            if not IsAnyMenuOpen() then
                XRP.Scoreboard.Menu:Open()
            end
        else
            if IsAnyMenuOpen() then XRP.Scoreboard.Menu:Close() end
            Citizen.Wait(100)
        end
    end
end)

--Draw Things
Citizen.CreateThread(function()
    local animationState = false
    while true do
        Citizen.Wait(0)

        if shouldDraw or forceDraw then
            local nearbyPlayers = GetNeareastPlayers()
            for k, v in pairs(nearbyPlayers) do
                local ped = v.ped
                if DoesEntityExist(ped) and IsEntityVisible(ped) then
                    local x, y, z = table.unpack(GetEntityCoords(v.ped))
                    Draw3DText(x, y, z + 1.1, v.playerId)
                end
            end
        end
    end
end)

function Draw3DText(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    if onScreen then
        -- Calculate text scale to use
        local dist = GetDistanceBetweenCoords(GetGameplayCamCoords(), x, y, z, 1)
        local scale = 0.7 * (1.0 / dist) * (1.0 / GetGameplayCamFov()) * 100

        -- Draw text on screen
        SetTextScale(scale, scale)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 255)
        SetTextDropShadow(0, 0, 0, 0, 255)
        SetTextDropShadow()
        SetTextEdge(4, 0, 0, 0, 255)
        SetTextOutline()
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x, _y)
    end
end

function GetNeareastPlayers()
	local playerPed = PlayerPedId()
	local playerlist = GetActivePlayers()

    local players_clean = {}
    local found_players = false

    for i = 1, #playerlist, 1 do
        found_players = true
        table.insert(players_clean, { playerName = GetPlayerName(playerlist[i]), playerId = GetPlayerServerId(playerlist[i]), ped = GetPlayerPed(playerlist[i]) })
    end
    return players_clean
end

RegisterNetEvent("xz-scoreboard:RemovePlayer", function(data)
    XRP.Scoreboard:RemovePlayer(data)
end)

RegisterNetEvent("xz-scoreboard:AddPlayer", function(data)
    XRP.Scoreboard:AddPlayer(data)
end)

RegisterNetEvent("xz-scoreboard:RemoveRecent", function(src)
    XRP.Scoreboard:RemoveRecent(src)
end)

RegisterNetEvent("xz-scoreboard:AddAllPlayers", function(data, recentData)
    XRP.Scoreboard:AddAllPlayers(data, recentData)
end)

TriggerServerEvent('xrp-scoreboard:AddPlayer')