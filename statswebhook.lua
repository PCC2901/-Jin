-- Services
local HttpService   = game:GetService("HttpService")
local Players       = game:GetService("Players")
local Workspace     = game:GetService("Workspace")

-- Cấu hình
local WEBHOOK_URL   = _G.Webhook   or error("Webhook URL chưa được thiết lập!")
local DISCORD_ID    = _G.DiscordID or error("DiscordID chưa được thiết lập!")

-- HTTP wrapper với error handling
local req = syn and syn.request or http_request or request
local function safeRequest(opts)
    local ok, res = pcall(function() return req(opts) end)
    if not ok or not res or res.StatusCode ~= 200 then
        warn("[Webhook] Gửi thất bại", res and res.StatusCode or res)
    end
end

-- Gửi lên Discord
local function sendWebhook(title, desc, mention)
    local payload = {
        content = mention and ("<@"..DISCORD_ID..">") or ("**📢 "..playerName.."**"),
        embeds  = {{ title = title, description = desc, color = 0x00ff00 }},
    }
    if mention then
        payload.allowed_mentions = { users = { DISCORD_ID } }
    end
    safeRequest({
        Url     = WEBHOOK_URL,
        Method  = "POST",
        Headers = { ["Content-Type"] = "application/json" },
        Body    = HttpService:JSONEncode(payload),
    })
end

-- Thông tin người chơi & GUI
local player      = Players.LocalPlayer or Players.PlayerAdded:Wait()
local playerName  = (player.DisplayName ~= "" and player.DisplayName) or player.Name
local pg          = player:WaitForChild("PlayerGui")
local HUD         = pg:WaitForChild("HUD")
local Tabs        = HUD:WaitForChild("Tabs")
local StatsChk    = Tabs:WaitForChild("StatsChecker")
local Miscs       = HUD:WaitForChild("Miscs")
local ServerStats = Miscs:WaitForChild("ServerStats")
local Bars        = HUD:WaitForChild("Bars")
local MainHUD     = Bars:WaitForChild("MainHUD")
local CashGui     = MainHUD:WaitForChild("Cash")

-- Thông báo kết nối webhook ngay khi script chạy
sendWebhook("📡 Webhook hoạt động", "✅ Webhook của **"..playerName.."** đã kết nối thành công!", false)

-- Rank thresholds
local rankTable = {
    {"F-",0}, {"F",26}, {"F+",51}, {"E-",76}, {"E",126}, {"E+",176},
    {"D-",226}, {"D",326}, {"D+",426}, {"C-",526}, {"C",726}, {"C+",926},
    {"B-",1126}, {"B",1426}, {"B+",1726}, {"A-",2026}, {"A",2751}, {"A+",3476},
    {"S-",4201}, {"S",5201}, {"S+",6201}, {"SS-",7201}, {"SS",8707}, {"SS+",10001},
    {"SSS-",12501}, {"SSS",15001}, {"SSS+",17501}, {"X-",20001}, {"X",24001},
    {"X+",28000}, {"XX-",32001}, {"XX",38001}, {"XX+",44001}, {"XXX-",50001},
    {"XXX",60001}, {"XXX+",70001}, {"Z-",80001}, {"Z",95000}, {"Z+",110001},
    {"ZZ-",125001}, {"ZZ",145001}, {"ZZ+",165001}, {"ZZZ-",185001},
    {"ZZZ",210001}, {"ZZZ+",235001}, {"?",260000}, {"??",500001}, {"???",750000}
}

-- Lấy stat
local function getStat(name)
    local stat = StatsChk:FindFirstChild(name)
    if stat then
        local amt = stat:FindFirstChild("AMT")
        return amt and tonumber(amt.Text) or 0
    end
    return 0
end

-- Tính rank
local function getRank(value)
    local current, nextRank, diff = rankTable[1][1], rankTable[2][1], math.huge
    for i = 1, #rankTable do
        local r, thr = rankTable[i][1], rankTable[i][2]
        if value >= thr then
            current = r
        else
            nextRank, diff = r, thr - value
            break
        end
    end
    return current, nextRank, diff
end

-- Lấy thông tin server & tiền
local function getServerInfo()
    return ServerStats:FindFirstChild("ServerName").Text or "N/A",
           ServerStats:FindFirstChild("Uptime").Text     or "N/A"
end
local function getCash() return CashGui.Text or "N/A" end

-- Gửi báo cáo stats định kỳ
local STAT_NAMES    = {"STR","DUR","ST","AG","BS"}
local statsInterval = 600  -- giây
spawn(function()
    while task.wait(statsInterval) do
        -- Tính tổng
        local total = 0
        for _, n in ipairs(STAT_NAMES) do total += getStat(n) end

        local cur, nxt, need = getRank(total)
        local msg = ("💪 Tổng: %d\n🏆 Hiện tại: %s\n🔜 Tiếp: %s (+%d)\n\n")
                    :format(total, cur, nxt, need)

        -- Chi tiết từng stat
        for _, n in ipairs(STAT_NAMES) do
            local v = getStat(n)
            local sr, nr, nd = getRank(v)
            msg = msg..(("%s: %d (%s→%s +%d)\n"):format(n, v, sr, nr, nd))
        end

        -- Server & tiền
        local srv, up = getServerInfo()
        msg = msg..(("\n🖥️ %s\n⌛ %s\n💰 %s"):format(srv, up, getCash()))

        sendWebhook("📊 Báo cáo Thống Kê", msg, false)
    end
end)

-- Danielbody ESP & alert
local lb = Workspace:WaitForChild("LivingBeings")
local function addESP(target)
    if target:FindFirstChild("ESP_HL") then return end
    local hl = Instance.new("Highlight", target)
    hl.Name, hl.FillTransparency, hl.OutlineTransparency = "ESP_HL", 0.5, 0
    hl.FillColor, hl.OutlineColor = Color3.new(1,0,0), Color3.new(1,1,0)
    local bg = Instance.new("BillboardGui", target)
    bg.Name, bg.Adornee, bg.Size, bg.AlwaysOnTop, bg.StudsOffset =
      "ESP_BB", target, UDim2.new(0,100,0,50), true, Vector3.new(0,3,0)
    local tl = Instance.new("TextLabel", bg)
    tl.Size, tl.BackgroundTransparency, tl.TextScaled = UDim2.new(1,1,1,1), 1, true
    tl.Text, tl.TextColor3, tl.TextStrokeTransparency = target.Name, Color3.new(1,1,1), 0
end

local function onAdded(c)
    if c.Name == "Danielbody" then
        sendWebhook("⚡ Danielbody xuất hiện", "", true)
        addESP(c)
    end
end
local function onRemoved(c)
    if c.Name == "Danielbody" then
        sendWebhook("❌ Danielbody biến mất", "", true)
    end
end

lb.ChildAdded:Connect(onAdded)
lb.ChildRemoved:Connect(onRemoved)
if lb:FindFirstChild("Danielbody") then onAdded(lb.Danielbody) end

-- Combat alert
local alerted = false
spawn(function()
    while task.wait(1) do
        local pl = lb:FindFirstChild(player.Name)
        local attName = pl and pl:GetAttribute("WhoStartedCombat")
        local attacker = attName and lb:FindFirstChild(attName)
        if attacker and not alerted then
            local disp = (attacker:FindFirstChildOfClass("Humanoid") or {}).DisplayName or attacker.Name
            sendWebhook("⚠️ Đang bị tấn công", "Bởi: "..disp, true)
            alerted = true
        elseif not attacker then
            alerted = false
        end
    end
end)
