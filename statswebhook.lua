-- Nhập các service cần thiết
local HttpService = game:GetService("HttpService")
local Players     = game:GetService("Players")
local Workspace   = game:GetService("Workspace")

-- Lấy cấu hình từ _G, báo lỗi nếu thiếu
local Webhook_URL = _G.Webhook    or error("Webhook URL chưa được thiết lập!")
local DiscordID   = _G.DiscordID  or error("DiscordID chưa được thiết lập!")

-- Thiết lập phương thức gửi HTTP
local req = syn and syn.request
         or http_request
         or request

local function safeRequest(options)
    if req then
        return req(options)
    else
        -- Fallback: sử dụng HttpService.PostAsync
        return HttpService:PostAsync(
            options.Url,
            options.Body,
            Enum.HttpContentType.ApplicationJson
        )
    end
end

-- Lấy object người chơi
local player = Players.LocalPlayer
if not player then return end
local playerName = (player.DisplayName ~= "" and player.DisplayName) or player.Name

-- Đợi PlayerGui và HUD load xong
local pg = player:WaitForChild("PlayerGui")
repeat task.wait() until pg:FindFirstChild("HUD")
local HUD = pg.HUD

-- Danh sách các stat cần lấy
local statNames      = {"STR", "DUR", "ST", "AG", "BS"}
local statsInterval  = 600      -- gửi mỗi 600s
local combatEnabled  = true
local inCombatAlert  = false    -- trạng thái đã gửi alert combat

-- Hàm gửi tin nhắn lên Discord
local function sendWebhookMessage(title, message, mention)
    local payload = {
        content = mention and ("<@"..DiscordID..">") or ("**📢 Cập nhật từ "..playerName.."**"),
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

-- Thông báo đã kết nối thành công
sendWebhookMessage("📡 Webhook hoạt động", "✅ Webhook của **"..playerName.."** đã kết nối thành công!")

-- Hàm lấy giá trị stat từ UI StatsChecker
local function getStatValue(stat)
    local sc = HUD.Tabs and HUD.Tabs:FindFirstChild("StatsChecker")
    if not sc then return 0 end
    local frame = sc:FindFirstChild(stat)
    if not frame then return 0 end
    local lbl   = frame:FindFirstChildWhichIsA("TextLabel")
    if not lbl then return 0 end
    return tonumber(lbl.Text:match("(%d+)") or 0) or 0
end

-- Tính tổng
local function calculateTotal()
    local t = 0
    for _, s in ipairs(statNames) do
        t = t + getStatValue(s)
    end
    return t
end

-- Lấy tên server và uptime
local function getServerInfo()
    local miscs = HUD:FindFirstChild("Miscs")
    local stats = miscs and miscs:FindFirstChild("ServerStats")
    return (
        (stats and stats.ServerName and stats.ServerName.Text) or "N/A"
    ), (
        (stats and stats.Uptime     and stats.Uptime.Text)     or "N/A"
    )
end

-- Lấy tiền
local function getMoney()
    local bars   = HUD:FindFirstChild("Bars")
    local main   = bars and bars:FindFirstChild("MainHUD")
    local cashUI = main and main:FindFirstChild("Cash")
    return (cashUI and cashUI.Text) or "N/A"
end

-- Gửi báo cáo stats
local function sendStats()
    local total = calculateTotal()
    local msg = string.format("💪 **Tổng Stats**: %d\n\n", total)
    for _, s in ipairs(statNames) do
        msg = msg .. string.format("%s: **%d**\n", s, getStatValue(s))
    end
    local server, up = getServerInfo()
    msg = msg .. string.format("\n🖥️ %s\n⌛: %s\n💰: %s", server, up, getMoney())
    sendWebhookMessage("📊 Báo cáo Thống Kê", msg)
end

-- Vòng lặp gửi stats định kỳ
spawn(function()
    while true do
        task.wait(statsInterval)
        sendStats()
    end
end)

-- Thêm ESP
local function addESP(target)
    if target:FindFirstChild("ESP_Highlight") then return end
    local hl = Instance.new("Highlight", target)
    hl.Name              = "ESP_Highlight"
    hl.FillColor         = Color3.new(1, 0, 0)
    hl.OutlineColor      = Color3.new(1, 1, 0)
    hl.OutlineTransparency = 0
    hl.FillTransparency    = 0.5

    local bg = Instance.new("BillboardGui", target)
    bg.Name       = "NameESP"
    bg.Adornee    = target
    bg.Size       = UDim2.new(0,100,0,50)
    bg.AlwaysOnTop = true
    bg.StudsOffset = Vector3.new(0,3,0)

    local tl = Instance.new("TextLabel", bg)
    tl.Size    = UDim2.new(1,0,1,0)
    tl.BackgroundTransparency = 1
    tl.Text    = target.Name
    tl.TextScaled            = true
    tl.TextStrokeTransparency = 0
end

-- Theo dõi mob
local mobs = Workspace:WaitForChild("LivingBeings"):WaitForChild("Mobs")
mobs.ChildAdded:Connect(function(m)
    sendWebhookMessage(m.Name.." xuất hiện", "", true)
    addESP(m)
end)
mobs.ChildRemoved:Connect(function(m)
    sendWebhookMessage(m.Name.." biến mất", "", true)
end)

-- Theo dõi Danielbody
local function trackDaniel(c, added)
    if added then
        sendWebhookMessage("Danielbody xuất hiện","", true)
        addESP(c)
    else
        sendWebhookMessage("Danielbody biến mất","", true)
    end
end
local lb = Workspace:WaitForChild("LivingBeings")
lb.ChildAdded:Connect(function(c) if c.Name=="Danielbody" then trackDaniel(c,true) end end)
lb.ChildRemoved:Connect(function(c) if c.Name=="Danielbody" then trackDaniel(c,false) end end)
if lb:FindFirstChild("Danielbody") then trackDaniel(lb.Danielbody,true) end

-- Kiểm tra combat mỗi giây
spawn(function()
    while combatEnabled do
        task.wait(1)
        local container = Workspace:FindFirstChild("LivingBeings")
        local plModel    = container and container:FindFirstChild(player.Name)
        if plModel then
            local attacker = plModel:GetAttribute("WhoStartedCombat")
            if attacker and not inCombatAlert then
                local ent = container:FindFirstChild(attacker)
                local disp = (ent and ent:FindFirstChildOfClass("Humanoid") and ent.DisplayName) or "Unknown"
                sendWebhookMessage("⚠️ "..playerName.." đang bị tấn công ⚠️",
                    "Bởi: "..disp..", "..attacker, true)
                inCombatAlert = true
            elseif not attacker then
                inCombatAlert = false
            end
        else
            inCombatAlert = false
        end
    end
end)

-- Báo khi người chơi rời
target = player
player.AncestryChanged:Connect(function(_, parent)
    if not parent then
        sendWebhookMessage("🚫 Người chơi rời game", playerName.." đã thoát khỏi trò chơi.", true)
    end
end)
