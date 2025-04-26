local game = game
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer.PlayerGui
local wait = task and task.wait or wait

local farmContainer = workspace:FindFirstChild("Farm")
local fruitWebhookUrl = "URL_WEBHOOK_HERE"
local shopWebhookUrl = "URL_WEBHOOK_HERE"

local function makeHttpRequest(url, data)
    if syn and syn.request then
        local response = syn.request({
            Url = url,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode(data)
        })
        return response.Success, response.StatusMessage
    elseif request then
        local response = request({
            Url = url,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode(data)
        })
        return response.Success, response.StatusMessage
    end
    return false, "Unsupported exploit environment"
end

local FarmUtils = {}

local pingTable = {
    ["Username1"] = "<@DEVID>", -- ["iluvcats123"] = "<@362345753093472257>"
    ["Username2"] = "<@DEVID>",
    ["Username3"] = "<@DEVID>"
}

local SPECIAL_ITEMS = {
    ["Godly Sprinkler"] = true,
    ["Master Sprinkler"] = true,
    ["Candy Blossom"] = true,
    ["Grape"] = true,
    ["Mango"] = true,
    ["Dragon Fruit"] = true
}

local SHOP_CONFIG = {
    Seed = {emoji = "🌱", title = "🌾 Seed Shop Stock", color = 0xFFFACD, restock = "5 minutes!"},
    Gear = {emoji = "⚙️", title = "🔧 Gear Shop Stock", color = 0xADD8E6, restock = "5 minutes!"},
    Easter = {emoji = "🐣", title = "🐰 Easter Shop Stock", color = 0xFFB6C1, restock = "60 minutes!"}
}

local SeedTimer = PlayerGui.Seed_Shop.Frame.Frame.Timer
local GearItems = PlayerGui.Gear_Shop:FindFirstChild("Item_Size", true)
if GearItems then GearItems = GearItems.Parent end
local SeedItems = PlayerGui.Seed_Shop:FindFirstChild("Item_Size", true)
if SeedItems then SeedItems = SeedItems.Parent end
local EasterTimer = PlayerGui.Easter_Shop.Frame.Frame.Timer
local EasterItems = PlayerGui.Easter_Shop:FindFirstChild("Item_Size", true)
if EasterItems then EasterItems = EasterItems.Parent end

FarmUtils.IsRunning = false
FarmUtils.CheckInterval = 60
local lastResults = {}
local lastSeedGearTimerSeconds, lastEasterTimerSeconds = -1, -1
local lastSeedGearReset, lastEasterReset = 0, 0
local wasRainActive, wasThunderstormActive = false, false
local COOLDOWN = 15

local function GetStock(Items)
    if not Items then return {} end
    local ResultTable = {}
    for _, Item in pairs(Items:GetChildren()) do
        local MainFrame = Item:FindFirstChild("Main_Frame")
        if not MainFrame then continue end
        local StockTextLabel = MainFrame:FindFirstChild("Stock_Text")
        if not StockTextLabel then continue end
        local StockCount = tonumber(StockTextLabel.Text:match("%d+"))
        if StockCount and StockCount > 0 then
            ResultTable[Item.Name] = StockCount
        end
    end
    return ResultTable
end

local function GetTimerSeconds(Timer)
    local time = Timer.Text:match("%d+:%d+")
    if not time then return 0 end
    local minutes, seconds = time:match("(%d+):(%d+)")
    return (tonumber(minutes) or 0) * 60 + (tonumber(seconds) or 0)
end

local function FormatStock(StockTable, shopType)
    local config = SHOP_CONFIG[shopType]
    if not next(StockTable) then return "No items in stock" end
    local result = ""
    for itemName, stockCount in pairs(StockTable) do
        result = result .. "- " .. config.emoji .. " " .. stockCount .. "x " .. itemName .. "\n"
    end
    return result:sub(1, -2)
end

local function SendWebhookEmbed(url, embed, mention)
    pcall(makeHttpRequest, url, {
        content = mention and "@everyone" or "",
        embeds = {embed},
        username = "goid",
        avatar_url = "https://i.imgur.com/4M34hi2.png"
    })
end

function FarmUtils.CountFruitsAndNotify(farmContainer, webhookUrl)
    if not farmContainer or not webhookUrl then return end

    local players = {}
    for _, player in pairs(Players:GetPlayers()) do
        table.insert(players, player.Name)
    end

    for _, farm in pairs(farmContainer:GetChildren()) do
        if not (farm:IsA("Folder") or farm:IsA("Model")) then continue end
        local important = farm:FindFirstChild("Important")
        if not important then continue end
        local data = important:FindFirstChild("Data")
        local plantsPhysical = important:FindFirstChild("Plants_Physical")
        if not (data and plantsPhysical) then continue end
        local ownerValue = data:FindFirstChild("Owner")
        if not ownerValue or not pingTable[ownerValue.Value] then continue end
        if not table.find(players, ownerValue.Value) then continue end

        local candyBlossomTreeCount = 0
        local goldFruitCount = 0
        local rainbowFruitCount = 0

        for _, plant in pairs(plantsPhysical:GetChildren()) do
            if plant:IsA("Model") and plant.Name == "Candy Blossom" then
                candyBlossomTreeCount += 1
                local fruitsFolder = plant:FindFirstChild("Fruits")
                if fruitsFolder then
                    for _, fruit in pairs(fruitsFolder:GetChildren()) do
                        if fruit:IsA("Model") and fruit.Name == "Candy Blossom" then
                            local variantValue = fruit:FindFirstChild("Variant")
                            if variantValue and variantValue:IsA("StringValue") then
                                if variantValue.Value == "Gold" then
                                    goldFruitCount += 1
                                elseif variantValue.Value == "Rainbow" then
                                    rainbowFruitCount += 1
                                end
                            end
                        end
                    end
                end
            end
        end

        if goldFruitCount == 0 and rainbowFruitCount == 0 then continue end

        local farmKey = farm:GetFullName()
        if lastResults[farmKey] and 
           goldFruitCount <= lastResults[farmKey].GoldFruitCount and 
           rainbowFruitCount <= lastResults[farmKey].RainbowFruitCount then
            continue
        end

        lastResults[farmKey] = {
            Owner = ownerValue.Value,
            TreeCount = candyBlossomTreeCount,
            GoldFruitCount = goldFruitCount,
            RainbowFruitCount = rainbowFruitCount
        }

        local embed = {
            title = "Candy Blossom Farm Update",
            description = string.format(
                "**Golden Fruits**: %d\n**Rainbow Fruits**: %d 🌈",
                goldFruitCount,
                rainbowFruitCount
            ),
            color = 0xF4C7D6,
            fields = {
                {name = "Owner", value = ownerValue.Value, inline = true},
                {name = "Trees", value = tostring(candyBlossomTreeCount), inline = true}
            },
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }

        pcall(makeHttpRequest, webhookUrl, {
            content = pingTable[ownerValue.Value],
            embeds = {embed},
            username = "Grow a Garden Bot",
            avatar_url = "https://i.imgur.com/4M34hi2.png"
        })
    end
end

function FarmUtils.PostSeedAndGearStock(easterTimerSeconds, isEasterRespawning, webhookUrl)
    task.wait(3)
    local seedResult = GetStock(SeedItems)
    local gearResult = GetStock(GearItems)

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
        SendWebhookEmbed(webhookUrl, {
            title = SHOP_CONFIG.Seed.title,
            description = seedStockText,
            color = SHOP_CONFIG.Seed.color,
            fields = {{name = "⏳ Restock in", value = SHOP_CONFIG.Seed.restock, inline = true}},
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }, seedMention)

        task.wait(1)
        SendWebhookEmbed(webhookUrl, {
            title = SHOP_CONFIG.Gear.title,
            description = gearStockText,
            color = SHOP_CONFIG.Gear.color,
            fields = {{name = "⏳ Restock in", value = SHOP_CONFIG.Seed.restock, inline = true}},
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }, gearMention)

        if not isEasterRespawning then
            local minutesRemaining = math.floor(easterTimerSeconds / 60)
            local secondsRemaining = easterTimerSeconds % 60
            local timeString = string.format("%d:%02d", minutesRemaining, secondsRemaining)
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
                SendWebhookEmbed(webhookUrl, {
                    title = "🐰 Easter Shop Timer",
                    description = "Easter Shop will restock in " .. timeString .. "!",
                    color = SHOP_CONFIG.Easter.color,
                    timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
                }, false)
            end
        end
    end)
end

function FarmUtils.PostEasterStock(webhookUrl)
    task.wait(3)
    local easterResult = GetStock(EasterItems)
    local easterStockText = FormatStock(easterResult, "Easter")

    local mention = false
    for itemName in pairs(easterResult) do
        if SPECIAL_ITEMS[itemName] then
            mention = true
            break
        end
    end

    task.spawn(function()
        SendWebhookEmbed(webhookUrl, {
            title = SHOP_CONFIG.Easter.title,
            description = easterStockText,
            color = SHOP_CONFIG.Easter.color,
            fields = {{name = "⏳ Restock in", value = SHOP_CONFIG.Easter.restock, inline = true}},
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }, mention)
    end)
end

function FarmUtils.SendEventEmbed(eventName, emoji, webhookUrl)
    SendWebhookEmbed(webhookUrl, {
        title = emoji .. " " .. eventName .. " Event Started!",
        description = eventName .. " event is now active!",
        color = 0x00BFFF,
        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
    }, true)
end

function FarmUtils.StartMonitoring(fruitWebhookUrl, shopWebhookUrl)
    if FarmUtils.IsRunning then return end

    FarmUtils.IsRunning = true

    coroutine.wrap(function()
        while FarmUtils.IsRunning do
            pcall(function()
                FarmUtils.CountFruitsAndNotify(workspace:FindFirstChild("Farm"), fruitWebhookUrl)
            end)
            wait(FarmUtils.CheckInterval)
        end
    end)()

    coroutine.wrap(function()
        while FarmUtils.IsRunning do
            pcall(function()
                local currentTime = os.time()
                local seedGearTimerSeconds = GetTimerSeconds(SeedTimer)
                local easterTimerSeconds = GetTimerSeconds(EasterTimer)

                local isRainActive = workspace:GetAttribute("RainEvent") == true
                local isThunderstormActive = workspace:GetAttribute("Thunderstorm") == true

                if isRainActive and not wasRainActive then
                    FarmUtils.SendEventEmbed("Rain", "☔", shopWebhookUrl)
                end
                if isThunderstormActive and not wasThunderstormActive then
                    FarmUtils.SendEventEmbed("Thunderstorm", "⛈️", shopWebhookUrl)
                end
                wasRainActive = isRainActive
                wasThunderstormActive = isThunderstormActive

                local isEasterRespawning = false
                if easterTimerSeconds <= 1 and currentTime - lastEasterReset >= COOLDOWN then
                    FarmUtils.PostEasterStock(shopWebhookUrl)
                    lastEasterTimerSeconds = easterTimerSeconds
                    lastEasterReset = currentTime
                    isEasterRespawning = true
                else
                    lastEasterTimerSeconds = easterTimerSeconds
                end

                if seedGearTimerSeconds <= 1 and currentTime - lastSeedGearReset >= COOLDOWN then
                    FarmUtils.PostSeedAndGearStock(easterTimerSeconds, isEasterRespawning, shopWebhookUrl)
                    lastSeedGearTimerSeconds = seedGearTimerSeconds
                    lastSeedGearReset = currentTime
                else
                    lastSeedGearTimerSeconds = seedGearTimerSeconds
                end
            end)
            wait(2)
        end
    end)()
end

function FarmUtils.StopMonitoring()
    FarmUtils.IsRunning = false
end

getgenv().FarmUtils = FarmUtils

if farmContainer then
    FarmUtils.StartMonitoring(fruitWebhookUrl, shopWebhookUrl)
    print("Bot is monitering")
end

return FarmUtils
