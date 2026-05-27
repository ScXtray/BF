-- ============================================================
--   XTRAY SCRIPT - Blox Fruits
--   github.com/ScXtray/BF
-- ============================================================

local fetcher, Settings = ...

Settings = type(Settings) == "table" and Settings or {}

-- ============================================================
-- LOAD LIBRARY & MODULES
-- ============================================================

local Library    = fetcher.load("{Repository}Library/main.luau")()

local function safeLoad(url, ...)
    local args = {...}
    local ok, result = pcall(function()
        return fetcher.load(url)(table.unpack(args))
    end)
    if ok and result ~= nil then return result end
    return {}
end

local Movement    = safeLoad("{Repository}Utils/Module/Movement.luau")
local FullBright  = safeLoad("{Repository}Utils/Module/FullBright.luau")
local AntiReset   = safeLoad("{Repository}Utils/Module/AntiReset.luau")
local ESP         = safeLoad("{Repository}Utils/Module/BloxFruitsESP.luau")
local FastAttack  = safeLoad("{Repository}Utils/Module/FastAttack.luau")
local TweenModule = safeLoad("https://raw.githubusercontent.com/newredzv3/Scripts/refs/heads/main/Utils/Module/Tween-Module.luau")

-- Pastikan semua modul punya fungsi fallback jika gagal load
if not Movement.Toggle    then Movement    = { Toggle = function() end, SetSpeed = function() end, SetJump = function() end } end
if not FullBright.Toggle  then FullBright  = { Toggle = function() end } end
if not AntiReset.SetEnabled then AntiReset = { SetEnabled = function() end } end
if not ESP.Toggle         then ESP         = { Toggle = function() end, Start = function() end } end
if not FastAttack.Toggle  then FastAttack  = { Toggle = function() end, SetRange = function() end, SetAttackMobs = function() end, SetAttackPlayers = function() end } end
-- Fallback TweenModule: gunakan teleport instan jika modul gagal load
if not TweenModule.Teleport then
    TweenModule = {
        _active = false,
        Teleport = function(self, cf)
            local root = GetRootPart()
            if root then root.CFrame = cf end
            return true
        end,
        Stop        = function(self) self._active = false end,
        SetSpeed    = function(self, s) end,
        IsTweening  = function(self) return false end,
    }
end

-- ============================================================
-- NOTIFIKASI HELPER (Library tidak punya Notify)
-- ============================================================

local function Notify(cfg)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title    = tostring(cfg.Title    or "Xtray Script"),
            Text     = tostring(cfg.Text     or cfg.Content or ""),
            Duration = tonumber(cfg.Duration or cfg.Time    or 4),
        })
    end)
end

-- ============================================================
-- SERVICES
-- ============================================================

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService  = game:GetService("UserInputService")
local Lighting          = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local Enemies     = workspace:WaitForChild("Enemies", 10)

local Remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
local CommF   = Remotes and Remotes:FindFirstChild("CommF_")

-- ============================================================
-- STATE
-- ============================================================

local State = {
    AutoFarm          = false,
    AutoCollect       = false,
    AntiKnockback     = false,
    InfJump           = false,
    AutoQuest         = false,
    FarmRange         = 150,
    FastAttack        = false,
    FastAttackRange   = 40,
    AntiAFK           = false,
    AutoStats         = false,
    AutoStatType      = "Melee",
    FruitNotif        = false,
    FruitSniper       = false,
    -- Kelompok A: Farm upgrades
    WeaponType        = "Blox Fruit",
    FarmMethod        = "Kill Mobs",
    TweeningSpeed     = 300,
    BringRadius       = 200,
    StartBring        = false,
    FreezeBring       = false,
    AttackMobs        = true,
    AttackPlayers     = false,
    WalkInWater       = false,
    DisableDmgCounter = false,
    -- Auto Farm Level
    AutoFarmLevel     = false,
    FarmLevelRange    = 300,
    -- Kill Aura
    KillAura          = false,
    KillAuraRange     = 60,
    -- Auto Boss
    AutoBoss          = false,
    AutoBossName      = "Gorilla King",
    -- Auto Buso
    AutoBuso          = false,
    -- Super Clique
    SuperClique       = false,
    SuperCliqueRange  = 60,
    -- Auto Fishing
    AutoFishing       = false,
    AutoFishingQuest  = false,
    AutoSellFish      = false,
    SelectedRod       = "Basic Rod",
    -- Mastery Farm
    MasteryFarm       = false,
    MasteryMethod     = "Blox Fruit",
    -- Auto Chest
    AutoChest         = false,
    AutoChestHop      = false,
    -- Sea Event
    SeaEventFarm      = false,
    SelectedSeaEvent  = "Shark",
    -- Extras
    AutoSkillZ        = false,
    AutoLogia         = false,
    AutoFireFlowers   = false,
    AutoHopLegSword   = false,
    AutoHopHakiColor  = false,
}

local Connections = {}

-- ============================================================
-- QUEST DATABASE
-- Level = level minimum karakter
-- NpcPos = posisi NPC untuk accept & complete quest
-- NpcName = nama NPC (untuk CommF_)
-- Enemies = nama musuh yang harus dibunuh
-- Kill = jumlah kill yang dibutuhkan
-- ============================================================

local QuestData = {
    -- ── Sea 1 ─────────────────────────────────────────────
    {
        Level   = 10,  Name = "Monkeys",
        NpcPos  = Vector3.new(-1598, 37, 153),
        NpcName = "Jungle Quest Giver",
        Enemies = { "Monkey" }, Kill = 6
    },
    {
        Level   = 15,  Name = "Gorillas",
        NpcPos  = Vector3.new(-1598, 37, 153),
        NpcName = "Jungle Quest Giver",
        Enemies = { "Gorilla" }, Kill = 8
    },
    {
        Level   = 30,  Name = "Pirates",
        NpcPos  = Vector3.new(-1140, 4, 3829),
        NpcName = "Buggy Quest Giver",
        Enemies = { "Pirate" }, Kill = 8
    },
    {
        Level   = 40,  Name = "Brutes",
        NpcPos  = Vector3.new(-1140, 4, 3829),
        NpcName = "Buggy Quest Giver",
        Enemies = { "Brute" }, Kill = 8
    },
    {
        Level   = 60,  Name = "Desert Bandits",
        NpcPos  = Vector3.new(875, 7, -550),
        NpcName = "Desert Quest Giver",
        Enemies = { "Desert Bandit" }, Kill = 8
    },
    {
        Level   = 75,  Name = "Desert Officers",
        NpcPos  = Vector3.new(875, 7, -550),
        NpcName = "Desert Quest Giver",
        Enemies = { "Desert Officer" }, Kill = 6
    },
    {
        Level   = 90,  Name = "Snow Bandits",
        NpcPos  = Vector3.new(1385, 87, -1298),
        NpcName = "Snow Quest Giver",
        Enemies = { "Snow Bandit" }, Kill = 7
    },
    {
        Level   = 100, Name = "Snowmen",
        NpcPos  = Vector3.new(1385, 87, -1298),
        NpcName = "Snow Quest Giver",
        Enemies = { "Snowman" }, Kill = 8
    },
    {
        Level   = 150, Name = "Sky Bandits",
        NpcPos  = Vector3.new(-5145, 449, -1176),
        NpcName = "Sky Quest Giver",
        Enemies = { "Sky Bandit" }, Kill = 7
    },
    {
        Level   = 175, Name = "Dark Masters",
        NpcPos  = Vector3.new(-5145, 449, -1176),
        NpcName = "Sky Quest Giver",
        Enemies = { "Dark Master" }, Kill = 8
    },
    {
        Level   = 220, Name = "Wardens",
        NpcPos  = Vector3.new(5191, 4, 692),
        NpcName = "Prison Quest Giver",
        Enemies = { "Warden" }, Kill = 8
    },
    {
        Level   = 230, Name = "Chief Wardens",
        NpcPos  = Vector3.new(5191, 4, 692),
        NpcName = "Prison Quest Giver",
        Enemies = { "Chief Warden" }, Kill = 8
    },
    {
        Level   = 300, Name = "Magma Ninjas",
        NpcPos  = Vector3.new(-5319, 12, 8515),
        NpcName = "Magma Quest Giver",
        Enemies = { "Magma Ninja" }, Kill = 8
    },
    {
        Level   = 450, Name = "God's Guard",
        NpcPos  = Vector3.new(-7861, 5545, -381),
        NpcName = "Sky Exp Quest Giver",
        Enemies = { "God's Guard" }, Kill = 7
    },
    {
        Level   = 475, Name = "Shanda",
        NpcPos  = Vector3.new(-7861, 5545, -381),
        NpcName = "Sky Exp Quest Giver",
        Enemies = { "Shanda" }, Kill = 9
    },
    {
        Level   = 575, Name = "Thunder God",
        NpcPos  = Vector3.new(-7903, 5636, -1412),
        NpcName = "Upper Sky Quest Giver",
        Enemies = { "Thunder God" }, Kill = 1
    },
    {
        Level   = 625, Name = "Galley Pirates",
        NpcPos  = Vector3.new(5258, 39, 4052),
        NpcName = "Fountain Quest Giver",
        Enemies = { "Galley Pirate" }, Kill = 8
    },
    {
        Level   = 650, Name = "Galley Captains",
        NpcPos  = Vector3.new(5258, 39, 4052),
        NpcName = "Fountain Quest Giver",
        Enemies = { "Galley Captain" }, Kill = 9
    },
    -- ── Sea 2 ─────────────────────────────────────────────
    {
        Level   = 700, Name = "Raiders",
        NpcPos  = Vector3.new(-427, 73, 1835),
        NpcName = "Area 1 Quest Giver",
        Enemies = { "Raider" }, Kill = 8
    },
    {
        Level   = 725, Name = "Mercenaries",
        NpcPos  = Vector3.new(-427, 73, 1835),
        NpcName = "Area 1 Quest Giver",
        Enemies = { "Mercenary" }, Kill = 8
    },
    {
        Level   = 775, Name = "Swan Pirates",
        NpcPos  = Vector3.new(635, 73, 919),
        NpcName = "Area 2 Quest Giver",
        Enemies = { "Swan Pirate" }, Kill = 8
    },
    {
        Level   = 800, Name = "Factory Staff",
        NpcPos  = Vector3.new(635, 73, 919),
        NpcName = "Area 2 Quest Giver",
        Enemies = { "Factory Staff" }, Kill = 8
    },
    {
        Level   = 950, Name = "Zombies",
        NpcPos  = Vector3.new(2680, 93, -1165),
        NpcName = "Zombie Quest Giver",
        Enemies = { "Zombie" }, Kill = 8
    },
    {
        Level   = 975, Name = "Vampires",
        NpcPos  = Vector3.new(2680, 93, -1165),
        NpcName = "Zombie Quest Giver",
        Enemies = { "Vampire" }, Kill = 8
    },
    {
        Level   = 1000, Name = "Snow Troopers",
        NpcPos  = Vector3.new(-3061, 315, -9542),
        NpcName = "Snow Mountain Quest Giver",
        Enemies = { "Snow Trooper" }, Kill = 8
    },
    {
        Level   = 1050, Name = "Winter Warriors",
        NpcPos  = Vector3.new(-3061, 315, -9542),
        NpcName = "Snow Mountain Quest Giver",
        Enemies = { "Winter Warrior" }, Kill = 9
    },
    {
        Level   = 1150, Name = "Magma Ninjas (S2)",
        NpcPos  = Vector3.new(-6229, 82, -4853),
        NpcName = "Ice Side Quest Giver",
        Enemies = { "Magma Ninja" }, Kill = 8
    },
    {
        Level   = 1250, Name = "Ship Deckhands",
        NpcPos  = Vector3.new(-7250, 9, -5773),
        NpcName = "Ship Quest Giver",
        Enemies = { "Ship Deckhand" }, Kill = 8
    },
    {
        Level   = 1275, Name = "Ship Engineers",
        NpcPos  = Vector3.new(-7250, 9, -5773),
        NpcName = "Ship Quest Giver",
        Enemies = { "Ship Engineer" }, Kill = 8
    },
    {
        Level   = 1350, Name = "Arctic Warriors",
        NpcPos  = Vector3.new(5668, 28, -6484),
        NpcName = "Frost Quest Giver",
        Enemies = { "Arctic Warrior" }, Kill = 8
    },
    {
        Level   = 1375, Name = "Snow Lurkers",
        NpcPos  = Vector3.new(5668, 28, -6484),
        NpcName = "Frost Quest Giver",
        Enemies = { "Snow Lurker" }, Kill = 8
    },
    {
        Level   = 1425, Name = "Sea Soldiers",
        NpcPos  = Vector3.new(-3056, 240, -10145),
        NpcName = "Forgotten Quest Giver",
        Enemies = { "Sea Soldier" }, Kill = 8
    },
    {
        Level   = 1450, Name = "Water Fighters",
        NpcPos  = Vector3.new(-3056, 240, -10145),
        NpcName = "Forgotten Quest Giver",
        Enemies = { "Water Fighter" }, Kill = 8
    },
    -- ── Sea 3 ─────────────────────────────────────────────
    {
        Level   = 1500, Name = "Pirate Millionaires",
        NpcPos  = Vector3.new(-449, 109, 5950),
        NpcName = "Pirate Port Quest Giver",
        Enemies = { "Pirate Millionaire" }, Kill = 8
    },
    {
        Level   = 1700, Name = "Marine Commodores",
        NpcPos  = Vector3.new(2485, 74, -6788),
        NpcName = "Marine Tree Quest Giver",
        Enemies = { "Marine Commodore" }, Kill = 8
    },
    {
        Level   = 1725, Name = "Marine Rear Admirals",
        NpcPos  = Vector3.new(2485, 74, -6788),
        NpcName = "Marine Tree Quest Giver",
        Enemies = { "Marine Rear Admiral" }, Kill = 8
    },
    {
        Level   = 1775, Name = "Fishman Raiders",
        NpcPos  = Vector3.new(-13233, 332, -7626),
        NpcName = "Deep Forest Quest Giver",
        Enemies = { "Fishman Raider" }, Kill = 8
    },
    {
        Level   = 1800, Name = "Fishman Captains",
        NpcPos  = Vector3.new(-13233, 332, -7626),
        NpcName = "Deep Forest Quest Giver",
        Enemies = { "Fishman Captain" }, Kill = 8
    },
    {
        Level   = 1900, Name = "Jungle Pirates",
        NpcPos  = Vector3.new(-12682, 391, -9901),
        NpcName = "Deep Forest 2 Quest Giver",
        Enemies = { "Jungle Pirate" }, Kill = 8
    },
    {
        Level   = 1925, Name = "Musketeer Pirates",
        NpcPos  = Vector3.new(-12682, 391, -9901),
        NpcName = "Deep Forest 2 Quest Giver",
        Enemies = { "Musketeer Pirate" }, Kill = 8
    },
    {
        Level   = 1975, Name = "Reborn Skeletons",
        NpcPos  = Vector3.new(-1680, 121, -11610),
        NpcName = "Haunted Quest Giver",
        Enemies = { "Reborn Skeleton" }, Kill = 8
    },
    {
        Level   = 2000, Name = "Living Zombies",
        NpcPos  = Vector3.new(-1680, 121, -11610),
        NpcName = "Haunted Quest Giver",
        Enemies = { "Living Zombie" }, Kill = 8
    },
    {
        Level   = 2400, Name = "Candy Pirates",
        NpcPos  = Vector3.new(-13665, 199, -11000),
        NpcName = "Candy Quest Giver",
        Enemies = { "Candy Pirate" }, Kill = 8
    },
}

-- ============================================================
-- HELPER FUNCTIONS
-- ============================================================

local function GetCharacter()
    return LocalPlayer.Character
end

local function GetRootPart()
    local char = GetCharacter()
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function GetHumanoid()
    local char = GetCharacter()
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function GetLevel()
    local Data = LocalPlayer:FindFirstChild("Data")
    local lvObj = Data and Data:FindFirstChild("Level")
    return lvObj and lvObj.Value or 1
end

local function TeleportTo(position)
    local root = GetRootPart()
    if root then
        root.CFrame = CFrame.new(position + Vector3.new(0, 3, 0))
    end
end

-- Terbang smooth ke target menggunakan TweenModule
-- (NoClip + BodyVelocity otomatis, lebih stabil dari tween manual)
local function TweenFlyTo(targetPos, speed)
    if not targetPos then return end

    -- Sync speed jika diberikan secara eksplisit
    if speed then
        TweenModule:SetSpeed(speed)
    else
        TweenModule:SetSpeed(State.TweeningSpeed or 300)
    end

    -- Mulai tween fly (non-blocking internal, kita poll sampai selesai)
    TweenModule:Teleport(CFrame.new(targetPos))

    -- Tunggu sampai tween selesai atau timeout 30 detik
    local timeout = tick() + 30
    repeat
        task.wait(0.05)
    until not TweenModule:IsTweening() or tick() > timeout
end

local function GetNearestEnemy(range, nameFilter)
    local root = GetRootPart()
    if not root or not Enemies then return nil end

    local nearest, nearestDist = nil, range or math.huge

    for _, enemy in ipairs(Enemies:GetChildren()) do
        local hrp = enemy:FindFirstChild("HumanoidRootPart")
        local hum = enemy:FindFirstChildOfClass("Humanoid")
        if hrp and hum and hum.Health > 0 then
            -- filter nama musuh jika diperlukan
            local passFilter = true
            if nameFilter then
                local found = false
                for _, n in ipairs(nameFilter) do
                    if enemy.Name:lower():find(n:lower()) then
                        found = true; break
                    end
                end
                if not found then passFilter = false end
            end
            if passFilter then
                local dist = (hrp.Position - root.Position).Magnitude
                if dist < nearestDist then
                    nearest     = enemy
                    nearestDist = dist
                end
            end
        end
    end

    return nearest
end

local function AttackWithTool()
    local char = GetCharacter()
    if not char then return end
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then return end
    pcall(function() tool:Activate() end)
end

-- Serang dengan senjata sesuai WeaponType yang dipilih
local function AttackWithWeapon()
    local char = GetCharacter()
    if not char then return end
    -- Cari tool sesuai tipe
    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") then
            local wt = State.WeaponType
            local tn = tool.Name:lower()
            local match = (wt == "Blox Fruit" and (tn:find("fruit") or tn:find("devil") or tn:find("blox")))
                or (wt == "Sword"      and (tn:find("sword") or tn:find("katana") or tn:find("blade") or tn:find("saber")))
                or (wt == "Gun"        and (tn:find("gun") or tn:find("pistol") or tn:find("rifle") or tn:find("musket")))
            if match or wt == "Semua" then
                pcall(function() tool:Activate() end)
                return
            end
        end
    end
    -- Fallback: aktifkan tool apapun yang ada
    local tool = char:FindFirstChildOfClass("Tool")
    if tool then pcall(function() tool:Activate() end) end
end

-- Tarik semua musuh dalam radius ke posisi player
-- (teknik dari Panda-Hub: size 60 + PlatformStand + Sit + CanCollide false + SimulationRadius)
local FreezeBringConns = {}
local function BringEnemiesToPlayer()
    local root = GetRootPart()
    if not root then return end
    local EFolder = workspace:FindFirstChild("Enemies")
    if not EFolder then return end

    -- Perluas SimulationRadius agar kita punya network ownership musuh
    pcall(sethiddenproperty, LocalPlayer, "SimulationRadius", math.huge)

    local targetCF = root.CFrame
    for _, enemy in ipairs(EFolder:GetChildren()) do
        local hrp = enemy:FindFirstChild("HumanoidRootPart")
        local hum = enemy:FindFirstChildOfClass("Humanoid")
        if hrp and hum and hum.Health > 0 then
            local dist = (hrp.Position - root.Position).Magnitude
            if dist <= State.BringRadius then
                pcall(function()
                    -- Perbesar hitbox agar mudah kena serangan
                    hrp.Size        = Vector3.new(60, 60, 60)
                    hrp.CFrame      = targetCF * CFrame.new(
                        math.random(-3, 3), 0, math.random(-3, 3)
                    )
                    hrp.CanCollide  = false
                    -- Paksa musuh tidak bergerak/menolak
                    hum.PlatformStand = true
                    hum.Sit           = true
                end)
            end
        end
    end
end

local function SetFreezeBring(enabled)
    for _, c in pairs(FreezeBringConns) do pcall(function() c:Disconnect() end) end
    FreezeBringConns = {}
    if not enabled then return end
    local root = GetRootPart()
    if not root then return end
    local EFolder = workspace:FindFirstChild("Enemies")
    if not EFolder then return end
    for _, enemy in ipairs(EFolder:GetChildren()) do
        local hrp = enemy:FindFirstChild("HumanoidRootPart")
        if hrp then
            local frozen = hrp.CFrame
            local c = RunService.Heartbeat:Connect(function()
                if not State.FreezeBring then return end
                pcall(function() hrp.CFrame = frozen end)
            end)
            table.insert(FreezeBringConns, c)
        end
    end
end

-- Aktifkan/nonaktifkan Walk in Water (disable swim state)
local function ApplyWalkInWater(char)
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        pcall(function()
            hum:SetStateEnabled(Enum.HumanoidStateType.Swimming, false)
            hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
        end)
    end
end

local function SetWalkInWater(enabled)
    local char = GetCharacter()
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            pcall(function()
                hum:SetStateEnabled(Enum.HumanoidStateType.Swimming, not enabled)
                hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, not enabled)
            end)
        end
    end
    if Connections.WalkInWater then
        Connections.WalkInWater:Disconnect()
        Connections.WalkInWater = nil
    end
    if enabled then
        Connections.WalkInWater = LocalPlayer.CharacterAdded:Connect(function(newChar)
            task.wait(1)
            ApplyWalkInWater(newChar)
        end)
    end
end

-- Hapus semua efek visual (partikel, api, asap) di workspace
local function RemoveEffects()
    pcall(function()
        for _, v in ipairs(workspace:GetDescendants()) do
            if v:IsA("ParticleEmitter") or v:IsA("Smoke")
            or v:IsA("Fire") or v:IsA("Sparkles") then
                v.Enabled = false
                pcall(function() v:Destroy() end)
            end
        end
    end)
    pcall(function()
        local char = GetCharacter()
        if char then
            for _, v in ipairs(char:GetDescendants()) do
                if v:IsA("ParticleEmitter") or v:IsA("Smoke")
                or v:IsA("Fire") or v:IsA("Sparkles") then
                    v.Enabled = false
                end
            end
        end
    end)
end

-- Sembunyikan/tampilkan Damage Counter di GUI
local function SetDamageCounter(disabled)
    pcall(function()
        local gui = LocalPlayer.PlayerGui
        for _, screen in ipairs(gui:GetChildren()) do
            local n = screen.Name:lower()
            if n:find("damage") or n:find("dmg") or n:find("combat") then
                screen.Enabled = not disabled
            end
        end
    end)
end

local function GetBestQuest()
    local lv = GetLevel()
    local best = nil
    for _, q in ipairs(QuestData) do
        if lv >= q.Level then
            if not best or q.Level > best.Level then
                best = q
            end
        end
    end
    return best
end

-- ============================================================
-- BOSS DATABASE (dari newredzv3/Scripts)
-- ============================================================

local BossData = {
    -- Sea 1
    { Name = "Gorilla King",    Sea = 1, Level = 20,   Position = Vector3.new(-1128, 6,   -451) },
    { Name = "Bobby",           Sea = 1, Level = 55,   Position = Vector3.new(-1131, 14,  4080) },
    { Name = "Yeti",            Sea = 1, Level = 105,  Position = Vector3.new(1185,  106, -1518) },
    { Name = "Vice Admiral",    Sea = 1, Level = 130,  Position = Vector3.new(-4807, 21,  4360) },
    { Name = "Swan",            Sea = 1, Level = 240,  Position = Vector3.new(5230,  4,   749) },
    { Name = "Magma Admiral",   Sea = 1, Level = 350,  Position = Vector3.new(-5694, 18,  8735) },
    { Name = "Fishman Lord",    Sea = 1, Level = 425,  Position = Vector3.new(61350, 31,  1095) },
    { Name = "Wysper",          Sea = 1, Level = 500,  Position = Vector3.new(-7927, 5551,-637) },
    { Name = "Thunder God",     Sea = 1, Level = 575,  Position = Vector3.new(-7751, 5607,-2315) },
    { Name = "Cyborg",          Sea = 1, Level = 675,  Position = Vector3.new(6138,  10,  3939) },
    -- Sea 2
    { Name = "Diamond",         Sea = 2, Level = 750,  Position = Vector3.new(-1569, 199, -31) },
    { Name = "Jeremy",          Sea = 2, Level = 850,  Position = Vector3.new(2316,  449, 787) },
    { Name = "Orbitus",         Sea = 2, Level = 925,  Position = Vector3.new(-2086, 73,  -4208) },
    { Name = "Smoke Admiral",   Sea = 2, Level = 1150, Position = Vector3.new(-5078, 24,  -5352) },
    { Name = "Awakened Ice Admiral", Sea = 2, Level = 1400, Position = Vector3.new(6473, 297, -6944) },
    { Name = "Tide Keeper",     Sea = 2, Level = 1475, Position = Vector3.new(-3711, 77,  -11469) },
    -- Sea 3
    { Name = "Stone",           Sea = 3, Level = 1550, Position = Vector3.new(-1049, 40,  6791) },
    { Name = "Hydra Leader",    Sea = 3, Level = 1675, Position = Vector3.new(5836,  1019,-83) },
    { Name = "Kilo Admiral",    Sea = 3, Level = 1750, Position = Vector3.new(2904,  509, -7349) },
    { Name = "Captain Elephant",Sea = 3, Level = 1875, Position = Vector3.new(-13393,319, -8423) },
    { Name = "Beautiful Pirate",Sea = 3, Level = 1950, Position = Vector3.new(5370,  22,  -89) },
    { Name = "Cake Queen",      Sea = 3, Level = 2175, Position = Vector3.new(-710,  382, -11150) },
}

-- Deteksi sea player saat ini
local function DetectSea()
    local sea1 = {2753915549, 85211729168715}
    local sea2 = {4442272183, 79091703265657}
    local sea3 = {7449423635, 100117331123089}
    if table.find(sea1, game.PlaceId) then return 1
    elseif table.find(sea2, game.PlaceId) then return 2
    elseif table.find(sea3, game.PlaceId) then return 3
    end
    return 0
end

local CurrentSea = DetectSea()

-- Dapatkan boss berdasarkan nama
local function GetBossByName(name)
    for _, b in ipairs(BossData) do
        if b.Name == name then return b end
    end
    return nil
end

-- ============================================================
-- HELPER: KILL AURA (dari newredzv3)
-- ============================================================

local sethiddenproperty = sethiddenproperty or (function() end)

local function KillAuraOnce(range)
    local root = GetRootPart()
    if not root then return end
    local EFolder = workspace:FindFirstChild("Enemies")
    if not EFolder then return end

    -- Perluas SimulationRadius agar server menerima damage
    pcall(sethiddenproperty, LocalPlayer, "SimulationRadius", math.huge)

    for _, enemy in ipairs(EFolder:GetChildren()) do
        local hrp = enemy:FindFirstChild("HumanoidRootPart")
        local hum = enemy:FindFirstChildOfClass("Humanoid")
        if hrp and hum and hum.Health > 0 then
            local dist = (hrp.Position - root.Position).Magnitude
            if dist <= (range or 60) then
                pcall(function()
                    hrp.Size          = Vector3.new(60, 60, 60)
                    hrp.CFrame        = root.CFrame
                    hrp.CanCollide    = false
                    hum.PlatformStand = true
                    hum.Sit           = true
                    hum:ChangeState(15)
                    hum.Health        = 0
                end)
            end
        end
    end
end

-- ============================================================
-- HELPER: AUTO BUSO HAKI (dari newredzv3)
-- ============================================================

local function TryEnableBuso()
    local char = GetCharacter()
    if not char then return end
    -- Cek apakah sudah punya Buso
    if char:FindFirstChild("HasBuso") then return end
    if CommF then
        pcall(function()
            -- Coba aktifkan dulu
            CommF:InvokeServer("Buso")
        end)
    end
end

local function TryAcceptQuest(quest)
    if not CommF then return end
    pcall(function()
        -- Set spawn point di lokasi NPC sebelum accept (teknik Panda-Hub)
        CommF:InvokeServer("SetSpawnPoint")
        task.wait(0.3)
        -- Coba accept quest dengan nama NPC dan slot (1 atau 2)
        -- StartQuest adalah remote yang benar di BloxFruits
        local slot = quest.QuestSlot or 1
        CommF:InvokeServer("StartQuest", quest.NpcName, slot)
    end)
    task.wait(0.5)
end

local function TryCompleteQuest(quest)
    if not CommF then return end
    pcall(function()
        -- TurnInQuest / EndQuest tergantung versi BF
        CommF:InvokeServer("TurnInQuest", quest.NpcName)
    end)
    task.wait(0.5)
end

local function IsQuestActive()
    -- Cek via PlayerGui.Main.Quest.Visible (cara akurat ala Panda-Hub)
    local ok, result = pcall(function()
        local gui = LocalPlayer:WaitForChild("PlayerGui", 1)
        if not gui then return false end
        local main = gui:FindFirstChild("Main") or gui:FindFirstChild("Main (minimal)")
        if not main then return false end
        local questFrame = main:FindFirstChild("Quest")
        return questFrame and questFrame.Visible
    end)
    if ok and result then return true end

    -- Fallback: cek via Data
    local Data = LocalPlayer:FindFirstChild("Data")
    if Data then
        local Quest = Data:FindFirstChild("Quest")
        if Quest and Quest.Value ~= "" then return true end
        local QuestProgress = Data:FindFirstChild("QuestProgress")
        if QuestProgress then return true end
    end
    return false
end

local function IsQuestComplete()
    -- Quest selesai = frame Quest tidak visible
    local ok, result = pcall(function()
        local gui  = LocalPlayer:FindFirstChild("PlayerGui")
        if not gui then return true end
        local main = gui:FindFirstChild("Main") or gui:FindFirstChild("Main (minimal)")
        if not main then return true end
        local questFrame = main:FindFirstChild("Quest")
        return questFrame and not questFrame.Visible
    end)
    if ok and result then return true end

    -- Fallback via Data
    local Data = LocalPlayer:FindFirstChild("Data")
    if not Data then return false end
    local Quest = Data:FindFirstChild("Quest")
    if Quest and Quest.Value == "" then return true end
    local QP = Data:FindFirstChild("QuestProgress")
    return QP == nil
end

-- ============================================================
-- CREATE WINDOW
-- ============================================================

local Window = Library:MakeWindow({
    Name       = "Xtray Script",
    SubTitle   = "by XtrayScript",
    SaveFolder = "XtrayScript-BF"
})

-- ============================================================
-- TAB: DISCORD
-- ============================================================

local DISCORD_LINK    = "discord.gg/wnfTtA42K"
local DISCORD_SERVER  = "Xtray Script | Community"
local DISCORD_DESC    = "Join server untuk dapat update terbaru, bug report, dan info fitur!"
local DISCORD_MEMBERS = "Server resmi Xtray Script"

local DiscordTab = Window:MakeTab({ "Discord", "rbxassetid://10747384394" })

DiscordTab:AddSection("Official Discord")

DiscordTab:AddParagraph({
    DISCORD_SERVER,
    DISCORD_DESC
})

DiscordTab:AddParagraph({
    "Link Undangan",
    DISCORD_LINK
})

DiscordTab:AddButton({
    "Salin Link Discord",
    function()
        if setclipboard then
            setclipboard(DISCORD_LINK)
            Notify({
                Title    = "Xtray Script",
                Text     = "Link Discord disalin! Buka Discord dan tempel link-nya.",
                Duration = 4
            })
        end
    end
})

DiscordTab:AddSection("Informasi Script")

DiscordTab:AddParagraph({
    "Xtray Script - Blox Fruits",
    "Versi 1.3.1 | Script gratis tanpa key"
})

DiscordTab:AddParagraph({
    "Platform Didukung",
    "Delta | Codex | Arceus X | Fluxus"
})

DiscordTab:AddSection("Credits")

DiscordTab:AddParagraph({
    "Developer",
    "XtrayScript"
})

DiscordTab:AddParagraph({
    "Special Thanks",
    "Semua pengguna yang sudah support Xtray Script!"
})

-- ============================================================
-- TAB: FARM
-- ============================================================

local FarmTab = Window:MakeTab({ "Farm", "rbxassetid://10747384394" })

FarmTab:AddSection("Main Farm")

FarmTab:AddDropdown({
    "Weapon",
    { "Blox Fruit", "Sword", "Gun", "Semua" },
    "Blox Fruit",
    function(v) State.WeaponType = v end,
    "WeaponType"
})

FarmTab:AddDropdown({
    "Farm Method",
    { "Kill Mobs", "Auto Quest" },
    "Kill Mobs",
    function(v) State.FarmMethod = v end,
    "FarmMethod"
})

FarmTab:AddToggle({
    "Attack Mobs",
    true,
    function(v) State.AttackMobs = v end,
    "AttackMobs"
})

FarmTab:AddToggle({
    "Attack Players",
    false,
    function(v) State.AttackPlayers = v end,
    "AttackPlayers"
})

FarmTab:AddSection("Auto Farm")

FarmTab:AddToggle({
    "Auto Farm",
    false,
    function(v)
        State.AutoFarm = v

        if v then
            task.spawn(function()
                while State.AutoFarm do
                    local root = GetRootPart()

                    -- Boost SimulationRadius agar kita punya network ownership
                    pcall(sethiddenproperty, LocalPlayer, "SimulationRadius", math.huge)

                    -- Bring otomatis selalu aktif saat Auto Farm ON
                    BringEnemiesToPlayer()

                    -- Serang musuh (mobs)
                    if State.AttackMobs then
                        local enemy = GetNearestEnemy(State.FarmRange)
                        if enemy and root then
                            local hrp = enemy:FindFirstChild("HumanoidRootPart")
                            local hum = enemy:FindFirstChildOfClass("Humanoid")
                            if hrp and hum and hum.Health > 0 then
                                -- Tween smooth ke musuh (tidak teleport abrupt)
                                local dist = (hrp.Position - root.Position).Magnitude
                                if dist > 8 then
                                    pcall(TweenFlyTo, hrp.Position)
                                    task.wait(0.05)
                                end
                                AttackWithWeapon()
                            end
                        end
                    end

                    -- Serang player terdekat jika AttackPlayers aktif
                    if State.AttackPlayers then
                        local nearest, nearDist = nil, math.huge
                        for _, plr in ipairs(Players:GetPlayers()) do
                            if plr ~= LocalPlayer and plr.Character then
                                local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
                                local myRoot = GetRootPart()
                                if hrp and myRoot then
                                    local d = (hrp.Position - myRoot.Position).Magnitude
                                    if d < nearDist and d < State.FarmRange then
                                        nearest  = plr.Character
                                        nearDist = d
                                    end
                                end
                            end
                        end
                        if nearest and root then
                            local hrp = nearest:FindFirstChild("HumanoidRootPart")
                            if hrp then
                                local dist = (hrp.Position - root.Position).Magnitude
                                if dist > 8 then
                                    pcall(TweenFlyTo, hrp.Position)
                                    task.wait(0.05)
                                end
                                AttackWithWeapon()
                            end
                        end
                    end

                    task.wait(0.07)
                end
            end)
        end
    end,
    "AutoFarm"
})

FarmTab:AddSlider({
    "Farm Range",
    50,
    500,
    1,
    150,
    function(v)
        State.FarmRange = v
    end,
    "FarmRange"
})

FarmTab:AddToggle({
    "Auto Collect (Chest)",
    false,
    function(v)
        State.AutoCollect = v

        if v then
            task.spawn(function()
                while State.AutoCollect do
                    local root = GetRootPart()
                    if root then
                        local ChestModels = workspace:FindFirstChild("ChestModels")
                        if ChestModels then
                            for _, chest in ipairs(ChestModels:GetChildren()) do
                                if not State.AutoCollect then break end
                                local part = chest.PrimaryPart
                                    or chest:FindFirstChildWhichIsA("BasePart")
                                if part then
                                    local dist = (part.Position - root.Position).Magnitude
                                    if dist < 200 then
                                        root.CFrame = CFrame.new(part.Position)
                                        task.wait(0.4)
                                    end
                                end
                            end
                        end
                    end
                    task.wait(1)
                end
            end)
        end
    end,
    "AutoCollect"
})

FarmTab:AddToggle({
    "Anti Knockback",
    false,
    function(v)
        State.AntiKnockback = v

        if v then
            Connections.AntiKB = RunService.Heartbeat:Connect(function()
                if not State.AntiKnockback then return end
                local hrp = GetRootPart()
                if hrp then
                    local vel = hrp.AssemblyLinearVelocity
                    -- Threshold 30 agar lebih efektif menahan knockback ringan sekalipun
                    if vel.Magnitude > 30 then
                        hrp.AssemblyLinearVelocity = Vector3.new(0, math.min(vel.Y, 50), 0)
                    end
                end
            end)
        else
            if Connections.AntiKB then
                Connections.AntiKB:Disconnect()
                Connections.AntiKB = nil
            end
        end
    end,
    "AntiKnockback"
})

-- ── Fast Attack ────────────────────────────────────────────
FarmTab:AddSection("Fast Attack")

FarmTab:AddToggle({
    "Fast Attack",
    false,
    function(v)
        State.FastAttack = v

        if v then
            task.spawn(function()
                while State.FastAttack do
                    local char = GetCharacter()
                    local root = GetRootPart()
                    if char and root then
                        -- Expand hitbox sementara agar hit terdaftar
                        local hrp = root
                        local origSize = hrp.Size

                        pcall(function()
                            hrp.Size = Vector3.new(
                                State.FastAttackRange,
                                State.FastAttackRange,
                                State.FastAttackRange
                            )
                        end)

                        -- Aktifkan tool
                        local tool = char:FindFirstChildOfClass("Tool")
                        if tool then
                            pcall(function() tool:Activate() end)
                        end

                        task.wait(0.05)

                        -- Kembalikan ukuran hitbox
                        pcall(function()
                            hrp.Size = origSize
                        end)
                    end
                    task.wait(0.05)
                end
            end)
        end
    end,
    "FastAttack"
})

FarmTab:AddSlider({
    "Fast Attack Range",
    10,
    150,
    1,
    40,
    function(v)
        State.FastAttackRange = v
    end,
    "FastAttackRange"
})

-- ── Kill Aura ──────────────────────────────────────────────
FarmTab:AddSection("Kill Aura")

FarmTab:AddToggle({
    "Kill Aura",
    false,
    function(v)
        State.KillAura = v

        if v then
            task.spawn(function()
                while State.KillAura do
                    pcall(KillAuraOnce, State.KillAuraRange)
                    task.wait(0.1)
                end
            end)
            Notify({
                Title    = "Xtray Script",
                Text     = "Kill Aura aktif — musuh dalam radius akan mati seketika.",
                Duration = 4
            })
        end
    end,
    "KillAura"
})

FarmTab:AddSlider({
    "Kill Aura Range",
    10,
    300,
    1,
    60,
    function(v)
        State.KillAuraRange = v
    end,
    "KillAuraRange"
})

-- ── Super Clique ────────────────────────────────────────────
FarmTab:AddSection("Super Clique")

FarmTab:AddToggle({
    "Super Clique",
    false,
    function(v)
        State.SuperClique = v

        if v then
            task.spawn(function()
                local hitRemote    = workspace:FindFirstChild("Enemies")
                    and game:GetService("ReplicatedStorage"):FindFirstChild("RE")
                    and game:GetService("ReplicatedStorage").RE:FindFirstChild("RegisterHit")
                local attackRemote = game:GetService("ReplicatedStorage"):FindFirstChild("RE")
                    and game:GetService("ReplicatedStorage").RE:FindFirstChild("RegisterAttack")

                while State.SuperClique do
                    local root = GetRootPart()
                    local EFolder = workspace:FindFirstChild("Enemies")

                    if root and EFolder then
                        pcall(sethiddenproperty, LocalPlayer, "SimulationRadius", math.huge)

                        for _, enemy in ipairs(EFolder:GetChildren()) do
                            if not State.SuperClique then break end
                            local hrp = enemy:FindFirstChild("HumanoidRootPart")
                            local hum = enemy:FindFirstChildOfClass("Humanoid")
                            if hrp and hum and hum.Health > 0 then
                                local dist = (hrp.Position - root.Position).Magnitude
                                if dist <= State.SuperCliqueRange then
                                    pcall(function()
                                        local times = (enemy:GetAttribute("IsBoss") and 25)
                                            or (enemy:GetAttribute("RaidBoss") and 40)
                                            or 6
                                        local bladeHits = {{enemy, hrp}, math.random()}
                                        for _ = 1, times do
                                            if attackRemote then
                                                attackRemote:FireServer()
                                            end
                                            if hitRemote then
                                                hitRemote:FireServer(hrp, bladeHits, nil, nil)
                                            end
                                        end
                                    end)
                                end
                            end
                        end
                    end

                    task.wait(0.07)
                end
            end)
            Notify({
                Title    = "Xtray Script",
                Text     = "Super Clique aktif — remote hit langsung dikirim ke server.",
                Duration = 4
            })
        end
    end,
    "SuperClique"
})

FarmTab:AddSlider({
    "Super Clique Range",
    10,
    200,
    1,
    60,
    function(v)
        State.SuperCliqueRange = v
    end,
    "SuperCliqueRange"
})

-- ── Farm Settings ──────────────────────────────────────────
FarmTab:AddSection("Farm Settings")

FarmTab:AddSlider({
    "Nearest Distance",
    50,
    5000,
    1,
    150,
    function(v) State.FarmRange = v end,
    "NearestDistance"
})

FarmTab:AddSlider({
    "Tweening Speed",
    50,
    600,
    1,
    300,
    function(v) State.TweeningSpeed = v; TweenModule:SetSpeed(v) end,
    "TweeningSpeed"
})

FarmTab:AddSlider({
    "Bring Radius",
    50,
    500,
    1,
    200,
    function(v) State.BringRadius = v end,
    "BringRadius"
})

FarmTab:AddToggle({
    "Start Bring",
    false,
    function(v)
        State.StartBring = v
    end,
    "StartBring"
})

FarmTab:AddToggle({
    "Freeze Bring",
    false,
    function(v)
        State.FreezeBring = v
        SetFreezeBring(v)
    end,
    "FreezeBring"
})

-- ── Utilitas Farm ───────────────────────────────────────────
FarmTab:AddSection("Utilitas")

FarmTab:AddToggle({
    "Walk in Water",
    false,
    function(v)
        State.WalkInWater = v
        SetWalkInWater(v)
    end,
    "WalkInWater"
})

FarmTab:AddToggle({
    "Disable Damage Counter",
    false,
    function(v)
        State.DisableDmgCounter = v
        SetDamageCounter(v)
    end,
    "DisableDmgCounter"
})

FarmTab:AddButton({
    "Remove Effects (VFX)",
    function()
        RemoveEffects()
        Notify({
            Title    = "Xtray Script",
            Text     = "Semua efek visual berhasil dihapus!",
            Duration = 3,
        })
    end
})

-- ── Auto Farm Level ─────────────────────────────────────────
FarmTab:AddSection("Auto Farm Level")

local FarmLvParagraph = FarmTab:AddParagraph({
    "Status",
    "Menunggu..."
})

FarmTab:AddSlider({
    "Tween Speed (fly)",
    50,
    800,
    1,
    300,
    function(v) State.TweeningSpeed = v; TweenModule:SetSpeed(v) end,
    "FarmLvTweenSpeed"
})

FarmTab:AddSlider({
    "Search Range Musuh",
    100,
    2000,
    1,
    300,
    function(v) State.FarmLevelRange = v end,
    "FarmLevelRange"
})

FarmTab:AddToggle({
    "Auto Farm Level (Tween Fly)",
    false,
    function(v)
        State.AutoFarmLevel = v

        if not v then
            FarmLvParagraph:Set("Status", "Auto Farm Level dimatikan.")
            return
        end

        task.spawn(function()
            while State.AutoFarmLevel do

                -- ── Ambil quest terbaik sesuai level ──────────────
                local quest = GetBestQuest()

                if not quest then
                    FarmLvParagraph:Set("Status", "Level terlalu rendah / quest tidak tersedia.")
                    task.wait(5)
                else
                    local lv = GetLevel()
                FarmLvParagraph:Set(
                    "Status",
                    ("Lv.%d → Quest: %s"):format(lv, quest.Name)
                )

                -- ── STEP 1: Tween Fly ke NPC, accept quest ────────
                FarmLvParagraph:Set("Status", "Terbang ke NPC: " .. quest.NpcName)
                pcall(TweenFlyTo, quest.NpcPos)
                task.wait(1)
                pcall(TryAcceptQuest, quest)
                task.wait(0.5)

                -- ── STEP 2: Terbang ke musuh & serang ────────────
                local killCount  = 0
                local killTarget = quest.Kill
                local startTime  = tick()

                while State.AutoFarmLevel and killCount < killTarget do
                    -- Timeout 4 menit agar tidak stuck
                    if tick() - startTime > 240 then
                        FarmLvParagraph:Set("Status", "Timeout — skip quest.")
                        break
                    end

                    local enemy = GetNearestEnemy(State.FarmLevelRange, quest.Enemies)
                    local root  = GetRootPart()

                    if enemy and root then
                        local hrp = enemy:FindFirstChild("HumanoidRootPart")
                        local hum = enemy:FindFirstChildOfClass("Humanoid")

                        if hrp and hum and hum.Health > 0 then
                            FarmLvParagraph:Set(
                                "Status",
                                ("Terbang ke %s [%d/%d]"):format(quest.Enemies[1], killCount, killTarget)
                            )

                            -- Terbang smooth ke musuh dengan TweenModule
                            pcall(TweenFlyTo, hrp.Position)
                            task.wait(0.1)

                            -- Pakai event Died agar kill count akurat (tidak race condition)
                            local killed = false
                            local deathConn
                            local ok = pcall(function()
                                deathConn = hum.Died:Connect(function()
                                    killed = true
                                end)
                            end)

                            -- Serang berulang sampai mati atau timeout
                            local attackStart = tick()
                            while State.AutoFarmLevel and hum and hum.Health > 0
                                and not killed and tick() - attackStart < 20 do
                                pcall(AttackWithWeapon)
                                task.wait(0.05)
                            end

                            if deathConn then
                                pcall(function() deathConn:Disconnect() end)
                            end

                            -- Fallback: jika killed false tapi HP = 0, tetap hitung
                            if killed or (hum and hum.Health <= 0) then
                                killCount = killCount + 1
                                FarmLvParagraph:Set(
                                    "Status",
                                    ("Kill %s [%d/%d]"):format(quest.Enemies[1], killCount, killTarget)
                                )
                            end
                        end
                    else
                        -- Tidak ada musuh — terbang ke area spawn musuh
                        FarmLvParagraph:Set("Status", "Cari musuh di area quest...")
                        pcall(TweenFlyTo, quest.NpcPos + Vector3.new(30, 5, 30))
                        task.wait(1)
                    end

                    task.wait(0.05)
                end

                -- ── STEP 3: Terbang ke NPC, selesaikan quest ─────
                -- Hanya kembali ke NPC jika kill target tercapai atau quest selesai
                if State.AutoFarmLevel and killCount >= killTarget then
                    FarmLvParagraph:Set("Status", "Terbang kembali ke NPC...")
                    pcall(TweenFlyTo, quest.NpcPos)
                    task.wait(1)
                    pcall(TryCompleteQuest, quest)

                    local newLv = GetLevel()
                    FarmLvParagraph:Set(
                        "Status",
                        ("Quest selesai! Level: %d → Lanjut..."):format(newLv)
                    )
                    task.wait(0.5)
                end
                end
            end

            FarmLvParagraph:Set("Status", "Auto Farm Level dimatikan.")
        end)
    end,
    "AutoFarmLevel"
})

-- ============================================================
-- TAB: AIMBOT
-- ============================================================

local AimBotModule = nil
do
    local ok, result = pcall(function()
        return fetcher.load("{Repository}Utils/Module/BloxFruitsAimBotModule.luau")(State, Connections)
    end)
    if ok and type(result) == "table" then
        AimBotModule = result
        pcall(function() AimBotModule.Start() end)
    else
        AimBotModule = {
            Start            = function() end,
            Stop             = function() end,
            ToggleGun        = function() end,
            ToggleTap        = function() end,
            ToggleSkills     = function() end,
            ToggleSilentAim  = function() end,
            ToggleNoAimMobs  = function() end,
            ToggleVisibleCheck = function() end,
            ToggleWallCheck  = function() end,
            SetTargetMode    = function() end,
            UpdateConfig     = function() end,
            GetStats         = function() return { TargetsLocked = 0, ShotsFired = 0, ShotsHit = 0 } end,
            ResetStats       = function() end,
        }
    end
end

local AimBotTab = Window:MakeTab({ "AimBot", "rbxassetid://10747384394" })

-- ── Target Lock ─────────────────────────────────────────────
AimBotTab:AddSection("Target Lock")

AimBotTab:AddToggle({
    "Silent Aim (Skill)",
    false,
    function(v)
        AimBotModule.ToggleSkills(v)
    end,
    "SilentAimSkill"
})

AimBotTab:AddToggle({
    "Silent Aim (Gun)",
    false,
    function(v)
        AimBotModule.ToggleGun(v)
    end,
    "SilentAimGun"
})

AimBotTab:AddToggle({
    "Tap Aim",
    false,
    function(v)
        AimBotModule.ToggleTap(v)
    end,
    "TapAim"
})

-- ── Target Settings ──────────────────────────────────────────
AimBotTab:AddSection("Target Settings")

AimBotTab:AddDropdown({
    "Target Mode",
    { "Closest", "LowestHealth", "HighestHealth" },
    "Closest",
    function(v)
        AimBotModule.SetTargetMode(v)
    end,
    "AimTargetMode"
})

AimBotTab:AddToggle({
    "Only Aim Players (No Mobs)",
    false,
    function(v)
        AimBotModule.ToggleNoAimMobs(v)
    end,
    "AimNoMobs"
})

AimBotTab:AddToggle({
    "Visible Check (Line of Sight)",
    false,
    function(v)
        AimBotModule.ToggleVisibleCheck(v)
    end,
    "AimVisibleCheck"
})

AimBotTab:AddToggle({
    "Wall Check",
    false,
    function(v)
        AimBotModule.ToggleWallCheck(v)
    end,
    "AimWallCheck"
})

-- ── AimBot Settings ──────────────────────────────────────────
AimBotTab:AddSection("Settings")

AimBotTab:AddToggle({
    "Silent Aim Hook (Namecall)",
    true,
    function(v)
        AimBotModule.ToggleSilentAim(v)
        AimBotModule.UpdateConfig({ SilentAim = v })
    end,
    "SilentAimHook"
})

AimBotTab:AddSlider({
    "Max Distance",
    50,
    1000,
    10,
    300,
    function(v)
        AimBotModule.UpdateConfig({ MaxDistance = v })
    end,
    "AimMaxDist"
})

AimBotTab:AddSlider({
    "Prediction (ms)",
    0,
    500,
    1,
    165,
    function(v)
        AimBotModule.UpdateConfig({ Prediction = v / 1000 })
    end,
    "AimPrediction"
})

AimBotTab:AddToggle({
    "Auto Prediction (Ping Based)",
    true,
    function(v)
        AimBotModule.UpdateConfig({ AutoPrediction = v })
    end,
    "AutoPrediction"
})

-- ── Visuals ──────────────────────────────────────────────────
AimBotTab:AddSection("Visuals")

AimBotTab:AddToggle({
    "Show FOV Circle",
    false,
    function(v)
        AimBotModule.UpdateConfig({ ShowFOV = v })
    end,
    "ShowFOV"
})

AimBotTab:AddSlider({
    "FOV Size",
    50,
    600,
    10,
    360,
    function(v)
        AimBotModule.UpdateConfig({ FOV = v })
    end,
    "FOVSize"
})

AimBotTab:AddToggle({
    "Draw Target Line",
    false,
    function(v)
        AimBotModule.UpdateConfig({ DrawTarget = v })
    end,
    "DrawTarget"
})

-- ── Stats ────────────────────────────────────────────────────
AimBotTab:AddSection("Stats")

AimBotTab:AddButton({
    "Lihat Statistik AimBot",
    function()
        local s = AimBotModule.GetStats()
        Notify({
            Title    = "AimBot Stats",
            Text     = string.format(
                "Target Terkunci: %d | Shot Terkirim: %d | Shot Kena: %d",
                s.TargetsLocked, s.ShotsFired, s.ShotsHit
            ),
            Duration = 6
        })
    end
})

AimBotTab:AddButton({
    "Reset Statistik",
    function()
        AimBotModule.ResetStats()
        Notify({
            Title    = "AimBot",
            Text     = "Statistik berhasil direset.",
            Duration = 3
        })
    end
})

-- ============================================================
-- TAB: ESP
-- ============================================================

local ESPTab = Window:MakeTab({ "ESP", "rbxassetid://10734943674" })

ESP:Start()

ESPTab:AddSection("ESP Utama")

ESPTab:AddToggle({
    "Enable ESP",
    false,
    function(v)
        ESP:Toggle(v)
    end,
    "ESPEnabled"
})

ESPTab:AddToggle({
    "Show Enemies",
    true,
    function(v)
        ESP.ShowEnemies = v
    end,
    "ESPEnemies"
})

ESPTab:AddToggle({
    "Show Players",
    true,
    function(v)
        ESP.ShowPlayers = v
    end,
    "ESPPlayers"
})

ESPTab:AddToggle({
    "Show Devil Fruits",
    true,
    function(v)
        ESP.ShowFruits = v
    end,
    "ESPFruits"
})

ESPTab:AddSection("Info")

ESPTab:AddToggle({
    "Show Name",
    true,
    function(v)
        ESP.ShowName = v
    end,
    "ESPName"
})

ESPTab:AddToggle({
    "Show Health Bar",
    true,
    function(v)
        ESP.ShowHealth = v
    end,
    "ESPHealth"
})

ESPTab:AddToggle({
    "Show Distance",
    true,
    function(v)
        ESP.ShowDistance = v
    end,
    "ESPDistance"
})

ESPTab:AddToggle({
    "Show Tracers",
    false,
    function(v)
        ESP.ShowTracers = v
    end,
    "ESPTracers"
})

ESPTab:AddSlider({
    "Max Distance",
    100,
    3000,
    100,
    1000,
    function(v)
        ESP.MaxDistance = v
    end,
    "ESPMaxDist"
})

-- ============================================================
-- TAB: AUTO STATS
-- ============================================================

local StatsTab = Window:MakeTab({ "Stats", "rbxassetid://10747384394" })

StatsTab:AddSection("Auto Stats")

local StatParagraph = StatsTab:AddParagraph({ "Status", "Menunggu..." })

StatsTab:AddDropdown({
    "Pilih Stat",
    { "Melee", "Defense", "Sword", "Gun", "Devil Fruit" },
    "Melee",
    function(v)
        State.AutoStatType = v
        StatParagraph:Set("Status", "Stat dipilih: " .. v)
    end,
    "AutoStatType"
})

StatsTab:AddToggle({
    "Auto Stats",
    false,
    function(v)
        State.AutoStats = v

        if v then
            task.spawn(function()
                while State.AutoStats do
                    pcall(function()
                        local Data = LocalPlayer:FindFirstChild("Data")
                        local Points = Data and Data:FindFirstChild("StatPoint")
                        local available = Points and Points.Value or 0

                        if available > 0 then
                            StatParagraph:Set("Status",
                                string.format("Membagikan %d poin ke %s...", available, State.AutoStatType)
                            )

                            for _ = 1, available do
                                if not State.AutoStats then break end
                                if CommF then
                                    pcall(function()
                                        CommF:InvokeServer("Beli", State.AutoStatType)
                                    end)
                                end
                                task.wait(0.15)
                            end

                            StatParagraph:Set("Status", "Selesai! Poin habis terbagikan.")
                        else
                            StatParagraph:Set("Status",
                                string.format("Menunggu poin stat... (%s)", State.AutoStatType)
                            )
                        end
                    end)

                    task.wait(3)
                end

                StatParagraph:Set("Status", "Auto Stats dimatikan.")
            end)
        else
            StatParagraph:Set("Status", "Auto Stats dimatikan.")
        end
    end,
    "AutoStats"
})

StatsTab:AddButton({
    "Bagi 1 Poin Sekarang",
    function()
        if CommF then
            pcall(function()
                CommF:InvokeServer("Beli", State.AutoStatType)
            end)
            Notify({
                Title = "Xtray Script",
                Text  = "1 poin dibagikan ke " .. State.AutoStatType,
                Duration = 3
            })
        end
    end
})

StatsTab:AddSection("Info Level")

StatsTab:AddButton({
    "Lihat Info Karakter",
    function()
        local Data = LocalPlayer:FindFirstChild("Data")
        if not Data then
            Notify({ Title = "Xtray Script", Text = "Data karakter tidak ditemukan.", Duration = 3 })
            return
        end

        local lv    = GetLevel()
        local pts   = (Data:FindFirstChild("StatPoint") and Data.StatPoint.Value) or 0
        local melee = (Data:FindFirstChild("Melee")  and Data.Melee.Value)  or 0
        local def   = (Data:FindFirstChild("Defense") and Data.Defense.Value) or 0
        local sword = (Data:FindFirstChild("Sword")  and Data.Sword.Value)  or 0
        local gun   = (Data:FindFirstChild("Gun")    and Data.Gun.Value)    or 0
        local df    = (Data:FindFirstChild("Devil Fruit") and Data["Devil Fruit"].Value) or 0

        Notify({
            Title = "Info Karakter (Lv " .. lv .. ")",
            Text  = string.format(
                "Poin: %d | Melee: %d | Def: %d | Sword: %d | Gun: %d | DF: %d",
                pts, melee, def, sword, gun, df
            ),
            Duration = 8
        })
    end
})

-- ============================================================
-- TAB: DEVIL FRUIT
-- ============================================================

local FruitTab = Window:MakeTab({ "Fruit", "rbxassetid://10734943674" })

FruitTab:AddSection("Devil Fruit Notifier")

local FruitParagraph = FruitTab:AddParagraph({ "Status", "Notifier tidak aktif" })

FruitTab:AddToggle({
    "Fruit Notifier",
    false,
    function(v)
        State.FruitNotif = v

        if v then
            task.spawn(function()
                local known = {}

                while State.FruitNotif do
                    pcall(function()
                        local fruitFolders = {
                            workspace:FindFirstChild("Fruits"),
                            workspace:FindFirstChild("DroppedFruits"),
                        }

                        local found = false

                        for _, folder in ipairs(fruitFolders) do
                            if folder then
                                for _, fruit in ipairs(folder:GetChildren()) do
                                    local id = fruit:GetDebugId()
                                    if not known[id] then
                                        known[id] = true
                                        found = true

                                        local part = fruit.PrimaryPart
                                            or fruit:FindFirstChildOfClass("BasePart")
                                        local myRoot = GetRootPart()
                                        local dist = part and myRoot
                                            and (part.Position - myRoot.Position).Magnitude
                                            or 0

                                        FruitParagraph:Set(
                                            "Status",
                                            string.format("Buah ditemukan: %s (%.0fm)", fruit.Name, dist)
                                        )

                                        Notify({
                                            Title    = "Devil Fruit Muncul!",
                                            Text     = string.format(
                                                "%s muncul di map! Jarak: %.0f meter",
                                                fruit.Name, dist
                                            ),
                                            Duration = 10
                                        })
                                    end
                                end
                            end
                        end

                        if not found then
                            FruitParagraph:Set("Status", "Tidak ada buah ditemukan saat ini")
                        end
                    end)

                    task.wait(2)
                end

                FruitParagraph:Set("Status", "Notifier tidak aktif")
            end)
        else
            FruitParagraph:Set("Status", "Notifier tidak aktif")
        end
    end,
    "FruitNotif"
})

FruitTab:AddToggle({
    "Auto Teleport ke Buah",
    false,
    function(v)
        State.FruitSniper = v

        if v then
            task.spawn(function()
                while State.FruitSniper do
                    pcall(function()
                        local fruitFolders = {
                            workspace:FindFirstChild("Fruits"),
                            workspace:FindFirstChild("DroppedFruits"),
                        }

                        for _, folder in ipairs(fruitFolders) do
                            if folder then
                                local fruits = folder:GetChildren()
                                if #fruits > 0 then
                                    local closest, closestDist = nil, math.huge
                                    local myRoot = GetRootPart()

                                    for _, fruit in ipairs(fruits) do
                                        local part = fruit.PrimaryPart
                                            or fruit:FindFirstChildOfClass("BasePart")
                                        if part and myRoot then
                                            local d = (part.Position - myRoot.Position).Magnitude
                                            if d < closestDist then
                                                closest     = part
                                                closestDist = d
                                            end
                                        end
                                    end

                                    if closest and myRoot then
                                        myRoot.CFrame = CFrame.new(
                                            closest.Position + Vector3.new(0, 5, 0)
                                        )
                                    end
                                end
                            end
                        end
                    end)

                    task.wait(1)
                end
            end)
        end
    end,
    "FruitSniper"
})

FruitTab:AddSection("Buah di Map")

FruitTab:AddButton({
    "Scan Buah Sekarang",
    function()
        local found = {}
        local fruitFolders = {
            workspace:FindFirstChild("Fruits"),
            workspace:FindFirstChild("DroppedFruits"),
        }
        local myRoot = GetRootPart()

        for _, folder in ipairs(fruitFolders) do
            if folder then
                for _, fruit in ipairs(folder:GetChildren()) do
                    local part = fruit.PrimaryPart or fruit:FindFirstChildOfClass("BasePart")
                    local dist = part and myRoot
                        and (part.Position - myRoot.Position).Magnitude or 0
                    table.insert(found, string.format("%s (%.0fm)", fruit.Name, dist))
                end
            end
        end

        if #found > 0 then
            Notify({
                Title    = "Devil Fruit Ditemukan",
                Text     = table.concat(found, ", "),
                Duration = 8
            })
        else
            Notify({
                Title    = "Scan Buah",
                Text     = "Tidak ada buah yang ditemukan di map.",
                Duration = 4
            })
        end
    end
})

-- ============================================================
-- TAB: AUTO QUEST
-- ============================================================

local QuestTab = Window:MakeTab({ "Quest", "rbxassetid://10747384394" })

local QuestStatusParagraph

QuestTab:AddSection("Auto Quest")

QuestStatusParagraph = QuestTab:AddParagraph({
    "Status",
    "Menunggu..."
})

QuestTab:AddToggle({
    "Auto Quest",
    false,
    function(v)
        State.AutoQuest = v

        if v then
            task.spawn(function()
                while State.AutoQuest do

                    local quest = GetBestQuest()

                    if not quest then
                        QuestStatusParagraph:Set("Status", "Tidak ada quest yang sesuai level!")
                        task.wait(5)
                    else

                    -- ── STEP 1: Teleport ke NPC dan accept quest ──────────
                    QuestStatusParagraph:Set("Status", "Teleport ke NPC: " .. quest.NpcName)
                    TeleportTo(quest.NpcPos)
                    task.wait(1.5)

                    TryAcceptQuest(quest)
                    QuestStatusParagraph:Set("Status", "Quest diterima: " .. quest.Name)

                    -- ── STEP 2: Farm musuh sesuai quest ───────────────────
                    local killCount = 0
                    local killTarget = quest.Kill

                    QuestStatusParagraph:Set(
                        "Status",
                        ("Farm: %s [0/%d]"):format(quest.Name, killTarget)
                    )

                    local startTime = tick()

                    while State.AutoQuest and killCount < killTarget do
                        -- timeout 3 menit per quest agar tidak stuck
                        if tick() - startTime > 180 then
                            QuestStatusParagraph:Set("Status", "Quest timeout, skip ke quest berikutnya.")
                            break
                        end

                        -- Bring otomatis: tarik semua musuh quest ke player
                        BringEnemiesToPlayer()

                        local enemy = GetNearestEnemy(State.FarmRange, quest.Enemies)
                        local root  = GetRootPart()

                        if enemy and root then
                            local hrp = enemy:FindFirstChild("HumanoidRootPart")
                            local hum = enemy:FindFirstChildOfClass("Humanoid")

                            if hrp and hum and hum.Health > 0 then
                                -- Tween fly ke musuh (smooth, tidak abrupt)
                                pcall(TweenFlyTo, hrp.Position)
                                task.wait(0.1)

                                -- Pakai event Died agar kill count akurat
                                local killed = false
                                local deathConn
                                pcall(function()
                                    deathConn = hum.Died:Connect(function()
                                        killed = true
                                    end)
                                end)

                                -- Serang sampai mati atau timeout 15 detik
                                local attackStart = tick()
                                while State.AutoQuest and hum and hum.Health > 0
                                    and not killed and tick() - attackStart < 15 do
                                    -- Bring terus saat attack agar musuh tidak kabur
                                    BringEnemiesToPlayer()
                                    AttackWithWeapon()
                                    task.wait(0.05)
                                end

                                if deathConn then
                                    pcall(function() deathConn:Disconnect() end)
                                end

                                if killed or (hum and hum.Health <= 0) then
                                    killCount = killCount + 1
                                    QuestStatusParagraph:Set(
                                        "Status",
                                        ("Farm: %s [%d/%d]"):format(quest.Name, killCount, killTarget)
                                    )
                                end
                            end
                        else
                            -- Tidak ada musuh → terbang ke area spawn musuh quest
                            QuestStatusParagraph:Set("Status", "Cari musuh quest di area spawn...")
                            local spawnOffset = Vector3.new(
                                math.random(-30, 30), 5, math.random(-30, 30)
                            )
                            pcall(TweenFlyTo, quest.NpcPos + spawnOffset)
                            task.wait(1)
                        end

                        task.wait(0.05)
                    end

                    -- ── STEP 3: Kembali ke NPC dan selesaikan quest ───────
                    if State.AutoQuest and killCount >= killTarget then
                        QuestStatusParagraph:Set("Status", "Kembali ke NPC untuk selesaikan quest...")
                        pcall(TweenFlyTo, quest.NpcPos)
                        task.wait(1.5)
                        TryCompleteQuest(quest)
                        QuestStatusParagraph:Set("Status", "Quest selesai! Memulai quest berikutnya...")
                        task.wait(1)
                    end
                    end
                end

                if not State.AutoQuest then
                    QuestStatusParagraph:Set("Status", "Auto Quest dimatikan.")
                end
            end)
        else
            QuestStatusParagraph:Set("Status", "Auto Quest dimatikan.")
        end
    end,
    "AutoQuest"
})

QuestTab:AddSection("Info Quest")

QuestTab:AddButton({
    "Lihat Quest Saat Ini",
    function()
        local quest = GetBestQuest()
        if quest then
            Notify({
                Title    = "Xtray Script",
                Text     = ("Level %d → Quest: %s (kill %d %s)"):format(
                    GetLevel(), quest.Name, quest.Kill, quest.Enemies[1]
                ),
                Duration = 6
            })
        else
            Notify({
                Title    = "Xtray Script",
                Text     = "Tidak ada quest yang sesuai levelmu.",
                Duration = 4
            })
        end
    end
})

-- ============================================================
-- TAB: BOSS
-- ============================================================

local BossTab = Window:MakeTab({ "Boss", "rbxassetid://10734933961" })

BossTab:AddSection("Auto Boss Farm")

local BossParagraph = BossTab:AddParagraph({ "Status", "Auto Boss tidak aktif" })

local BossNames = {}
for _, b in ipairs(BossData) do
    table.insert(BossNames, b.Name .. " (Sea " .. b.Sea .. ")")
end

local SelectedBossDisplay = BossNames[1] or "Gorilla King (Sea 1)"

BossTab:AddDropdown({
    "Pilih Boss",
    BossNames,
    SelectedBossDisplay,
    function(v)
        -- parse nama boss dari string "Boss Name (Sea X)"
        local bname = v:match("^(.+) %(Sea %d+%)$") or v
        State.AutoBossName = bname
    end,
    "SelectedBoss"
})

BossTab:AddToggle({
    "Auto Boss Farm",
    false,
    function(v)
        State.AutoBoss = v

        if v then
            task.spawn(function()
                while State.AutoBoss do
                    local boss = GetBossByName(State.AutoBossName)
                    if not boss then
                        BossParagraph:Set("Status", "Boss tidak ditemukan di database!")
                        task.wait(2)
                    else

                    -- Teleport ke posisi boss
                    BossParagraph:Set("Status", "Teleport ke " .. boss.Name .. "...")
                    TeleportTo(boss.Position)
                    task.wait(1.5)

                    -- Cari boss di Enemies
                    local bossModel = nil
                    local EFolder   = workspace:FindFirstChild("Enemies")

                    if EFolder then
                        for _, e in ipairs(EFolder:GetChildren()) do
                            if e.Name == boss.Name then
                                local h = e:FindFirstChildOfClass("Humanoid")
                                if h and h.Health > 0 then
                                    bossModel = e
                                    break
                                end
                            end
                        end
                    end

                    if bossModel then
                        BossParagraph:Set("Status", "Menyerang " .. boss.Name .. "...")

                        local startTime = tick()
                        while State.AutoBoss do
                            local hum = bossModel:FindFirstChildOfClass("Humanoid")
                            if not hum or hum.Health <= 0 then
                                BossParagraph:Set("Status", boss.Name .. " telah mati! Menunggu respawn...")
                                task.wait(5)
                                break
                            end

                            if tick() - startTime > 300 then
                                BossParagraph:Set("Status", "Timeout, retry...")
                                break
                            end

                            -- Teleport ke boss terus
                            local hrp = bossModel:FindFirstChild("HumanoidRootPart")
                            if hrp then
                                local root = GetRootPart()
                                if root then
                                    local dist = (hrp.Position - root.Position).Magnitude
                                    if dist > 20 then
                                        pcall(TweenFlyTo, hrp.Position)
                                        task.wait(0.2)
                                    end
                                end
                            end

                            -- Gunakan Kill Aura jika aktif, atau serang normal
                            if State.KillAura then
                                pcall(KillAuraOnce, 80)
                            else
                                BringEnemiesToPlayer()
                                AttackWithWeapon()
                            end

                            task.wait(0.05)
                        end
                    else
                        BossParagraph:Set("Status", boss.Name .. " tidak ada di map. Tunggu respawn (30 detik)...")
                        task.wait(30)
                    end
                    end
                end

                BossParagraph:Set("Status", "Auto Boss tidak aktif")
            end)

            Notify({
                Title    = "Xtray Script",
                Text     = "Auto Boss Farm aktif: " .. State.AutoBossName,
                Duration = 5
            })
        else
            BossParagraph:Set("Status", "Auto Boss tidak aktif")
        end
    end,
    "AutoBoss"
})

BossTab:AddSection("Sea 1 - Bosses")
for _, b in ipairs(BossData) do
    if b.Sea == 1 then
        BossTab:AddButton({
            "TP → " .. b.Name .. " (Lv." .. b.Level .. ")",
            function()
                TeleportTo(b.Position)
                Notify({
                    Title    = "Xtray Script",
                    Text     = "Teleport ke " .. b.Name,
                    Duration = 3
                })
            end
        })
    end
end

BossTab:AddSection("Sea 2 - Bosses")
for _, b in ipairs(BossData) do
    if b.Sea == 2 then
        BossTab:AddButton({
            "TP → " .. b.Name .. " (Lv." .. b.Level .. ")",
            function()
                TeleportTo(b.Position)
                Notify({
                    Title    = "Xtray Script",
                    Text     = "Teleport ke " .. b.Name,
                    Duration = 3
                })
            end
        })
    end
end

BossTab:AddSection("Sea 3 - Bosses")
for _, b in ipairs(BossData) do
    if b.Sea == 3 then
        BossTab:AddButton({
            "TP → " .. b.Name .. " (Lv." .. b.Level .. ")",
            function()
                TeleportTo(b.Position)
                Notify({
                    Title    = "Xtray Script",
                    Text     = "Teleport ke " .. b.Name,
                    Duration = 3
                })
            end
        })
    end
end

BossTab:AddSection("Info Sea")

BossTab:AddButton({
    "Deteksi Sea Saat Ini",
    function()
        local sea = DetectSea()
        local seaName = sea == 0 and "Tidak diketahui" or ("Sea " .. sea)
        Notify({
            Title    = "Xtray Script",
            Text     = "Kamu berada di: " .. seaName,
            Duration = 5
        })
    end
})

-- ============================================================
-- TAB: VISUAL
-- ============================================================

local VisualTab = Window:MakeTab({ "Visual", "rbxassetid://10734943674" })

VisualTab:AddSection("Lighting")

VisualTab:AddToggle({
    "Full Bright",
    false,
    function(v)
        FullBright:Toggle(v)
    end,
    "FullBright"
})

VisualTab:AddSection("Movement")

VisualTab:AddToggle({
    "Speed Hack",
    false,
    function(v)
        Movement:Toggle(v)
    end,
    "SpeedHack"
})

VisualTab:AddSlider({
    "Walk Speed",
    16,
    500,
    1,
    58,
    function(v)
        Movement:SetSpeed(v)
    end,
    "WalkSpeed"
})

VisualTab:AddSlider({
    "Jump Power",
    50,
    500,
    1,
    150,
    function(v)
        Movement:SetJump(v)
    end,
    "JumpPower"
})

VisualTab:AddSection("Fast Attack")

VisualTab:AddToggle({
    "Fast Attack (Melee / Sword / Fruit / Gun)",
    false,
    function(v)
        State.FastAttack = v
        FastAttack:Toggle(v)
        Notify({
            Title = "Xtray Script",
            Text  = v and "Fast Attack aktif — serangan max speed!" or "Fast Attack dimatikan.",
            Duration = 3
        })
    end,
    "FastAttack"
})

VisualTab:AddSlider({
    "Fast Attack Range",
    10,
    300,
    5,
    60,
    function(v)
        State.FastAttackRange = v
        FastAttack:SetRange(v)
    end,
    "FastAttackRange"
})

VisualTab:AddToggle({
    "Serang Pemain (PvP)",
    false,
    function(v)
        FastAttack:SetAttackPlayers(v)
    end,
    "FastAttackPvP"
})

VisualTab:AddToggle({
    "Serang Musuh (Mob)",
    true,
    function(v)
        FastAttack:SetAttackMobs(v)
    end,
    "FastAttackMobs"
})

VisualTab:AddSection("Movement")

VisualTab:AddToggle({
    "Infinite Jump",
    false,
    function(v)
        State.InfJump = v

        if v then
            Connections.InfJump = UserInputService.JumpRequest:Connect(function()
                if not State.InfJump then return end
                local hum = GetHumanoid()
                if hum then
                    hum:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end)
        else
            if Connections.InfJump then
                Connections.InfJump:Disconnect()
                Connections.InfJump = nil
            end
        end
    end,
    "InfJump"
})

-- ============================================================
-- TAB: TELEPORT
-- ============================================================

local TeleportTab = Window:MakeTab({ "Teleport", "rbxassetid://10709791437" })

TeleportTab:AddSection("Sea 1 - Islands")

local Sea1Islands = {
    { "Starter Island",   Vector3.new(977,   15,  1579) },
    { "Marine Starter",   Vector3.new(-2373,  8,  2205) },
    { "Jungle",           Vector3.new(-1718,  8,  -650) },
    { "Pirate Village",   Vector3.new(-1370,  8,  1890) },
    { "Desert",           Vector3.new(922,    9,  -450) },
    { "Snow Island",      Vector3.new(1170,   8, -3200) },
    { "Skylands",         Vector3.new(-5130, 460,-1175) },
    { "Prison",           Vector3.new(4713,   6,   754) },
    { "Colosseum",        Vector3.new(924,   99, -1567) },
    { "Magma Village",    Vector3.new(-4630, 725,-3350) },
    { "Upper Skylands",   Vector3.new(-5060, 738,-1152) },
}

for _, island in ipairs(Sea1Islands) do
    TeleportTab:AddButton({
        island[1],
        function() TeleportTo(island[2]) end
    })
end

TeleportTab:AddSection("Sea 2 - Islands")

local Sea2Islands = {
    { "Flower Hill",      Vector3.new(-2980,  67, -9095) },
    { "Cafe",             Vector3.new(-5154,  23, -3869) },
    { "Ice Castle",       Vector3.new(1160,  121, -9698) },
    { "Forgotten Island", Vector3.new(-3848, 288, -5575) },
    { "Cocoa Island",     Vector3.new(-6227,  10, -7453) },
    { "Haunted Castle",   Vector3.new(-4898, 141, -9766) },
    { "Green Zone",       Vector3.new(4347,   36, -7612) },
    { "Graveyard",        Vector3.new(5031,    4, -6233) },
    { "Snow Mountain",    Vector3.new(-3050, 335, -9543) },
}

for _, island in ipairs(Sea2Islands) do
    TeleportTab:AddButton({
        island[1],
        function() TeleportTo(island[2]) end
    })
end

TeleportTab:AddSection("Sea 3 - Islands")

local Sea3Islands = {
    { "Port Town",           Vector3.new(-449,    109,   5950) },
    { "Castle on the Sea",   Vector3.new(-1049,    40,   6791) },
    { "Hydra Island (Sky)",  Vector3.new(5214,   1004,    761) },
    { "Great Tree",          Vector3.new(2485,     74,  -6788) },
    { "Floating Turtle",     Vector3.new(-5450,   280,   -430) },
    { "Haunted Castle",      Vector3.new(-1680,   121, -11610) },
    { "Ice Cream Island",    Vector3.new(-13665,  199, -11000) },
    { "Deep Forest",         Vector3.new(-13233,  332,  -7626) },
    { "Longma Island",       Vector3.new(-10218,  333,  -9444) },
}

for _, island in ipairs(Sea3Islands) do
    TeleportTab:AddButton({
        island[1],
        function() TeleportTo(island[2]) end
    })
end

-- ============================================================
-- TAB: MISC
-- ============================================================

local MiscTab = Window:MakeTab({ "Misc", "rbxassetid://10709752996" })

MiscTab:AddSection("Anti-AFK & Auto Rejoin")

MiscTab:AddToggle({
    "Anti-AFK",
    false,
    function(v)
        State.AntiAFK = v

        if v then
            -- Simulasikan input agar tidak ter-kick karena idle
            Connections.AntiAFK = RunService.Heartbeat:Connect(function()
                if not State.AntiAFK then return end
                if tick() % 60 < 0.05 then
                    local VIS = game:GetService("VirtualInputManager")
                    pcall(function()
                        VIS:SendKeyEvent(true, Enum.KeyCode.W, false, game)
                        VIS:SendKeyEvent(false, Enum.KeyCode.W, false, game)
                    end)
                end
            end)

            -- Anti-AFK via humanoid state
            task.spawn(function()
                while State.AntiAFK do
                    local hum = GetHumanoid()
                    if hum then
                        pcall(function()
                            hum:ChangeState(Enum.HumanoidStateType.Running)
                        end)
                    end
                    task.wait(60)
                end
            end)

            Notify({
                Title = "Xtray Script",
                Text  = "Anti-AFK diaktifkan — kamu tidak akan di-kick.",
                Duration = 4
            })
        else
            if Connections.AntiAFK then
                Connections.AntiAFK:Disconnect()
                Connections.AntiAFK = nil
            end
        end
    end,
    "AntiAFK"
})

MiscTab:AddToggle({
    "Auto Rejoin (tiap 30 menit)",
    false,
    function(v)
        AntiReset.SetEnabled(v)
        if v then
            Notify({
                Title = "Xtray Script",
                Text  = "Auto Rejoin aktif — script akan pindah server tiap ~30 menit.",
                Duration = 5
            })
        end
    end,
    "AutoRejoin"
})

MiscTab:AddSection("Haki & Combat")

MiscTab:AddToggle({
    "Auto Buso Haki",
    false,
    function(v)
        State.AutoBuso = v

        if v then
            task.spawn(function()
                while State.AutoBuso do
                    pcall(TryEnableBuso)
                    task.wait(2)
                end
            end)
            Notify({
                Title    = "Xtray Script",
                Text     = "Auto Buso Haki aktif — Buso akan diaktifkan otomatis.",
                Duration = 4
            })
        end
    end,
    "AutoBuso"
})

MiscTab:AddButton({
    "Aktifkan Buso Sekali",
    function()
        pcall(TryEnableBuso)
        Notify({
            Title    = "Xtray Script",
            Text     = "Mencoba mengaktifkan Buso Haki...",
            Duration = 3
        })
    end
})

MiscTab:AddSection("Player")

MiscTab:AddButton({
    "Rejoin Server",
    function()
        local TeleportService = game:GetService("TeleportService")
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end
})

MiscTab:AddButton({
    "Copy PlaceId",
    function()
        if setclipboard then
            setclipboard(tostring(game.PlaceId))
            Notify({ Title = "Xtray Script", Text = "PlaceId tersalin: " .. game.PlaceId, Duration = 3 })
        end
    end
})

MiscTab:AddSection("Info")

MiscTab:AddParagraph({
    "Xtray Script",
    "Version 1.5.0 | github.com/XtrayScript"
})

MiscTab:AddParagraph({
    "Developer",
    "XtrayScript"
})

-- ============================================================
-- HELPER: HOP SERVER
-- ============================================================

local function HopServer()
    pcall(function()
        local TeleportService = game:GetService("TeleportService")
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end)
end

local function IsNPCPresent(npcName)
    local npcs = workspace:FindFirstChild("NPCs")
    if npcs and npcs:FindFirstChild(npcName) then return true end
    for _, obj in ipairs(workspace:GetChildren()) do
        if obj.Name == npcName then return true end
    end
    return false
end

-- ============================================================
-- TAB: FISHING
-- ============================================================

local FishingTab = Window:MakeTab({ "Fishing", "rbxassetid://10734943674" })

local FishingRemote   = Remotes and Remotes:FindFirstChild("FishingRequest")
local JobsRemote      = Remotes and Remotes:FindFirstChild("JobsRemoteFunction")

local FishParagraph = FishingTab:AddParagraph({ "Status", "Tidak aktif" })

FishingTab:AddSection("Pengaturan")

FishingTab:AddDropdown({
    "Pilih Rod",
    { "Basic Rod", "Iron Rod", "Saber Rod", "Serpent Rod", "Trident" },
    "Basic Rod",
    function(v)
        State.SelectedRod = v
    end,
    "SelectedRod"
})

FishingTab:AddSection("Auto Fishing")

FishingTab:AddToggle({
    "Auto Fishing",
    false,
    function(v)
        State.AutoFishing = v

        if v then
            task.spawn(function()
                while State.AutoFishing do
                    pcall(function()
                        local char = LocalPlayer.Character
                        local root = char and char:FindFirstChild("HumanoidRootPart")
                        if not root then return end

                        -- Equip rod jika belum
                        local tool = char:FindFirstChildOfClass("Tool")
                        if not tool or tool.Name ~= State.SelectedRod then
                            local rod = LocalPlayer.Backpack:FindFirstChild(State.SelectedRod)
                            if rod then
                                char.Humanoid:EquipTool(rod)
                                tool = rod
                                task.wait(0.3)
                            end
                        end

                        if tool then
                            local clientState = tool:GetAttribute("State")
                            local serverState = tool:GetAttribute("ServerState")
                            local targetPos   = root.CFrame * CFrame.new(0, -3, -20)

                            if clientState == "ReeledIn" or serverState == "ReeledIn" then
                                if FishingRemote then
                                    FishingRemote:InvokeServer("StartCasting")
                                    task.wait(0.1)
                                    FishingRemote:InvokeServer("CastLineAtLocation", targetPos.Position, 100, true)
                                end
                                FishParagraph:Set("Status", "Casting...")
                            elseif serverState == "Biting" then
                                if FishingRemote then
                                    FishingRemote:InvokeServer("Catching", true)
                                    task.wait(0.1)
                                    FishingRemote:InvokeServer("Catch", 1)
                                end
                                FishParagraph:Set("Status", "Menangkap ikan!")
                            else
                                FishParagraph:Set("Status", "Menunggu ikan... (" .. tostring(serverState) .. ")")
                            end
                        end
                    end)
                    task.wait(0.5)
                end
                FishParagraph:Set("Status", "Tidak aktif")
            end)
        else
            FishParagraph:Set("Status", "Tidak aktif")
        end
    end,
    "AutoFishing"
})

FishingTab:AddToggle({
    "Auto Quest Fishing",
    false,
    function(v)
        State.AutoFishingQuest = v

        if v then
            task.spawn(function()
                while State.AutoFishingQuest do
                    pcall(function()
                        if JobsRemote then
                            local hasQuest = false
                            local qGui = LocalPlayer.PlayerGui:FindFirstChild("Quest") or
                                         LocalPlayer.PlayerGui:FindFirstChild("QuestGui")
                            if qGui and qGui:FindFirstChild("Container") then
                                hasQuest = true
                            end
                            if not hasQuest then
                                JobsRemote:InvokeServer("FishingNPC", "Angler", "AskQuest")
                                FishParagraph:Set("Status", "Menerima fishing quest...")
                            end
                        end
                    end)
                    task.wait(3)
                end
            end)
        end
    end,
    "AutoFishingQuest"
})

FishingTab:AddToggle({
    "Auto Complete Quest Fishing",
    false,
    function(v)
        if v then
            task.spawn(function()
                while v do
                    pcall(function()
                        if JobsRemote then
                            JobsRemote:InvokeServer("FishingNPC", "FinishQuest")
                        end
                    end)
                    task.wait(5)
                end
            end)
        end
    end,
    "AutoCompleteQuest"
})

FishingTab:AddToggle({
    "Auto Sell Fish",
    false,
    function(v)
        State.AutoSellFish = v

        if v then
            task.spawn(function()
                while State.AutoSellFish do
                    pcall(function()
                        if JobsRemote then
                            JobsRemote:InvokeServer("FishingNPC", "SellFish")
                            FishParagraph:Set("Status", "Menjual ikan...")
                        end
                    end)
                    task.wait(10)
                end
            end)
        end
    end,
    "AutoSellFish"
})

-- ============================================================
-- TAB: MASTERY
-- ============================================================

local MasteryTab = Window:MakeTab({ "Mastery", "rbxassetid://10734933961" })

local MasteryParagraph = MasteryTab:AddParagraph({ "Status", "Tidak aktif" })

MasteryTab:AddSection("Pengaturan Mastery Farm")

MasteryTab:AddDropdown({
    "Metode Farm",
    { "Blox Fruit", "Gun", "Sword", "Melee" },
    "Blox Fruit",
    function(v)
        State.MasteryMethod = v
    end,
    "MasteryMethod"
})

MasteryTab:AddSection("Farm")

MasteryTab:AddToggle({
    "Mastery Farm",
    false,
    function(v)
        State.MasteryFarm = v

        if v then
            task.spawn(function()
                while State.MasteryFarm do
                    pcall(function()
                        local char = LocalPlayer.Character
                        if not char then return end

                        -- Auto equip weapon sesuai metode
                        local backpack = LocalPlayer.Backpack
                        local target   = nil

                        for _, tool in ipairs(backpack:GetChildren()) do
                            if tool:IsA("Tool") then
                                local tip = tool.ToolTip or ""
                                if State.MasteryMethod == "Blox Fruit" and string.find(tip, "Blox Fruit") then
                                    target = tool; break
                                elseif State.MasteryMethod == "Gun" and string.find(tip, "Gun") then
                                    target = tool; break
                                elseif State.MasteryMethod == "Sword" and string.find(tip, "Sword") then
                                    target = tool; break
                                elseif State.MasteryMethod == "Melee" and string.find(tip, "Melee") then
                                    target = tool; break
                                end
                            end
                        end

                        if target then
                            local hum = char:FindFirstChildOfClass("Humanoid")
                            if hum then hum:EquipTool(target) end
                            task.wait(0.1)
                        end

                        -- Serang musuh terdekat
                        local enemy = GetNearestEnemy(State.FarmRange, nil)
                        local root  = GetRootPart()

                        if enemy and root then
                            local hrp = enemy:FindFirstChild("HumanoidRootPart")
                            local hum = enemy:FindFirstChildOfClass("Humanoid")
                            if hrp and hum and hum.Health > 0 then
                                local dist = (hrp.Position - root.Position).Magnitude
                                if dist > 10 then
                                    pcall(TweenFlyTo, hrp.Position)
                                    task.wait(0.2)
                                end
                                MasteryParagraph:Set("Status",
                                    ("Farm Mastery [%s] → %s"):format(State.MasteryMethod, enemy.Name)
                                )
                                AttackWithWeapon()
                            end
                        else
                            MasteryParagraph:Set("Status", "Mencari musuh...")
                        end
                    end)
                    task.wait(0.05)
                end
                MasteryParagraph:Set("Status", "Tidak aktif")
            end)
            Notify({ Title = "Xtray Script", Text = "Mastery Farm aktif: " .. State.MasteryMethod, Duration = 4 })
        else
            MasteryParagraph:Set("Status", "Tidak aktif")
        end
    end,
    "MasteryFarm"
})

MasteryTab:AddSection("Info")

MasteryTab:AddParagraph({
    "Tips",
    "Pastikan kamu sudah equip senjata yang benar di backpack sebelum aktifkan Mastery Farm."
})

-- ============================================================
-- TAB: SEA EVENT
-- ============================================================

local SeaEventTab = Window:MakeTab({ "Sea Event", "rbxassetid://10709791437" })

local SeaParagraph = SeaEventTab:AddParagraph({ "Status", "Tidak aktif" })

local SeaEnemyMap = {
    ["Shark"]               = "Shark",
    ["Piranha"]             = "Piranha",
    ["Terror Shark"]        = "Terrorshark",
    ["Fish Crew Member"]    = "Fish Crew Member",
    ["Haunted Crew Member"] = "Haunted Crew Member",
    ["Sea Soldier"]         = "Sea Soldier",
    ["Water Fighter"]       = "Water Fighter",
}

SeaEventTab:AddSection("Pengaturan")

SeaEventTab:AddDropdown({
    "Pilih Sea Event",
    { "Shark", "Piranha", "Terror Shark", "Fish Crew Member", "Haunted Crew Member", "Sea Soldier", "Water Fighter" },
    "Shark",
    function(v)
        State.SelectedSeaEvent = v
    end,
    "SelectedSeaEvent"
})

SeaEventTab:AddSection("Auto Farm")

SeaEventTab:AddToggle({
    "Auto Sea Event",
    false,
    function(v)
        State.SeaEventFarm = v

        if v then
            task.spawn(function()
                while State.SeaEventFarm do
                    pcall(function()
                        local targetName = SeaEnemyMap[State.SelectedSeaEvent] or State.SelectedSeaEvent
                        local EFolder    = workspace:FindFirstChild("Enemies")
                        local root       = GetRootPart()

                        if not EFolder or not root then return end

                        local nearest, nearestDist = nil, math.huge

                        for _, e in ipairs(EFolder:GetChildren()) do
                            if e.Name == targetName then
                                local hum = e:FindFirstChildOfClass("Humanoid")
                                local hrp = e:FindFirstChild("HumanoidRootPart")
                                if hum and hum.Health > 0 and hrp then
                                    local d = (hrp.Position - root.Position).Magnitude
                                    if d < nearestDist then
                                        nearest     = e
                                        nearestDist = d
                                    end
                                end
                            end
                        end

                        if nearest then
                            local hrp = nearest:FindFirstChild("HumanoidRootPart")
                            local hum = nearest:FindFirstChildOfClass("Humanoid")
                            if hrp and hum and hum.Health > 0 then
                                SeaParagraph:Set("Status", "Menyerang " .. nearest.Name .. " (" .. math.floor(nearestDist) .. "m)")
                                local dist = (hrp.Position - root.Position).Magnitude
                                if dist > 15 then
                                    pcall(TweenFlyTo, hrp.Position)
                                    task.wait(0.2)
                                end
                                AttackWithWeapon()
                            end
                        else
                            SeaParagraph:Set("Status", "Menunggu " .. State.SelectedSeaEvent .. " muncul...")
                        end
                    end)
                    task.wait(0.05)
                end
                SeaParagraph:Set("Status", "Tidak aktif")
            end)
            Notify({ Title = "Xtray Script", Text = "Auto Sea Event: " .. State.SelectedSeaEvent, Duration = 4 })
        else
            SeaParagraph:Set("Status", "Tidak aktif")
        end
    end,
    "SeaEventFarm"
})

SeaEventTab:AddSection("Info")
SeaEventTab:AddParagraph({ "Tips", "Sea Events muncul saat kamu di atas kapal / laut. Pastikan speedhack aktif agar bisa mengejar musuh laut." })

-- ============================================================
-- TAB: EXTRAS
-- ============================================================

local ExtrasTab = Window:MakeTab({ "Extras", "rbxassetid://10709752996" })

-- ── CHEST FARM ──────────────────────────────────────────────

ExtrasTab:AddSection("Chest Farm")

local ChestParagraph = ExtrasTab:AddParagraph({ "Status Chest", "Tidak aktif" })

ExtrasTab:AddToggle({
    "Auto Chest Farm",
    false,
    function(v)
        State.AutoChest = v

        if v then
            task.spawn(function()
                local CollectionService = game:GetService("CollectionService")
                while State.AutoChest do
                    pcall(function()
                        local char  = LocalPlayer.Character
                        local root  = GetRootPart()
                        if not root then return end

                        local chests  = CollectionService:GetTagged("_ChestTagged")
                        local nearest, nearestDist = nil, math.huge

                        for _, chest in ipairs(chests) do
                            if not chest:GetAttribute("IsDisabled") then
                                local ok, pos = pcall(function() return chest:GetPivot().Position end)
                                if ok then
                                    local d = (pos - root.Position).Magnitude
                                    if d < nearestDist then
                                        nearest     = chest
                                        nearestDist = d
                                    end
                                end
                            end
                        end

                        if nearest then
                            ChestParagraph:Set("Status Chest", ("Chest ditemukan (%.0fm)"):format(nearestDist))
                            pcall(function()
                                root.CFrame = nearest:GetPivot() * CFrame.new(0, 3, 0)
                            end)
                        else
                            ChestParagraph:Set("Status Chest", "Tidak ada chest di map")
                        end
                    end)
                    task.wait(0.2)
                end
                ChestParagraph:Set("Status Chest", "Tidak aktif")
            end)
        else
            ChestParagraph:Set("Status Chest", "Tidak aktif")
        end
    end,
    "AutoChest"
})

ExtrasTab:AddToggle({
    "Auto Chest Hop (pindah server jika tidak ada chest)",
    false,
    function(v)
        State.AutoChestHop = v

        if v then
            task.spawn(function()
                local CollectionService = game:GetService("CollectionService")
                while State.AutoChestHop do
                    pcall(function()
                        if State.AutoChest then
                            local chests = CollectionService:GetTagged("_ChestTagged")
                            local hasActive = false
                            for _, c in ipairs(chests) do
                                if not c:GetAttribute("IsDisabled") then
                                    hasActive = true
                                    break
                                end
                            end
                            if not hasActive then
                                ChestParagraph:Set("Status Chest", "Tidak ada chest, hop server...")
                                task.wait(2)
                                HopServer()
                            end
                        end
                    end)
                    task.wait(3)
                end
            end)
        end
    end,
    "AutoChestHop"
})

-- ── FIRE FLOWERS (Sea 3) ─────────────────────────────────────

ExtrasTab:AddSection("Fire Flowers (Sea 3)")

local FlowerParagraph = ExtrasTab:AddParagraph({ "Status Flower", "Tidak aktif" })

ExtrasTab:AddToggle({
    "Auto Collect Fire Flowers",
    false,
    function(v)
        State.AutoFireFlowers = v

        if v then
            task.spawn(function()
                local VIM = game:GetService("VirtualInputManager")
                while State.AutoFireFlowers do
                    pcall(function()
                        local root = GetRootPart()
                        if not root then return end

                        local FireFlowers = workspace:FindFirstChild("FireFlowers")
                        if FireFlowers then
                            local nearest, nearestDist = nil, math.huge
                            for _, flower in ipairs(FireFlowers:GetChildren()) do
                                if flower:IsA("Model") then
                                    local pp = flower.PrimaryPart or flower:FindFirstChildOfClass("BasePart")
                                    if pp then
                                        local d = (pp.Position - root.Position).Magnitude
                                        if d < nearestDist then
                                            nearest     = pp
                                            nearestDist = d
                                        end
                                    end
                                end
                            end

                            if nearest then
                                FlowerParagraph:Set("Status Flower", ("Flower (%.0fm)"):format(nearestDist))
                                if nearestDist > 10 then
                                    pcall(function() root.CFrame = CFrame.new(nearest.Position + Vector3.new(0,3,0)) end)
                                    task.wait(0.3)
                                end
                                pcall(function()
                                    VIM:SendKeyEvent(true,  "E", false, game)
                                    task.wait(0.5)
                                    VIM:SendKeyEvent(false, "E", false, game)
                                end)
                                task.wait(1)
                            else
                                FlowerParagraph:Set("Status Flower", "Tidak ada flower di map")
                            end
                        else
                            FlowerParagraph:Set("Status Flower", "Folder FireFlowers tidak ditemukan (harus di Sea 3)")
                        end
                    end)
                    task.wait(0.5)
                end
                FlowerParagraph:Set("Status Flower", "Tidak aktif")
            end)
        else
            FlowerParagraph:Set("Status Flower", "Tidak aktif")
        end
    end,
    "AutoFireFlowers"
})

-- ── SKILLS ──────────────────────────────────────────────────

ExtrasTab:AddSection("Skills & Haki")

ExtrasTab:AddToggle({
    "Auto Skill Z (spam skill Z)",
    false,
    function(v)
        State.AutoSkillZ = v

        if v then
            task.spawn(function()
                local VIM = game:GetService("VirtualInputManager")
                while State.AutoSkillZ do
                    pcall(function()
                        VIM:SendKeyEvent(true,  "Z", false, game)
                        task.wait(0.05)
                        VIM:SendKeyEvent(false, "Z", false, game)
                    end)
                    task.wait(0.1)
                end
            end)
        end
    end,
    "AutoSkillZ"
})

ExtrasTab:AddToggle({
    "Auto Logia (aktifkan Logia Protection)",
    false,
    function(v)
        State.AutoLogia = v

        if v then
            task.spawn(function()
                while State.AutoLogia do
                    pcall(function()
                        local char = LocalPlayer.Character
                        if char and not char:FindFirstChild("HasLogia") then
                            if CommF then
                                CommF:InvokeServer("Logia")
                            end
                        end
                    end)
                    task.wait(2)
                end
            end)
            Notify({ Title = "Xtray Script", Text = "Auto Logia aktif.", Duration = 3 })
        end
    end,
    "AutoLogia"
})

-- ── HOP SERVER ───────────────────────────────────────────────

ExtrasTab:AddSection("Hop Server")

ExtrasTab:AddToggle({
    "Auto Hop — Legendary Sword (cari dealer)",
    false,
    function(v)
        State.AutoHopLegSword = v

        if v then
            task.spawn(function()
                while State.AutoHopLegSword do
                    pcall(function()
                        if not IsNPCPresent("LegendarySwordDealer") then
                            task.wait(3)
                            HopServer()
                        end
                    end)
                    task.wait(5)
                end
            end)
            Notify({ Title = "Xtray Script", Text = "Auto Hop Legendary Sword aktif.", Duration = 4 })
        end
    end,
    "AutoHopLegSword"
})

ExtrasTab:AddToggle({
    "Auto Hop — Haki Color (cari dealer)",
    false,
    function(v)
        State.AutoHopHakiColor = v

        if v then
            task.spawn(function()
                while State.AutoHopHakiColor do
                    pcall(function()
                        if not IsNPCPresent("ColorsDealer") then
                            task.wait(3)
                            HopServer()
                        end
                    end)
                    task.wait(5)
                end
            end)
            Notify({ Title = "Xtray Script", Text = "Auto Hop Haki Color aktif.", Duration = 4 })
        end
    end,
    "AutoHopHakiColor"
})

ExtrasTab:AddButton({
    "Hop Server Sekarang",
    function()
        Notify({ Title = "Xtray Script", Text = "Pindah server...", Duration = 3 })
        task.wait(1)
        HopServer()
    end
})

-- ── RACE & MISC SHOP ─────────────────────────────────────────

ExtrasTab:AddSection("Race & Shop")

ExtrasTab:AddButton({
    "Reroll Race",
    function()
        pcall(function()
            CommF:InvokeServer("BlackbeardReward", "Reroll", "1")
            CommF:InvokeServer("BlackbeardReward", "Reroll", "2")
        end)
        Notify({ Title = "Xtray Script", Text = "Reroll Race dijalankan!", Duration = 4 })
    end
})

ExtrasTab:AddButton({
    "Reset Stats",
    function()
        pcall(function()
            CommF:InvokeServer("BlackbeardReward", "Refund", "1")
            CommF:InvokeServer("BlackbeardReward", "Refund", "2")
        end)
        Notify({ Title = "Xtray Script", Text = "Reset Stats dijalankan!", Duration = 4 })
    end
})

ExtrasTab:AddButton({
    "Beli Ghoul Race (250 Ectoplasm)",
    function()
        pcall(function()
            CommF:InvokeServer("Ectoplasm", "BuyCheck", 4)
            task.wait(0.5)
            CommF:InvokeServer("Ectoplasm", "Change", 4)
        end)
        Notify({ Title = "Xtray Script", Text = "Mencoba beli Ghoul Race...", Duration = 4 })
    end
})

ExtrasTab:AddButton({
    "Beli Cyborg Race",
    function()
        pcall(function()
            CommF:InvokeServer("CyborgTrainer", "Buy")
        end)
        Notify({ Title = "Xtray Script", Text = "Mencoba beli Cyborg Race...", Duration = 4 })
    end
})

ExtrasTab:AddButton({
    "Beli Legendary Sword (dari dealer)",
    function()
        pcall(function()
            CommF:InvokeServer("LegendarySwordDealer", "1")
        end)
        Notify({ Title = "Xtray Script", Text = "Mencoba beli Legendary Sword...", Duration = 4 })
    end
})

-- ============================================================
-- NOTIFIKASI SELESAI LOAD
-- ============================================================

Notify({
    Title    = "Xtray Script",
    Text     = "Script v2.0.0 berhasil dimuat! Farm + Panda-Hub logic, Boss, Fishing, Mastery, Sea Event ready!",
    Duration = 5
})
