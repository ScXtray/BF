--[[
    XTRAY FAST ATTACK MODULE v2.0
    Teknik gabungan dari DojoHub + Skirasuperfastattack
    - RegisterAttack + RegisterHit (Melee/Sword/Fruit)
    - ShootGunEvent (Gun)
    - PMT_GunFast compatibility
    - Heartbeat loop (max speed)
    - Range & Rate configurable
]]

local FastAttackModule = {}
FastAttackModule.Enabled    = false
FastAttackModule.Range      = 60
FastAttackModule.Rate       = 0
FastAttackModule.AttackMobs = true
FastAttackModule.AttackPlrs = false
FastAttackModule._conn      = nil

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer

-- ── NET MODULE ───────────────────────────────────────────────────

local Net = nil
pcall(function()
    Net = require(ReplicatedStorage:WaitForChild("Modules", 5):WaitForChild("Net", 5))
end)

local function getRemote(name)
    if not Net then return nil end
    return pcall(function() return Net[name] end) and Net[name] or nil
end

-- ── HELPER ───────────────────────────────────────────────────────

local function isAlive(model)
    local h = model and model:FindFirstChildOfClass("Humanoid")
    return h and h.Health > 0
end

local function getRootPos()
    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    return hrp and hrp.Position
end

-- ── GET TARGETS ──────────────────────────────────────────────────

local function getTargets()
    local myPos = getRootPos()
    if not myPos then return {}, {} end

    local range   = FastAttackModule.Range
    local targets = {}  -- list of {model, headPart}
    local roots   = {}  -- list of HumanoidRootPart

    local function scan(folder)
        if not folder then return end
        for _, e in ipairs(folder:GetChildren()) do
            if e ~= LocalPlayer.Character and isAlive(e) then
                local hrp  = e:FindFirstChild("HumanoidRootPart")
                local head = e:FindFirstChild("Head") or hrp
                if hrp and (hrp.Position - myPos).Magnitude <= range then
                    table.insert(targets, { e, head })
                    table.insert(roots, hrp)
                end
            end
        end
    end

    if FastAttackModule.AttackMobs then
        scan(workspace:FindFirstChild("Enemies"))
    end
    if FastAttackModule.AttackPlrs then
        scan(workspace:FindFirstChild("Characters"))
    end

    return targets, roots
end

-- ── CORE ATTACK ──────────────────────────────────────────────────

local function doAttack()
    if not FastAttackModule.Enabled then return end

    local char = LocalPlayer.Character
    if not char or not isAlive(char) then return end

    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then return end

    local targets, roots = getTargets()
    if #targets == 0 then return end

    local toolTip = (tool.ToolTip or ""):lower()

    -- ── GUN FAST ────────────────────────────────────────────────
    if string.find(toolTip, "gun") then
        pcall(function()
            getgenv().PMT_GunFast       = true
            getgenv().PMT_GunFast_Delay = 0
            tool:Activate()
            local shootRemote = getRemote("RE/ShootGunEvent")
            if shootRemote then
                local topTarget = targets[1]
                if topTarget and topTarget[2] then
                    shootRemote:FireServer(topTarget[2].Position, { topTarget[2] })
                end
            end
        end)
        return
    end

    -- ── MELEE / SWORD / BLOX FRUIT ───────────────────────────────
    pcall(function()
        local attackRemote = getRemote("RE/RegisterAttack")
        local hitRemote    = getRemote("RE/RegisterHit")

        if attackRemote then
            attackRemote:FireServer(FastAttackModule.Rate)
        end

        if hitRemote and #targets > 0 then
            local topHead = targets[1][2]
            hitRemote:FireServer(topHead, targets)
        end

        -- Juga activate tool (visual)
        pcall(function() tool:Activate() end)
    end)
end

-- ── START / STOP ─────────────────────────────────────────────────

function FastAttackModule:Start()
    if self._conn then return end

    -- Heartbeat loop (jauh lebih cepat dari task.wait)
    self._conn = RunService.Heartbeat:Connect(function()
        pcall(doAttack)
    end)
end

function FastAttackModule:Stop()
    if self._conn then
        self._conn:Disconnect()
        self._conn = nil
    end
    -- Reset gun flag
    pcall(function()
        getgenv().PMT_GunFast = false
    end)
end

function FastAttackModule:Toggle(v)
    self.Enabled = v
    if v then
        self:Start()
    else
        self:Stop()
    end
end

function FastAttackModule:SetRange(r)
    self.Range = r
end

function FastAttackModule:SetAttackMobs(v)
    self.AttackMobs = v
end

function FastAttackModule:SetAttackPlayers(v)
    self.AttackPlrs = v
end

return FastAttackModule
