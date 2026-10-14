-- language: Lua, target: Roblox client (executor required), mobile-friendly
-- MEI HUB — Steal An Egg
-- style: Big Froot (dark green accents, pill toggles)
-- key: local HWID derive + master bypass

local Players   = game:GetService("Players")
local RunService= game:GetService("RunService")
local UIS       = game:GetService("UserInputService")
local Tween     = game:GetService("TweenService")
local LP        = Players.LocalPlayer
if not LP then
    Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
    LP = Players.LocalPlayer
end


-- ============================================================
-- KEY SYSTEM
-- ============================================================
local KEY_SALT   = "MEI_HUB_EGG_v1"
local MASTER_KEY = "MEI"

local function deriveKey(uid)
    local s = tostring(uid) .. KEY_SALT
    local h = 5381
    for i = 1, #s do
        h = (h * 33 + s:byte(i)) % 0xFFFFFFFF
    end
    return string.format("MEI-%08X", h)
end

local validKey = deriveKey(LP.UserId)
print("[MEI HUB] expected key:", validKey)

local function normalize(s)
    if not s then return "" end
    s = s:gsub("%s", ""):gsub("[^%w%-]", ""):upper()
    return s
end

local VALID_NORM  = normalize(validKey)
local MASTER_NORM = normalize(MASTER_KEY)

local function keyOk(input)
    local n = normalize(input)
    return n == VALID_NORM or n == MASTER_NORM
end

-- ============================================================
-- KEY GUI
-- ============================================================
local keyGui = Instance.new("ScreenGui")
keyGui.Name = "MEIKeyGate"
keyGui.ResetOnSpawn = false
keyGui.IgnoreGuiInset = true
keyGui.Parent = LP:WaitForChild("PlayerGui")

local kFrame = Instance.new("Frame")
kFrame.Size = UDim2.new(0, 300, 0, 230)
kFrame.Position = UDim2.new(0.5, -150, 0.5, -115)
kFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
kFrame.BorderSizePixel = 0
kFrame.Active = true
kFrame.Draggable = true
kFrame.Parent = keyGui
Instance.new("UICorner", kFrame).CornerRadius = UDim.new(0, 14)

local kStroke = Instance.new("UIStroke")
kStroke.Color = Color3.fromRGB(90, 180, 90)
kStroke.Thickness = 1.4
kStroke.Transparency = 0.3
kStroke.Parent = kFrame

local kHeader = Instance.new("Frame")
kHeader.Size = UDim2.new(1, 0, 0, 48)
kHeader.BackgroundColor3 = Color3.fromRGB(20, 26, 20)
kHeader.BorderSizePixel = 0
kHeader.Parent = kFrame
Instance.new("UICorner", kHeader).CornerRadius = UDim.new(0, 14)

local kHeaderFix = Instance.new("Frame")
kHeaderFix.Size = UDim2.new(1, 0, 0, 22)
kHeaderFix.Position = UDim2.new(0, 0, 1, -22)
kHeaderFix.BackgroundColor3 = Color3.fromRGB(20, 26, 20)
kHeaderFix.BorderSizePixel = 0
kHeaderFix.Parent = kHeader

local kTitle = Instance.new("TextLabel")
kTitle.Size = UDim2.new(1, -20, 1, 0)
kTitle.Position = UDim2.new(0, 14, 0, 0)
kTitle.BackgroundTransparency = 1
kTitle.Text = "🍏  MEI HUB  —  KEY"
kTitle.TextColor3 = Color3.fromRGB(160, 230, 160)
kTitle.TextScaled = true
kTitle.Font = Enum.Font.GothamBold
kTitle.TextXAlignment = Enum.TextXAlignment.Left
kTitle.Parent = kHeader

local kDot = Instance.new("Frame")
kDot.Size = UDim2.new(0, 8, 0, 8)
kDot.Position = UDim2.new(1, -22, 0.5, -4)
kDot.BackgroundColor3 = Color3.fromRGB(120, 200, 120)
kDot.BorderSizePixel = 0
kDot.Parent = kHeader
Instance.new("UICorner", kDot).CornerRadius = UDim.new(1, 0)

local kBox = Instance.new("TextBox")
kBox.Size = UDim2.new(1, -20, 0, 42)
kBox.Position = UDim2.new(0, 10, 0, 62)
kBox.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
kBox.TextColor3 = Color3.fromRGB(220, 220, 235)
kBox.PlaceholderText = "MEI-XXXXXXXX  or  MEI"
kBox.Text = ""
kBox.TextScaled = true
kBox.Font = Enum.Font.Code
kBox.BorderSizePixel = 0
kBox.ClearTextOnFocus = false
kBox.Parent = kFrame
Instance.new("UICorner", kBox).CornerRadius = UDim.new(0, 8)

local function keyBtn(text, color, x, y, w)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, w, 0, 40)
    b.Position = UDim2.new(0, x, 0, y)
    b.BackgroundColor3 = color
    b.TextColor3 = Color3.fromRGB(230, 240, 230)
    b.Text = text
    b.TextScaled = true
    b.Font = Enum.Font.GothamBold
    b.BorderSizePixel = 0
    b.Parent = kFrame
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
    return b
end

local getKeyBtn = keyBtn("GET KEY", Color3.fromRGB(40, 70, 45), 10, 116, 135)
local verifyBtn = keyBtn("VERIFY",  Color3.fromRGB(80, 170, 80), 155, 116, 135)

local kStatus = Instance.new("TextLabel")
kStatus.Size = UDim2.new(1, -20, 0, 42)
kStatus.Position = UDim2.new(0, 10, 0, 168)
kStatus.BackgroundTransparency = 1
kStatus.Text = "GET KEY fills the box — or type MEI"
kStatus.TextColor3 = Color3.fromRGB(150, 150, 165)
kStatus.TextScaled = true
kStatus.TextWrapped = true
kStatus.Font = Enum.Font.Gotham
kStatus.Parent = kFrame

getKeyBtn.MouseButton1Click:Connect(function()
    kBox.Text = validKey
    local copied = false
    if setclipboard then copied = pcall(setclipboard, validKey) end
    kStatus.Text = validKey .. (copied and "  (copied)" or "  (copy manually)")
    kStatus.TextColor3 = Color3.fromRGB(140, 220, 140)
end)

-- ============================================================
-- MAIN HUB (loads after key)
-- ============================================================
local function loadHub()

    kFrame.Visible = false
    task.wait(0.2)
    keyGui:Destroy()

    local State = {
        autoSteal   = false,
        eggESP      = false,
        autoCollect = false,
        autoSell    = false,
        antiAFK     = false,
        fly         = false,
        speed       = 50,
        status      = "ready",
    }

    local char = LP.Character or LP.CharacterAdded:Wait()
    local hrp  = char:WaitForChild("HumanoidRootPart")
    local hum  = char:WaitForChild("Humanoid")

    LP.CharacterAdded:Connect(function(c)
        char = c
        hrp  = c:WaitForChild("HumanoidRootPart")
        hum  = c:WaitForChild("Humanoid")
    end)

    -- NOTIFY
    local notifGui = Instance.new("ScreenGui")
    notifGui.Name = "MEINotify"
    notifGui.ResetOnSpawn = false
    notifGui.IgnoreGuiInset = true
    notifGui.Parent = LP:WaitForChild("PlayerGui")

    local function notify(text, color)
        color = color or Color3.fromRGB(140, 220, 140)
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(0, 240, 0, 36)
        lbl.Position = UDim2.new(1, -260, 0, 20)
        lbl.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
        lbl.TextColor3 = color
        lbl.Text = text
        lbl.TextScaled = true
        lbl.Font = Enum.Font.Gotham
        lbl.BorderSizePixel = 0
        lbl.BackgroundTransparency = 0.1
        lbl.Parent = notifGui
        Instance.new("UICorner", lbl).CornerRadius = UDim.new(0, 8)
        local st = Instance.new("UIStroke")
        st.Color = color
        st.Thickness = 1
        st.Transparency = 0.5
        st.Parent = lbl
        task.delay(2.5, function()
            Tween:Create(lbl, TweenInfo.new(0.3), {
                BackgroundTransparency = 1, TextTransparency = 1,
                UIStroke = nil,
            }):Play()
            task.wait(0.35)
            lbl:Destroy()
        end)
    end

    -- GUI
    local gui = Instance.new("ScreenGui")
    gui.Name = "MEIHubUI"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.Parent = LP:WaitForChild("PlayerGui")

    local main = Instance.new("Frame")
    main.Size = UDim2.new(0, 240, 0, 420)
    main.Position = UDim2.new(0, 20, 0, 80)
    main.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    main.BorderSizePixel = 0
    main.Active = true
    main.Draggable = true
    main.Parent = gui
    Instance.new("UICorner", main).CornerRadius = UDim.new(0, 14)

    local mStroke = Instance.new("UIStroke")
    mStroke.Color = Color3.fromRGB(90, 180, 90)
    mStroke.Thickness = 1.4
    mStroke.Transparency = 0.3
    mStroke.Parent = main

    -- header (nameplate)
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 44)
    header.BackgroundColor3 = Color3.fromRGB(20, 26, 20)
    header.BorderSizePixel = 0
    header.Parent = main
    Instance.new("UICorner", header).CornerRadius = UDim.new(0, 14)

    local headerFix = Instance.new("Frame")
    headerFix.Size = UDim2.new(1, 0, 0, 20)
    headerFix.Position = UDim2.new(0, 0, 1, -20)
    headerFix.BackgroundColor3 = Color3.fromRGB(20, 26, 20)
    headerFix.BorderSizePixel = 0
    headerFix.Parent = header

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -20, 1, 0)
    title.Position = UDim2.new(0, 14, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "🍏  MEI HUB"
    title.TextColor3 = Color3.fromRGB(160, 230, 160)
    title.TextScaled = true
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header

    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 8, 0, 8)
    dot.Position = UDim2.new(1, -22, 0.5, -4)
    dot.BackgroundColor3 = Color3.fromRGB(120, 200, 120)
    dot.BorderSizePixel = 0
    dot.Parent = header
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

    -- widgets
    local function makeSection(text, y)
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -20, 0, 22)
        lbl.Position = UDim2.new(0, 10, 0, y)
        lbl.BackgroundTransparency = 1
        lbl.Text = text:upper()
        lbl.TextColor3 = Color3.fromRGB(120, 130, 120)
        lbl.TextScaled = true
        lbl.Font = Enum.Font.GothamBold
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = main
    end

    local function makeToggle(text, y, key, onToggle)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -20, 0, 36)
        row.Position = UDim2.new(0, 10, 0, y)
        row.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
        row.BorderSizePixel = 0
        row.Parent = main
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(0.7, 0, 1, 0)
        lbl.Position = UDim2.new(0, 12, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = text
        lbl.TextColor3 = Color3.fromRGB(210, 210, 220)
        lbl.TextScaled = true
        lbl.Font = Enum.Font.Gotham
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = row

        local track = Instance.new("Frame")
        track.Size = UDim2.new(0, 40, 0, 20)
        track.Position = UDim2.new(1, -50, 0.5, -10)
        track.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
        track.BorderSizePixel = 0
        track.Parent = row
        Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, 16, 0, 16)
        knob.Position = UDim2.new(0, 2, 0.5, -8)
        knob.BackgroundColor3 = Color3.fromRGB(180, 180, 190)
        knob.BorderSizePixel = 0
        knob.Parent = track
        Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 1, 0)
        btn.BackgroundTransparency = 1
        btn.Text = ""
        btn.Parent = row

        local on = State[key] or false
        local function render()
            Tween:Create(knob, TweenInfo.new(0.15), {
                Position = on and UDim2.new(1, -18, 0.5, -8)
                    or UDim2.new(0, 2, 0.5, -8)
            }):Play()
            track.BackgroundColor3 = on and Color3.fromRGB(80, 170, 80)
                or Color3.fromRGB(40, 40, 50)
            knob.BackgroundColor3 = on and Color3.fromRGB(230, 250, 230)
                or Color3.fromRGB(180, 180, 190)
        end
        render()
        btn.MouseButton1Click:Connect(function()
            on = not on
            State[key] = on
            render()
            if onToggle then onToggle(on) end
        end)
    end

    local function makeButton(text, y, color, onClick)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(1, -20, 0, 34)
        b.Position = UDim2.new(0, 10, 0, y)
        b.BackgroundColor3 = color or Color3.fromRGB(40, 70, 45)
        b.TextColor3 = Color3.fromRGB(230, 240, 230)
        b.Text = text
        b.TextScaled = true
        b.Font = Enum.Font.Gotham
        b.BorderSizePixel = 0
        b.Parent = main
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
        b.MouseButton1Click:Connect(onClick)
    end

    -- EGG SCAN
    local function isEgg(obj)
        if not obj then return false end
        if not obj:IsA("BasePart") and not obj:IsA("Model") then return false end
        return obj.Name:lower():find("egg") ~= nil
    end

    local function getEggs()
        local list = {}
        for _, obj in ipairs(workspace:GetDescendants()) do
            if isEgg(obj) then
                local part = obj:IsA("BasePart") and obj
                    or obj:FindFirstChildWhichIsA("BasePart")
                if part then table.insert(list, {obj = obj, part = part}) end
            end
        end
        return list
    end

    local function nearestEgg()
        local best, bestD
        for _, e in ipairs(getEggs()) do
            local d = (e.part.Position - hrp.Position).Magnitude
            if not bestD or d < bestD then best, bestD = e, d end
        end
        return best
    end

    local function interact(egg)
        if not egg then return false end
        local prompt = egg.obj:FindFirstChildWhichIsA("ProximityPrompt", true)
        if prompt and fireproximityprompt then
            pcall(function() prompt.HoldDuration = 0; fireproximityprompt(prompt) end)
            return true
        end
        local cd = egg.obj:FindFirstChildWhichIsA("ClickDetector", true)
        if cd and fireclickdetector then
            pcall(fireclickdetector, cd)
            return true
        end
        if firetouchinterest then
            pcall(function()
                firetouchinterest(hrp, egg.part, 0)
                task.wait(0.04)
                firetouchinterest(hrp, egg.part, 1)
            end)
            return true
        end
        return false
    end

    -- ESP
    local espFolder = Instance.new("Folder")
    espFolder.Name = "MEIESP"
    espFolder.Parent = gui
    local espCache = {}
    local function clearESP()
        for _, h in ipairs(espCache) do if h.Parent then h:Destroy() end end
        espCache = {}
    end
    local function buildESP()
        clearESP()
        for _, e in ipairs(getEggs()) do
            if e.part then
                local hl = Instance.new("Highlight")
                hl.FillColor = Color3.fromRGB(140, 230, 140)
                hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                hl.FillTransparency = 0.55
                hl.OutlineTransparency = 0.2
                hl.Adornee = e.part
                hl.Parent = espFolder
                table.insert(espCache, hl)
            end
        end
    end

    -- FLY
    local flyVel, flyGyro, flyAtt
    local function startFly()
        if flyVel then return end
        flyAtt = Instance.new("Attachment", hrp)
        flyVel = Instance.new("LinearVelocity")
        flyVel.Attachment0 = flyAtt
        flyVel.MaxForce = math.huge
        flyVel.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
        flyVel.Parent = hrp
        flyGyro = Instance.new("AlignOrientation")
        flyGyro.Attachment0 = flyAtt
        flyGyro.Mode = Enum.OrientationAlignmentMode.OneAttachment
        flyGyro.MaxTorque = math.huge
        flyGyro.Responsiveness = 200
        flyGyro.Parent = hrp
        hum.PlatformStand = true
    end
    local function stopFly()
        if flyVel then flyVel:Destroy() flyVel = nil end
        if flyGyro then flyGyro:Destroy() flyGyro = nil end
        if flyAtt then flyAtt:Destroy() flyAtt = nil end
        if hum then hum.PlatformStand = false end
    end

    -- ANTI-AFK
    local vu = game:GetService("VirtualUser")
    LP.Idled:Connect(function()
        if State.antiAFK then
            vu:CaptureController()
            vu:ClickButton2(Vector2.new())
        end
    end)

    -- LAYOUT
    local y = 54
    makeSection("Steal", y)                          y = y + 26
    makeToggle("Auto Steal", y, "autoSteal")         y = y + 40
    makeToggle("Auto Collect", y, "autoCollect")     y = y + 40
    makeToggle("Auto Sell", y, "autoSell")           y = y + 44

    makeSection("Visuals", y)                        y = y + 26
    makeToggle("Egg ESP", y, "eggESP", function(on)
        if on then buildESP() else clearESP() end
    end)                                              y = y + 40

    makeSection("Movement", y)                       y = y + 26
    makeToggle("Fly", y, "fly", function(on)
        if on then startFly() else stopFly() end
    end)                                              y = y + 40
    makeToggle("Anti-AFK", y, "antiAFK")             y = y + 44

    makeSection("Utility", y)                        y = y + 26
    makeButton("TP To Nearest Egg", y, Color3.fromRGB(45, 80, 120), function()
        local e = nearestEgg()
        if e then
            hrp.CFrame = CFrame.new(e.part.Position + Vector3.new(0, 4, 0))
            notify("tp'd: " .. e.obj.Name)
        else
            notify("no egg found", Color3.fromRGB(220, 140, 100))
        end
    end)                                              y = y + 40

    local spdLabel = Instance.new("TextLabel")
    spdLabel.Size = UDim2.new(1, -20, 0, 18)
    spdLabel.Position = UDim2.new(0, 10, 0, y)
    spdLabel.BackgroundTransparency = 1
    spdLabel.Text = "Speed: 50"
    spdLabel.TextColor3 = Color3.fromRGB(200, 200, 210)
    spdLabel.TextScaled = true
    spdLabel.Font = Enum.Font.Gotham
    spdLabel.TextXAlignment = Enum.TextXAlignment.Left
    spdLabel.Parent = main
    y = y + 22

    local slider = Instance.new("Frame")
    slider.Size = UDim2.new(1, -20, 0, 22)
    slider.Position = UDim2.new(0, 10, 0, y)
    slider.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    slider.BorderSizePixel = 0
    slider.Parent = main
    Instance.new("UICorner", slider).CornerRadius = UDim.new(0, 6)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(0.25, 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(90, 180, 90)
    fill.BorderSizePixel = 0
    fill.Parent = slider
    Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 6)

    local dragging = false
    slider.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then dragging = true end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)
    UIS.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement
        or i.UserInputType == Enum.UserInputType.Touch) then
            local rel = math.clamp(
                (i.Position.X - slider.AbsolutePosition.X) / slider.AbsoluteSize.X, 0, 1)
            fill.Size = UDim2.new(rel, 0, 1, 0)
            State.speed = math.floor(rel * 195 + 5)
            spdLabel.Text = "Speed: " .. State.speed
        end
    end)

    y = y + 30

    local statusLbl = Instance.new("TextLabel")
    statusLbl.Size = UDim2.new(1, -20, 0, 20)
    statusLbl.Position = UDim2.new(0, 10, 0, y)
    statusLbl.BackgroundTransparency = 1
    statusLbl.Text = "mei hub ready"
    statusLbl.TextColor3 = Color3.fromRGB(140, 200, 140)
    statusLbl.TextScaled = true
    statusLbl.Font = Enum.Font.Gotham
    statusLbl.TextXAlignment = Enum.TextXAlignment.Center
    statusLbl.Parent = main

    main.Size = UDim2.new(0, 240, 0, y + 34)

    -- MAIN LOOP
    local lastSteal, lastSell, lastESP = 0, 0, 0
    RunService.Heartbeat:Connect(function(dt)
        local now = tick()

        if hum and not State.fly then hum.WalkSpeed = State.speed end

        if State.fly and flyVel then
            local cam = workspace.CurrentCamera
            local move = Vector3.new()
            local look, right = cam.CFrame.LookVector, cam.CFrame.RightVector
            if UIS:IsKeyDown(Enum.KeyCode.W) then move += look end
            if UIS:IsKeyDown(Enum.KeyCode.S) then move -= look end
            if UIS:IsKeyDown(Enum.KeyCode.A) then move -= right end
            if UIS:IsKeyDown(Enum.KeyCode.D) then move += right end
            if UIS:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.new(0,1,0) end
            if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then move -= Vector3.new(0,1,0) end
            if move.Magnitude > 0 then move = move.Unit end
            flyVel.VectorVelocity = move * State.speed
            flyGyro.CFrame = cam.CFrame
        end

        if State.autoSteal and now - lastSteal > 0.35 then
            lastSteal = now
            local e = nearestEgg()
            if e then
                local d = (e.part.Position - hrp.Position).Magnitude
                if d > 8 then
                    hrp.CFrame = CFrame.new(e.part.Position + Vector3.new(0, 4, 0))
                end
                interact(e)
                statusLbl.Text = "stealing: " .. e.obj.Name
            else
                statusLbl.Text = "scanning for eggs..."
            end
        end

        if State.autoCollect and now - lastSteal > 0.2 then
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("BasePart")
                and not obj:IsDescendantOf(char)
                and (obj.Position - hrp.Position).Magnitude < 10
                and firetouchinterest then
                    pcall(function()
                        firetouchinterest(hrp, obj, 0)
                        task.wait()
                        firetouchinterest(hrp, obj, 1)
                    end)
                end
            end
        end

        if State.eggESP and now - lastESP > 2 then
            lastESP = now
            buildESP()
        end

        if State.autoSell and now - lastSell > 3 then
            lastSell = now
            local remotes = game:GetService("ReplicatedStorage"):GetDescendants()
            for _, r in ipairs(remotes) do
                if (r:IsA("RemoteEvent") or r:IsA("RemoteFunction"))
                and r.Name:lower():find("sell") then
                    pcall(function()
                        if r:IsA("RemoteEvent") then r:FireServer()
                        else r:InvokeServer() end
                    end)
                end
            end
        end
    end)

    notify("MEI HUB loaded")
end

-- ============================================================
-- VERIFY
-- ============================================================
verifyBtn.MouseButton1Click:Connect(function()
    if keyOk(kBox.Text) then
        kStatus.Text = "key valid — loading"
        kStatus.TextColor3 = Color3.fromRGB(140, 220, 140)
        task.wait(0.4)
        local ok, err = pcall(loadHub)
        if not ok then
            warn("[MEI HUB]", err)
            kStatus.Text = "load error: " .. tostring(err)
            kStatus.TextColor3 = Color3.fromRGB(220, 100, 100)
            kFrame.Visible = true
        end
    else
        kStatus.Text = "invalid — expected: " .. validKey
        kStatus.TextColor3 = Color3.fromRGB(220, 100, 100)
        local ox = kFrame.Position
        for i = 1, 6 do
            kFrame.Position = ox + UDim2.new(0, (i % 2 == 0 and 6 or -6), 0, 0)
            task.wait(0.03)
        end
        kFrame.Position = ox
    end
end)
