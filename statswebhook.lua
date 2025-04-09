local HttpService = game:GetService("HttpService")
local Players     = game:GetService("Players")
local Workspace   = game:GetService("Workspace")

-- Cấu hình
local Webhook_URL = _G.Webhook or error("Webhook URL chưa được thiết lập!")
local DiscordID   = _G.DiscordID or error("DiscordID chưa được thiết lập!")

-- Chọn hàm request
local req = syn and syn.request or http_request or request
if not req then return end

-- Tìm hàm screenshot bất kỳ
local screenshotFn = screenshot or Screenshot or (getscreenshot and getscreenshot)
-- Boundary multipart
local function makeBoundary() return "----WebKitFormBoundary"..HttpService:GenerateGUID(false) end

-- Hàm gửi webhook bình thường
local function sendWebhookMessage(title, message, tag)
    local payload = {
        content = tag and ("<@" .. DiscordID .. ">") or ("**📢 Cập nhật từ " .. Players.LocalPlayer.DisplayName .. "**"),
        embeds  = {{ title = title, description = message, color = 0x00ff00 }},
    }
    if tag then payload.allowed_mentions = { users = { DiscordID } } end
    req({
        Url     = Webhook_URL,
        Method  = "POST",
        Headers = { ["Content-Type"] = "application/json" },
        Body    = HttpService:JSONEncode(payload)
    })
end

-- Hàm chụp màn hình & gửi kèm ảnh
local function captureAndSendScreenshot(title, message)
    if not screenshotFn then
        -- fallback nếu không có screenshot
        sendWebhookMessage(title, message, true)
        return
    end

    local imageData = screenshotFn()  -- binary PNG string
    if not imageData then
        sendWebhookMessage(title, message, true)
        return
    end

    local boundary = makeBoundary()
    local bodyLines = {}

    -- file part
    table.insert(bodyLines, "--"..boundary)
    table.insert(bodyLines, 'Content-Disposition: form-data; name="file"; filename="combat.png"')
    table.insert(bodyLines, "Content-Type: image/png\r\n")
    table.insert(bodyLines, imageData)

    -- payload_json part
    table.insert(bodyLines, "--"..boundary)
    table.insert(bodyLines, 'Content-Disposition: form-data; name="payload_json"\r\n')
    local payload = {
        content = "<@" .. DiscordID .. ">",
        embeds  = {{
            title       = title,
            description = message,
            color       = 0xff0000,
            image       = { url = "attachment://combat.png" },
        }},
        allowed_mentions = { users = { DiscordID } }
    }
    table.insert(bodyLines, HttpService:JSONEncode(payload))

    -- end boundary
    table.insert(bodyLines, "--"..boundary.."--")

    local fullBody = table.concat(bodyLines, "\r\n")
    req({
        Url     = Webhook_URL,
        Method  = "POST",
        Headers = {
            ["Content-Type"]   = "multipart/form-data; boundary="..boundary,
            ["Content-Length"] = tostring(#fullBody),
        },
        Body = fullBody,
    })
end

-- Lấy player & GUI
local player    = Players.LocalPlayer
local playerName= player and (player.DisplayName or player.Name)
local pg        = player and player:FindFirstChild("PlayerGui")
if not player or not pg then return end

-- Các biến stats
local statNames    = {"STR","DUR","ST","AG","BS"}
local rankTable    = {
    {"F-",0},{"F",26},{"F+",51},{"E-",76},{"E",126},{"E+",176},{"D-",226},{"D",326},
    {"D+",426},{"C-",526},{"C",726},{"C+",926},{"B-",1126},{"B",1426},{"B+",1726},
    {"A-",2026},{"A",2751},{"A+",3476},{"S-",4201},{"S",5201},{"S+",6201},{"SS-",7201},
    {"SS",8707},{"SS+",10001},{"SSS-",12501},{"SSS",15001},{"SSS+",17501},{"X-",20001},
    {"X",24001},{"X+",28000},{"XX-",32001},{"XX",38001},{"XX+",44001},{"XXX-",50001},
    {"XXX",60001},{"XXX+",70001},{"Z-",80001},{"Z",95000},{"Z+",110001},{"ZZ-",125001},
    {"ZZ",145001},{"ZZ+",165001},{"ZZZ-",185001},{"ZZZ",210001},{"ZZZ+",235001},{"?",260000},
    {"??",500001},{"???",750000}
}
local running, statsInterval, combatEnabled = true,600,true
local inCombatAlertSent = false

-- Helper
local function getChild(parent,name) return parent and parent:FindFirstChild(name) end

local function getStatValue(s)
    local amt = getChild(getChild(getChild(pg,"HUD"),"Tabs").StatsChecker, s)
             and getChild(getChild(getChild(pg,"HUD"),"Tabs").StatsChecker[s],"AMT")
    return amt and tonumber(amt.Text) or 0
end

local function calculateTotalStats()
    local total=0
    for _,s in ipairs(statNames) do total+=getStatValue(s) end
    return total
end

local function getRank(v)
    local cur,nxt,diff="F-","F",math.huge
    for i=1,#rankTable do
        local r,thr=rankTable[i][1],rankTable[i][2]
        if v>=thr then cur=r
        else nxt, diff = r, thr-v; break end
    end
    return cur,nxt,diff
end

local function getServerInfo()
    local stats = getChild(getChild(getChild(pg,"HUD"),"Miscs"),"ServerStats")
    return (stats and getChild(stats,"ServerName").Text) or "N/A",
           (stats and getChild(stats,"Uptime").Text) or "N/A"
end

local function getMoney()
    local cash = getChild(getChild(getChild(getChild(pg,"HUD"),"Bars"),"MainHUD"),"Cash")
    return cash and cash.Text or "N/A"
end

-- Gửi stats
local function sendStats()
    local total=calculateTotalStats()
    local cur,nxt,need=getRank(total)
    local msg = string.format(
        "💪 **Tổng Stats**: %d\n🏆 **Rank hiện tại**: %s\n🔜 **Rank tiếp theo**: %s *(Cần +%d stats)*\n\n",
        total,cur,nxt,need
    )
    for _,s in ipairs(statNames) do
        local v=getStatValue(s); local sr,nr,nd=getRank(v)
        msg..=string.format("%s: **%d** *(%s → %s cần +%d)*\n",s,v,sr,nr,nd)
    end
    local server,uptime = getServerInfo()
    msg..=string.format("\n🖥️ %s\n⌛: %s\n💰: %s",server,uptime,getMoney())
    sendWebhookMessage("📊 Báo cáo Thống Kê",msg)
end

-- Chat commands
local function onChatMessage(_,message)
    local msg=message:lower()
    if msg=="/e stats" then sendStats()
    elseif msg:sub(1,12)=="/e statstime" then
        local t=tonumber(msg:match("%d+"))
        if t and t>0 then statsInterval=t*60; sendWebhookMessage("⏳ Cập nhật thời gian gửi","📊 Thời gian gửi stats đã được đặt thành "..t.." phút.") end
    elseif msg=="/e stop" then running=false; sendWebhookMessage("🛑 Dừng gửi stats","📊 Việc gửi stats đã tạm dừng.")
    elseif msg=="/e start" then running=true; sendWebhookMessage("▶️ Bắt đầu gửi stats","📊 Việc gửi stats đã được khởi động lại.")
    elseif msg=="/e combat on" then combatEnabled=true; sendWebhookMessage("▶️ Combat Check",playerName.." combat check đã được bật.",true)
    elseif msg=="/e combat off" then combatEnabled=false; sendWebhookMessage("🛑 Combat Check",playerName.." combat check đã được tắt.",true)
    end
end

for _,plr in ipairs(Players:GetPlayers()) do plr.Chatted:Connect(onChatMessage) end
spawn(function() while task.wait(statsInterval) do if running then sendStats() end end end)

-- ESP & Danielbody alerts (giữ nguyên)
local function addESP(target)
    if target:FindFirstChild("ESP_Highlight") then return end
    local hl=Instance.new("Highlight",target)
    hl.Name="ESP_Highlight"; hl.FillColor=Color3.new(1,0,0); hl.OutlineColor=Color3.new(1,1,0)
    hl.OutlineTransparency=0; hl.FillTransparency=0.5
    local bg=Instance.new("BillboardGui",target)
    bg.Name="NameESP"; bg.Adornee=target; bg.Size=UDim2.new(0,100,0,50)
    bg.AlwaysOnTop=true; bg.StudsOffset=Vector3.new(0,3,0)
    local tl=Instance.new("TextLabel",bg)
    tl.Size=UDim2.new(1,0,1,0); tl.BackgroundTransparency=1
    tl.Text=target.Name; tl.TextColor3=Color3.new(1,1,1)
    tl.TextStrokeTransparency=0; tl.TextScaled=true
end

local function onDanielbodyAppeared(d)
    sendWebhookMessage("Danielbody xuất hiện","",true)
    addESP(d)
end
local function onDanielbodyRemoved(d)
    sendWebhookMessage("Danielbody biến mất","",true)
end

local lb=Workspace:WaitForChild("LivingBeings")
lb.ChildAdded:Connect(function(c) if c.Name=="Danielbody" then onDanielbodyAppeared(c) end end)
lb.ChildRemoved:Connect(function(c) if c.Name=="Danielbody" then onDanielbodyRemoved(c) end end)
if lb:FindFirstChild("Danielbody") then onDanielbodyAppeared(lb.Danielbody) end

-- Combat alert with screenshot
local function checkCombatByAttribute()
    local lb=Workspace:FindFirstChild("LivingBeings")
    if not lb then return end
    local pl=lb:FindFirstChild(player.Name)
    if pl then
        local attackerName=pl:GetAttribute("WhoStartedCombat")
        if attackerName and not inCombatAlertSent then
            local attacker=lb:FindFirstChild(attackerName)
            local disp=(attacker and attacker:FindFirstChildOfClass("Humanoid") and attacker.DisplayName) or "Unknown"
            -- Gửi kèm ảnh
            captureAndSendScreenshot(
                "⚠️ "..playerName.." đang bị tấn công ⚠️",
                "Bởi: **"..disp.."** (`"..attackerName.."`)"
            )
            inCombatAlertSent=true
        elseif not attackerName then
            inCombatAlertSent=false
        end
    else
        inCombatAlertSent=false
    end
end

spawn(function() while task.wait(1) do checkCombatByAttribute() end end)

-- BindToClose
game:BindToClose(function()
    sendWebhookMessage("🚫 Game Đóng","Webhook của **"..playerName.."** đã dừng hoạt động",true)
end)
