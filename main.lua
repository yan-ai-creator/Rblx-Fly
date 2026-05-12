local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local flyenabled = false
local noclipenabled = false
local flyspeed = 80

local flyConn, noclipConn = nil, nil
local originalCollide = {}
local minimized = false

-- ====================== HELPERS ======================
local function getChar() return player.Character end
local function getHum() local c = getChar() return c and c:FindFirstChild("Humanoid") end
local function getRoot() local c = getChar() return c and c:FindFirstChild("HumanoidRootPart") end

-- ====================== ADVANCED NOCLIP + ANTI-STUCK ======================
local function enableNoclip()
    local char = getChar()
    if not char or noclipConn then return end

    for _, v in ipairs(char:GetDescendants()) do
        if v:IsA("BasePart") then
            originalCollide[v] = v.CanCollide
            v.CanCollide = false
        end
    end

    noclipConn = char.DescendantAdded:Connect(function(v)
        if v:IsA("BasePart") then
            originalCollide[v] = v.CanCollide
            v.CanCollide = false
        end
    end)
end

local function disableNoclip()
    if noclipConn then noclipConn:Disconnect() noclipConn = nil end
    for part, state in pairs(originalCollide) do
        if part and part.Parent then part.CanCollide = state end
    end
    originalCollide = {}
end

-- ====================== JETPACK FLY SYSTEM ======================
local function startFly()
    if flyConn then return end

    flyConn = RunService.RenderStepped:Connect(function()
        local hum = getHum()
        local root = getRoot()
        if not (hum and root) then return end

        hum.PlatformStand = true

        local move = hum.MoveDirection
        local cf = camera.CFrame
        
        -- Camera Based Direction (Perfect for Mobile Joystick)
        local dir = (cf.RightVector * move.X) + (cf.LookVector * move.Z)

        -- Vertical Control (Mobile + PC)
        local vertical = 0
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) or UserInputService:IsKeyDown(Enum.KeyCode.R) then
            vertical = 1
        elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
            vertical = -1
        end

        dir = dir + (Vector3.new(0,1,0) * vertical)

        if dir.Magnitude > 0 then
            local target = dir.Unit * flyspeed
            root.AssemblyLinearVelocity = root.AssemblyLinearVelocity:Lerp(target, 0.65)  -- Jetpack feel
        else
            root.AssemblyLinearVelocity = root.AssemblyLinearVelocity:Lerp(Vector3.zero, 0.7) -- Strong hover stability
        end

        root.AssemblyAngularVelocity = Vector3.zero
    end)
end

local function stopFly()
    if flyConn then flyConn:Disconnect() flyConn = nil end
    local hum = getHum()
    if hum then hum.PlatformStand = false end
    disableNoclip()
end

-- ====================== DRAGGABLE + MINIMIZABLE GUI ======================
local gui = Instance.new("ScreenGui")
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 300, 0, 380)
frame.Position = UDim2.new(0, 20, 0.1, 0)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
frame.BorderSizePixel = 0
frame.Parent = gui

local titleBar = Instance.new("TextLabel")
titleBar.Size = UDim2.new(1, 0, 0, 40)
titleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
titleBar.Text = "   YANG KAI HUB - JETPACK"
titleBar.TextColor3 = Color3.fromRGB(255, 80, 80)
titleBar.Font = Enum.Font.SourceSansBold
titleBar.TextSize = 21
titleBar.TextXAlignment = Enum.TextXAlignment.Left
titleBar.Parent = frame

local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Size = UDim2.new(0, 35, 0, 35)
minimizeBtn.Position = UDim2.new(1, -38, 0, 3)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
minimizeBtn.Text = "-"
minimizeBtn.TextColor3 = Color3.new(1,1,1)
minimizeBtn.TextSize = 24
minimizeBtn.Parent = titleBar

-- Draggable
local dragging, dragStart, startPos
titleBar.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = inp.Position
        startPos = frame.Position
    end
end)

UserInputService.InputChanged:Connect(function(inp)
    if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
        local delta = inp.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

titleBar.InputEnded:Connect(function() dragging = false end)

-- ====================== UI BUTTONS ======================
local status = Instance.new("TextLabel")
status.Position = UDim2.new(0,0,0,45)
status.Size = UDim2.new(1,0,0,30)
status.BackgroundTransparency = 1
status.Text = "Speed: 80"
status.TextColor3 = Color3.fromRGB(0, 255, 140)
status.Font = Enum.Font.SourceSans
status.TextSize = 18
status.Parent = frame

local function createBtn(text, y, color, func)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -20, 0, 38)
    btn.Position = UDim2.new(0, 10, 0, y)
    btn.BackgroundColor3 = color
    btn.Text = text
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 17
    btn.Parent = frame
    btn.MouseButton1Click:Connect(func)
    return btn
end

local flybtn = createBtn("Fly: OFF", 85, Color3.fromRGB(60,60,60), function()
    flyenabled = not flyenabled
    flybtn.Text = flyenabled and "Fly: ON" or "Fly: OFF"
    flybtn.BackgroundColor3 = flyenabled and Color3.fromRGB(0,180,0) or Color3.fromRGB(60,60,60)
    
    if flyenabled then startFly() if noclipenabled then enableNoclip() end
    else stopFly() end
end)

local noclipbtn = createBtn("NoClip: OFF", 130, Color3.fromRGB(60,60,60), function()
    noclipenabled = not noclipenabled
    noclipbtn.Text = noclipenabled and "NoClip: ON" or "NoClip: OFF"
    noclipbtn.BackgroundColor3 = noclipenabled and Color3.fromRGB(0,180,0) or Color3.fromRGB(60,60,60)
    if noclipenabled and flyenabled then enableNoclip() else disableNoclip() end
end)

-- Mobile Vertical Thrust Buttons
createBtn("▲ UP Thrust", 175, Color3.fromRGB(0, 120, 200), function()
    if flyenabled then
        local root = getRoot()
        if root then root.AssemblyLinearVelocity += Vector3.new(0, 45, 0) end
    end
end)

createBtn("▼ DOWN Thrust", 220, Color3.fromRGB(200, 80, 0), function()
    if flyenabled then
        local root = getRoot()
        if root then root.AssemblyLinearVelocity += Vector3.new(0, -45, 0) end
    end
end)

-- Speed Controls
createBtn("+30 Speed", 265, Color3.fromRGB(80,80,80), function() flyspeed += 30; status.Text = "Speed: "..flyspeed end)
createBtn("+150 Speed", 305, Color3.fromRGB(80,80,80), function() flyspeed += 150; status.Text = "Speed: "..flyspeed end)
createBtn("-30 Speed", 345, Color3.fromRGB(80,80,80), function() flyspeed = math.max(30, flyspeed-30); status.Text = "Speed: "..flyspeed end)

-- Minimize
minimizeBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    frame.Size = minimized and UDim2.new(0,300,0,45) or UDim2.new(0,300,0,380)
    minimizeBtn.Text = minimized and "+" or "-"
end)

-- ====================== RESPAWN ======================
player.CharacterAdded:Connect(function()
    task.wait(1.5)
    originalCollide = {}
    if flyenabled then
        stopFly()
        task.wait(0.5)
        startFly()
        if noclipenabled then enableNoclip() end
    end
end)

print("✅ Yang Kai Hub - Ultimate Jetpack Fly Loaded")
