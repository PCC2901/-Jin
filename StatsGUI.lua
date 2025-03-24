local Players, TweenService, UserInputService = game:GetService("Players"), game:GetService("TweenService"), game:GetService("UserInputService")
local player, pg = Players.LocalPlayer, Players.LocalPlayer:WaitForChild("PlayerGui")
local totC, subC = Color3.new(1,1,1), Color3.fromRGB(200,200,200)
local function N(c, p, par) local o=Instance.new(c) for k,v in pairs(p) do o[k]=v end o.Parent=par return o end
local sg = N("ScreenGui",{Name="StatsViewer",ResetOnSpawn=false,Enabled=false},pg)
local mf = N("Frame",{Size=UDim2.new(0,350,0,350),Position=UDim2.new(0,20,0,20),BackgroundColor3=Color3.fromRGB(30,30,30),BackgroundTransparency=0.2,BorderSizePixel=2,BorderColor3=Color3.fromRGB(255,170,0)},sg)
local hf = N("Frame",{Size=UDim2.new(1,-10,0,100),Position=UDim2.new(0,5,0,5),BackgroundTransparency=1},mf)
local tot = N("TextLabel",{Size=UDim2.new(1,0,0,30),Text="⚔ Total Stats: 0",BackgroundTransparency=1,TextColor3=totC,Font=Enum.Font.GothamBold,TextScaled=true},hf)
local rnk = N("TextLabel",{Size=UDim2.new(1,0,0,30),Position=UDim2.new(0,0,0,35),Text="⭐ Rank: ???",BackgroundTransparency=1,TextColor3=totC,Font=Enum.Font.GothamBold,TextScaled=true},hf)
local nrnk = N("TextLabel",{Size=UDim2.new(1,0,0,30),Position=UDim2.new(0,0,0,70),Text="↓ Next Rank: 0",BackgroundTransparency=1,TextColor3=totC,Font=Enum.Font.GothamBold,TextScaled=true},hf)
local sf = N("Frame",{Size=UDim2.new(1,-10,1,-110),Position=UDim2.new(0,5,0,105),BackgroundTransparency=1},mf)
N("UIListLayout",{FillDirection=Enum.FillDirection.Vertical,SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,5)},sf)
local sn, si = {"STR","DUR","ST","AG","BS"},{STR="💪",DUR="🛡",ST="⚡",AG="🏃",BS="⚔"}
local sr, rnkTbl = {}, {{"F-",0},{"F",26},{"F+",51},{"E-",76},{"E",126},{"E+",176},{"D-",226},{"D",326},{"D+",426},{"C-",526},{"C",726},{"C+",926},{"B-",1126},{"B",1426},{"B+",1726},{"A-",2026},{"A",2751},{"A+",3476},{"S-",4201},{"S",5201},{"S+",6201},{"SS-",7201},{"SS",8701},{"SS+",10001},{"SSS-",12501},{"SSS",15001},{"SSS+",17501},{"X-",20001},{"X",24001},{"X+",28000},{"XX-",32001},{"XX",38001},{"XX+",44001},{"XXX-",50001},{"XXX",60001},{"XXX+",70001},{"Z-",80001},{"Z",95000},{"Z+",110001},{"ZZ-",125001},{"ZZ",145001},{"ZZ+",165001},{"ZZZ-",185001},{"ZZZ",210001},{"ZZZ+",235001},{"?",260000},{"??",500001},{"???",750000}}
local ps, pt = {STR=0,DUR=0,ST=0,AG=0,BS=0}, 0
for _,s in ipairs(sn) do 
	local r1 = N("Frame",{Size=UDim2.new(1,0,0,40),BackgroundTransparency=1},sf)
	local m = N("TextLabel",{Size=UDim2.new(0.5,-5,1,0),Text=si[s].." 0 (---)",BackgroundTransparency=1,TextColor3=totC,Font=Enum.Font.GothamBold,TextScaled=true,TextXAlignment=Enum.TextXAlignment.Left},r1)
	local sT = N("TextLabel",{Size=UDim2.new(0.5,-5,1,0),Position=UDim2.new(0.5,5,0,0),Text="(0) > ---",BackgroundTransparency=1,TextColor3=subC,Font=Enum.Font.Gotham,TextScaled=true,TextXAlignment=Enum.TextXAlignment.Left},r1)
	sr[s]={m=m,s=sT}
end
local function getRank(v) local c,n,need="F-","F",math.huge; for i=1,#rnkTbl do local r,t=rnkTbl[i][1],rnkTbl[i][2] if v>=t then c=r else n,need=r,t-v break end; return c,n,need end
local function getVal(s) local sc = pg:FindFirstChild("HUD") and pg.HUD:FindFirstChild("Tabs") and pg.HUD.Tabs:FindFirstChild("StatsChecker"); if sc then local sf = sc:FindFirstChild(s); if sf then local a = sf:FindFirstChild("AMT"); return a and tonumber(a.Text) or 0 end end return 0 end
local function totVal() local t=0; for _,s in ipairs(sn) do t=t+getVal(s) end; return t end
local function fmt(i) return (i==math.floor(i)) and ("+"..i) or (i*10==math.floor(i*10)) and string.format("+%.1f",i) or string.format("+%.2f",i) end
local function effect(lbl, orig) local ti=TweenInfo.new(0.2,Enum.EasingStyle.Quad,Enum.EasingDirection.Out) local tw=TweenService:Create(lbl,ti,{TextColor3=Color3.fromRGB(0,255,0)}) tw:Play() tw.Completed:Connect(function() TweenService:Create(lbl,ti,{TextColor3=orig}):Play() end) end
local function inc(base,d) local e=N("TextLabel",{Size=base.Size,Position=base.Position,BackgroundTransparency=1,Text=fmt(d),Font=base.Font,TextScaled=base.TextScaled,TextColor3=Color3.fromRGB(0,255,0),ZIndex=base.ZIndex+1},base.Parent) TweenService:Create(e,TweenInfo.new(1,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Position=e.Position+UDim2.new(0,0,-0.06,0),TextTransparency=1}):Play() end
local function upd() if sg.Enabled then local tv=totVal() local c,n,need=getRank(tv) tot.Text="⚔ Total Stats: "..tv; rnk.Text="⭐ Rank: "..c; nrnk.Text="↓ Next Rank: "..n.." ("..need..")"; local diff=math.floor(tv)-math.floor(pt) if diff>=1 then effect(tot,totC) inc(tot,diff) end; pt=tv; for _,s in ipairs(sn) do local v=getVal(s) local c1,n1,need1=getRank(v) sr[s].m.Text=si[s].." "..v.." ("..c1..")"; sr[s].s.Text="("..need1..") > "..n1; if v>ps[s] then effect(sr[s].m,totC) effect(sr[s].s,subC) inc(sr[s].m,v-ps[s]) end; ps[s]=v end end end
local function lis() local sc=pg:WaitForChild("HUD"):WaitForChild("Tabs"):WaitForChild("StatsChecker"); for _,s in ipairs(sn) do local sf=sc:FindFirstChild(s); if sf then local a=sf:FindFirstChild("AMT"); if a then a:GetPropertyChangedSignal("Text"):Connect(upd) end end end end
local vis=false; local function tog() vis=not vis; if vis then sg.Enabled=true; mf.Position=UDim2.new(0,-400,0,20); TweenService:Create(mf,TweenInfo.new(0.5,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Position=UDim2.new(0,20,0,20)}):Play(); upd() else TweenService:Create(mf,TweenInfo.new(0.5,Enum.EasingStyle.Back,Enum.EasingDirection.In),{Position=UDim2.new(0,-400,0,20)}):Play(); sg.Enabled=false end end
UserInputService.InputBegan:Connect(function(i,gp) if not gp and i.KeyCode==Enum.KeyCode.K then tog() end end)
lis()
