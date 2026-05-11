local players = game:GetService("Players")
local runservice = game:GetService("RunService")
local userinputservice = game:GetService("UserInputService")

local player = players.LocalPlayer
local camera = workspace.CurrentCamera

local flyenabled = false
local flyspeed = 50

-- =========================
-- CHARACTER HELPERS
-- =========================

local function getcharacter()
    return player.Character or player.CharacterAdded:Wait()
end

local function gethumanoid()
    local character = getcharacter()
    return character:FindFirstChild("Humanoid")
end

local function getrootpart()
    local character = getcharacter()
    return character:FindFirstChild("HumanoidRootPart")
end

-- =========================
-- UI (MOBILE SAFE)
-- =========================

local gui = Instance.new("ScreenGui")
gui.Parent = player:WaitForChild("PlayerGui")
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true

local frame = Instance.new("Frame")
frame.Parent = gui
frame.Size = UDim2.new(0, 220, 0, 150)
frame.Position = UDim2.new(0, 20, 0.3, 0)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
frame.BorderSizePixel = 0

local title = Instance.new("TextLabel")
title.Parent = frame
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
title.Text = "YANG KAI HUB"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 18

-- STATUS
local status = Instance.new("TextLabel")
status.Parent = frame
status.Position = UDim2.new(0, 0, 0, 35)
status.Size = UDim2.new(1, 0, 0, 20)
status.BackgroundTransparency = 1
status.TextColor3 = Color3.fromRGB(0, 255, 0)
status.Font = Enum.Font.SourceSans
status.TextSize = 16
status.Text = "WalkSpeed: 16"

-- FLY BUTTON
local flybutton = Instance.new("TextButton")
flybutton.Parent = frame
flybutton.Position = UDim2.new(0, 10, 0, 60)
flybutton.Size = UDim2.new(1, -20, 0, 30)
flybutton.Text = "Fly: OFF"
flybutton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
flybutton.TextColor3 = Color3.fromRGB(255, 255, 255)

flybutton.MouseButton1Click:Connect(function()
    flyenabled = not flyenabled
    flybutton.Text = flyenabled and "Fly: ON" or "Fly: OFF"

    local humanoid = gethumanoid()
    if humanoid then
        humanoid.PlatformStand = flyenabled
    end
end)

-- SPEED BUTTONS
local speedup = Instance.new("TextButton")
speedup.Parent = frame
speedup.Position = UDim2.new(0, 10, 0, 100)
speedup.Size = UDim2.new(0.45, 0, 0, 30)
speedup.Text = "Speed +"
speedup.BackgroundColor3 = Color3.fromRGB(60, 60, 60)

speedup.MouseButton1Click:Connect(function()
    flyspeed = flyspeed + 10
end)

local speeddown = Instance.new("TextButton")
speeddown.Parent = frame
speeddown.Position = UDim2.new(0.5, 0, 0, 100)
speeddown.Size = UDim2.new(0.45, 0, 0, 30)
speeddown.Text = "Speed -"
speeddown.BackgroundColor3 = Color3.fromRGB(60, 60, 60)

speeddown.MouseButton1Click:Connect(function()
    if flyspeed > 10 then
        flyspeed = flyspeed - 10
    end
end)

-- =========================
-- RESPAWN SAFE
-- =========================

player.CharacterAdded:Connect(function(char)
    task.wait(1)
    local humanoid = char:WaitForChild("Humanoid")
    humanoid.PlatformStand = false
end)

-- =========================
-- MAIN FLY LOOP (ANTI JITTER)
-- =========================

runservice.RenderStepped:Connect(function()

    local humanoid = gethumanoid()
    local rootpart = getrootpart()

    if humanoid then
        status.Text = "WalkSpeed: " .. math.floor(humanoid.WalkSpeed)
    end

    if flyenabled and humanoid and rootpart then

        -- noclip
        for _, v in pairs(getcharacter():GetDescendants()) do
            if v:IsA("BasePart") then
                v.CanCollide = false
            end
      end
