local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local autoClick, clickPosition, clickConnection = false, Vector2.new(mouse.X, mouse.Y), nil

if not player:GetAttribute("autoMacro") then
    player:SetAttribute("autoMacro", false)
end

local ScreenGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
local ClickFrame = Instance.new("Frame", ScreenGui)
ClickFrame.Size = UDim2.new(0, 50, 0, 50)
ClickFrame.Position = UDim2.new(0, clickPosition.X, 0, clickPosition.Y)
ClickFrame.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
ClickFrame.Active, ClickFrame.Draggable = true, true

local function onRenderStep()
    if autoClick then
        VirtualInputManager:SendMouseButtonEvent(clickPosition.X, clickPosition.Y, 1, true, game, 0)
        task.wait(0.1)
        VirtualInputManager:SendMouseButtonEvent(clickPosition.X, clickPosition.Y, 1, false, game, 0)
    end
end

ClickFrame:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
    clickPosition = ClickFrame.AbsolutePosition
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.L then
        autoClick = not autoClick
        player:SetAttribute("autoMacro", autoClick)
        ClickFrame.BackgroundColor3 = autoClick and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
        if autoClick then
            clickConnection = RunService.RenderStepped:Connect(onRenderStep)
        elseif clickConnection then
            clickConnection:Disconnect()
            clickConnection = nil
        end
        StarterGui:SetCore("SendNotification", {Title = "Auto Clicker", Text = autoClick and "Bật Auto Click" or "Tắt Auto Click", Duration = 2})
    end
end)
