--[[
    Archive Hub
--]]

-- ==================== CAMADA DE PROTEÇÃO ====================
local function initSecurity()
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    if LocalPlayer then
        pcall(function()
            hookfunction(LocalPlayer.Kick, function() return end)
        end)
        pcall(function()
            hookfunction(LocalPlayer.Destroy, function() return end)
        end)
        LocalPlayer.OnTeleport:Connect(function(state)
            if state == Enum.TeleportState.Started then
                pcall(function() game:GetService("TeleportService"):TeleportCancel() end)
            end
        end)
    end
    pcall(function()
        if syn and syn.protect_gui then
            syn.protect_gui()
        end
    end)
end
initSecurity()

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Archive Hub",
   LoadingTitle = "Archive Hub",
   LoadingSubtitle = "",
   ConfigurationSaving = { Enabled = false }
})

-- ==================== SERVIÇOS ====================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Camera = workspace.CurrentCamera
local Stats = game:GetService("Stats")

-- ==================== CONFIGURAÇÕES GLOBAIS ====================
getgenv().Aimbot = false
getgenv().AimbotKey = Enum.KeyCode.E
getgenv().AimbotKeyType = "key"
getgenv().AimbotPart = "Head"
getgenv().TeamCheck = false
getgenv().ShowFOV = false
getgenv().FOVSize = 100
getgenv().HitboxAtivo = false
getgenv().HitboxSize = 2
getgenv().ESP = false
getgenv().FOV_Jogo = 70
getgenv().WalkSpeedAtivo = false
getgenv().WalkSpeed = 16
getgenv().FlyAtivo = false
getgenv().FlyHabilitado = false
getgenv().FlySpeed = 50
getgenv().AntiFling = false
getgenv().NoClip = false
getgenv().ClickTPAtivo = false
getgenv().AutoClickAtivo = false
getgenv().AutoClickDelay = 0.1
getgenv().AutoClickKey = nil
getgenv().AimbotSmoothness = 0.2
getgenv().AntiBan = true
getgenv().AntiAFK = false

-- ==================== VARIÁVEIS INTERNAS ====================
local originalCollisions = {}
local ESP_Active = false
local autoclickToggleUI = nil
local lastFPS = 60
local ESPColorCache = {}

-- ==================== DICIONÁRIO DE PARTES ====================
local TraducaoPartes = {
    ["Cabeça"] = "Head",
    ["Tronco Superior"] = "UpperTorso",
    ["Tronco Inferior"] = "LowerTorso",
    ["Centro (Raiz)"] = "HumanoidRootPart"
}

-- ==================== DRAWING OBJECTS ====================
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 2
FOVCircle.Color = Color3.fromRGB(255, 255, 255)
FOVCircle.Visible = false

local StatsText = Drawing.new("Text")
StatsText.Text = ""
StatsText.Color = Color3.fromRGB(255, 255, 255)
StatsText.Size = 18
StatsText.Center = false
StatsText.Outline = true
StatsText.OutlineColor = Color3.new(0,0,0)
StatsText.Position = Vector2.new(0, 0)
StatsText.Visible = false

-- ==================== INTERFACE ====================

-- ABA 1: COMBATE
local TabCombate = Window:CreateTab("Combate", 4483362458)
TabCombate:CreateToggle({Name = "Ativar Aimbot", CurrentValue = false, Callback = function(V) getgenv().Aimbot = V end})
TabCombate:CreateToggle({
    Name = "Team Check",
    CurrentValue = false,
    Callback = function(V)
        getgenv().TeamCheck = V
        UpdateAllHitboxes()
        if ESP_Active then
            ToggleESP(false)
            ToggleESP(true)
        end
    end
})
TabCombate:CreateDropdown({
    Name = "Focar Parte do Corpo",
    Options = {"Cabeça", "Tronco Superior", "Tronco Inferior", "Centro (Raiz)"},
    CurrentOption = {"Cabeça"},
    Callback = function(Option) 
        local escolha = type(Option) == "table" and Option[1] or Option
        getgenv().AimbotPart = TraducaoPartes[escolha]
    end
})
TabCombate:CreateDropdown({
    Name = "Tecla do Aimbot", 
    Options = {"E", "Q", "F", "MouseButton2"}, 
    CurrentOption = {"E"}, 
    Callback = function(Option)
        local tecla = type(Option) == "table" and Option[1] or Option
        if tecla == "MouseButton2" then 
            getgenv().AimbotKey = Enum.UserInputType.MouseButton2
            getgenv().AimbotKeyType = "mouse"
        else 
            getgenv().AimbotKey = Enum.KeyCode[tecla]
            getgenv().AimbotKeyType = "key"
        end
    end
})
TabCombate:CreateToggle({Name = "Ver Círculo FOV", CurrentValue = false, Callback = function(V) getgenv().ShowFOV = V end})
TabCombate:CreateSlider({Name = "Raio do Aimbot", Range = {30, 800}, Increment = 1, CurrentValue = 100, Callback = function(V) getgenv().FOVSize = V end})
TabCombate:CreateToggle({Name = "Expandir Hitbox", CurrentValue = false, Callback = function(V) getgenv().HitboxAtivo = V; UpdateAllHitboxes() end})
TabCombate:CreateSlider({Name = "Tamanho Hitbox", Range = {2, 50}, Increment = 1, CurrentValue = 2, Callback = function(V) getgenv().HitboxSize = V; UpdateAllHitboxes() end})
TabCombate:CreateSlider({Name = "Velocidade do Aimbot", Range = {0.01, 1}, Increment = 0.01, CurrentValue = 0.2, Callback = function(V) getgenv().AimbotSmoothness = V end})

-- ABA 2: VISUAIS
local TabVisuais = Window:CreateTab("Visuais", 4483362458)
TabVisuais:CreateToggle({Name = "ESP Aura + Vida (HP)", CurrentValue = false, Callback = function(V) getgenv().ESP = V; ToggleESP(V) end})
TabVisuais:CreateSlider({Name = "Field of View", Range = {70, 120}, Increment = 1, CurrentValue = 70, Callback = function(V) getgenv().FOV_Jogo = V end})
TabVisuais:CreateToggle({Name = "Ver Info de Sistema (FPS/Ping)", CurrentValue = false, Callback = function(V) getgenv().ShowStatsHUD = V; StatsText.Visible = V end})
TabVisuais:CreateButton({Name = "Gráficos de Batata (Ultra FPS)", Callback = function()
    local lighting = game:GetService("Lighting")
    lighting.GlobalShadows = false
    lighting.FogEnd = 100000
    lighting.FogStart = 0
    lighting.Brightness = 2
    lighting.OutdoorAmbient = Color3.new(0.7, 0.7, 0.7)
    lighting.Outlines = false
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") or v:IsA("MeshPart") then
            v.Material = Enum.Material.SmoothPlastic
            v.Reflectance = 0
        elseif v:IsA("Decal") or v:IsA("Texture") then
            v:Destroy()
        elseif v:IsA("ParticleEmitter") or v:IsA("Fire") or v:IsA("Smoke") then
            v.Enabled = false
        elseif v:IsA("SpecialMesh") then
            v.TextureId = ""
        end
    end
end})

-- ABA 3: MOVIMENTO
local TabMove = Window:CreateTab("Movimento", 4483362458)
TabMove:CreateToggle({Name = "Anti-Fling (Smart)", CurrentValue = false, Callback = function(V) getgenv().AntiFling = V end})
TabMove:CreateToggle({Name = "No-Clip (Atravessar Tudo)", CurrentValue = false, Callback = function(V) 
    getgenv().NoClip = V
    if not V then RestoreNoClip() end
end})
TabMove:CreateToggle({Name = "Ativar Custom Speed", CurrentValue = false, Callback = function(V) getgenv().WalkSpeedAtivo = V end})
TabMove:CreateSlider({Name = "Velocidade (WS)", Range = {16, 300}, Increment = 1, CurrentValue = 16, Callback = function(V) getgenv().WalkSpeed = V end})
TabMove:CreateToggle({Name = "Habilitar Voo (F)", CurrentValue = false, Callback = function(V) getgenv().FlyHabilitado = V end})
TabMove:CreateSlider({Name = "Velocidade do Voo", Range = {10, 500}, Increment = 1, CurrentValue = 50, Callback = function(V) getgenv().FlySpeed = V end})
TabMove:CreateToggle({Name = "Click TP (Ctrl+Click)", CurrentValue = false, Callback = function(V) getgenv().ClickTPAtivo = V end})

-- ABA 4: TROLL & EXTRAS
local TabExtras = Window:CreateTab("Troll & Extras", 4483362458)
TabExtras:CreateButton({Name = "Abrir Menu de Danças/Emotes", Callback = function()
    pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/7yd7/Hub/refs/heads/Branch/GUIS/Emotes.lua"))()
    end)
end})
TabExtras:CreateButton({Name = "Infinite Yield Admin", Callback = function()
    pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
    end)
end})

-- ABA 5: AUTOMATION
local TabAuto = Window:CreateTab("Autoclicker", 4483362458)
autoclickToggleUI = TabAuto:CreateToggle({Name = "Ativar Autoclick", CurrentValue = false, Callback = function(V) 
    getgenv().AutoClickAtivo = V 
end})
TabAuto:CreateSlider({Name = "Delay Click", Range = {0.001, 1}, Increment = 0.001, CurrentValue = 0.1, Callback = function(V) getgenv().AutoClickDelay = V end})
TabAuto:CreateDropdown({
    Name = "Tecla Autoclick",
    Options = {"None", "V", "B", "Z", "X"},
    CurrentOption = {"None"},
    Callback = function(O)
        local tecla = type(O) == "table" and O[1] or O
        if tecla == "None" then
            getgenv().AutoClickKey = nil
        else
            getgenv().AutoClickKey = Enum.KeyCode[tecla]
        end
    end
})

-- ABA 6: SEGURANÇA
local TabSeg = Window:CreateTab("Segurança", 4483362458)
TabSeg:CreateToggle({Name = "Anti-Ban (Experimental)", CurrentValue = true, Callback = function(V)
    getgenv().AntiBan = V
    if V then
        initSecurity()
    end
end})
TabSeg:CreateToggle({Name = "Anti-AFK (Parado sem Kick)", CurrentValue = false, Callback = function(V)
    getgenv().AntiAFK = V
end})

-- ==================== FUNÇÕES AUXILIARES ====================

function isEnemy(player)
    if not getgenv().TeamCheck then return true end
    if not player.Team or not LocalPlayer.Team then
        return true
    end
    return player.Team ~= LocalPlayer.Team
end

function UpdateAllHitboxes()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            if getgenv().HitboxAtivo and isEnemy(player) then
                ApplyHitboxToCharacter(player.Character)
            else
                RemoveHitboxFromCharacter(player.Character)
            end
        end
    end
end

function ApplyHitboxToCharacter(char)
    pcall(function()
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.Size = Vector3.new(getgenv().HitboxSize, getgenv().HitboxSize, getgenv().HitboxSize)
            hrp.Transparency = 0.7
        end
    end)
end

function RemoveHitboxFromCharacter(char)
    pcall(function()
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.Size = Vector3.new(2, 2, 1)
            hrp.Transparency = 1
        end
    end)
end

local teamColorPalette = {
    Color3.new(1, 0, 0),
    Color3.new(1, 1, 1),
    Color3.new(0, 0, 0),
    Color3.new(1, 1, 0),
    Color3.new(0, 1, 0),
    Color3.new(0, 1, 1),
    Color3.new(1, 0, 1),
    Color3.new(0.5, 0, 0.5),
}

local function getESPOutlineColor(player)
    local myTeam = LocalPlayer.Team
    local pTeam = player.Team

    if not myTeam or not pTeam then
        return Color3.new(1, 0, 0)
    end

    if getgenv().TeamCheck and pTeam == myTeam then
        return Color3.new(0, 0, 1)
    end

    if not getgenv().TeamCheck then
        return Color3.new(1, 0, 0)
    end

    if not ESPColorCache[pTeam] then
        local count = #ESPColorCache + 1
        local cor = teamColorPalette[count] or teamColorPalette[(count % #teamColorPalette) + 1]
        ESPColorCache[pTeam] = cor
    end
    return ESPColorCache[pTeam]
end

function CreateESPForCharacter(char, player)
    if not getgenv().ESP then return end
    pcall(function()
        local outlineColor = getESPOutlineColor(player)

        local aura = char:FindFirstChild("KawasakiAura") or Instance.new("Highlight")
        aura.Name = "KawasakiAura"
        aura.FillTransparency = 1
        aura.OutlineColor = outlineColor
        aura.Parent = char

        local tag = char:FindFirstChild("KawasakiTag") or Instance.new("BillboardGui")
        tag.Name = "KawasakiTag"
        tag.Size = UDim2.new(0, 200, 0, 50)
        tag.AlwaysOnTop = true
        tag.StudsOffset = Vector3.new(0, 3, 0)
        tag.Parent = char

        local lbl = tag:FindFirstChild("TextLabel") or Instance.new("TextLabel")
        lbl.BackgroundTransparency = 1
        lbl.Size = UDim2.new(1, 0, 1, 0)
        lbl.TextColor3 = Color3.new(1, 1, 1)
        lbl.TextStrokeTransparency = 0
        lbl.Parent = tag

        local hum = char:FindFirstChild("Humanoid")
        if hum then
            lbl.Text = player.Name .. " [" .. math.floor(hum.Health) .. " HP]"
            hum.HealthChanged:Connect(function(health)
                lbl.Text = player.Name .. " [" .. math.floor(health) .. " HP]"
            end)
        end
    end)
end

function RemoveESPFromCharacter(char)
    pcall(function()
        local aura = char:FindFirstChild("KawasakiAura")
        if aura then aura:Destroy() end
        local tag = char:FindFirstChild("KawasakiTag")
        if tag then tag:Destroy() end
    end)
end

function ToggleESP(state)
    ESP_Active = state
    if state then
        ESPColorCache = {}
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                CreateESPForCharacter(player.Character, player)
                if getgenv().HitboxAtivo and isEnemy(player) then
                    ApplyHitboxToCharacter(player.Character)
                end
            end
        end
    else
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                RemoveESPFromCharacter(player.Character)
                RemoveHitboxFromCharacter(player.Character)
            end
        end
    end
end

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(char)
        task.wait(0.1)
        if ESP_Active then
            CreateESPForCharacter(char, player)
            if getgenv().HitboxAtivo and isEnemy(player) then
                ApplyHitboxToCharacter(char)
            end
        end
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    if player.Character then RemoveESPFromCharacter(player.Character) end
    if player.Team then
        ESPColorCache[player.Team] = nil
    end
end)

for _, player in pairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        player.CharacterAdded:Connect(function(char)
            task.wait(0.1)
            if ESP_Active then
                CreateESPForCharacter(char, player)
                if getgenv().HitboxAtivo and isEnemy(player) then
                    ApplyHitboxToCharacter(char)
                end
            end
        end)
        if player.Character and ESP_Active then
            CreateESPForCharacter(player.Character, player)
        end
    end
end

function RestoreNoClip()
    for obj, canCollide in pairs(originalCollisions) do
        if obj then pcall(function() obj.CanCollide = canCollide end) end
    end
    originalCollisions = {}
end

-- Anti-AFK
task.spawn(function()
    while true do
        if getgenv().AntiAFK then
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("Humanoid") then
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    hrp.Velocity = hrp.Velocity + Vector3.new(math.random(-1, 1), 0, math.random(-1, 1))
                end
            end
        end
        task.wait(10)
    end
end)

-- Autoclicker
task.spawn(function()
    while true do
        if getgenv().AutoClickAtivo then pcall(mouse1click) end
        task.wait(getgenv().AutoClickDelay)
    end
end)

-- HUD Stats
task.spawn(function()
    task.spawn(function()
        while true do
            local t0 = os.clock()
            local frames = 0
            local heartbeat
            heartbeat = RunService.Heartbeat:Connect(function()
                frames = frames + 1
                if os.clock() - t0 >= 1 then
                    lastFPS = frames
                    heartbeat:Disconnect()
                end
            end)
            task.wait(1)
        end
    end)
    while true do
        if getgenv().ShowStatsHUD then
            local ping = Stats.Network.ServerStatsItem["Data Ping"]:GetValue() or 0
            StatsText.Text = string.format("FPS: %d | Ping: %d ms", lastFPS, ping)
            StatsText.Position = Vector2.new(Camera.ViewportSize.X - 200, 30)
        end
        task.wait(0.5)
    end
end)

-- Fly
local FlyBV, FlyBG
function SetupFly()
    if FlyBV then FlyBV:Destroy() end
    if FlyBG then FlyBG:Destroy() end
    FlyBV = Instance.new("BodyVelocity")
    FlyBV.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    FlyBG = Instance.new("BodyGyro")
    FlyBG.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    FlyBG.CFrame = Camera.CFrame
end
function CleanupFly()
    if FlyBV then FlyBV.Parent = nil end
    if FlyBG then FlyBG.Parent = nil end
end

-- AIMBOT
local hasMouseMoveRel = type(mousemoverel) == "function"

local function GetTargetPart()
    local closestPart = nil
    local shortestDist = getgenv().FOVSize
    local mousePos = UserInputService:GetMouseLocation()

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild(getgenv().AimbotPart) then
            if not isEnemy(player) then continue end
            local targetPart = player.Character[getgenv().AimbotPart]
            local pos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)

            if onScreen then
                local dist = (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude
                if dist < shortestDist then
                    shortestDist = dist
                    closestPart = targetPart
                end
            end
        end
    end
    return closestPart
end

-- ==================== RENDERSTEPPED ====================
RunService.RenderStepped:Connect(function()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChild("Humanoid")

    Camera.FieldOfView = getgenv().FOV_Jogo

    if not hrp or not hum then return end

    if getgenv().AntiFling then
        if hrp.Velocity.Magnitude > 60 or hrp.RotVelocity.Magnitude > 60 then
            hrp.Velocity = Vector3.zero
            hrp.RotVelocity = Vector3.zero
        end
    end

    if getgenv().NoClip then
        for _, v in pairs(char:GetDescendants()) do
            if v:IsA("BasePart") then
                if originalCollisions[v] == nil then originalCollisions[v] = v.CanCollide end
                v.CanCollide = false
            end
        end
    end

    if getgenv().WalkSpeedAtivo then hum.WalkSpeed = getgenv().WalkSpeed end

    if getgenv().Aimbot then
        local isPressed = false
        if getgenv().AimbotKeyType == "mouse" then
            pcall(function() isPressed = UserInputService:IsMouseButtonPressed(getgenv().AimbotKey) end)
        else
            pcall(function() isPressed = UserInputService:IsKeyDown(getgenv().AimbotKey) end)
        end

        if isPressed then
            if hasMouseMoveRel then
                local target = GetTargetPart()
                if target then
                    local targetPos, onScreen = Camera:WorldToViewportPoint(target.Position)
                    if onScreen then
                        local mousePos = UserInputService:GetMouseLocation()
                        local delta = Vector2.new(targetPos.X, targetPos.Y) - mousePos
                        local speed = 1 - math.clamp(getgenv().AimbotSmoothness, 0.01, 1)
                        mousemoverel(delta.X * speed, delta.Y * speed)
                    end
                end
            else
                local target = GetTargetPart()
                if target then
                    local lookAt = CFrame.new(Camera.CFrame.Position, target.Position)
                    local speed = 1 - math.clamp(getgenv().AimbotSmoothness, 0.01, 1)
                    Camera.CFrame = Camera.CFrame:Lerp(lookAt, speed)
                end
            end
        end
    end

    FOVCircle.Visible = getgenv().ShowFOV
    FOVCircle.Radius = getgenv().FOVSize
    FOVCircle.Position = UserInputService:GetMouseLocation()

    if getgenv().FlyAtivo and getgenv().FlyHabilitado then
        if not FlyBV or not FlyBG then SetupFly() end
        FlyBV.Parent = hrp
        FlyBG.Parent = hrp
        FlyBG.CFrame = Camera.CFrame
        if hum:GetState() == Enum.HumanoidStateType.Freefall then
            hum:ChangeState(Enum.HumanoidStateType.Running)
        end
        local moveDir = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir += Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir -= Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir -= Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir += Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir += Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir -= Vector3.new(0, 1, 0) end
        FlyBV.Velocity = moveDir * getgenv().FlySpeed
    else
        CleanupFly()
    end
end)

-- ==================== INPUTS ====================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.KeyCode == Enum.KeyCode.F and getgenv().FlyHabilitado then
        getgenv().FlyAtivo = not getgenv().FlyAtivo
        if not getgenv().FlyAtivo then CleanupFly() end
    end

    if getgenv().AutoClickKey and input.KeyCode == getgenv().AutoClickKey then
        getgenv().AutoClickAtivo = not getgenv().AutoClickAtivo
        if autoclickToggleUI then autoclickToggleUI:Set(getgenv().AutoClickAtivo) end
    end

    if input.UserInputType == Enum.UserInputType.MouseButton1 and 
       UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) and 
       getgenv().ClickTPAtivo then
        local char = LocalPlayer.Character
        if char then char:MoveTo(Mouse.Hit.p) end
    end
end)

-- Limpeza ao teleporte
game:GetService("Players").LocalPlayer.OnTeleport:Connect(function()
    CleanupFly()
    RestoreNoClip()
    StatsText:Remove()
end)