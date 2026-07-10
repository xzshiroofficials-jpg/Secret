local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- File-level scoping for Linoria UI components
local Options, Toggles, Window
local killerHighlights = {}

-- VirtualInputManager setup for cross-device support
local VirtualInputManager = nil
pcall(function()
    VirtualInputManager = game:GetService("VirtualInputManager")
end)

-- Reusable static Raycast and Overlap parameters to prevent garbage collection spikes
local wallCheckParams = RaycastParams.new()
wallCheckParams.FilterType = Enum.RaycastFilterType.Exclude
wallCheckParams.IgnoreWater = true

local behindDetectionParams = OverlapParams.new()
behindDetectionParams.FilterType = Enum.RaycastFilterType.Exclude

-- Configurations
local BACK_CONE_ANGLE = 90
local AUTO_STAB_RANGE = 5
local TWEEN_BEHIND_DISTANCE_WALKING = 4
local TWEEN_BEHIND_DISTANCE_SPRINTING = 6
local TWEEN_SPEED = 150
local TWEEN_DURATION = 0.2
local AIM_SPEED = 15  -- New default aimbot lerp speed
local MAX_PREDICTION = 0.2 -- Default velocity prediction time in seconds

local enabled = false
local chAimEnabled = false
local caAimEnabled = false
local cAimDuration = 1.5
local visualizerEnabled = false
local visualHighlightEnabled = false
local visualOutlineTransparency = 0.5
local visualFillTransparency = 0.85
local autoDaggerEnabled = true
local autoDaggerDelay = 0.02
local characterNoclipEnabled = false
local characterNoclipDuration = 0.8
local wallCheckEnabled = false
local lastTriggerTime = 0
local TRIGGER_DEBOUNCE = 0.5

-- Auto M1 Configuration Variables
local autoM1Enabled = false
local autoM1VisualizerEnabled = false
local autoM1Range = 5
local autoM1ConeAngle = 90
local autoM1AimDuration = 1.5
local autoM1MaxPrediction = 0.2
local autoM1AimSpeed = 15
local leftConeLine = nil
local rightConeLine = nil
local autoM1Circle = nil
local autoM1AimbotActive = false
local autoM1AimbotStart = 0
local autoM1AimbotTarget = nil

-- Shedletsky Configurations
local shAimEnabled = false
local saAimEnabled = false
local saAimDuration = 1.5
local shAimSpeed = 15
local shMaxPrediction = 0.2
local shManualAimbotActive = false
local shManualAimbotStart = 0
local shManualAimbotTarget = nil
local shAutoTowardsKiller = false
local shATKDuration = 1.5
local shATKActive = false
local shATKStart = 0

-- Chance Configurations
local chance_chAimEnabled = false
local chance_caAimEnabled = false
local chance_aimSpeed = 15
local chance_aimDuration = 1.5
local chance_maxPrediction = 0.2
local chance_tech360Enabled = false
local chance_spinDuration = 0.5
local chance_spinSpeed = 30
local chanceManualAimbotActive = false
local chanceManualAimbotStart = 0
local chanceManualAimbotTarget = nil
local chanceSpinning = false
local chanceSpinStart = 0
local chanceAimbotActiveStart = 0

-- Elliot Configurations
local elliot_chAimEnabled = false
local elliot_caAimEnabled = false
local elliot_aimSpeed = 15
local elliot_maxPrediction = 0.2
local elliot_aimDuration = 1.5
local elliot_range = 30
local elliot_visualizerEnabled = false
local elliotManualAimbotActive = false
local elliotManualAimbotStart = 0
local elliotManualAimbotTarget = nil
local elliotCircle = nil

-- BehindDetection Configurations
local behindDetectionEnabled = false
local behindDetectionVisualEnabled = true
local behindWidth = 4
local behindLength = 4
local behindHeight = 6
local behindOffset = 2
local behindBoxPart = nil
local isBehindBoxInWall = false

-- StunCDDetection Configurations
local stunCDDetectionEnabled = true
local stunCDDetectionActive = false
local stunCDDetectionTimerStart = 0
local stunCDDetectionDuration = 5
local lastNotificationTime = 0
local TARGET_ASSET_ID = "124460367514427"

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
local INF_STAMINA = false

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
local LOBBY_POSITION = Vector3.new(0, 5, 0)
local LOBBY_RADIUS = 220
local isUnloaded = false
local backstabConnection = nil
local autoM1Connection = nil

-- Manual Aimbot States
local manualAimbotActive = false
local manualAimbotStart = 0
local manualAimbotTarget = nil

-- Highly Efficient Cache Maps for State Lookups
local killerImmuneState = {}
local killerTargetAssetDetected = {}
local listenerConnections = {}
local killerNameCheckCache = {}

local function getCharacterInfo()
    local char = LocalPlayer.Character
    if not char then return nil, nil, nil end
    local hum = char:FindFirstChildWhichIsA("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    return char, hum, hrp
end

-- Optimized and Fixed function to check for Helpless status
local function checkHelplessStatus()
    local character = LocalPlayer.Character
    if not character then return false end

    -- Method 1: Check standard Character Attributes
    for _, attrName in ipairs({"Helpless", "helpless", "HELPLESS", "HelplessStatus", "Helpless_Status", "Status"}) do
        local attrVal = character:GetAttribute(attrName)
        if attrVal == true or attrVal == "Helpless" or (type(attrVal) == "number" and attrVal > 0) then
            return true
        end
    end

    -- Method 2: Check LocalPlayer Attributes
    for _, attrName in ipairs({"Helpless", "helpless", "HELPLESS", "Status"}) do
        local attrVal = LocalPlayer:GetAttribute(attrName)
        if attrVal == true or attrVal == "Helpless" or (type(attrVal) == "number" and attrVal > 0) then
            return true
        end
    end

    -- Method 3: Check for a Status Folder/Value configuration (checks game-standard StatusEffects folder)
    local statusFolders = {
        character:FindFirstChild("StatusEffects"),
        character:FindFirstChild("Status"),
        character:FindFirstChild("Effects"),
        character:FindFirstChild("Debuffs"),
        LocalPlayer:FindFirstChild("StatusEffects"),
        LocalPlayer:FindFirstChild("Status"),
        LocalPlayer:FindFirstChild("Effects"),
        LocalPlayer:FindFirstChild("Debuffs"),
        character
    }

    for _, statusFolder in ipairs(statusFolders) do
        if statusFolder then
            local helplessValue = statusFolder:FindFirstChild("Helpless") or statusFolder:FindFirstChild("helpless") or statusFolder:FindFirstChild("HELPLESS")
            if helplessValue then
                if helplessValue:IsA("ValueBase") then
                    if helplessValue.Value == true or helplessValue.Value == 1 or (type(helplessValue.Value) == "number" and helplessValue.Value > 0) or helplessValue.Value == "Helpless" then
                        return true
                    end
                else
                    return true
                end
            end
            
            -- Fallback loop checking children names
            for _, child in ipairs(statusFolder:GetChildren()) do
                local lowerChildName = child.Name:lower()
                if lowerChildName:find("helpless") then
                    if child:IsA("ValueBase") then
                        if child.Value == true or child.Value == 1 or (type(child.Value) == "number" and child.Value > 0) or child.Value == "Helpless" then
                            return true
                        end
                    else
                        return true
                    end
                end
            end
        end
    end

    -- Method 4: Optimized UI overlay checking
    local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if playerGui then
        local mainUI = playerGui:FindFirstChild("MainUI") or playerGui:FindFirstChild("Main")
        if mainUI and mainUI.Enabled then
            if mainUI:FindFirstChild("HelplessOverlay") or mainUI:FindFirstChild("ChainOverlay") or mainUI:FindFirstChild("Helpless") then
                return true
            end
            
            local container = mainUI:FindFirstChild("AbilityContainer") or mainUI:FindFirstChild("Container")
            if container then
                local helplessFrame = container:FindFirstChild("Helpless") or container:FindFirstChild("HelplessOverlay") or container:FindFirstChild("helpless")
                if helplessFrame and helplessFrame.Visible then
                    return true
                end
            end
        end
    end

    return false
end

-- Match Detection Cache
local isCurrentlyInMatch = false
local lastInMatchCheck = 0
local IN_MATCH_CHECK_INTERVAL = 0.5 -- Slowed down slightly to decrease footprint

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
    if os.clock() - lastInMatchCheck >= IN_MATCH_CHECK_INTERVAL then
        lastInMatchCheck = os.clock()
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
    local hum = char:WaitForChild("Humanoid", 10)
    if hum then pcall(function() hum.AutoRotate = true end) end
end)

-- Direct UI Scanning for Dagger Ability with Caching
local cachedDaggerBtn = nil
local function getDaggerButton()
    if cachedDaggerBtn and cachedDaggerBtn.Parent then
        return cachedDaggerBtn
    end
    
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if not pg then return nil end
    local mainUI = pg:FindFirstChild("MainUI")
    if not mainUI then return nil end
    local container = mainUI:FindFirstChild("AbilityContainer")
    if not container then return nil end
    local btn = container:FindFirstChild("Dagger")
    if btn then
        cachedDaggerBtn = btn
    end
    return btn
end

local cachedCooldownObj = nil
local function getDaggerCooldown()
    if cachedCooldownObj and cachedCooldownObj.Parent then
        return cachedCooldownObj
    end

    local btn = getDaggerButton()
    if not btn then return nil end
    local cd = btn:FindFirstChild("CooldownTime")
        or btn:FindFirstChild("Cooldown")
        or btn:FindFirstChildWhichIsA("NumberValue")
        or btn:FindFirstChildWhichIsA("StringValue")
    if cd then 
        cachedCooldownObj = cd
        return cd 
    end
    local lbl = btn:FindFirstChild("CooldownLabel") or btn:FindFirstChild("Timer") or btn:FindFirstChild("CD")
    if lbl then 
        cachedCooldownObj = lbl
        return lbl 
    end
    return nil
end

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

local function isDaggerOnCooldown()
    local cdObj = getDaggerCooldown()
    if not cdObj then return false end
    local val = readCooldownValue(cdObj)
    return (val and val > 0.1) or false
end

-- Direct UI Scanning for Slash Ability with Caching
local cachedSlashBtn = nil
local function getSlashButton()
    if cachedSlashBtn and cachedSlashBtn.Parent then
        return cachedSlashBtn
    end
    
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if not pg then return nil end
    local mainUI = pg:FindFirstChild("MainUI")
    if not mainUI then return nil end
    local container = mainUI:FindFirstChild("AbilityContainer")
    if not container then return nil end
    local btn = container:FindFirstChild("Slash")
    if btn then
        cachedSlashBtn = btn
    end
    return btn
end

local cachedSlashCooldownObj = nil
local function getSlashCooldown()
    if cachedSlashCooldownObj and cachedSlashCooldownObj.Parent then
        return cachedSlashCooldownObj
    end

    local btn = getSlashButton()
    if not btn then return nil end
    local cd = btn:FindFirstChild("CooldownTime")
        or btn:FindFirstChild("Cooldown")
        or btn:FindFirstChildWhichIsA("NumberValue")
        or btn:FindFirstChildWhichIsA("StringValue")
    if cd then 
        cachedSlashCooldownObj = cd
        return cd 
    end
    local lbl = btn:FindFirstChild("CooldownLabel") or btn:FindFirstChild("Timer") or btn:FindFirstChild("CD")
    if lbl then 
        cachedSlashCooldownObj = lbl
        return lbl 
    end
    return nil
end

local function isSlashOnCooldown()
    local cdObj = getSlashCooldown()
    if not cdObj then return false end
    local val = readCooldownValue(cdObj)
    return (val and val > 0.1) or false
end

-- Direct UI Scanning for Chance Ability with Caching (Excluding Coin Flip, Reroll, Hat Fix)
local cachedChanceBtn = nil
local function getChanceButton()
    if cachedChanceBtn and cachedChanceBtn.Parent then
        return cachedChanceBtn
    end
    
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if not pg then return nil end
    local mainUI = pg:FindFirstChild("MainUI")
    if not mainUI then return nil end
    local container = mainUI:FindFirstChild("AbilityContainer")
    if not container then return nil end
    
    -- Strictly scan for One Shot related names only, explicitly avoiding Coin Flip, Reroll, and Hat Fix
    for _, child in ipairs(container:GetChildren()) do
        local name = child.Name:lower()
        if not name:find("coin") and not name:find("flip") and not name:find("reroll") and not name:find("favor") and not name:find("fix") then
            if name:find("shot") or name:find("shoot") or name:find("flintlock") or name:find("gun") then
                cachedChanceBtn = child
                return child
            end
        end
    end
    
    local targetNames = {"One Shot", "One shot", "True One Shot", "TrueOneShot", "Shot", "Shoot", "True One-Shot", "One-Shot"}
    for _, name in ipairs(targetNames) do
        local btn = container:FindFirstChild(name)
        if btn then
            cachedChanceBtn = btn
            return btn
        end
    end
    return nil
end

-- Direct UI Scanning for Order Up Ability with Caching
local cachedOrderUpBtn = nil
local function getOrderUpButton()
    if cachedOrderUpBtn and cachedOrderUpBtn.Parent then
        return cachedOrderUpBtn
    end
    
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if not pg then return nil end
    local mainUI = pg:FindFirstChild("MainUI")
    if not mainUI then return nil end
    local container = mainUI:FindFirstChild("AbilityContainer")
    if not container then return nil end
    
    local targetNames = {"order up", "orderup", "pizza throw", "pizza"}
    for _, child in ipairs(container:GetChildren()) do
        local name = child.Name:lower()
        for _, tName in ipairs(targetNames) do
            if name == tName or name:find(tName) then
                cachedOrderUpBtn = child
                return child
            end
        end
    end
    return nil
end

local cachedOrderUpCooldownObj = nil
local function getOrderUpCooldown()
    if cachedOrderUpCooldownObj and cachedOrderUpCooldownObj.Parent then
        return cachedOrderUpCooldownObj
    end

    local btn = getOrderUpButton()
    if not btn then return nil end
    local cd = btn:FindFirstChild("CooldownTime")
        or btn:FindFirstChild("Cooldown")
        or btn:FindFirstChildWhichIsA("NumberValue")
        or btn:FindFirstChildWhichIsA("StringValue")
    if cd then 
        cachedOrderUpCooldownObj = cd
        return cd 
    end
    local lbl = btn:FindFirstChild("CooldownLabel") or btn:FindFirstChild("Timer") or btn:FindFirstChild("CD")
    if lbl then 
        cachedOrderUpCooldownObj = lbl
        return lbl 
    end
    return nil
end

local function isOrderUpOnCooldown()
    local cdObj = getOrderUpCooldown()
    if not cdObj then return false end
    local val = readCooldownValue(cdObj)
    return (val and val > 0.1) or false
end

-- Direct UI Scanning for Auto M1 Action Buttons with Caching
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
    
    local targetNames = {"slash", "punch", "stab", "carving slash", "eviscerate", "lacerate"}
    for _, child in ipairs(container:GetChildren()) do
        local name = child.Name:lower()
        for _, tName in ipairs(targetNames) do
            if name == tName or name:find(tName) then
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

local function isValidKillerModel(model)
    if not model then return false end
    if model == LocalPlayer.Character then return false end
    
    local humanoid = model:FindFirstChildWhichIsA("Humanoid")
    if not humanoid or not humanoid.Health or humanoid.Health <= 0 then
        return false
    end

    local hrp = model:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    if model:GetAttribute("NPC") == true or model:GetAttribute("IsNPC") == true then
        return false
    end

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

-- Shared dynamic cached killers retriever
local getKillersList

-- Survivor state checker (Auto M1 targets and Elliot targets)
local function isValidSurvivor(model)
    if not model then return false end
    if model == LocalPlayer.Character then return false end
    
    local humanoid = model:FindFirstChildWhichIsA("Humanoid")
    if not humanoid or not humanoid.Health or humanoid.Health <= 0 then
        return false
    end

    local hrp = model:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    if model:GetAttribute("NPC") == true or model:GetAttribute("IsNPC") == true then
        return false
    end

    local role = model:GetAttribute("Role") or model:GetAttribute("role") or ""
    if tostring(role):lower():find("killer") then
        return false
    end

    local killers = getKillersList()
    if table.find(killers, model) then
        return false
    end

    local isSurvivorAttr = model:GetAttribute("Role") == "Survivor" or model:GetAttribute("role") == "Survivor" or model:GetAttribute("IsSurvivor") == true
    if isSurvivorAttr then
        return true
    end

    local player = Players:GetPlayerFromCharacter(model)
    if player then
        return true
    end

    local lowerName = model.Name:lower()
    local survivorNames = {"twotime", "guest 1337", "dusekkar", "chance", "veeronica", "builderman", "taph", "noob", "shedletsky", "007n7", "elliot"}
    for _, sName in ipairs(survivorNames) do
        if lowerName:find(sName) then
            return true
        end
    end

    return false
end

-- Raycast Line-of-Sight Check
local function checkWall(originPart, targetPart)
    if not originPart or not targetPart then return false end
    
    wallCheckParams.FilterDescendantsInstances = {LocalPlayer.Character, targetPart.Parent}
    
    local origin = originPart.Position
    local direction = targetPart.Position - origin
    
    local result = Workspace:Raycast(origin, direction, wallCheckParams)
    return result == nil
end

-- Fast asset detector scanning single elements
local function scanDescendantForAsset(child)
    local detected = false
    pcall(function()
        if child:IsA("Sound") and child.SoundId:find(TARGET_ASSET_ID) then
            detected = true
        elseif child:IsA("Animation") and child.AnimationId:find(TARGET_ASSET_ID) then
            detected = true
        elseif (child:IsA("Decal") or child:IsA("Texture")) and child.Texture:find(TARGET_ASSET_ID) then
            detected = true
        elseif child:IsA("SpecialMesh") and (child.MeshId:find(TARGET_ASSET_ID) or child.TextureId:find(TARGET_ASSET_ID)) then
            detected = true
        elseif child:IsA("MeshPart") and (child.MeshId:find(TARGET_ASSET_ID) or child.TextureID:find(TARGET_ASSET_ID)) then
            detected = true
        end
    end)
    return detected
end

-- Highly Optimized background scanner to refresh target asset state on a model
local function updateKillerAssetDetection(killer)
    if killerTargetAssetDetected[killer] ~= nil then
        if killerTargetAssetDetected[killer] == true then return end
    end
    
    local found = false
    local hum = killer:FindFirstChildOfClass("Humanoid")
    local animator = hum and hum:FindFirstChildOfClass("Animator")
    if animator then
        local ok, tracks = pcall(function() return animator:GetPlayingAnimationTracks() end)
        if ok and tracks then
            for _, track in ipairs(tracks) do
                if track.Animation and track.Animation.AnimationId:find(TARGET_ASSET_ID) then
                    found = true
                    break
                end
            end
        end
    end
    
    if not found and killerTargetAssetDetected[killer] == nil then
        for _, desc in ipairs(killer:GetDescendants()) do
            if scanDescendantForAsset(desc) then
                found = true
                break
            end
        end
    end
    
    killerTargetAssetDetected[killer] = found
end

-- Dynamic GUI Corner Roundness Application
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
        
        -- Connect to newly added descendants to apply styling dynamically
        if not cornerConnection then
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
end

-- Expanded lists targeting variations of stun protections, cooldowns, and ability blocks
local immuneAttrs = {
    "StunImmune", "StunImmunity", "StunProtection", "Immune", "StunProtected", "NoStun", "AntiStun",
    "Stun_Immune", "Stun_Immunity", "Stun_Protection", "Stun_Protected", "No_Stun", "Anti_Stun",
    "StunCooldown", "Stun_Cooldown", "StunCD", "Stun_CD", "StunResist", "StunResistance",
    "StunBlock", "StunBlocked", "StunShield", "Protected", "SpawnProtection", "Spawn_Protection",
    "RagingPace", "Enraged", "Observant", "Cataclysm", "Rejuvenate the undead", "RejuvenateTheUndead", 
    "VoidRush", "Void Rush", "Invincible", "ActiveDash", "BloodHunt", "BloodHuntActive", "Blood Rush", "BloodRush",
    "Slateskin", "SlateSkin", "IsImmune", "StunResistant", "Stunned"
}

local immuneKeywords = {
    "stunimmune", "stunimmunity", "stunprotection", "stunprotected", "stun_immune", "stun_immunity",
    "stun_protection", "stun_protected", "nostun", "no_stun", "antistun", "anti_stun", "stuncooldown",
    "stun_cooldown", "stuncd", "stun_cd", "stunresist", "stunresistance", "stunblock", "stunblocked",
    "stunshield", "protected", "spawnprotection", "spawn_protection", "invincible", "activedash",
    "ragingpace", "enraged", "observant", "cataclysm", "rejuvenate", "voidrush", "void rush", 
    "bloodhunt", "blood rush", "bloodrush", "immune", "slateskin", "cooldown", "stunned", "unstoppable"
}

-- Checks Attributes + StatusEffects folder (Forsaken framework standard)
local function checkImmunityAttributes(killer)
    for _, attr in ipairs(immuneAttrs) do
        if killer:GetAttribute(attr) == true then
            return true
        end
    end
    
    local statusEffects = killer:FindFirstChild("StatusEffects")
    if statusEffects then
        for _, effect in ipairs(statusEffects:GetChildren()) do
            local lowerName = effect.Name:lower()
            for _, keyword in ipairs(immuneKeywords) do
                if lowerName:find(keyword) then
                    return true
                end
            end
        end
    end
    return false
end

-- Checks if the killer is playing any animations associated with stun immunity/protection
local function isPlayingStunProtectionAnimation(killer)
    local hum = killer:FindFirstChildOfClass("Humanoid")
    local animator = hum and hum:FindFirstChildOfClass("Animator")
    if animator then
        local ok, tracks = pcall(function() return animator:GetPlayingAnimationTracks() end)
        if ok and tracks then
            for _, track in ipairs(tracks) do
                local anim = track.Animation
                if anim then
                    local animId = anim.AnimationId or ""
                    local lowerAnimId = animId:lower()
                    
                    for _, keyword in ipairs(immuneKeywords) do
                        if lowerAnimId:find(keyword) then
                            return true
                        end
                    end
                end
            end
        end
    end
    return false
end

-- Deep immunity calculation process
local function updateKillerImmunityState(killer)
    if not killer then return end
    
    local immune = checkImmunityAttributes(killer)
    if immune then
        killerImmuneState[killer] = true
        return
    end
    
    if killer:FindFirstChildOfClass("ForceField") then
        killerImmuneState[killer] = true
        return
    end
    
    local hum = killer:FindFirstChildOfClass("Humanoid")
    if hum and hum.WalkSpeed >= 19.4 and hum.WalkSpeed <= 19.6 then
        killerImmuneState[killer] = true
        return
    end
    
    local statusEffects = killer:FindFirstChild("StatusEffects")
    if statusEffects then
        for _, effect in ipairs(statusEffects:GetChildren()) do
            local lowerName = effect.Name:lower()
            for _, keyword in ipairs(immuneKeywords) do
                if lowerName:find(keyword) then
                    killerImmuneState[killer] = true
                    return
                end
            end
        end
    end

    if isPlayingStunProtectionAnimation(killer) then
        killerImmuneState[killer] = true
        return
    end
    
    killerImmuneState[killer] = false
end

local function registerKillerImmunityListener(killer)
    if listenerConnections[killer] then return end
    
    listenerConnections[killer] = {}
    pcall(updateKillerImmunityState, killer)
    pcall(updateKillerAssetDetection, killer)

    -- Static attributes monitoring
    for _, attr in ipairs(immuneAttrs) do
        local signal = killer:GetAttributeChangedSignal(attr)
        if signal then
            local conn = signal:Connect(function()
                killerImmuneState[killer] = checkImmunityAttributes(killer)
            end)
            table.insert(listenerConnections[killer], conn)
        end
    end

    -- StatusEffects folder monitoring
    local statusEffects = killer:FindFirstChild("StatusEffects")
    if statusEffects then
        local onAdded = statusEffects.ChildAdded:Connect(function()
            pcall(updateKillerImmunityState, killer)
        end)
        local onRemoved = statusEffects.ChildRemoved:Connect(function()
            pcall(updateKillerImmunityState, killer)
        end)
        table.insert(listenerConnections[killer], onAdded)
        table.insert(listenerConnections[killer], onRemoved)
    else
        local parentConn
        parentConn = killer.ChildAdded:Connect(function(child)
            if child.Name == "StatusEffects" then
                pcall(updateKillerImmunityState, killer)
                local onAdded = child.ChildAdded:Connect(function()
                    pcall(updateKillerImmunityState, killer)
                end)
                local onRemoved = child.ChildRemoved:Connect(function()
                    pcall(updateKillerImmunityState, killer)
                end)
                table.insert(listenerConnections[killer], onAdded)
                table.insert(listenerConnections[killer], onRemoved)
            end
        end)
        table.insert(listenerConnections[killer], parentConn)
    end

    -- Decoupled listener tracking of added components
    local onDescAdded = killer.DescendantAdded:Connect(function(desc)
        if scanDescendantForAsset(desc) then
            killerTargetAssetDetected[killer] = true
        end
    end)
    local onDescRemoved = killer.DescendantRemoving:Connect(function()
        pcall(updateKillerAssetDetection, killer)
    end)
    table.insert(listenerConnections[killer], onDescAdded)
    table.insert(listenerConnections[killer], onDescRemoved)
end

local function unregisterKiller(killer)
    local conns = listenerConnections[killer]
    if conns then
        for _, conn in ipairs(conns) do
            pcall(function() conn:Disconnect() end)
        end
        listenerConnections[killer] = nil
    end
    killerImmuneState[killer] = nil
    killerTargetAssetDetected[killer] = nil
end

local function cleanupAllListeners()
    for killer, _ in pairs(listenerConnections) do
        unregisterKiller(killer)
    end
end

local function isKillerImmune(killer)
    if not killer then return false end
    return killerImmuneState[killer] or false
end

-- Optimized Cached Killer Query
local cachedKillers = {}
local lastKillersRefresh = 0
local KILLERS_REFRESH_INTERVAL = 0.2 -- Increased interval slightly to cut CPU lag

local function updateKillersCache()
    table.clear(killerNameCheckCache)
    local list = {}
    local playersFolder = Workspace:FindFirstChild("Players")
    
    local killersFolder = playersFolder and playersFolder:FindFirstChild("Killers")
    if killersFolder then
        for _, c in ipairs(killersFolder:GetChildren()) do
            if c:IsA("Model") and c:FindFirstChild("HumanoidRootPart") then
                table.insert(list, c)
            end
        end
    end
    
    local workspaceKillers = Workspace:FindFirstChild("Killers")
    if workspaceKillers then
        for _, c in ipairs(workspaceKillers:GetChildren()) do
            if c:IsA("Model") and c:FindFirstChild("HumanoidRootPart") and not table.find(list, c) then
                table.insert(list, c)
            end
        end
    end

    if playersFolder then
        for _, c in ipairs(playersFolder:GetChildren()) do
            if c:IsA("Model") and c ~= LocalPlayer.Character and c:FindFirstChild("HumanoidRootPart") then
                local isKillerAttr = c:GetAttribute("Role") == "Killer" or c:GetAttribute("role") == "Killer" or c:GetAttribute("IsKiller") == true or c:GetAttribute("isKiller") == true
                if isKillerAttr then
                    if not table.find(list, c) then
                        table.insert(list, c)
                    end
                end
            end
        end
    end

    if #list == 0 and inMatch() then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local charModel = p.Character
                local isKillerAttr = charModel:GetAttribute("Role") == "Killer" 
                    or charModel:GetAttribute("role") == "Killer" 
                    or charModel:GetAttribute("IsKiller") == true 
                    or charModel:GetAttribute("isKiller") == true
                
                if isKillerAttr then
                    table.insert(list, charModel)
                end
            end
        end
    end

    for _, killer in ipairs(list) do
        registerKillerImmunityListener(killer)
    end

    for killer, _ in pairs(listenerConnections) do
        if not table.find(list, killer) then
            unregisterKiller(killer)
        end
    end

    cachedKillers = list
end

getKillersList = function()
    if os.clock() - lastKillersRefresh >= KILLERS_REFRESH_INTERVAL then
        lastKillersRefresh = os.clock()
        pcall(updateKillersCache)
    end
    return cachedKillers
end

-- Active Target Survivors Cached Query
local cachedSurvivors = {}
local lastSurvivorsRefresh = 0
local SURVIVORS_REFRESH_INTERVAL = 0.2

local function updateSurvivorsCache()
    local list = {}
    local playersFolder = Workspace:FindFirstChild("Players")
    
    if playersFolder then
        for _, c in ipairs(playersFolder:GetChildren()) do
            if c:IsA("Model") and c ~= LocalPlayer.Character and c:FindFirstChild("HumanoidRootPart") then
                if isValidSurvivor(c) then
                    table.insert(list, c)
                end
            end
        end
    end

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local charModel = p.Character
            if isValidSurvivor(charModel) and not table.find(list, charModel) then
                table.insert(list, charModel)
            end
        end
    end

    cachedSurvivors = list
end

local function getSurvivorsList()
    if os.clock() - lastSurvivorsRefresh >= SURVIVORS_REFRESH_INTERVAL then
        lastSurvivorsRefresh = os.clock()
        pcall(updateSurvivorsCache)
    end
    return cachedSurvivors
end

-- Get dynamic behind distance based on the killer's current WalkSpeed
local function getBehindDistance(killer)
    if not killer then return TWEEN_BEHIND_DISTANCE_WALKING end
    local khum = killer:FindFirstChildWhichIsA("Humanoid")
    local ws = khum and khum.WalkSpeed or 16
    if ws <= 19 then
        return TWEEN_BEHIND_DISTANCE_WALKING
    elseif ws >= 20 then
        return TWEEN_BEHIND_DISTANCE_SPRINTING
    else
        return TWEEN_BEHIND_DISTANCE_WALKING
    end
end

-- Manual Aimbot Activation Handler
local function triggerManualDaggerAimbot()
    if not inMatch() or manualAimbotActive then return end
    
    local char, _, hrp = getCharacterInfo()
    if not hrp then return end
    
    local killers = getKillersList()
    local target = nil
    local minDist = math.huge
    for _, killer in ipairs(killers) do
        if isValidKillerModel(killer) then
            local khrp = killer:FindFirstChild("HumanoidRootPart")
            if khrp then
                local dist = (khrp.Position - hrp.Position).Magnitude
                if dist < minDist then
                    minDist = dist
                    target = killer
                end
            end
        end
    end
    
    if target then
        manualAimbotActive = true
        manualAimbotStart = os.clock()
        manualAimbotTarget = target
        
        local _, humanoid, _ = getCharacterInfo()
        if humanoid and (chAimEnabled or not caAimEnabled) then
            pcall(function() humanoid.AutoRotate = false end)
        end
    end
end

-- Manual Shedletsky Aimbot Activation Handler
local function triggerManualSlashAimbot()
    if not inMatch() or shManualAimbotActive then return end
    
    local char, _, hrp = getCharacterInfo()
    if not hrp then return end
    
    local killers = getKillersList()
    local target = nil
    local minDist = math.huge
    for _, killer in ipairs(killers) do
        if isValidKillerModel(killer) then
            local khrp = killer:FindFirstChild("HumanoidRootPart")
            if khrp then
                local dist = (khrp.Position - hrp.Position).Magnitude
                if dist < minDist then
                    minDist = dist
                    target = killer
                end
            end
        end
    end
    
    if target then
        shManualAimbotActive = true
        shManualAimbotStart = os.clock()
        shManualAimbotTarget = target
        
        local _, humanoid, _ = getCharacterInfo()
        if humanoid and (shAimEnabled or not saAimEnabled) then
            pcall(function() humanoid.AutoRotate = false end)
        end

        if shAutoTowardsKiller then
            local localChar = LocalPlayer.Character
            local isLocalSurvivor = true
            if localChar then
                local isKillerAttr = localChar:GetAttribute("Role") == "Killer" or localChar:GetAttribute("role") == "Killer" or localChar:GetAttribute("IsKiller") == true
                if isKillerAttr then
                    isLocalSurvivor = false
                end
            end
            
            if isLocalSurvivor then
                shATKActive = true
                shATKStart = os.clock()
            end
        end
    end
end

-- Manual Chance Aimbot Activation Handler
local function triggerManualChanceAimbot()
    if not inMatch() or chanceManualAimbotActive then return end
    
    local char, _, hrp = getCharacterInfo()
    if not hrp then return end
    
    local killers = getKillersList()
    local target = nil
    local minDist = math.huge
    for _, killer in ipairs(killers) do
        if isValidKillerModel(killer) then
            local khrp = killer:FindFirstChild("HumanoidRootPart")
            if khrp then
                local dist = (khrp.Position - hrp.Position).Magnitude
                if dist < minDist then
                    minDist = dist
                    target = killer
                end
            end
        end
    end
    
    if target then
        chanceManualAimbotActive = true
        chanceManualAimbotStart = os.clock()
        chanceManualAimbotTarget = target
        
        if chance_tech360Enabled then
            chanceSpinning = true
            chanceSpinStart = os.clock()
        else
            chanceSpinning = false
            chanceAimbotActiveStart = os.clock()
        end
        
        local _, humanoid, _ = getCharacterInfo()
        if humanoid and (chance_chAimEnabled or not chance_caAimEnabled) then
            pcall(function() humanoid.AutoRotate = false end)
        end
    end
end

-- Elliot Target Selection Algorithm based on Rectangle Mode
local function getElliotTarget()
    local char, _, hrp = getCharacterInfo()
    if not hrp then return nil end
    
    local survivors = getSurvivorsList()
    local candidates = {}
    
    for _, survivor in ipairs(survivors) do
        if isValidSurvivor(survivor) then
            local sHrp = survivor:FindFirstChild("HumanoidRootPart")
            local sHum = survivor:FindFirstChildWhichIsA("Humanoid")
            if sHrp and sHum then
                local dist = (sHrp.Position - hrp.Position).Magnitude
                if dist <= elliot_range then
                    table.insert(candidates, {
                        model = survivor,
                        hrp = sHrp,
                        hum = sHum,
                        distance = dist,
                        hp = sHum.Health
                    })
                end
            end
        end
    end
    
    if #candidates == 0 then return nil end
    
    local strategy = Options.Rectangle and Options.Rectangle.Value or "LowestHp & Nearest"
    
    if strategy == "LowestHp" then
        table.sort(candidates, function(a, b)
            return a.hp < b.hp
        end)
        return candidates[1].model
    elseif strategy == "Nearest" then
        table.sort(candidates, function(a, b)
            return a.distance < b.distance
        end)
        return candidates[1].model
    elseif strategy == "LowestHp & Nearest" then
        table.sort(candidates, function(a, b)
            if math.abs(a.hp - b.hp) < 1 then
                return a.distance < b.distance
            end
            return a.hp < b.hp
        end)
        return candidates[1].model
    end
    
    return nil
end

-- Manual Elliot Pizza Order Up Aimbot Activation Handler
local function triggerManualElliotAimbot()
    if not inMatch() or elliotManualAimbotActive then return end
    
    local target = getElliotTarget()
    if target then
        elliotManualAimbotActive = true
        elliotManualAimbotStart = os.clock()
        elliotManualAimbotTarget = target
        
        local _, humanoid, _ = getCharacterInfo()
        if humanoid and (elliot_chAimEnabled or not elliot_caAimEnabled) then
            pcall(function() humanoid.AutoRotate = false end)
        end
    end
end

-- Auto M1 Target Aimbot Activation Handler
local function triggerAutoM1Aimbot(target)
    if not inMatch() or autoM1AimbotActive then return end
    
    autoM1AimbotActive = true
    autoM1AimbotStart = os.clock()
    autoM1AimbotTarget = target
    
    local _, humanoid, _ = getCharacterInfo()
    if humanoid then
        pcall(function() humanoid.AutoRotate = false end)
    end
end

-- Connect to Dagger UI signals explicitly
local function connectDaggerButtonSignals()
    local btn = getDaggerButton()
    if btn then
        if btn:GetAttribute("AimbotConnected") then return end
        btn:SetAttribute("AimbotConnected", true)
        
        btn.MouseButton1Click:Connect(triggerManualDaggerAimbot)
        btn.Activated:Connect(triggerManualDaggerAimbot)
        if btn:IsA("ImageButton") or btn:IsA("TextButton") then
            btn.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    triggerManualDaggerAimbot()
                end
            end)
        end
    end
end

-- Connect to Slash UI signals explicitly
local function connectSlashButtonSignals()
    local btn = getSlashButton()
    if btn then
        if btn:GetAttribute("AimbotConnected") then return end
        btn:SetAttribute("AimbotConnected", true)
        
        btn.MouseButton1Click:Connect(triggerManualSlashAimbot)
        btn.Activated:Connect(triggerManualSlashAimbot)
        if btn:IsA("ImageButton") or btn:IsA("TextButton") then
            btn.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    triggerManualSlashAimbot()
                end
            end)
        end
    end
end

-- Connect to Chance UI signals explicitly (Direct Input Hooks Only)
local function connectChanceButtonSignals()
    local btn = getChanceButton()
    if btn then
        if btn:GetAttribute("AimbotConnected") then return end
        btn:SetAttribute("AimbotConnected", true)
        
        btn.MouseButton1Click:Connect(triggerManualChanceAimbot)
        btn.Activated:Connect(triggerManualChanceAimbot)
        if btn:IsA("ImageButton") or btn:IsA("TextButton") then
            btn.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    triggerManualChanceAimbot()
                end
            end)
        end
    end
end

-- Connect to Order Up UI signals explicitly
local function connectOrderUpButtonSignals()
    local btn = getOrderUpButton()
    if btn then
        if btn:GetAttribute("AimbotConnected") then return end
        btn:SetAttribute("AimbotConnected", true)
        
        btn.MouseButton1Click:Connect(triggerManualElliotAimbot)
        btn.Activated:Connect(triggerManualElliotAimbot)
        if btn:IsA("ImageButton") or btn:IsA("TextButton") then
            btn.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    triggerManualElliotAimbot()
                end
            end)
        end
    end
end

-- Connect to M1 action button signals
local function connectM1ButtonSignals()
    local btn = getM1Button()
    if btn then
        if btn:GetAttribute("AimbotConnected") then return end
        btn:SetAttribute("AimbotConnected", true)
    end
end

-- Cross-Device / Mobile Friendly Button Simulator
local function tryActivateButton(btn)
    if not btn then return false end
    
    local activated = false

    -- Method 1: Standard Roblox API Activation
    pcall(function()
        if btn.Activate then 
            btn:Activate() 
            activated = true
        end
    end)

    -- Method 2: Fire all connected signals (Standard desktop/mobile executor global)
    local ok, conns = pcall(function()
        if type(getconnections) == "function" then
            local foundConns = {}
            local events = {btn.MouseButton1Click, btn.Activated}
            for _, event in ipairs(events) do
                if event then
                    for _, conn in ipairs(getconnections(event)) do
                        table.insert(foundConns, conn)
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

    -- Method 3: Virtual Input Manager emulation
    if not activated and VirtualInputManager then
        pcall(function()
            local absPos = btn.AbsolutePosition
            local absSize = btn.AbsoluteSize
            local clickX = absPos.X + (absSize.X / 2)
            local clickY = absPos.Y + (absSize.Y / 2) + 58
            
            -- Touch Emulation
            VirtualInputManager:SendTouchEvent(1, 0, clickX, clickY)
            task.wait(0.01)
            VirtualInputManager:SendTouchEvent(1, 2, clickX, clickY)
            
            -- Mouse Emulation
            VirtualInputManager:SendMouseButtonEvent(clickX, clickY, 0, true, game, 1)
            task.wait(0.01)
            VirtualInputManager:SendMouseButtonEvent(clickX, clickY, 0, false, game, 1)
            activated = true
        end)
    end

    return activated
end

-- Full Bright Logic
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

-- Shared Configs Data cache maps and backend logic
local sharedConfigsData = {}

local function loadLocalCache()
    local dir = (SaveManager and SaveManager.Folder) or "autobackshot/games/Forsaken"
    local localCachePath = dir .. "/configs/others_configs_cache.json"
    if isfile and isfile(localCachePath) then
        local succ, data = pcall(function()
            return HttpService:JSONDecode(readfile(localCachePath))
        end)
        if succ and type(data) == "table" then
            return data
        end
    end
    return {
        { name = "Default Backstab Pro", author = "PingTooHigh", data = '{"toggles":{},"options":{}}' },
        { name = "Rage Mode Set", author = "CataclysmGod", data = '{"toggles":{},"options":{}}' },
        { name = "Legit Backstab Setup", author = "SilentAssassin", data = '{"toggles":{},"options":{}}' }
    }
end

local function saveLocalCache(tbl)
    local dir = (SaveManager and SaveManager.Folder) or "autobackshot/games/Forsaken"
    local localCachePath = dir .. "/configs/others_configs_cache.json"
    pcall(function()
        if writefile then
            local configsDir = dir .. "/configs"
            if not isfolder(dir) then pcall(makefolder, dir) end
            if not isfolder(configsDir) then pcall(makefolder, configsDir) end
            writefile(localCachePath, HttpService:JSONEncode(tbl))
        end
    end)
end

local function fetchCloudConfigs()
    local list = {}
    local onlineSuccess = false
    
    local requestFunc = (syn and syn.request) or (http and http.request) or http_request or request
    if requestFunc then
        local success, res = pcall(function()
            return requestFunc({
                Url = "https://autobackshot-configs-default-rtdb.firebaseio.com/forsaken_configs.json",
                Method = "GET"
            })
        end)
        
        if success and res and (res.StatusCode == 200 or res.Status == 200) then
            local data = nil
            pcall(function()
                data = HttpService:JSONDecode(res.Body)
            end)
            if data and type(data) == "table" then
                onlineSuccess = true
                for key, value in pairs(data) do
                    if type(value) == "table" and value.name and value.data then
                        table.insert(list, {
                            id = key,
                            name = value.name,
                            author = value.author or "Anonymous",
                            data = value.data
                        })
                    end
                end
            end
        end
    end
    
    if not onlineSuccess then
        local cachedList = loadLocalCache()
        for _, value in ipairs(cachedList) do
            table.insert(list, value)
        end
    else
        saveLocalCache(list)
    end
    
    return list
end

local function publishCloudConfig(name, author, configJson)
    local payload = HttpService:JSONEncode({
        name = name,
        author = author,
        data = configJson,
        timestamp = os.time()
    })
    
    local onlineSuccess = false
    local requestFunc = (syn and syn.request) or (http and http.request) or http_request or request
    if requestFunc then
        local success, res = pcall(function()
            return requestFunc({
                Url = "https://autobackshot-configs-default-rtdb.firebaseio.com/forsaken_configs.json",
                Method = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body = payload
            })
        end)
        if success and res and (res.StatusCode == 200 or res.Status == 200 or res.StatusCode == 201) then
            onlineSuccess = true
        end
    end
    
    local cachedList = loadLocalCache()
    table.insert(cachedList, {
        name = name,
        author = author,
        data = configJson
    })
    saveLocalCache(cachedList)
    
    return true
end

local function refreshCloudList()
    notify("Cloud List", "Fetching shared configurations...", 2)
    local list = fetchCloudConfigs()
    local dropdownValues = {}
    table.clear(sharedConfigsData)
    
    for _, item in ipairs(list) do
        local displayName = item.name .. " (by " .. item.author .. ")"
        table.insert(dropdownValues, displayName)
        sharedConfigsData[displayName] = item.data
    end
    
    if Options and Options.SharedConfigsList then
        Options.SharedConfigsList:SetValues(dropdownValues)
        Options.SharedConfigsList:SetValue(nil)
    end
    notify("Cloud List", "Loaded " .. tostring(#dropdownValues) .. " configurations!", 2)
end

local function downloadSelectedConfig()
    local selected = Options.SharedConfigsList and Options.SharedConfigsList.Value
    if not selected or selected == "" then
        notify("Download Failed", "Please select a configuration from the list.", 3)
        return
    end
    
    local configJson = sharedConfigsData[selected]
    if not configJson then
        notify("Download Failed", "Selected configuration data not found.", 3)
        return
    end
    
    -- Extract clean config name
    local cleanName = selected:match("^(.-)%s*%(by%s+.+%)$") or selected
    cleanName = cleanName:gsub("[%s%p]", "_")
    
    local success, err = pcall(function()
        local folder = (SaveManager and SaveManager.Folder) or "autobackshot/games"
        local subfolder = (SaveManager and SaveManager.SubFolder) or "Forsaken"
        
        -- Aligning directly with Linoria's configuration file structures
        local settingsDir = folder .. "/settings"
        if subfolder and subfolder ~= "" then
            settingsDir = settingsDir .. "/" .. subfolder
        end
        
        if writefile then
            if not isfolder(folder) then pcall(makefolder, folder) end
            if not isfolder(folder .. "/settings") then pcall(makefolder, folder .. "/settings") end
            if subfolder and subfolder ~= "" and not isfolder(settingsDir) then
                pcall(makefolder, settingsDir)
            end
            
            writefile(settingsDir .. "/" .. cleanName .. ".json", configJson)
        else
            error("Executor is missing writefile function")
        end
    end)
    
    if success then
        notify("Download Success", "Downloaded " .. cleanName .. " to your local configs list!", 5)
        pcall(function()
            if SaveManager then
                SaveManager:RefreshConfigList()
            end
        end)
    else
        notify("Download Failed", "Error saving file: " .. tostring(err), 5)
    end
end

-- Compile UI configurations directly in memory
local function serializeConfig()
    local data = {
        toggles = {},
        options = {}
    }
    
    if not Toggles or not Options then
        return HttpService:JSONEncode(data)
    end
    
    for idx, toggle in pairs(Toggles) do
        if not (SaveManager and SaveManager.Ignore and SaveManager.Ignore[idx]) then
            pcall(function()
                data.toggles[idx] = { value = toggle.Value }
            end)
        end
    end
    
    for idx, option in pairs(Options) do
        if not (SaveManager and SaveManager.Ignore and SaveManager.Ignore[idx]) then
            pcall(function()
                if option.Type == "Slider" then
                    data.options[idx] = { value = option.Value }
                elseif option.Type == "Dropdown" then
                    data.options[idx] = { value = option.Value }
                elseif option.Type == "ColorPicker" then
                    data.options[idx] = { value = option.Value:ToHex() }
                elseif option.Type == "KeyPicker" then
                    data.options[idx] = { mode = option.Mode, key = option.Value }
                end
            end)
        end
    end
    
    return HttpService:JSONEncode(data)
end

local function publishConfig(name)
    if name == "" then
        notify("Publish Failed", "Please enter a config name.", 3)
        return
    end
    
    local successSave, data = pcall(serializeConfig)
    
    if not successSave or not data then
        notify("Publish Failed", "Failed to serialize current state.", 3)
        return
    end
    
    local authorName = game.Players.LocalPlayer.Name
    local success, msg = pcall(function()
        return publishCloudConfig(name, authorName, data)
    end)
    
    if success then
        notify("Publish Success", "Successfully published config: " .. name, 5)
        task.spawn(refreshCloudList)
    else
        notify("Publish Failed", "Error: " .. tostring(msg), 5)
    end
end

-- Continuous tracking loop for Helpless status alerts (Slowed down to prevent frame spikes)
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

-- Background Throttled Scanner Thread to refresh dynamic states of active targets
task.spawn(function()
    while true do
        task.wait(0.5) -- Throttled check rate to prevent CPU spikes on low-end devices
        if isUnloaded then break end
        
        if inMatch() then
            for _, killer in ipairs(cachedKillers) do
                if isValidKillerModel(killer) then
                    pcall(updateKillerImmunityState, killer)
                end
            end
        end
    end
end)

-- Load UI Library
local success, Library = pcall(function()
    local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
    return loadstring(game:HttpGet(repo .. "Library.lua"))()
end)

local Tabs
local ThemeManager, SaveManager
if success and Library then
    pcall(function()
        local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
        ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
        SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()
    end)
else
    warn("Obsidian library failed to load.")
end

local ui_refs = {}

if Library then
    Library.ForceCheckbox = false
    Library.ShowToggleFrameInKeybinds = true

    Window = Library:CreateWindow({
        Title = "(HighPingedBackstab)[⭐]",
        Footer = "Made By: PingTooHigh! Join the Disc :D",
        NotifySide = "Right",
        ShowCustomCursor = true,
    })

    -- Dynamically attach and align Discord button to the topbar cleanly
    task.spawn(function()
        local titleLabel = nil
        for i = 1, 20 do
            if not Library.ScreenGui then task.wait(0.05) continue end
            for _, desc in ipairs(Library.ScreenGui:GetDescendants()) do
                if desc:IsA("TextLabel") and desc.Text == "(HighPingedBackstab)[⭐]" then
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
        TwoTime = Window:AddTab("TwoTime", "sword"),
        Chance = Window:AddTab("Chance", "star"),
        Shedletsky = Window:AddTab("Shedletsky", "swords"),
        Killer = Window:AddTab("Killer", "skull"), -- New Killer Tab Added
        Elliot = Window:AddTab("Elliot", "pizza"), -- New Elliot Tab Added with Pizza Icon
        Visuals = Window:AddTab("Visuals", "eye"),
        Stamina = Window:AddTab("Stamina", "zap"),
        ["UI Settings"] = Window:AddTab("Settings", "settings"),
    }

    local LeftGroup = Tabs.TwoTime:AddLeftGroupbox("Auto Backstab Configuration")
    local BehindDetectionGroup = Tabs.TwoTime:AddRightGroupbox("BehindDetection")
    
    local ChanceGroup = Tabs.Chance:AddLeftGroupbox("Chance Configuration")
    
    local ShedletskyGroup = Tabs.Shedletsky:AddLeftGroupbox("Shedletsky Configuration")
    
    -- Killer Configuration Elements
    local KillerGroup = Tabs.Killer:AddLeftGroupbox("Auto M1 Configuration")
    
    -- Elliot Configuration Elements
    local ElliotGroup = Tabs.Elliot:AddLeftGroupbox("Elliot Configuration")
    
    local VisualsLeftGroup = Tabs.Visuals:AddLeftGroupbox("Visual Configurations")
    local StaminaLeftGroup = Tabs.Stamina:AddLeftGroupbox("Stamina Configurations")

    local function updateBackstabUIStates()
        if not Options or not Toggles then return end
        local abEnabled = Toggles.AutoBackstab and Toggles.AutoBackstab.Value or false
        
        local targetOptions = {
            Options.BackConeAngle,
            Options.AutoStabRange,
            Toggles.chAim,
            Toggles.caAim,
            Options.AimSpeed,
            Options.cAimDurationInput,
            Options.MaxPrediction,
            Toggles.Visualizer,
            Toggles.AutoDaggerToggle,
            Options.AutoDaggerDelay,
            Toggles.CharNoclip,
            Options.NoclipDuration,
            Options.TweenBehindWalking,
            Options.TweenBehindSprinting,
            Options.TweenSpeed,
            Options.TweenDuration,
            Toggles.WallCheck,
            Toggles.StunCDDetectionToggle,
            Options.StunCDDetectionDuration,
            Toggles.BehindDetectionToggle,
            Toggles.BehindDetectionVisualToggle,
            Options.BehindWidth,
            Options.BehindLength,
            Options.BehindHeight,
            Options.BehindOffset
        }
        
        for _, opt in ipairs(targetOptions) do
            if opt then
                local ok = pcall(function() opt:SetVisible(abEnabled) end)
                if not ok then
                    pcall(function() opt:SetDisabled(not abEnabled) end)
                end
            end
        end
    end

    LeftGroup:AddToggle("AutoBackstab", {
        Text = "Auto Backstab",
        Tooltip = "Enables automatic dagger alignment and scanning systems",
        Default = false,
        Callback = function(Value)
            enabled = Value
            updateBackstabUIStates()
        end,
    })

    LeftGroup:AddSlider("BackConeAngle", {
        Text = "Back Cone Angle",
        Default = 90,
        Min = 1,
        Max = 180,
        Rounding = 0,
        Suffix = "°",
        Tooltip = "Angle constraint behind the killer's view",
        Callback = function(Value)
            BACK_CONE_ANGLE = tonumber(Value) or 90
        end,
    })

    LeftGroup:AddInput("AutoStabRange", {
        Text = "Auto Backstab Range (studs)",
        Default = tostring(AUTO_STAB_RANGE),
        Numeric = true,
        ClearTextOnFocus = false,
        Placeholder = tostring(AUTO_STAB_RANGE),
        Callback = function(Value)
            AUTO_STAB_RANGE = tonumber(Value) or AUTO_STAB_RANGE
        end,
    })

    LeftGroup:AddToggle("chAim", {
        Text = "CH-Aim",
        Tooltip = "Character-based aimbot: locks character rotation to face the killer",
        Default = false,
        Callback = function(Value)
            chAimEnabled = Value
            if Value and Toggles.caAim and Toggles.caAim.Value then
                Toggles.caAim:SetValue(false)
            end
        end,
    })

    LeftGroup:AddToggle("caAim", {
        Text = "CA-Aim",
        Tooltip = "Camera-based aimbot: locks camera rotation to face the killer",
        Default = false,
        Callback = function(Value)
            caAimEnabled = Value
            if Value and Toggles.chAim and Toggles.chAim.Value then
                Toggles.chAim:SetValue(false)
            end
        end,
    })

    LeftGroup:AddSlider("AimSpeed", {
        Text = "Aim Speed",
        Default = 15,
        Min = 1,
        Max = 50,
        Rounding = 1,
        Tooltip = "Smoothness and track speed of the aimbot rotation",
        Callback = function(Value)
            AIM_SPEED = tonumber(Value) or 15
        end,
    })

    LeftGroup:AddInput("cAimDurationInput", {
        Text = "C-Aim Duration",
        Default = "1.5",
        Numeric = true,
        ClearTextOnFocus = false,
        Placeholder = "e.g. 1.5",
        Callback = function(Value)
            cAimDuration = tonumber(Value) or 1.5
        end,
    })

    LeftGroup:AddSlider("MaxPrediction", {
        Text = "Max Prediction Limit",
        Default = 0.2,
        Min = 0,
        Max = 1,
        Rounding = 2,
        Suffix = "s",
        Tooltip = "Max time (in seconds) to predict target velocity for target acquisition",
        Callback = function(Value)
            MAX_PREDICTION = tonumber(Value) or 0.2
        end,
    })

    LeftGroup:AddToggle("Visualizer", {
        Text = "Visualizer",
        Tooltip = "Draw range circle below the killer/target",
        Default = false,
        Callback = function(Value)
            visualizerEnabled = Value
        end,
    })

    LeftGroup:AddToggle("AutoDaggerToggle", {
        Text = "Auto Dagger",
        Tooltip = "Automatically triggers the dagger ability click when aligned",
        Default = true,
        Callback = function(Value)
            autoDaggerEnabled = Value
        end,
    })

    LeftGroup:AddInput("AutoDaggerDelay", {
        Text = "Auto Dagger Delay",
        Default = "0.02",
        Numeric = true,
        ClearTextOnFocus = false,
        Placeholder = "e.g. 0.02",
        Callback = function(Value)
            autoDaggerDelay = tonumber(Value) or 0.02
        end,
    })

    LeftGroup:AddToggle("CharNoclip", {
        Text = "Character Noclip",
        Tooltip = "Disables character collision only during the auto backstab movement",
        Default = false,
        Callback = function(Value)
            characterNoclipEnabled = Value
        end,
    })

    LeftGroup:AddInput("NoclipDuration", {
        Text = "Noclip Duration",
        Default = "0.8",
        Numeric = true,
        ClearTextOnFocus = false,
        Placeholder = "e.g. 0.8",
        Callback = function(Value)
            characterNoclipDuration = tonumber(Value) or 0.8
        end,
    })

    LeftGroup:AddInput("TweenBehindWalking", {
        Text = "BehindDistance(Walking)",
        Default = "4",
        Numeric = true,
        ClearTextOnFocus = false,
        Placeholder = "e.g. 4",
        Callback = function(Value)
            TWEEN_BEHIND_DISTANCE_WALKING = tonumber(Value) or 4
        end,
    })

    LeftGroup:AddInput("TweenBehindSprinting", {
        Text = "BehindDistance(Sprinting)",
        Default = "6",
        Numeric = true,
        ClearTextOnFocus = false,
        Placeholder = "e.g. 6",
        Callback = function(Value)
            TWEEN_BEHIND_DISTANCE_SPRINTING = tonumber(Value) or 6
        end,
    })

    LeftGroup:AddSlider("TweenSpeed", {
        Text = "Tween Speed",
        Default = 150,
        Min = 10,
        Max = 350,
        Rounding = 0,
        Tooltip = "Speed of the movement in studs per second",
        Callback = function(Value)
            TWEEN_SPEED = tonumber(Value) or 150
        end,
    })

    LeftGroup:AddSlider("TweenDuration", {
        Text = "Tween Duration",
        Default = 0.2,
        Min = 0,
        Max = 1,
        Rounding = 2,
        Suffix = "s",
        Tooltip = "Maximum seconds the movement is allowed to run",
        Callback = function(Value)
            TWEEN_DURATION = tonumber(Value) or 0.2
        end,
    })

    LeftGroup:AddToggle("WallCheck", {
        Text = "Wall Check",
        Tooltip = "Prevents backstabbing if there is a wall between you and the killer",
        Default = false,
        Callback = function(Value)
            wallCheckEnabled = Value
        end,
    })

    LeftGroup:AddToggle("StunCDDetectionToggle", {
        Text = "StunCDDetection",
        Tooltip = "Pauses auto backstab when target asset 124460367514427 (Cataclysm) is found on the killer",
        Default = true,
        Callback = function(Value)
            stunCDDetectionEnabled = Value
            if not Value then
                stunCDDetectionActive = false
            end
        end
    })

    LeftGroup:AddSlider("StunCDDetectionDuration", {
        Text = "StunCDDetection Detection Duration(Secs)",
        Default = 5,
        Min = 1,
        Max = 30,
        Rounding = 1,
        Suffix = "s",
        Tooltip = "Duration in seconds to pause auto backstabbing when target asset is detected",
        Callback = function(Value)
            stunCDDetectionDuration = tonumber(Value) or 5
        end,
    })

    BehindDetectionGroup:AddToggle("BehindDetectionToggle", {
        Text = "Behind Detection",
        Tooltip = "Enables custom physical checking behind the killer. Disables auto backstab when the intersection block collides with a wall",
        Default = false,
        Callback = function(Value)
            behindDetectionEnabled = Value
        end,
    })

    BehindDetectionGroup:AddToggle("BehindDetectionVisualToggle", {
        Text = "Behind Detection Visualizer",
        Tooltip = "Toggles the rendering visibility of the physical check box behind the killer",
        Default = true,
        Callback = function(Value)
            behindDetectionVisualEnabled = Value
        end,
    })

    BehindDetectionGroup:AddSlider("BehindWidth", {
        Text = "Width",
        Default = 4,
        Min = 1,
        Max = 20,
        Rounding = 1,
        Tooltip = "Width of the detection box",
        Callback = function(Value)
            behindWidth = tonumber(Value) or 4
        end,
    })

    BehindDetectionGroup:AddSlider("BehindLength", {
        Text = "Length",
        Default = 4,
        Min = 1,
        Max = 20,
        Rounding = 1,
        Tooltip = "Length of the detection box",
        Callback = function(Value)
            behindLength = tonumber(Value) or 4
        end,
    })

    BehindDetectionGroup:AddSlider("BehindHeight", {
        Text = "Height",
        Default = 6,
        Min = 1,
        Max = 20,
        Rounding = 1,
        Tooltip = "Height of the detection box",
        Callback = function(Value)
            behindHeight = tonumber(Value) or 6
        end,
    })

    BehindDetectionGroup:AddSlider("BehindOffset", {
        Text = "Offset",
        Default = 2,
        Min = 0,
        Max = 15,
        Rounding = 1,
        Tooltip = "Offset distance behind the killer",
        Callback = function(Value)
            behindOffset = tonumber(Value) or 2
        end,
    })

    -- Chance Configurations Elements
    ChanceGroup:AddLabel("Triggers ONLY when One Shot, One shot, True One Shot, or TrueOneShot ability is used.")

    ChanceGroup:AddToggle("chance_chAim", {
        Text = "CH-Aim",
        Tooltip = "Character-based aimbot: locks character rotation to face the killer",
        Default = false,
        Callback = function(Value)
            chance_chAimEnabled = Value
            if Value and Toggles.chance_caAim and Toggles.chance_caAim.Value then
                Toggles.chance_caAim:SetValue(false)
            end
        end,
    })

    ChanceGroup:AddToggle("chance_caAim", {
        Text = "CA-Aim",
        Tooltip = "Camera-based aimbot: locks camera rotation to face the killer",
        Default = false,
        Callback = function(Value)
            chance_caAimEnabled = Value
            if Value and Toggles.chance_chAim and Toggles.chance_chAim.Value then
                Toggles.chance_chAim:SetValue(false)
            end
        end,
    })

    ChanceGroup:AddSlider("chance_aimSpeed", {
        Text = "Aim Speed",
        Default = 15,
        Min = 1,
        Max = 50,
        Rounding = 1,
        Tooltip = "Smoothness and track speed of the aimbot rotation",
        Callback = function(Value)
            chance_aimSpeed = tonumber(Value) or 15
        end,
    })

    ChanceGroup:AddInput("chance_aimDurationInput", {
        Text = "Aim Duration",
        Default = "1.5",
        Numeric = true,
        ClearTextOnFocus = false,
        Placeholder = "e.g. 1.5",
        Callback = function(Value)
            chance_aimDuration = tonumber(Value) or 1.5
        end,
    })

    ChanceGroup:AddSlider("chance_maxPrediction", {
        Text = "Max Prediction Limit",
        Default = 0.2,
        Min = 0,
        Max = 1,
        Rounding = 2,
        Suffix = "s",
        Tooltip = "Max time (in seconds) to predict target velocity for target acquisition",
        Callback = function(Value)
            chance_maxPrediction = tonumber(Value) or 0.2
        end,
    })

    ChanceGroup:AddDivider()

    ChanceGroup:AddToggle("chance_tech360", {
        Text = "360Tech",
        Tooltip = "Spins your character before the lock-on aimbot activates",
        Default = false,
        Callback = function(Value)
            chance_tech360Enabled = Value
        end,
    })

    ChanceGroup:AddSlider("chance_spinDuration", {
        Text = "Spin Duration",
        Default = 0.5,
        Min = 0.1,
        Max = 3,
        Rounding = 2,
        Suffix = "s",
        Tooltip = "How long the character spins for before aiming",
        Callback = function(Value)
            chance_spinDuration = tonumber(Value) or 0.5
        end,
    })

    ChanceGroup:AddSlider("chance_spinSpeed", {
        Text = "Spin Speed",
        Default = 30,
        Min = 5,
        Max = 100,
        Rounding = 1,
        Tooltip = "The rotational speed during the 360Tech spin",
        Callback = function(Value)
            chance_spinSpeed = tonumber(Value) or 30
        end,
    })

    -- Shedletsky Configurations Elements
    ShedletskyGroup:AddToggle("shchAim", {
        Text = "CH-Aim",
        Tooltip = "Character-based aimbot: locks character rotation to face the killer",
        Default = false,
        Callback = function(Value)
            shAimEnabled = Value
            if Value and Toggles.shcaAim and Toggles.shcaAim.Value then
                Toggles.shcaAim:SetValue(false)
            end
        end,
    })

    ShedletskyGroup:AddToggle("shcaAim", {
        Text = "CA-Aim",
        Tooltip = "Camera-based aimbot: locks camera rotation to face the killer",
        Default = false,
        Callback = function(Value)
            saAimEnabled = Value
            if Value and Toggles.shchAim and Toggles.shchAim.Value then
                Toggles.shchAim:SetValue(false)
            end
        end,
    })

    ShedletskyGroup:AddSlider("shAimSpeed", {
        Text = "Aim Speed",
        Default = 15,
        Min = 1,
        Max = 50,
        Rounding = 1,
        Tooltip = "Smoothness and track speed of the aimbot rotation",
        Callback = function(Value)
            shAimSpeed = tonumber(Value) or 15
        end,
    })

    ShedletskyGroup:AddInput("shcAimDurationInput", {
        Text = "C-Aim Duration",
        Default = "1.5",
        Numeric = true,
        ClearTextOnFocus = false,
        Placeholder = "e.g. 1.5",
        Callback = function(Value)
            saAimDuration = tonumber(Value) or 1.5
        end,
    })

    ShedletskyGroup:AddSlider("shMaxPrediction", {
        Text = "Max Prediction Limit",
        Default = 0.2,
        Min = 0,
        Max = 1,
        Rounding = 2,
        Suffix = "s",
        Tooltip = "Max time (in seconds) to predict target velocity for target acquisition",
        Callback = function(Value)
            shMaxPrediction = tonumber(Value) or 0.2
        end,
    })

    ShedletskyGroup:AddToggle("shAutoTowardsKiller", {
        Text = "Auto Towards Killer",
        Tooltip = "Makes your character run towards the killer during the Slash/Shedletsky Aimbot",
        Default = false,
        Callback = function(Value)
            shAutoTowardsKiller = Value
        end,
    })

    ShedletskyGroup:AddInput("shATKDuration", {
        Text = "ATK Duration",
        Default = "1.5",
        Numeric = true,
        ClearTextOnFocus = false,
        Placeholder = "e.g. 1.5",
        Callback = function(Value)
            shATKDuration = tonumber(Value) or 1.5
        end,
    })

    -- Killer / Auto M1 UI Configurations Elements
    KillerGroup:AddToggle("AutoM1Toggle", {
        Text = "Auto M1",
        Tooltip = "Automatically aligns and hits target survivors in front of you",
        Default = false,
        Callback = function(Value)
            autoM1Enabled = Value
        end,
    })

    KillerGroup:AddToggle("AutoM1Visualizer", {
        Text = "Visualizer",
        Tooltip = "Draw range circle and cone lines around your character",
        Default = false,
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
        Suffix = "°",
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

    -- Elliot UI Configurations Elements
    ElliotGroup:AddToggle("elliot_chAim", {
        Text = "CH-Aim",
        Tooltip = "Character-based aimbot: locks character rotation to face the survivor",
        Default = false,
        Callback = function(Value)
            elliot_chAimEnabled = Value
            if Value and Toggles.elliot_caAim and Toggles.elliot_caAim.Value then
                Toggles.elliot_caAim:SetValue(false)
            end
        end,
    })

    ElliotGroup:AddToggle("elliot_caAim", {
        Text = "CA-Aim",
        Tooltip = "Camera-based aimbot: locks camera rotation to face the survivor",
        Default = false,
        Callback = function(Value)
            elliot_caAimEnabled = Value
            if Value and Toggles.elliot_chAim and Toggles.elliot_chAim.Value then
                Toggles.elliot_chAim:SetValue(false)
            end
        end,
    })

    ElliotGroup:AddSlider("elliot_aimSpeed", {
        Text = "Aim Speed",
        Default = 15,
        Min = 1,
        Max = 50,
        Rounding = 1,
        Tooltip = "Smoothness and track speed of the aimbot rotation",
        Callback = function(Value)
            elliot_aimSpeed = tonumber(Value) or 15
        end,
    })

    ElliotGroup:AddInput("elliot_aimDurationInput", {
        Text = "Aim Duration",
        Default = "1.5",
        Numeric = true,
        ClearTextOnFocus = false,
        Placeholder = "e.g. 1.5",
        Callback = function(Value)
            elliot_aimDuration = tonumber(Value) or 1.5
        end,
    })

    ElliotGroup:AddSlider("elliot_maxPrediction", {
        Text = "Max Prediction Limit",
        Default = 0.2,
        Min = 0,
        Max = 1,
        Rounding = 2,
        Suffix = "s",
        Tooltip = "Velocity tracking projection timeframe",
        Callback = function(Value)
            elliot_maxPrediction = tonumber(Value) or 0.2
        end,
    })

    ElliotGroup:AddDropdown("Rectangle", {
        Values = { "LowestHp & Nearest", "LowestHp", "Nearest" },
        Default = "LowestHp & Nearest",
        Multi = false,
        Text = "Rectangle",
        Tooltip = "Choose target prioritization mode",
    })

    ElliotGroup:AddSlider("elliot_range", {
        Text = "Range",
        Default = 30,
        Min = 1,
        Max = 100,
        Rounding = 1,
        Tooltip = "Maximum target scanning distance",
        Callback = function(Value)
            elliot_range = tonumber(Value) or 30
        end,
    })

    ElliotGroup:AddToggle("elliot_visualizer", {
        Text = "Visualizer",
        Tooltip = "Toggles range visualizer circle below your character",
        Default = false,
        Callback = function(Value)
            elliot_visualizerEnabled = Value
        end,
    })

    VisualsLeftGroup:AddToggle("KillerHighlight", {
        Text = "Visuals",
        Tooltip = "Highlight and outline killers in red",
        Default = false,
        Callback = function(Value)
            visualHighlightEnabled = Value
        end,
    })

    VisualsLeftGroup:AddInput("OutlineTransparency", {
        Text = "Outline Transparency",
        Default = "0.5",
        Numeric = true,
        ClearTextOnFocus = false,
        Placeholder = "e.g. 0.5",
        Callback = function(Value)
            visualOutlineTransparency = tonumber(Value) or 0.5
            for _, hl in pairs(killerHighlights) do
                if hl then hl.OutlineTransparency = visualOutlineTransparency end
            end
        end,
    })

    VisualsLeftGroup:AddInput("FillTransparency", {
        Text = "Fill Transparency",
        Default = "0.85",
        Numeric = true,
        ClearTextOnFocus = false,
        Placeholder = "e.g. 0.85",
        Callback = function(Value)
            visualFillTransparency = tonumber(Value) or 0.85
            for _, hl in pairs(killerHighlights) do
                if hl then hl.FillTransparency = visualFillTransparency end
            end
        end
    })

    VisualsLeftGroup:AddToggle("FullBrightToggle", {
        Text = "Full Bright",
        Tooltip = "Forces global environment illumination",
        Default = false,
        Callback = function(Value)
            fullBrightEnabled = Value
            pcall(applyFullBright)
        end,
    })

    StaminaLeftGroup:AddToggle("EnableStaminaMod", {
        Text = "Enable Stamina Mods",
        Tooltip = "Enables automatic application of customized stamina values",
        Default = false,
        Callback = function(Value)
            staminaEnabled = Value
        end,
    })

    StaminaLeftGroup:AddToggle("InfStaminaToggle", {
        Text = "Infinite Stamina",
        Tooltip = "Disables stamina loss",
        Default = false,
        Callback = function(Value)
            INF_STAMINA = Value
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
        end,
    })

    Options = Library.Options
    Toggles = Library.Toggles

    if Toggles and Toggles.AutoBackstab then
        Toggles.AutoBackstab:OnChanged(function()
            enabled = Toggles.AutoBackstab.Value
            updateBackstabUIStates()
        end)
    end

    if Options and Options.BackConeAngle then
        Options.BackConeAngle:OnChanged(function()
            BACK_CONE_ANGLE = tonumber(Options.BackConeAngle.Value) or BACK_CONE_ANGLE
        end)
    end

    if Options and Options.AutoStabRange then
        Options.AutoStabRange:OnChanged(function()
            AUTO_STAB_RANGE = tonumber(Options.AutoStabRange.Value) or AUTO_STAB_RANGE
        end)
    end

    if Toggles and Toggles.chAim then
        Toggles.chAim:OnChanged(function()
            chAimEnabled = Toggles.chAim.Value
            if chAimEnabled and Toggles.caAim and Toggles.caAim.Value then
                Toggles.caAim:SetValue(false)
            end
        end)
    end

    if Toggles and Toggles.caAim then
        Toggles.caAim:OnChanged(function()
            caAimEnabled = Toggles.caAim.Value
            if caAimEnabled and Toggles.chAim and Toggles.chAim.Value then
                Toggles.chAim:SetValue(false)
            end
        end)
    end

    if Options and Options.AimSpeed then
        Options.AimSpeed:OnChanged(function()
            AIM_SPEED = tonumber(Options.AimSpeed.Value) or AIM_SPEED
        end)
    end

    if Options and Options.cAimDurationInput then
        Options.cAimDurationInput:OnChanged(function()
            cAimDuration = tonumber(Options.cAimDurationInput.Value) or 1.5
        end)
    end

    if Options and Options.MaxPrediction then
        Options.MaxPrediction:OnChanged(function()
            MAX_PREDICTION = tonumber(Options.MaxPrediction.Value) or 0.2
        end)
    end

    if Toggles and Toggles.Visualizer then
        Toggles.Visualizer:OnChanged(function()
            visualizerEnabled = Toggles.Visualizer.Value
        end)
    end

    if Toggles and Toggles.AutoDaggerToggle then
        Toggles.AutoDaggerToggle:OnChanged(function()
            autoDaggerEnabled = Toggles.AutoDaggerToggle.Value
        end)
    end

    if Options and Options.AutoDaggerDelay then
        Options.AutoDaggerDelay:OnChanged(function()
            autoDaggerDelay = tonumber(Options.AutoDaggerDelay.Value) or 0.02
        end)
    end

    if Toggles and Toggles.CharNoclip then
        Toggles.CharNoclip:OnChanged(function()
            characterNoclipEnabled = Toggles.CharNoclip.Value
        end)
    end

    if Options and Options.NoclipDuration then
        Options.NoclipDuration:OnChanged(function()
            characterNoclipDuration = tonumber(Options.NoclipDuration.Value) or 0.8
        end)
    end

    if Options and Options.TweenBehindWalking then
        Options.TweenBehindWalking:OnChanged(function()
            TWEEN_BEHIND_DISTANCE_WALKING = tonumber(Options.TweenBehindWalking.Value) or 4
        end)
    end

    if Options and Options.TweenBehindSprinting then
        Options.TweenBehindSprinting:OnChanged(function()
            TWEEN_BEHIND_DISTANCE_SPRINTING = tonumber(Options.TweenBehindSprinting.Value) or 6
        end)
    end

    if Options and Options.TweenSpeed then
        Options.TweenSpeed:OnChanged(function()
            TWEEN_SPEED = tonumber(Options.TweenSpeed.Value) or 150
        end)
    end

    if Options and Options.TweenDuration then
        Options.TweenDuration:OnChanged(function()
            TWEEN_DURATION = tonumber(Options.TweenDuration.Value) or 0.2
        end)
    end

    if Toggles and Toggles.WallCheck then
        Toggles.WallCheck:OnChanged(function()
            wallCheckEnabled = Toggles.WallCheck.Value
        end)
    end

    if Toggles and Toggles.StunCDDetectionToggle then
        Toggles.StunCDDetectionToggle:OnChanged(function()
            stunCDDetectionEnabled = Toggles.StunCDDetectionToggle.Value
            if not stunCDDetectionEnabled then
                stunCDDetectionActive = false
            end
        end)
    end

    if Options and Options.StunCDDetectionDuration then
        Options.StunCDDetectionDuration:OnChanged(function()
            stunCDDetectionDuration = tonumber(Options.StunCDDetectionDuration.Value) or 5
        end)
    end

    if Toggles and Toggles.BehindDetectionToggle then
        Toggles.BehindDetectionToggle:OnChanged(function()
            behindDetectionEnabled = Toggles.BehindDetectionToggle.Value
        end)
    end
    if Toggles and Toggles.BehindDetectionVisualToggle then
        Toggles.BehindDetectionVisualToggle:OnChanged(function()
            behindDetectionVisualEnabled = Toggles.BehindDetectionVisualToggle.Value
        end)
    end
    if Options and Options.BehindWidth then
        Options.BehindWidth:OnChanged(function()
            behindWidth = tonumber(Options.BehindWidth.Value) or behindWidth
        end)
    end
    if Options and Options.BehindLength then
        Options.BehindLength:OnChanged(function()
            behindLength = tonumber(Options.BehindLength.Value) or behindLength
        end)
    end
    if Options and Options.BehindHeight then
        Options.BehindHeight:OnChanged(function()
            behindHeight = tonumber(Options.BehindHeight.Value) or behindHeight
        end)
    end
    if Options and Options.BehindOffset then
        Options.BehindOffset:OnChanged(function()
            behindOffset = tonumber(Options.BehindOffset.Value) or behindOffset
        end)
    end

    -- Chance Changed Listeners
    if Toggles and Toggles.chance_chAim then
        Toggles.chance_chAim:OnChanged(function()
            chance_chAimEnabled = Toggles.chance_chAim.Value
            if chance_chAimEnabled and Toggles.chance_caAim and Toggles.chance_caAim.Value then
                Toggles.chance_caAim:SetValue(false)
            end
        end)
    end

    if Toggles and Toggles.chance_caAim then
        Toggles.chance_caAim:OnChanged(function()
            chance_caAimEnabled = Toggles.chance_caAim.Value
            if chance_caAimEnabled and Toggles.chance_chAim and Toggles.chance_chAim.Value then
                Toggles.chance_chAim:SetValue(false)
            end
        end)
    end

    if Options and Options.chance_aimSpeed then
        Options.chance_aimSpeed:OnChanged(function()
            chance_aimSpeed = tonumber(Options.chance_aimSpeed.Value) or chance_aimSpeed
        end)
    end

    if Options and Options.chance_aimDurationInput then
        Options.chance_aimDurationInput:OnChanged(function()
            chance_aimDuration = tonumber(Options.chance_aimDurationInput.Value) or 1.5
        end)
    end

    if Options and Options.chance_maxPrediction then
        Options.chance_maxPrediction:OnChanged(function()
            chance_maxPrediction = tonumber(Options.chance_maxPrediction.Value) or 0.2
        end)
    end

    if Toggles and Toggles.chance_tech360 then
        Toggles.chance_tech360:OnChanged(function()
            chance_tech360Enabled = Toggles.chance_tech360.Value
        end)
    end

    if Options and Options.chance_spinDuration then
        Options.chance_spinDuration:OnChanged(function()
            chance_spinDuration = tonumber(Options.chance_spinDuration.Value) or 0.5
        end)
    end

    if Options and Options.chance_spinSpeed then
        Options.chance_spinSpeed:OnChanged(function()
            chance_spinSpeed = tonumber(Options.chance_spinSpeed.Value) or 30
        end)
    end

    -- Shedletsky Changed Listeners
    if Toggles and Toggles.shchAim then
        Toggles.shchAim:OnChanged(function()
            shAimEnabled = Toggles.shchAim.Value
            if shAimEnabled and Toggles.shcaAim and Toggles.shcaAim.Value then
                Toggles.shcaAim:SetValue(false)
            end
        end)
    end

    if Toggles and Toggles.shcaAim then
        Toggles.shcaAim:OnChanged(function()
            saAimEnabled = Toggles.shcaAim.Value
            if saAimEnabled and Toggles.shchAim and Toggles.shchAim.Value then
                Toggles.shchAim:SetValue(false)
            end
        end)
    end

    if Options and Options.shAimSpeed then
        Options.shAimSpeed:OnChanged(function()
            shAimSpeed = tonumber(Options.shAimSpeed.Value) or shAimSpeed
        end)
    end

    if Options and Options.shcAimDurationInput then
        Options.shcAimDurationInput:OnChanged(function()
            saAimDuration = tonumber(Options.shcAimDurationInput.Value) or 1.5
        end)
    end

    if Options and Options.shMaxPrediction then
        Options.shMaxPrediction:OnChanged(function()
            shMaxPrediction = tonumber(Options.shMaxPrediction.Value) or 0.2
        end)
    end

    if Toggles and Toggles.shAutoTowardsKiller then
        Toggles.shAutoTowardsKiller:OnChanged(function()
            shAutoTowardsKiller = Toggles.shAutoTowardsKiller.Value
        end)
    end

    if Options and Options.shATKDuration then
        Options.shATKDuration:OnChanged(function()
            shATKDuration = tonumber(Options.shATKDuration.Value) or 1.5
        end)
    end

    -- Auto M1 Listeners Connection
    if Toggles and Toggles.AutoM1Toggle then
        Toggles.AutoM1Toggle:OnChanged(function()
            autoM1Enabled = Toggles.AutoM1Toggle.Value
        end)
    end

    if Toggles and Toggles.AutoM1Visualizer then
        Toggles.AutoM1Visualizer:OnChanged(function()
            autoM1VisualizerEnabled = Toggles.AutoM1Visualizer.Value
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

    if Options and Options.AutoM1AimDuration then
        Options.AutoM1AimDuration:OnChanged(function()
            autoM1AimDuration = tonumber(Options.AutoM1AimDuration.Value) or 1.5
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

    -- Elliot Changed Listeners
    if Toggles and Toggles.elliot_chAim then
        Toggles.elliot_chAim:OnChanged(function()
            elliot_chAimEnabled = Toggles.elliot_chAim.Value
            if elliot_chAimEnabled and Toggles.elliot_caAim and Toggles.elliot_caAim.Value then
                Toggles.elliot_caAim:SetValue(false)
            end
        end)
    end

    if Toggles and Toggles.elliot_caAim then
        Toggles.elliot_caAim:OnChanged(function()
            elliot_caAimEnabled = Toggles.elliot_caAim.Value
            if elliot_caAimEnabled and Toggles.elliot_chAim and Toggles.elliot_chAim.Value then
                Toggles.elliot_chAim:SetValue(false)
            end
        end)
    end

    if Options and Options.elliot_aimSpeed then
        Options.elliot_aimSpeed:OnChanged(function()
            elliot_aimSpeed = tonumber(Options.elliot_aimSpeed.Value) or elliot_aimSpeed
        end)
    end

    if Options and Options.elliot_aimDurationInput then
        Options.elliot_aimDurationInput:OnChanged(function()
            elliot_aimDuration = tonumber(Options.elliot_aimDurationInput.Value) or 1.5
        end)
    end

    if Options and Options.elliot_maxPrediction then
        Options.elliot_maxPrediction:OnChanged(function()
            elliot_maxPrediction = tonumber(Options.elliot_maxPrediction.Value) or 0.2
        end)
    end

    if Options and Options.elliot_range then
        Options.elliot_range:OnChanged(function()
            elliot_range = tonumber(Options.elliot_range.Value) or 30
        end)
    end

    if Toggles and Toggles.elliot_visualizer then
        Toggles.elliot_visualizer:OnChanged(function()
            elliot_visualizerEnabled = Toggles.elliot_visualizer.Value
        end)
    end

    if Toggles and Toggles.KillerHighlight then
        Toggles.KillerHighlight:OnChanged(function()
            visualHighlightEnabled = Toggles.KillerHighlight.Value
        end)
    end

    if Options and Options.OutlineTransparency then
        Options.OutlineTransparency:OnChanged(function()
            visualOutlineTransparency = tonumber(Options.OutlineTransparency.Value) or 0.5
        end)
    end

    if Options and Options.FillTransparency then
        Options.FillTransparency:OnChanged(function()
            visualFillTransparency = tonumber(Options.FillTransparency.Value) or 0.85
        end)
    end

    updateBackstabUIStates()

    if Toggles and Toggles.EnableStaminaMod then
        Toggles.EnableStaminaMod:OnChanged(function()
            staminaEnabled = Toggles.EnableStaminaMod.Value
        end)
    end
    if Toggles and Toggles.InfStaminaToggle then
        Toggles.InfStaminaToggle:OnChanged(function()
            INF_STAMINA = Toggles.InfStaminaToggle.Value
        end)
    end
    if Options and Options.SprintSpeedVal then
        Options.SprintSpeedVal:OnChanged(function()
            SPRINT_SPEED = tonumber(Options.SprintSpeedVal.Value) or 40
        end)
    end

    ui_refs.Library = Library
    ui_refs.Window = Window
    ui_refs.Options = Options
    ui_refs.Toggles = Toggles
end

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
        Library:SetNotifySide(Value)
    end,
})
MenuGroup:AddDropdown("DPIDropdown", {
    Values = { "50%", "75%", "100%", "125%", "150%", "175%", "200%" },
    Default = "100%",
    Text = "DPI Scale",
    Callback = function(Value)
        Value = Value:gsub("%%", "")
        local DPI = tonumber(Value)
        Library:SetDPIScale(DPI)
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
    cleanupAllListeners()
    if cornerConnection then
        pcall(function() cornerConnection:Disconnect() end)
        cornerConnection = nil
    end
    if backstabConnection then
        backstabConnection:Disconnect()
    end
    if autoM1Connection then
        autoM1Connection:Disconnect()
    end
    if behindBoxPart then
        pcall(function() behindBoxPart:Destroy() end)
        behindBoxPart = nil
    end
    if leftConeLine then pcall(function() leftConeLine:Destroy() end) end
    if rightConeLine then pcall(function() rightConeLine:Destroy() end) end
    if autoM1Circle then pcall(function() autoM1Circle:Destroy() end) end
    if elliotCircle then pcall(function() elliotCircle:Destroy() end) end
    Library:Unload()
end)

_G.AutoBackstabUI = _G.AutoBackstabUI or {}
_G.AutoBackstabUI.refs = ui_refs

-- Background Dagger, Slash & Order Up Ability Activation Detection Loop (Optimized cooldown checks)
task.spawn(function()
    local lastDaggerCooldownState = false
    local lastSlashCooldownState = false
    local lastOrderUpCooldownState = false
    while true do
        task.wait(0.05) -- Adjusted poll frequency to preserve local memory threads
        if isUnloaded then break end
        
        local currentCd = isDaggerOnCooldown()
        if currentCd and not lastDaggerCooldownState then
            triggerManualDaggerAimbot()
        end
        lastDaggerCooldownState = currentCd

        local currentSlashCd = isSlashOnCooldown()
        if currentSlashCd and not lastSlashCooldownState then
            triggerManualSlashAimbot()
        end
        lastSlashCooldownState = currentSlashCd

        local currentOrderUpCd = isOrderUpOnCooldown()
        if currentOrderUpCd and not lastOrderUpCooldownState then
            triggerManualElliotAimbot()
        end
        lastOrderUpCooldownState = currentOrderUpCd
    end
end)

-- Separated Throttled Button Signal Binder (Saves dramatic amounts of processing overhead)
task.spawn(function()
    while true do
        task.wait(1.0)
        if isUnloaded then break end
        pcall(connectDaggerButtonSignals)
        pcall(connectSlashButtonSignals)
        pcall(connectChanceButtonSignals)
        pcall(connectOrderUpButtonSignals)
        pcall(connectM1ButtonSignals)
    end
end)

-- Robust direct keyboard hook for Chance activation (Strictly bound to One Shot keybind)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if isUnloaded then return end
    if gameProcessed then return end
    if inMatch() then
        if input.KeyCode == Enum.KeyCode.E then
            if getChanceButton() then
                triggerManualChanceAimbot()
            end
        end
    end
end)

-- Dedicated Manual Dagger, Shedletsky, Chance & Elliot Active Aimbot Tracking Loop
RunService.Heartbeat:Connect(function(dt)
    if isUnloaded then return end
    
    -- TwoTime/Dagger Aimbot
    if manualAimbotActive and manualAimbotTarget and manualAimbotTarget.Parent then
        local elapsed = os.clock() - manualAimbotStart
        local aimDur = cAimDuration
        
        if elapsed >= aimDur or not inMatch() then
            manualAimbotActive = false
            manualAimbotTarget = nil
            local _, humanoid, _ = getCharacterInfo()
            if humanoid then
                pcall(function() humanoid.AutoRotate = true end)
            end
            return
        end
        
        local char, humanoid, hrp = getCharacterInfo()
        local khrp = manualAimbotTarget:FindFirstChild("HumanoidRootPart")
        if hrp and khrp then
            local chAimActive = chAimEnabled
            local caAimActive = caAimEnabled
            
            if not chAimActive and not caAimActive then
                chAimActive = true
            end
            
            local predictedKPos = khrp.Position
            if MAX_PREDICTION > 0 then
                local vel = khrp.AssemblyLinearVelocity or khrp.Velocity
                if vel and vel.Magnitude > 0.1 then
                    predictedKPos = khrp.Position + (vel * MAX_PREDICTION)
                end
            end
            
            if chAimActive then
                local targetLook = Vector3.new(predictedKPos.X, hrp.Position.Y, predictedKPos.Z)
                if (targetLook - hrp.Position).Magnitude > 0.001 then
                    local targetRotation = CFrame.lookAt(hrp.Position, targetLook) - hrp.Position
                    local currentRotation = hrp.CFrame - hrp.CFrame.Position
                    local finalRotation = currentRotation:Lerp(targetRotation, math.min(1, AIM_SPEED * dt))
                    hrp.CFrame = CFrame.new(hrp.Position) * finalRotation
                end
            end
            
            if caAimActive then
                local cam = Workspace.CurrentCamera
                if cam then
                    local camPos = cam.CFrame.Position
                    local targetCamCFrame = CFrame.lookAt(camPos, predictedKPos)
                    cam.CFrame = cam.CFrame:Lerp(targetCamCFrame, math.min(1, AIM_SPEED * dt))
                end
            end
        end
    end

    -- Shedletsky/Slash Aimbot with added AutoTowardsKiller logic
    if shManualAimbotActive and shManualAimbotTarget and shManualAimbotTarget.Parent then
        local elapsed = os.clock() - shManualAimbotStart
        local aimDur = saAimDuration
        
        if elapsed >= aimDur or not inMatch() then
            shManualAimbotActive = false
            shManualAimbotTarget = nil
            local _, humanoid, _ = getCharacterInfo()
            if humanoid then
                pcall(function() humanoid.AutoRotate = true end)
            end
            shATKActive = false
            return
        end
        
        local char, humanoid, hrp = getCharacterInfo()
        local khrp = shManualAimbotTarget:FindFirstChild("HumanoidRootPart")
        if hrp and khrp then
            local chAimActive = shAimEnabled
            local caAimActive = saAimEnabled
            
            if not chAimActive and not caAimActive then
                chAimActive = true
            end
            
            local predictedKPos = khrp.Position
            if shMaxPrediction > 0 then
                local vel = khrp.AssemblyLinearVelocity or khrp.Velocity
                if vel and vel.Magnitude > 0.1 then
                    predictedKPos = khrp.Position + (vel * shMaxPrediction)
                end
            end
            
            if chAimActive then
                local targetLook = Vector3.new(predictedKPos.X, hrp.Position.Y, predictedKPos.Z)
                if (targetLook - hrp.Position).Magnitude > 0.001 then
                    local targetRotation = CFrame.lookAt(hrp.Position, targetLook) - hrp.Position
                    local currentRotation = hrp.CFrame - hrp.CFrame.Position
                    local finalRotation = currentRotation:Lerp(targetRotation, math.min(1, shAimSpeed * dt))
                    hrp.CFrame = CFrame.new(hrp.Position) * finalRotation
                end
            end
            
            if caAimActive then
                local cam = Workspace.CurrentCamera
                if cam then
                    local camPos = cam.CFrame.Position
                    local targetCamCFrame = CFrame.lookAt(camPos, predictedKPos)
                    cam.CFrame = cam.CFrame:Lerp(targetCamCFrame, math.min(1, shAimSpeed * dt))
                end
            end

            -- AutoTowardsKiller Feature Implementation
            if shAutoTowardsKiller and shATKActive then
                local atkElapsed = os.clock() - shATKStart
                if atkElapsed >= shATKDuration then
                    shATKActive = false
                else
                    local relativeDirection = (khrp.Position - hrp.Position)
                    if relativeDirection.Magnitude > 2 then
                        local dirUnit = Vector3.new(relativeDirection.X, 0, relativeDirection.Z).Unit
                        if humanoid then
                            humanoid:Move(dirUnit, false)
                        end
                    end
                end
            end
        end
    end

    -- Chance/OneShot Aimbot
    if chanceManualAimbotActive and chanceManualAimbotTarget and chanceManualAimbotTarget.Parent then
        local char, humanoid, hrp = getCharacterInfo()
        if hrp and humanoid then
            if chanceSpinning then
                local elapsedSpin = os.clock() - chanceSpinStart
                if elapsedSpin >= chance_spinDuration or not inMatch() then
                    chanceSpinning = false
                    chanceAimbotActiveStart = os.clock()
                else
                    local spinY = (os.clock() * chance_spinSpeed) % (math.pi * 2)
                    hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, spinY, 0)
                end
            else
                local elapsedAim = os.clock() - chanceAimbotActiveStart
                local aimDur = chance_aimDuration
                
                if elapsedAim >= aimDur or not inMatch() then
                    chanceManualAimbotActive = false
                    chanceManualAimbotTarget = nil
                    if humanoid then
                        pcall(function() humanoid.AutoRotate = true end)
                    end
                    return
                end
                
                local khrp = chanceManualAimbotTarget:FindFirstChild("HumanoidRootPart")
                if khrp then
                    local chAimActive = chance_chAimEnabled
                    local caAimActive = chance_caAimEnabled
                    
                    if not chAimActive and not caAimActive then
                        chAimActive = true
                    end
                    
                    local predictedKPos = khrp.Position
                    if chance_maxPrediction > 0 then
                        local vel = khrp.AssemblyLinearVelocity or khrp.Velocity
                        if vel and vel.Magnitude > 0.1 then
                            predictedKPos = khrp.Position + (vel * chance_maxPrediction)
                        end
                    end
                    
                    if chAimActive then
                        local targetLook = Vector3.new(predictedKPos.X, hrp.Position.Y, predictedKPos.Z)
                        if (targetLook - hrp.Position).Magnitude > 0.001 then
                            local targetRotation = CFrame.lookAt(hrp.Position, targetLook) - hrp.Position
                            local currentRotation = hrp.CFrame - hrp.CFrame.Position
                            local finalRotation = currentRotation:Lerp(targetRotation, math.min(1, chance_aimSpeed * dt))
                            hrp.CFrame = CFrame.new(hrp.Position) * finalRotation
                        end
                    end
                    
                    if caAimActive then
                        local cam = Workspace.CurrentCamera
                        if cam then
                            local camPos = cam.CFrame.Position
                            local targetCamCFrame = CFrame.lookAt(camPos, predictedKPos)
                            cam.CFrame = cam.CFrame:Lerp(targetCamCFrame, math.min(1, chance_aimSpeed * dt))
                        end
                    end
                end
            end
        end
    end

    -- Elliot Pizza Throwing Order Up Aimbot
    if elliotManualAimbotActive and elliotManualAimbotTarget and elliotManualAimbotTarget.Parent then
        local elapsed = os.clock() - elliotManualAimbotStart
        local aimDur = elliot_aimDuration
        
        if elapsed >= aimDur or not inMatch() then
            elliotManualAimbotActive = false
            elliotManualAimbotTarget = nil
            local _, humanoid, _ = getCharacterInfo()
            if humanoid then
                pcall(function() humanoid.AutoRotate = true end)
            end
            return
        end
        
        local char, humanoid, hrp = getCharacterInfo()
        local khrp = elliotManualAimbotTarget:FindFirstChild("HumanoidRootPart")
        if hrp and khrp then
            local chAimActive = elliot_chAimEnabled
            local caAimActive = elliot_caAimEnabled
            
            if not chAimActive and not caAimActive then
                chAimActive = true
            end
            
            local predictedKPos = khrp.Position
            if elliot_maxPrediction > 0 then
                local vel = khrp.AssemblyLinearVelocity or khrp.Velocity
                if vel and vel.Magnitude > 0.1 then
                    predictedKPos = khrp.Position + (vel * elliot_maxPrediction)
                end
            end
            
            if chAimActive then
                local targetLook = Vector3.new(predictedKPos.X, hrp.Position.Y, predictedKPos.Z)
                if (targetLook - hrp.Position).Magnitude > 0.001 then
                    local targetRotation = CFrame.lookAt(hrp.Position, targetLook) - hrp.Position
                    local currentRotation = hrp.CFrame - hrp.CFrame.Position
                    local finalRotation = currentRotation:Lerp(targetRotation, math.min(1, elliot_aimSpeed * dt))
                    hrp.CFrame = CFrame.new(hrp.Position) * finalRotation
                end
            end
            
            if caAimActive then
                local cam = Workspace.CurrentCamera
                if cam then
                    local camPos = cam.CFrame.Position
                    local targetCamCFrame = CFrame.lookAt(camPos, predictedKPos)
                    cam.CFrame = cam.CFrame:Lerp(targetCamCFrame, math.min(1, elliot_aimSpeed * dt))
                end
            end
        end
    end

    -- Auto M1 Target Aimbot Tracking (CH-Aim rotation)
    if autoM1AimbotActive and autoM1AimbotTarget and autoM1AimbotTarget.Parent then
        local elapsed = os.clock() - autoM1AimbotStart
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
            
            local targetLook = Vector3.new(predictedKPos.X, hrp.Position.Y, predictedKPos.Z)
            if (targetLook - hrp.Position).Magnitude > 0.001 then
                local targetRotation = CFrame.lookAt(hrp.Position, targetLook) - hrp.Position
                local currentRotation = hrp.CFrame - hrp.CFrame.Position
                local finalRotation = currentRotation:Lerp(targetRotation, math.min(1, autoM1AimSpeed * dt))
                hrp.CFrame = CFrame.new(hrp.Position) * finalRotation
            end
        end
    end
end)

-- Auto Backstab Executive Loop
backstabConnection = RunService.Heartbeat:Connect(function()
    if isUnloaded then
        if backstabConnection then
            backstabConnection:Disconnect()
            backstabConnection = nil
        end
        return
    end

    if enabled and inMatch() then
        if checkHelplessStatus() then
            return
        end

        -- Process Asset Detection Check & Dynamic Bypass Cool Down
        if stunCDDetectionEnabled then
            if stunCDDetectionActive then
                if os.clock() - stunCDDetectionTimerStart >= stunCDDetectionDuration then
                    stunCDDetectionActive = false
                end
            end

            local foundAssetOnKiller = false
            local killers = getKillersList()
            for _, killer in pairs(killers) do
                if isValidKillerModel(killer) then
                    -- Highly optimized direct lookup
                    if killerTargetAssetDetected[killer] then
                        foundAssetOnKiller = true
                        break
                    end
                end
            end

            if foundAssetOnKiller then
                stunCDDetectionActive = true
                stunCDDetectionTimerStart = os.clock()
                if os.clock() - lastNotificationTime > stunCDDetectionDuration then
                    lastNotificationTime = os.clock()
                    notify("StunCDDetection Triggered", "Target asset detected. Auto backstab paused for " .. tostring(stunCDDetectionDuration) .. "s.", 3)
                end
            end
        else
            stunCDDetectionActive = false
        end

        if not stunCDDetectionActive and os.clock() - lastTriggerTime >= TRIGGER_DEBOUNCE then
            local daggerBtn = getDaggerButton()
            if daggerBtn and not isDaggerOnCooldown() then
                local char, humanoid, hrp = getCharacterInfo()
                if hrp and humanoid then
                    local killers = getKillersList()
                    for _, killer in pairs(killers) do
                        if isValidKillerModel(killer) then
                            -- O(1) table-lookup verification replaces recursive searching on active frames
                            local passesImmuneCheck = not isKillerImmune(killer)
                            
                            local passesBehindCheck = true
                            if behindDetectionEnabled and isBehindBoxInWall then
                                passesBehindCheck = false
                            end

                            if passesImmuneCheck and passesBehindCheck then
                                local khrp = killer:FindFirstChild("HumanoidRootPart")
                                if khrp then
                                    local dist = (khrp.Position - hrp.Position).Magnitude
                                    if dist <= AUTO_STAB_RANGE then
                                        local relative = hrp.Position - khrp.Position
                                        local rel2d = Vector3.new(relative.X, 0, relative.Z)
                                        local behindVec = -khrp.CFrame.LookVector
                                        local behind2d = Vector3.new(behindVec.X, 0, behindVec.Z)
                                        local passesCone = false

                                        if rel2d.Magnitude > 0.001 and behind2d.Magnitude > 0.001 then
                                            local dot = rel2d.Unit:Dot(behind2d.Unit)
                                            local angleRad = math.acos(math.clamp(dot, -1, 1))
                                            local angleDeg = math.deg(angleRad)
                                            if angleDeg <= (BACK_CONE_ANGLE or 90) then
                                                passesCone = true
                                            end
                                        end

                                        if passesCone then
                                            local passesWallCheck = true
                                            if wallCheckEnabled then
                                                passesWallCheck = checkWall(hrp, khrp)
                                            end

                                            if passesWallCheck then
                                                lastTriggerTime = os.clock()

                                                task.spawn(function()
                                                    if autoDaggerDelay > 0 then
                                                        task.wait(autoDaggerDelay)
                                                    end

                                                    if autoDaggerEnabled then
                                                        tryActivateButton(daggerBtn)
                                                    end

                                                    local chAimActive = chAimEnabled
                                                    local caAimActive = caAimEnabled
                                                    if chAimActive then
                                                        pcall(function() humanoid.AutoRotate = false end)
                                                    end

                                                    local currentPos = hrp.Position
                                                    local lastTime = os.clock()
                                                    local tweenStart = os.clock()
                                                    local tweenDuration = TWEEN_DURATION
                                                    local aimDur = cAimDuration
                                                    local noclipDur = characterNoclipDuration
                                                    
                                                    local originalCollides = {}
                                                    local noclipConn

                                                    local function stopNoclip()
                                                        if noclipConn then
                                                            noclipConn:Disconnect()
                                                            noclipConn = nil
                                                        end
                                                        for part, wasCollidable in pairs(originalCollides) do
                                                            if part and part.Parent then
                                                                pcall(function() part.CanCollide = wasCollidable end)
                                                            end
                                                        end
                                                        table.clear(originalCollides)
                                                    end

                                                    if characterNoclipEnabled then
                                                        noclipConn = RunService.Stepped:Connect(function()
                                                            if os.clock() - tweenStart >= noclipDur or not hrp.Parent then
                                                                stopNoclip()
                                                                return
                                                            end
                                                            pcall(function()
                                                                local myChar = LocalPlayer.Character
                                                                if myChar then
                                                                    for _, part in ipairs(myChar:GetDescendants()) do
                                                                        if part:IsA("BasePart") then
                                                                            if originalCollides[part] == nil then
                                                                                originalCollides[part] = part.CanCollide
                                                                            end
                                                                            part.CanCollide = false
                                                                        end
                                                                    end
                                                                end
                                                            end)
                                                        end)
                                                    end

                                                    local movementConn
                                                    movementConn = RunService.Heartbeat:Connect(function()
                                                        local now = os.clock()
                                                        local dt = now - lastTime
                                                        lastTime = now
                                                        local elapsed = now - tweenStart
                                                        
                                                        local maxAllowedDuration = tweenDuration
                                                        if (chAimActive or caAimActive) and aimDur > maxAllowedDuration then
                                                            maxAllowedDuration = aimDur
                                                        end
                                                        if characterNoclipEnabled and noclipDur > maxAllowedDuration then
                                                            maxAllowedDuration = noclipDur
                                                        end

                                                        if not hrp.Parent or not khrp.Parent or isUnloaded or elapsed >= maxAllowedDuration then
                                                            if movementConn then movementConn:Disconnect() end
                                                            stopNoclip()
                                                            pcall(function() humanoid.AutoRotate = true end)
                                                            return
                                                        end

                                                        local kCFrame = khrp.CFrame
                                                        local predictedKPos = khrp.Position
                                                        if MAX_PREDICTION > 0 then
                                                            local vel = khrp.AssemblyLinearVelocity or khrp.Velocity
                                                            if vel and vel.Magnitude > 0.1 then
                                                                predictedKPos = khrp.Position + (vel * MAX_PREDICTION)
                                                            end
                                                        end

                                                        local currentBehindDist = getBehindDistance(killer)
                                                        local targetBehindPos = predictedKPos - (kCFrame.LookVector.Unit * currentBehindDist)
                                                        targetBehindPos = Vector3.new(targetBehindPos.X, hrp.Position.Y, targetBehindPos.Z)

                                                        if elapsed < tweenDuration then
                                                            local toTarget = targetBehindPos - currentPos
                                                            local distance = toTarget.Magnitude
                                                            local moveStep = TWEEN_SPEED * dt
                                                            if distance > 0.001 then
                                                                if moveStep >= distance then
                                                                    currentPos = targetBehindPos
                                                                else
                                                                    currentPos = currentPos + toTarget.Unit * moveStep
                                                                end
                                                            else
                                                                currentPos = targetBehindPos
                                                            end
                                                        else
                                                            currentPos = hrp.Position
                                                        end

                                                        local targetRotation = hrp.CFrame - hrp.CFrame.Position
                                                        if chAimActive and elapsed < aimDur then
                                                            local targetLook = Vector3.new(predictedKPos.X, currentPos.Y, predictedKPos.Z)
                                                            if (targetLook - currentPos).Magnitude > 0.001 then
                                                                targetRotation = CFrame.lookAt(currentPos, targetLook) - currentPos
                                                            end
                                                        end

                                                        local currentRotation = hrp.CFrame - hrp.CFrame.Position
                                                        local finalRotation = currentRotation
                                                        if chAimActive and elapsed < aimDur then
                                                            finalRotation = currentRotation:Lerp(targetRotation, math.min(1, AIM_SPEED * dt))
                                                        end

                                                        if caAimActive and elapsed < aimDur then
                                                            local cam = Workspace.CurrentCamera
                                                            if cam then
                                                                local camPos = cam.CFrame.Position
                                                                local targetCamCFrame = CFrame.lookAt(camPos, predictedKPos)
                                                                cam.CFrame = cam.CFrame:Lerp(targetCamCFrame, math.min(1, AIM_SPEED * dt))
                                                            end
                                                        end

                                                        hrp.CFrame = CFrame.new(currentPos) * finalRotation
                                                    end)
                                                end)
                                                break
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- Auto M1 Executive Loop
autoM1Connection = RunService.Heartbeat:Connect(function()
    if isUnloaded then
        if autoM1Connection then
            autoM1Connection:Disconnect()
            autoM1Connection = nil
        end
        return
    end

    if autoM1Enabled and inMatch() then
        if checkHelplessStatus() then
            return
        end

        local m1Btn = getM1Button()
        if m1Btn and not isM1OnCooldown() then
            local char, humanoid, hrp = getCharacterInfo()
            if hrp and humanoid then
                local survivors = getSurvivorsList()
                for _, survivor in pairs(survivors) do
                    if isValidSurvivor(survivor) then
                        local khrp = survivor:FindFirstChild("HumanoidRootPart")
                        if khrp then
                            local dist = (khrp.Position - hrp.Position).Magnitude
                            if dist <= autoM1Range then
                                -- Validate survivors are in front of our character inside our cone
                                local relative = khrp.Position - hrp.Position
                                local rel2d = Vector3.new(relative.X, 0, relative.Z)
                                local frontVec = hrp.CFrame.LookVector
                                local front2d = Vector3.new(frontVec.X, 0, frontVec.Z)
                                local passesCone = false

                                if rel2d.Magnitude > 0.001 and front2d.Magnitude > 0.001 then
                                    local dot = rel2d.Unit:Dot(front2d.Unit)
                                    local angleRad = math.acos(math.clamp(dot, -1, 1))
                                    local angleDeg = math.deg(angleRad)
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
    end
end)

-- Range Circle Visualizer Loop
local currentVisualizer = nil
local function updateVisualizer(targetHrp)
    if not visualizerEnabled or not targetHrp then
        if currentVisualizer then
            currentVisualizer:Destroy()
            currentVisualizer = nil
        end
        return
    end

    if not currentVisualizer then
        currentVisualizer = Instance.new("CylinderHandleAdornment")
        currentVisualizer.Height = 0.01
        currentVisualizer.Color3 = Color3.fromRGB(255, 0, 0)
        currentVisualizer.Transparency = 0.6
        currentVisualizer.ZIndex = 10
        currentVisualizer.AlwaysOnTop = true
        currentVisualizer.Parent = Workspace:FindFirstChild("Terrain") or Workspace
    end

    currentVisualizer.Adornee = targetHrp
    currentVisualizer.Radius = AUTO_STAB_RANGE
    currentVisualizer.CFrame = CFrame.new(0, -targetHrp.Size.Y/2, 0) * CFrame.Angles(math.rad(90), 0, 0)
end

-- Custom Auto M1 Range Circle
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
    autoM1Circle.CFrame = CFrame.new(0, -hrp.Size.Y/2, 0) * CFrame.Angles(math.rad(90), 0, 0)
end

-- Elliot Range Circle Visualizer
local function updateElliotCircle(hrp)
    if not elliot_visualizerEnabled or not hrp then
        if elliotCircle then
            elliotCircle:Destroy()
            elliotCircle = nil
        end
        return
    end

    if not elliotCircle then
        elliotCircle = Instance.new("CylinderHandleAdornment")
        elliotCircle.Height = 0.01
        elliotCircle.Color3 = Color3.fromRGB(255, 165, 0)
        elliotCircle.Transparency = 0.6
        elliotCircle.ZIndex = 10
        elliotCircle.AlwaysOnTop = true
        elliotCircle.Parent = Workspace:FindFirstChild("Terrain") or Workspace
    end

    elliotCircle.Adornee = hrp
    elliotCircle.Radius = elliot_range
    elliotCircle.CFrame = CFrame.new(0, -hrp.Size.Y/2, 0) * CFrame.Angles(math.rad(90), 0, 0)
end

-- BehindDetection Box Update Function (Highly optimized)
local function updateBehindBox(targetHrp)
    if not behindDetectionEnabled or not targetHrp then
        if behindBoxPart then
            pcall(function() behindBoxPart:Destroy() end)
            behindBoxPart = nil
        end
        isBehindBoxInWall = false
        return
    end

    if not behindBoxPart then
        behindBoxPart = Instance.new("Part")
        behindBoxPart.Name = "BehindDetectionBox"
        behindBoxPart.Shape = Enum.PartType.Block
        behindBoxPart.Material = Enum.Material.ForceField
        behindBoxPart.Transparency = 0.6
        behindBoxPart.CanCollide = false
        behindBoxPart.Anchored = true
        behindBoxPart.CastShadow = false
    end

    behindBoxPart.Parent = Workspace:FindFirstChild("Terrain") or Workspace
    
    local kCFrame = targetHrp.CFrame
    local calculatedOffset = behindOffset + (behindLength / 2)
    local boxCFrame = kCFrame * CFrame.new(0, 0, calculatedOffset)

    behindBoxPart.Size = Vector3.new(behindWidth, behindHeight, behindLength)
    behindBoxPart.CFrame = boxCFrame

    -- Perform Overlap spatial queries for static structures (Reuses OverlapParams cache)
    local filterList = {LocalPlayer.Character, targetHrp.Parent}
    local playersFolder = Workspace:FindFirstChild("Players")
    if playersFolder then
        table.insert(filterList, playersFolder)
    end
    behindDetectionParams.FilterDescendantsInstances = filterList

    local intersectingParts = Workspace:GetPartsInPart(behindBoxPart, behindDetectionParams)
    local hitWall = false
    for _, part in ipairs(intersectingParts) do
        if part.CanCollide then
            hitWall = true
            break
        end
    end

    isBehindBoxInWall = hitWall

    if behindDetectionVisualEnabled then
        if hitWall then
            behindBoxPart.Color = Color3.fromRGB(255, 100, 100)
        else
            behindBoxPart.Color = Color3.fromRGB(255, 255, 0)
        end
        behindBoxPart.Transparency = 0.6
    else
        behindBoxPart.Transparency = 1
    end
end

-- Core Visualizer Scanning Loop
task.spawn(function()
    while true do
        task.wait(0.1) -- Optimized check rate to save processor resources
        if isUnloaded then 
            if currentVisualizer then currentVisualizer:Destroy() end
            if behindBoxPart then pcall(function() behindBoxPart:Destroy() end) end
            if leftConeLine then pcall(function() leftConeLine:Destroy() end) end
            if rightConeLine then pcall(function() rightConeLine:Destroy() end) end
            if autoM1Circle then pcall(function() autoM1Circle:Destroy() end) end
            if elliotCircle then pcall(function() elliotCircle:Destroy() end) end
            break 
        end
        
        local char, _, hrp = getCharacterInfo()
        
        if (visualizerEnabled or behindDetectionEnabled) and inMatch() then
            local killers = getKillersList()
            local targetHrp = nil
            local minDistance = math.huge
            
            if hrp then
                for _, killer in pairs(killers) do
                    if isValidKillerModel(killer) then
                        local khrp = killer:FindFirstChild("HumanoidRootPart")
                        if khrp then
                            local dist = (khrp.Position - hrp.Position).Magnitude
                            if dist < minDistance then
                                minDistance = dist
                                targetHrp = khrp
                            end
                        end
                    end
                end
            end
            
            updateVisualizer(targetHrp)
            updateBehindBox(targetHrp)
        else
            updateVisualizer(nil)
            updateBehindBox(nil)
        end
        
        -- Update Auto M1 Range Circle & Cone visuals
        if autoM1Enabled and autoM1VisualizerEnabled and inMatch() and hrp then
            updateM1Circle(hrp)
            
            -- Left Boundary Visualizer Line
            if leftConeLine then
                leftConeLine.Adornee = hrp
                leftConeLine.Length = autoM1Range
                leftConeLine.CFrame = CFrame.Angles(0, math.rad(180 + autoM1ConeAngle / 2), 0)
            else
                leftConeLine = Instance.new("LineHandleAdornment")
                leftConeLine.Color3 = Color3.fromRGB(0, 255, 0)
                leftConeLine.Thickness = 3
                leftConeLine.ZIndex = 10
                leftConeLine.AlwaysOnTop = true
                leftConeLine.Adornee = hrp
                leftConeLine.Length = autoM1Range
                leftConeLine.CFrame = CFrame.Angles(0, math.rad(180 + autoM1ConeAngle / 2), 0)
                leftConeLine.Parent = Workspace:FindFirstChild("Terrain") or Workspace
            end
            
            -- Right Boundary Visualizer Line
            if rightConeLine then
                rightConeLine.Adornee = hrp
                rightConeLine.Length = autoM1Range
                rightConeLine.CFrame = CFrame.Angles(0, math.rad(180 - autoM1ConeAngle / 2), 0)
            else
                rightConeLine = Instance.new("LineHandleAdornment")
                rightConeLine.Color3 = Color3.fromRGB(0, 255, 0)
                rightConeLine.Thickness = 3
                rightConeLine.ZIndex = 10
                rightConeLine.AlwaysOnTop = true
                rightConeLine.Adornee = hrp
                rightConeLine.Length = autoM1Range
                rightConeLine.CFrame = CFrame.Angles(0, math.rad(180 - autoM1ConeAngle / 2), 0)
                rightConeLine.Parent = Workspace:FindFirstChild("Terrain") or Workspace
            end
        else
            if leftConeLine then pcall(function() leftConeLine:Destroy() end) leftConeLine = nil end
            if rightConeLine then pcall(function() rightConeLine:Destroy() end) rightConeLine = nil end
            updateM1Circle(nil)
        end

        -- Update Elliot visualizer circle
        if elliot_visualizerEnabled and inMatch() and hrp then
            updateElliotCircle(hrp)
        else
            updateElliotCircle(nil)
        end
    end
end)

-- Killer Highlight System with Dynamic Point-Precision Transparency Sync
local function clearHighlights()
    for model, hl in pairs(killerHighlights) do
        if hl then pcall(function() hl:Destroy() end) end
    end
    table.clear(killerHighlights)
end

local function updateHighlights()
    if not visualHighlightEnabled then
        clearHighlights()
        return
    end

    local killers = getKillersList()
    for _, killer in ipairs(killers) do
        if isValidKillerModel(killer) then
            local hl = killerHighlights[killer]
            if not hl or not hl.Parent then
                hl = Instance.new("Highlight")
                hl.OutlineColor = Color3.fromRGB(255, 0, 0)
                hl.OutlineTransparency = visualOutlineTransparency
                hl.FillColor = Color3.fromRGB(255, 0, 0)
                hl.FillTransparency = visualFillTransparency
                hl.Adornee = killer
                hl.Parent = killer
                killerHighlights[killer] = hl
            else
                hl.OutlineTransparency = visualOutlineTransparency
                hl.FillTransparency = visualFillTransparency
            end
        end
    end

    -- Efficient cleanup using cached arrays rather than scanning whole workspace
    for model, hl in pairs(killerHighlights) do
        if not model or not model.Parent or not table.find(killers, model) or not isValidKillerModel(model) then
            if hl then pcall(function() hl:Destroy() end) end
            killerHighlights[model] = nil
        end
    end
end

task.spawn(function()
    while true do
        task.wait(0.2) -- Slowed down updates slightly for optimized backend updates
        if isUnloaded then
            clearHighlights()
            break
        end
        if visualHighlightEnabled then
            pcall(updateHighlights)
        else
            clearHighlights()
        end
    end
end)

-- Background Stamina Re-execution Loop
task.spawn(function()
    while true do
        task.wait(1.5)
        if isUnloaded then break end
        if staminaEnabled and inMatch() then
            pcall(function()
                local SprintingPath = ReplicatedStorage:FindFirstChild("Systems")
                    and ReplicatedStorage.Systems:FindFirstChild("Character")
                    and ReplicatedStorage.Systems.Character:FindFirstChild("Game")
                    and ReplicatedStorage.Systems.Character.Game:FindFirstChild("Sprinting")
                if SprintingPath then
                    local stamina = require(SprintingPath)
                    if stamina and type(stamina) == "table" then
                        stamina.MaxStamina = MAX_STAMINA
                        stamina.MinStamina = MIN_STAMINA
                        stamina.StaminaGain = STAMINA_GAIN
                        stamina.StaminaLoss = STAMINA_LOSS
                        stamina.SprintSpeed = SPRINT_SPEED
                        stamina.StaminaLossDisabled = INF_STAMINA
                    end
                end
            end)
        end
    end
end)

-- Background Full Bright Loop
task.spawn(function()
    while true do
        task.wait(1)
        if isUnloaded then break end
        if fullBrightEnabled then
            pcall(applyFullBright)
        end
    end
end)

if Library then
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
                
                local OthersConfigsGroup = Tabs["UI Settings"]:AddRightGroupbox("Other's Configs")
                
                OthersConfigsGroup:AddDropdown("SharedConfigsList", {
                    Text = "Shared Configs",
                    Values = {},
                    AllowNull = true,
                    Tooltip = "Select a configuration posted by another user"
                })

                OthersConfigsGroup:AddButton("Refresh Cloud List", function()
                    refreshCloudList()
                end)

                OthersConfigsGroup:AddButton("Download Selected", function()
                    downloadSelectedConfig()
                end)

                OthersConfigsGroup:AddDivider()

                OthersConfigsGroup:AddInput("PublishName", {
                    Text = "New Config Name",
                    Default = "",
                    Placeholder = "Enter a name to share..."
                })

                OthersConfigsGroup:AddButton("Post Current Config", function()
                    local name = Options.PublishName and Options.PublishName.Value or ""
                    publishConfig(name)
                end)
                
                task.spawn(refreshCloudList)
            end
            SaveManager:LoadAutoloadConfig()
        end)
    end
    
    task.spawn(function()
        task.wait(0.5)
        pcall(updateGuiCorners, guiCornerRadius)
    end)
end
