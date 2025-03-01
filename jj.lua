local ESPModule = {}

-- ตัวแปรระบบ
ESPModule.ESPEnabled = false
ESPModule.ESPStore = {}

-- ระบบสีทีม
function ESPModule.getTeamColor(player)
    if player.Team then
        return player.Team.Name == "Outlaws" and Color3.new(1, 0.2, 0.2)
            or player.Team.Name == "Cowboys" and Color3.new(0.2, 0.4, 1)
    end
    return Color3.new(1, 1, 1)
end

-- สร้าง ESP
function ESPModule.createESP(player)
    if player == LocalPlayer then return end
    
    local function setupCharacter(character)
        if not character then return end
        
        local humanoid = character:FindFirstChild("Humanoid")
        local head = character:FindFirstChild("Head")
        if not humanoid or not head then return end

        local billboard = Instance.new("BillboardGui")
        billboard.Name = "ESP_" .. player.Name
        billboard.Size = UDim2.new(4, 0, 2.5, 0)
        billboard.StudsOffset = Vector3.new(0, 3, 0)
        billboard.AlwaysOnTop = true
        billboard.Adornee = head
        billboard.Parent = head

        local textLabel = Instance.new("TextLabel")
        textLabel.Size = UDim2.new(1, 0, 1, 0)
        textLabel.Position = UDim2.new(0, 0, 0, 0)
        textLabel.BackgroundTransparency = 1
        textLabel.Font = Enum.Font.GothamBold
        textLabel.TextSize = 18
        textLabel.TextStrokeTransparency = 0.5
        textLabel.TextXAlignment = Enum.TextXAlignment.Center
        textLabel.TextYAlignment = Enum.TextYAlignment.Center
        textLabel.TextColor3 = ESPModule.getTeamColor(player)
        textLabel.Parent = billboard

        ESPModule.ESPStore[player] = {
            Billboard = billboard,
            NameLabel = textLabel,
            Head = head,
            Humanoid = humanoid
        }
    end

    if player.Character then
        setupCharacter(player.Character)
    end
    
    player.CharacterAdded:Connect(function(character)
        setupCharacter(character)
    end)
end

-- อัพเดตข้อมูล ESP
local lastUpdate = 0
local updateInterval = 0.5

function ESPModule.updateESP()
    local now = tick()
    if now - lastUpdate < updateInterval then return end
    lastUpdate = now

    local localCharacter = LocalPlayer.Character
    local localRoot = localCharacter and localCharacter:FindFirstChild("HumanoidRootPart")
    if not localRoot then return end

    for player, data in pairs(ESPModule.ESPStore) do
        if player.Character and data.Head and data.Humanoid then
            data.NameLabel.TextColor3 = ESPModule.getTeamColor(player)
            
            local targetRoot = player.Character:FindFirstChild("HumanoidRootPart")
            if targetRoot then
                local distance = (localRoot.Position - targetRoot.Position).Magnitude
                
                local health = data.Humanoid.Health
                local healthColor
                if health > 75 then
                    healthColor = Color3.new(0, 1, 0)
                elseif health > 25 then
                    healthColor = Color3.new(1, 1, 0)
                else
                    healthColor = Color3.new(1, 0, 0)
                end
                
                data.NameLabel.Text = string.format("%s\n📏 %.1fm\n❤️ %.0f", player.Name, distance, health)
                data.NameLabel.TextColor3 = ESPModule.getTeamColor(player)
            end
        end
    end
end

-- ระบบเปิดปิด ESP
function ESPModule.toggleESP()
    ESPModule.ESPEnabled = not ESPModule.ESPEnabled
    if ESPModule.ESPEnabled then
        for _, player in ipairs(Players:GetPlayers()) do
            pcall(ESPModule.createESP, player)
        end
        RunService:BindToRenderStep("ESPUpdate", Enum.RenderPriority.First.Value, ESPModule.updateESP)
    else
        RunService:UnbindFromRenderStep("ESPUpdate")
        for player, data in pairs(ESPModule.ESPStore) do
            data.Billboard:Destroy()
        end
        ESPModule.ESPStore = {}
    end
end

-- ระบบจัดการผู้เล่น
Players.PlayerAdded:Connect(function(player)
    if ESPModule.ESPEnabled then
        pcall(ESPModule.createESP, player)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    if ESPModule.ESPStore[player] then
        ESPModule.ESPStore[player].Billboard:Destroy()
        ESPModule.ESPStore[player] = nil
    end
end)

return ESPModule