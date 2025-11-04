-- Основные переменные
local isKilling = false
local killInterval = 5
local killedHumanoidsCount = {}
local lastKillTime = 0
local runService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Создаем GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "KillerGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game.CoreGui

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 250, 0, 150)
Frame.Position = UDim2.new(0, 10, 0, 10)
Frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
Frame.Parent = ScreenGui

local ToggleButton = Instance.new("TextButton")
ToggleButton.Size = UDim2.new(0, 100, 0, 25)
ToggleButton.Position = UDim2.new(0, 10, 0, 10)
ToggleButton.Text = "Начать убийство"
ToggleButton.Parent = Frame

local KillCountLabel = Instance.new("TextLabel")
KillCountLabel.Size = UDim2.new(0, 230, 0, 60)
KillCountLabel.Position = UDim2.new(0, 10, 0, 45)
KillCountLabel.Text = "Жертвы:\n"
KillCountLabel.TextWrapped = true
KillCountLabel.TextXAlignment = Enum.TextXAlignment.Left
KillCountLabel.BackgroundTransparency = 1
KillCountLabel.TextColor3 = Color3.new(1,1,1)
KillCountLabel.Parent = Frame

local ProgressBar = Instance.new("Frame")
ProgressBar.Size = UDim2.new(0, 230, 0, 10)
ProgressBar.Position = UDim2.new(0, 10, 0, 115)
ProgressBar.BackgroundColor3 = Color3.fromRGB(0,255,0)
ProgressBar.Parent = Frame

local function updateProgressBar(progress)
    ProgressBar.Size = UDim2.new(progress, 0, 0, 10)
end

local function toggleKilling()
    isKilling = not isKilling
    if isKilling then
        ToggleButton.Text = "Стоп"
    else
        ToggleButton.Text = "Начать убийство"
    end
end

ToggleButton.MouseButton1Click:Connect(toggleKilling)

-- Функция для поиска NPC
local function findHumanoids()
    local npcs = {}
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("Humanoid") and v.Parent:FindFirstChildOfClass("Humanoid") then
            -- исключаем игроков
            if not game.Players:GetPlayerFromCharacter(v.Parent) then
                table.insert(npcs, v.Parent)
            end
        end
    end
    return npcs
end

-- Подсветка NPC
local function highlightNPC(npc)
    if not npc then return end
    local highlight = npc:FindFirstChild("Highlight")
    if not highlight then
        highlight = Instance.new("Highlight")
        highlight.Adornee = npc
        highlight.FillColor = Color3.fromRGB(255, 0, 0)
        highlight.OutlineColor = Color3.fromRGB(255, 255, 0)
        highlight.Parent = npc
    end
    highlight.Enabled = isKilling
end

local function removeHighlight(npc)
    if npc then
        local highlight = npc:FindFirstChild("Highlight")
        if highlight then
            highlight.Enabled = false
        end
    end
end

-- Основной цикл убийства
runService.Heartbeat:Connect(function()
    if isKilling then
        local currentTime = tick()
        local elapsed = currentTime - lastKillTime
        updateProgressBar(elapsed / killInterval)
        if elapsed >= killInterval then
            -- Убить NPC
            local npcs = findHumanoids()
            for _, npc in pairs(npcs) do
                local humanoid = npc:FindFirstChildOfClass("Humanoid")
                if humanoid and humanoid.Health > 0 then
                    -- Подсветка
                    highlightNPC(npc)
                    -- Убийство
                    humanoid.Health = 0
                end
            end
            lastKillTime = currentTime
            -- Обновление GUI
            updateKillCount()
        end
    else
        updateProgressBar(0)
    end
end)

-- Обновление счетчика
local function updateKillCount()
    killedHumanoidsCount = {}
    for _, npc in pairs(findHumanoids()) do
        local name = npc.Name
        if killedHumanoidsCount[name] then
            killedHumanoidsCount[name] = killedHumanoidsCount[name] + 1
        else
            killedHumanoidsCount[name] = 1
        end
    end
    local displayText = "Жертвы:\n"
    for name, count in pairs(killedHumanoidsCount) do
        displayText = displayText .. name
        if count > 1 then
            displayText = displayText .. " x" .. count
        end
        displayText = displayText .. "\n"
    end
    KillCountLabel.Text = displayText
end

-- Обновление GUI каждые 0.5 сек
while true do
    wait(0.5)
    updateKillCount()
end

-- Перемещение GUI
local dragging = false
local dragInput, dragStart, startPos

Frame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = Frame.Position
    end
end)

Frame.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

Frame.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
        local delta = dragInput.Position - dragStart
        Frame.Position = startPos + UDim2.new(0, delta.X, 0, delta.Y)
    end
end)
