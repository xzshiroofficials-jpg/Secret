- REPLACE THIS URL WITH YOUR RAW MAIN SCRIPT LINK (GitHub Gist, Pastebin Raw, etc.)
local MAIN_SCRIPT_URL = "https://raw.githubusercontent.com/xzshiroofficials-jpg/MainScript/refs/heads/main/FLSSCRIPT.lua"

local DISCORD_WEBHOOK = "https://discord.com/api/webhooks/1530903761067970623/jPDFgrUd9TePxoVHCUYvQzlToIoLDn40Q7vbuhed_En5SobxdW4M20y4dfZvNJ6EvBja"
local KEY_SALT = "FLS_SECURE_SALT_2026"             -- Change this to change the key pool
local DISCORD_INVITE = "https://discord.gg/CYAmmsuRa"
local SAVE_FILE_NAME = "FLS_PermKey_Saved.txt"

-- Cloud Database Endpoint for Single-Use Tracking
local ONLINE_KV_URL = "https://kvdb.io/7zR4w9Q2pX8mN1k5/"

-- =================================================================
-- 101 PERMANENT SINGLE-USE KEYS POOL (FLS BRANDED)
-- =================================================================
local PERMANENT_KEYS = {
    ["FLS-PERM-001-8F3A"] = true, ["FLS-PERM-002-1C9B"] = true, ["FLS-PERM-003-7D2E"] = true,
    ["FLS-PERM-004-4A8F"] = true, ["FLS-PERM-005-9B1C"] = true, ["FLS-PERM-006-2E7D"] = true,
    ["FLS-PERM-007-6F4A"] = true, ["FLS-PERM-008-3B91"] = true, ["FLS-PERM-009-8C2E"] = true,
    ["FLS-PERM-010-5D7F"] = true, ["FLS-PERM-011-1A4B"] = true, ["FLS-PERM-012-9C8E"] = true,
    ["FLS-PERM-013-3E2F"] = true, ["FLS-PERM-014-7F9A"] = true, ["FLS-PERM-015-2B1C"] = true,
    ["FLS-PERM-016-8D4E"] = true, ["FLS-PERM-017-4C7F"] = true, ["FLS-PERM-018-9A3B"] = true,
    ["FLS-PERM-019-1E8D"] = true, ["FLS-PERM-020-6F2C"] = true, ["FLS-PERM-021-3A9E"] = true,
    ["FLS-PERM-022-7C1F"] = true, ["FLS-PERM-023-2D8B"] = true, ["FLS-PERM-024-8E4A"] = true,
    ["FLS-PERM-025-4F9C"] = true, ["FLS-PERM-026-9B2E"] = true, ["FLS-PERM-027-1C7D"] = true,
    ["FLS-PERM-028-6D3F"] = true, ["FLS-PERM-029-3E8A"] = true, ["FLS-PERM-030-7F1B"] = true,
    ["FLS-PERM-031-2A9C"] = true, ["FLS-PERM-032-8C4E"] = true, ["FLS-PERM-033-4D7F"] = true,
    ["FLS-PERM-034-9E2B"] = true, ["FLS-PERM-035-1F8C"] = true, ["FLS-PERM-036-6B3D"] = true,
    ["FLS-PERM-037-3C9E"] = true, ["FLS-PERM-038-7D1F"] = true, ["FLS-PERM-039-2E8A"] = true,
    ["FLS-PERM-040-8F4B"] = true, ["FLS-PERM-041-4A2C"] = true, ["FLS-PERM-042-9C7E"] = true,
    ["FLS-PERM-043-1D3F"] = true, ["FLS-PERM-044-6E8A"] = true, ["FLS-PERM-045-3F1B"] = true,
    ["FLS-PERM-046-7A9C"] = true, ["FLS-PERM-047-2C4E"] = true, ["FLS-PERM-048-8D7F"] = true,
    ["FLS-PERM-049-4E2B"] = true, ["FLS-PERM-050-9F8C"] = true, ["FLS-PERM-051-1B3D"] = true,
    ["FLS-PERM-052-6C9E"] = true, ["FLS-PERM-053-3D1F"] = true, ["FLS-PERM-054-7E8A"] = true,
    ["FLS-PERM-055-2F4B"] = true, ["FLS-PERM-056-8A2C"] = true, ["FLS-PERM-057-4C7E"] = true,
    ["FLS-PERM-058-9D3F"] = true, ["FLS-PERM-059-1E8A"] = true, ["FLS-PERM-060-6F1B"] = true,
    ["FLS-PERM-061-3A9C"] = true, ["FLS-PERM-062-7C4E"] = true, ["FLS-PERM-063-2D7F"] = true,
    ["FLS-PERM-064-8E2B"] = true, ["FLS-PERM-065-4F8C"] = true, ["FLS-PERM-066-9B3D"] = true,
    ["FLS-PERM-067-1C9E"] = true, ["FLS-PERM-068-6D1F"] = true, ["FLS-PERM-069-3E8A"] = true,
    ["FLS-PERM-070-7F4B"] = true, ["FLS-PERM-071-2A2C"] = true, ["FLS-PERM-072-8C7E"] = true,
    ["FLS-PERM-073-4D3F"] = true, ["FLS-PERM-074-9E8A"] = true, ["FLS-PERM-075-1F1B"] = true,
    ["FLS-PERM-076-6A9C"] = true, ["FLS-PERM-077-3C4E"] = true, ["FLS-PERM-078-7D7F"] = true,
    ["FLS-PERM-079-2E2B"] = true, ["FLS-PERM-080-8F8C"] = true, ["FLS-PERM-081-4B3D"] = true,
    ["FLS-PERM-082-9C9E"] = true, ["FLS-PERM-083-1D1F"] = true, ["FLS-PERM-084-6E8A"] = true,
    ["FLS-PERM-085-3F4B"] = true, ["FLS-PERM-086-7A2C"] = true, ["FLS-PERM-087-2C7E"] = true,
    ["FLS-PERM-088-8D3F"] = true, ["FLS-PERM-089-4E8A"] = true, ["FLS-PERM-090-9F1B"] = true,
    ["FLS-PERM-091-1A9C"] = true, ["FLS-PERM-092-6C4E"] = true, ["FLS-PERM-093-3D7F"] = true,
    ["FLS-PERM-094-7E2B"] = true, ["FLS-PERM-095-2F8C"] = true, ["FLS-PERM-096-8B3D"] = true,
    ["FLS-PERM-097-4C9E"] = true, ["FLS-PERM-098-9D1F"] = true, ["FLS-PERM-099-1E8A"] = true,
    ["FLS-PERM-100-6F4B"] = true, ["FLS-PERM-101-999Z"] = true
}

-- Execute Main Script Loader Function
local function loadMainScript()
    print("[FreshLeavesSaken] Key authenticated. Loading main script...")
    local success, result = pcall(function()
        return game:HttpGet(MAIN_SCRIPT_URL)
    end)
    
    if success and result then
        local mainFn, err = loadstring(result)
        if mainFn then
            mainFn()
        else
            warn("[FreshLeavesSaken] Syntax error in Main Script:", err)
        end
    else
        warn("[FreshLeavesSaken] Failed to download main script from URL. Check MAIN_SCRIPT_URL:", result)
    end
end

-- =================================================================
-- DETERMINISTIC DAILY KEY GENERATION
-- =================================================================
local function getDailyKey()
    local dateString = os.date("!%Y%m%d") -- YYYYMMDD UTC
    local combined = dateString .. KEY_SALT
    local num = 0
    for i = 1, #combined do
        num = (num + string.byte(combined, i) * i) % 999983
    end
    return "FLS-" .. tostring(num) .. "-K3Y"
end

local expectedDailyKey = getDailyKey()

-- Helper function to save key locally
local function saveKeyLocally(key)
    pcall(function()
        if writefile then
            writefile(SAVE_FILE_NAME, key)
        end
    end)
end

-- Helper function to check for saved key
local function checkSavedPermKey()
    local savedKey = nil
    pcall(function()
        if isfile and readfile and isfile(SAVE_FILE_NAME) then
            savedKey = readfile(SAVE_FILE_NAME)
        end
    end)
    if savedKey and PERMANENT_KEYS[savedKey] then
        return true, savedKey
    end
    return false, nil
end

-- =================================================================
-- ONLINE SINGLE-USE VERIFICATION SYSTEM
-- =================================================================
local function isPermKeyClaimedOnline(key)
    local httpRequest = request or (http and http.request) or (syn and syn.request) or (http_request)
    if not httpRequest then return false end
    
    local claimed = false
    pcall(function()
        local res = httpRequest({
            Url = ONLINE_KV_URL .. key,
            Method = "GET"
        })
        if res and (res.StatusCode == 200 or res.Status == 200) and res.Body == "CLAIMED" then
            claimed = true
        end
    end)
    return claimed
end

local function markPermKeyClaimedOnline(key)
    local httpRequest = request or (http and http.request) or (syn and syn.request) or (http_request)
    if not httpRequest then return end
    
    pcall(function()
        httpRequest({
            Url = ONLINE_KV_URL .. key,
            Method = "POST",
            Headers = { ["Content-Type"] = "text/plain" },
            Body = "CLAIMED"
        })
    end)
end

-- =================================================================
-- DISCORD NOTIFICATION SENDER (PROTECTED / REDACTED PERM KEYS)
-- =================================================================
local function sendKeyToDiscord(key, keyType)
    if DISCORD_WEBHOOK == "" then return end

    local displayKey = key
    if keyType == "Permanent Key" or key:find("PERM") then
        displayKey = "||FLS-PERM-***-PROTECTED|| (Redacted for Security)"
    end

    local httpRequest = request or (http and http.request) or (syn and syn.request) or (http_request)
    if httpRequest then
        pcall(function()
            httpRequest({
                Url = DISCORD_WEBHOOK .. "?wait=true",
                Method = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body = game:GetService("HttpService"):JSONEncode({
                    username = "FreshLeavesSaken Key System Bot",
                    embeds = {{
                        title = "[🔑] - FreshLeavesSaken Authentication",
                        description = "A user authenticated using the FreshLeavesSaken (FLS) Key System.",
                        fields = {
                            { name = "Current Active Key", value = "`" .. displayKey .. "`", inline = false },
                            { name = "Key Type", value = keyType or "Daily Rotation Key", inline = true },
                            { name = "System Date (UTC)", value = os.date("!%Y-%m-%d"), inline = true }
                        },
                        color = 8011246
                    }}
                })
            })
        end)
    end
end

-- Dispatch active daily key notification
task.spawn(function()
    sendKeyToDiscord(expectedDailyKey, "Daily Key")
end)

-- Helper function to copy to clipboard
local function copyToClipboard(text)
    local setClipboard = setclipboard or writeclipboard or toclipboard or (Clipboard and Clipboard.set)
    if setClipboard then
        pcall(setClipboard, text)
        return true
    end
    return false
end

-- =================================================================
-- KEY SYSTEM USER INTERFACE
-- =================================================================
local function loadKeySystem(onSuccess)
    -- Check local whitelist bypass first
    local isSaved, savedKey = checkSavedPermKey()
    if isSaved then
        print("[FreshLeavesSaken] Valid permanent key found saved locally. Bypassing key system.")
        onSuccess()
        return
    end

    local Players = game:GetService("Players")
    local CoreGui = game:GetService("CoreGui")
    local LocalPlayer = Players.LocalPlayer
    
    local existingUI = CoreGui:FindFirstChild("FLSKeySystemUI") or (LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("FLSKeySystemUI"))
    if existingUI then existingUI:Destroy() end

    -- Palette Styling
    local bgDark = Color3.fromRGB(15, 15, 18)
    local frameDark = Color3.fromRGB(22, 22, 27)
    local accentColor = Color3.fromRGB(114, 137, 218)
    local strokeColor = Color3.fromRGB(42, 42, 50)
    local strokeActive = Color3.fromRGB(114, 137, 218)
    local textColor = Color3.fromRGB(225, 225, 230)
    local subTextColor = Color3.fromRGB(135, 135, 145)
    local inputBg = Color3.fromRGB(25, 25, 30)

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "FLSKeySystemUI"
    ScreenGui.ResetOnSpawn = false
    
    local successParent, _ = pcall(function() ScreenGui.Parent = CoreGui end)
    if not successParent then
        ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end

    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 420, 0, 250)
    MainFrame.Position = UDim2.new(0.5, -210, 0.5, -125)
    MainFrame.BackgroundColor3 = bgDark
    MainFrame.BorderSizePixel = 0
    MainFrame.Parent = ScreenGui

    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 10)
    MainCorner.Parent = MainFrame

    local MainStroke = Instance.new("UIStroke")
    MainStroke.Color = strokeColor
    MainStroke.Thickness = 1.5
    MainStroke.Parent = MainFrame

    local HeaderFrame = Instance.new("Frame")
    HeaderFrame.Name = "HeaderFrame"
    HeaderFrame.Size = UDim2.new(1, 0, 0, 45)
    HeaderFrame.BackgroundColor3 = frameDark
    HeaderFrame.BorderSizePixel = 0
    HeaderFrame.Parent = MainFrame

    local HeaderCorner = Instance.new("UICorner")
    HeaderCorner.CornerRadius = UDim.new(0, 10)
    HeaderCorner.Parent = HeaderFrame

    local HeaderFix = Instance.new("Frame")
    HeaderFix.Size = UDim2.new(1, 0, 0, 10)
    HeaderFix.Position = UDim2.new(0, 0, 1, -10)
    HeaderFix.BackgroundColor3 = frameDark
    HeaderFix.BorderSizePixel = 0
    HeaderFix.Parent = HeaderFrame

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Name = "TitleLabel"
    TitleLabel.Size = UDim2.new(1, -30, 1, 0)
    TitleLabel.Position = UDim2.new(0, 15, 0, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = "FreshLeavesSaken  —  Authentication"
    TitleLabel.TextColor3 = textColor
    TitleLabel.TextSize = 15
    TitleLabel.Font = Enum.Font.SourceSansBold
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Parent = HeaderFrame

    local SubTitleLabel = Instance.new("TextLabel")
    SubTitleLabel.Name = "SubTitleLabel"
    SubTitleLabel.Size = UDim2.new(1, -30, 0, 18)
    SubTitleLabel.Position = UDim2.new(0, 15, 0, 52)
    SubTitleLabel.BackgroundTransparency = 1
    SubTitleLabel.Text = "Enter your single-use permanent key or daily key to access FLS Hub."
    SubTitleLabel.TextColor3 = subTextColor
    SubTitleLabel.TextSize = 12
    SubTitleLabel.Font = Enum.Font.SourceSans
    SubTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    SubTitleLabel.Parent = MainFrame

    local KeyInput = Instance.new("TextBox")
    KeyInput.Name = "KeyInput"
    KeyInput.Size = UDim2.new(1, -30, 0, 40)
    KeyInput.Position = UDim2.new(0, 15, 0, 80)
    KeyInput.BackgroundColor3 = inputBg
    KeyInput.BorderSizePixel = 0
    KeyInput.Text = ""
    KeyInput.PlaceholderText = "Paste key here (e.g., FLS-PERM-... or FLS-...-K3Y)"
    KeyInput.TextColor3 = textColor
    KeyInput.PlaceholderColor3 = Color3.fromRGB(110, 110, 120)
    KeyInput.TextSize = 13
    KeyInput.Font = Enum.Font.SourceSans
    KeyInput.ClearTextOnFocus = false
    KeyInput.Parent = MainFrame

    local InputCorner = Instance.new("UICorner")
    InputCorner.CornerRadius = UDim.new(0, 6)
    InputCorner.Parent = KeyInput

    local InputStroke = Instance.new("UIStroke")
    InputStroke.Color = strokeColor
    InputStroke.Thickness = 1
    InputStroke.Parent = KeyInput

    KeyInput.Focused:Connect(function() InputStroke.Color = strokeActive end)
    KeyInput.FocusLost:Connect(function() InputStroke.Color = strokeColor end)

    local StatusLabel = Instance.new("TextLabel")
    StatusLabel.Name = "StatusLabel"
    StatusLabel.Size = UDim2.new(1, -30, 0, 22)
    StatusLabel.Position = UDim2.new(0, 15, 0, 130)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Text = "Permanent keys are single-use only."
    StatusLabel.TextColor3 = Color3.fromRGB(150, 150, 160)
    StatusLabel.TextSize = 12
    StatusLabel.Font = Enum.Font.SourceSansItalic
    StatusLabel.TextXAlignment = Enum.TextXAlignment.Center
    StatusLabel.Parent = MainFrame

    local ButtonContainer = Instance.new("Frame")
    ButtonContainer.Size = UDim2.new(1, -30, 0, 42)
    ButtonContainer.Position = UDim2.new(0, 15, 0, 165)
    ButtonContainer.BackgroundTransparency = 1
    ButtonContainer.Parent = MainFrame

    local SubmitButton = Instance.new("TextButton")
    SubmitButton.Name = "SubmitButton"
    SubmitButton.Size = UDim2.new(0.5, -6, 1, 0)
    SubmitButton.Position = UDim2.new(0, 0, 0, 0)
    SubmitButton.BackgroundColor3 = accentColor
    SubmitButton.BorderSizePixel = 0
    SubmitButton.Text = "Verify Key"
    SubmitButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    SubmitButton.TextSize = 14
    SubmitButton.Font = Enum.Font.SourceSansBold
    SubmitButton.Parent = ButtonContainer

    local SubmitCorner = Instance.new("UICorner")
    SubmitCorner.CornerRadius = UDim.new(0, 6)
    SubmitCorner.Parent = SubmitButton

    local DiscordButton = Instance.new("TextButton")
    DiscordButton.Name = "DiscordButton"
    DiscordButton.Size = UDim2.new(0.5, -6, 1, 0)
    DiscordButton.Position = UDim2.new(0.5, 6, 0, 0)
    DiscordButton.BackgroundColor3 = Color3.fromRGB(32, 34, 40)
    DiscordButton.BorderSizePixel = 0
    DiscordButton.Text = "Copy Discord Link"
    DiscordButton.TextColor3 = Color3.fromRGB(220, 220, 225)
    DiscordButton.TextSize = 13
    DiscordButton.Font = Enum.Font.SourceSansBold
    DiscordButton.Parent = ButtonContainer

    local DiscordCorner = Instance.new("UICorner")
    DiscordCorner.CornerRadius = UDim.new(0, 6)
    DiscordCorner.Parent = DiscordButton

    local DiscordStroke = Instance.new("UIStroke")
    DiscordStroke.Color = strokeColor
    DiscordStroke.Thickness = 1
    DiscordStroke.Parent = DiscordButton

    DiscordButton.MouseButton1Click:Connect(function()
        if copyToClipboard(DISCORD_INVITE) then
            StatusLabel.Text = "Discord invite link copied to clipboard!"
            StatusLabel.TextColor3 = Color3.fromRGB(85, 255, 120)
        else
            StatusLabel.Text = DISCORD_INVITE
            StatusLabel.TextColor3 = Color3.fromRGB(255, 200, 85)
        end
    end)

    SubmitButton.MouseButton1Click:Connect(function()
        local input = KeyInput.Text:gsub("%s+", "")
        if input == expectedDailyKey then
            StatusLabel.Text = "Daily key verified! Loading FreshLeavesSaken..."
            StatusLabel.TextColor3 = Color3.fromRGB(85, 255, 85)
            task.wait(0.8)
            ScreenGui:Destroy()
            onSuccess()
        elseif PERMANENT_KEYS[input] then
            StatusLabel.Text = "Checking key availability online..."
            StatusLabel.TextColor3 = Color3.fromRGB(255, 200, 85)
            
            task.defer(function()
                if isPermKeyClaimedOnline(input) then
                    StatusLabel.Text = "Key Already Used! This permanent key has been claimed."
                    StatusLabel.TextColor3 = Color3.fromRGB(255, 85, 85)
                else
                    StatusLabel.Text = "Permanent key activated! Saving access..."
                    StatusLabel.TextColor3 = Color3.fromRGB(85, 255, 85)
                    
                    markPermKeyClaimedOnline(input)
                    saveKeyLocally(input)
                    sendKeyToDiscord(input, "Permanent Key")
                    
                    task.wait(1)
                    ScreenGui:Destroy()
                    onSuccess()
                end
            end)
        else
            StatusLabel.Text = "Invalid Key! Get active keys in Discord."
            StatusLabel.TextColor3 = Color3.fromRGB(255, 85, 85)
        end
    end)
end

-- Launch key authentication system
loadKeySystem(function()
    loadMainScript()
end)
