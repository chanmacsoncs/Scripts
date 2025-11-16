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
      FileName = "Note Hub (pab)"
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

local Main = Window:CreateTab("Main") -- Title, Image
local function createToggle(args)
    local name, flag, tab, callback  = args[1], args[2], args[3], args[4]

    local toggle = false;
    local Toggle = tab:CreateToggle({
        Name = name,
        CurrentValue = false,
        Flag = flag,
        Callback = function(value)
            toggle = value;
            repeat
                callback()
                task.wait()
            until not toggle
        end
    })
end

createToggle({
    "Auto Push Brainrots",
    "autopushbrainrots",
    Main,
    function()
        for _, thing in workspace.PlayerBrainrots[game.Players.LocalPlayer.Name]:GetChildren() do
            game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Net"):WaitForChild("RE/BrainrotFell"):FireServer(thing.Name)
            task.wait()
        end
    end
})

createToggle({
    "Auto Sell",
    "autosell",
    Main,
    function()
        game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Net"):WaitForChild("RF/Sell"):InvokeServer("All")
    end
})

createToggle({
    "Auto Rebirth",
    "autorebrith",
    Main,
    function()
        game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Net"):WaitForChild("RF/Rebirth"):InvokeServer()
    end
})
