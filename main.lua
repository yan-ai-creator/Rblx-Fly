local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local flyenabled = false
local noclipenabled = false
local flyspeed = 65

local flyConn = nil
local noclipConn = nil
local originalCollide = {}

print("✅ Yang Kai Hub Loading...")

-- ====================== HELPERS ======================
local function getChar() return player.Character end
local function getHum() local c = getChar() return c and c:FindFirstChild("Humanoid") end
local function getRoot() local c = getChar() return c and c:FindFirstChild("HumanoidRootPart") end

-- ====================== NOCLIP ======================
local function enableNoclip()
    local char = getChar()
    if not char then return end
    for _, v in ipairs(char:GetDescendants()) do
        if v:IsA("BasePart") and v.CanCollide then
            originalCollide[v] = true
            v.CanCollide = false
        end
    end
end

local function disableNoclip()
    for part, _ in pairs(originalCollide) do
        if part and part.Parent then part.CanCollide = true end
    end
    originalCollide = {}
end

-- ====================== FLIGHT ======================
local function startFly()
    if flyConn then return end
    flyConn = RunService.RenderStepped:Connect(function()
        local hum = getHum()
        local root = getRoot()
        if not (hum and root) then return end

        hum.PlatformStand = true

        local move = hum.MoveDirection
        local cf = camera.CFrame
        local direction = (cf.RightVector * move.X) + (cf.LookVector * move.Z)

        if direction.Magnitude > 0 then
            root.AssemblyLinearVelocity = root.AssemblyLinearVelocity:Lerp(direction.Unit * flyspeed, 0.7)
        else
            root.AssemblyLinearVelocity = root.AssemblyLinearVelocity:Lerp(Vector3.zero, 0.8)
        end
    end)
end

local function stopFly()
    if flyConn then flyConn:Disconnect() flyConn = nil end
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
frame.Size = UDim2.new(0, 290, 0, 380)
frame.Position = UDim2.new(0, 20, 0.2, 0)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
frame.Parent = gui

local titleBar = Instance.new("TextLabel")
titleBar.Size = UDim2.new(1,0,0,40)
titleBar.BackgroundColor3 = Color3.fromRGB(30,30,30)
titleBar.Text = "   YANG KAI HUB"
titleBar.TextColor3 = Color3.fromRGB(255,80,80)
titleBar.Font = Enum.Font.SourceSansBold
titleBar.TextSize = 22
titleBar.Parent = frame

local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Size = UDim2.new(0,35,0,35)
minimizeBtn.Position = UDim2.new(1,-38,0,3)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(180,50,50)
minimizeBtn.Text = "-"
minimizeBtn.TextColor3 = Color3.new(1,1,1)
minimizeBtn.TextSize = 24
minimizeBtn.Parent = titleBar

-- Draggable
local dragging
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

-- Status
local status = Instance.new("TextLabel")
status.Position = UDim2.new(0,0,0,50)
status.Size = UDim2.new(1,0,0,30)
status.BackgroundTransparency = 1
status.Text = "Speed: 65"
status.TextColor3 = Color3.fromRGB(0,255,140)
status.Font = Enum.Font.SourceSans
status.TextSize = 18
status.Parent = frame

local function createBtn(text, y, color, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1,-20,0,38)
    btn.Position = UDim2.new(0,10,0,y)
    btn.BackgroundColor3 = color
    btn.Text = text
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 17
    btn.Parent = frame
    btn.MouseButton1Click:Connect(callback)
    return btn
end

-- Buttons
local flybtn = createBtn("Fly: OFF", 90, Color3.fromRGB(60,60,60), function()
    flyenabled = not flyenabled
    flybtn.Text = flyenabled and "Fly: ON" or "Fly: OFF"
    flybtn.BackgroundColor3 = flyenabled and Color3.fromRGB(0,170,0) or Color3.fromRGB(60,60,60)

    if flyenabled then
        startFly()
        if noclipenabled then enableNoclip() end
    else
        stopFly()
    end
end)

local noclipbtn = createBtn("NoClip: OFF", 140, Color3.fromRGB(60,60,60), function()
    noclipenabled = not noclipenabled
    noclipbtn.Text = noclipenabled and "NoClip: ON" or "NoClip: OFF"
    noclipbtn.BackgroundColor3 = noclipenabled and Color3.fromRGB(0,170,0) or Color3.fromRGB(60,60,60)
    if noclipenabled and flyenabled then enableNoclip() else disableNoclip() end
end)

-- Speed Buttons (শুধু Fly ON থাকলে কাজ করবে)
createBtn("+20 Speed", 190, Color3.fromRGB(70,70,70), function()
    if flyenabled then flyspeed += 20; status.Text = "Speed: "..flyspeed end
end)

createBtn("-20 Speed", 235, Color3.fromRGB(70,70,70), function()
    if flyenabled then flyspeed = math.max(30, flyspeed-20); status.Text = "Speed: "..flyspeed end
end)

-- Minimize
minimizeBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    frame.Size = minimized and UDim2.new(0,300,0,45) or UDim2.new(0,300,0,380)
    minimizeBtn.Text = minimized and "+" or "-"
end)

print("✅ Yang Kai Hub Loaded Successfully!")
