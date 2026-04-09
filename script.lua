--// SERVICES
local CoreGui = game:GetService("CoreGui")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local VIM = game:GetService("VirtualInputManager")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

--// CONFIG
local CONFIG_FILE = "miu_all_config.json"
local Config = {
	autoParry = false,
	parryDelay = 0.12,
	showESP = false,
	showPrediction = true
}

pcall(function()
	if readfile and isfile and isfile(CONFIG_FILE) then
		Config = HttpService:JSONDecode(readfile(CONFIG_FILE))
	end
end)

local function save()
	if writefile then
		writefile(CONFIG_FILE, HttpService:JSONEncode(Config))
	end
end

--// GITHUB
local GitHub = {}
GitHub.base = "https://raw.githubusercontent.com/username/repo/main/"

function GitHub.load(file)
	local ok, data = pcall(function()
		return game:HttpGet(GitHub.base .. file)
	end)
	return ok and data
end

--// GUI
local gui = Instance.new("ScreenGui", CoreGui)
local main = Instance.new("Frame", gui)
main.Size = UDim2.new(0,720,0,420)
main.Position = UDim2.new(0.5,-360,0.5,-210)
main.BackgroundColor3 = Color3.fromRGB(25,25,25)

-- SIDEBAR + CONTENT
local sidebar = Instance.new("Frame", main)
sidebar.Size = UDim2.new(0,150,1,0)

local content = Instance.new("Frame", main)
content.Position = UDim2.new(0,150,0,0)
content.Size = UDim2.new(1,-150,1,0)

-- TAB
local function tab(name)
	local b = Instance.new("TextButton", sidebar)
	b.Size = UDim2.new(1,0,0,40)
	b.Text = name
	
	local f = Instance.new("Frame", content)
	f.Size = UDim2.new(1,0,1,0)
	f.Visible = false
	
	b.MouseButton1Click:Connect(function()
		for _,v in pairs(content:GetChildren()) do
			if v:IsA("Frame") then v.Visible = false end
		end
		f.Visible = true
	end)
	return f
end

local combat = tab("Combat")
local visual = tab("Visual")
local loader = tab("Loader")
local combat = tab("Combat")
combat.Visible = true

-- BUTTON
local function btn(p,t,y,f)
	local b = Instance.new("TextButton",p)
	b.Size = UDim2.new(0,220,0,40)
	b.Position = UDim2.new(0,20,0,y)
	b.Text = t
	b.MouseButton1Click:Connect(function()
		f(b)
	end)
end

-- AUTO PARRY + CURVE AI
local lastVelocity = Vector3.new()

RunService.RenderStepped:Connect(function()
	if Config.autoParry then
		for _,v in pairs(workspace:GetChildren()) do
			if v:FindFirstChild("Hitbox") and v:FindFirstChild("Velocity") then
				
				local vel = v.Velocity
				local speed = vel.Magnitude
				local dist = (v.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
				
				local curve = (vel - lastVelocity).Magnitude > 10
				lastVelocity = vel
				
				if speed > 40 then
					local delay = dist / speed
					if curve then delay = delay * 0.6 end
					
					delay = math.clamp(delay + Config.parryDelay, 0.05, 0.25)
					
					task.delay(delay, function()
						VIM:SendMouseButtonEvent(0,0,0,true,game,0)
					end)
				end
				
			end
		end
	end
end)

-- SLIDER
local slider = Instance.new("Frame", combat)
slider.Size = UDim2.new(0,220,0,20)
slider.Position = UDim2.new(0,20,0,80)

local fill = Instance.new("Frame", slider)
fill.Size = UDim2.new(Config.parryDelay/0.3,0,1,0)

local dragging = false

slider.InputBegan:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end
end)

UIS.InputChanged:Connect(function(i)
	if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
		local x = math.clamp((i.Position.X - slider.AbsolutePosition.X)/slider.AbsoluteSize.X,0,1)
		fill.Size = UDim2.new(x,0,1,0)
		Config.parryDelay = x * 0.3
		save()
	end
end)

UIS.InputEnded:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)

-- PREDICTION MARKER
local marker = Instance.new("Part", workspace)
marker.Anchored = true
marker.Size = Vector3.new(1,1,1)
marker.Shape = Enum.PartType.Ball
marker.Color = Color3.fromRGB(0,255,100)

RunService.RenderStepped:Connect(function()
	if Config.showPrediction then
		for _,v in pairs(workspace:GetChildren()) do
			if v:FindFirstChild("Velocity") then
				
				local speed = v.Velocity.Magnitude
				local dist = (v.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
				
				if speed > 0 then
					local t = math.clamp(dist/speed,0.05,0.3)
					marker.Position = v.Position + v.Velocity * t
				end
				
			end
		end
	end
end)

-- DEBUG
local label = Instance.new("TextLabel", combat)
label.Position = UDim2.new(0,20,0,120)
label.Size = UDim2.new(0,220,0,30)
label.BackgroundTransparency = 1

RunService.RenderStepped:Connect(function()
	for _,v in pairs(workspace:GetChildren()) do
		if v:FindFirstChild("Velocity") then
			label.Text = "Speed: "..math.floor(v.Velocity.Magnitude)
		end
	end
end)

-- BUTTONS
btn(combat,"Auto Parry",20,function()
	Config.autoParry = not Config.autoParry
	save()
end)

btn(visual,"Prediction",20,function()
	Config.showPrediction = not Config.showPrediction
	save()
end)

btn(loader,"Load Module",20,function()
	local code = GitHub.load("module.lua")
	if code then loadstring(code)() end
end)

-- TOGGLE UI
UIS.InputBegan:Connect(function(i)
	if i.KeyCode == Enum.KeyCode.RightControl then
		main.Visible = not main.Visible
	end
end)
