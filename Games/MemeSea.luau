-- ============================================================
--   XTRAY SCRIPT - Meme Sea
--   github.com/XtrayScript/XtrayScript
-- ============================================================

local fetcher = ...

-- ============================================================
-- LOAD LIBRARY & MODULES
-- ============================================================

local Library = fetcher.load("{Repository}Library/main.luau")()

local function safeLoad(url, ...)
    local args = {...}
    local ok, result = pcall(function()
        return fetcher.load(url)(table.unpack(args))
    end)
    return (ok and result ~= nil) and result or {}
end

local Movement   = safeLoad("{Repository}Utils/Module/Movement.luau")
local FullBright = safeLoad("{Repository}Utils/Module/FullBright.luau")
if not Movement.Toggle   then Movement   = { Toggle=function()end, SetSpeed=function()end, SetJump=function()end } end
if not FullBright.Toggle then FullBright = { Toggle=function()end } end

-- ============================================================
-- SERVICES
-- ============================================================

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService  = game:GetService("UserInputService")
local VirtualUser       = game:GetService("VirtualUser")
local VIM               = game:GetService("VirtualInputManager")

local Player      = Players.LocalPlayer
local _env        = getgenv and getgenv() or {}
local CFrame_new  = CFrame.new
local CFrame_Ang  = CFrame.Angles
local _huge       = math.huge

-- ============================================================
-- WAIT GAME LOAD
-- ============================================================

repeat task.wait() until game:IsLoaded()

-- Anti-AFK bawaan
Player.Idled:Connect(function()
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end)

-- ============================================================
-- GAME OBJECTS
-- ============================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local rs_Monsters   = ReplicatedStorage:WaitForChild("MonsterSpawn")
local Modules       = ReplicatedStorage:WaitForChild("ModuleScript")
local OtherEvent    = ReplicatedStorage:WaitForChild("OtherEvent")
local Monsters      = workspace:WaitForChild("Monster")
local NPCs          = workspace:WaitForChild("NPCs")
local Location      = workspace:WaitForChild("Location")

local Quests_Npc    = NPCs:WaitForChild("Quests_Npc")
local EnemyLocation = Location:WaitForChild("Enemy_Location")
local QuestLocation = Location:WaitForChild("QuestLocaion")

local QuestFolder   = Player:WaitForChild("QuestFolder")
local Ability       = Player:WaitForChild("Ability")
local PlayerData    = Player:WaitForChild("PlayerData")
local PlayerLevel   = PlayerData:WaitForChild("Level")

local MQuestSettings = require(Modules:WaitForChild("Quest_Settings"))
local MSetting       = require(Modules:WaitForChild("Setting"))

local sethiddenproperty = sethiddenproperty or (function()end)

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
-- SETTINGS
-- ============================================================

local Settings = {
    BringMobs    = true,
    FarmDistance = 9,
    AutoHaki     = true,
    AutoClick    = true,
    ToolFarm     = "Fight",
    AutoStats_Points = 1,
}

Settings.FarmCFrame = CFrame_new(0, Settings.FarmDistance, 0) * CFrame_Ang(math.rad(-90), 0, 0)

-- ============================================================
-- LOAD DATA (Quest, Enemies)
-- ============================================================

local Loaded = {
    WeaponsList   = { "Fight", "Power", "Weapon" },
    EnemeiesList  = {},
    EnemiesQuests = {},
    Quests        = {},
}

for Npc, Quest in pairs(MQuestSettings) do
    if QuestLocation:FindFirstChild(Npc) then
        table.insert(Loaded.Quests, {
            RaidBoss     = Quest.Raid_Boss,
            SpecialQuest = Quest.Special_Quest,
            QuestPos     = QuestLocation[Npc].CFrame,
            EnemyPos     = EnemyLocation[Quest.Target].CFrame,
            Level        = Quest.LevelNeed,
            Enemy        = Quest.Target,
            NpcName      = Npc,
        })
    end
end

table.sort(Loaded.Quests, function(a, b) return a.Level > b.Level end)

for _, v in ipairs(Loaded.Quests) do
    table.insert(Loaded.EnemeiesList, v.Enemy)
    Loaded.EnemiesQuests[v.Enemy] = v.NpcName
end

-- ============================================================
-- HELPER FUNCTIONS
-- ============================================================

local function GetCharacter() return Player.Character end
local function GetRootPart()
    local c = GetCharacter(); return c and c:FindFirstChild("HumanoidRootPart")
end
local function GetHumanoid()
    local c = GetCharacter(); return c and c:FindFirstChildOfClass("Humanoid")
end

local function IsAlive(Char)
    local Hum = Char and Char:FindFirstChild("Humanoid")
    return Hum and Hum.Health > 0
end

local function AbilityUnlocked(Ablt)
    return Ability:FindFirstChild(Ablt) and Ability[Ablt].Value
end

local function GetPlayerLevel() return PlayerLevel.Value end

local function GoTo(cf)
    local Char = GetCharacter()
    if IsAlive(Char) then Char:SetPrimaryPartCFrame(cf) end
end

local function EquipWeapon()
    local Backpack = Player:FindFirstChild("Backpack")
    local Char = GetCharacter()
    if not IsAlive(Char) or not Backpack then return end
    -- Cek apakah sudah equip
    for _, v in ipairs(Char:GetChildren()) do
        if v:IsA("Tool") and v.ToolTip:find(Settings.ToolFarm) then return end
    end
    -- Equip dari backpack
    for _, v in ipairs(Backpack:GetChildren()) do
        if v:IsA("Tool") and v.ToolTip:find(Settings.ToolFarm) then
            Char.Humanoid:EquipTool(v)
            return
        end
    end
end

local function PlayerClick()
    local Char = GetCharacter()
    if not Char then return end
    if Settings.AutoClick then
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:Button1Down(Vector2.new(1e4, 1e4))
        end)
    end
    if Settings.AutoHaki and Char:FindFirstChild("AuraColor_Folder") and AbilityUnlocked("Aura") then
        if #Char.AuraColor_Folder:GetChildren() < 1 then
            pcall(function() OtherEvent.MainEvents.Ability:InvokeServer("Aura") end)
        end
    end
end

local function BringMobsTo(EnemieName, cf)
    for _, v in ipairs(Monsters:GetChildren()) do
        if v.Name == EnemieName and IsAlive(v) then
            local PP, Hum = v.PrimaryPart, v.Humanoid
            if PP and (PP.Position - cf.p).Magnitude < 500 then
                pcall(function()
                    Hum.WalkSpeed = 0
                    Hum:ChangeState(14)
                    PP.CFrame      = cf
                    PP.CanCollide  = false
                    PP.Transparency = 1
                    PP.Size        = Vector3.new(50, 50, 50)
                end)
            end
        end
    end
    pcall(sethiddenproperty, Player, "SimulationRadius", _huge)
end

local function GetNextEnemy(EnemieName)
    for _, v in ipairs(Monsters:GetChildren()) do
        if (not EnemieName or v.Name == EnemieName) and IsAlive(v) then
            return v
        end
    end
    return false
end

local function KillMonster(EnemieName)
    local Enemy = (typeof(EnemieName) == "Instance") and EnemieName or GetNextEnemy(EnemieName)
    if IsAlive(Enemy) and Enemy.PrimaryPart then
        GoTo(Enemy.PrimaryPart.CFrame * Settings.FarmCFrame)
        EquipWeapon()
        if not Enemy:FindFirstChild("Reverse_Mark") then PlayerClick() end
        if Settings.BringMobs then BringMobsTo(EnemieName, Enemy.PrimaryPart.CFrame) end
        return true
    end
end

-- ============================================================
-- QUEST HELPERS
-- ============================================================

local function GetCurrentQuest()
    for _, Quest in pairs(Loaded.Quests) do
        if Quest.Level <= GetPlayerLevel() and not Quest.RaidBoss and not Quest.SpecialQuest then
            return Quest
        end
    end
end

local function CheckQuest()
    for _, v in ipairs(QuestFolder:GetChildren()) do
        if v.Target.Value ~= "None" then return v end
    end
end

local function VerifyQuest(QName)
    local Quest = CheckQuest()
    return Quest and Quest.QuestGiver.Value == QName
end

local function ClearQuests(Ignore)
    for _, v in ipairs(QuestFolder:GetChildren()) do
        if v.QuestGiver.Value ~= Ignore and v.Target.Value ~= "None" then
            pcall(function()
                OtherEvent.QuestEvents.Quest:FireServer("Abandon_Quest", { QuestSlot = v.Name })
            end)
        end
    end
end

local function TakeQuest(QuestName, cf)
    local QuestGiver = Quests_Npc:FindFirstChild(QuestName)
    if QuestGiver and Player:DistanceFromCharacter(QuestGiver.WorldPivot.p) < 5 then
        pcall(fireproximityprompt, QuestGiver.Block.QuestPrompt)
        task.wait(0.1)
        return
    end
    GoTo(cf or QuestLocation[QuestName].CFrame)
end

-- ============================================================
-- FARM LOOP
-- ============================================================

_env.FarmFuncs = {
    { "Level Farm", function()
        local Quest       = GetCurrentQuest()
        local QuestActive = CheckQuest()
        if Quest then
            if QuestActive then
                local _QuestName = QuestActive.QuestGiver.Value
                if _QuestName == Quest.NpcName then
                    if not KillMonster(Quest.Enemy) then GoTo(Quest.EnemyPos) end
                else
                    if not KillMonster(QuestActive.Target.Value) then
                        GoTo(QuestLocation[_QuestName].CFrame)
                    end
                end
            else
                TakeQuest(Quest.NpcName)
            end
        end
        return true
    end },
    { "FS Enemie", function()
        local Enemy = _env.SelectedEnemy
        local Quest = Loaded.EnemiesQuests[Enemy]
        if VerifyQuest(Quest) or not _env["FS Take Quest"] then
            if not KillMonster(Enemy) then GoTo(EnemyLocation[Enemy].CFrame) end
        else
            ClearQuests(Quest)
            TakeQuest(Quest)
        end
        return true
    end },
    { "Nearest Farm", function()
        return KillMonster(GetNextEnemy())
    end },
}

if not _env.XtrayMemeSea_FarmLoaded then
    _env.XtrayMemeSea_FarmLoaded = true
    task.spawn(function()
        while task.wait() do
            for _, f in ipairs(_env.FarmFuncs) do
                if _env[f[1]] then
                    local ok, r = pcall(f[2])
                    if ok and r then break end
                end
            end
        end
    end)
end

-- ============================================================
-- AUTO STATS LOOP
-- ============================================================

local StatsName = {
    ["Power"]  = "MemePowerLevel",
    ["Health"] = "DefenseLevel",
    ["Weapon"] = "SwordLevel",
    ["Melee"]  = "MeleeLevel",
}

local SelectedStats = {}

if not _env.XtrayMemeSea_StatsLoaded then
    _env.XtrayMemeSea_StatsLoaded = true
    task.spawn(function()
        while task.wait(0.5) do
            if not _env.AutoStats then continue end
            local _Points = PlayerData:FindFirstChild("SkillPoint")
            if not _Points then continue end
            for stat, enabled in pairs(SelectedStats) do
                if enabled and _Points.Value > 0 then
                    local _s = PlayerData:FindFirstChild(StatsName[stat])
                    if _s and _s.Value < MSetting.Setting.MaxLevel then
                        pcall(function()
                            OtherEvent.MainEvents.StatsFunction:InvokeServer({
                                Target = StatsName[stat],
                                Action = "UpgradeStats",
                                Amount = math.clamp(Settings.AutoStats_Points, 0, MSetting.Setting.MaxLevel - _s.Value),
                            })
                        end)
                    end
                end
            end
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
    for _, enemy in ipairs(Monsters:GetChildren()) do
        local pp  = enemy.PrimaryPart or enemy:FindFirstChildOfClass("BasePart")
        local hum = enemy:FindFirstChildOfClass("Humanoid")
        if pp and hum and hum.Health > 0 then
            local screen, onScreen = cam:WorldToViewportPoint(pp.Position)
            local key = "ms_" .. enemy:GetDebugId()
            seenKeys[key] = true
            local dist = myRoot and (pp.Position - myRoot.Position).Magnitude or 0
            if onScreen and dist <= 800 then
                if not ESPDrawings[key] then
                    ESPDrawings[key] = {
                        name = newDraw("Text", { Color=Color3.fromRGB(255,120,60), Size=13, Center=true, Outline=true, OutlineColor=Color3.new(0,0,0), Visible=false }),
                        dist = newDraw("Text", { Color=Color3.fromRGB(200,200,200), Size=11, Center=true, Outline=true, OutlineColor=Color3.new(0,0,0), Visible=false }),
                    }
                end
                local sp = Vector2.new(screen.X, screen.Y)
                ESPDrawings[key].name.Text     = enemy.Name
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
-- CONNECTIONS TABLE
-- ============================================================

local Connections = {}

-- ============================================================
-- BUILD UI
-- ============================================================

local Window = Library:MakeWindow({
    Name           = "Xtray Script — Meme Sea",
    HidePremium    = false,
    SaveConfig     = true,
    ConfigFileName = "XtrayScript_MemeSea",
})

-- ============================================================
-- TAB: AUTO FARM
-- ============================================================

local FarmTab = Window:MakeTab({ "Farm", "rbxassetid://10734933961" })

FarmTab:AddSection("Auto Farm")

FarmTab:AddParagraph({
    "Info",
    ("Level: %d / %d | Tool: %s"):format(GetPlayerLevel(), MSetting.Setting.MaxLevel, Settings.ToolFarm)
})

FarmTab:AddDropdown({
    "Weapon Tool",
    Loaded.WeaponsList,
    "Fight",
    function(v)
        Settings.ToolFarm = v
        Notify({ Title="Xtray Script", Text="Farm tool: "..v, Duration=2 })
    end,
    "FarmTool"
})

FarmTab:AddToggle({
    "Auto Farm Level (Quest Otomatis)",
    false,
    function(v)
        _env["Level Farm"] = v
        Notify({ Title="Xtray Script", Text=v and "Level Farm aktif!" or "Level Farm dimatikan.", Duration=3 })
    end,
    "LevelFarm"
})

FarmTab:AddToggle({
    "Auto Farm Musuh Terdekat",
    false,
    function(v)
        _env["Nearest Farm"] = v
        Notify({ Title="Xtray Script", Text=v and "Nearest Farm aktif!" or "Nearest Farm dimatikan.", Duration=3 })
    end,
    "NearestFarm"
})

FarmTab:AddSection("Farm Musuh Pilihan")

FarmTab:AddDropdown({
    "Pilih Musuh",
    #Loaded.EnemeiesList > 0 and Loaded.EnemeiesList or { "Memuat..." },
    Loaded.EnemeiesList[1] or "Memuat...",
    function(v)
        _env.SelectedEnemy = v
        Notify({ Title="Xtray Script", Text="Target: "..v, Duration=2 })
    end,
    "SelectedEnemy"
})

FarmTab:AddToggle({
    "Auto Farm Musuh Pilihan",
    false,
    function(v)
        _env["FS Enemie"] = v
        Notify({ Title="Xtray Script", Text=v and "Enemy Farm aktif!" or "Enemy Farm dimatikan.", Duration=3 })
    end,
    "EnemyFarm"
})

FarmTab:AddToggle({
    "Auto Ambil Quest (untuk musuh pilihan)",
    true,
    function(v)
        _env["FS Take Quest"] = v
    end,
    "FSTakeQuest"
})

-- Init FS Take Quest default on
_env["FS Take Quest"] = true

-- ============================================================
-- TAB: AUTO STATS
-- ============================================================

local StatsTab = Window:MakeTab({ "Stats", "rbxassetid://10709752996" })

StatsTab:AddSection("Auto Upgrade Stats")

StatsTab:AddSlider({
    "Poin per Upgrade",
    1,
    100,
    1,
    1,
    function(v) Settings.AutoStats_Points = v end,
    "StatsPoints"
})

StatsTab:AddToggle({
    "Auto Stats",
    false,
    function(v)
        _env.AutoStats = v
        Notify({ Title="Xtray Script", Text=v and "Auto Stats aktif!" or "Auto Stats dimatikan.", Duration=3 })
    end,
    "AutoStats"
})

StatsTab:AddSection("Pilih Stats yang Diupgrade")

StatsTab:AddToggle({
    "Power (Meme Power Level)",
    false,
    function(v) SelectedStats["Power"] = v end,
    "StatsPower"
})

StatsTab:AddToggle({
    "Health (Defense Level)",
    false,
    function(v) SelectedStats["Health"] = v end,
    "StatsHealth"
})

StatsTab:AddToggle({
    "Weapon (Sword Level)",
    false,
    function(v) SelectedStats["Weapon"] = v end,
    "StatsWeapon"
})

StatsTab:AddToggle({
    "Melee (Melee Level)",
    false,
    function(v) SelectedStats["Melee"] = v end,
    "StatsMelee"
})

-- ============================================================
-- TAB: SETTINGS COMBAT
-- ============================================================

local SettingsTab = Window:MakeTab({ "Settings", "rbxassetid://10709791437" })

SettingsTab:AddSection("Pengaturan Combat")

SettingsTab:AddToggle({
    "Bring Mobs (tarik musuh ke player)",
    true,
    function(v)
        Settings.BringMobs = v
        Notify({ Title="Xtray Script", Text=v and "Bring Mobs aktif." or "Bring Mobs dimatikan.", Duration=2 })
    end,
    "BringMobs"
})

SettingsTab:AddToggle({
    "Auto Haki (aktifkan Aura otomatis)",
    true,
    function(v)
        Settings.AutoHaki = v
        Notify({ Title="Xtray Script", Text=v and "Auto Haki aktif." or "Auto Haki dimatikan.", Duration=2 })
    end,
    "AutoHaki"
})

SettingsTab:AddToggle({
    "Auto Attack (klik otomatis saat farm)",
    true,
    function(v)
        Settings.AutoClick = v
        Notify({ Title="Xtray Script", Text=v and "Auto Attack aktif." or "Auto Attack dimatikan.", Duration=2 })
    end,
    "AutoAttack"
})

SettingsTab:AddSection("Jarak Farm")

SettingsTab:AddSlider({
    "Farm Distance",
    5,
    20,
    1,
    9,
    function(v)
        Settings.FarmDistance = v
        Settings.FarmCFrame   = CFrame_new(0, v, 0) * CFrame_Ang(math.rad(-90), 0, 0)
    end,
    "FarmDistance"
})

SettingsTab:AddSection("No Stun")

SettingsTab:AddToggle({
    "No Stun",
    false,
    function(v)
        if v then
            local function hookStun(char)
                if not char then return end
                local stun = char:FindFirstChild("Stun")
                if stun then
                    if Connections.NoStun then Connections.NoStun:Disconnect() end
                    Connections.NoStun = stun:GetPropertyChangedSignal("Value"):Connect(function()
                        if _env.NoStun then stun.Value = 0 end
                    end)
                end
            end
            _env.NoStun = true
            hookStun(GetCharacter())
            if Connections.NoStunAdded then Connections.NoStunAdded:Disconnect() end
            Connections.NoStunAdded = Player.CharacterAdded:Connect(hookStun)
        else
            _env.NoStun = false
            if Connections.NoStun then Connections.NoStun:Disconnect(); Connections.NoStun = nil end
            if Connections.NoStunAdded then Connections.NoStunAdded:Disconnect(); Connections.NoStunAdded = nil end
        end
        Notify({ Title="Xtray Script", Text=v and "No Stun aktif." or "No Stun dimatikan.", Duration=2 })
    end,
    "NoStun"
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
    "FullBright"
})

VisualTab:AddSection("Movement")

VisualTab:AddToggle({
    "Speed Hack",
    false,
    function(v) Movement:Toggle(v) end,
    "SpeedHack"
})

VisualTab:AddSlider({
    "Walk Speed", 16, 500, 1, 58,
    function(v) Movement:SetSpeed(v) end,
    "WalkSpeed"
})

VisualTab:AddSlider({
    "Jump Power", 50, 500, 1, 150,
    function(v) Movement:SetJump(v) end,
    "JumpPower"
})

VisualTab:AddToggle({
    "Infinite Jump",
    false,
    function(v)
        if v then
            Connections.InfJump = UserInputService.JumpRequest:Connect(function()
                local hum = GetHumanoid()
                if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
            end)
        else
            if Connections.InfJump then Connections.InfJump:Disconnect(); Connections.InfJump = nil end
        end
    end,
    "InfJump"
})

VisualTab:AddSection("ESP Musuh")

VisualTab:AddToggle({
    "Enable ESP",
    false,
    function(v) ToggleESP(v) end,
    "ESPEnabled"
})

-- ============================================================
-- TAB: TELEPORT
-- ============================================================

local TeleportTab = Window:MakeTab({ "Teleport", "rbxassetid://10709791437" })

TeleportTab:AddSection("Teleport ke Quest")

TeleportTab:AddButton({
    "TP ke NPC Quest Terbaik",
    function()
        local q = GetCurrentQuest()
        if q then
            GoTo(q.QuestPos)
            Notify({ Title="Xtray Script", Text="TP ke "..q.NpcName, Duration=3 })
        else
            Notify({ Title="Xtray Script", Text="Tidak ada quest tersedia.", Duration=3 })
        end
    end
})

TeleportTab:AddButton({
    "TP ke Area Musuh Quest",
    function()
        local q = GetCurrentQuest()
        if q then
            GoTo(q.EnemyPos)
            Notify({ Title="Xtray Script", Text="TP ke area "..q.Enemy, Duration=3 })
        else
            Notify({ Title="Xtray Script", Text="Tidak ada quest tersedia.", Duration=3 })
        end
    end
})

TeleportTab:AddSection("Area Meme Sea")

local Areas = {
    { "Spawn Island",     CFrame_new(  0,  5,   0) },
    { "Doge Village",     CFrame_new(150,  5, 200) },
    { "Cheems Castle",    CFrame_new(-300, 5, 500) },
    { "Meme Dungeon",     CFrame_new( 500, 5,-200) },
    { "Ohio Island",      CFrame_new( 800, 5, 100) },
    { "Nugget Kingdom",   CFrame_new(-600, 5, -50) },
    { "Baller Colosseum", CFrame_new(1200, 5, 300) },
}

for _, area in ipairs(Areas) do
    TeleportTab:AddButton({
        area[1],
        function()
            GoTo(area[2])
            Notify({ Title="Xtray Script", Text="TP ke "..area[1], Duration=2 })
        end
    })
end

-- ============================================================
-- TAB: MISC
-- ============================================================

local MiscTab = Window:MakeTab({ "Misc", "rbxassetid://10709752996" })

MiscTab:AddSection("Anti AFK")

MiscTab:AddToggle({
    "Anti AFK",
    false,
    function(v)
        if v then
            Connections.AntiAFK = RunService.Heartbeat:Connect(function()
                if not _env.AntiAFK then return end
                if tick() % 60 < 0.05 then
                    pcall(function()
                        VIM:SendKeyEvent(true,  Enum.KeyCode.W, false, game)
                        VIM:SendKeyEvent(false, Enum.KeyCode.W, false, game)
                    end)
                end
            end)
            _env.AntiAFK = true
            Notify({ Title="Xtray Script", Text="Anti AFK aktif.", Duration=3 })
        else
            _env.AntiAFK = false
            if Connections.AntiAFK then Connections.AntiAFK:Disconnect(); Connections.AntiAFK = nil end
        end
    end,
    "AntiAFK"
})

MiscTab:AddSection("Auto Respawn")

MiscTab:AddToggle({
    "Auto Respawn",
    false,
    function(v)
        if v then
            Connections.AutoRespawn = RunService.Heartbeat:Connect(function()
                if not _env.AutoRespawn then return end
                local hum = GetHumanoid()
                if hum and hum.Health <= 0 then
                    task.wait(1)
                    pcall(function() Player:LoadCharacter() end)
                end
            end)
            _env.AutoRespawn = true
        else
            _env.AutoRespawn = false
            if Connections.AutoRespawn then Connections.AutoRespawn:Disconnect(); Connections.AutoRespawn = nil end
        end
    end,
    "AutoRespawn"
})

MiscTab:AddSection("Info")

MiscTab:AddButton({
    "Info Karakter",
    function()
        local hum   = GetHumanoid()
        local hp    = hum and math.floor(hum.Health)    or 0
        local maxHp = hum and math.floor(hum.MaxHealth) or 0
        local pts   = PlayerData:FindFirstChild("SkillPoint")
        Notify({
            Title    = "Xtray Script",
            Text     = ("Level: %d/%d | HP: %d/%d | Skill Points: %d"):format(
                GetPlayerLevel(), MSetting.Setting.MaxLevel, hp, maxHp,
                pts and pts.Value or 0
            ),
            Duration = 6
        })
    end
})

MiscTab:AddButton({
    "Jumlah Musuh di Sekitar (500m)",
    function()
        local root  = GetRootPart()
        local count = 0
        for _, enemy in ipairs(Monsters:GetChildren()) do
            local pp  = enemy.PrimaryPart or enemy:FindFirstChildOfClass("BasePart")
            local hum = enemy:FindFirstChildOfClass("Humanoid")
            if pp and hum and hum.Health > 0 and root then
                if (pp.Position - root.Position).Magnitude <= 500 then
                    count = count + 1
                end
            end
        end
        Notify({ Title="Xtray Script", Text=("Musuh aktif dalam 500m: %d"):format(count), Duration=4 })
    end
})

-- ============================================================
-- NOTIFIKASI SELESAI LOAD
-- ============================================================

Notify({
    Title    = "Xtray Script",
    Text     = ("Meme Sea v2 dimuat! Level: %d/%d"):format(GetPlayerLevel(), MSetting.Setting.MaxLevel),
    Duration = 5
})
