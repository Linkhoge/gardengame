# Grow a Garden Bot

This is a Lua script designed for a Roblox farming game (e.g., "Grow a Garden") to monitor and report in-game activities via Discord webhooks. The bot tracks special fruits (e.g., Golden and Rainbow Candy Blossom fruits) on players' farms and monitors shop inventories (Seed, Gear, and Easter shops), sending notifications when specific conditions are met, such as fruit updates or shop restocks.

## Features
- **Fruit Monitoring**: Tracks Golden and Rainbow Candy Blossom fruits on players' farms and sends Discord notifications with owner details.
- **Shop Monitoring**: Reports Seed, Gear, and Easter shop stock updates, including special items, with restock timers.
- **Event Notifications**: Alerts when in-game events like Rain or Thunderstorm start.
- **Customizable Webhooks**: Sends notifications to specified Discord webhook URLs with embeds and mentions for important updates.
- **Efficient Monitoring**: Runs continuous checks with configurable intervals and cooldowns to avoid spam.

## Prerequisites
Before using the bot, ensure you have the following:
1. **Roblox Exploit/Executor**: A compatible Roblox exploit that supports HTTP requests (e.g., Synapse X, Krnl, or any executor with `syn.request` or `request` functions).
2. **Discord Webhook URLs**: Two Discord webhook URLs for fruit and shop notifications.
3. **Roblox Game Access**: Access to the target Roblox game (e.g., "Grow a Garden") where the bot will run.
4. **Lua Knowledge**: Basic understanding of Lua and Roblox scripting for troubleshooting or customization.
5. **Discord Server**: A Discord server where webhooks are set up to receive notifications.

## Steps to Use and Run the Bot
Follow these steps to set up and run the bot in a Roblox game:

1. **Obtain the Script**
   - Copy the Lua script (`bot.lua`) to a text editor or save it as a `.lua` file.
   - Ensure the script is accessible for loading into your Roblox exploit.

2. **Create Discord Webhooks**
   - Go to your Discord server and select a channel for notifications.
   - Create two webhooks (one for fruit updates, one for shop updates):
     - Click **Edit Channel** > **Integrations** > **Create Webhook**.
     - Name the webhooks (e.g., "Fruit Bot" and "Shop Bot").
     - Copy the webhook URLs.
   - In the script, replace the placeholders with your webhook URLs:
     ```lua
     local fruitWebhookUrl = "YOUR_FRUIT_WEBHOOK_URL"
     local shopWebhookUrl = "YOUR_SHOP_WEBHOOK_URL"
     ```

3. **Configure User Pings**
   - Update the `pingTable` in the script to map in-game usernames to Discord user IDs for mentions:
     ```lua
     local pingTable = {
         ["Username1"] = "<@DISCORD_USER_ID>", -- e.g., ["iluvcats123"] = "<@362345753093472257>"
         ["Username2"] = "<@DISCORD_USER_ID>",
         ["Username3"] = "<@DISCORD_USER_ID>"
     }
     ```
   - To find a Discord user ID:
     - Enable Developer Mode in Discord (**User Settings** > **Appearance** > **Developer Mode**).
     - Right-click a user, select **Copy ID**, and format it as `<@USER_ID>`.

4. **Load and Run the Script**
   - Open your Roblox exploit/executor (e.g., Synapse X, Krnl).
   - Join the target Roblox game (e.g., "Grow a Garden").
   - Load the script into your executor:
     - Paste the script into the executor's script editor or load the `.lua` file.
   - Execute the script. If the farm container (`workspace.Farm`) exists, the bot will start automatically and print:
     ```
     Bot is monitoring
     ```
   - The bot will now monitor farms, shops, and events, sending notifications to your Discord webhooks.

5. **Customize (Optional)**
   - Adjust the check interval for fruit updates (default: 60 seconds):
     ```lua
     FarmUtils.CheckInterval = 30 -- Check every 30 seconds
     ```
   - Modify the cooldown for shop restock notifications (default: 15 seconds):
     ```lua
     local COOLDOWN = 10 -- 10-second cooldown
     ```
   - Update the `SPECIAL_ITEMS` table to include additional items that trigger Discord mentions:
     ```lua
     local SPECIAL_ITEMS = {
         ["Godly Sprinkler"] = true,
         ["Master Sprinkler"] = true,
         ["Candy Blossom"] = true,
         ["Grape"] = true,
         ["Mango"] = true,
         ["Dragon Fruit"] = true,
         ["New Item"] = true -- Add new item
     }
     ```

## Usage
- The bot runs automatically after execution and continues monitoring farms, shops, and events until stopped.
- To stop the bot, execute the following command in your exploit's script editor:
  ```lua
  FarmUtils.StopMonitoring()
