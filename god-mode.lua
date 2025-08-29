-- Services
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Local Player
local player = Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local hum = char:WaitForChild("Humanoid")
local root = char:WaitForChild("HumanoidRootPart")

--------------------------------------------------
-- 無敵処理
--------------------------------------------------
hum:GetPropertyChangedSignal("Health"):Connect(function()
    hum.Health = hum.MaxHealth
end)

hum.Died:Connect(function()
    player:LoadCharacter()
end)

--------------------------------------------------
-- 反射処理
--------------------------------------------------
local DAMAGE_MULTIPLIER = 1.5

local reflectFX = Instance.new("ParticleEmitter")
reflectFX.Texture = "rbxassetid://2415947841"
reflectFX.Lifetime = NumberRange.new(0.2)
reflectFX.Rate = 200
reflectFX.Speed = NumberRange.new(0)
reflectFX.Enabled = false
reflectFX.Parent = root

local function reflectDamage(enemyHum, dmg)
    if enemyHum and enemyHum ~= hum and enemyHum.Health > 0 then
        enemyHum:TakeDamage(dmg * DAMAGE_MULTIPLIER)
        reflectFX.Enabled = true
        task.delay(0.2, function() reflectFX.Enabled = false end)
    end
end

--------------------------------------------------
-- 近接反射
--------------------------------------------------
root.Touched:Connect(function(hit)
    local enemyHum = hit.Parent:FindFirstChild("Humanoid")
    if enemyHum then
        reflectDamage(enemyHum, enemyHum.MaxHealth)
    end
end)

--------------------------------------------------
-- Projectile反射
--------------------------------------------------
CollectionService:GetInstanceAddedSignal("Projectile"):Connect(function(obj)
    if obj:IsA("BasePart") then
        obj.Touched:Connect(function(hit)
            if hit:IsDescendantOf(char) then
                local shooterVal = obj:FindFirstChild("Shooter")
                if shooterVal and shooterVal.Value and shooterVal.Value:FindFirstChild("Humanoid") then
                    reflectDamage(shooterVal.Value.Humanoid, shooterVal.Value.Humanoid.MaxHealth)
                end
                obj:Destroy()
            end
        end)
    end
end)

--------------------------------------------------
-- RemoteEvent反射
--------------------------------------------------
local blacklist = {"UIUpdate","SystemMessage","InventorySync"}

for _,v in pairs(ReplicatedStorage:GetDescendants()) do
    if v:IsA("RemoteEvent") then
        v.OnClientEvent:Connect(function(...)
            if not table.find(blacklist, v.Name) then
                v:FireServer(...)
            end
        end)
    end
end
