-- ============================================================
--   XTRAY SCRIPT - Vox Seas
--   github.com/ScXtray/BF
-- ============================================================

local fetcher = ...

-- ============================================================
-- SERVICES
-- ============================================================

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local PhysicsService    = game:GetService("PhysicsService")
local UserInputService  = game:GetService("UserInputService")
local VirtualUser       = game:GetService("VirtualUser")
local VIM               = game:GetService("VirtualInputManager")
local TweenService      = game:GetService("TweenService")

local Player    = Players.LocalPlayer
local _env      = getgenv and getgenv() or {}
local _huge     = math.huge

-- ============================================================
-- WAIT GAME LOAD
-- ============================================================

repeat task.wait() until game:IsLoaded()

-- Anti-AFK
Player.Idled:Connect(function()
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end)

-- ============================================================
-- LOAD LIBRARY
-- ============================================================

local Library = fetcher.load("{Repository}Library/main.luau")()

local function safeLoad(url, ...)
    local args = {...}
    local ok, result = pcall(function()
        return fetcher.load(url)(table.unpack(args))
    end)
    return (ok and result ~= nil) and result or {}
end

local FullBright = safeLoad("{Repository}Utils/Module/FullBright.luau")
if not FullBright.Toggle then FullBright = { Toggle = function() end } end

-- ============================================================
-- NOTIFY HELPER
-- ============================================================

local function Notify(cfg)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title    = tostring(cfg.Title    or "Xtray Script"),
            Text     = tostring(cfg.Text     or ""),
            Duration = tonumber(cfg.Duration or 4),
        })
    end)
end

-- ============================================================
-- GAME OBJECTS (Vox Seas structure)
-- ============================================================

local Enemys     = workspace:WaitForChild("Playability"):WaitForChild("Enemys")
local QuestsNpcs = workspace:WaitForChild("IgnoreList"):WaitForChild("Int"):WaitForChild("NPCs"):WaitForChild("Quests")

-- ============================================================
-- SETTINGS
-- ============================================================

local Settings = {
    SelectedTool  = "Sword",      -- "Sword" | "Gun" | "Melee"
    BringDistance = 300,
    FarmDistance  = 6,
    SmoothMode    = false,
    BringMobs     = true,
    AutoAttack    = true,
    TweenSpeed    = 250,
    NoClip        = true,
}

local Connections = {}

-- ============================================================
-- CHARACTER HELPERS
-- ============================================================

local function GetCharacter() return Player.Character end
local function GetRootPart()
    local c = GetCharacter(); return c and c:FindFirstChild("HumanoidRootPart")
end
local function GetHumanoid()
    local c = GetCharacter(); return c and c:FindFirstChildOfClass("Humanoid")
end

local function IsAlive(char)
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0
end

-- ============================================================
-- TWEEN MOVEMENT (dari referensi newredzv3/Tween-Module)
-- Smooth BodyVelocity based movement dengan NoClip
-- ============================================================

local ActiveTween = false
local CanCollideObjects = {}

local function ToggleNoClip(state)
    local char = GetCharacter()
    if not char then return end
    for _, v in pairs(char:GetDescendants()) do
        if v:IsA("BasePart") then
            pcall(function()
                if state then
                    v.CanCollide = false
                else
                    v.CanCollide = true
                end
            end)
        end
    end
end

local function GetHover(rootPart)
    local bv = rootPart:FindFirstChild("VS_Hover")
    if not bv then
        bv = Instance.new("BodyVelocity")
        bv.Name     = "VS_Hover"
        bv.MaxForce = Vector3.new(1e9, 1e9, 1e9)
        bv.P        = 1e9
        bv.Velocity = Vector3.zero
        bv.Parent   = rootPart
    end
    return bv
end

local function StopTween()
    ActiveTween = false
    local root = GetRootPart()
    if root then
        local hover = root:FindFirstChild("VS_Hover")
        if hover then hover:Destroy() end
        root.AssemblyLinearVelocity = Vector3.zero
    end
    ToggleNoClip(false)
end

-- Heartbeat: jaga hover velocity = 0 (biar tidak melayang liar)
RunService.Stepped:Connect(function()
    if not ActiveTween then return end
    local char = GetCharacter()
    if not char then return end
    local hum  = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    if hum and root and hum.Health > 0 then
        hum:ChangeState(Enum.HumanoidStateType.Freefall)
        local hover = GetHover(root)
        hover.Velocity = Vector3.zero
        if Settings.NoClip then ToggleNoClip(true) end
    end
end)

local function TweenTo(targetCFrame)
    StopTween()
    local char = GetCharacter()
    if not char then return false end
    local hum  = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    if not hum or hum.Health <= 0 or not root then return false end
    if hum.Sit then hum.Sit = false; return false end

    ActiveTween = true

    task.spawn(function()
        if Settings.NoClip then ToggleNoClip(true) end

        local targetY = targetCFrame.Position.Y + 3
        local mag     = (root.Position - targetCFrame.Position).Magnitude

        while ActiveTween and mag > Settings.FarmDistance do
            local cur = root.Position
            local dir = (Vector3.new(
                targetCFrame.Position.X,
                targetY,
                targetCFrame.Position.Z
            ) - cur).Unit

            local step = dir * Settings.TweenSpeed * task.wait()
            root.AssemblyLinearVelocity = Vector3.zero
            root.CFrame = CFrame.new(cur + step, targetCFrame.Position)
            mag = (root.Position - targetCFrame.Position).Magnitude
        end

        if ActiveTween then
            root.CFrame = targetCFrame * CFrame.new(0, 3, 0)
        end

        StopTween()
    end)

    return true
end

-- ============================================================
-- ENEMY HELPERS (Vox Seas specific)
-- ============================================================

local MobsFolders = {}

local function CanAttackMob(enemy)
    return (enemy:GetAttribute("Respawned") and enemy:GetAttribute("Ready")) or false
end

local function MobNameIs(enemy, name)
    return enemy:GetAttribute("OriginalName") == name
end

local function GetMobFromFolder(folder, name)
    for _, enemy in ipairs(folder:GetChildren()) do
        if CanAttackMob(enemy) and MobNameIs(enemy, name) then
            return enemy
        end
    end
end

local function GetEnemyByName(name)
    local cached = MobsFolders[name]
    if cached then
        return GetMobFromFolder(cached, name)
    end
    for _, folder in ipairs(Enemys:GetChildren()) do
        for _, enemy in ipairs(folder:GetChildren()) do
            if MobNameIs(enemy, name) then
                MobsFolders[name] = folder
                return GetMobFromFolder(folder, name)
            end
        end
    end
end

local function GetNearestEnemy(nameFilter)
    local root = GetRootPart()
    if not root then return nil end
    local nearest, nearestDist = nil, _huge

    for _, folder in ipairs(Enemys:GetChildren()) do
        for _, enemy in ipairs(folder:GetChildren()) do
            if CanAttackMob(enemy) then
                local pass = (not nameFilter or nameFilter == "" or MobNameIs(enemy, nameFilter))
                if pass then
                    local pp = enemy:FindFirstChild("HumanoidRootPart")
                    local hum = enemy:FindFirstChildOfClass("Humanoid")
                    if pp and hum and hum.Health > 0 then
                        local dist = (pp.Position - root.Position).Magnitude
                        if dist < nearestDist then
                            nearest     = enemy
                            nearestDist = dist
                        end
                    end
                end
            end
        end
    end

    return nearest
end

-- ============================================================
-- BRING MOBS (Vox Seas style dengan BodyVelocity)
-- ============================================================

local function BringMobs(baseMob)
    if not baseMob or not baseMob.Parent then return end
    local originalName  = baseMob:GetAttribute("OriginalName")
    local baseRoot      = baseMob:FindFirstChild("HumanoidRootPart")
    if not baseRoot then return end
    local bringPos = baseRoot.Position

    pcall(sethiddenproperty or (function()end), Player, "SimulationRadius", 1250)

    for _, enemy in ipairs(baseMob.Parent:GetChildren()) do
        if not IsAlive(enemy) then continue end
        if enemy:GetAttribute("OriginalName") ~= originalName then continue end
        local rp = enemy:FindFirstChild("HumanoidRootPart")
        if rp and (bringPos - rp.Position).Magnitude <= Settings.BringDistance then
            pcall(function()
                if not rp:FindFirstChild("BringBV") then
                    local bv = Instance.new("BodyVelocity", rp)
                    bv.Name     = "BringBV"
                    bv.Velocity = Vector3.zero
                    bv.MaxForce = Vector3.one * _huge
                end
                rp.Size         = Vector3.one * 50
                rp.CFrame       = baseRoot.CFrame
                rp.CanCollide   = false
            end)
        end
    end
end

-- ============================================================
-- TOOL EQUIP (Vox Seas tool attribute system)
-- ============================================================

local EquippedTool = nil

local function IsSelectedTool(tool)
    return tool:GetAttribute(Settings.SelectedTool .. "Type")
end

local function EquipTool()
    local char = GetCharacter()
    if not IsAlive(char) then return nil end

    -- Cek yang sudah equip
    if EquippedTool and IsSelectedTool(EquippedTool) then
        if EquippedTool.Parent == Player.Backpack then
            char.Humanoid:EquipTool(EquippedTool)
        elseif EquippedTool.Parent ~= char then
            EquippedTool = nil
        end
        return EquippedTool
    end

    -- Cek karakter
    local current = char:FindFirstChildOfClass("Tool")
    if current and IsSelectedTool(current) then
        EquippedTool = current
        return EquippedTool
    end

    -- Cari di backpack
    for _, tool in ipairs(Player.Backpack:GetChildren()) do
        if tool:IsA("Tool") and IsSelectedTool(tool) then
            EquippedTool = tool
            char.Humanoid:EquipTool(tool)
            return EquippedTool
        end
    end

    return nil
end

-- ============================================================
-- ATTACK
-- ============================================================

local function Attack()
    if not Settings.AutoAttack then return end
    local char = GetCharacter()
    if not char then return end
    -- Klik mouse kiri ke arah musuh
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:Button1Down(Vector2.new(1e4, 1e4))
    end)
    -- Aktifkan tool jika ada
    local tool = char:FindFirstChildOfClass("Tool")
    if tool then
        pcall(function()
            tool.Enabled = true
            tool:Activate()
        end)
    end
end

-- ============================================================
-- SCAN ENEMY LIST
-- ============================================================

local EnemyList = {}

local function BuildEnemyList()
    table.clear(EnemyList)
    local seen = {}
    for _, folder in ipairs(Enemys:GetChildren()) do
        for _, enemy in ipairs(folder:GetChildren()) do
            local name = enemy:GetAttribute("OriginalName")
            if name and not seen[name] then
                seen[name] = true
                table.insert(EnemyList, name)
            end
        end
    end
    table.sort(EnemyList)
    return EnemyList
end

task.spawn(function()
    task.wait(3)
    BuildEnemyList()
end)

-- ============================================================
-- FARM LOOPS
-- ============================================================

-- Auto Farm (farm musuh tertentu atau terdekat)
local function StartFarmLoop()
    if _env.VS_FarmLoaded then return end
    _env.VS_FarmLoaded = true

    task.spawn(function()
        while task.wait(Settings.SmoothMode and 0.25 or 0.07) do
            if not _env.VS_AutoFarm then continue end

            pcall(function()
                local targetName = _env.VS_FarmTarget ~= "" and _env.VS_FarmTarget or nil
                local enemy = targetName and GetEnemyByName(targetName) or GetNearestEnemy()
                local root  = GetRootPart()

                if not enemy or not root then return end

                local pp  = enemy:FindFirstChild("HumanoidRootPart")
                local hum = enemy:FindFirstChildOfClass("Humanoid")
                if not pp or not hum or hum.Health <= 0 then return end

                local dist = (pp.Position - root.Position).Magnitude

                -- Tween ke musuh jika jauh
                if dist > Settings.FarmDistance + 5 then
                    TweenTo(pp.CFrame)
                    task.wait(0.1)
                    return
                end

                -- Sudah dekat: equip, bring, attack
                EquipTool()

                if Settings.BringMobs then
                    BringMobs(enemy)
                end

                Attack()
            end)
        end
    end)
end

-- ============================================================
-- ESP
-- ============================================================

local ESPDrawings   = {}
local ESPConnection = nil
local DrawAvail     = (typeof(Drawing) ~= "nil" and pcall(function() Drawing.new("Circle"):Remove() end))

local function newDraw(kind, props)
    if not DrawAvail then return {} end
    local ok, d = pcall(Drawing.new, kind)
    if not ok then return {} end
    for k, v in pairs(props) do pcall(function() d[k] = v end) end
    return d
end

local function removeDraw(key)
    if ESPDrawings[key] then
        for _, d in pairs(ESPDrawings[key]) do pcall(function() d:Remove() end) end
        ESPDrawings[key] = nil
    end
end

local function runESP()
    local seenKeys = {}
    local myRoot   = GetRootPart()
    local cam      = workspace.CurrentCamera
    if not cam then return end

    for _, folder in ipairs(Enemys:GetChildren()) do
        for _, enemy in ipairs(folder:GetChildren()) do
            local pp  = enemy:FindFirstChild("HumanoidRootPart")
            local hum = enemy:FindFirstChildOfClass("Humanoid")
            if pp and hum and hum.Health > 0 then
                local screen, onScreen = cam:WorldToViewportPoint(pp.Position)
                local key = "vs_" .. enemy:GetDebugId()
                seenKeys[key] = true
                local dist = myRoot and (pp.Position - myRoot.Position).Magnitude or 0

                if onScreen and dist <= 1000 then
                    if not ESPDrawings[key] then
                        ESPDrawings[key] = {
                            name = newDraw("Text", { Color=Color3.fromRGB(80,200,255),  Size=13, Center=true, Outline=true, OutlineColor=Color3.new(0,0,0), Visible=false }),
                            dist = newDraw("Text", { Color=Color3.fromRGB(200,200,200), Size=11, Center=true, Outline=true, OutlineColor=Color3.new(0,0,0), Visible=false }),
                        }
                    end
                    local sp = Vector2.new(screen.X, screen.Y)
                    local label = enemy:GetAttribute("OriginalName") or enemy.Name
                    ESPDrawings[key].name.Text     = label
                    ESPDrawings[key].name.Position = sp + Vector2.new(0, -18)
                    ESPDrawings[key].name.Visible  = true
                    ESPDrawings[key].dist.Text     = string.format("%.0fm", dist)
                    ESPDrawings[key].dist.Position = sp + Vector2.new(0, -5)
                    ESPDrawings[key].dist.Visible  = true
                else
                    removeDraw(key)
                end
            end
        end
    end

    for key in pairs(ESPDrawings) do
        if not seenKeys[key] then removeDraw(key) end
    end
end

local function ToggleESP(v)
    if v then
        if not ESPConnection and DrawAvail then
            ESPConnection = RunService.RenderStepped:Connect(function() pcall(runESP) end)
        end
    else
        if ESPConnection then ESPConnection:Disconnect(); ESPConnection = nil end
        for key in pairs(ESPDrawings) do removeDraw(key) end
    end
end

-- ============================================================
-- BUILD UI
-- ============================================================

local Window = Library:MakeWindow({
    Name           = "Xtray Script — Vox Seas",
    HidePremium    = false,
    SaveConfig     = true,
    ConfigFileName = "XtrayScript_VoxSeas",
})

-- ============================================================
-- TAB: FARM
-- ============================================================

local FarmTab = Window:MakeTab({ "Farm", "rbxassetid://10734933961" })

FarmTab:AddSection("Auto Farm")

local FarmStatus = FarmTab:AddParagraph({ "Status", "Tidak aktif" })

-- Refresh enemy list saat tab dibuka
local EnemyOptions = { "" }
task.spawn(function()
    task.wait(3)
    local list = BuildEnemyList()
    if #list > 0 then
        for _, v in ipairs(list) do
            table.insert(EnemyOptions, v)
        end
    end
end)

FarmTab:AddDropdown({
    "Target Musuh (kosong = terdekat)",
    EnemyOptions,
    "",
    function(v)
        _env.VS_FarmTarget = v
        Notify({ Title="Xtray Script", Text="Target: "..(v~="" and v or "Musuh Terdekat"), Duration=2 })
    end,
    "VSFarmTarget"
})

FarmTab:AddToggle({
    "Bring Mobs ke Player",
    true,
    function(v)
        Settings.BringMobs = v
    end,
    "VSBringMobs"
})

FarmTab:AddToggle({
    "Auto Farm",
    false,
    function(v)
        _env.VS_AutoFarm = v
        if v then
            _env.VS_FarmTarget = _env.VS_FarmTarget or ""
            FarmStatus:Set("Status", "Aktif — "..((_env.VS_FarmTarget or "") ~= "" and _env.VS_FarmTarget or "Terdekat"))
            StartFarmLoop()
            Notify({ Title="Xtray Script", Text="Auto Farm aktif!", Duration=3 })
        else
            FarmStatus:Set("Status", "Tidak aktif")
            StopTween()
            Notify({ Title="Xtray Script", Text="Auto Farm dimatikan.", Duration=3 })
        end
    end,
    "VSAutoFarm"
})

FarmTab:AddButton({
    "Scan Musuh di Map",
    function()
        local list = BuildEnemyList()
        Notify({
            Title    = "Xtray Script",
            Text     = (#list > 0) and ("Musuh: "..table.concat(list, ", "):sub(1, 120)) or "Tidak ada musuh ditemukan.",
            Duration = 6
        })
    end
})

-- ============================================================
-- TAB: SENJATA & COMBAT
-- ============================================================

local CombatTab = Window:MakeTab({ "Combat", "rbxassetid://10747384394" })

CombatTab:AddSection("Tipe Senjata")

CombatTab:AddDropdown({
    "Selected Tool Type",
    { "Sword", "Gun", "Melee", "Power" },
    "Sword",
    function(v)
        Settings.SelectedTool = v
        EquippedTool = nil
        Notify({ Title="Xtray Script", Text="Tool type: "..v, Duration=2 })
    end,
    "VSToolType"
})

CombatTab:AddToggle({
    "Auto Attack",
    true,
    function(v)
        Settings.AutoAttack = v
    end,
    "VSAutoAttack"
})

CombatTab:AddSection("Tween Speed")

CombatTab:AddSlider({
    "Tween Speed (kecepatan gerak)",
    50,
    800,
    10,
    250,
    function(v)
        Settings.TweenSpeed = v
    end,
    "VSTweenSpeed"
})

CombatTab:AddSlider({
    "Farm Distance (jarak berhenti ke musuh)",
    3,
    20,
    1,
    6,
    function(v)
        Settings.FarmDistance = v
    end,
    "VSFarmDist"
})

CombatTab:AddToggle({
    "Smooth Mode (lebih stabil, sedikit lambat)",
    false,
    function(v)
        Settings.SmoothMode = v
    end,
    "VSSmoothMode"
})

CombatTab:AddToggle({
    "NoClip saat Farm",
    true,
    function(v)
        Settings.NoClip = v
        if not v then ToggleNoClip(false) end
    end,
    "VSNoClip"
})

CombatTab:AddSection("Bring Mobs")

CombatTab:AddSlider({
    "Bring Distance (radius tarik musuh)",
    100,
    1000,
    50,
    300,
    function(v)
        Settings.BringDistance = v
    end,
    "VSBringDist"
})

CombatTab:AddSection("No Stun")

CombatTab:AddToggle({
    "No Stun",
    false,
    function(v)
        _env.VS_NoStun = v
        if v then
            local function hookStun(char)
                if not char then return end
                local stun = char:FindFirstChild("Stun")
                if stun then
                    if Connections.NoStun then Connections.NoStun:Disconnect() end
                    Connections.NoStun = stun:GetPropertyChangedSignal("Value"):Connect(function()
                        if _env.VS_NoStun then stun.Value = 0 end
                    end)
                end
            end
            hookStun(GetCharacter())
            if Connections.NoStunAdded then Connections.NoStunAdded:Disconnect() end
            Connections.NoStunAdded = Player.CharacterAdded:Connect(hookStun)
        else
            if Connections.NoStun then Connections.NoStun:Disconnect(); Connections.NoStun = nil end
            if Connections.NoStunAdded then Connections.NoStunAdded:Disconnect(); Connections.NoStunAdded = nil end
        end
        Notify({ Title="Xtray Script", Text=v and "No Stun aktif." or "No Stun dimatikan.", Duration=2 })
    end,
    "VSNoStun"
})

-- ============================================================
-- TAB: VISUAL
-- ============================================================

local VisualTab = Window:MakeTab({ "Visual", "rbxassetid://10734943674" })

VisualTab:AddSection("Lighting")

VisualTab:AddToggle({
    "Full Bright",
    false,
    function(v) FullBright:Toggle(v) end,
    "VSFullBright"
})

VisualTab:AddSection("Movement")

VisualTab:AddToggle({
    "Speed Hack",
    false,
    function(v)
        if v then
            Connections.SpeedHack = RunService.Heartbeat:Connect(function()
                if not _env.VS_SpeedHack then return end
                local hum = GetHumanoid()
                if hum then hum.WalkSpeed = _env.VS_WalkSpeed or 58 end
            end)
            _env.VS_SpeedHack = true
        else
            _env.VS_SpeedHack = false
            local hum = GetHumanoid()
            if hum then hum.WalkSpeed = 16 end
            if Connections.SpeedHack then Connections.SpeedHack:Disconnect(); Connections.SpeedHack = nil end
        end
    end,
    "VSSpeedHack"
})

VisualTab:AddSlider({
    "Walk Speed", 16, 500, 1, 58,
    function(v)
        _env.VS_WalkSpeed = v
        if _env.VS_SpeedHack then
            local hum = GetHumanoid()
            if hum then hum.WalkSpeed = v end
        end
    end,
    "VSWalkSpeed"
})

VisualTab:AddSlider({
    "Jump Power", 50, 500, 1, 150,
    function(v)
        local hum = GetHumanoid()
        if hum then hum.JumpPower = v end
    end,
    "VSJumpPower"
})

VisualTab:AddToggle({
    "Infinite Jump",
    false,
    function(v)
        if v then
            Connections.InfJump = UserInputService.JumpRequest:Connect(function()
                if not _env.VS_InfJump then return end
                local hum = GetHumanoid()
                if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
            end)
            _env.VS_InfJump = true
        else
            _env.VS_InfJump = false
            if Connections.InfJump then Connections.InfJump:Disconnect(); Connections.InfJump = nil end
        end
    end,
    "VSInfJump"
})

VisualTab:AddSection("ESP Musuh")

VisualTab:AddToggle({
    "Enable ESP",
    false,
    function(v) ToggleESP(v) end,
    "VSEspEnabled"
})

-- ============================================================
-- TAB: TELEPORT
-- ============================================================

local TeleportTab = Window:MakeTab({ "Teleport", "rbxassetid://10709791437" })

TeleportTab:AddSection("Teleport ke Musuh")

TeleportTab:AddButton({
    "TP ke Musuh Target",
    function()
        local name = _env.VS_FarmTarget ~= "" and _env.VS_FarmTarget or nil
        local enemy = name and GetEnemyByName(name) or GetNearestEnemy()
        if enemy then
            local pp = enemy:FindFirstChild("HumanoidRootPart")
            if pp then
                TweenTo(pp.CFrame)
                Notify({ Title="Xtray Script", Text="Tween ke "..(enemy:GetAttribute("OriginalName") or enemy.Name), Duration=3 })
            end
        else
            Notify({ Title="Xtray Script", Text="Musuh tidak ditemukan.", Duration=3 })
        end
    end
})

TeleportTab:AddButton({
    "Stop Tween",
    function()
        StopTween()
        Notify({ Title="Xtray Script", Text="Tween dihentikan.", Duration=2 })
    end
})

TeleportTab:AddSection("Teleport ke Quest NPC")

TeleportTab:AddButton({
    "TP ke Quest NPC Terdekat",
    function()
        local root = GetRootPart()
        if not root then return end
        local nearest, nearestDist = nil, _huge
        for _, npc in ipairs(QuestsNpcs:GetDescendants()) do
            if npc:IsA("Model") and npc.PrimaryPart then
                local dist = (npc.PrimaryPart.Position - root.Position).Magnitude
                if dist < nearestDist then
                    nearest     = npc
                    nearestDist = dist
                end
            end
        end
        if nearest then
            TweenTo(nearest.PrimaryPart.CFrame)
            Notify({ Title="Xtray Script", Text="Tween ke "..nearest.Name, Duration=3 })
        else
            Notify({ Title="Xtray Script", Text="Quest NPC tidak ditemukan.", Duration=3 })
        end
    end
})

-- ============================================================
-- TAB: MISC
-- ============================================================

local MiscTab = Window:MakeTab({ "Misc", "rbxassetid://10709752996" })

MiscTab:AddSection("Anti AFK")

MiscTab:AddToggle({
    "Anti AFK",
    false,
    function(v)
        _env.VS_AntiAFK = v
        if v then
            Connections.AntiAFK = RunService.Heartbeat:Connect(function()
                if not _env.VS_AntiAFK then return end
                if tick() % 60 < 0.05 then
                    pcall(function()
                        VIM:SendKeyEvent(true,  Enum.KeyCode.W, false, game)
                        VIM:SendKeyEvent(false, Enum.KeyCode.W, false, game)
                    end)
                end
            end)
            Notify({ Title="Xtray Script", Text="Anti AFK aktif.", Duration=3 })
        else
            if Connections.AntiAFK then Connections.AntiAFK:Disconnect(); Connections.AntiAFK = nil end
        end
    end,
    "VSAntiAFK"
})

MiscTab:AddSection("Auto Respawn")

MiscTab:AddToggle({
    "Auto Respawn",
    false,
    function(v)
        _env.VS_AutoRespawn = v
        if v then
            Connections.AutoRespawn = RunService.Heartbeat:Connect(function()
                if not _env.VS_AutoRespawn then return end
                local hum = GetHumanoid()
                if hum and hum.Health <= 0 then
                    task.wait(1)
                    pcall(function() Player:LoadCharacter() end)
                end
            end)
        else
            if Connections.AutoRespawn then Connections.AutoRespawn:Disconnect(); Connections.AutoRespawn = nil end
        end
    end,
    "VSAutoRespawn"
})

MiscTab:AddSection("Info")

MiscTab:AddButton({
    "Info Karakter",
    function()
        local hum   = GetHumanoid()
        local hp    = hum and math.floor(hum.Health)    or 0
        local maxHp = hum and math.floor(hum.MaxHealth) or 0
        local data  = Player:FindFirstChild("Data")
        local lv    = data and data:FindFirstChild("Level") and data.Level.Value or "?"
        Notify({
            Title    = "Xtray Script",
            Text     = ("Level: %s | HP: %d/%d"):format(tostring(lv), hp, maxHp),
            Duration = 5
        })
    end
})

MiscTab:AddButton({
    "Jumlah Musuh di Map",
    function()
        local count = 0
        for _, folder in ipairs(Enemys:GetChildren()) do
            for _, enemy in ipairs(folder:GetChildren()) do
                local hum = enemy:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then count = count + 1 end
            end
        end
        Notify({ Title="Xtray Script", Text=("Total musuh aktif: %d"):format(count), Duration=4 })
    end
})

MiscTab:AddButton({
    "Refresh Daftar Musuh",
    function()
        local list = BuildEnemyList()
        Notify({
            Title    = "Xtray Script",
            Text     = ("Ditemukan %d jenis musuh."):format(#list),
            Duration = 4
        })
    end
})

-- ============================================================
-- NOTIFIKASI LOAD
-- ============================================================

Notify({
    Title    = "Xtray Script",
    Text     = "Vox Seas berhasil dimuat! Farm + Tween Movement siap.",
    Duration = 5
})
