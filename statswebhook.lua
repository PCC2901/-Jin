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

local player = Players.LocalPlayer
if not player then return end
local playerName = (player.DisplayName ~= "" and player.DisplayName) or player.Name

local pg = player:WaitForChild("PlayerGui")
repeat task.wait() until pg:FindFirstChild("HUD")
local HUD = pg:WaitForChild("HUD")
local StatsChecker = HUD:WaitForChild("Tabs"):WaitForChild("StatsChecker")

local statNames      = {"STR", "DUR", "ST", "AG", "BS"}
local statsInterval  = 600
local combatEnabled  = true
local inCombatAlert  = false

local function sendWebhookMessage(title, message, mention)
    local payload = {
        content = mention and ("<@"..DiscordID.."> ") or ("**📢 Cập nhật từ "..playerName.."**"),
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

sendWebhookMessage("📡 Webhook hoạt động", "✅ Kết nối thành công!", false)

local function getStatValue(stat)
    local frame = StatsChecker:FindFirstChild(stat)
    if not frame then return 0 end
    local lbl  = frame:FindFirstChildWhichIsA("TextLabel")
    if not lbl then return 0 end
    local text = lbl.Text
    -- lấy số cuối cùng trong chuỗi, hỗ trợ float
    local num = text:match("([%d%.]+)%s*$")
    return tonumber(num) or 0
end

local function getStatRaw(stat)
    local frame = StatsChecker:FindFirstChild(stat)
    if not frame then return "N/A" end
    local lbl  = frame:FindFirstChildWhichIsA("TextLabel")
    return lbl and lbl.Text or "N/A"
end

local function calculateTotal()
    local sum = 0
    for _, name in ipairs(statNames) do
        sum = sum + getStatValue(name)
    end
    return sum
end

local function getServerInfo()
    local miscs = HUD:FindFirstChild("Miscs")
    local stats = miscs and miscs:FindFirstChild("ServerStats")
    local serverName = stats and stats:FindFirstChild("ServerName") and stats.ServerName.Text or "N/A"
    local uptime     = stats and stats:FindFirstChild("Uptime")     and stats.Uptime.Text     or "N/A"
    return serverName, uptime
end

local function getMoney()
    local bars   = HUD:FindFirstChild("Bars")
    local main   = bars and bars:FindFirstChild("MainHUD")
    local cashUI = main and main:FindFirstChild("Cash")
    return cashUI and cashUI.Text or "N/A"
end

local function sendStats()
    local total = calculateTotal()
    local msg   = string.format("💪 **Tổng Stats**: %.2f\n\n", total)
    for _, name in ipairs(statNames) do
        local raw = getStatRaw(name)
        msg = msg .. string.format("%s: `%s`\n", name, raw)
    end
    local server, up = getServerInfo()
    msg = msg .. string.format("\n🖥️ %s\n⌛: %s\n💰: %s", server, up, getMoney())
    sendWebhookMessage("📊 Báo cáo Thống Kê", msg, false)
end

spawn(function()
    while task.wait(statsInterval) do
        sendStats()
    end
end)

local function addESP(target)
    -- kiểm tra đối tượng hợp lệ
    if not (target:IsA("Model") or target:IsA("BasePart")) then return end
    if target:FindFirstChild("ESP_Highlight") then return end

    -- highlight
    local hl = Instance.new("Highlight")
    hl.Name  = "ESP_Highlight"
    hl.Adornee = target:IsA("Model") and target or target
    hl.FillColor    = Color3.new(1, 0, 0)
    hl.OutlineColor = Color3.new(1, 1, 0)
    hl.FillTransparency    = 0.5
    hl.OutlineTransparency = 0
    hl.Parent = target

    -- billboard name
    local adorneePart = target:IsA("Model") and (target.PrimaryPart or target:FindFirstChild("HumanoidRootPart") or target:FindFirstChildOfClass("BasePart"))
                        or (target:IsA("BasePart") and target)
    if not adorneePart then return end
    local bg = Instance.new("BillboardGui")
    bg.Name        = "NameESP"
    bg.Adornee     = adorneePart
    bg.Parent      = adorneePart
    bg.Size        = UDim2.new(0,100,0,50)
    bg.AlwaysOnTop = true
    bg.StudsOffset = Vector3.new(0,3,0)

    local tl = Instance.new("TextLabel")
    tl.Size                   = UDim2.new(1,0,1,0)
    tl.BackgroundTransparency = 1
    tl.TextColor3            = Color3.new(1,1,1)
    tl.TextStrokeTransparency = 0
    tl.TextScaled            = true
    tl.Text                   = target.Name
    tl.Parent                 = bg
end

-- theo dõi và thêm ESP cho mob mới
local mobs = Workspace:WaitForChild("LivingBeings"):WaitForChild("Mobs")
mobs.ChildAdded:Connect(addESP)

-- Danielbody
local living = Workspace:WaitForChild("LivingBeings")
local function onDaniel(child, added)
    if child.Name == "Danielbody" then
        if added then addESP(child) end
        sendWebhookMessage("Danielbody "..(added and "xuất hiện" or "biến mất"), "", true)
    end
end
living.ChildAdded:Connect(function(c) onDaniel(c, true) end)
living.ChildRemoved:Connect(function(c) onDaniel(c, false) end)
if living:FindFirstChild("Danielbody") then onDaniel(living:FindFirstChild("Danielbody"), true) end

-- combat detection
local function handleCombatChanged(plModel)
    plModel:GetAttributeChangedSignal("WhoStartedCombat"):Connect(function()
        local attacker = plModel:GetAttribute("WhoStartedCombat")
        if attacker and attacker ~= "" and not inCombatAlert then
            local ent = living:FindFirstChild(attacker)
            local disp = (ent and ent:FindFirstChildOfClass("Humanoid") and ent.DisplayName) or "Unknown"
            sendWebhookMessage("⚠️ "..playerName.." đang bị tấn công ⚠️", "Bởi: "..disp..", "..attacker, true)
            inCombatAlert = true
        elseif not attacker or attacker == "" then
            inCombatAlert = false
        end
    end)
end
living.ChildAdded:Connect(function(c) if c.Name == player.Name then handleCombatChanged(c) end end)
if living:FindFirstChild(player.Name) then handleCombatChanged(living:FindFirstChild(player.Name)) end

-- client close
player.AncestryChanged:Connect(function(_, parent)
    if not parent then
        sendWebhookMessage("🚫 Người chơi rời game", playerName.." đã thoát khỏi trò chơi.", true)
    end
end)
