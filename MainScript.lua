local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- Localized Globals for High-Frequency Optimization
local table_clear = table.clear
local table_find = table.find
local table_insert = table.insert
local math_min = math.min
local math_clamp = math.clamp
local math_deg = math.deg
local math_rad = math.rad
local os_clock = os.time
local vector3_new = Vector3.new
local cframe_new = CFrame.new
local cframe_lookAt = CFrame.lookAt

-- File-level scoping for Linoria UI components and services
local Options, Toggles, Window, Library, ThemeManager, SaveManager
local Tabs
local killerHighlights = {}
local survivorHighlights = {}

-- VirtualInputManager setup
local VirtualInputManager = nil
pcall(function()
    VirtualInputManager = game:GetService("VirtualInputManager")
end)

-- Configurations
local enabled = false

-- Visual Configurations
local visualKillerHighlightEnabled = false
local visualKillerOutlineTransparency = 0.5
local visualKillerFillTransparency = 0.85

local visualSurvivorHighlightEnabled = false
local visualSurvivorOutlineTransparency = 0.5
local visualSurvivorFillTransparency = 0.85

-- Auto M1 Configurations
local autoM1Enabled = false
local autoM1Range = 5
local autoM1ConeAngle = 90
local autoM1AimDuration = 1.5
local autoM1MaxPrediction = 0.2
local autoM1AimSpeed = 15
local autoM1VisualizerEnabled = true
local leftConeLine = nil
local rightConeLine = nil
local autoM1Circle = nil
local autoM1AimbotActive = false
local autoM1AimbotStart = 0
local autoM1AimbotTarget = nil

-- UI Styling Configurations
local guiCornerRadius = 8
local cornerConnection = nil

-- Stamina Configurations
local staminaEnabled = false
local MAX_STAMINA = 100
local MIN_STAMINA = -20
local STAMINA_GAIN = 100
local STAMINA_LOSS = 5
local SPRINT_SPEED = 40
local INF_STAMINA = true

-- Full Bright Configurations
local fullBrightEnabled = false
local originalLightingSettings = {
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    ColorShift_Bottom = Lighting.ColorShift_Bottom,
    ColorShift_Top = Lighting.ColorShift_Top,
    ExposureCompensation = Lighting.ExposureCompensation,
    GlobalShadows = Lighting.GlobalShadows,
    Brightness = Lighting.Brightness,
}

-- Lobby Configurations
local LOBBY_POSITION = vector3_new(0, 5, 0)
local LOBBY_RADIUS = 220
local isUnloaded = false
local autoM1Connection = nil

-- High Efficiency Cache Tables
local killerNameCheckCache = {}
local killerHumanoidCache = {}
local killerHrpCache = {}
local survivorHumanoidCache = {}
local survivorHrpCache = {}

local cachedHelpless = false
local lastHelplessCheck = 0
local HELPLESS_CACHE_INTERVAL = 0.5 

local cachedM1CD = false
local lastM1CDCheck = 0

local cachedSprintingModule = nil

local function safeConnect(button, eventName, callback)
    local event = nil
    pcall(function()
        event = button[eventName]
    end)
    if event and type(event) == "userdata" and type(event.Connect) == "function" then
        pcall(function()
            event:Connect(callback)
        end)
    end
end

local function getCharacterInfo()
    local char = LocalPlayer.Character
    if not char then return nil, nil, nil end
    local hum = char:FindFirstChildWhichIsA("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    return char, hum, hrp
end

local function isLocalPlayerSurvivor()
    local char = LocalPlayer.Character
    if not char then return false end
    
    local isKillerAttr = char:GetAttribute("Role") == "Killer" 
        or char:GetAttribute("role") == "Killer" 
        or char:GetAttribute("IsKiller") == true 
        or char:GetAttribute("isKiller") == true
    
    return not isKillerAttr
end

local function checkHelplessStatus()
    local now = os_clock()
    if now - lastHelplessCheck < HELPLESS_CACHE_INTERVAL then
        return cachedHelpless
    end
    lastHelplessCheck = now

    local character = LocalPlayer.Character
    if not character then 
        cachedHelpless = false
        return false 
    end

    for name, value in pairs(character:GetAttributes()) do
        if name:lower():find("helpless") then
            if value == true or value == "Helpless" or (type(value) == "number" and value > 0) then
                cachedHelpless = true
                return true
            end
        end
    end

    for _, child in ipairs(character:GetChildren()) do
        if child.Name:lower():find("helpless") then
            if child:IsA("ValueBase") then
                if child.Value == true or child.Value == 1 or (type(child.Value) == "number" and child.Value > 0) then
                    cachedHelpless = true
                    return true
                end
            else
                cachedHelpless = true
                return true
            end
        end
    end

    local statusFolders = {
        character:FindFirstChild("StatusEffects"),
        character:FindFirstChild("Status"),
        character:FindFirstChild("Effects"),
        LocalPlayer:FindFirstChild("StatusEffects"),
        LocalPlayer:FindFirstChild("Status"),
        LocalPlayer:FindFirstChild("Effects")
    }

    for _, statusFolder in ipairs(statusFolders) do
        if statusFolder then
            for _, child in ipairs(statusFolder:GetChildren()) do
                if child.Name:lower():find("helpless") then
                    if child:IsA("ValueBase") then
                        if child.Value == true or child.Value == 1 or (type(child.Value) == "number" and child.Value > 0) then
                            cachedHelpless = true
                            return true
                        end
                    else
                        cachedHelpless = true
                        return true
                    end
                end
            end
        end
    end

    local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if playerGui then
        local mainUI = playerGui:FindFirstChild("MainUI") or playerGui:FindFirstChild("Main")
        if mainUI and mainUI.Enabled then
            for _, child in ipairs(mainUI:GetChildren()) do
                if child.Name:lower():find("helpless") and child.Visible then
                    cachedHelpless = true
                    return true
                end
                if child.Name == "Status" or child.Name == "Effects" or child.Name == "StatusEffects" then
                    for _, subChild in ipairs(child:GetChildren()) do
                        if subChild.Name:lower():find("helpless") and (subChild:IsA("ValueBase") or subChild.Visible) then
                            cachedHelpless = true
                            return true
                        end
                    end
                end
            end
        end
    end

    cachedHelpless = false
    return false
end

local isCurrentlyInMatch = false
local lastInMatchCheck = 0
local IN_MATCH_CHECK_INTERVAL = 0.5

local function updateInMatchCache()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then
        isCurrentlyInMatch = false
        return
    end

    local distance = (char.HumanoidRootPart.Position - LOBBY_POSITION).Magnitude
    if distance <= LOBBY_RADIUS then
        isCurrentlyInMatch = false
        return
    end

    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if pg then
        local mainUI = pg:FindFirstChild("MainUI")
        if mainUI and not mainUI.Enabled then
            isCurrentlyInMatch = false
            return
        end

        for _, uiName in ipairs({"Lobby", "LobbyUI", "Menu", "MenuUI", "MainMenu", "IntroUI", "SpectateUI"}) do
            local ui = pg:FindFirstChild(uiName)
            if ui and ui.Enabled then
                isCurrentlyInMatch = false
                return
            end
        end
    end

    local generatorExists = false
    if Workspace:FindFirstChild("Generator", true) then
        generatorExists = true
    end

    local hasMap = Workspace:FindFirstChild("Map") or Workspace:FindFirstChild("Arena") or generatorExists
    if not hasMap and distance < 800 then
        isCurrentlyInMatch = false
        return
    end

    isCurrentlyInMatch = true
end

local function inMatch()
    if os_clock() - lastInMatchCheck >= IN_MATCH_CHECK_INTERVAL then
        lastInMatchCheck = os_clock()
        pcall(updateInMatchCache)
    end
    return isCurrentlyInMatch
end

local function notify(title, text, duration)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = duration or 3
        })
    end)
end

LocalPlayer.CharacterAdded:Connect(function(char)
    cachedSprintingModule = nil
    cachedM1Btn = nil
    cachedM1CooldownObj = nil
    local hum = char:WaitForChild("Humanoid", 10)
    if hum then pcall(function() hum.AutoRotate = true end) end
end)

local function readCooldownValue(cdObj)
    if not cdObj then return nil end
    if cdObj:IsA("NumberValue") then
        return cdObj.Value
    end
    if cdObj:IsA("StringValue") then
        return tonumber(cdObj.Value)
    end
    if cdObj:IsA("TextLabel") or cdObj:IsA("TextBox") then
        return tonumber(cdObj.Text)
    end
    if cdObj.Value ~= nil then
        if type(cdObj.Value) == "number" then return cdObj.Value end
        if type(cdObj.Value) == "string" then return tonumber(cdObj.Value) end
    end
    if cdObj.Text ~= nil then
        return tonumber(cdObj.Text)
    end
    return nil
end

local cachedM1Btn = nil
local function getM1Button()
    if cachedM1Btn and cachedM1Btn.Parent then
        return cachedM1Btn
    end
    
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if not pg then return nil end
    local mainUI = pg:FindFirstChild("MainUI")
    if not mainUI then return nil end
    local container = mainUI:FindFirstChild("AbilityContainer")
    if not container then return nil end
    
    -- Exclude complex utility and non-M1 abilities across all killer kits
    local blacklist = {
        "unstable", "eye", "eyes", "infection", "entanglement", "rejuvenate", "block", 
        "heal", "teleport", "ability", "skill", "shield", "dodge", "run", "dash",
        "behead", "gashing", "wound", "raging", "pace", "prankster", "void rush", "rush",
        "mass infection", "rejuvenate the rotten", "void", "nova", "observant", 
        "hallucination", "hallucinations", "blood hook", "bloodhook", "ascension", 
        "cataclysm", "hunter's feast", "hunters feast", "leap", "gaze", "corrupt", 
        "nature", "trap", "traps", "spike", "spikes"
    }
    
    -- Target basic attack keywords
    local targetNames = {
        "slash", "swing", "punch", "stab", "lacerate", "bite", "claw", "hit", "thrust", "dagger"
    }
    
    local children = container:GetChildren()
    
    local function isBtnBlacklisted(btnName)
        for _, bName in ipairs(blacklist) do
            if btnName:find(bName) then
                return true
            end
        end
        return false
    end
    
    -- Pass 1: Exact target name match
    for _, child in ipairs(children) do
        local name = child.Name:lower()
        if not isBtnBlacklisted(name) then
            for _, tName in ipairs(targetNames) do
                if name == tName then
                    cachedM1Btn = child
                    return child
                end
            end
        end
    end
    
    -- Pass 2: Target name substring match
    for _, child in ipairs(children) do
        local name = child.Name:lower()
        if not isBtnBlacklisted(name) then
            for _, tName in ipairs(targetNames) do
                if name:find(tName) then
                    cachedM1Btn = child
                    return child
                end
            end
        end
    end
    
    -- Pass 3: Hotkey checks (M1, LMB, Click)
    for _, child in ipairs(children) do
        local name = child.Name:lower()
        if not isBtnBlacklisted(name) then
            local hotkey = child:FindFirstChild("Hotkey") or child:FindFirstChild("Keybind") or child:FindFirstChild("Key")
            if hotkey and (hotkey:IsA("TextLabel") or hotkey:IsA("TextBox")) then
                local txt = hotkey.Text:lower()
                if txt == "m1" or txt == "lmb" or txt == "click" or txt:find("mouse") then
                    cachedM1Btn = child
                    return child
                end
            end
        end
    end
    
    -- Pass 4: Fallback to the first non-blacklisted button
    for _, child in ipairs(children) do
        if child:IsA("GuiObject") and child.Visible then
            local name = child.Name:lower()
            if not isBtnBlacklisted(name) and name ~= "uipadding" and name ~= "uilistlayout" and name ~= "uigridlayout" then
                cachedM1Btn = child
                return child
            end
        end
    end
    
    return nil
end

local cachedM1CooldownObj = nil
local function getM1Cooldown()
    if cachedM1CooldownObj and cachedM1CooldownObj.Parent then
        return cachedM1CooldownObj
    end

    local btn = getM1Button()
    if not btn then return nil end
    local cd = btn:FindFirstChild("CooldownTime")
        or btn:FindFirstChild("Cooldown")
        or btn:FindFirstChildWhichIsA("NumberValue")
        or btn:FindFirstChildWhichIsA("StringValue")
    if cd then 
        cachedM1CooldownObj = cd
        return cd 
    end
    local lbl = btn:FindFirstChild("CooldownLabel") or btn:FindFirstChild("Timer") or btn:FindFirstChild("CD")
    if lbl then 
        cachedM1CooldownObj = lbl
        return lbl 
    end
    return nil
end

local function isM1OnCooldown()
    local cdObj = getM1Cooldown()
    if not cdObj then return false end
    local val = readCooldownValue(cdObj)
    return (val and val > 0.1) or false
end

local function isM1OnCooldownCached()
    local now = os_clock()
    if now - lastM1CDCheck < 0.05 then
        return cachedM1CD
    end
    lastM1CDCheck = now
    cachedM1CD = isM1OnCooldown()
    return cachedM1CD
end

local function isValidKillerModel(model)
    if not model then return false end
    if model == LocalPlayer.Character then return false end
    
    -- Exclude NPCs
    if model:GetAttribute("NPC") == true or model:GetAttribute("IsNPC") == true then
        return false
    end

    local humanoid = killerHumanoidCache[model]
    if not humanoid or not humanoid.Parent then
        humanoid = model:FindFirstChildWhichIsA("Humanoid")
        killerHumanoidCache[model] = humanoid
    end

    if not humanoid or not humanoid.Health or humanoid.Health <= 0 then
        return false
    end

    local hrp = killerHrpCache[model]
    if not hrp or not hrp.Parent then
        hrp = model:FindFirstChild("HumanoidRootPart")
        killerHrpCache[model] = hrp
    end
    if not hrp then return false end

    local isClean = killerNameCheckCache[model]
    if isClean == nil then
        local lowerName = model.Name:lower()
        if lowerName:find("clone") or lowerName:find("npc") or lowerName:find("fake") then
            killerNameCheckCache[model] = false
            isClean = false
        else
            killerNameCheckCache[model] = true
            isClean = true
        end
    end

    return isClean
end

local function isValidSurvivor(model)
    if not model then return false end
    if model == LocalPlayer.Character then return false end
    
    -- Exclude NPCs
    if model:GetAttribute("NPC") == true or model:GetAttribute("IsNPC") == true then
        return false
    end

    -- Parent hierarchy check to filter out players in the killer directory
    if model.Parent and (model.Parent.Name == "Killers" or (model.Parent.Parent and model.Parent.Parent.Name == "Killers")) then
        return false
    end

    -- Explicit killer role markers
    local isKillerAttr = model:GetAttribute("Role") == "Killer" 
        or model:GetAttribute("role") == "Killer" 
        or model:GetAttribute("IsKiller") == true 
        or model:GetAttribute("isKiller") == true
    if isKillerAttr then
        return false
    end

    -- Comprehensive check against known killers to prevent green highlights on killers
    local lowerName = model.Name:lower()
    local killerNames = {"slasher", "c00lkidd", "john doe", "noli", "1x1x1x1", "guest 666", "nosferatu", "jason", "doombringer", "azure", "slenderman", "zombie king", "kool killer", "drakobloxxer", "phosphorus", "charlatan", "flowers", "guest 1458", "the masked", "the decayed", "sorcus"}
    for _, kName in ipairs(killerNames) do
        if lowerName == kName or lowerName:find(kName) then
            return false
        end
    end

    local humanoid = survivorHumanoidCache[model]
    if not humanoid or not humanoid.Parent then
        humanoid = model:FindFirstChildWhichIsA("Humanoid")
        survivorHumanoidCache[model] = humanoid
    end

    if not humanoid or not humanoid.Health or humanoid.Health <= 0 then
        return false
    end

    local hrp = survivorHrpCache[model]
    if not hrp or not hrp.Parent then
        hrp = model:FindFirstChild("HumanoidRootPart")
        survivorHrpCache[model] = hrp
    end
    if not hrp then return false end

    local player = Players:GetPlayerFromCharacter(model)
    if player then
        if lowerName:find("clone") or lowerName:find("npc") or lowerName:find("fake") then
            return false
        end
        return true
    end

    local playersFolder = Workspace:FindFirstChild("Players")
    if playersFolder and model.Parent == playersFolder then
        if lowerName:find("clone") or lowerName:find("npc") or lowerName:find("fake") then
            return false
        end
        return true
    end

    if lowerName:find("clone") or lowerName:find("npc") or lowerName:find("fake") then
        return false
    end

    local survivorNames = {"twotime", "guest 1337", "dusekkar", "chance", "veeronica", "builderman", "taph", "noob", "shedletsky", "007n7", "elliot", "jane doe"}
    for _, sName in ipairs(survivorNames) do
        if lowerName:find(sName) then
            return true
        end
    end

    return false
end

local function updateGuiCorners(radiusValue)
    local gui = Library and Library.ScreenGui
    if not gui then
        gui = game:GetService("CoreGui"):FindFirstChild("Obsidian") or game:GetService("CoreGui"):FindFirstChild("HighPingedBackstab")
    end
    if gui then
        for _, child in ipairs(gui:GetDescendants()) do
            if child:IsA("UICorner") then
                pcall(function()
                    child.CornerRadius = UDim.new(0, radiusValue)
                end)
            end
        end
        
        if cornerConnection then
            cornerConnection:Disconnect()
            cornerConnection = nil
        end
        
        cornerConnection = gui.DescendantAdded:Connect(function(descendant)
            if descendant:IsA("UICorner") then
                task.wait()
                pcall(function()
                    descendant.CornerRadius = UDim.new(0, guiCornerRadius)
                end)
            end
        end)
    end
end

local cachedKillers = {}
local lastKillersRefresh = 0
local KILLERS_REFRESH_INTERVAL = 0.5

local function updateKillersCache()
    table_clear(killerNameCheckCache)
    table_clear(killerHumanoidCache)
    table_clear(killerHrpCache)
    table_clear(cachedKillers)
    
    local playersFolder = Workspace:FindFirstChild("Players")
    
    local killersFolder = playersFolder and playersFolder:FindFirstChild("Killers")
    if killersFolder then
        for _, c in ipairs(killersFolder:GetChildren()) do
            if c:IsA("Model") and c:FindFirstChild("HumanoidRootPart") then
                table_insert(cachedKillers, c)
            end
        end
    end
    
    local workspaceKillers = Workspace:FindFirstChild("Killers")
    if workspaceKillers then
        for _, c in ipairs(workspaceKillers:GetChildren()) do
            if c:IsA("Model") and c:FindFirstChild("HumanoidRootPart") and not table_find(cachedKillers, c) then
                table_insert(cachedKillers, c)
            end
        end
    end

    if playersFolder then
        for _, c in ipairs(playersFolder:GetChildren()) do
            if c:IsA("Model") and c ~= LocalPlayer.Character and c:FindFirstChild("HumanoidRootPart") then
                local isKillerAttr = c:GetAttribute("Role") == "Killer" or c:GetAttribute("role") == "Killer" or c:GetAttribute("IsKiller") == true or c:GetAttribute("isKiller") == true
                if isKillerAttr then
                    if not table_find(cachedKillers, c) then
                        table_insert(cachedKillers, c)
                    end
                end
            end
        end
    end

    if #cachedKillers == 0 and inMatch() then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local charModel = p.Character
                local isKillerAttr = charModel:GetAttribute("Role") == "Killer" 
                    or charModel:GetAttribute("role") == "Killer" 
                    or charModel:GetAttribute("IsKiller") == true 
                    or charModel:GetAttribute("isKiller") == true
                
                if isKillerAttr then
                    table_insert(cachedKillers, charModel)
                end
            end
        end
    end
end

local function getKillersList()
    if os_clock() - lastKillersRefresh >= KILLERS_REFRESH_INTERVAL then
        lastKillersRefresh = os_clock()
        pcall(updateKillersCache)
    end
    return cachedKillers
end

local cachedSurvivors = {}
local lastSurvivorsRefresh = 0
local SURVIVORS_REFRESH_INTERVAL = 0.5 

local function updateSurvivorsCache()
    table_clear(survivorHumanoidCache)
    table_clear(survivorHrpCache)
    table_clear(cachedSurvivors)
    
    local killers = getKillersList()
    local playersFolder = Workspace:FindFirstChild("Players")
    
    if playersFolder then
        for _, c in ipairs(playersFolder:GetChildren()) do
            if c:IsA("Model") and c ~= LocalPlayer.Character and c:FindFirstChild("HumanoidRootPart") then
                if not table_find(killers, c) and isValidSurvivor(c) then
                    table_insert(cachedSurvivors, c)
                end
            end
        end
    end

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local charModel = p.Character
            if not table_find(killers, charModel) and isValidSurvivor(charModel) and not table_find(cachedSurvivors, charModel) then
                table_insert(cachedSurvivors, charModel)
            end
        end
    end
end

local function getSurvivorsList()
    if os_clock() - lastSurvivorsRefresh >= SURVIVORS_REFRESH_INTERVAL then
        lastSurvivorsRefresh = os_clock()
        pcall(updateSurvivorsCache)
    end
    return cachedSurvivors
end

local function triggerAutoM1Aimbot(target)
    if not inMatch() or autoM1AimbotActive then return end
    
    autoM1AimbotActive = true
    autoM1AimbotStart = os_clock()
    autoM1AimbotTarget = target
    
    local _, humanoid, _ = getCharacterInfo()
    if humanoid then
        pcall(function() humanoid.AutoRotate = false end)
    end
end

local function tryActivateButton(btn)
    if not btn then return false end
    
    local activated = false

    pcall(function()
        if btn.Activate then 
            btn:Activate() 
            activated = true
        end
    end)

    local ok, conns = pcall(function()
        if type(getconnections) == "function" then
            local foundConns = {}
            local events = {btn.MouseButton1Click, btn.Activated}
            for _, event in ipairs(events) do
                if event then
                    for _, conn in ipairs(getconnections(event)) do
                        table_insert(foundConns, conn)
                    end
                end
            end
            return foundConns
        end
        return nil
    end)

    if ok and conns then
        for _, conn in ipairs(conns) do
            pcall(function()
                if conn.Function then
                    conn.Function()
                    activated = true
                elseif conn.func then
                    conn.func()
                    activated = true
                elseif conn.Fire then
                    conn.Fire()
                    activated = true
                end
            end)
        end
    end

    if not activated and VirtualInputManager then
        pcall(function()
            local absPos = btn.AbsolutePosition
            local absSize = btn.AbsoluteSize
            local clickX = absPos.X + (absSize.X / 2)
            local clickY = absPos.Y + (absSize.Y / 2) + 58
            
            VirtualInputManager:SendTouchEvent(1, 0, clickX, clickY)
            task.wait(0.01)
            VirtualInputManager:SendTouchEvent(1, 2, clickX, clickY)
            
            VirtualInputManager:SendMouseButtonEvent(clickX, clickY, 0, true, game, 1)
            task.wait(0.01)
            VirtualInputManager:SendMouseButtonEvent(clickX, clickY, 0, false, game, 1)
            activated = true
        end)
    end

    return activated
end

local function applyFullBright()
    if fullBrightEnabled then
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
        Lighting.ColorShift_Bottom = Color3.fromRGB(0, 0, 0)
        Lighting.ColorShift_Top = Color3.fromRGB(0, 0, 0)
        Lighting.ExposureCompensation = 0.5
        Lighting.GlobalShadows = false
        Lighting.Brightness = 2
    else
        Lighting.Ambient = originalLightingSettings.Ambient
        Lighting.OutdoorAmbient = originalLightingSettings.OutdoorAmbient
        Lighting.ColorShift_Bottom = originalLightingSettings.ColorShift_Bottom
        Lighting.ColorShift_Top = originalLightingSettings.ColorShift_Top
        Lighting.ExposureCompensation = originalLightingSettings.ExposureCompensation
        Lighting.GlobalShadows = originalLightingSettings.GlobalShadows
        Lighting.Brightness = originalLightingSettings.Brightness
    end
end

-- Safely applies custom stats to the retrieved Sprinting module
local function applyCustomStats(stamina)
    if not stamina then return end
    stamina.MaxStamina = MAX_STAMINA
    stamina.MinStamina = MIN_STAMINA
    stamina.StaminaGain = STAMINA_GAIN
    stamina.StaminaLoss = STAMINA_LOSS
    stamina.SprintSpeed = SPRINT_SPEED
    stamina.StaminaLossDisabled = INF_STAMINA
end

-- Retrieves the Sprinting module dynamically via the requested path
local function getSprintingModule()
    if cachedSprintingModule then 
        return cachedSprintingModule 
    end
    
    local success, res = pcall(function()
        local Sprinting = game:GetService("ReplicatedStorage").Systems.Character.Game.Sprinting
        return require(Sprinting)
    end)
    
    if success and type(res) == "table" then
        cachedSprintingModule = res
        return res
    end
    return nil
end

task.spawn(function()
    local wasHelpless = false
    while true do
        if isUnloaded then break end
        local isHelpless = checkHelplessStatus()
        
        if isHelpless and not wasHelpless then
            print("[SCRIPT ALERT]: Survivor is now HELPLESS! Skills locked.")
            wasHelpless = true
        elseif not isHelpless and wasHelpless then
            print("[SCRIPT ALERT]: Helpless status cleared. Skills available.")
            wasHelpless = false
        end
        task.wait(0.5)
    end
end)

local successLoad, loadError = pcall(function()
    local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
    Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
    ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
    SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()
end)

if not successLoad or not Library then
    warn("Obsidian library failed to load correctly: " .. tostring(loadError))
end

local ui_refs = {}

if Library then
    Library.ForceCheckbox = false
    Library.ShowToggleFrameInKeybinds = true

    Window = Library:CreateWindow({
        Title = "(HighPingedBackstab)[â­]",
        Footer = "Made By: PingTooHigh! Join the Disc :D",
        NotifySide = "Right",
        ShowCustomCursor = true,
    })

    task.spawn(function()
        local titleLabel = nil
        for i = 1, 20 do
            if not Library.ScreenGui then task.wait(0.05) continue end
            for _, desc in ipairs(Library.ScreenGui:GetDescendants()) do
                if desc:IsA("TextLabel") and desc.Text == "(HighPingedBackstab)[â­]" then
                    titleLabel = desc
                    break
                end
            end
            if titleLabel then break end
            task.wait(0.05)
        end

        if titleLabel then
            local topbar = titleLabel.Parent
            if topbar then
                local discordBtn = Instance.new("ImageButton")
                discordBtn.Name = "DiscordTopRightButton"
                discordBtn.BackgroundTransparency = 1
                discordBtn.Image = "rbxassetid://15243171358"
                discordBtn.ImageColor3 = Color3.fromRGB(114, 137, 218)
                discordBtn.Size = UDim2.fromOffset(16, 16)
                discordBtn.ZIndex = titleLabel.ZIndex + 5

                local rightOffset = -28
                for _, child in ipairs(topbar:GetChildren()) do
                    if (child:IsA("ImageButton") or child:IsA("TextButton")) and child.Name ~= "DiscordTopRightButton" then
                        if child.Position.X.Scale >= 0.8 then
                            local offset = child.Position.X.Offset
                            if offset < rightOffset then
                                rightOffset = offset - 22
                            end
                        end
                    end
                end

                discordBtn.Position = UDim2.new(1, rightOffset, 0.5, -8)
                discordBtn.Parent = topbar

                titleLabel.Size = UDim2.new(1, rightOffset - 15, 1, 0)
                titleLabel.TextTruncate = Enum.TextTruncate.AtEnd

                discordBtn.MouseButton1Click:Connect(function()
                    local invite = "https://discord.gg/CYAmmsuRa"
                    local setClipboard = setclipboard or writeclipboard or toclipboard or (Clipboard and Clipboard.set)
                    if setClipboard then
                        pcall(setClipboard, invite)
                        notify("Discord Invite Copied", "Link copied to clipboard! Paste it into your browser.", 5)
                    else
                        notify("Discord Server Invite", invite, 10)
                    end
                end)

                discordBtn.MouseEnter:Connect(function()
                    discordBtn.ImageColor3 = Color3.fromRGB(140, 160, 255)
                end)
                discordBtn.MouseLeave:Connect(function()
                    discordBtn.ImageColor3 = Color3.fromRGB(114, 137, 218)
                end)
            end
        end
    end)

    Tabs = {
        Combat = Window:AddTab("Combat", "swords"),
        Killer = Window:AddTab("Killer", "skull"),
        Visuals = Window:AddTab("Visuals", "eye"),
        Stamina = Window:AddTab("Stamina", "zap"),
        ["UI Settings"] = Window:AddTab("Settings", "settings"),
    }

    local CombatGroup = Tabs.Combat:AddLeftGroupbox("Combat Execution")
    local KillerGroup = Tabs.Killer:AddLeftGroupbox("Auto M1 Configuration")
    local VisualsLeftGroup = Tabs.Visuals:AddLeftGroupbox("Visual Configurations")
    local StaminaLeftGroup = Tabs.Stamina:AddLeftGroupbox("Stamina Configurations")

    CombatGroup:AddButton("Twotime", function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/xzshiroofficials-jpg/Secret/refs/heads/main/Twotime.lua"))()
    end)

    CombatGroup:AddButton("Shedletsky", function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/xzshiroofficials-jpg/Secret/refs/heads/main/Shedletsky.lua"))()
    end)

    CombatGroup:AddButton("Elliot", function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/xzshiroofficials-jpg/Secret/refs/heads/main/Elliot.lua"))()
    end)

    CombatGroup:AddButton("Chance", function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/xzshiroofficials-jpg/Secret/refs/heads/main/Chance.lua"))()
    end)

    KillerGroup:AddToggle("AutoM1Toggle", {
        Text = "Auto M1",
        Tooltip = "Automatically aligns and hits target survivors in front of you",
        Default = false,
        Callback = function(Value)
            autoM1Enabled = Value
        end,
    })

    KillerGroup:AddToggle("AutoM1VisualizerToggle", {
        Text = "Visualizer",
        Tooltip = "Toggles range circle and cone line visuals",
        Default = true,
        Callback = function(Value)
            autoM1VisualizerEnabled = Value
        end,
    })

    KillerGroup:AddSlider("AutoM1Range", {
        Text = "Range",
        Default = 5,
        Min = 1,
        Max = 20,
        Rounding = 1,
        Tooltip = "Maximum distance scanning survivors",
        Callback = function(Value)
            autoM1Range = tonumber(Value) or 5
        end,
    })

    KillerGroup:AddSlider("AutoM1ConeAngle", {
        Text = "Cone Angle",
        Default = 90,
        Min = 1,
        Max = 180,
        Rounding = 0,
        Suffix = "Â°",
        Tooltip = "Target scanning window constraint in front of you",
        Callback = function(Value)
            autoM1ConeAngle = tonumber(Value) or 90
        end,
    })

    KillerGroup:AddInput("AutoM1AimDuration", {
        Text = "Aimbot Duration",
        Default = "1.5",
        Numeric = true,
        ClearTextOnFocus = false,
        Placeholder = "e.g. 1.5",
        Callback = function(Value)
            autoM1AimDuration = tonumber(Value) or 1.5
        end,
    })

    KillerGroup:AddSlider("AutoM1MaxPrediction", {
        Text = "Max Prediction Limit",
        Default = 0.2,
        Min = 0,
        Max = 1,
        Rounding = 2,
        Suffix = "s",
        Tooltip = "Velocity tracking projection timeframe",
        Callback = function(Value)
            autoM1MaxPrediction = tonumber(Value) or 0.2
        end,
    })

    KillerGroup:AddSlider("AutoM1AimSpeed", {
        Text = "Aim Speed",
        Default = 15,
        Min = 1,
        Max = 50,
        Rounding = 1,
        Tooltip = "Track target rotation transition speed",
        Callback = function(Value)
            autoM1AimSpeed = tonumber(Value) or 15
        end,
    })

    -- Killer Visual Setup
    VisualsLeftGroup:AddToggle("KillerHighlight", {
        Text = "Killer",
        Tooltip = "Highlight and outline killers in red",
        Default = false,
        Callback = function(Value)
            visualKillerHighlightEnabled = Value
        end,
    })

    VisualsLeftGroup:AddInput("KillerOutlineTransparency", {
        Text = "Killer Outline Transparency",
        Default = "0.5",
        Numeric = true,
        ClearTextOnFocus = false,
        Placeholder = "e.g. 0.5",
        Callback = function(Value)
            visualKillerOutlineTransparency = tonumber(Value) or 0.5
            for _, hl in pairs(killerHighlights) do
                if hl then hl.OutlineTransparency = visualKillerOutlineTransparency end
            end
        end,
    })

    VisualsLeftGroup:AddInput("KillerFillTransparency", {
        Text = "Killer Fill Transparency",
        Default = "0.85",
        Numeric = true,
        ClearTextOnFocus = false,
        Placeholder = "e.g. 0.85",
        Callback = function(Value)
            visualKillerFillTransparency = tonumber(Value) or 0.85
            for _, hl in pairs(killerHighlights) do
                if hl then hl.FillTransparency = visualKillerFillTransparency end
            end
        end
    })

    VisualsLeftGroup:AddDivider()

    -- Survivor Visual Setup
    VisualsLeftGroup:AddToggle("SurvivorHighlight", {
        Text = "Survivor",
        Tooltip = "Highlight and outline survivors in green",
        Default = false,
        Callback = function(Value)
            visualSurvivorHighlightEnabled = Value
        end,
    })

    VisualsLeftGroup:AddInput("SurvivorOutlineTransparency", {
        Text = "Survivor Outline Transparency",
        Default = "0.5",
        Numeric = true,
        ClearTextOnFocus = false,
        Placeholder = "e.g. 0.5",
        Callback = function(Value)
            visualSurvivorOutlineTransparency = tonumber(Value) or 0.5
            for _, hl in pairs(survivorHighlights) do
                if hl then hl.OutlineTransparency = visualSurvivorOutlineTransparency end
            end
        end,
    })

    VisualsLeftGroup:AddInput("SurvivorFillTransparency", {
        Text = "Survivor Fill Transparency",
        Default = "0.85",
        Numeric = true,
        ClearTextOnFocus = false,
        Placeholder = "e.g. 0.85",
        Callback = function(Value)
            visualSurvivorFillTransparency = tonumber(Value) or 0.85
            for _, hl in pairs(survivorHighlights) do
                if hl then hl.FillTransparency = visualSurvivorFillTransparency end
            end
        end
    })

    VisualsLeftGroup:AddDivider()

    VisualsLeftGroup:AddToggle("FullBrightToggle", {
        Text = "Full Bright",
        Tooltip = "Forces global environment illumination",
        Default = false,
        Callback = function(Value)
            fullBrightEnabled = Value
            pcall(applyFullBright)
        end,
    })

    -- Stamina Configuration Tab UI
    StaminaLeftGroup:AddToggle("EnStaminaMod", {
        Text = "EnStaminaMod",
        Tooltip = "Enables custom stamina configurations from Sprinting module",
        Default = false,
        Callback = function(Value)
            staminaEnabled = Value
            if staminaEnabled then
                local stamina = getSprintingModule()
                if stamina then pcall(applyCustomStats, stamina) end
            end
        end,
    })

    StaminaLeftGroup:AddToggle("InfStam", {
        Text = "InfStam",
        Tooltip = "Disables stamina drain (StaminaLossDisabled = true)",
        Default = true,
        Callback = function(Value)
            INF_STAMINA = Value
            if staminaEnabled then
                local stamina = getSprintingModule()
                if stamina then pcall(applyCustomStats, stamina) end
            end
        end,
    })

    StaminaLeftGroup:AddInput("MaxStaminaVal", {
        Text = "Max Stamina",
        Default = tostring(MAX_STAMINA),
        Numeric = true,
        ClearTextOnFocus = false,
        Placeholder = "100",
        Callback = function(Value)
            MAX_STAMINA = tonumber(Value) or 100
            if staminaEnabled then
                local stamina = getSprintingModule()
                if stamina then pcall(applyCustomStats, stamina) end
            end
        end,
    })

    StaminaLeftGroup:AddInput("MinStaminaVal", {
        Text = "Min Stamina",
        Default = tostring(MIN_STAMINA),
        Numeric = true,
        ClearTextOnFocus = false,
        Placeholder = "-20",
        Callback = function(Value)
            MIN_STAMINA = tonumber(Value) or -20
            if staminaEnabled then
                local stamina = getSprintingModule()
                if stamina then pcall(applyCustomStats, stamina) end
            end
        end,
    })

    StaminaLeftGroup:AddInput("StaminaGainVal", {
        Text = "Stamina Gain",
        Default = tostring(STAMINA_GAIN),
        Numeric = true,
        ClearTextOnFocus = false,
        Placeholder = "100",
        Callback = function(Value)
            STAMINA_GAIN = tonumber(Value) or 100
            if staminaEnabled then
                local stamina = getSprintingModule()
                if stamina then pcall(applyCustomStats, stamina) end
            end
        end,
    })

    StaminaLeftGroup:AddInput("StaminaLossVal", {
        Text = "Stamina Loss",
        Default = tostring(STAMINA_LOSS),
        Numeric = true,
        ClearTextOnFocus = false,
        Placeholder = "5",
        Callback = function(Value)
            STAMINA_LOSS = tonumber(Value) or 5
            if staminaEnabled then
                local stamina = getSprintingModule()
                if stamina then pcall(applyCustomStats, stamina) end
            end
        end,
    })

    StaminaLeftGroup:AddInput("SprintSpeedVal", {
        Text = "Sprint Speed",
        Default = tostring(SPRINT_SPEED),
        Numeric = true,
        ClearTextOnFocus = false,
        Placeholder = "40",
        Callback = function(Value)
            SPRINT_SPEED = tonumber(Value) or 40
            if staminaEnabled then
                local stamina = getSprintingModule()
                if stamina then pcall(applyCustomStats, stamina) end
            end
        end,
    })

    Options = Library.Options
    Toggles = Library.Toggles

    if Toggles and Toggles.AutoM1Toggle then
        Toggles.AutoM1Toggle:OnChanged(function()
            autoM1Enabled = Toggles.AutoM1Toggle.Value
        end)
    end

    if Toggles and Toggles.AutoM1VisualizerToggle then
        Toggles.AutoM1VisualizerToggle:OnChanged(function()
            autoM1VisualizerEnabled = Toggles.AutoM1VisualizerToggle.Value
        end)
    end

    if Options and Options.AutoM1Range then
        Options.AutoM1Range:OnChanged(function()
            autoM1Range = tonumber(Options.AutoM1Range.Value) or 5
        end)
    end

    if Options and Options.AutoM1ConeAngle then
        Options.AutoM1ConeAngle:OnChanged(function()
            autoM1ConeAngle = tonumber(Options.AutoM1ConeAngle.Value) or 90
        end)
    end

    if Options and Options.AutoM1MaxPrediction then
        Options.AutoM1MaxPrediction:OnChanged(function()
            autoM1MaxPrediction = tonumber(Options.AutoM1MaxPrediction.Value) or 0.2
        end)
    end

    if Options and Options.AutoM1AimSpeed then
        Options.AutoM1AimSpeed:OnChanged(function()
            autoM1AimSpeed = tonumber(Options.AutoM1AimSpeed.Value) or 15
        end)
    end

    -- Hook up changed listeners for Killer Highlights
    if Toggles and Toggles.KillerHighlight then
        Toggles.KillerHighlight:OnChanged(function()
            visualKillerHighlightEnabled = Toggles.KillerHighlight.Value
        end)
    end

    -- Hook up changed listeners for Survivor Highlights
    if Toggles and Toggles.SurvivorHighlight then
        Toggles.SurvivorHighlight:OnChanged(function()
            visualSurvivorHighlightEnabled = Toggles.SurvivorHighlight.Value
        end)
    end

    -- Hook up listeners for updated Stamina controls
    if Toggles and Toggles.EnStaminaMod then
        Toggles.EnStaminaMod:OnChanged(function()
            staminaEnabled = Toggles.EnStaminaMod.Value
            if staminaEnabled then
                local stamina = getSprintingModule()
                if stamina then pcall(applyCustomStats, stamina) end
            end
        end)
    end
    if Toggles and Toggles.InfStam then
        Toggles.InfStam:OnChanged(function()
            INF_STAMINA = Toggles.InfStam.Value
            if staminaEnabled then
                local stamina = getSprintingModule()
                if stamina then pcall(applyCustomStats, stamina) end
            end
        end)
    end

    ui_refs.Library = Library
    ui_refs.Window = Window
    ui_refs.Options = Options
    ui_refs.Toggles = Toggles

    local MenuGroup = Tabs["UI Settings"]:AddLeftGroupbox("Setting", "wrench")

    MenuGroup:AddToggle("KeybindMenuOpen", {
        Default = Library.KeybindFrame.Visible,
        Text = "Open Keybind Menu",
        Callback = function(value)
            Library.KeybindFrame.Visible = value
        end,
    })
    MenuGroup:AddToggle("ShowCustomCursor", {
        Text = "Custom Cursor",
        Default = true,
        Callback = function(Value)
            Library.ShowCustomCursor = Value
        end,
    })
    MenuGroup:AddDropdown("NotificationSide", {
        Values = { "Left", "Right" },
        Default = "Right",
        Text = "Notification Side",
        Callback = function(Value)
            pcall(function() Library:SetNotifySide(Value) end)
        end,
    })
    MenuGroup:AddDropdown("DPIDropdown", {
        Values = { "50%", "75%", "100%", "125%", "150%", "175%", "200%" },
        Default = "100%",
        Text = "DPI Scale",
        Callback = function(Value)
            Value = Value:gsub("%%", "")
            local DPI = tonumber(Value)
            pcall(function() Library:SetDPIScale(DPI) end)
        end,
    })

    MenuGroup:AddSlider("GuiCornerRadius", {
        Text = "GUI Corner Radius",
        Default = 8,
        Min = 0,
        Max = 20,
        Rounding = 0,
        Tooltip = "Adjust GUI corner roundness",
        Callback = function(Value)
            guiCornerRadius = tonumber(Value) or 8
            pcall(updateGuiCorners, guiCornerRadius)
        end,
    })

    MenuGroup:AddDivider()
    MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = true, Text = "Menu keybind" })

    MenuGroup:AddButton("unload script", function()
        isUnloaded = true
        if cornerConnection then
            pcall(function() cornerConnection:Disconnect() end)
            cornerConnection = nil
        end
        if autoM1Connection then
            pcall(function() autoM1Connection:Disconnect() end)
        end
        if leftConeLine then pcall(function() leftConeLine:Destroy() end) end
        if rightConeLine then pcall(function() rightConeLine:Destroy() end) end
        if autoM1Circle then pcall(function() autoM1Circle:Destroy() end) end
        for _, hl in pairs(killerHighlights) do
            if hl then pcall(function() hl:Destroy() end) end
        end
        for _, hl in pairs(survivorHighlights) do
            if hl then pcall(function() hl:Destroy() end) end
        end
        Library:Unload()
    end)

    _G.AutoBackstabUI = _G.AutoBackstabUI or {}
    _G.AutoBackstabUI.refs = ui_refs

    Library.ToggleKeybind = Options.MenuKeybind
    
    if ThemeManager then
        pcall(function()
            ThemeManager:SetLibrary(Library)
            ThemeManager:SetFolder("autobackstab")
            if Tabs and Tabs["UI Settings"] then
                ThemeManager:ApplyToTab(Tabs["UI Settings"])
            end
        end)
    end

    if SaveManager then
        pcall(function()
            SaveManager:SetLibrary(Library)
            SaveManager:IgnoreThemeSettings()
            SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
            SaveManager:SetFolder("autobackshot/games")
            SaveManager:SetSubFolder("Forsaken")
            if Tabs and Tabs["UI Settings"] then
                SaveManager:BuildConfigSection(Tabs["UI Settings"])
            end
            SaveManager:LoadAutoloadConfig()
        end)
    end
    
    task.spawn(function()
        task.wait(0.5)
        pcall(updateGuiCorners, guiCornerRadius)
    end)
end

RunService.Heartbeat:Connect(function(dt)
    if isUnloaded then return end
    
    if autoM1AimbotActive and autoM1AimbotTarget and autoM1AimbotTarget.Parent then
        local elapsed = os_clock() - autoM1AimbotStart
        local aimDur = autoM1AimDuration
        
        if elapsed >= aimDur or not inMatch() then
            autoM1AimbotActive = false
            autoM1AimbotTarget = nil
            local _, humanoid, _ = getCharacterInfo()
            if humanoid then
                pcall(function() humanoid.AutoRotate = true end)
            end
            return
        end
        
        local char, humanoid, hrp = getCharacterInfo()
        local khrp = autoM1AimbotTarget:FindFirstChild("HumanoidRootPart")
        if hrp and khrp then
            local predictedKPos = khrp.Position
            if autoM1MaxPrediction > 0 then
                local vel = khrp.AssemblyLinearVelocity or khrp.Velocity
                if vel and vel.Magnitude > 0.1 then
                    predictedKPos = khrp.Position + (vel * autoM1MaxPrediction)
                end
            end
            
            local targetLook = vector3_new(predictedKPos.X, hrp.Position.Y, predictedKPos.Z)
            if (targetLook - hrp.Position).Magnitude > 0.001 then
                local targetRotation = cframe_lookAt(hrp.Position, targetLook) - hrp.Position
                local currentRotation = hrp.CFrame - hrp.CFrame.Position
                local finalRotation = currentRotation:Lerp(targetRotation, math_min(1, autoM1AimSpeed * dt))
                hrp.CFrame = cframe_new(hrp.Position) * finalRotation
            end
        end
    end
end)

autoM1Connection = RunService.Heartbeat:Connect(function()
    if isUnloaded then
        if autoM1Connection then
            pcall(function() autoM1Connection:Disconnect() end)
            autoM1Connection = nil
        end
        return
    end

    if autoM1AimbotActive then return end

    if not autoM1Enabled then return end
    if isM1OnCooldownCached() then return end
    if not inMatch() then return end
    if checkHelplessStatus() then return end

    local m1Btn = getM1Button()
    if m1Btn then
        local char, humanoid, hrp = getCharacterInfo()
        if hrp and humanoid then
            local survivors = getSurvivorsList()
            for _, survivor in pairs(survivors) do
                if isValidSurvivor(survivor) then
                    local khrp = survivor:FindFirstChild("HumanoidRootPart")
                    if khrp then
                        local dist = (khrp.Position - hrp.Position).Magnitude
                        if dist <= autoM1Range then
                            local relative = khrp.Position - hrp.Position
                            local rel2d = vector3_new(relative.X, 0, relative.Z)
                            local frontVec = hrp.CFrame.LookVector
                            local front2d = vector3_new(frontVec.X, 0, frontVec.Z)
                            local passesCone = false

                            if rel2d.Magnitude > 0.001 and front2d.Magnitude > 0.001 then
                                local dot = rel2d.Unit:Dot(front2d.Unit)
                                local angleRad = math.acos(math_clamp(dot, -1, 1))
                                local angleDeg = math_deg(angleRad)
                                if angleDeg <= (autoM1ConeAngle or 90) then
                                    passesCone = true
                                end
                            end

                            if passesCone then
                                triggerAutoM1Aimbot(survivor)
                                tryActivateButton(m1Btn)
                                break
                            end
                        end
                    end
                end
            end
        end
    end
end)

local function updateM1Circle(hrp)
    if not autoM1Enabled or not autoM1VisualizerEnabled or not hrp then
        if autoM1Circle then
            autoM1Circle:Destroy()
            autoM1Circle = nil
        end
        return
    end

    if not autoM1Circle then
        autoM1Circle = Instance.new("CylinderHandleAdornment")
        autoM1Circle.Height = 0.01
        autoM1Circle.Color3 = Color3.fromRGB(0, 255, 0)
        autoM1Circle.Transparency = 0.6
        autoM1Circle.ZIndex = 10
        autoM1Circle.AlwaysOnTop = true
        autoM1Circle.Parent = Workspace:FindFirstChild("Terrain") or Workspace
    end

    autoM1Circle.Adornee = hrp
    autoM1Circle.Radius = autoM1Range
    autoM1Circle.CFrame = cframe_new(0, -hrp.Size.Y/2, 0) * CFrame.Angles(math_rad(90), 0, 0)
end

-- Visualizer refresh rate loop
task.spawn(function()
    while true do
        task.wait(0.25)
        if isUnloaded then 
            if leftConeLine then pcall(function() leftConeLine:Destroy() end) end
            if rightConeLine then pcall(function() rightConeLine:Destroy() end) end
            if autoM1Circle then pcall(function() autoM1Circle:Destroy() end) end
            break 
        end
        
        local char, _, hrp = getCharacterInfo()
        
        if autoM1Enabled and autoM1VisualizerEnabled and inMatch() and hrp then
            updateM1Circle(hrp)
            
            if leftConeLine then
                leftConeLine.Adornee = hrp
                leftConeLine.Length = autoM1Range
                leftConeLine.CFrame = CFrame.Angles(0, math_rad(180 + autoM1ConeAngle / 2), 0)
            else
                leftConeLine = Instance.new("LineHandleAdornment")
                leftConeLine.Color3 = Color3.fromRGB(0, 255, 0)
                leftConeLine.Thickness = 3
                leftConeLine.ZIndex = 10
                leftConeLine.AlwaysOnTop = true
                leftConeLine.Adornee = hrp
                leftConeLine.Length = autoM1Range
                leftConeLine.CFrame = CFrame.Angles(0, math_rad(180 + autoM1ConeAngle / 2), 0)
                leftConeLine.Parent = Workspace:FindFirstChild("Terrain") or Workspace
            end
            
            if rightConeLine then
                rightConeLine.Adornee = hrp
                rightConeLine.Length = autoM1Range
                rightConeLine.CFrame = CFrame.Angles(0, math_rad(180 - autoM1ConeAngle / 2), 0)
            else
                rightConeLine = Instance.new("LineHandleAdornment")
                rightConeLine.Color3 = Color3.fromRGB(0, 255, 0)
                rightConeLine.Thickness = 3
                rightConeLine.ZIndex = 10
                rightConeLine.AlwaysOnTop = true
                rightConeLine.Adornee = hrp
                rightConeLine.Length = autoM1Range
                rightConeLine.CFrame = CFrame.Angles(0, math_rad(180 - autoM1ConeAngle / 2), 0)
                rightConeLine.Parent = Workspace:FindFirstChild("Terrain") or Workspace
            end
        else
            if leftConeLine then pcall(function() leftConeLine:Destroy() end) leftConeLine = nil end
            if rightConeLine then pcall(function() rightConeLine:Destroy() end) rightConeLine = nil end
            updateM1Circle(nil)
        end
    end
end)

local function clearKillerHighlights()
    for model, hl in pairs(killerHighlights) do
        if hl then pcall(function() hl:Destroy() end) end
    end
    table_clear(killerHighlights)
end

local function clearSurvivorHighlights()
    for model, hl in pairs(survivorHighlights) do
        if hl then pcall(function() hl:Destroy() end) end
    end
    table_clear(survivorHighlights)
end

local function updateKillerHighlights()
    if not visualKillerHighlightEnabled then
        clearKillerHighlights()
        return
    end

    local killers = getKillersList()
    for _, killer in ipairs(killers) do
        if isValidKillerModel(killer) then
            local hl = killerHighlights[killer]
            if not hl or not hl.Parent then
                hl = Instance.new("Highlight")
                hl.OutlineColor = Color3.fromRGB(255, 0, 0) -- Red
                hl.OutlineTransparency = visualKillerOutlineTransparency
                hl.FillColor = Color3.fromRGB(255, 0, 0)
                hl.FillTransparency = visualKillerFillTransparency
                hl.Adornee = killer
                hl.Parent = killer
                killerHighlights[killer] = hl
            else
                hl.OutlineTransparency = visualKillerOutlineTransparency
                hl.FillTransparency = visualKillerFillTransparency
            end
        end
    end

    for model, hl in pairs(killerHighlights) do
        if not model or not model.Parent or not table_find(killers, model) or not isValidKillerModel(model) then
            if hl then pcall(function() hl:Destroy() end) end
            killerHighlights[model] = nil
        end
    end
end

local function updateSurvivorHighlights()
    if not visualSurvivorHighlightEnabled then
        clearSurvivorHighlights()
        return
    end

    local survivors = getSurvivorsList()
    for _, survivor in ipairs(survivors) do
        if isValidSurvivor(survivor) then
            local hl = survivorHighlights[survivor]
            if not hl or not hl.Parent then
                hl = Instance.new("Highlight")
                hl.OutlineColor = Color3.fromRGB(0, 255, 0) -- Green
                hl.OutlineTransparency = visualSurvivorOutlineTransparency
                hl.FillColor = Color3.fromRGB(0, 255, 0)
                hl.FillTransparency = visualSurvivorFillTransparency
                hl.Adornee = survivor
                hl.Parent = survivor
                survivorHighlights[survivor] = hl
            else
                hl.OutlineTransparency = visualSurvivorOutlineTransparency
                hl.FillTransparency = visualSurvivorFillTransparency
            end
        end
    end

    for model, hl in pairs(survivorHighlights) do
        if not model or not model.Parent or not table_find(survivors, model) or not isValidSurvivor(model) then
            if hl then pcall(function() hl:Destroy() end) end
            survivorHighlights[model] = nil
        end
    end
end

task.spawn(function()
    while true do
        task.wait(0.2)
        if isUnloaded then
            clearKillerHighlights()
            clearSurvivorHighlights()
            break
        end
        pcall(updateKillerHighlights)
        pcall(updateSurvivorHighlights)
    end
end)

-- Stamina Modifier Loop
task.spawn(function()
    while true do
        task.wait(0.5) -- Responsive interval for enforcement
        if isUnloaded then break end
        if staminaEnabled and inMatch() then
            pcall(function()
                local stamina = getSprintingModule()
                if stamina then
                    applyCustomStats(stamina)
                end
            end)
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(1)
        if isUnloaded then break end
        if fullBrightEnabled then
            pcall(applyFullBright)
        end
    end
end)
