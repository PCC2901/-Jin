local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local clickPosition = Vector2.new(mouse.X, mouse.Y)
local clickConnection, patternThread = nil, nil
local autoClickL, autoPatternK = false, false

if not player:GetAttribute("autoMacro") then
    player:SetAttribute("autoMacro", false)
end

local ScreenGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
local ClickFrame = Instance.new("Frame", ScreenGui)
ClickFrame.Size = UDim2.new(0, 50, 0, 50)
ClickFrame.Position = UDim2.new(0, clickPosition.X, 0, clickPosition.Y)
ClickFrame.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
ClickFrame.Active, ClickFrame.Draggable = true, true

ClickFrame:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
    clickPosition = ClickFrame.AbsolutePosition
end)

local function doClick(button)
    VirtualInputManager:SendMouseButtonEvent(clickPosition.X, clickPosition.Y, button, true, game, 0)
    task.wait(0.05)
    VirtualInputManager:SendMouseButtonEvent(clickPosition.X, clickPosition.Y, button, false, game, 0)
end

local function onRenderStep()
    if autoClickL then
        doClick(1)
    end
end

local function patternLoop()
    while autoPatternK do
        doClick(0)
        task.wait(0.6)
        doClick(0)
        task.wait(0.6)
        doClick(0)
        task.wait(2.0)
    end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.KeyCode == Enum.KeyCode.L then
        if not autoClickL and autoPatternK then
            StarterGui:SetCore("SendNotification", {Title = "Auto Clicker", Text = "Không thể bật Auto Click khi Auto Pattern (K) đang bật!", Duration = 2})
            return
        end
        autoClickL = not autoClickL
        if autoClickL then
            clickConnection = RunService.RenderStepped:Connect(onRenderStep)
            ClickFrame.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
            player:SetAttribute("autoMacro", true)
            StarterGui:SetCore("SendNotification", {Title = "Auto Clicker", Text = "Bật Auto Click (L) [Right]", Duration = 2})
        else
            if clickConnection then clickConnection:Disconnect() clickConnection = nil end
            ClickFrame.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
            player:SetAttribute("autoMacro", false)
            StarterGui:SetCore("SendNotification", {Title = "Auto Clicker", Text = "Tắt Auto Click (L)", Duration = 2})
        end

    elseif input.KeyCode == Enum.KeyCode.K then
        if not autoPatternK and autoClickL then
            StarterGui:SetCore("SendNotification", {Title = "Auto Pattern", Text = "Không thể bật Auto Pattern khi Auto Click (L) đang bật!", Duration = 2})
            return
        end
        autoPatternK = not autoPatternK
        if autoPatternK then
            patternThread = task.spawn(patternLoop)
            ClickFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 255)
            StarterGui:SetCore("SendNotification", {Title = "Auto Pattern", Text = "Bật Auto Pattern (K) [Left]", Duration = 2})
        else
            ClickFrame.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
            StarterGui:SetCore("SendNotification", {Title = "Auto Pattern", Text = "Tắt Auto Pattern (K)", Duration = 2})
        end
    end
end)
