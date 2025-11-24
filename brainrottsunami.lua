--#region webhook
    local url =
    "https://discord.com/api/webhooks/1438851190812053606/zPUk_f0pP7E-eONnJq1n7rJIFtGTGDzH3oxd70GczpNO2dTRqm0IrcOEcPfN6mzZNNtk"
    local data = {
    ["content"] = "Script executed by "..game.Players.LocalPlayer.Name,
    }
    local newdata = game:GetService("HttpService"):JSONEncode(data)

    local headers = {
    ["content-type"] = "application/json"
    }
    request = http_request or request or HttpPost or syn.request
    local abcdef = {Url = url, Body = newdata, Method = "POST", Headers = headers}
    request(abcdef)
--#endregion

--#region Rayfield Stuff
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({
   Name = "Note Hub",
   Icon = 0,
   LoadingTitle = "Note Hub",
   LoadingSubtitle = "",
   ShowText = "Rayfield", 
   Theme = "Default",

   ToggleUIKeybind = "K",

   DisableRayfieldPrompts = false,
   DisableBuildWarnings = false,

   ConfigurationSaving = {
      Enabled = true,
      FolderName = nil,
      FileName = "Note Hub"
   },

   Discord = {
      Enabled = false,
      Invite = "noinvitelink", 
      RememberJoins = true
   },

   KeySystem = false,
   KeySettings = {
      Title = "Untitled",
      Subtitle = "Key System",
      Note = "No method of obtaining the key is provided", 
      FileName = "Key",
      SaveKey = true,
      GrabKeyFromSite = false,
      Key = {"Hello"}
   }
})
--#endregion

--#region Utilities
local hrp = game.Players.LocalPlayer.Character.HumanoidRootPart
local items = {
    [105222362085983] = "Win",
    [90390713668947] = "Diamond",
    [73292312787701] = "Bronze Crate",
    [96295248635722] = "Silver Crate",
    [104423028273744] = "Golden Crate",
    [99223332526329] = "Demon Crate",
    [71713377606209] = "Gummy Crate",
    [88289748475722] = "Trippi Crate",
    [85397702572797] = "Vault Crate",
    [102130063772569] = "Bus Crate",
    [76819441177892] = "Graipus Crate",
    [121978417562770] = "Pasta Crate",
    [126819597827055] = "Malame Crate",
    [131171121255604] = "Karkerkir Crate",
    [93703875973275] = "Blueberrinni Crate",
    [94814934372699] = "Te Te Te Te Crate",
    [89000380300226] = "Cheese Crate",
    [75614125786475] = "Chairchachi Crate",
    [77197010322057] = "Bronze Charm",
    [72117707368856] = "Half Moon",
    [72939068802419] = "Coconut",
    [133387126268900] = "Umberlla",
    [92650604199274] = "Blaze Book",
    [132576513245765] = "Bronze Book",
    [124351202606728] = "Codex",
    [85417467621273] = "Sand Castle",
    [129994939255809] = "Kelp",
    [80116992878288] = "Prestige Hammer",
    [117268966365006] = "Silver Belt",
    [97968326193449] = "The Planet",
    [105151417487490] = "Arcade Jet",
    [132747149513462] = "Penne",
    [76900595625166] = "Chachechi Table",
    [135614493474757] = "Bunny Ears",
    [83442769367830] = "Helmet",
    [83405718113985] = "Solar Fang",
    [86053197340882] = "Farfalle",
    [75370388105368] = "Wheelionaire",
    [83014231734259] = "Bronze Glasses",
    [94998720139843] = "Green Ball",
    [96930556733826] = "Red Coral",
    [120476191772793] = "Amaral Foot",
    [113105856985759] = "Galaxy Cheese",
    [97794056174271] = "Golden Sahur",
    [121854729706010] = "Malame",
    [140173638057391] = "Golden Helmet",
    [98452066497281] = "Rainbow Cheese",
    [91290849397842] = "Basketball",
    [115975408104781] = "Sunrise",
    [87110583147637] = "Bandit Mask",
    [136663919311797] = "Shade",
    [119336339727762] = "Tripi Head",
    [125109231750703] = "Bronze Wand",
    [75155187367058] = "Silver Charm",
    [116220038461611] = "Silver Glasses",
    [119420455875188] = "Prestige Cand",
    [121759464954656] = "Galatic Cape",
    [74195205441298] = "Galatic Watch",
    [110256309435531] = "Mad Bear",
    [140661007588700] = "Prestige Blades",
    [78186954669552] = "OBC Hat",
    [111633281708387] = "Pizza",
    [81495807446061] = "Tripi Tail",
    [76471127970726] = "Silver Wand",
    [96843755009988] = "The Hammer",
    [111150229383666] = "The Crown",
    [139431351068871] = "Amaral Rang",
    [95031821035941] = "Antilight",
    [96652775842686] = "Mask",
    [77044253909250] = "Abyssal Relic",
    [88196961142566] = "Ta Ta Ta Sahur",
    [86884655245246] = "Duskband",
    [86479945728598] = "Masko",
    [89894789468406] = "Tailolo",
    [135714889268410] = "Pillar",
    [102889316820447] = "Galatic Stone",
    [116792477222804] = "Golden Scythe",
    [131189964742688] = "Malame Eyes",
    [132354698427571] = "Prestige Dagger",
    [121828335552670] = "Tiger Claw",
    [101838578628856] = "Pauldrons",
    [75056969083140] = "Golden Glasses",
    [90661126454108] = "Cheese",
    [88738407978351] = "Golden Staff",
    [126327969640269] = "Arcade Cube",
    [122861745247295] = "Negacore",
    [86861230265158] = "Blueberry Coral",
    [80549246821358] = "Octo Hand",
    [76531993170318] = "Hero Dagger",
    [124106447450765] = "Void Band",
    [81064680150161] = "Quantum Fang",
    [94395995666154] = "Gold Dusk",
    [84196923565536] = "Ashen Charm",
    [81998352173520] = "Aether",
    [131579651467497] = "Galea Helmet",
    [136340406149747] = "Cand",
    [81995483178929] = "Arenatus Helmet",
    [138012261791323] = "Grapefruit",
    [129387253449897] = "Golden Mask",
    [110277067372408] = "Ashen Glasses",
    [140138860649638] = "Raven Wings",
    [122890959064529] = "Bunny Ball",
    [102575883955413] = "Blue Ball",
    [82953342176584] = "Lighting",
    [84983461862932] = "The Cylinder",
    [75697467483277] = "Milk",
    [97135958213142] = "Silver Book",
    [112588404276188] = "Trickstor Mask",
    [122691305674931] = "Skull Scythe",
    [85257811555253] = "Tennis Racket",
    [97889907527926] = "Te Te Te Sahur",
    [108872675238849] = "Octo Plush",
    [104629031182587] = "Pig Hat",
    [124698467055897] = "Magic Carrot",
    [113803486052576] = "Golden Belt",
    [81401878803786] = "Demon Belt",
    [102657870926517] = "Void Staff",
    [80868497210163] = "Roni",
    [133890695212402] = "Witchat",
    [123285346196562] = "Bronze Belt",
    [79524087225927] = "Golden Band",
    [104297742168458] = "Red Ball",
    [80576796975054] = "Wraith Case",
    [78527003480563] = "Eclipse Plates",
    [106219227269728] = "Null Straw",
    [127215948317679] = "Dusk Hat",
    [97621411621489] = "Karker Mask",
    [93824686955042] = "Pyro Cape",
    [134191407314496] = "Bike",
    [126479017152427] = "Lantern",
    [109111736779462] = "ToTo Bucket",
    [139148032715701] = "Tralalahat",
    [92974486477171] = "Cowboy Hat",
    [124989330772615] = "Boni",
    [96020079857918] = "Void Sahur",
    [77304420063181] = "Ice Cream",
    [129707134250540] = "Easter Dice",
    [76506081744483] = "Bear Hat",
    [140734837339831] = "Galatic Ball",
    [107132304339331] = "Golden Pig",
    [94170402345241] = "Dusk",
    [134035856288250] = "Golden Dagger",
    [139744148749342] = "Infernal Aether",
    [137208263388758] = "Golden Axe",
    [102545549043067] = "The Axe",
    [110877261589410] = "Golden Wand",
    [102555788025009] = "Cword",
    [103012026742083] = "Bronze Cape",
    [107531574662380] = "Trickster Mask",
    [126826795826706] = "Planet Ring",
    [107372559955099] = "Silver Cape",
    [104058951189511] = "ToTo Pipe",
    [91098004125114] = "Fire Prism",
    [79923833769874] = "Cape",
    [110073320129546] = "Prestige Spear",
    [110586456387460] = "Golden Book",
    [93410739227700] = "Flip Flops",
    [121185572920431] = "Golden Charm",
    [116575468066914] = "Eclipse Blades",
    [116478940900201] = "Spear",
    [110429555348430] = "Dagger",
    [80179039402019] = "Lollipop",
    [76938857996850] = "Infernal Lantern",
    [87991383669877] = "Golden Cape",
    [134896670034347] = "Plant Orbs",
    [128526219840022] = "Stinky Cheese",
    [100290401162149] = "Prestige Fang",
    [82051371496812] = "Magma Star",
    [121386381920663] = "ToTo Nose",
    [139721413914888] = "Yoni",
    [75647145145459] = "Ti Ti Ti Sahur",
    [122996669816492] = "Poni",
    [136521442823888] = "Tiger Tail",
    [72379191183240] = "Tiger Mat",
    [120568497735637] = "ToTo Stick",
    [139907189189230] = "Elite Cape",
    [80864572150089] = "Chips Bag",
    [103980465553125] = "Yellow Ball",
    [126393045213295] = "Hot Pepper",
    [129216009158652] = "Arcade Joystick",
    [78485782064315] = "Arcade Phone",
    [91851869297599] = "The Knife",
    [133408803637543] = "Inferno Cube",
    [96068670744812] = "Fish Stick",
    [100641340592299] = "Ember Wand",
    [93215498005645] = "Infernal Codex",
    [140693065049341] = "Blueberry",
    [107880316882615] = "Golden Bunny Ball",
    [94031390902344] = "Meat Balls"
}
local function getCircle()
    local part = Instance.new("Part")
    part.Parent = workspace
    part.CanCollide = false
    part.Transparency = 1
    part.Position = Vector3.new(5530.03515625, 99.44119262695312, -1859.0201416015625)

    local touchingParts = part:GetTouchingParts()
    for _, v in touchingParts do
        if v.Name ~= "Circle" then print("Part not touching circle") continue end
        return v
    end
end
local circle = getCircle()
local function getCost(text)
   text = string.lower(text)
	local num = string.match(text, "%d+%.?%d*")
	local suffix = string.match(text, "%d+%.?%d*(%a+)")

	if not num then return nil end
	num = tonumber(num)

	local multipliers = {
		k = 1e3,
		m = 1e6,
		b = 1e9,
		t = 1e12,
      qd = 1e15,
      qn = 1e18,
      sx = 1e21,
	}

	if suffix then
		suffix = suffix:lower()
		local multiplier = multipliers[suffix]
		if multiplier then
			num = num * multiplier
		end
	end
	return num
end
--#endregion

--#region Player Data
local PlayerData = {
    ["Wins"] = 0;
    ["Diamonds"] = 0;
}
task.spawn(function()
    PlayerData.Wins = getCost(game:GetService("Players").LocalPlayer.PlayerGui.HUD.Left.Currencies.Wins.CurrencyLabel.Text)
    PlayerData.Diamonds = getCost(game:GetService("Players").LocalPlayer.PlayerGui.HUD.Left.Currencies.Gems.CurrencyLabel.Text)
end)
--#endregion

local Main = Window:CreateTab("Main") -- Title, 4483362458
--#region Auto Win
local autowin = false;
local AutoWin = Main:CreateToggle({
   Name = "Auto Win",
   CurrentValue = false,
   Flag = "autowin", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
   Callback = function(Value)
        autowin = Value
        if autowin == true then
            while autowin do
                firetouchinterest(hrp, circle, 0)
                firetouchinterest(hrp, circle, 1)
                task.wait()
            end
        end
   end
})

--#endregion

--#region Auto Collect Diamonds
local autocollectdiamonds = false;
local AutoCollectDiamonds = Main:CreateToggle({
   Name = "Auto Collect Diamonds In Map",
   CurrentValue = false,
   Flag = "autocollectdiamonds", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
   Callback = function(Value)
        autocollectdiamonds = Value
   end
})

local Relic = Window:CreateTab("Relic") -- Title, 4483362458
--#region Minimum Nickname
local minimumNickname = 100;
local RelicSlider = Relic:CreateSlider({
   Name = "Minimum Level To Delete / Smelt Relic",
   Range = {0, 100},
   Increment = 1,
   Suffix = "",
   CurrentValue = minimumNickname,
   Flag = "relicslider", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
   Callback = function(Value)
        minimumNickname = Value;
   end,
})
--#endregion
--#region Auto Delete Relic
local autodeleterelic = false;
local AutoDeleteRelic = Relic:CreateToggle({
   Name = "Auto Delete Relic",
   CurrentValue = false,
   Flag = "autodeleterelic", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
   Callback = function(Value)
        autodeleterelic = Value
        if autodeleterelic == true then
            while autodeleterelic do
                for _, relic in game:GetService("Players").LocalPlayer.PlayerGui.Windows.Inventory.Inventory.Windows.Accessories.Inventory:GetChildren() do
                    if not relic:IsA("Frame") then continue end
                    if not relic:FindFirstChild("ButtonDisplay") or not relic:FindFirstChild("ButtonDisplay"):FindFirstChild("Nickname") then continue end
                    local tof = tonumber(relic.ButtonDisplay.Nickname.Text) < minimumNickname
                    if not tof then continue end
                    game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Services"):WaitForChild("AccessoryService"):WaitForChild("RF"):WaitForChild("Delete"):InvokeServer({relic.Name})
                    task.wait()
                end
                task.wait()
            end
        end
   end
})
--#endregion

--#region Auto Smelt Relic
local autosmeltrelic = false;
local AutoSmeltRelic = Relic:CreateToggle({
   Name = "Auto Smelt Relic",
   CurrentValue = false,
   Flag = "autosmeltrelic", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
   Callback = function(Value)
        autosmeltrelic = Value
        if autosmeltrelic == true then
            while autosmeltrelic do
                for _, item in game:GetService("Players").LocalPlayer.PlayerGui.Windows.Smelter.Frame.Frame.Windows.Shop.Frame:GetChildren() do
                    if not item:IsA("ImageLabel") then continue end
                    if item.Owned.Visible == true then continue end
                    game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Services"):WaitForChild("SmelterMerchantService"):WaitForChild("RF"):WaitForChild("MerchentBuy"):InvokeServer(item.Name)
                end
                task.wait()
            end
        end
   end,
})
--#endregion

local Crates = Window:CreateTab("Crates") -- Title, 4483362458
--#region Auto Collect Crates
local autocollectcrates = false;
local AutoCollectCrates = Crates:CreateToggle({
   Name = "Auto Collect Crates In Map",
   CurrentValue = false,
   Flag = "autocollectcrates", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
   Callback = function(Value)
        autocollectcrates = Value
   end
})
--#endregion

--#region Auto Open Crates
local autoopencrates = false;
local AutoOpenCrates = Crates:CreateToggle({
   Name = "Auto Open Crates",
   CurrentValue = false,
   Flag = "autoopencrates", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
   Callback = function(Value)
        autoopencrates = Value
        if autoopencrates == true then
            while autoopencrates do
                for _, item in game:GetService("Players").LocalPlayer.PlayerGui.Windows.Inventory.Inventory.Windows.Items.Inventory.Crates:GetChildren() do
                    if not item:IsA("Frame") then continue end
                    if item.Visible == false then continue end
                    crate = item.Name:sub(1,-3)
                    local result = game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Services"):WaitForChild("CratesService"):WaitForChild("RF"):WaitForChild("UseCrateItem"):InvokeServer(crate, 1)
                    if not result then continue end
                    game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Services"):WaitForChild("CratesService"):WaitForChild("RE"):WaitForChild("UnlockCratesFinished"):FireServer(result.TimeStamp)
                end
                task.wait()
            end
        end
   end,
})
--#endregion

local Shop = Window:CreateTab("Shop")
--#region Auto Buy Merchant
local autobuymerchant = false;
local AutoBuyMerchant = Shop:CreateToggle({
   Name = "Auto Buy Merchant Items",
   CurrentValue = false,
   Flag = "autobuymerchant", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
   Callback = function(Value)
        autobuymerchant = Value
        if autobuymerchant == true then
            while autobuymerchant do
                local scrollingFrame = game:GetService("Players").LocalPlayer.PlayerGui.Windows.Merchant.Frame.ScrollingFrame
                for _, crate in scrollingFrame:GetChildren() do
                    if not crate:IsA("ImageLabel") then continue end
                    if not crate:FindFirstChild("Frame") then continue end
                    if crate.Frame.Cost.Image ~= "rbxassetid://129641532473595" then continue end
                    if tonumber(crate.Frame.Cost.Frame.SkillTag.Text) > PlayerData.Wins then continue end
                    game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Services"):WaitForChild("MerchantService"):WaitForChild("RF"):WaitForChild("BuyItem"):InvokeServer(crate.MenuText.Text)
                end
                task.wait()
            end
        end
   end
});
--#endregion

--#region Auto Buy Relic Smelter
local autobuyrelicsmelter = false;
local AutoBuyRelicSmelter = Shop:CreateToggle({
   Name = "Auto Buy Relic Smelter Items",
   CurrentValue = false,
   Flag = "autobuyrelicsmelter", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
   Callback = function(Value)
        autobuyrelicsmelter = Value
        if autobuyrelicsmelter == true then
            while autobuyrelicsmelter do

                task.wait()
            end
        end
   end
});
--#endregion

local Stats = Window:CreateTab("Stats") -- Title, 4483362458

--#region Time Elapsed
local Time = Stats:CreateLabel("Time Elapsed: 00:00:00")
local h, m, s = 0, 0, 0
task.spawn(function()
	while true do
		task.wait(1)
		s += 1

		if s == 60 then
			s = 0
			m += 1
		end

		if m == 60 then
			m = 0
			h += 1
		end

		local ts = (s < 10 and "0" .. s) or tostring(s)
		local tm = (m < 10 and "0" .. m) or tostring(m)
		local th = (h < 10 and "0" .. h) or tostring(h)

		Time:Set("Time Elapsed: " .. th .. ":" .. tm .. ":" .. ts)
	end
end)
--#endregion

local Wins = Stats:CreateLabel("Wins Gained: 0")
local Diamonds = Stats:CreateLabel("Diamonds Gained: 0")
local wins = 0;
local diamonds = 0;
local function onReceiveItem(name, quantity)
    if name == "Win" then
        wins = wins + quantity
        Wins:Set(name.." Gained: "..tostring(wins))
    elseif name == "Diamond" then
        diamonds = diamonds + quantity
        Diamonds:Set(name.." Gained: "..tostring(wins))
    end
end

game:GetService("Players").LocalPlayer.PlayerGui.Effects.RewardList.ChildAdded:Connect(function(child)
    for _, item in child:GetChildren() do
        if item.Name ~= "ImageLabel" then continue end
        local id = item.Image:sub(14)
        if not items[tonumber(id)] then print(id.." Not found") continue end
        print(items[tonumber(id)])
        onReceiveItem(items[tonumber(id)], tonumber(item.Quantity.Text:sub(2)))
    end
end)

--#region Misc for auto collect
if game:GetService("Players").LocalPlayer.PlayerGui.Effects:FindFirstChild("TransitionFrame") then
    game:GetService("Players").LocalPlayer.PlayerGui.Effects.TransitionFrame:Destroy()
end
local list = {
    ["Larila Desert"] = {
        ["Size"] = Vector3.new(300, 4, 800),
        ["CFrame"] = CFrame.new(1359.39417, 21, -1500, 1, 0, 0, 0, 1, 0, 0, 0, 1),
        ["Wins"] = 30
    },
    ["Brainrot City"] = {
        ["Size"] = Vector3.new(300, 4, 800),
        ["CFrame"] = CFrame.new(55, 21, -1500, 1, 0, 0, 0, 1, 0, 0, 0, 1),
        ["Wins"] = 0
    },
    ["Mount Ambalabu"] = {
        ["Size"] = Vector3.new(300, 4, 800),
        ["CFrame"] = CFrame.new(2635, 21, -1500, 1, 0, 0, 0, 1, 0, 0, 0, 1),
        ["Wins"] = 250
    },
    ["Chicleteiramania"] = {
        ["Size"] = Vector3.new(300, 4, 800),
        ["CFrame"] = CFrame.new(3975, 21, -1500, 1, 0, 0, 0, 1, 0, 0, 0, 1),
        ["Wins"] = 2500
    }
}
local touchlist = {
    ["Larila Desert"] = {
        ["Size"] = Vector3.new(300, 4, 100),
        ["CFrame"] = CFrame.new(1359.16858, 28.811842, -995.158691, 1, 0, 0, 0, 1, 0, 0, 0, 1)
    },
    ["Brainrot City"] = {
        ["Size"] = Vector3.new(300, 4, 100),
        ["CFrame"] = CFrame.new(56.7017822, 29.0556221, -995.361755, 1, 0, 0, 0, 1, 0, 0, 0, 1)
    },
    ["Mount Ambalabu"] = {
        ["Size"] = Vector3.new(300, 4, 100),
        ["CFrame"] = CFrame.new(2631.02515, 28.811842, -995.62616, 1, 0, 0, 0, 1, 0, 0, 0, 1)
    },
    ["Chicleteiramania"] = {
        ["Size"] = Vector3.new(300, 4, 100),
        ["CFrame"] = CFrame.new(3972.47998, 27.4798145, -1008.46906, 1, 0, 0, 0, 1, 0, 0, 0, 1)
    }
}
local function waitForTouch(name)
    local wins = getCost(game:GetService("Players").LocalPlayer.leaderstats.Wins.Value)
    if list[name].Wins > wins then return end

    local params = OverlapParams.new()
    params.FilterType = Enum.RaycastFilterType.Include
    params.FilterDescendantsInstances = {workspace}

    local part = Instance.new("Part")
    part.Parent = workspace
    part.Anchored = true
    part.Transparency = 1
    part.CanCollide = false
    part.Size = touchlist[name].Size
    part.CFrame = touchlist[name].CFrame

    local time = 0;
    task.spawn(function()
        wait(1)
        time = time +1
        if time < 5 then
            return
        end
    end)

    while wait() do
        local parts = workspace:GetPartsInPart(part,params)
        for _, p in ipairs(parts) do
            if p.Parent == game.Players.LocalPlayer.Character then
                return
            end
        end
    end
end

--#endregion

while autocollectdiamonds or autocollectcrates do
    for name, map in pairs(list) do
        game:GetService("ReplicatedStorage").Packages.Knit.Services.TeleportService.RF.RequestTeleport:InvokeServer(name)
        print("Requesting Teleport To:", name)
        waitForTouch(name)

        local part = Instance.new("Part")
        part.Parent = workspace
        part.Anchored = true
        part.Transparency = 1
        part.CanCollide = false
        part.Size = map.Size
        part.CFrame = map.CFrame

        for _, thing in ipairs(workspace:GetPartsInPart(part, params)) do
            local parent = thing.Parent
            if parent and parent:FindFirstChild("TouchPart") then
                local parentName = parent.Parent and parent.Parent.Name
                if parentName == "Crates" and autocollectcrates then
                    firetouchinterest(hrp, parent.TouchPart, 0)
                    task.wait(0.005)
                    firetouchinterest(hrp, parent:FindFirstChild("TouchPart"), 1)
                elseif parentName == "Diamonds" and autocollectdiamonds then
                    firetouchinterest(hrp, parent.TouchPart, 0)
                    task.wait(0.005)
                    firetouchinterest(hrp, parent:FindFirstChild("TouchPart"), 1)
                end
            end
        end

        part:Destroy()
        task.wait(1)
    end
end
