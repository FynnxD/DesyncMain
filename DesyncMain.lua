--[[
	WARNING: Heads up! This script has not been verified by ScriptBlox. Use at your own risk!
]]
local hotkey = _G.desyncHotkey or Enum.KeyCode.F1

local uis = game:GetService("UserInputService")
local lp = game.Players.LocalPlayer
local starterGui = game:GetService("StarterGui") -- Wird für die Notification benötigt
local desyncActive = false
local mainCharacter = nil
local deathConnections = {}
local activeEffects = {}

-- NEU: Roblox Notification beim Ausführen des Scripts
starterGui:SetCore("SendNotification", {
	Title = "Script Loaded!";
	Text = "Press F1 for Desync\nMade BY fynn_xD";
	Duration = 5; -- Bleibt für 5 Sekunden sichtbar
})

-- Hilfsfunktion zum Erstellen des cleanen Outline- und White-Effects
local function createCleanEffect(targetCharacter)
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
end

-- Hilfsfunktion zum kompletten Entfernen der Effekte
local function removeEffects()
	for _, effect in pairs(activeEffects) do
		if typeof(effect) == "Instance" then
			effect:Destroy()
		elseif type(effect) == "table" and effect.Part and effect.Part.Parent then
			effect.Part.Material = effect.Material
			effect.Part.Color = effect.Color
		end
	end
	activeEffects = {}
end

function deactivate()
	desyncActive = false
	
	for i, connection in pairs(deathConnections) do
		connection:Disconnect()
		table.remove(deathConnections, i)
	end
	
	removeEffects()
	
	if mainCharacter and mainCharacter:FindFirstChild("HumanoidRootPart") then
		mainCharacter.HumanoidRootPart.Anchored = false
	end
	
	mainCharacter.HumanoidRootPart.CFrame = lp.Character.HumanoidRootPart.CFrame
	lp.Character:Destroy()
	local oldctype = game.Workspace.CurrentCamera.CameraType
	game.Workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
	task.wait()
	lp.Character = mainCharacter
	game.Workspace.CurrentCamera.CameraSubject = mainCharacter.Humanoid
	game.Workspace.CurrentCamera.CameraType = oldctype
	mainCharacter.Animate.Enabled = false
	mainCharacter.Animate.Enabled = true
end


uis.InputBegan:Connect(function(input, gameProcessed)
	if not gameProcessed and input.KeyCode == hotkey then
		if desyncActive then
			deactivate()
		else
			desyncActive = true
			mainCharacter = lp.Character
			local oldArchivable = mainCharacter.Archivable
			mainCharacter.Archivable = true
			local clone = mainCharacter:Clone()
			mainCharacter.Archivable = oldArchivable
			clone.Parent = game.Workspace
			local oldctype = game.Workspace.CurrentCamera.CameraType
			game.Workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
			task.wait()
			lp.Character = clone
			game.Workspace.CurrentCamera.CameraSubject = clone.Humanoid
			game.Workspace.CurrentCamera.CameraType = oldctype
			clone.Animate.Enabled = false
			clone.Animate.Enabled = true
			
			if mainCharacter and mainCharacter:FindFirstChild("HumanoidRootPart") then
				mainCharacter.HumanoidRootPart.Anchored = true
				createCleanEffect(mainCharacter)
			end
			
			table.insert(deathConnections, mainCharacter.Humanoid.Died:Connect(function()
				deactivate()
			end))
			table.insert(deathConnections, clone.Humanoid.Died:Connect(function()
				deactivate()
			end))
		end
	end
end)
