-- ================================================================
--  YANG KAI HUB  |  v3.0 Professional
--  Entity-based physics (LinearVelocity constraint)
--  Anti-detection: randomised names, pcall guards, no flagged APIs
-- ================================================================

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local cfg = {
    flySpeed   = 65,
    walkSpeed  = 16,
    jumpHeight = 7.2,
}

local state = {
    fly     = false,
    noclip  = false,
    dragging = false,
    minimized = false,
    dragStart = nil,
    startPos  = nil,
}

local flyEntity = { lv = nil, att = nil }
local flyConn    = nil
local noclipConn = nil

local function rname()
    local s = ""
    for _ = 1, 8 do
        s = s .. string.char(math.random(97, 122))
    end
    return s
end

local function safe(fn, ...)
    local ok, err = pcall(fn, ...)
    if not ok then end
end

local function getChar()  return player.Character end
local function getHum()   local c = getChar(); return c and c:FindFirstChildOfClass("Humanoid") end
local function getRoot()  local c = getChar(); return c and c:FindFirstChild("HumanoidRootPart") end

local function destroyFlyEntity()
    safe(function()
        if flyEntity.lv  and flyEntity.lv.Parent  then flyEntity.lv:Destroy()  end
        if flyEntity.att and flyEntity.att.Parent then flyEntity.att:Destroy() end
    end)
    flyEntity.lv  = nil
    flyEntity.att = nil
end

local function buildFlyEntity()
    destroyFlyEntity()
    local root = getRoot()
    if not root then return false end

    local att = Instance.new("Attachment")
    att.Name   = rname()
    att.Parent = root

    local lv = Instance.new("LinearVelocity")
    lv.Name                   = rname()
    lv.Attachment0             = att
    lv.MaxForce               = 1e6
    lv.RelativeTo             = Enum.ActuatorRelativeTo.World
    lv.VelocityConstraintMode  = Enum.VelocityConstraintMode.Vector
    lv.VectorVelocity          = Vector3.zero
    lv.Parent                  = root

    flyEntity.lv  = lv
    flyEntity.att = att
    return true
end

local function enableNoclip()
    if noclipConn then return end
    noclipConn = RunService.Stepped:Connect(function()
        safe(function()
            local char = getChar()
            if not char then return end
            for _, v in ipairs(char:GetDescendants()) do
                if v:IsA("BasePart") then
                    v.CanCollide = false
                end
            end
        end)
    end)
end

local function disableNoclip()
    if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
    safe(function()
        local char = getChar()
        if not char then return end
        for _, v in ipairs(char:GetDescendants()) do
            if v:IsA("BasePart") then v.CanCollide = true end
        end
    end)
end

local function startFly()
    if flyConn then return end
    if not buildFlyEntity() then return end

    safe(function()
        local hum = getHum()
        if hum then hum.PlatformStand = true end
    end)

    flyConn = RunService.RenderStepped:Connect(function()
        safe(function()
            local hum  = getHum()
            local root = getRoot()
            local lv   = flyEntity.lv
            if not (hum and root and lv and lv.Parent) then return end

            hum.PlatformStand = true

            local moveDir = hum.MoveDirection
            local cf      = camera.CFrame
            local direction = (cf.RightVector * moveDir.X) + (cf.LookVector * moveDir.Z)

            if direction.Magnitude > 0 then
                lv.VectorVelocity = direction.Unit * cfg.flySpeed
            else
                lv.VectorVelocity = Vector3.zero
            end
        end)
    end)
end

local function stopFly()
    if flyConn then flyConn:Disconnect(); flyConn = nil end
    safe(function()
        if flyEntity.lv and flyEntity.lv.Parent then
            flyEntity.lv.VectorVelocity = Vector3.zero
        end
        local hum = getHum()
        if hum then hum.PlatformStand = false end
    end)
    destroyFlyEntity()
    if not state.noclip then disableNoclip() end
end

local function applyWalkSpeed()
    safe(function()
        local hum = getHum()
        if hum then hum.WalkSpeed = cfg.walkSpeed end
    end)
end

local function applyJumpHeight()
    safe(function()
        local hum = getHum()
        if hum then hum.JumpHeight = cfg.jumpHeight end
    end)
end

local function onCharacterAdded(char)
    char:WaitForChild("HumanoidRootPart", 10)
    char:WaitForChild("Humanoid", 10)
    task.wait(0.5)
    applyWalkSpeed()
    applyJumpHeight()
    if state.noclip then enableNoclip() end
    if state.fly then
        destroyFlyEntity()
        startFly()
    end
end

player.CharacterAdded:Connect(onCharacterAdded)
if player.Character then onCharacterAdded(player.Character) end

-- ================================================================
--  GUI
-- ================================================================

local FRAME_W      = 310
local FRAME_H_FULL = 460
local FRAME_H_MIN  = 46
local PAD          = 10

local gui = Instance.new("ScreenGui")
gui.Name           = rname()
gui.ResetOnSpawn   = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent         = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Name            = rname()
frame.Size            = UDim2.new(0, FRAME_W, 0, FRAME_H_FULL)
frame.Position        = UDim2.new(0, 24, 0.12, 0)
frame.BackgroundColor3 = Color3.fromRGB(14, 14, 14)
frame.BorderSizePixel = 0
frame.Parent          = gui
do Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12) end

do
    local s = Instance.new("UIStroke", frame)
    s.Color     = Color3.fromRGB(200, 50, 50)
    s.Thickness = 1.2
    s.Transparency = 0.5
end

local titleBar = Instance.new("Frame")
titleBar.Size            = UDim2.new(1, 0, 0, 46)
titleBar.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
titleBar.BorderSizePixel = 0
titleBar.Parent          = frame
do Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 12) end

local accent = Instance.new("Frame")
accent.Size            = UDim2.new(1, 0, 0, 2)
accent.Position        = UDim2.new(0, 0, 1, -2)
accent.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
accent.BorderSizePixel = 0
accent.Parent          = titleBar

local titleLabel = Instance.new("TextLabel")
titleLabel.Size               = UDim2.new(1, -55, 1, 0)
titleLabel.Position           = UDim2.new(0, 14, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text               = "YANG KAI HUB  v3.0"
titleLabel.TextColor3         = Color3.fromRGB(240, 60, 60)
titleLabel.Font               = Enum.Font.GothamBold
titleLabel.TextSize           = 16
titleLabel.TextXAlignment     = Enum.TextXAlignment.Left
titleLabel.Parent             = titleBar

local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Size            = UDim2.new(0, 34, 0, 34)
minimizeBtn.Position        = UDim2.new(1, -40, 0, 6)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(150, 35, 35)
minimizeBtn.Text            = "—"
minimizeBtn.TextColor3      = Color3.new(1, 1, 1)
minimizeBtn.TextSize        = 16
minimizeBtn.Font            = Enum.Font.GothamBold
minimizeBtn.BorderSizePixel = 0
minimizeBtn.Parent          = titleBar
do Instance.new("UICorner", minimizeBtn).CornerRadius = UDim.new(0, 7) end

titleBar.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1
    or inp.UserInputType == Enum.UserInputType.Touch then
        state.dragging = true
        state.dragStart = inp.Position
        state.startPos  = frame.Position
    end
end)
UserInputService.InputChanged:Connect(function(inp)
    if state.dragging and (
        inp.UserInputType == Enum.UserInputType.MouseMovement or
        inp.UserInputType == Enum.UserInputType.Touch
    ) then
        local d = inp.Position - state.dragStart
        frame.Position = UDim2.new(
            state.startPos.X.Scale, state.startPos.X.Offset + d.X,
            state.startPos.Y.Scale, state.startPos.Y.Offset + d.Y
        )
    end
end)
UserInputService.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1
    or inp.UserInputType == Enum.UserInputType.Touch then
        state.dragging = false
    end
end)

local content = Instance.new("Frame")
content.Size               = UDim2.new(1, 0, 1, -46)
content.Position           = UDim2.new(0, 0, 0, 46)
content.BackgroundTransparency = 1
content.ClipsDescendants   = true
content.Parent             = frame

local notifLabel = Instance.new("TextLabel")
notifLabel.Size               = UDim2.new(1, -20, 0, 26)
notifLabel.Position           = UDim2.new(0, 10, 0, 6)
notifLabel.BackgroundColor3   = Color3.fromRGB(30, 30, 30)
notifLabel.TextColor3         = Color3.fromRGB(0, 215, 115)
notifLabel.Font               = Enum.Font.Gotham
notifLabel.TextSize            = 13
notifLabel.Text               = ""
notifLabel.BorderSizePixel    = 0
notifLabel.Transparency       = 1
notifLabel.Parent             = content
do Instance.new("UICorner", notifLabel).CornerRadius = UDim.new(0, 6) end

local notifThread = nil
local function notify(msg)
    if notifThread then task.cancel(notifThread) end
    notifLabel.Text = "  " .. msg
    notifLabel.BackgroundTransparency = 0
    notifLabel.TextTransparency = 0
    notifThread = task.delay(2.5, function()
        TweenService:Create(notifLabel,
            TweenInfo.new(0.4), { TextTransparency = 1, BackgroundTransparency = 1 }
        ):Play()
    end)
end

local statusBar = Instance.new("TextLabel")
statusBar.Size               = UDim2.new(1, -20, 0, 28)
statusBar.Position           = UDim2.new(0, 10, 0, 38)
statusBar.BackgroundColor3   = Color3.fromRGB(22, 22, 22)
statusBar.TextColor3         = Color3.fromRGB(0, 215, 115)
statusBar.Font               = Enum.Font.Gotham
statusBar.TextSize            = 13
statusBar.BorderSizePixel    = 0
statusBar.TextXAlignment     = Enum.TextXAlignment.Left
statusBar.Parent             = content
do Instance.new("UICorner", statusBar).CornerRadius = UDim.new(0, 6) end

local function updateStatus()
    statusBar.Text = string.format(
        "  Fly: %s   NoClip: %s   Speed: %d   Walk: %d   Jump: %.1f",
        state.fly    and "ON" or "OFF",
        state.noclip and "ON" or "OFF",
        cfg.flySpeed, cfg.walkSpeed, cfg.jumpHeight
    )
end

local function sectionLabel(text, yOff, parent)
    parent = parent or content
    local lbl = Instance.new("TextLabel")
    lbl.Size               = UDim2.new(1, -20, 0, 20)
    lbl.Position           = UDim2.new(0, 10, 0, yOff)
    lbl.BackgroundTransparency = 1
    lbl.Text               = text
    lbl.TextColor3         = Color3.fromRGB(120, 120, 120)
    lbl.Font               = Enum.Font.Gotham
    lbl.TextSize            = 12
    lbl.TextXAlignment     = Enum.TextXAlignment.Left
    lbl.Parent             = parent
    return lbl
end

local function makeToggle(text, yOff)
    local btn = Instance.new("TextButton")
    btn.Size            = UDim2.new(1, -20, 0, 40)
    btn.Position        = UDim2.new(0, 10, 0, yOff)
    btn.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
    btn.Text            = text .. ": OFF"
    btn.TextColor3      = Color3.fromRGB(200, 200, 200)
    btn.Font            = Enum.Font.GothamBold
    btn.TextSize        = 15
    btn.BorderSizePixel = 0
    btn.Parent          = content
    do Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8) end
    do
        local s = Instance.new("UIStroke", btn)
        s.Color     = Color3.fromRGB(60, 60, 60)
        s.Thickness = 1
    end

    local indicator = Instance.new("Frame")
    indicator.Size            = UDim2.new(0, 8, 0, 8)
    indicator.Position        = UDim2.new(1, -20, 0.5, -4)
    indicator.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    indicator.BorderSizePixel = 0
    indicator.Parent          = btn
    do Instance.new("UICorner", indicator).CornerRadius = UDim.new(1, 0) end

    local function setOn(on)
        local col = on and Color3.fromRGB(20, 170, 80) or Color3.fromRGB(38, 38, 38)
        TweenService:Create(btn, TweenInfo.new(0.18), { BackgroundColor3 = col }):Play()
        btn.Text = text .. (on and ": ON" or ": OFF")
        btn.TextColor3 = on and Color3.new(1,1,1) or Color3.fromRGB(200,200,200)
        indicator.BackgroundColor3 = on and Color3.fromRGB(0, 230, 100) or Color3.fromRGB(80, 80, 80)
    end

    return btn, setOn
end

local function makeSmallBtn(label, xOff, w, yOff, parent)
    parent = parent or content
    local b = Instance.new("TextButton")
    b.Size            = UDim2.new(0, w, 0, 34)
    b.Position        = UDim2.new(0, xOff, 0, yOff)
    b.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
    b.Text            = label
    b.TextColor3      = Color3.fromRGB(210, 210, 210)
    b.Font            = Enum.Font.GothamBold
    b.TextSize        = 14
    b.BorderSizePixel = 0
    b.Parent          = parent
    do Instance.new("UICorner", b).CornerRadius = UDim.new(0, 7) end
    do
        local s = Instance.new("UIStroke", b)
        s.Color     = Color3.fromRGB(60, 60, 60)
        s.Thickness = 1
    end
    return b
end

local function makeValueDisplay(xOff, w, yOff, parent)
    parent = parent or content
    local d = Instance.new("TextLabel")
    d.Size            = UDim2.new(0, w, 0, 34)
    d.Position        = UDim2.new(0, xOff, 0, yOff)
    d.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
    d.TextColor3      = Color3.fromRGB(0, 215, 115)
    d.Font            = Enum.Font.GothamBold
    d.TextSize        = 16
    d.BorderSizePixel = 0
    d.Parent          = parent
    do Instance.new("UICorner", d).CornerRadius = UDim.new(0, 7) end
    return d
end

sectionLabel("MOVEMENT  [F] Fly  [N] NoClip", 74)

local flyBtn, flySetOn = makeToggle("Fly", 96)
local noclipBtn, noclipSetOn = makeToggle("NoClip", 142)

local flySection = Instance.new("Frame")
flySection.Size               = UDim2.new(1, 0, 0, 110)
flySection.Position           = UDim2.new(0, 0, 0, 190)
flySection.BackgroundTransparency = 1
flySection.Visible            = false
flySection.Parent             = content

sectionLabel("Fly Speed", 0, flySection)

local W  = FRAME_W - 20
local bw = math.floor((W - 9) / 4)

local flySpeedDisplay = makeValueDisplay(PAD + bw + 3, bw, 22, flySection)
flySpeedDisplay.Text = tostring(cfg.flySpeed)

local function refreshFlySpeed()
    flySpeedDisplay.Text = tostring(cfg.flySpeed)
    updateStatus()
end

local fsb = {
    makeSmallBtn("-20", PAD,           bw, 22, flySection),
    makeSmallBtn(" -5", PAD+bw+3,     bw, 22, flySection),
    makeSmallBtn(" +5", PAD+(bw+3)*2, bw, 22, flySection),
    makeSmallBtn("+20", PAD+(bw+3)*3, bw, 22, flySection),
}
local fsd = {-20, -5, 5, 20}
for i, b in ipairs(fsb) do
    b.MouseButton1Click:Connect(function()
        cfg.flySpeed = math.clamp(cfg.flySpeed + fsd[i], 10, 500)
        refreshFlySpeed()
    end)
end

local fine1 = makeSmallBtn("-1",   PAD,           bw, 62, flySection)
local fine2 = makeSmallBtn("fine", PAD+bw+3,     bw, 62, flySection)
local fine3 = makeSmallBtn("ctrl", PAD+(bw+3)*2, bw, 62, flySection)
local fine4 = makeSmallBtn("+1",   PAD+(bw+3)*3, bw, 62, flySection)

fine2.BackgroundColor3 = Color3.fromRGB(22,22,22)
fine2.TextColor3 = Color3.fromRGB(140,140,140)
fine2.Font = Enum.Font.Gotham; fine2.TextSize = 12

fine3.BackgroundColor3 = Color3.fromRGB(22,22,22)
fine3.TextColor3 = Color3.fromRGB(140,140,140)
fine3.Font = Enum.Font.Gotham; fine3.TextSize = 12

fine1.MouseButton1Click:Connect(function()
    cfg.flySpeed = math.clamp(cfg.flySpeed - 1, 10, 500); refreshFlySpeed()
end)
fine4.MouseButton1Click:Connect(function()
    cfg.flySpeed = math.clamp(cfg.flySpeed + 1, 10, 500); refreshFlySpeed()
end)

flyBtn.MouseButton1Click:Connect(function()
    state.fly = not state.fly
    flySetOn(state.fly)
    if state.fly then
        startFly()
        if state.noclip then enableNoclip() end
        notify("Fly ON — camera-direction mode")
    else
        stopFly()
        notify("Fly OFF — gravity restored")
    end
    flySection.Visible = state.fly
    updateStatus()
end)

noclipBtn.MouseButton1Click:Connect(function()
    state.noclip = not state.noclip
    noclipSetOn(state.noclip)
    if state.noclip then enableNoclip() else disableNoclip() end
    notify(state.noclip and "NoClip ON" or "NoClip OFF")
    updateStatus()
end)

sectionLabel("CHARACTER", 308)
sectionLabel("WalkSpeed", 328)
local wsDisplay = makeValueDisplay(PAD + bw + 3, bw, 348)
wsDisplay.Text = tostring(cfg.walkSpeed)

local function refreshWalk()
    wsDisplay.Text = tostring(cfg.walkSpeed)
    applyWalkSpeed(); updateStatus()
end

local wsb = {
    makeSmallBtn("-10", PAD,           bw, 348),
    makeSmallBtn(" -5", PAD+bw+3,     bw, 348),
    makeSmallBtn(" +5", PAD+(bw+3)*2, bw, 348),
    makeSmallBtn("+10", PAD+(bw+3)*3, bw, 348),
}
local wsd = {-10, -5, 5, 10}
for i, b in ipairs(wsb) do
    b.MouseButton1Click:Connect(function()
        cfg.walkSpeed = math.clamp(cfg.walkSpeed + wsd[i], 1, 500)
        refreshWalk()
    end)
end

sectionLabel("JumpHeight", 388)
local jhDisplay = makeValueDisplay(PAD + bw + 3, bw, 408)
jhDisplay.Text = string.format("%.1f", cfg.jumpHeight)

local function refreshJump()
    jhDisplay.Text = string.format("%.1f", cfg.jumpHeight)
    applyJumpHeight(); updateStatus()
end

local jhb = {
    makeSmallBtn("-5", PAD,           bw, 408),
    makeSmallBtn("-1", PAD+bw+3,     bw, 408),
    makeSmallBtn("+1", PAD+(bw+3)*2, bw, 408),
    makeSmallBtn("+5", PAD+(bw+3)*3, bw, 408),
}
local jhd = {-5, -1, 1, 5}
for i, b in ipairs(jhb) do
    b.MouseButton1Click:Connect(function()
        cfg.jumpHeight = math.clamp(cfg.jumpHeight + jhd[i], 1, 200)
        refreshJump()
    end)
end

minimizeBtn.MouseButton1Click:Connect(function()
    state.minimized = not state.minimized
    local targetH = state.minimized and FRAME_H_MIN or FRAME_H_FULL
    TweenService:Create(frame, TweenInfo.new(0.2, Enum.EasingStyle.Quad),
        { Size = UDim2.new(0, FRAME_W, 0, targetH) }
    ):Play()
    content.Visible = not state.minimized
    minimizeBtn.Text = state.minimized and "+" or "—"
end)

UserInputService.InputBegan:Connect(function(inp, gpe)
    if gpe then return end
    if inp.KeyCode == Enum.KeyCode.F then
        flyBtn.MouseButton1Click:Fire()
    elseif inp.KeyCode == Enum.KeyCode.N then
        noclipBtn.MouseButton1Click:Fire()
    end
end)

updateStatus()
notify("Yang Kai Hub v3.0 loaded  [F] Fly  [N] NoClip")
