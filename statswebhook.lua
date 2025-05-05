local HttpService = game:GetService("HttpService")
local Players     = game:GetService("Players")
local Workspace   = game:GetService("Workspace")

local Webhook_URL = _G.Webhook    or error("Webhook URL chưa được thiết lập!")
local DiscordID   = _G.DiscordID  or error("DiscordID chưa được thiết lập!")

local req = syn and syn.request
         or http_request
         or request

local function safeRequest(options)
    if req then
        return req(options)
    else
        if not HttpService.HttpEnabled then
            warn("HTTP request disabled")
            return
        end
        return HttpService:PostAsync(
            options.Url,
            options.Body,
            Enum.HttpContentType.ApplicationJson
        )
    end
end

local function sendWebhookMessage(title, message, mention)
    local payload = {
        content = mention and ("<@"..DiscordID.."> ") or ("**📢 Thông báo từ AutoESP**"),
        embeds  = {{ title = title, description = message, color = 0x00ff00 }}
    }
    if mention then
        payload.allowed_mentions = { users = { DiscordID } }
    end
    safeRequest({
        Url     = Webhook_URL,
        Method  = "POST",
        Headers = { ["Content-Type"] = "application/json" },
        Body    = HttpService:JSONEncode(payload)
    })
end

-- Khởi tạo webhook
sendWebhookMessage("📡 AutoESP hoạt động", "Webhook đã kết nối thành công!", false)

-- Hàm thêm ESP cho Model
local function addESP(target)
    if not target:IsA("Model") then return end
    if target:FindFirstChild("ESP_Highlight") then return end
    local adorneePart = target.PrimaryPart
                        or target:FindFirstChild("HumanoidRootPart")
                        or target:FindFirstChildOfClass("BasePart")
    if not adorneePart then return end

    local hl = Instance.new("Highlight")
    hl.Name = "ESP_Highlight"
    hl.Adornee = adorneePart
    hl.FillColor = Color3.new(1, 0, 0)
    hl.OutlineColor = Color3.new(1, 1, 0)
    hl.FillTransparency = 0.5
    hl.OutlineTransparency = 0
    hl.Parent = target

    local bg = Instance.new("BillboardGui")
    bg.Name = "NameESP"
    bg.Adornee = adorneePart
    bg.Size = UDim2.new(0, 100, 0, 50)
    bg.AlwaysOnTop = true
    bg.StudsOffset = Vector3.new(0, 3, 0)
    bg.Parent = adorneePart

    local tl = Instance.new("TextLabel")
    tl.Size = UDim2.new(1, 0, 1, 0)
    tl.BackgroundTransparency = 1
    tl.TextColor3 = Color3.new(1, 1, 1)
    tl.TextStrokeTransparency = 0
    tl.TextScaled = true
    tl.Text = target.Name
    tl.Parent = bg
end

-- Xử lý Webhook khi Mob xuất hiện/biến mất và thêm ESP
local mobs = Workspace:WaitForChild("LivingBeings"):WaitForChild("Mobs")
for _, mob in ipairs(mobs:GetChildren()) do
    addESP(mob)
    sendWebhookMessage(mob.Name .. " xuất hiện", "", true)
end
mobs.ChildAdded:Connect(function(m)
    addESP(m)
    sendWebhookMessage(m.Name .. " xuất hiện", "", true)
end)
mobs.ChildRemoved:Connect(function(m)
    sendWebhookMessage(m.Name .. " biến mất", "", true)
end)

-- Theo dõi Boss Danielbody
local living = Workspace:WaitForChild("LivingBeings")
local function onDaniel(child, added)
    if child.Name == "Danielbody" then
        if added then addESP(child) end
        sendWebhookMessage("Danielbody " .. (added and "xuất hiện" or "biến mất"), "", true)
    end
end
living.ChildAdded:Connect(function(c) onDaniel(c, true) end)
living.ChildRemoved:Connect(function(c) onDaniel(c, false) end)
if living:FindFirstChild("Danielbody") then
    onDaniel(living:FindFirstChild("Danielbody"), true)
end

-- Phát hiện combat qua polling attribute
local inCombatAlertSent = false
local function checkCombatByAttribute()
    local lb = Workspace:FindFirstChild("LivingBeings")
    if not lb then return end
    local pl = lb:FindFirstChild(Players.LocalPlayer.Name)
    if pl then
        local attackerName = pl:GetAttribute("WhoStartedCombat")
        if attackerName and attackerName ~= "" and not inCombatAlertSent then
            local attacker = lb:FindFirstChild(attackerName)
            local humanoid = attacker and attacker:FindFirstChildOfClass("Humanoid")
            local disp = (humanoid and humanoid.DisplayName) or "Unknown"
            sendWebhookMessage("⚠️ " .. Players.LocalPlayer.DisplayName .. " đang bị tấn công ⚠️", "Bởi: " .. disp .. ", " .. attackerName, true)
            inCombatAlertSent = true
        elseif not attackerName or attackerName == "" then
            inCombatAlertSent = false
        end
    else
        inCombatAlertSent = false
    end
end
spawn(function()
    while task.wait(1) do
        checkCombatByAttribute()
    end
end)
