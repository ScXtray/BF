-- ============================================================
--   XTRAY SCRIPT - ESP Module (Blox Fruits)
--   Draws boxes, names, health bars, and tracers for
--   Enemies, Players, and Devil Fruits.
-- ============================================================

local ESP = {}

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

ESP.Enabled       = false
ESP.ShowEnemies   = true
ESP.ShowPlayers   = true
ESP.ShowFruits    = true
ESP.ShowHealth    = true
ESP.ShowName      = true
ESP.ShowDistance  = true
ESP.ShowTracers   = false
ESP.MaxDistance   = 1000
ESP.EnemyColor    = Color3.fromRGB(255, 80, 80)
ESP.PlayerColor   = Color3.fromRGB(80, 180, 255)
ESP.FruitColor    = Color3.fromRGB(255, 215, 0)

local Drawings    = {}
local Connection  = nil

local DrawingAvailable = (typeof(Drawing) ~= "nil" and pcall(function() Drawing.new("Circle"):Remove() end))

local function newDrawing(type, props)
    if not DrawingAvailable then return {} end
    local ok, d = pcall(Drawing.new, type)
    if not ok then return {} end
    for k, v in pairs(props) do
        pcall(function() d[k] = v end)
    end
    return d
end

local function removeDrawing(key)
    if Drawings[key] then
        for _, d in pairs(Drawings[key]) do
            pcall(function() d:Remove() end)
        end
        Drawings[key] = nil
    end
end

local function removeAll()
    for key in pairs(Drawings) do
        removeDrawing(key)
    end
end

local function getScreenPos(pos)
    local camera = workspace.CurrentCamera
    if not camera then return nil, false end
    local screen, onScreen = camera:WorldToViewportPoint(pos)
    return Vector2.new(screen.X, screen.Y), onScreen, screen.Z
end

local function getCharBounds(model)
    local root = model:FindFirstChild("HumanoidRootPart")
    if not root then return nil end
    local pos = root.Position
    local camera = workspace.CurrentCamera
    if not camera then return nil end

    local tops    = {pos + Vector3.new( 2.5, 3.5,  2.5), pos + Vector3.new(-2.5, 3.5,  2.5),
                     pos + Vector3.new( 2.5, 3.5, -2.5), pos + Vector3.new(-2.5, 3.5, -2.5)}
    local bottoms = {pos + Vector3.new( 2.5, -3,  2.5), pos + Vector3.new(-2.5, -3,  2.5),
                     pos + Vector3.new( 2.5, -3, -2.5), pos + Vector3.new(-2.5, -3, -2.5)}

    local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge

    for _, p in ipairs(tops) do
        local s = camera:WorldToViewportPoint(p)
        minX = math.min(minX, s.X); minY = math.min(minY, s.Y)
        maxX = math.max(maxX, s.X); maxY = math.max(maxY, s.Y)
    end
    for _, p in ipairs(bottoms) do
        local s = camera:WorldToViewportPoint(p)
        minX = math.min(minX, s.X); minY = math.min(minY, s.Y)
        maxX = math.max(maxX, s.X); maxY = math.max(maxY, s.Y)
    end

    local onScreen = camera:WorldToViewportPoint(pos)
    if onScreen.Z < 0 then return nil end

    return {
        x = minX, y = minY,
        w = maxX - minX,
        h = maxY - minY,
        cx = (minX + maxX) / 2,
        cy = (minY + maxY) / 2,
    }, Vector2.new((minX + maxX) / 2, maxY)
end

local function drawEntity(key, model, color, label, healthPct)
    local root = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChildOfClass("BasePart")
    if not root then removeDrawing(key); return end

    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local dist = myRoot and (root.Position - myRoot.Position).Magnitude or 0

    if dist > ESP.MaxDistance then
        removeDrawing(key); return
    end

    local screenPos, onScreen = getScreenPos(root.Position)
    if not onScreen then removeDrawing(key); return end

    local bounds, bottomPos = getCharBounds(model)
    if not bounds then removeDrawing(key); return end

    if not Drawings[key] then
        Drawings[key] = {
            box   = newDrawing("Square", { Color = color, Thickness = 1.5, Filled = false, Transparency = 1, Visible = false }),
            name  = newDrawing("Text",   { Color = Color3.new(1,1,1), Size = 13, Center = true, Outline = true, OutlineColor = Color3.new(0,0,0), Visible = false }),
            dist  = newDrawing("Text",   { Color = Color3.fromRGB(200,200,200), Size = 11, Center = true, Outline = true, OutlineColor = Color3.new(0,0,0), Visible = false }),
            hbBg  = newDrawing("Square", { Color = Color3.new(0,0,0), Thickness = 1, Filled = true, Transparency = 0.6, Visible = false }),
            hbFg  = newDrawing("Square", { Color = Color3.fromRGB(80,255,80), Thickness = 1, Filled = true, Transparency = 1, Visible = false }),
            tracer= newDrawing("Line",   { Color = color, Thickness = 1, Transparency = 0.7, Visible = false }),
        }
    end

    local d = Drawings[key]

    d.box.Position    = Vector2.new(bounds.x, bounds.y)
    d.box.Size        = Vector2.new(bounds.w, bounds.h)
    d.box.Color       = color
    d.box.Visible     = true

    if ESP.ShowName then
        d.name.Text     = label
        d.name.Position = Vector2.new(bounds.cx, bounds.y - 15)
        d.name.Visible  = true
    else
        d.name.Visible = false
    end

    if ESP.ShowDistance then
        d.dist.Text     = string.format("%.0fm", dist)
        d.dist.Position = Vector2.new(bounds.cx, bounds.y + bounds.h + 2)
        d.dist.Visible  = true
    else
        d.dist.Visible = false
    end

    if ESP.ShowHealth and healthPct then
        local barH = bounds.h * math.clamp(healthPct, 0, 1)
        local bx   = bounds.x - 6
        d.hbBg.Position = Vector2.new(bx, bounds.y)
        d.hbBg.Size     = Vector2.new(4, bounds.h)
        d.hbBg.Visible  = true

        local hpColor = Color3.fromRGB(math.floor((1 - healthPct) * 255), math.floor(healthPct * 255), 50)
        d.hbFg.Position = Vector2.new(bx, bounds.y + bounds.h - barH)
        d.hbFg.Size     = Vector2.new(4, barH)
        d.hbFg.Color    = hpColor
        d.hbFg.Visible  = true
    else
        d.hbBg.Visible = false
        d.hbFg.Visible = false
    end

    if ESP.ShowTracers then
        local cam    = workspace.CurrentCamera
        local vp     = cam and cam.ViewportSize or Vector2.new(1280, 720)
        d.tracer.From    = Vector2.new(vp.X / 2, vp.Y)
        d.tracer.To      = bottomPos or screenPos
        d.tracer.Color   = color
        d.tracer.Visible = true
    else
        d.tracer.Visible = false
    end
end

local function getHealthPct(model)
    local hum = model:FindFirstChildOfClass("Humanoid")
    if hum and hum.MaxHealth > 0 then
        return hum.Health / hum.MaxHealth
    end
    local h = model:FindFirstChild("Health")
    if h and h.MaxValue and h.MaxValue > 0 then
        return h.Value / h.MaxValue
    end
    return nil
end

local function runESP()
    -- Enemies
    local Enemies = workspace:FindFirstChild("Enemies")
    local seenKeys = {}

    if ESP.ShowEnemies and Enemies then
        for _, enemy in ipairs(Enemies:GetChildren()) do
            local hum = enemy:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                local key = "enemy_" .. enemy:GetDebugId()
                seenKeys[key] = true
                local hp = getHealthPct(enemy)
                drawEntity(key, enemy, ESP.EnemyColor, enemy.Name, hp)
            end
        end
    end

    -- Players
    if ESP.ShowPlayers then
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                local hum = plr.Character:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    local key = "player_" .. plr.UserId
                    seenKeys[key] = true
                    local hp = getHealthPct(plr.Character)
                    drawEntity(key, plr.Character, ESP.PlayerColor, plr.Name, hp)
                end
            end
        end
    end

    -- Devil Fruits
    if ESP.ShowFruits then
        local fruits = workspace:FindFirstChild("Fruits") or workspace:FindFirstChild("DroppedFruits")
        if fruits then
            for _, fruit in ipairs(fruits:GetChildren()) do
                local key = "fruit_" .. fruit:GetDebugId()
                seenKeys[key] = true
                local part = fruit.PrimaryPart or fruit:FindFirstChildOfClass("BasePart")
                if part then
                    local sp, on = getScreenPos(part.Position)
                    if on then
                        if not Drawings[key] then
                            Drawings[key] = {
                                label = newDrawing("Text", { Color = ESP.FruitColor, Size = 14, Center = true, Outline = true, OutlineColor = Color3.new(0,0,0), Visible = false }),
                                tracer = newDrawing("Line", { Color = ESP.FruitColor, Thickness = 1.5, Transparency = 0.8, Visible = false }),
                            }
                        end
                        local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                        local dist = myRoot and (part.Position - myRoot.Position).Magnitude or 0
                        Drawings[key].label.Text     = string.format("[BUAH] %s (%.0fm)", fruit.Name, dist)
                        Drawings[key].label.Position = sp
                        Drawings[key].label.Visible  = true

                        if ESP.ShowTracers then
                            local cam = workspace.CurrentCamera
                            local vp  = cam and cam.ViewportSize or Vector2.new(1280, 720)
                            Drawings[key].tracer.From    = Vector2.new(vp.X / 2, vp.Y)
                            Drawings[key].tracer.To      = sp
                            Drawings[key].tracer.Visible = true
                        else
                            Drawings[key].tracer.Visible = false
                        end
                    else
                        removeDrawing(key)
                    end
                end
                seenKeys[key] = true
            end
        end
    end

    -- Hapus drawing yang entity-nya sudah hilang
    for key in pairs(Drawings) do
        if not seenKeys[key] then
            removeDrawing(key)
        end
    end
end

function ESP:Start()
    if Connection then return end
    if not DrawingAvailable then return end
    Connection = RunService.RenderStepped:Connect(function()
        if not self.Enabled then return end
        pcall(runESP)
    end)
end

function ESP:Toggle(v)
    self.Enabled = v
    if v then
        self:Start()
    else
        removeAll()
    end
end

function ESP:Stop()
    if Connection then
        Connection:Disconnect()
        Connection = nil
    end
    removeAll()
end

return ESP
