local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

-- Two separate toggles: L (green, sets autoMacro) and K (blue, does NOT set autoMacro)
local autoClickL, autoClickK = false, false
local clickPosition = Vector2.new(mouse.X, mouse.Y)
local clickConnectionL, clickCoroutineK

-- Ensure attribute exists
if player:GetAttribute("autoMacro") == nil then
    player:SetAttribute("autoMacro", false)
end

-- Draggable click frame indicator
local ScreenGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
local ClickFrame = Instance.new("Frame", ScreenGui)
ClickFrame.Size = UDim2.new(0, 50, 0, 50)
ClickFrame.Position = UDim2.new(0, clickPosition.X, 0, clickPosition.Y)
ClickFrame.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
ClickFrame.Active = true
ClickFrame.Draggable = true

-- Update stored click position when moved
ClickFrame:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
    clickPosition = ClickFrame.AbsolutePosition
end)

-- Standard auto-click for L key (every 0.1s)
local function onRenderStepL()
    VirtualInputManager:SendMouseButtonEvent(clickPosition.X, clickPosition.Y, 1, true, game, 0)
    task.wait(0.1)
    VirtualInputManager:SendMouseButtonEvent(clickPosition.X, clickPosition.Y, 1, false, game, 0)
end

-- Patterned auto-click for K key: 600ms, 600ms, 2000ms between clicks
local function onClickPatternK()
    while autoClickK do
        -- First click
        VirtualInputManager:SendMouseButtonEvent(clickPosition.X, clickPosition.Y, 1, true, game, 0)
        task.wait(0.1)
        VirtualInputManager:SendMouseButtonEvent(clickPosition.X, clickPosition.Y, 1, false, game, 0)
        task.wait(0.6)
        if not autoClickK then break end
        -- Second click
        VirtualInputManager:SendMouseButtonEvent(clickPosition.X, clickPosition.Y, 1, true, game, 0)
        task.wait(0.1)
        VirtualInputManager:SendMouseButtonEvent(clickPosition.X, clickPosition.Y, 1, false, game, 0)
        task.wait(0.6)
        if not autoClickK then break end
        -- Third click
        VirtualInputManager:SendMouseButtonEvent(clickPosition.X, clickPosition.Y, 1, true, game, 0)
        task.wait(0.1)
        VirtualInputManager:SendMouseButtonEvent(clickPosition.X, clickPosition.Y, 1, false, game, 0)
        task.wait(2)
    end
end

-- Handle key presses
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.KeyCode == Enum.KeyCode.L then
        -- Prevent enabling L-click if K-click is active
        if autoClickK then return end
        autoClickL = not autoClickL
        player:SetAttribute("autoMacro", autoClickL)
        ClickFrame.BackgroundColor3 = autoClickL and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)

        if autoClickL then
            clickConnectionL = RunService.RenderStepped:Connect(onRenderStepL)
        elseif clickConnectionL then
            clickConnectionL:Disconnect()
            clickConnectionL = nil
        end

        StarterGui:SetCore("SendNotification", {
            Title = "Auto Clicker L",
            Text = autoClickL and "Bật Auto Click L" or "Tắt Auto Click L",
            Duration = 2
        })

    elseif input.KeyCode == Enum.KeyCode.K then
        -- Prevent enabling K-click if L-click is active
        if autoClickL then return end
        autoClickK = not autoClickK
        -- NOTE: Does NOT modify autoMacro attribute
        ClickFrame.BackgroundColor3 = autoClickK and Color3.fromRGB(0, 0, 255) or Color3.fromRGB(255, 0, 0)

        if autoClickK then
            clickCoroutineK = task.spawn(onClickPatternK)
        end

        StarterGui:SetCore("SendNotification", {
            Title = "Auto Clicker K",
            Text = autoClickK and "Bật Auto Click K" or "Tắt Auto Click K",
            Duration = 2
        })
    end
end)
