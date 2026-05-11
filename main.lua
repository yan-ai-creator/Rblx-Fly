local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local flyenabled = false
local noclipenabled = false
local flyspeed = 50

local connection = nil
local noclipConnection = nil
local originalCollide = {}

-- =========================
-- HELPERS
-- =========================
local function getcharacter()
    return player.Character
end

local function gethumanoid()
    local char = getcharacter()
    return char and char:FindFirstChild("Humanoid")
end

local function getroot()
    local char = getcharacter()
    return char and char:FindFirstChild("HumanoidRootPart")
end

-- =========================
-- ULTRA RELIABLE NOCLIP
-- =========================
local function applyNoclipToCharacter(char)
    if not char then return end
    
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            if originalCollide[part] == nil then
                originalCollide[part] = part.CanCollide
            end
            part.CanCollide = false
        end
    end
end

local function enableNoclip()
    if noclipConnection then return end
    
    local char = getcharacter()
    if not char then return end

    applyNoclipToCharacter(char)

    -- Dynamic new parts
    noclipConnection = char.DescendantAdded:Connect(function(desc)
        if desc:IsA("BasePart") then
            originalCollide[desc] = desc.CanCollide
            desc.CanCollide = false
        end
    end)
end

local function disableNoclip()
    if noclipConnection then
        noclipConnection:Disconnect()
        noclipConnection = nil
    end

    for part, state in pairs(originalCollide) do
        if part and part.Parent then
            part.CanCollide = state
        end
    end
    originalCollide = {}
end

-- =========================
-- GUI (Same as before)
-- =========================
local gui = Instance.new("ScreenGui")
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 260, 0, 240)
frame.Position = UDim2.new(0, 20, 0.2, 0)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
frame.BorderSizePixel = 0
frame.Parent = gui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 35)
title.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
title.Text = "YANG KAI HUB"
title.TextColor3 = Color3.fromRGB(255, 100, 100)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 20
title.Parent = frame

local status = Instance.new("TextLabel")
status.Position = UDim2.new(0, 0, 0, 40)
status.Size = UDim2.new(1, 0, 0, 25)
status.BackgroundTransparency = 1
status.TextColor3 = Color3.fromRGB(0, 255, 100)
status.Text = "Speed: 50"
status.Font = Enum.Font.SourceSans
status.TextSize = 16
status.Parent = frame

local flybtn = Instance.new("TextButton")
flybtn.Position = UDim2.new(0, 10, 0, 70)
flybtn.Size = UDim2.new(1, -20, 0, 35)
flybtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
flybtn.Text = "Fly: OFF"
flybtn.TextColor3 = Color3.new(1,1,1)
flybtn.Font = Enum.Font.SourceSansBold
flybtn.TextSize = 18
flybtn.Parent = frame

local noclipbtn = Instance.new("TextButton")
noclipbtn.Position = UDim2.new(0, 10, 0, 115)
noclipbtn.Size = UDim2.new(1, -20, 0, 35)
noclipbtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
noclipbtn.Text = "NoClip: OFF"
noclipbtn.TextColor3 = Color3.new(1,1,1)
noclipbtn.Font = Enum.Font.SourceSansBold
noclipbtn.TextSize = 18
noclipbtn.Parent = frame

-- Speed Buttons
local function createBtn(text, pos, inc)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.45, 0, 0, 30)
    btn.Position = pos
    btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    btn.Text = text
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 16
    btn.Parent = frame
    btn.MouseButton1Click:Connect(function()
        flyspeed = math.max(10, flyspeed + inc)
    end)
    return btn
end

createBtn("+10", UDim2.new(0, 10, 0, 160), 10)
createBtn("+50", UDim2.new(0.5, 5, 0, 160), 50)
createBtn("-10", UDim2.new(0, 10, 0, 195), -10)
createBtn("-50", UDim2.new(0.5, 5, 0, 195), -50)

-- =========================
-- FLY MOVEMENT
-- =========================
local function startfly()
    if connection then return end

    connection = RunService.RenderStepped:Connect(function()
        local hum = gethumanoid()
        local root = getroot()
        if not hum or not root then return end

        status.Text = "Speed: " .. math.floor(flyspeed)
        hum.PlatformStand = true

        local move = hum.MoveDirection
        local camcf = camera.CFrame
        local dir = camcf.RightVector * move.X + camcf.LookVector * move.Z

        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            dir += Vector3.new(0, 1, 0)
        elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
            dir -= Vector3.new(0, 1, 0)
        end

        if dir.Magnitude > 0 then
            local targetVel = dir.Unit * flyspeed
            root.AssemblyLinearVelocity = root.AssemblyLinearVelocity:Lerp(targetVel, 0.48)
        else
            root.AssemblyLinearVelocity = root.AssemblyLinearVelocity:Lerp(Vector3.zero, 0.4)
        end

        root.AssemblyAngularVelocity = Vector3.zero
    end)
end

local function stopfly()
    if connection then
        connection:Disconnect()
        connection = nil
    end
    local hum = gethumanoid()
    if hum then hum.PlatformStand = false end
    disableNoclip()
end

-- =========================
-- BUTTONS
-- =========================
flybtn.MouseButton1Click:Connect(function()
    flyenabled = not flyenabled
    flybtn.Text = flyenabled and "Fly: ON" or "Fly: OFF"
    flybtn.BackgroundColor3 = flyenabled and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(60, 60, 60)

    if flyenabled then
        startfly()
        if noclipenabled then enableNoclip() end
    else
        stopfly()
    end
end)

noclipbtn.MouseButton1Click:Connect(function()
    noclipenabled = not noclipenabled
    noclipbtn.Text = noclipenabled and "NoClip: ON" or "NoClip: OFF"
    noclipbtn.BackgroundColor3 = noclipenabled and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(60, 60, 60)

    if noclipenabled and flyenabled then
        enableNoclip()
    else
        disableNoclip()
    end
end)

-- =========================
-- RESPAWN + EDGE CASE HANDLING
-- =========================
player.CharacterAdded:Connect(function(newChar)
    task.wait(1.2)
    originalCollide = {} -- reset

    if flyenabled then
        stopfly()
        task.wait(0.4)
        startfly()
        if noclipenabled then
            task.wait(0.3)
            enableNoclip()
        end
    end
end)

print("Yang Kai Hub - Advanced Fly + Noclip Loaded")
