local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local flyenabled = false
local noclipenabled = false
local flyspeed = 85
local minimized = false
local dragging = false
local dragStart
local startPos

local flyConn = nil
local noclipConn = nil
local originalCollide = {}

-- ====================== HELPERS ======================
local function getChar() return player.Character end
local function getHum() local c = getChar() return c and c:FindFirstChild("Humanoid") end
local function getRoot() local c = getChar() return c and c:FindFirstChild("HumanoidRootPart") end

-- ====================== NOCLIP ======================
local function enableNoclip()
    local char = getChar()
    if not char or noclipConn then return end

    for _, v in ipairs(char:GetDescendants()) do
        if v:IsA("BasePart") and v.CanCollide then
            originalCollide[v] = true
            v.CanCollide = false
        end
    end

    noclipConn = char.DescendantAdded:Connect(function(v)
        if v:IsA("BasePart") and v.CanCollide then
            originalCollide[v] = true
            v.CanCollide = false
        end
    end)
end

local function disableNoclip()
    if noclipConn then 
        noclipConn:Disconnect() 
        noclipConn = nil 
    end
    for part, _ in pairs(originalCollide) do
        if part and part.Parent then 
            part.CanCollide = true 
        end
    end
    originalCollide = {}
end

-- ====================== 6D CAMERA FLIGHT ======================
local function startFly()
    if flyConn then return end

    flyConn = RunService.RenderStepped:Connect(function()
        local hum = getHum()
        local root = getRoot()
        if not (hum and root) then return end

        hum.PlatformStand = true

        local move = hum.MoveDirection
        local cf = camera.CFrame

        local forward = cf.LookVector
        local right = cf.RightVector

        local direction = (right * move.X) + (forward * move.Z)

        if direction.Magnitude > 0 then
            local targetVel = direction.Unit * flyspeed
            root.AssemblyLinearVelocity = root.AssemblyLinearVelocity:Lerp(targetVel, 0.68)
        else
            root.AssemblyLinearVelocity = root.AssemblyLinearVelocity:Lerp(Vector3.zero, 0.75)
        end

        root.AssemblyAngularVelocity = Vector3.zero
    end)
end

local function stopFly()
    if flyConn then 
        flyConn:Disconnect() 
        flyConn = nil 
    end
    local hum = getHum()
    if hum then hum.PlatformStand = false end
    disableNoclip()
end

-- ====================== GUI ======================
local gui = Instance.new("ScreenGui")
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 300, 0, 420)
frame.Position = UDim2.new(0, 20, 0.15, 0)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
frame.BorderSizePixel = 0
frame.Parent = gui

-- Title Bar
local titleBar = Instance.new("TextLabel")
titleBar.Size = UDim2.new(1, 0, 0, 40)
titleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
titleBar.Text = "   YANG KAI HUB - 6D FLIGHT"
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
minimizeBtn.Font = Enum.Font.SourceSansBold
minimizeBtn.TextSize = 24
minimizeBtn.Parent = titleBar

-- Draggable
titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = frame.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

titleBar.InputEnded:Connect(function() dragging = false end)

-- Status
local status = Instance.new("TextLabel")
status.Position = UDim2.new(0,0,0,45)
status.Size = UDim2.new(1,0,0,30)
status.BackgroundTransparency = 1
status.Text = "Speed: 85"
status.TextColor3 = Color3.fromRGB(0,255,140)
status.Font = Enum.Font.SourceSans
status.TextSize = 18
status.Parent = frame

-- Button Function
local function createBtn(text, yPos, color, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -20, 0, 38)
    btn.Position = UDim2.new(0, 10, 0, yPos)
    btn.BackgroundColor3 = color
    btn.Text = text
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 17
    btn.Parent = frame
    btn.MouseButton1Click:Connect(callback)
    return btn
end

-- Main Buttons
local flybtn = createBtn("Fly: OFF", 85, Color3.fromRGB(60,60,60), function()
    flyenabled = not flyenabled
    flybtn.Text = flyenabled and "Fly: ON" or "Fly: OFF"
    flybtn.BackgroundColor3 = flyenabled and Color3.fromRGB(0,185,0) or Color3.fromRGB(60,60,60)
    
    if flyenabled then
        startFly()
        if noclipenabled then enableNoclip() end
    else
        stopFly()
    end
end)

local noclipbtn = createBtn("NoClip: OFF", 135, Color3.fromRGB(60,60,60), function()
    noclipenabled = not noclipenabled
    noclipbtn.Text = noclipenabled and "NoClip: ON" or "NoClip: OFF"
    noclipbtn.BackgroundColor3 = noclipenabled and Color3.fromRGB(0,185,0) or Color3.fromRGB(60,60,60)
    if noclipenabled and flyenabled then enableNoclip() else disableNoclip() end
end)

createBtn("▲ UP Thrust", 185, Color3.fromRGB(0,110,200), function()
    if flyenabled then
        local root = getRoot()
        if root then root.AssemblyLinearVelocity += Vector3.new(0, 45, 0) end
    end
end)

createBtn("▼ DOWN Thrust", 230, Color3.fromRGB(200,90,0), function()
    if flyenabled then
        local root = getRoot()
        if root then root.AssemblyLinearVelocity += Vector3.new(0, -45, 0) end
    end
end)

createBtn("+50 Speed", 275, Color3.fromRGB(80,80,80), function() 
    flyspeed += 50 
    status.Text = "Speed: " .. flyspeed 
end)

createBtn("-50 Speed", 320, Color3.fromRGB(80,80,80), function() 
    flyspeed = math.max(30, flyspeed - 50)
    status.Text = "Speed: " .. flyspeed 
end)

-- Minimize Button
minimizeBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        frame.Size = UDim2.new(0, 300, 0, 45)
        minimizeBtn.Text = "+"
    else
        frame.Size = UDim2.new(0, 300, 0, 420)
        minimizeBtn.Text = "-"
    end
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

print("✅ Yang Kai Hub - Final Clean Version Loaded")
