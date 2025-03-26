local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Webhook_URL = _G.Webhook or "DEFAULT_WEBHOOK_URL"
local DiscordID = _G.DiscordID or "DEFAULT_DISCORD_ID"

local req = syn and syn.request or http_request or request
if not req then return end

local player = Players.LocalPlayer
if not player then return end

local playerName = player.DisplayName or player.Name
local pg = player:FindFirstChild("PlayerGui")
if not pg then return end

local statNames = {"STR", "DUR", "ST", "AG", "BS"}
local rankTable = {
    {"F-",0},{"F",26},{"F+",51},{"E-",76},{"E",126},{"E+",176},{"D-",226},{"D",326},
    {"D+",426},{"C-",526},{"C",726},{"C+",926},{"B-",1126},{"B",1426},{"B+",1726},
    {"A-",2026},{"A",2751},{"A+",3476},{"S-",4201},{"S",5201},{"S+",6201},{"SS-",7201},
    {"SS",8707},{"SS+",10001},{"SSS-",12501},{"SSS",15001},{"SSS+",17501},{"X-",20001},
    {"X",24001},{"X+",28000},{"XX-",32001},{"XX",38001},{"XX+",44001},{"XXX-",50001},
    {"XXX",60001},{"XXX+",70001},{"Z-",80001},{"Z",95000},{"Z+",110001},{"ZZ-",125001},
    {"ZZ",145001},{"ZZ+",165001},{"ZZZ-",185001},{"ZZZ",210001},{"ZZZ+",235001},{"?",260000},
    {"??",500001},{"???",750000}
}
local running, statsInterval, combatEnabled = true, 600, true
local inCombatAlertSent = false

local function sendWebhookMessage(title, message, tag)
    local payload = {
        content = tag and "<@" .. DiscordID .. ">" or "**📢 Cập nhật từ " .. playerName .. "**",
        embeds = {{
            title = title,
            description = message,
            color = 0x00ff00
        }}
    }
    if tag then
        -- Thay vì tag everyone, ta chỉ cho phép tag người dùng có DiscordID cụ thể
        payload.allowed_mentions = {users = {DiscordID}}
    end
    req({
        Url = Webhook_URL,
        Method = "POST",
        Headers = {["Content-Type"] = "application/json"},
        Body = HttpService:JSONEncode(payload)
    })
end

sendWebhookMessage("📡 Webhook hoạt động", "✅ Webhook của **" .. playerName .. "** đã kết nối thành công!")

local function getStatValue(s)
    local hud = pg:FindFirstChild("HUD")
    local amt = hud and hud:FindFirstChild("Tabs") and hud.Tabs:FindFirstChild("StatsChecker")
               and hud.Tabs.StatsChecker:FindFirstChild(s) and hud.Tabs.StatsChecker[s]:FindFirstChild("AMT")
    return amt and tonumber(amt.Text) or 0
end

local function calculateTotalStats()
    local t = 0
    for _, s in ipairs(statNames) do
        t = t + getStatValue(s)
    end
    return t
end

local function getRank(v)
    local cur, nxt, diff = "F-", "F", math.huge
    for i = 1, #rankTable do
        local r, thr = rankTable[i][1], rankTable[i][2]
        if v >= thr then
            cur = r
        else
            nxt, diff = r, thr - v
            break
        end
    end
    return cur, nxt, diff
end

local function getServerInfo()
    local hud = pg:FindFirstChild("HUD")
    local miscs = hud and hud:FindFirstChild("Miscs")
    local stats = miscs and miscs:FindFirstChild("ServerStats")
    local sName = stats and stats:FindFirstChild("ServerName")
    local up = stats and stats:FindFirstChild("Uptime")
    return sName and sName.Text or "N/A", up and up.Text or "N/A"
end

local function getMoney()
    local hud = pg:FindFirstChild("HUD")
    local bars = hud and hud:FindFirstChild("Bars")
    local main = bars and bars:FindFirstChild("MainHUD")
    local cash = main and main:FindFirstChild("Cash")
    return cash and cash.Text or "N/A"
end

local function sendStats()
    local total = calculateTotalStats()
    local cur, nxt, need = getRank(total)
    local msg = string.format("💪 **Tổng Stats**: %d\n🏆 **Rank hiện tại**: %s\n🔜 **Rank tiếp theo**: %s *(Cần +%d stats)*\n\n", total, cur, nxt, need)
    for _, s in ipairs(statNames) do
        local v = getStatValue(s)
        local sr, nr, nd = getRank(v)
        msg = msg .. string.format("%s: **%d** *(%s → %s cần +%d)*\n", s, v, sr, nr, nd)
    end
    local server, uptime = getServerInfo()
    local money = getMoney()
    msg = msg .. string.format("\n🖥️ %s\n⌛: %s\n💰: %s", server, uptime, money)
    sendWebhookMessage("📊 Báo cáo Thống Kê", msg)
end

local function onChatMessage(_, m)
    local msg = m:lower()
    if msg == "/e stats" then
        sendStats()
    elseif msg:sub(1, 12) == "/e statstime" then
        local t = tonumber(msg:match("%d+"))
        if t and t > 0 then
            statsInterval = t * 60
            sendWebhookMessage("⏳ Cập nhật thời gian gửi", "📊 Thời gian gửi stats đã được đặt thành " .. t .. " phút.")
        end
    elseif msg == "/e stop" then
        running = false
        sendWebhookMessage("🛑 Dừng gửi stats", "📊 Việc gửi stats đã tạm dừng.")
    elseif msg == "/e start" then
        running = true
        sendWebhookMessage("▶️ Bắt đầu gửi stats", "📊 Việc gửi stats đã được khởi động lại.")
    elseif msg == "/e combat on" then
        combatEnabled = true
        sendWebhookMessage("▶️ Combat Check", playerName .. " combat check đã được bật.", true)
    elseif msg == "/e combat off" then
        combatEnabled = false
        sendWebhookMessage("🛑 Combat Check", playerName .. " combat check đã được tắt.", true)
    end
end

for _, plr in pairs(game:GetService("Players"):GetPlayers()) do
    plr.Chatted:Connect(function(m) onChatMessage(plr, m) end)
end

spawn(function()
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

local function onDanielbodyAppeared(d)
    sendWebhookMessage("Danielbody xuất hiện", "", true)
    addESP(d)
end

local function onDanielbodyRemoved(d)
    sendWebhookMessage("Danielbody biến mất", "", true)
end

local lb = Workspace:WaitForChild("LivingBeings")
lb.ChildAdded:Connect(function(c)
    if c.Name == "Danielbody" then onDanielbodyAppeared(c) end
end)
lb.ChildRemoved:Connect(function(c)
    if c.Name == "Danielbody" then onDanielbodyRemoved(c) end
end)
local existing = lb:FindFirstChild("Danielbody")
if existing then onDanielbodyAppeared(existing) end

local function checkCombatByAttribute()
    local lb = Workspace:FindFirstChild("LivingBeings")
    if lb then
        local pl = lb:FindFirstChild(player.Name)
        if pl then
            local attackerName = pl:GetAttribute("WhoStartedCombat")
            if attackerName then
                if not inCombatAlertSent then
                    local attacker = lb:FindFirstChild(attackerName)
                    local humanoid = attacker and attacker:FindFirstChildOfClass("Humanoid")
                    local disp = (humanoid and humanoid.DisplayName) or "Unknown"
                    sendWebhookMessage("⚠️" .. playerName .. " đang bị tấn công⚠️", "\nBởi: " .. disp .. ", " .. tostring(attackerName), true)
                    inCombatAlertSent = true
                end
            else
                inCombatAlertSent = false
            end
        else
            inCombatAlertSent = false
        end
    end
end

spawn(function()
    while task.wait(1) do
        checkCombatByAttribute()
    end
end)

game:BindToClose(function()
    sendWebhookMessage("🚫 Game Đóng", "Webhook của **" .. playerName .. "** đã dừng hoạt động", true)
end)
