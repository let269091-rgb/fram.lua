
-- DX TAME CHEST ESP + AUTO FARM
-- Dành cho game Roblox Studio của bạn
-- Rương: tag "Chest" hoặc tên có chữ "chest"

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local remote = ReplicatedStorage:WaitForChild("ChestCollectRequest")
local playerGui = player:WaitForChild("PlayerGui")

local old = playerGui:FindFirstChild("DXTameChestUI")
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "DXTameChestUI"
gui.ResetOnSpawn = false
gui.Parent = playerGui

local function make(class, props, parent)
    local obj = Instance.new(class)
    for k, v in pairs(props) do obj[k] = v end
    obj.Parent = parent
    return obj
end

local panel = make("Frame", {
    Size = UDim2.fromOffset(285, 350),
    Position = UDim2.new(0.5, -142, 0.5, -175),
    BackgroundColor3 = Color3.fromRGB(18, 20, 32),
    BorderSizePixel = 0,
}, gui)
make("UICorner", {CornerRadius = UDim.new(0, 12)}, panel)

local stroke = make("UIStroke", {
    Thickness = 2,
    Color = Color3.fromRGB(0, 220, 255),
}, panel)

local title = make("TextLabel", {
    Size = UDim2.new(1, -15, 0, 38),
    Position = UDim2.fromOffset(10, 0),
    BackgroundTransparency = 1,
    Text = "DX TAME | CHEST",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 18,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left,
}, panel)

local function button(text, y)
    local b = make("TextButton", {
        Size = UDim2.new(1, -24, 0, 35),
        Position = UDim2.fromOffset(12, y),
        BackgroundColor3 = Color3.fromRGB(38, 43, 64),
        Text = text,
        TextColor3 = Color3.new(1, 1, 1),
        TextSize = 13,
        Font = Enum.Font.GothamSemibold,
        AutoButtonColor = true,
    }, panel)
    make("UICorner", {CornerRadius = UDim.new(0, 7)}, b)
    return b
end

local espBtn = button("Chest ESP: OFF", 48)
local distBtn = button("Distance: ON", 89)
local listBtn = button("Chest List: ON", 130)
local farmBtn = button("AUTO FARM: OFF", 171)
local stopBtn = button("STOP AUTO FARM", 212)
local refreshBtn = button("REFRESH CHESTS", 253)

local status = make("TextLabel", {
    Size = UDim2.new(1, -24, 0, 26),
    Position = UDim2.fromOffset(12, 296),
    BackgroundTransparency = 1,
    Text = "Status: Ready",
    TextColor3 = Color3.fromRGB(180, 220, 255),
    TextSize = 12,
    Font = Enum.Font.Gotham,
}, panel)

local chestList = make("TextLabel", {
    Size = UDim2.new(1, -24, 0, 0),
    Position = UDim2.fromOffset(12, 324),
    BackgroundTransparency = 1,
    Text = "",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top,
    Visible = false,
}, panel)

local orb = make("TextButton", {
    Size = UDim2.fromOffset(54, 54),
    Position = UDim2.new(0.8, 0, 0.5, 0),
    BackgroundColor3 = Color3.fromRGB(23, 26, 43),
    Text = "DX",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 17,
    Font = Enum.Font.GothamBold,
    Visible = false,
}, gui)
make("UICorner", {CornerRadius = UDim.new(1, 0)}, orb)
make("UIStroke", {Thickness = 2, Color = Color3.fromRGB(0, 220, 255)}, orb)

-- Kéo thả menu và nút tròn bằng chuột/cảm ứng
local function draggable(object, handle)
    local dragging = false
    local startInput, startPos

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            startInput = input
            startPos = object.Position
        end
    end)

    handle.InputEnded:Connect(function(input)
        if input == startInput then dragging = false end
    end)

    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - startInput.Position
            object.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

draggable(panel, title)
draggable(orb, orb)

local minimized = false
local function minimize()
    minimized = not minimized
    panel.Visible = not minimized
    orb.Visible = minimized
end
local minimizeBtn = make("TextButton", {
    Size = UDim2.fromOffset(30, 28),
    Position = UDim2.new(1, -38, 0, 5),
    BackgroundColor3 = Color3.fromRGB(55, 60, 83),
    Text = "—",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 18,
}, panel)
make("UICorner", {CornerRadius = UDim.new(0, 6)}, minimizeBtn)
minimizeBtn.Activated:Connect(minimize)
orb.Activated:Connect(minimize)

local espOn = false
local distanceOn = true
local listOn = true
local farming = false
local busy = false
local highlights = {}
local labels = {}
local currentTween

local function isChest(obj)
    return CollectionService:HasTag(obj, "Chest")
        or string.find(string.lower(obj.Name), "chest", 1, true) ~= nil
end

local function positionOf(obj)
    if obj:IsA("BasePart") then return obj.Position end
    if obj:IsA("Model") then return obj:GetPivot().Position end
end

local function getChests()
    local result = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if isChest(obj) and positionOf(obj)
        and not obj:GetAttribute("Collected") then
            table.insert(result, obj)
        end
    end
    return result
end

local function clearVisuals()
    for obj, item in pairs(highlights) do
        if item then item:Destroy() end
        highlights[obj] = nil
    end
    for obj, item in pairs(labels) do
        if item then item:Destroy() end
        labels[obj] = nil
    end
end

local function updateVisuals()
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local chests = getChests()
    local rows = {}

    for _, chest in ipairs(chests) do
        local pos = positionOf(chest)
        if pos and root then
            local d = (root.Position - pos).Magnitude
            table.insert(rows, {obj = chest, distance = d})

            if espOn then
                if not highlights[chest] then
                    local h = Instance.new("Highlight")
                    h.FillTransparency = 0.65
                    h.OutlineColor = Color3.fromRGB(0, 255, 220)
                    h.Parent = chest
                    highlights[chest] = h
                end

                if distanceOn then
                    local adornee = chest:IsA("Model") and chest
                        or (chest:IsA("BasePart") and chest or nil)

                    if adornee and not labels[chest] then
                        local bb = Instance.new("BillboardGui")
                        bb.Name = "DXChestDistance"
                        bb.Size = UDim2.fromOffset(140, 25)
                        bb.StudsOffset = Vector3.new(0, 3, 0)
                        bb.AlwaysOnTop = true
                        bb.Adornee = adornee
                        bb.Parent = playerGui

                        local txt = Instance.new("TextLabel")
                        txt.Size = UDim2.fromScale(1, 1)
                        txt.BackgroundTransparency = 1
                        txt.TextColor3 = Color3.new(1, 1, 1)
                        txt.TextStrokeTransparency = 0
                        txt.TextSize = 13
                        txt.Parent = bb
                        labels[chest] = bb
                    end

                    local bb = labels[chest]
                    local txt = bb and bb:FindFirstChildOfClass("TextLabel")
                    if txt then
                        txt.Text = chest.Name .. " | " .. math.floor(d) .. " studs"
                    end
                end
            end
        end
    end

    for obj, item in pairs(highlights) do
        if not obj:IsDescendantOf(workspace) or not espOn then
            item:Destroy()
            highlights[obj] = nil
        end
    end
    for obj, item in pairs(labels) do
        if not obj:IsDescendantOf(workspace) or not espOn or not distanceOn then
            item:Destroy()
            labels[obj] = nil
        end
    end

    table.sort(rows, function(a, b)
        return a.distance < b.distance
    end)

    if listOn then
        local lines = {}
        for i = 1, math.min(5, #rows) do
            table.insert(lines, string.format(
                "%d. %s - %d studs",
                i, rows[i].obj.Name, rows[i].distance
            ))
        end
        chestList.Text = #lines > 0 and table.concat(lines, "\n")
            or "Không tìm thấy rương"
        chestList.Size = UDim2.new(1, -24, 0, 85)
        chestList.Visible = true
    else
        chestList.Visible = false
    end

    return rows
end

local function stopFarm()
    farming = false
    busy = false
    if currentTween then
        currentTween:Cancel()
        currentTween = nil
    end
    farmBtn.Text = "AUTO FARM: OFF"
    status.Text = "Status: Stopped"
end

local function farmLoop()
    if busy or not farming then return end
    busy = true

    task.spawn(function()
        while farming do
            local rows = updateVisuals()
            local target = rows[1]

            if not target then
                status.Text = "Status: No chest"
                task.wait(1)
                continue
            end

            local character = player.Character
            local root = character and character:FindFirstChild("HumanoidRootPart")
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            local pos = positionOf(target.obj)

            if not root or not humanoid or humanoid.Health <= 0 or not pos then
                task.wait(0.5)
                continue
            end

            status.Text = "Going to: " .. target.obj.Name

            -- Smooth movement for your own game's test environment.
            local destination = pos + Vector3.new(0, 3, 0)
            local distance = (root.Position - destination).Magnitude
            local duration = math.clamp(distance / 65, 0.3, 4)

            currentTween = TweenService:Create(
                root,
                TweenInfo.new(duration, Enum.EasingStyle.Linear),
                {CFrame = CFrame.new(destination)}
            )
            currentTween:Play()
            currentTween.Completed:Wait()
            currentTween = nil

            if not farming then break end

            -- Server verifies distance and awards the reward.
            if target.obj:IsDescendantOf(workspace) then
                remote:FireServer(target.obj)
            end

            task.wait(0.35)
        end

        busy = false
    end)
end

espBtn.Activated:Connect(function()
    espOn = not espOn
    espBtn.Text = "Chest ESP: " .. (espOn and "ON" or "OFF")
    if not espOn then clearVisuals() end
    updateVisuals()
end)

distBtn.Activated:Connect(function()
    distanceOn = not distanceOn
    distBtn.Text = "Distance: " .. (distanceOn and "ON" or "OFF")
    updateVisuals()
end)

listBtn.Activated:Connect(function()
    listOn = not listOn
    listBtn.Text = "Chest List: " .. (listOn and "ON" or "OFF")
    updateVisuals()
end)

farmBtn.Activated:Connect(function()
    if farming then
        stopFarm()
    else
        farming = true
        farmBtn.Text = "AUTO FARM: ON"
        status.Text = "Status: Farming"
        farmLoop()
    end
end)

stopBtn.Activated:Connect(stopFarm)
refreshBtn.Activated:Connect(updateVisuals)

RunService.Heartbeat:Connect(function()
    local t = os.clock()
    local hue = (t * 0.18) % 1
    local color = Color3.fromHSV(hue, 1, 1)
    stroke.Color = color
    orb.UIStroke.Color = color
end)

task.spawn(function()
    while gui.Parent do
        updateVisuals()
        task.wait(1)
    end
end)

print("DX TAME CHEST ESP loaded")
