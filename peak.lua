-- LocalScript in StarterPlayerScripts

local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local BG_ASSET_ID = "rbxassetid://123795358585660"

local guiTable = {}
local guiVisible = true

local function createStatesDisplay(player)
    if player == LocalPlayer then return end

    -- Đợi model trong LivingBeings khớp tên player
    local living = workspace:WaitForChild("LivingBeings")
    local char   = living:WaitForChild(player.Name, 5)
    if not char then return end

    local head     = char:FindFirstChild("Head")
    local humanoid = char:FindFirstChild("Humanoid")
    if not head or not humanoid then return end

    -- Xoá GUI cũ nếu tồn tại
    local oldGui = head:FindFirstChild("StatesDisplay")
    if oldGui then oldGui:Destroy() end

    -- Tạo BillboardGui (50% size)
    local gui = Instance.new("BillboardGui", head)
    gui.Name        = "StatesDisplay"
    gui.Adornee     = head
    gui.AlwaysOnTop = true
    gui.StudsOffset = Vector3.new(0, 1, 0)
    gui.MaxDistance = 100
    gui.Size        = UDim2.new(2, 0, 1, 0)

    -- Factory Bar
    local function makeBar(parent, color)
        local bar = Instance.new("Frame", parent)
        bar.Name             = "Bar"
        bar.Size             = UDim2.new(0.925, 0, 1, 0)
        bar.Position         = UDim2.new(0.04, 0, 0, 0)
        bar.BackgroundColor3 = color
        bar.ZIndex           = 1
        return bar
    end

    -- BG image (ZIndex = 2)
    local BG = Instance.new("ImageLabel", gui)
    BG.Name                   = "BG"
    BG.Size                   = UDim2.new(1,0,1,0)
    BG.Position               = UDim2.new(0,0,0,0)
    BG.BackgroundTransparency = 1
    BG.Image                  = BG_ASSET_ID
    BG.ZIndex                 = 2

    -- Factory Section (Frame + Bar + Label)
    local function makeSection(name, ypos)
        local frame = Instance.new("Frame", gui)
        frame.Name                   = name
        frame.Size                   = UDim2.new(1,0,0.35,0)
        frame.Position               = UDim2.new(0,0,ypos,0)
        frame.BackgroundTransparency = 1
        frame.ZIndex                 = 2

        local bar = makeBar(frame, name == "HP"
            and Color3.fromRGB(200,22,22)
            or Color3.fromRGB(8,177,255)
        )

        local label = Instance.new("TextLabel", frame)
        label.Name                   = "Current"
        label.Size                   = UDim2.new(1,0,1,0)
        label.Position               = UDim2.new(0,0,0.05,0)
        label.BackgroundTransparency = 1
        label.TextColor3             = Color3.new(1,1,1)
        label.TextScaled             = true
        label.Font                   = Enum.Font.SourceSansBold
        label.TextStrokeTransparency = 0
        label.ZIndex                 = 3

        return bar, label
    end

    local HPBar, HPLabel             = makeSection("HP", 0.1)
    local StaminaBar, StaminaLabel   = makeSection("Stamina", 0.5)

    -- Cập nhật HP
    local function updateHP()
        local pct = math.clamp(humanoid.Health / humanoid.MaxHealth * 100, 0, 100)
        HPLabel.Text = ("%d%%"):format(pct)
        HPBar.Size   = UDim2.new(math.clamp(humanoid.Health / humanoid.MaxHealth,0,1)*0.925,0,1,0)
    end
    humanoid.HealthChanged:Connect(updateHP)

    -- Cập nhật Stamina (lấy từ Players[player.Name])
    local function updateStamina()
        -- Lấy lại player object để chắc chắn khớp tên model
        local plr = Players:FindFirstChild(player.Name)
        local stam = 0
        if plr then
            stam = math.clamp(plr:GetAttribute("Stamina") or 0, 0, 100)
        end
        StaminaLabel.Text = ("%d%%"):format(stam)
        StaminaBar.Size   = UDim2.new((stam/100)*0.925,0,1,0)
    end
    -- Kết nối và gọi khởi tạo
    player:GetAttributeChangedSignal("Stamina"):Connect(updateStamina)
    updateHP()
    updateStamina()

    guiTable[player] = gui
end

-- Tạo GUI cho players có sẵn và khi respawn
for _, pl in ipairs(Players:GetPlayers()) do
    pl.CharacterAdded:Connect(function() createStatesDisplay(pl) end)
    if pl.Character then createStatesDisplay(pl) end
end
Players.PlayerAdded:Connect(function(pl)
    pl.CharacterAdded:Connect(function() createStatesDisplay(pl) end)
end)

-- Phím J bật/tắt
UserInputService.InputBegan:Connect(function(input, gp)
    if gp or input.KeyCode ~= Enum.KeyCode.J then return end
    guiVisible = not guiVisible
    for _, gui in pairs(guiTable) do
        if gui then gui.Enabled = guiVisible end
    end
end)
