-- Auto Clicker Cải Tiến cho Roblox

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Khởi tạo attribute nếu chưa có
if player:GetAttribute("autoMacro") == nil then
    player:SetAttribute("autoMacro", false)
end

-- Tạo ScreenGui và ClickFrame
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AutoClickGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local clickFrame = Instance.new("Frame")
clickFrame.Name = "ClickFrame"
clickFrame.Size = UDim2.new(0, 50, 0, 50)
clickFrame.Position = UDim2.new(0, 100, 0, 100)
clickFrame.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
clickFrame.Active = true
clickFrame.Draggable = true
clickFrame.Parent = screenGui

-- Label hiển thị trạng thái
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, 0, 0.3, 0)
statusLabel.Position = UDim2.new(0, 0, -0.3, 0)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Tắt"
statusLabel.Font = Enum.Font.SourceSansBold
statusLabel.TextSize = 14
statusLabel.TextColor3 = Color3.new(1, 1, 1)
statusLabel.Parent = clickFrame

-- Nút bật/tắt bằng GUI
local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(1, 0, 1, 0)
toggleButton.BackgroundTransparency = 0.5
toggleButton.Text = ""
toggleButton.Parent = clickFrame

toggleButton.MouseButton1Click:Connect(function()
    -- Tương tự như nhấn phím L
    toggleAutoClick()
end)

-- Biến điều khiển
local autoClick = player:GetAttribute("autoMacro")
local clickInterval = 0.1  -- giây
local lastClickTime = 0
local clickPosition = clickFrame.AbsolutePosition
local clickConnection
local debounceKey = false

-- Hàm bật/tắt auto click
function toggleAutoClick()
    autoClick = not autoClick
    player:SetAttribute("autoMacro", autoClick)
    -- Cập nhật màu và label
    clickFrame.BackgroundColor3 = autoClick and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
    statusLabel.Text = autoClick and "Bật" or "Tắt"

    -- Thông báo
    StarterGui:SetCore("SendNotification", {
        Title = "Auto Clicker",
        Text = autoClick and "Đã bật Auto Click" or "Đã tắt Auto Click",
        Duration = 2,
    })

    -- Kết nối hoặc ngắt kết nối RenderStepped
    if autoClick then
        clickConnection = RunService.RenderStepped:Connect(onRenderStep)
    elseif clickConnection then
        clickConnection:Disconnect()
        clickConnection = nil
    end
end

-- Hàm thực hiện click
function onRenderStep()
    local now = tick()
    if now - lastClickTime >= clickInterval then
        clickPosition = clickFrame.AbsolutePosition + Vector2.new(clickFrame.AbsoluteSize.X/2, clickFrame.AbsoluteSize.Y/2)
        VirtualInputManager:SendMouseButtonEvent(clickPosition.X, clickPosition.Y, 1, true, game, 0)
        VirtualInputManager:SendMouseButtonEvent(clickPosition.X, clickPosition.Y, 1, false, game, 0)
        lastClickTime = now
    end
end

-- Cập nhật vị trí khi kéo Frame
clickFrame:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
    clickPosition = clickFrame.AbsolutePosition + Vector2.new(clickFrame.AbsoluteSize.X/2, clickFrame.AbsoluteSize.Y/2)
end)

-- Bắt sự kiện phím L (với debounce)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.L and not debounceKey then
        debounceKey = true
        toggleAutoClick()
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.L then
        debounceKey = false
    end
end)

-- Khởi tạo trạng thái ban đầu
if autoClick then
    toggleAutoClick()
end
