local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local clickPosition = Vector2.new(mouse.X, mouse.Y)
local clickConnection = nil
local patternThread = nil

-- hai trạng thái riêng biệt
local autoClickL = false
local autoPatternK = false

-- GUI frame để kéo thả và đổi màu
local ScreenGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
local ClickFrame = Instance.new("Frame", ScreenGui)
ClickFrame.Size = UDim2.new(0, 50, 0, 50)
ClickFrame.Position = UDim2.new(0, clickPosition.X, 0, clickPosition.Y)
ClickFrame.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
ClickFrame.Active, ClickFrame.Draggable = true, true

ClickFrame:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
    clickPosition = ClickFrame.AbsolutePosition
end)

-- hàm click đơn giản (dùng cho L)
local function doClick()
    VirtualInputManager:SendMouseButtonEvent(clickPosition.X, clickPosition.Y, 1, true, game, 0)
    task.wait(0.1)
    VirtualInputManager:SendMouseButtonEvent(clickPosition.X, clickPosition.Y, 1, false, game, 0)
end

-- vòng lặp auto click cho L
local function onRenderStep()
    if autoClickL then
        doClick()
    end
end

-- vòng lặp cho pattern K: click -> wait 600ms -> click -> wait 600ms -> click -> wait 2000ms
local function patternLoop()
    while autoPatternK do
        -- lần 1
        VirtualInputManager:SendMouseButtonEvent(clickPosition.X, clickPosition.Y, 1, true, game, 0)
        VirtualInputManager:SendMouseButtonEvent(clickPosition.X, clickPosition.Y, 1, false, game, 0)
        task.wait(0.6)
        -- lần 2
        VirtualInputManager:SendMouseButtonEvent(clickPosition.X, clickPosition.Y, 1, true, game, 0)
        VirtualInputManager:SendMouseButtonEvent(clickPosition.X, clickPosition.Y, 1, false, game, 0)
        task.wait(0.6)
        -- lần 3
        VirtualInputManager:SendMouseButtonEvent(clickPosition.X, clickPosition.Y, 1, true, game, 0)
        VirtualInputManager:SendMouseButtonEvent(clickPosition.X, clickPosition.Y, 1, false, game, 0)
        task.wait(2.0)
    end
end

-- Xử lý nhấn phím
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    -- phím L: auto click nhanh
    if input.KeyCode == Enum.KeyCode.L then
        -- không cho bật nếu K đang bật
        if not autoClickL and autoPatternK then
            StarterGui:SetCore("SendNotification", {
                Title = "Auto Clicker",
                Text = "Không thể bật Auto Click khi Auto Pattern (K) đang bật!",
                Duration = 2
            })
            return
        end

        autoClickL = not autoClickL
        -- bật/tắt RenderStepped
        if autoClickL then
            clickConnection = RunService.RenderStepped:Connect(onRenderStep)
            ClickFrame.BackgroundColor3 = Color3.fromRGB(0, 255, 0)  -- xanh lá
            player:SetAttribute("autoMacro", true)
            StarterGui:SetCore("SendNotification", {
                Title = "Auto Clicker",
                Text = "Bật Auto Click (L)",
                Duration = 2
            })
        else
            if clickConnection then
                clickConnection:Disconnect()
                clickConnection = nil
            end
            ClickFrame.BackgroundColor3 = Color3.fromRGB(255, 0, 0)  -- đỏ
            player:SetAttribute("autoMacro", false)
            StarterGui:SetCore("SendNotification", {
                Title = "Auto Clicker",
                Text = "Tắt Auto Click (L)",
                Duration = 2
            })
        end

    -- phím K: pattern 3 click
    elseif input.KeyCode == Enum.KeyCode.K then
        -- không cho bật nếu L đang bật
        if not autoPatternK and autoClickL then
            StarterGui:SetCore("SendNotification", {
                Title = "Auto Pattern",
                Text = "Không thể bật Auto Pattern khi Auto Click (L) đang bật!",
                Duration = 2
            })
            return
        end

        autoPatternK = not autoPatternK
        if autoPatternK then
            -- khởi chạy thread loop
            patternThread = task.spawn(patternLoop)
            ClickFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 255)  -- xanh dương
            StarterGui:SetCore("SendNotification", {
                Title = "Auto Pattern",
                Text = "Bật Auto Pattern (K)",
                Duration = 2
            })
        else
            -- dừng thread loop tự động qua biến autoPatternK = false
            ClickFrame.BackgroundColor3 = Color3.fromRGB(255, 0, 0)  -- đỏ
            StarterGui:SetCore("SendNotification", {
                Title = "Auto Pattern",
                Text = "Tắt Auto Pattern (K)",
                Duration = 2
            })
        end
    end
end)
