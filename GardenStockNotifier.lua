local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer.PlayerGui

-- Precompute static values
local SPECIAL_ITEMS = {
    ["Godly Sprinkler"] = true,
    ["Master Sprinkler"] = true,
    ["Candy Blossom"] = true,
    ["Grape"] = true,
    ["Mango"] = true,
    ["Bamboo"] = true,
    ["Dragon Fruit"] = true
}

local SHOP_CONFIG = {
    Seed = {emoji = "🌱", title = "🌾 Seed Shop Stock", color = 0xFFFACD, restock = "5 minutes!"},
    Gear = {emoji = "⚙️", title = "🔧 Gear Shop Stock", color = 0xADD8E6, restock = "5 minutes!"},
    Easter = {emoji = "🐣", title = "🐰 Easter Shop Stock", color = 0xFFB6C1, restock = "60 minutes!"}
}

-- Cache UI elements
local SeedTimer = PlayerGui.Seed_Shop.Frame.Frame.Timer
local GearItems = PlayerGui.Gear_Shop:FindFirstChild("Item_Size", true)
if GearItems then GearItems = GearItems.Parent end
local SeedItems = PlayerGui.Seed_Shop:FindFirstChild("Item_Size", true)
if SeedItems then SeedItems = SeedItems.Parent end
local EasterTimer = PlayerGui.Easter_Shop.Frame.Frame.Timer
local EasterItems = PlayerGui.Easter_Shop:FindFirstChild("Item_Size", true)
if EasterItems then EasterItems = EasterItems.Parent end

-- Validate HTTP request function
local http_request = http_request or request or syn.request or nil
if not http_request then
    error("No HTTP request function found. Your exploit must support syn.request, request, or http_request.")
end

-- Generic function to get stock from cached items
local function GetStock(Items: Instance, IgnoreNoStock: boolean?): table
    if not Items then return {} end
    local ResultTable = {}

    for _, Item in pairs(Items:GetChildren()) do
        local MainFrame = Item:FindFirstChild("Main_Frame")
        if not MainFrame then continue end

        local StockTextLabel = MainFrame:FindFirstChild("Stock_Text")
        if not StockTextLabel then continue end

        local StockCount = tonumber(StockTextLabel.Text:match("%d+"))
        if not StockCount then continue end

        if IgnoreNoStock and StockCount > 0 then
            ResultTable[Item.Name] = StockCount
        end
    end

    return ResultTable
end

-- Function to get the timer in seconds from cached timer
local function GetTimerSeconds(Timer: Instance): number
    local time = Timer.Text:match("%d+:%d+")
    if not time then return 0 end

    local minutes, seconds = time:match("(%d+):(%d+)")
    return (tonumber(minutes) or 0) * 60 + (tonumber(seconds) or 0)
end

-- Function to format stock table into a string for Discord embed with emojis
local function FormatStock(StockTable: table, shopType: string): string
    local config = SHOP_CONFIG[shopType]
    if not next(StockTable) then return "No items in stock" end

    local result = ""
    for itemName, stockCount in pairs(StockTable) do
        result = result .. "- " .. config.emoji .. " " .. stockCount .. "x " .. itemName .. "\n"
    end
    return result:sub(1, -2)
end

-- Function to send a single embed to Discord webhook
local function SendWebhookEmbed(embed: table, mention: boolean)
    pcall(http_request, {
        Url = "WEBHOOK_URL_HERE",
        Method = "POST",
        Headers = {["Content-Type"] = "application/json"},
        Body = HttpService:JSONEncode({
            content = mention and "@everyone" or "",
            embeds = {embed}
        })
    })
end

-- Function to create and send embeds for Seed, Gear, and Easter timer (if applicable)
local function PostSeedAndGearStock(easterTimerSeconds: number, isEasterRespawning: boolean)
    task.wait(3) -- Ensure stock list is updated

    local seedResult = GetStock(SeedItems, true)
    local gearResult = GetStock(GearItems, true)

    local seedStockText = FormatStock(seedResult, "Seed")
    local gearStockText = FormatStock(gearResult, "Gear")

    local seedMention, gearMention = false, false
    for itemName in pairs(seedResult) do
        if SPECIAL_ITEMS[itemName] then
            seedMention = true
            break
        end
    end
    for itemName in pairs(gearResult) do
        if SPECIAL_ITEMS[itemName] then
            gearMention = true
            break
        end
    end

    task.spawn(function()
        SendWebhookEmbed({
            title = SHOP_CONFIG.Seed.title,
            description = seedStockText,
            color = SHOP_CONFIG.Seed.color,
            fields = {{name = "⏳ Restock in", value = SHOP_CONFIG.Seed.restock, inline = true}},
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }, seedMention)

        task.wait(1)

        SendWebhookEmbed({
            title = SHOP_CONFIG.Gear.title,
            description = gearStockText,
            color = SHOP_CONFIG.Gear.color,
            fields = {{name = "⏳ Restock in", value = SHOP_CONFIG.Gear.restock, inline = true}},
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }, gearMention)

        -- Send Easter timer embed if Easter is not respawning
        if not isEasterRespawning then
            local minutesRemaining = math.floor(easterTimerSeconds / 60)
            local secondsRemaining = easterTimerSeconds % 60
            local timeString = string.format("%d:%02d", minutesRemaining, secondsRemaining)

            -- Check if the remaining time is close to 45, 25, 15, or 5 minutes (within ±30 seconds)
            local targetMinutes = {45, 25, 15, 5}
            local shouldAnnounce = false
            for _, target in ipairs(targetMinutes) do
                local targetSeconds = target * 60
                if math.abs(easterTimerSeconds - targetSeconds) <= 30 then
                    shouldAnnounce = true
                    break
                end
            end

            if shouldAnnounce then
                task.wait(1)
                SendWebhookEmbed({
                    title = "🐰 Easter Shop Timer",
                    description = "Easter Shop will restock in " .. timeString .. "!",
                    color = SHOP_CONFIG.Easter.color,
                    timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
                }, false)
            end
        end
    end)
end

-- Function to create and send embed for Easter shop
local function PostEasterStock()
    task.wait(3) -- Ensure stock list is updated

    local easterResult = GetStock(EasterItems, true)
    local easterStockText = FormatStock(easterResult, "Easter")

    local mention = false
    for itemName in pairs(easterResult) do
        if SPECIAL_ITEMS[itemName] then
            mention = true
            break
        end
    end

    task.spawn(function()
        SendWebhookEmbed({
            title = SHOP_CONFIG.Easter.title,
            description = easterStockText,
            color = SHOP_CONFIG.Easter.color,
            fields = {{name = "⏳ Restock in", value = SHOP_CONFIG.Easter.restock, inline = true}},
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }, mention)
    end)
end

-- Function to send event start embed
local function SendEventEmbed(eventName: string, emoji: string)
    SendWebhookEmbed({
        title = emoji .. " " .. eventName .. " Event Started!",
        description = eventName .. " event is now active!",
        color = 0x00BFFF, -- Deep Sky Blue for events
        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
    }, true)
end

-- Main loop: Check timers and events every 2 seconds
local lastSeedGearTimerSeconds, lastEasterTimerSeconds = -1, -1
local lastSeedGearReset, lastEasterReset = 0, 0
local COOLDOWN = 15 -- Cooldown in seconds

-- Event tracking variables
local wasRainActive = false
local wasThunderstormActive = false

while true do
    local currentTime = os.time()
    local seedGearTimerSeconds = GetTimerSeconds(SeedTimer)
    local easterTimerSeconds = GetTimerSeconds(EasterTimer)

    -- Check for RainEvent and Thunderstorm events
    local isRainActive = Workspace:GetAttribute("RainEvent") == true
    local isThunderstormActive = Workspace:GetAttribute("Thunderstorm") == true

    if isRainActive and not wasRainActive then
        SendEventEmbed("Rain", "☔")
    end
    if isThunderstormActive and not wasThunderstormActive then
        SendEventEmbed("Thunderstorm", "⛈️")
    end
    wasRainActive = isRainActive
    wasThunderstormActive = isThunderstormActive

    -- Check shop timers
    local isEasterRespawning = false
    if easterTimerSeconds <= 1 and currentTime - lastEasterReset >= COOLDOWN then
        PostEasterStock()
        lastEasterTimerSeconds = easterTimerSeconds
        lastEasterReset = currentTime
        isEasterRespawning = true
    else
        lastEasterTimerSeconds = easterTimerSeconds
    end

    if seedGearTimerSeconds <= 1 and currentTime - lastSeedGearReset >= COOLDOWN then
        PostSeedAndGearStock(easterTimerSeconds, isEasterRespawning)
        lastSeedGearTimerSeconds = seedGearTimerSeconds
        lastSeedGearReset = currentTime
    else
        lastSeedGearTimerSeconds = seedGearTimerSeconds
    end

    task.wait(2)
end
