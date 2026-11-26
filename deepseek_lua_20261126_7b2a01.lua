--// PRISON LIFE | CUSTOM EXPLOIT SUITE
--// Rage, Blatant, Visuals, Gun Mods, Movement

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

--// КОНФИГУРАЦИЯ
local Config = {
    Rage = { Enabled = false, SilentAim = true, AutoShoot = true, FOV = 300, WallCheck = true },
    Visuals = { Enabled = true, Box = true, Name = true, Health = true, Tracers = true },
    Movement = { InfiniteJump = false, Noclip = false, Speed = 50 },
    GunMod = { Enabled = false, FireRate = 0.000001, AutoFire = true, MaxAmmo = math.huge, Spread = 0, Range = math.huge, Bullets = 10 }
}

local espObjects = {}
local fovCircle = nil
local activeConnections = {}

local function SafeDestroy(inst) if inst and inst.Parent then inst:Destroy() end end

--// 1. ИНТЕРФЕЙС (КАСТОМНЫЙ UI)
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PL_CheatSuite"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game:GetService("CoreGui")

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 300, 0, 400)
MainFrame.Position = UDim2.new(0.5, -150, 0.5, -200)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Parent = ScreenGui
local MainCorner = Instance.new("UICorner", MainFrame); MainCorner.CornerRadius = UDim.new(0, 10)
local MainStroke = Instance.new("UIStroke", MainFrame); MainStroke.Color = Color3.fromRGB(180, 0, 255); MainStroke.Thickness = 2

-- Заголовок
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 30)
TitleBar.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
TitleBar.Parent = MainFrame
local TBCorner = Instance.new("UICorner", TitleBar); TBCorner.CornerRadius = UDim.new(0, 10)
local TitleText = Instance.new("TextLabel")
TitleText.Size = UDim2.new(1, 0, 1, 0)
TitleText.BackgroundTransparency = 1
TitleText.Text = "Prison Life | Cheat Suite"
TitleText.TextColor3 = Color3.new(1,1,1)
TitleText.Font = Enum.Font.GothamBold
TitleText.TextSize = 14
TitleText.Parent = TitleBar

-- Контент (Скроллинг)
local ContentFrame = Instance.new("ScrollingFrame")
ContentFrame.Size = UDim2.new(1, -20, 1, -40)
ContentFrame.Position = UDim2.new(0, 10, 0, 35)
ContentFrame.BackgroundTransparency = 1
ContentFrame.BorderSizePixel = 0
ContentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ContentFrame.ScrollBarThickness = 3
ContentFrame.Parent = MainFrame
local UIListLayout = Instance.new("UIListLayout", ContentFrame); UIListLayout.Padding = UDim.new(0, 5)
UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    ContentFrame.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y + 10)
end)

--// ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ UI
local function CreateToggle(text, default, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, 30)
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    btn.Text = "  " .. text
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 13
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.Parent = ContentFrame
    local c = Instance.new("UICorner", btn); c.CornerRadius = UDim.new(0, 6)

    local indicator = Instance.new("Frame")
    indicator.Size = UDim2.new(0, 40, 0, 18)
    indicator.Position = UDim2.new(1, -50, 0.5, -9)
    indicator.BackgroundColor3 = default and Color3.fromRGB(180, 0, 255) or Color3.fromRGB(50, 50, 50)
    indicator.Parent = btn
    local ic = Instance.new("UICorner", indicator); ic.CornerRadius = UDim.new(0, 9)

    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 14, 0, 14)
    dot.Position = default and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
    dot.BackgroundColor3 = Color3.new(1,1,1)
    dot.Parent = indicator
    local dc = Instance.new("UICorner", dot); dc.CornerRadius = UDim.new(1, 0)

    local state = default
    btn.MouseButton1Click:Connect(function()
        state = not state
        TweenService:Create(dot, TweenInfo.new(0.2), {Position = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)}):Play()
        TweenService:Create(indicator, TweenInfo.new(0.2), {BackgroundColor3 = state and Color3.fromRGB(180, 0, 255) or Color3.fromRGB(50, 50, 50)}):Play()
        callback(state)
    end)
end

--// 2. RAGE / SILENT AIM
local fovGui = Instance.new("ScreenGui")
fovGui.Name = "PL_FOV"; fovGui.ResetOnSpawn = false; fovGui.Parent = game:GetService("CoreGui")
fovCircle = Instance.new("Frame")
fovCircle.Size = UDim2.new(0, Config.Rage.FOV, 0, Config.Rage.FOV)
fovCircle.Position = UDim2.new(0.5, 0, 0.5, 0)
fovCircle.AnchorPoint = Vector2.new(0.5, 0.5)
fovCircle.BackgroundTransparency = 1
fovCircle.Visible = false
fovCircle.Parent = fovGui
local fovCorner = Instance.new("UICorner", fovCircle); fovCorner.CornerRadius = UDim.new(1, 0)
local fovStroke = Instance.new("UIStroke", fovCircle); fovStroke.Color = Color3.fromRGB(255, 0, 0); fovStroke.Thickness = 2; fovStroke.Transparency = 0.3

local function GetTarget()
    local closest, dist = nil, math.huge
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            local targetPart = p.Character:FindFirstChild("Head")
            if hum and targetPart and hum.Health > 0 then
                local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                if onScreen then
                    local d = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                    if d <= Config.Rage.FOV and d < dist then
                        if Config.Rage.WallCheck then
                            local ray = Ray.new(Camera.CFrame.Position, targetPart.Position - Camera.CFrame.Position)
                            local hit = workspace:FindPartOnRayWithIgnoreList(ray, {LocalPlayer.Character, Camera})
                            if hit and not hit:IsDescendantOf(p.Character) then continue end
                        end
                        dist = d
                        closest = targetPart
                    end
                end
            end
        end
    end
    return closest
end

local aimbotConn = RunService.RenderStepped:Connect(function()
    if not Config.Rage.Enabled then return end
    local target = GetTarget()
    if target then
        if Config.Rage.SilentAim then
            Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, target.Position)
        end
        if Config.Rage.AutoShoot then
            local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
            if tool then pcall(function() tool:Activate() end) end
        end
    end
end)
table.insert(activeConnections, aimbotConn)

--// 3. ESP
local function CreateESP(player)
    if player == LocalPlayer then return end
    local function Setup(char)
        if not char or not Config.Visuals.Enabled then return end
        local head = char:WaitForChild("Head", 5)
        local hum = char:WaitForChild("Humanoid", 5)
        if not head or not hum then return end

        if espObjects[player] then
            SafeDestroy(espObjects[player].billboard)
            SafeDestroy(espObjects[player].highlight)
        end

        local hl = Instance.new("Highlight")
        hl.FillColor = Color3.fromRGB(255, 0, 0)
        hl.FillTransparency = 0.5
        hl.OutlineColor = Color3.new(1,1,1)
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Enabled = Config.Visuals.Box
        hl.Parent = char

        local bg = Instance.new("BillboardGui")
        bg.Adornee = head
        bg.Size = UDim2.new(0, 150, 0, 50)
        bg.StudsOffset = Vector3.new(0, 2.5, 0)
        bg.AlwaysOnTop = true
        bg.Parent = head

        local nameLbl = Instance.new("TextLabel")
        nameLbl.Size = UDim2.new(1, 0, 0.5, 0)
        nameLbl.BackgroundTransparency = 1
        nameLbl.TextColor3 = Color3.new(1,1,1)
        nameLbl.TextSize = 14
        nameLbl.Font = Enum.Font.Code
        nameLbl.Text = player.Name
        nameLbl.Parent = bg

        local hpLbl = Instance.new("TextLabel")
        hpLbl.Size = UDim2.new(1, 0, 0.5, 0)
        hpLbl.Position = UDim2.new(0, 0, 0.5, 0)
        hpLbl.BackgroundTransparency = 1
        hpLbl.TextColor3 = Color3.fromRGB(0, 255, 0)
        hpLbl.TextSize = 12
        hpLbl.Font = Enum.Font.Code
        hpLbl.Parent = bg

        espObjects[player] = { billboard = bg, highlight = hl, name = nameLbl, hp = hpLbl, hum = hum }

        task.spawn(function()
            while espObjects[player] and espObjects[player].billboard == bg do
                hpLbl.Text = string.format("HP: %d", math.floor(hum.Health))
                nameLbl.Visible = Config.Visuals.Name
                hpLbl.Visible = Config.Visuals.Health
                task.wait(0.1)
            end
        end)
    end
    if player.Character then Setup(player.Character) end
    player.CharacterAdded:Connect(Setup)
end

local function ToggleESP(state)
    Config.Visuals.Enabled = state
    if state then
        for _, p in ipairs(Players:GetPlayers()) do CreateESP(p) end
    else
        for p, obj in pairs(espObjects) do
            SafeDestroy(obj.billboard)
            SafeDestroy(obj.highlight)
        end
        table.clear(espObjects)
    end
end

--// 4. MOVEMENT
local function ApplySpeed()
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = Config.Movement.Speed end
    end
end

local infJumpConn = RunService.Heartbeat:Connect(function()
    if Config.Movement.InfiniteJump then
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum and hum:GetState() ~= Enum.HumanoidStateType.Jumping then
                hum.Jump = true
            end
        end
    end
end)
table.insert(activeConnections, infJumpConn)

local noclipConn = RunService.Stepped:Connect(function()
    if Config.Movement.Noclip then
        local char = LocalPlayer.Character
        if char then
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
        end
    end
end)
table.insert(activeConnections, noclipConn)

--// 5. GUN MODS
local function ModGun(toolName)
    local char = LocalPlayer.Character
    if not char then return end
    local tool = char:FindFirstChild(toolName) or LocalPlayer.Backpack:FindFirstChild(toolName)
    if tool and tool:FindFirstChild("GunStates") then
        local module = require(tool.GunStates)
        module.MaxAmmo = Config.GunMod.MaxAmmo
        module.CurrentAmmo = Config.GunMod.MaxAmmo
        module.StoredAmmo = Config.GunMod.MaxAmmo
        module.FireRate = Config.GunMod.FireRate
        module.Spread = Config.GunMod.Spread
        module.Range = Config.GunMod.Range
        module.Bullets = Config.GunMod.Bullets
        module.AutoFire = Config.GunMod.AutoFire
    end
end

--// 6. ПРИВЯЗКА UI
CreateToggle("Rage (Silent Aim + Auto Shoot)", Config.Rage.Enabled, function(state)
    Config.Rage.Enabled = state
    fovCircle.Visible = state
end)

CreateToggle("ESP (Box + Name + HP)", Config.Visuals.Enabled, ToggleESP)

CreateToggle("Infinite Jump", Config.Movement.InfiniteJump, function(state)
    Config.Movement.InfiniteJump = state
end)

CreateToggle("Noclip", Config.Movement.Noclip, function(state)
    Config.Movement.Noclip = state
end)

-- Кнопка для Gun Mod
local gunBtn = Instance.new("TextButton")
gunBtn.Size = UDim2.new(1, -10, 0, 30)
gunBtn.BackgroundColor3 = Color3.fromRGB(180, 0, 255)
gunBtn.Text = "APPLY GUN MODS"
gunBtn.TextColor3 = Color3.new(1,1,1)
gunBtn.Font = Enum.Font.GothamBold
gunBtn.Parent = ContentFrame
local gbc = Instance.new("UICorner", gunBtn); gbc.CornerRadius = UDim.new(0, 6)
gunBtn.MouseButton1Click:Connect(function()
    ModGun("M9")
    ModGun("Remington 870")
    ModGun("AK-47")
    gunBtn.Text = "GUN MODS APPLIED"
    task.wait(1)
    gunBtn.Text = "APPLY GUN MODS"
end)

--// 7. ОЧИСТКА ПРИ РЕСПАВНЕ
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    ApplySpeed()
    if Config.Visuals.Enabled then ToggleESP(true) end
end)

print("[Prison Life Suite] Loaded successfully.")