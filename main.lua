local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local flyenabled = false
local noclipenabled = false
local flyspeed = 85

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

-- ====================== TRUE 6D CAMERA FLIGHT ======================
local function startFly()
    if flyConn then return end

    flyConn = RunService.RenderStepped:Connect(function()
        local hum = getHum()
        local root = getRoot()
        if not (hum and root) then return end

        hum.PlatformStand = true

        local move = hum.MoveDirection
        local cf = camera.CFrame

        -- Full Camera Relative Movement
        local forward = cf.LookVector
        local right = cf.RightVector

        local direction = (right * move.X) + (forward * move.Z)

        if direction.Magnitude > 0 then
            local targetVel = direction.Unit * flyspeed
            root.AssemblyLinearVelocity = root.AssemblyLinearVelocity:Lerp(targetVel, 0.65)
        else
            root.AssemblyLinearVelocity = root.AssemblyLinearVelocity:Lerp(Vector3.zero, 0.72)
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
frame.Size = UDim2.new(0, 300, 0, 400)
frame.Position = UDim2.new(0, 20, 0.15, 0)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
frame.Parent = gui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,0,0,40)
title.BackgroundColor3 = Color3.fromRGB(30,30,30)
title.Text = "   YANG KAI HUB - 6D FLIGHT"
title.TextColor3 = Color3.fromRGB(255, 85, 85)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 21
title.Parent = frame

local status = Instance.new("TextLabel")
status.Position = UDim2.new(0,0,0,45)
status.Size = UDim2.new(1,0,0,30)
status.BackgroundTransparency = 1
status.Text = "Speed: 85"
status.TextColor3 = Color3.fromRGB(0,255,140)
status.Font = Enum.Font.SourceSans
status.TextSize = 18
status.Parent = frame

local function createBtn(text, y, color, func)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1,-20,0,38)
    b.Position = UDim2.new(0,10,0,y)
    b.BackgroundColor3 = color
    b.Text = text
    b.TextColor3 = Color3.new(1,1,1)
    b.Font = Enum.Font.SourceSansBold
    b.TextSize = 17
    b.Parent = frame
    b.MouseButton1Click:Connect(func)
    return b
end

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

-- Real Vertical Thrust Buttons
createBtn("▲ UP Thrust", 185, Color3.fromRGB(0, 110, 200), function()
    if flyenabled then
        local root = getRoot()
        if root then root.AssemblyLinearVelocity += Vector3.new(0, 35, 0) end
    end
end)

createBtn("▼ DOWN Thrust", 230, Color3.fromRGB(200, 90, 0), function()
    if flyenabled then
        local root = getRoot()
        if root then root.AssemblyLinearVelocity += Vector3.new(0, -35, 0) end
    end
end)

-- Speed Control
createBtn("+50 Speed", 275, Color3.fromRGB(80,80,80), function() 
    flyspeed += 50 
    status.Text = "Speed: " .. flyspeed 
end)

createBtn("-50 Speed", 320, Color3.fromRGB(80,80,80), function() 
    flyspeed = math.max(30, flyspeed - 50)
    status.Text = "Speed: " .. flyspeed 
end)

-- ====================== RESPAWN ======================
player.CharacterAdded:Connect(function()
    task.wait(1.5)
    originalCollide = {}
    if flyenabled then
        stopFly()
        task.wait(0.4)
        startFly()
        if noclipenabled then enableNoclip() end
    end
end)

print("✅ Yang Kai Hub - Fixed 6D Flight Loaded")
