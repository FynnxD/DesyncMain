--[[
	WARNING: Heads up! This script has not been verified by ScriptBlox. Use at your own risk!
]]
-- Wir packen alles in ein task.defer, damit der Loadstring sauber im Hintergrund initialisiert wird
task.defer(function()
	local hotkey = _G.desyncHotkey or Enum.KeyCode.F1
	local autoHotkey5s = Enum.KeyCode.F2
	local autoHotkey2s = Enum.KeyCode.F3

	local uis = game:GetService("UserInputService")
	local lp = game.Players.LocalPlayer
	local starterGui = game:GetService("StarterGui")
	
	local desyncActive = false
	local autoDesyncActive = false 
	local currentLoopTime = 5      
	local mainCharacter = nil
	local deathConnections = {}
	local activeEffects = {}
	local activeModeName = "None"

	-- Start-Notification
	pcall(function()
		starterGui:SetCore("SendNotification", {
			Title = "Script Loaded!";
			Text = "Made by Fynn_xD/Press F1 for desync\nF2 for every 5 second Desync\nF3 for Every 2 second desync";
			Duration = 7;
		})
	end)

	-- Hilfsfunktion für Effekte
	local function createCleanEffect(targetCharacter)
		pcall(function()
			local highlight = Instance.new("Highlight")
			highlight.Name = "DesyncOutline"
			highlight.FillColor = Color3.fromRGB(255, 255, 255)
			highlight.FillTransparency = 0.6
			highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
			highlight.OutlineTransparency = 0
			highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
			highlight.Parent = targetCharacter
			table.insert(activeEffects, highlight)

			for _, part in pairs(targetCharacter:GetChildren()) do
				if part:IsA("BasePart") then
					local originalMaterial = part.Material
					local originalColor = part.Color
					
					part.Material = Enum.Material.ForceField
					part.Color = Color3.fromRGB(255, 255, 255)
					
					table.insert(activeEffects, {Part = part, Material = originalMaterial, Color = originalColor})
				end
			end
		end)
	end

	-- Hilfsfunktion zum Entfernen der Effekte
	local function removeEffects()
		for _, effect in pairs(activeEffects) do
			pcall(function()
				if typeof(effect) == "Instance" then
					effect:Destroy()
				elseif type(effect) == "table" and effect.Part and effect.Part.Parent then
					effect.Part.Material = effect.Material
					effect.Part.Color = effect.Color
				end
			end)
		end
		activeEffects = {}
	end

	-- Aktiviert den Desync
	local function activate(suppressNotification)
		if desyncActive then return end
		
		local success, err = pcall(function()
			mainCharacter = lp.Character
			if not mainCharacter or not mainCharacter:FindFirstChild("HumanoidRootPart") then return end
			
			desyncActive = true
			
			local oldArchivable = mainCharacter.Archivable
			mainCharacter.Archivable = true
			local clone = mainCharacter:Clone()
			mainCharacter.Archivable = oldArchivable
			
			clone.Name = "DesyncClone" -- Eindeutiger Name zur Sicherheit
			clone.Parent = game.Workspace
			
			local oldctype = game.Workspace.CurrentCamera.CameraType
			game.Workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
			task.wait(0.1) -- Stabiles Timing für Loadstrings
			
			lp.Character = clone
			game.Workspace.CurrentCamera.CameraSubject = clone.Humanoid
			game.Workspace.CurrentCamera.CameraType = oldctype
			clone.Animate.Enabled = false
			clone.Animate.Enabled = true
			
			if mainCharacter and mainCharacter:FindFirstChild("HumanoidRootPart") then
				mainCharacter.HumanoidRootPart.Anchored = true
				createCleanEffect(mainCharacter)
			end

			if not suppressNotification then
				starterGui:SetCore("SendNotification", {
					Title = "Desync State";
					Text = "Desync Enabled!";
					Duration = 2;
				})
			end
			
			table.insert(deathConnections, mainCharacter.Humanoid.Died:Connect(function()
				deactivate()
			end))
			table.insert(deathConnections, clone.Humanoid.Died:Connect(function()
				deactivate()
			end))
		end)
		
		if not success then
			desyncActive = false
		end
	end

	-- Deaktiviert den Desync
	function deactivate(suppressNotification)
		if not desyncActive then return end
		
		pcall(function()
			desyncActive = false
			
			for i, connection in pairs(deathConnections) do
				connection:Disconnect()
			end
			deathConnections = {}
			
			removeEffects()
			
			if mainCharacter and mainCharacter:FindFirstChild("HumanoidRootPart") then
				mainCharacter.HumanoidRootPart.Anchored = false
			end
			
			local currentClone = lp.Character
			if currentClone and currentClone.Name == "DesyncClone" and mainCharacter then
				local targetCFrame = currentClone.HumanoidRootPart.CFrame
				mainCharacter.HumanoidRootPart.CFrame = targetCFrame
				currentClone:Destroy()
			end
			
			local oldctype = game.Workspace.CurrentCamera.CameraType
			game.Workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
			task.wait(0.1) -- Wichtig für Loadstrings, damit Roblox hinterherkommt
			
			lp.Character = mainCharacter
			if mainCharacter and mainCharacter:FindFirstChild("Humanoid") then
				game.Workspace.CurrentCamera.CameraSubject = mainCharacter.Humanoid
			end
			game.Workspace.CurrentCamera.CameraType = oldctype
			if mainCharacter and mainCharacter:FindFirstChild("Animate") then
				mainCharacter.Animate.Enabled = false
				mainCharacter.Animate.Enabled = true
			end

			if not suppressNotification then
				starterGui:SetCore("SendNotification", {
					Title = "Desync State";
					Text = "Desync Disabled!";
					Duration = 2;
				})
			end
		end)
	end

	-- Präzise Wartefunktion
	local function dynamicWait(seconds)
		local steps = seconds / 0.1
		for i = 1, steps do
			if not autoDesyncActive then return false end
			task.wait(0.1)
		end
		return true
	end

	-- Startet die automatischen Loops
	local function startAutoLoop(waitTime)
		autoDesyncActive = true
		currentLoopTime = waitTime
		
		task.spawn(function()
			while autoDesyncActive do
				activate(true)
				if not dynamicWait(currentLoopTime) then break end
				deactivate(true)
				task.wait(0.6) -- Etwas erhöht, um SEH-Crashs im Loadstring komplett zu killen
			end
		end)
	end

	-- Zeigt die Fehlermeldung an
	local function showAlreadyEnabledWarning()
		pcall(function()
			starterGui:SetCore("SendNotification", {
				Title = "Warning!";
				Text = "Desync " .. activeModeName .. " Already Enabled. Disable it First.";
				Duration = 4;
			})
		end)
	end

	-- Hotkey Abfragen
	uis.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		
		-- F1: Normaler Desync
		if input.KeyCode == hotkey then
			if desyncActive then
				if activeModeName == "Normal" then
					activeModeName = "None"
					deactivate(false)
				else
					showAlreadyEnabledWarning()
				end
			else
				activeModeName = "Normal"
				activate(false)
			end
			
		-- F2: 5-Sekunden-Loop
		elseif input.KeyCode == autoHotkey5s then
			if autoDesyncActive and currentLoopTime == 5 then
				autoDesyncActive = false
				activeModeName = "None"
				deactivate(true)
				pcall(function()
					starterGui:SetCore("SendNotification", {
						Title = "Auto Desync";
						Text = "5s Loop Stopped";
						Duration = 3;
					})
				end)
			else
				if desyncActive then
					showAlreadyEnabledWarning()
				else
					activeModeName = "5s Loop"
					pcall(function()
						starterGui:SetCore("SendNotification", {
							Title = "Auto Desync";
							Text = "5s Loop Started";
							Duration = 3;
						})
					end)
					startAutoLoop(5)
				end
			end
			
		-- F3: 2-Sekunden-Loop
		elseif input.KeyCode == autoHotkey2s then
			if autoDesyncActive and currentLoopTime == 2 then
				autoDesyncActive = false
				activeModeName = "None"
				deactivate(true)
				pcall(function()
					starterGui:SetCore("SendNotification", {
						Title = "Auto Desync";
						Text = "2s Loop Stopped";
						Duration = 3;
					})
				end)
			else
				if desyncActive then
					showAlreadyEnabledWarning()
				else
					activeModeName = "2s Loop"
					pcall(function()
						starterGui:SetCore("SendNotification", {
							Title = "Auto Desync";
							Text = "2s Loop Started";
							Duration = 3;
						})
					end)
					startAutoLoop(2)
				end
			end
		end
	end)
end)
