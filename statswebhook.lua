local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Webhook_URL = _G.Webhook or error("Webhook URL chưa được thiết lập!")
local DiscordID = _G.DiscordID or error("DiscordID chưa được thiết lập!")

local req = syn and syn.request or http_request or request
if not req then
    warn("Không thể gửi Webhook, không tìm thấy phương thức request phù hợp.")
    return
end

local player = Players.LocalPlayer
if not player then return end

local playerName = player.DisplayName or player.Name
local pg = player:WaitForChild("PlayerGui")

local statNames = {"STR", "DUR", "ST", "AG", "BS"}
local running, statsInterval, combatEnabled = true, 600, true
local inCombatAlertSent = false

local function sendWebhookMessage(title, message, tag)
    local payload = {
        content = tag and ("<@" .. DiscordID .. ">") or ("**📢 Cập nhật từ " .. playerName .. "**"),
        embeds = {{ title = title, description = message, color = 0x00ff00 }}
    }
    if tag then payload.allowed_mentions = { users = { DiscordID } } end
    req({
        Url = Webhook_URL,
        Method = "POST",
        Headers = { ["Content-Type"] = "application/json" },
        Body = HttpService:JSONEncode(payload)
    })
end

-- Khởi tạo webhook khi script chạy
sendWebhookMessage("📡 Webhook hoạt động", "✅ Webhook của **" .. playerName .. "** đã kết nối thành công!")

-- Hàm lấy giá trị stat trực tiếp từ TextLabel chứa "STAT: <số>"
local function getStatValue(statName)
    local statsChecker = pg:FindFirstChild("HUD")
                        and pg.HUD:FindFirstChild("Tabs")
                        and pg.HUD.Tabs:FindFirstChild("StatsChecker")
    if not statsChecker then return 0 end

    local statFrame = statsChecker:FindFirstChild(statName)
    if not statFrame then return 0 end

    local label = statFrame:FindFirstChildWhichIsA("TextLabel")
    if not label then return 0 end

    local text = label.Text
    local num = tonumber(text:match("(%d+)") or 0) or 0
    return num
end

local function calculateTotalStats()
    local total = 0
    for _, stat in ipairs(statNames) do
        total = total + getStatValue(stat)
    end
    return total
end

local function getServerInfo()
    local hud = pg:FindFirstChild("HUD")
    local miscs = hud and hud:FindFirstChild("Miscs")
    local stats = miscs and miscs:FindFirstChild("ServerStats")
    return stats and stats.ServerName and stats.ServerName.Text or "N/A",
           stats and stats.Uptime and stats.Uptime.Text or "N/A"
end

local function getMoney()
    local hud = pg:FindFirstChild("HUD")
    local bars = hud and hud:FindFirstChild("Bars")
    local mainHUD = bars and bars:FindFirstChild("MainHUD")
    local cash = mainHUD and mainHUD:FindFirstChild("Cash")
    return cash and cash.Text or "N/A"
end

local function sendStats()
    local total = calculateTotalStats()
    local msg = string.format("💪 **Tổng Stats**: %d\n\n", total)
    for _, stat in ipairs(statNames) do
        local v = getStatValue(stat)
        msg = msg .. string.format("%s: **%d**\n", stat, v)
    end
    local server, uptime = getServerInfo()
    msg = msg .. string.format("\n🖥️ %s\n⌛: %s\n💰: %s", server, uptime, getMoney())
    sendWebhookMessage("📊 Báo cáo Thống Kê", msg)
end

-- Vòng lặp gửi stats định kỳ\spawn(function()
    while task.wait(statsInterval) do
        if running then sendStats() end
    end
end)

local function addESP(target)
    if target:FindFirstChild("ESP_Highlight") then return end
    local hl = Instance.new("Highlight")
    hl.Name = "ESP_Highlight"
    hl.FillColor = Color3.new(1, 0, 0)
    hl.OutlineColor = Color3.new(1, 1, 0)
    hl.OutlineTransparency = 0
    hl.FillTransparency = 0.5
    hl.Parent = target

    local bg = Instance.new("BillboardGui")
    bg.Name = "NameESP"
    bg.Adornee = target
    bg.Size = UDim2.new(0, 100, 0, 50)
    bg.AlwaysOnTop = true
    bg.StudsOffset = Vector3.new(0, 3, 0)

    local tl = Instance.new("TextLabel", bg)
    tl.Size = UDim2.new(1, 0, 1, 0)
    tl.BackgroundTransparency = 1
    tl.Text = target.Name
    tl.TextColor3 = Color3.new(1, 1, 1)
    tl.TextStrokeTransparency = 0
    tl.TextScaled = true

    bg.Parent = target
end

-- Watcher NPC trong LivingBeings.Mobs
local mobsFolder = Workspace:WaitForChild("LivingBeings"):WaitForChild("Mobs")
mobsFolder.ChildAdded:Connect(function(mob)
    sendWebhookMessage(mob.Name .. " xuất hiện", "", true)
    addESP(mob)
end)
mobsFolder.ChildRemoved:Connect(function(mob)
    sendWebhookMessage(mob.Name .. " biến mất", "", true)
end)

-- Watcher Danielbody (nếu cần giữ)
local function onDanielbodyAppeared(d)
    sendWebhookMessage("Danielbody xuất hiện", "", true)
    addESP(d)
end

local function onDanielbodyRemoved(d)
    sendWebhookMessage("Danielbody biến mất", "", true)
end

local lb = Workspace:WaitForChild("LivingBeings")
lb.ChildAdded:Connect(function(child)
    if child.Name == "Danielbody" then onDanielbodyAppeared(child) end
end)
lb.ChildRemoved:Connect(function(child)
    if child.Name == "Danielbody" then onDanielbodyRemoved(child) end
end)
if lb:FindFirstChild("Danielbody") then
    onDanielbodyAppeared(lb.Danielbody)
end

local function checkCombatByAttribute()
    local lb = Workspace:FindFirstChild("LivingBeings")
    if not lb then return end
    local pl = lb:FindFirstChild(player.Name)
    if pl then
        local attackerName = pl:GetAttribute("WhoStartedCombat")
        if attackerName and not inCombatAlertSent then
            local attacker = lb:FindFirstChild(attackerName)
            local humanoid = attacker and attacker:FindFirstChildOfClass("Humanoid")
            local disp = (humanoid and humanoid.DisplayName) or "Unknown"
            sendWebhookMessage("⚠️ " .. playerName .. " đang bị tấn công ⚠️",
                "\nBởi: " .. disp .. ", " .. attackerName, true)
            inCombatAlertSent = true
        elseif not attackerName then
            inCombatAlertSent = false
        end
    else
        inCombatAlertSent = false
    end
end

spawn(function()
    while task.wait(1) do
        if combatEnabled then
            checkCombatByAttribute()
        end
    end
end)

game:BindToClose(function()
    sendWebhookMessage("🚫 Game Đóng", "Webhook của **" .. playerName .. "** đã dừng hoạt động", true)
end)
