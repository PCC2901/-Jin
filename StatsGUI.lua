local Players, TweenService, UserInputService = game:GetService("Players"), game:GetService("TweenService"), game:GetService("UserInputService")
local player, playerGui = Players.LocalPlayer, Players.LocalPlayer:WaitForChild("PlayerGui")
local function new(class, props, parent)
	local inst = Instance.new(class)
	for k, v in pairs(props) do inst[k] = v end
	inst.Parent = parent
	return inst
end

local screenGui = new("ScreenGui", {Name="StatsViewer", ResetOnSpawn=false, Enabled=false}, playerGui)
local mainFrame = new("Frame", {Size=UDim2.new(0,350,0,350), Position=UDim2.new(0,20,0,20), BackgroundColor3=Color3.fromRGB(30,30,30), BackgroundTransparency=0.2, BorderSizePixel=2, BorderColor3=Color3.fromRGB(255,170,0)}, screenGui)
local headerFrame = new("Frame", {Size=UDim2.new(1,-10,0,100), Position=UDim2.new(0,5,0,5), BackgroundTransparency=1}, mainFrame)
local totalLabel = new("TextLabel", {Size=UDim2.new(1,0,0,30), Text="⚔ Total Stats: 0", BackgroundTransparency=1, TextColor3=Color3.new(1,1,1), Font=Enum.Font.GothamBold, TextScaled=true}, headerFrame)
local rankLabel = new("TextLabel", {Size=UDim2.new(1,0,0,30), Position=UDim2.new(0,0,0,35), Text="⭐ Rank: ???", BackgroundTransparency=1, TextColor3=Color3.new(1,1,1), Font=Enum.Font.GothamBold, TextScaled=true}, headerFrame)
local nextRankLabel = new("TextLabel", {Size=UDim2.new(1,0,0,30), Position=UDim2.new(0,0,0,70), Text="↓ Next Rank: 0", BackgroundTransparency=1, TextColor3=Color3.new(1,1,1), Font=Enum.Font.GothamBold, TextScaled=true}, headerFrame)
local statsFrame = new("Frame", {Size=UDim2.new(1,-10,1,-110), Position=UDim2.new(0,5,0,105), BackgroundTransparency=1}, mainFrame)
new("UIListLayout", {FillDirection=Enum.FillDirection.Vertical, SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,5)}, statsFrame)

local statNames, statIcons = {"STR","DUR","ST","AG","BS"}, {STR="⚔", DUR="🛡", ST="✊", AG="🏃", BS="🔥"}
local statRows = {}
for _, stat in ipairs(statNames) do
	local row = new("Frame", {Size=UDim2.new(1,0,0,40), BackgroundTransparency=1}, statsFrame)
	local mainStat = new("TextLabel", {Size=UDim2.new(0.5,-5,1,0), Text=string.format("%s 0 (---)", statIcons[stat]), BackgroundTransparency=1, TextColor3=Color3.new(1,1,1), Font=Enum.Font.GothamBold, TextScaled=true, TextXAlignment=Enum.TextXAlignment.Left}, row)
	local subStat = new("TextLabel", {Size=UDim2.new(0.5,-5,1,0), Position=UDim2.new(0.5,5,0,0), Text="(0) > ---", BackgroundTransparency=1, TextColor3=Color3.fromRGB(200,200,200), Font=Enum.Font.Gotham, TextScaled=true, TextXAlignment=Enum.TextXAlignment.Left}, row)
	statRows[stat] = {main = mainStat, sub = subStat}
end

local rankTable = {{"F-",0},{"F",26},{"F+",51},{"E-",76},{"E",126},{"E+",176},{"D-",226},{"D",326},{"D+",426},{"C-",526},{"C",726},{"C+",926},{"B-",1126},{"B",1426},{"B+",1726},{"A-",2026},{"A",2751},{"A+",3476},{"S-",4201},{"S",5201},{"S+",6201},{"SS-",7201},{"SS",8701},{"SS+",10001},{"SSS-",12501},{"SSS",15001},{"SSS+",17501},{"X-",20001},{"X",24001},{"X+",28000},{"XX-",32001},{"XX",38001},{"XX+",44001},{"XXX-",50001},{"XXX",60001},{"XXX+",70001},{"Z-",80001},{"Z",95000},{"Z+",110001},{"ZZ-",125001},{"ZZ",145001},{"ZZ+",165001},{"ZZZ-",185001},{"ZZZ",210001},{"ZZZ+",235001},{"?",260000},{"??",500001},{"???",750000}}
local prevStats = {STR=0, DUR=0, ST=0, AG=0, BS=0}
local prevTotal = 0

local function getRank(val)
	local cur, nxt, need = "F-", "F", math.huge
	for i = 1, #rankTable do
		local r, t = rankTable[i][1], rankTable[i][2]
		if val >= t then cur = r else nxt, need = r, t - val; break end
	end
	return cur, nxt, need
end

local function getStatValue(stat)
	local sc = playerGui:FindFirstChild("HUD") and playerGui.HUD:FindFirstChild("Tabs") and playerGui.HUD.Tabs:FindFirstChild("StatsChecker")
	if sc then
		local sf = sc:FindFirstChild(stat)
		if sf then
			local amt = sf:FindFirstChild("AMT")
			return amt and tonumber(amt.Text) or 0
		end
	end
	return 0
end

local function calcTotal() local s=0; for _,sn in ipairs(statNames) do s = s + getStatValue(sn) end; return s end
local function fmtInc(inc) return (inc == math.floor(inc)) and string.format("+%d", inc) or (inc*10 == math.floor(inc*10)) and string.format("+%.1f", inc) or string.format("+%.2f", inc) end

local function playEffect(lbl)
	local orig = lbl.TextColor3
	local info = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tw = TweenService:Create(lbl, info, {TextColor3 = Color3.fromRGB(0,255,0)})
	tw:Play()
	tw.Completed:Connect(function() TweenService:Create(lbl, info, {TextColor3 = orig}):Play() end)
end

local function showInc(base, inc)
	local eff = new("TextLabel", {Size=base.Size, Position=base.Position, BackgroundTransparency=1, Text=fmtInc(inc), Font=base.Font, TextScaled=base.TextScaled, TextColor3=Color3.fromRGB(0,255,0), ZIndex=base.ZIndex+1}, base.Parent)
	local info = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local goal = {Position = eff.Position + UDim2.new(0,0,-0.06,0), TextTransparency = 1}
	local tw = TweenService:Create(eff, info, goal)
	tw:Play()
	tw.Completed:Connect(function() eff:Destroy() end)
end

local function updateGUI()
	if screenGui.Enabled then
		local total = calcTotal()
		local cur, nxt, need = getRank(total)
		totalLabel.Text = string.format("⚔ Total Stats: %d", total)
		rankLabel.Text = string.format("⭐ Rank: %s", cur)
		nextRankLabel.Text = string.format("↓ Next Rank: %s (%d)", nxt, need)
		local diff = math.floor(total) - math.floor(prevTotal)
		if diff >= 1 then playEffect(totalLabel); showInc(totalLabel, diff) end
		prevTotal = total
		for _, stat in ipairs(statNames) do
			local value = getStatValue(stat)
			local curR, nxtR, n = getRank(value)
			statRows[stat].main.Text = string.format("%s %d (%s)", statIcons[stat], value, curR)
			statRows[stat].sub.Text = string.format("(%d) > %s", n, nxtR)
			if value > prevStats[stat] then
				playEffect(statRows[stat].main)
				playEffect(statRows[stat].sub)
				showInc(statRows[stat].main, value - prevStats[stat])
			end
			prevStats[stat] = value
		end
	end
end

local function listenChanges()
	local sc = playerGui:WaitForChild("HUD"):WaitForChild("Tabs"):WaitForChild("StatsChecker")
	for _, stat in ipairs(statNames) do
		local sf = sc:FindFirstChild(stat)
		if sf then
			local amt = sf:FindFirstChild("AMT")
			if amt then amt:GetPropertyChangedSignal("Text"):Connect(updateGUI) end
		end
	end
end

local visible = false
local function toggleGUI()
	visible = not visible
	if visible then
		screenGui.Enabled = true
		mainFrame.Position = UDim2.new(0, -400, 0, 20)
		local tw = TweenService:Create(mainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(0, 20, 0, 20)})
		tw:Play()
		updateGUI()
	else
		local tw = TweenService:Create(mainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Position = UDim2.new(0, -400, 0, 20)})
		tw:Play()
		tw.Completed:Connect(function() screenGui.Enabled = false end)
	end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if not gameProcessed and input.KeyCode == Enum.KeyCode.K then toggleGUI() end
end)
listenChanges()
