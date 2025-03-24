-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Tạo ScreenGui chính
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "StatsViewer"
screenGui.Parent = playerGui
screenGui.ResetOnSpawn = false

-- Tạo Main Frame (container GUI)
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 350, 0, 350)
mainFrame.Position = UDim2.new(0, 20, 0, 20)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.BackgroundTransparency = 0.2
mainFrame.BorderSizePixel = 2
mainFrame.BorderColor3 = Color3.fromRGB(255, 170, 0)
mainFrame.Parent = screenGui

-- Tạo Header Frame hiển thị tổng chỉ số và xếp hạng
local headerFrame = Instance.new("Frame")
headerFrame.Size = UDim2.new(1, -10, 0, 100)
headerFrame.Position = UDim2.new(0, 5, 0, 5)
headerFrame.BackgroundTransparency = 1
headerFrame.Parent = mainFrame

local totalLabel = Instance.new("TextLabel")
totalLabel.Size = UDim2.new(1, 0, 0, 30)
totalLabel.Position = UDim2.new(0, 0, 0, 0)
totalLabel.BackgroundTransparency = 1
totalLabel.TextColor3 = Color3.new(1, 1, 1)
totalLabel.Font = Enum.Font.GothamBold
totalLabel.TextScaled = true
totalLabel.Text = "⚔ Total Stats: 0"
totalLabel.Parent = headerFrame

local rankLabel = Instance.new("TextLabel")
rankLabel.Size = UDim2.new(1, 0, 0, 30)
rankLabel.Position = UDim2.new(0, 0, 0, 35)
rankLabel.BackgroundTransparency = 1
rankLabel.TextColor3 = Color3.new(1, 1, 1)
rankLabel.Font = Enum.Font.GothamBold
rankLabel.TextScaled = true
rankLabel.Text = "⭐ Rank: ???"
rankLabel.Parent = headerFrame

local nextRankLabel = Instance.new("TextLabel")
nextRankLabel.Size = UDim2.new(1, 0, 0, 30)
nextRankLabel.Position = UDim2.new(0, 0, 0, 70)
nextRankLabel.BackgroundTransparency = 1
nextRankLabel.TextColor3 = Color3.new(1, 1, 1)
nextRankLabel.Font = Enum.Font.GothamBold
nextRankLabel.TextScaled = true
nextRankLabel.Text = "↓ Next Rank: 0"
nextRankLabel.Parent = headerFrame

-- Tạo Stats List Frame
local statsFrame = Instance.new("Frame")
statsFrame.Size = UDim2.new(1, -10, 1, -110)
statsFrame.Position = UDim2.new(0, 5, 0, 105)
statsFrame.BackgroundTransparency = 1
statsFrame.Parent = mainFrame

local listLayout = Instance.new("UIListLayout")
listLayout.FillDirection = Enum.FillDirection.Vertical
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 5)
listLayout.Parent = statsFrame

-- Định nghĩa tên chỉ số và biểu tượng
local statNames = {"STR", "DUR", "ST", "AG", "BS"}
local statIcons = {STR = "⚔", DUR = "🛡", ST = "✊", AG = "🏃", BS = "🔥"}
local statRows = {}

for _, stat in ipairs(statNames) do
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 40)
	row.BackgroundTransparency = 1
	row.Parent = statsFrame
	
	local mainStat = Instance.new("TextLabel")
	mainStat.Size = UDim2.new(0.5, -5, 1, 0)
	mainStat.Position = UDim2.new(0, 0, 0, 0)
	mainStat.BackgroundTransparency = 1
	mainStat.TextColor3 = Color3.new(1, 1, 1)
	mainStat.Font = Enum.Font.GothamBold
	mainStat.TextScaled = true
	mainStat.TextXAlignment = Enum.TextXAlignment.Left
	mainStat.Text = string.format("%s 0 (---)", statIcons[stat])
	mainStat.Parent = row
	
	local subStat = Instance.new("TextLabel")
	subStat.Size = UDim2.new(0.5, -5, 1, 0)
	subStat.Position = UDim2.new(0.5, 5, 0, 0)
	subStat.BackgroundTransparency = 1
	subStat.TextColor3 = Color3.fromRGB(200, 200, 200)
	subStat.Font = Enum.Font.Gotham
	subStat.TextScaled = true
	subStat.TextXAlignment = Enum.TextXAlignment.Left
	subStat.Text = "(0) > ---"
	subStat.Parent = row
	
	statRows[stat] = {main = mainStat, sub = subStat}
end

-- Ẩn GUI mặc định, sẽ bật khi nhấn phím
screenGui.Enabled = false

-- Bảng xếp hạng
local rankTable = {
	{ "F-", 0 }, { "F", 26 }, { "F+", 51 }, { "E-", 76 }, { "E", 126 }, { "E+", 176 },
	{ "D-", 226 }, { "D", 326 }, { "D+", 426 }, { "C-", 526 }, { "C", 726 }, { "C+", 926 },
	{ "B-", 1126 }, { "B", 1426 }, { "B+", 1726 }, { "A-", 2026 }, { "A", 2751 }, { "A+", 3476 },
	{ "S-", 4201 }, { "S", 5201 }, { "S+", 6201 }, { "SS-", 7201 }, { "SS", 8701 }, { "SS+", 10001 },
	{ "SSS-", 12501 }, { "SSS", 15001 }, { "SSS+", 17501 }, { "X-", 20001 }, { "X", 24001 }, { "X+", 28000 },
	{ "XX-", 32001 }, { "XX", 38001 }, { "XX+", 44001 }, { "XXX-", 50001 }, { "XXX", 60001 }, { "XXX+", 70001 },
	{ "Z-", 80001 }, { "Z", 95000 }, { "Z+", 110001 }, { "ZZ-", 125001 }, { "ZZ", 145001 }, { "ZZ+", 165001 },
	{ "ZZZ-", 185001 }, { "ZZZ", 210001 }, { "ZZZ+", 235001 }, { "?", 260000 }, { "??", 500001 }, { "???", 750000 }
}

local previousStats = {STR = 0, DUR = 0, ST = 0, AG = 0, BS = 0}
local previousTotal = 0

local function getRank(value)
	local currentRank, nextRank, nextThreshold = "F-", "F", math.huge
	for i = 1, #rankTable do
		local rankName, threshold = rankTable[i][1], rankTable[i][2]
		if value >= threshold then
			currentRank = rankName
		else
			nextRank, nextThreshold = rankName, threshold
			break
		end
	end
	return currentRank, nextRank, nextThreshold - value
end

local function getStatValue(statName)
	local statsChecker = playerGui:FindFirstChild("HUD") 
		and playerGui.HUD:FindFirstChild("Tabs") 
		and playerGui.HUD.Tabs:FindFirstChild("StatsChecker")
	if statsChecker then
		local statFrame = statsChecker:FindFirstChild(statName)
		if statFrame then
			local amtLabel = statFrame:FindFirstChild("AMT")
			if amtLabel then
				return tonumber(amtLabel.Text) or 0
			end
		end
	end
	return 0
end

local function calculateTotalStats()
	local total = 0
	for _, stat in ipairs(statNames) do
		total = total + getStatValue(stat)
	end
	return total
end

local function formatIncrement(inc)
	if inc == math.floor(inc) then
		return string.format("+%d", inc)
	elseif inc * 10 == math.floor(inc * 10) then
		return string.format("+%.1f", inc)
	else
		return string.format("+%.2f", inc)
	end
end

local function playEffect(labelObj)
	local originalColor = labelObj.TextColor3
	local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tweenUp = TweenService:Create(labelObj, tweenInfo, {TextColor3 = Color3.fromRGB(0, 255, 0)})
	local tweenDown = TweenService:Create(labelObj, tweenInfo, {TextColor3 = originalColor})
	tweenUp:Play()
	tweenUp.Completed:Connect(function()
		tweenDown:Play()
	end)
end

local function showIncrementEffect(baseLabel, increment)
	local effectLabel = Instance.new("TextLabel")
	effectLabel.Size = baseLabel.Size
	effectLabel.Position = baseLabel.Position
	effectLabel.BackgroundTransparency = 1
	effectLabel.Text = formatIncrement(increment)
	effectLabel.Font = baseLabel.Font
	effectLabel.TextScaled = baseLabel.TextScaled
	effectLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
	effectLabel.Parent = baseLabel.Parent
	effectLabel.ZIndex = baseLabel.ZIndex + 1
	
	local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local goal = {Position = effectLabel.Position + UDim2.new(0, 0, 0, -20), TextTransparency = 1}
	local tween = TweenService:Create(effectLabel, tweenInfo, goal)
	tween:Play()
	tween.Completed:Connect(function()
		effectLabel:Destroy()
	end)
end

local function updateGUI()
	if screenGui.Enabled then
		local total = calculateTotalStats()
		local currentRank, nextRank, needed = getRank(total)
		totalLabel.Text = string.format("⚔ Total Stats: %d", total)
		rankLabel.Text = string.format("⭐ Rank: %s", currentRank)
		nextRankLabel.Text = string.format("↓ Next Rank: %s (%d)", nextRank, needed)
		
		local intDiff = math.floor(total) - math.floor(previousTotal)
		if intDiff >= 1 then
			playEffect(totalLabel)
			showIncrementEffect(totalLabel, intDiff)
		end
		previousTotal = total
		
		for _, stat in ipairs(statNames) do
			local value = getStatValue(stat)
			local current, nextR, need = getRank(value)
			statRows[stat].main.Text = string.format("%s %d (%s)", statIcons[stat], value, current)
			statRows[stat].sub.Text = string.format("(%d) > %s", need, nextR)
			
			if value > previousStats[stat] then
				playEffect(statRows[stat].main)
				playEffect(statRows[stat].sub)
				showIncrementEffect(statRows[stat].main, value - previousStats[stat])
			end
			previousStats[stat] = value
		end
	end
end

local function listenForStatChanges()
	local statsChecker = playerGui:WaitForChild("HUD"):WaitForChild("Tabs"):WaitForChild("StatsChecker")
	for _, stat in ipairs(statNames) do
		local statFrame = statsChecker:FindFirstChild(stat)
		if statFrame then
			local amtLabel = statFrame:FindFirstChild("AMT")
			if amtLabel then
				amtLabel:GetPropertyChangedSignal("Text"):Connect(updateGUI)
			end
		end
	end
end

-- Tạo hiệu ứng mở/đóng GUI bằng Tween
local isVisible = false
local function toggleGUI()
	isVisible = not isVisible
	if isVisible then
		screenGui.Enabled = true
		mainFrame.Position = UDim2.new(0, -400, 0, 20)
		local tween = TweenService:Create(mainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(0, 20, 0, 20)})
		tween:Play()
		updateGUI()
	else
		local tween = TweenService:Create(mainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Position = UDim2.new(0, -400, 0, 20)})
		tween:Play()
		tween.Completed:Connect(function()
			screenGui.Enabled = false
		end)
	end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.K then
		toggleGUI()
	end
end)

listenForStatChanges()
