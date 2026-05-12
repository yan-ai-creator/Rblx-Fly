    -- ================================================================
--  YANG KAI HUB  |  v4.0 Mobile Edition
--  Entity system: LinearVelocity + AlignOrientation
--  Mobile-optimised, camera-direction fly, character lock
-- ================================================================

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local cfg = { flySpeed=80, walkSpeed=16, jumpHeight=7.2 }

local state = { fly=false, noclip=false, dragging=false, minimized=false, dragStart=nil, startPos=nil }

local flyEntity  = { lv=nil, att=nil, ao=nil }
local flyConn    = nil
local noclipConn = nil

local function rname()
    local s=""
    for _=1,10 do s=s..string.char(math.random(97,122)) end
    return s
end

local function safe(fn) local ok=pcall(fn); if not ok then end end

local function getChar()  return player.Character end
local function getHum()   local c=getChar(); return c and c:FindFirstChildOfClass("Humanoid") end
local function getRoot()  local c=getChar(); return c and c:FindFirstChild("HumanoidRootPart") end

local function destroyFlyEntity()
    safe(function()
        if flyEntity.lv  and flyEntity.lv.Parent  then flyEntity.lv:Destroy()  end
        if flyEntity.ao  and flyEntity.ao.Parent  then flyEntity.ao:Destroy()  end
        if flyEntity.att and flyEntity.att.Parent then flyEntity.att:Destroy() end
    end)
    flyEntity.lv=nil; flyEntity.ao=nil; flyEntity.att=nil
end

local function buildFlyEntity()
    destroyFlyEntity()
    local root=getRoot()
    if not root then return false end

    local att=Instance.new("Attachment")
    att.Name=rname(); att.Parent=root

    local lv=Instance.new("LinearVelocity")
    lv.Name=rname(); lv.Attachment0=att; lv.MaxForce=1e6
    lv.RelativeTo=Enum.ActuatorRelativeTo.World
    lv.VelocityConstraintMode=Enum.VelocityConstraintMode.Vector
    lv.VectorVelocity=Vector3.zero; lv.Parent=root

    local ao=Instance.new("AlignOrientation")
    ao.Name=rname(); ao.Attachment0=att; ao.MaxTorque=4e5
    ao.Responsiveness=50; ao.RigidityEnabled=false; ao.Parent=root

    flyEntity.att=att; flyEntity.lv=lv; flyEntity.ao=ao
    return true
end

local function enableNoclip()
    if noclipConn then return end
    noclipConn=RunService.Stepped:Connect(function()
        safe(function()
            local char=getChar(); if not char then return end
            for _,v in ipairs(char:GetDescendants()) do
                if v:IsA("BasePart") then v.CanCollide=false end
            end
        end)
    end)
end

local function disableNoclip()
    if noclipConn then noclipConn:Disconnect(); noclipConn=nil end
    safe(function()
        local char=getChar(); if not char then return end
        for _,v in ipairs(char:GetDescendants()) do
            if v:IsA("BasePart") then v.CanCollide=true end
        end
    end)
end

local function startFly()
    if flyConn then return end
    if not buildFlyEntity() then return end
    safe(function() local h=getHum(); if h then h.PlatformStand=true end end)

    flyConn=RunService.Heartbeat:Connect(function()
        safe(function()
            local hum=getHum(); local root=getRoot()
            local lv=flyEntity.lv; local ao=flyEntity.ao
            if not (hum and root and lv and lv.Parent) then return end

            hum.PlatformStand=true

            -- Lock character upright facing camera horizontal direction
            if ao and ao.Parent then
                local lookFlat=Vector3.new(camera.CFrame.LookVector.X,0,camera.CFrame.LookVector.Z)
                if lookFlat.Magnitude>0.05 then
                    ao.CFrame=CFrame.lookAt(Vector3.zero, lookFlat.Unit)
                end
            end

            -- Mobile joystick → full 3D camera direction
            local moveDir=hum.MoveDirection
            local cf=camera.CFrame

            if moveDir.Magnitude>0.05 then
                local flatFwd=Vector3.new(cf.LookVector.X,0,cf.LookVector.Z)
                local flatRgt=Vector3.new(cf.RightVector.X,0,cf.RightVector.Z)
                if flatFwd.Magnitude<0.01 then flatFwd=Vector3.new(0,0,-1) end
                if flatRgt.Magnitude<0.01 then flatRgt=Vector3.new(1,0,0) end
                flatFwd=flatFwd.Unit; flatRgt=flatRgt.Unit

                local fwdAmt=moveDir:Dot(flatFwd)
                local rgtAmt=moveDir:Dot(flatRgt)
                local flyDir=(cf.LookVector*fwdAmt)+(cf.RightVector*rgtAmt)

                if flyDir.Magnitude>0.01 then
                    lv.VectorVelocity=lv.VectorVelocity:Lerp(flyDir.Unit*cfg.flySpeed, 0.25)
                else
                    lv.VectorVelocity=Vector3.zero
                end
            else
                lv.VectorVelocity=lv.VectorVelocity:Lerp(Vector3.zero, 0.3)
            end
        end)
    end)
end

local function stopFly()
    if flyConn then flyConn:Disconnect(); flyConn=nil end
    safe(function()
        if flyEntity.lv and flyEntity.lv.Parent then flyEntity.lv.VectorVelocity=Vector3.zero end
        local h=getHum(); if h then h.PlatformStand=false end
    end)
    destroyFlyEntity()
    if not state.noclip then disableNoclip() end
end

local function applyWalkSpeed() safe(function() local h=getHum(); if h then h.WalkSpeed=cfg.walkSpeed end end) end
local function applyJumpHeight() safe(function() local h=getHum(); if h then h.JumpHeight=cfg.jumpHeight end end) end

local function onCharacterAdded(char)
    safe(function()
        char:WaitForChild("HumanoidRootPart",10)
        char:WaitForChild("Humanoid",10)
        task.wait(0.6)
        applyWalkSpeed(); applyJumpHeight()
        if state.noclip then enableNoclip() end
        if state.fly then destroyFlyEntity(); startFly() end
    end)
end

player.CharacterAdded:Connect(onCharacterAdded)
if player.Character then task.spawn(onCharacterAdded, player.Character) end

-- ================================================================
--  GUI
-- ================================================================

local FW=300; local FH_FULL=490; local FH_MIN=48; local PAD=10

local gui=Instance.new("ScreenGui")
gui.Name=rname(); gui.ResetOnSpawn=false; gui.IgnoreGuiInset=true
gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
gui.Parent=player:WaitForChild("PlayerGui")

local frame=Instance.new("Frame")
frame.Name=rname(); frame.Size=UDim2.new(0,FW,0,FH_FULL)
frame.Position=UDim2.new(0,18,0.08,0); frame.BackgroundColor3=Color3.fromRGB(12,12,12)
frame.BorderSizePixel=0; frame.Parent=gui
Instance.new("UICorner",frame).CornerRadius=UDim.new(0,14)
do local s=Instance.new("UIStroke",frame); s.Color=Color3.fromRGB(210,40,40); s.Thickness=1.5; s.Transparency=0.45 end

local titleBar=Instance.new("Frame")
titleBar.Size=UDim2.new(1,0,0,48); titleBar.BackgroundColor3=Color3.fromRGB(20,20,20)
titleBar.BorderSizePixel=0; titleBar.Parent=frame
Instance.new("UICorner",titleBar).CornerRadius=UDim.new(0,14)

local stripe=Instance.new("Frame")
stripe.Size=UDim2.new(0,4,0,28); stripe.Position=UDim2.new(0,12,0.5,-14)
stripe.BackgroundColor3=Color3.fromRGB(220,40,40); stripe.BorderSizePixel=0; stripe.Parent=titleBar
Instance.new("UICorner",stripe).CornerRadius=UDim.new(1,0)

local titleLabel=Instance.new("TextLabel")
titleLabel.Size=UDim2.new(1,-60,1,0); titleLabel.Position=UDim2.new(0,22,0,0)
titleLabel.BackgroundTransparency=1; titleLabel.Text="YANG KAI HUB"
titleLabel.TextColor3=Color3.fromRGB(235,235,235); titleLabel.Font=Enum.Font.GothamBold
titleLabel.TextSize=17; titleLabel.TextXAlignment=Enum.TextXAlignment.Left; titleLabel.Parent=titleBar

local verLbl=Instance.new("TextLabel")
verLbl.Size=UDim2.new(0,80,0,14); verLbl.Position=UDim2.new(0,22,1,-16)
verLbl.BackgroundTransparency=1; verLbl.Text="v4.0 Mobile"
verLbl.TextColor3=Color3.fromRGB(210,40,40); verLbl.Font=Enum.Font.Gotham
verLbl.TextSize=11; verLbl.TextXAlignment=Enum.TextXAlignment.Left; verLbl.Parent=titleBar

local minBtn=Instance.new("TextButton")
minBtn.Size=UDim2.new(0,38,0,38); minBtn.Position=UDim2.new(1,-44,0.5,-19)
minBtn.BackgroundColor3=Color3.fromRGB(210,40,40); minBtn.Text="—"
minBtn.TextColor3=Color3.new(1,1,1); minBtn.TextSize=18; minBtn.Font=Enum.Font.GothamBold
minBtn.BorderSizePixel=0; minBtn.Parent=titleBar
Instance.new("UICorner",minBtn).CornerRadius=UDim.new(0,8)

titleBar.InputBegan:Connect(function(inp)
    if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
        state.dragging=true; state.dragStart=inp.Position; state.startPos=frame.Position
    end
end)
UserInputService.InputChanged:Connect(function(inp)
    if not state.dragging then return end
    if inp.UserInputType==Enum.UserInputType.MouseMovement or inp.UserInputType==Enum.UserInputType.Touch then
        local d=inp.Position-state.dragStart
        frame.Position=UDim2.new(state.startPos.X.Scale,state.startPos.X.Offset+d.X,state.startPos.Y.Scale,state.startPos.Y.Offset+d.Y)
    end
end)
UserInputService.InputEnded:Connect(function(inp)
    if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
        state.dragging=false
    end
end)

local content=Instance.new("Frame")
content.Size=UDim2.new(1,0,1,-48); content.Position=UDim2.new(0,0,0,48)
content.BackgroundTransparency=1; content.ClipsDescendants=true; content.Parent=frame

local toast=Instance.new("TextLabel")
toast.Size=UDim2.new(1,-20,0,28); toast.Position=UDim2.new(0,10,0,6)
toast.BackgroundColor3=Color3.fromRGB(210,40,40); toast.TextColor3=Color3.new(1,1,1)
toast.Font=Enum.Font.GothamBold; toast.TextSize=13; toast.Text=""
toast.BorderSizePixel=0; toast.BackgroundTransparency=1; toast.TextTransparency=1; toast.Parent=content
Instance.new("UICorner",toast).CornerRadius=UDim.new(0,7)

local toastThread=nil
local function notify(msg)
    if toastThread then task.cancel(toastThread) end
    toast.Text="  "..msg; toast.BackgroundTransparency=0; toast.TextTransparency=0
    toastThread=task.delay(2.2,function()
        TweenService:Create(toast,TweenInfo.new(0.35),{BackgroundTransparency=1,TextTransparency=1}):Play()
    end)
end

local statusBar=Instance.new("TextLabel")
statusBar.Size=UDim2.new(1,-20,0,30); statusBar.Position=UDim2.new(0,10,0,40)
statusBar.BackgroundColor3=Color3.fromRGB(20,20,20); statusBar.TextColor3=Color3.fromRGB(0,210,110)
statusBar.Font=Enum.Font.Gotham; statusBar.TextSize=13; statusBar.BorderSizePixel=0
statusBar.TextXAlignment=Enum.TextXAlignment.Left; statusBar.Parent=content
Instance.new("UICorner",statusBar).CornerRadius=UDim.new(0,7)

local function updateStatus()
    statusBar.Text=string.format("  Fly: %s  |  NoClip: %s  |  FlySpd: %d  |  Walk: %d",
        state.fly and "ON" or "OFF", state.noclip and "ON" or "OFF", cfg.flySpeed, cfg.walkSpeed)
end

local function makeDivider(yOff,label)
    local row=Instance.new("Frame")
    row.Size=UDim2.new(1,-20,0,18); row.Position=UDim2.new(0,10,0,yOff)
    row.BackgroundTransparency=1; row.Parent=content
    local line=Instance.new("Frame")
    line.Size=UDim2.new(1,0,0,1); line.Position=UDim2.new(0,0,0.5,0)
    line.BackgroundColor3=Color3.fromRGB(40,40,40); line.BorderSizePixel=0; line.Parent=row
    if label then
        local lbl=Instance.new("TextLabel")
        lbl.Size=UDim2.new(0,120,1,0); lbl.Position=UDim2.new(0,6,0,0)
        lbl.BackgroundColor3=Color3.fromRGB(12,12,12); lbl.TextColor3=Color3.fromRGB(210,40,40)
        lbl.Font=Enum.Font.GothamBold; lbl.TextSize=11; lbl.Text="  "..label.."  "
        lbl.BorderSizePixel=0; lbl.Parent=row
    end
end

local function makeToggle(label, yOff)
    local btn=Instance.new("TextButton")
    btn.Size=UDim2.new(1,-20,0,48); btn.Position=UDim2.new(0,10,0,yOff)
    btn.BackgroundColor3=Color3.fromRGB(28,28,28); btn.Text=""
    btn.BorderSizePixel=0; btn.Parent=content
    Instance.new("UICorner",btn).CornerRadius=UDim.new(0,10)
    do local s=Instance.new("UIStroke",btn); s.Color=Color3.fromRGB(45,45,45); s.Thickness=1 end

    local lbl=Instance.new("TextLabel")
    lbl.Size=UDim2.new(1,-60,1,0); lbl.Position=UDim2.new(0,14,0,0)
    lbl.BackgroundTransparency=1; lbl.Text=label
    lbl.TextColor3=Color3.fromRGB(210,210,210); lbl.Font=Enum.Font.GothamBold
    lbl.TextSize=16; lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.Parent=btn

    local pill=Instance.new("Frame")
    pill.Size=UDim2.new(0,44,0,24); pill.Position=UDim2.new(1,-54,0.5,-12)
    pill.BackgroundColor3=Color3.fromRGB(50,50,50); pill.BorderSizePixel=0; pill.Parent=btn
    Instance.new("UICorner",pill).CornerRadius=UDim.new(1,0)

    local dot=Instance.new("Frame")
    dot.Size=UDim2.new(0,18,0,18); dot.Position=UDim2.new(0,3,0.5,-9)
    dot.BackgroundColor3=Color3.fromRGB(100,100,100); dot.BorderSizePixel=0; dot.Parent=pill
    Instance.new("UICorner",dot).CornerRadius=UDim.new(1,0)

    local function setOn(on)
        TweenService:Create(pill,TweenInfo.new(0.15),{BackgroundColor3=on and Color3.fromRGB(20,160,70) or Color3.fromRGB(50,50,50)}):Play()
        TweenService:Create(dot,TweenInfo.new(0.15),{BackgroundColor3=on and Color3.new(1,1,1) or Color3.fromRGB(100,100,100),
            Position=on and UDim2.new(1,-21,0.5,-9) or UDim2.new(0,3,0.5,-9)}):Play()
        lbl.TextColor3=on and Color3.new(1,1,1) or Color3.fromRGB(210,210,210)
    end
    return btn, setOn
end

local function makeCtrlBtn(text,xOff,w,yOff,parent)
    parent=parent or content
    local b=Instance.new("TextButton")
    b.Size=UDim2.new(0,w,0,40); b.Position=UDim2.new(0,xOff,0,yOff)
    b.BackgroundColor3=Color3.fromRGB(28,28,28); b.Text=text
    b.TextColor3=Color3.fromRGB(215,215,215); b.Font=Enum.Font.GothamBold
    b.TextSize=14; b.BorderSizePixel=0; b.Parent=parent
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,8)
    do local s=Instance.new("UIStroke",b); s.Color=Color3.fromRGB(45,45,45); s.Thickness=1 end
    return b
end

local function makeValDisplay(xOff,w,yOff,parent)
    parent=parent or content
    local d=Instance.new("TextLabel")
    d.Size=UDim2.new(0,w,0,40); d.Position=UDim2.new(0,xOff,0,yOff)
    d.BackgroundColor3=Color3.fromRGB(20,20,20); d.TextColor3=Color3.fromRGB(0,210,110)
    d.Font=Enum.Font.GothamBold; d.TextSize=18; d.BorderSizePixel=0; d.Parent=parent
    Instance.new("UICorner",d).CornerRadius=UDim.new(0,8)
    do local s=Instance.new("UIStroke",d); s.Color=Color3.fromRGB(0,80,45); s.Thickness=1 end
    return d
end

local BIG=50; local SMALL=44
local function buildRow(yOff,getVal,setVal,bigStep,smallStep,minVal,maxVal,fmt,parent)
    parent=parent or content; fmt=fmt or "%d"
    local totalW=FW-20; local valW=totalW-2*BIG-2*SMALL-8
    local display=makeValDisplay(PAD+BIG+2+SMALL+2, valW, yOff, parent)
    display.Text=string.format(fmt, getVal())
    local function refresh() display.Text=string.format(fmt,getVal()); updateStatus() end
    local b1=makeCtrlBtn("−"..bigStep,  PAD,                             BIG,   yOff,parent)
    local b2=makeCtrlBtn("−"..smallStep,PAD+BIG+2,                       SMALL, yOff,parent)
    local b3=makeCtrlBtn("+"..smallStep,PAD+BIG+2+SMALL+2+valW+2,        SMALL, yOff,parent)
    local b4=makeCtrlBtn("+"..bigStep,  PAD+BIG+2+SMALL+2+valW+2+SMALL+2,BIG,   yOff,parent)
    b1.TextSize=13; b2.TextSize=13; b3.TextSize=13; b4.TextSize=13
    b1.MouseButton1Click:Connect(function() setVal(math.clamp(getVal()-bigStep,  minVal,maxVal)); refresh() end)
    b2.MouseButton1Click:Connect(function() setVal(math.clamp(getVal()-smallStep,minVal,maxVal)); refresh() end)
    b3.MouseButton1Click:Connect(function() setVal(math.clamp(getVal()+smallStep,minVal,maxVal)); refresh() end)
    b4.MouseButton1Click:Connect(function() setVal(math.clamp(getVal()+bigStep,  minVal,maxVal)); refresh() end)
    return display
end

-- Layout
makeDivider(76, "MOVEMENT")
local flyBtn, flySetOn = makeToggle("Fly", 98)
local noclipBtn, noclipSetOn = makeToggle("NoClip", 152)

local flySection=Instance.new("Frame")
flySection.Size=UDim2.new(1,0,0,56); flySection.Position=UDim2.new(0,0,0,206)
flySection.BackgroundTransparency=1; flySection.Visible=false; flySection.Parent=content

local fsLbl=Instance.new("TextLabel")
fsLbl.Size=UDim2.new(1,-20,0,14); fsLbl.Position=UDim2.new(0,10,0,0)
fsLbl.BackgroundTransparency=1; fsLbl.Text="FLY SPEED"
fsLbl.TextColor3=Color3.fromRGB(210,40,40); fsLbl.Font=Enum.Font.GothamBold
fsLbl.TextSize=11; fsLbl.TextXAlignment=Enum.TextXAlignment.Left; fsLbl.Parent=flySection

buildRow(16, function() return cfg.flySpeed end, function(v) cfg.flySpeed=v end, 50,10,10,1000,"%d",flySection)

makeDivider(268,"CHARACTER")

local wsLbl=Instance.new("TextLabel")
wsLbl.Size=UDim2.new(1,-20,0,14); wsLbl.Position=UDim2.new(0,10,0,290)
wsLbl.BackgroundTransparency=1; wsLbl.Text="WALK SPEED"
wsLbl.TextColor3=Color3.fromRGB(210,40,40); wsLbl.Font=Enum.Font.GothamBold
wsLbl.TextSize=11; wsLbl.TextXAlignment=Enum.TextXAlignment.Left; wsLbl.Parent=content

buildRow(306, function() return cfg.walkSpeed end, function(v) cfg.walkSpeed=v; applyWalkSpeed() end, 20,5,1,500,"%d")

local jhLbl=Instance.new("TextLabel")
jhLbl.Size=UDim2.new(1,-20,0,14); jhLbl.Position=UDim2.new(0,10,0,352)
jhLbl.BackgroundTransparency=1; jhLbl.Text="JUMP HEIGHT"
jhLbl.TextColor3=Color3.fromRGB(210,40,40); jhLbl.Font=Enum.Font.GothamBold
jhLbl.TextSize=11; jhLbl.TextXAlignment=Enum.TextXAlignment.Left; jhLbl.Parent=content

buildRow(368, function() return cfg.jumpHeight end, function(v) cfg.jumpHeight=v; applyJumpHeight() end, 5,1,1,200,"%.1f")

flyBtn.MouseButton1Click:Connect(function()
    state.fly=not state.fly; flySetOn(state.fly); flySection.Visible=state.fly
    if state.fly then startFly(); if state.noclip then enableNoclip() end; notify("Fly ON  —  camera direction mode")
    else stopFly(); notify("Fly OFF  —  gravity restored") end
    updateStatus()
end)

noclipBtn.MouseButton1Click:Connect(function()
    state.noclip=not state.noclip; noclipSetOn(state.noclip)
    if state.noclip then enableNoclip() else disableNoclip() end
    notify(state.noclip and "NoClip ON" or "NoClip OFF"); updateStatus()
end)

minBtn.MouseButton1Click:Connect(function()
    state.minimized=not state.minimized
    local h=state.minimized and FH_MIN or FH_FULL
    TweenService:Create(frame,TweenInfo.new(0.2,Enum.EasingStyle.Quart),{Size=UDim2.new(0,FW,0,h)}):Play()
    content.Visible=not state.minimized; minBtn.Text=state.minimized and "+" or "—"
end)

updateStatus()
notify("Yang Kai Hub v4.0 Mobile loaded!")
