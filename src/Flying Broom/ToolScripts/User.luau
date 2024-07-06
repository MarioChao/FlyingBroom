--!strict

---------- Module ----------
local User: {
    Character: Model?,
    Humanoid: Humanoid?,
    Player: Player?,
    UserLoaded: BindableEvent,
    UserUnloaded: BindableEvent,
} = {}

---------- Services ----------
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

---------- Types ----------
export type UserInfo = {
    Character: Model,
    Humanoid: Humanoid,
    Player: Player
}

---------- Instances ----------
local Tool = script.Parent.Parent

local Camera = workspace.CurrentCamera

---------- Variables ----------
local maxRayDistance = 10000

---------- Module variables ----------
User.UserLoaded = Instance.new("BindableEvent")
User.UserUnloaded = Instance.new("BindableEvent")

---------- Local functions ----------
local function getMousePosition(): Vector3?
    if not RunService:IsClient() then
        warn("getMousePosition() can only be called from the client!")
        return nil
    end

    -- Get viewport position
    local screenLocation = UserInputService:GetMouseLocation()

    -- Get ray
    local unitRay = Camera:ViewportPointToRay(screenLocation.X, screenLocation.Y)

    -- Prepare for raycast
    local raycastParams = RaycastParams.new()
    raycastParams:AddToFilter(User.Character:GetDescendants())
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude

    -- Get world position
    local raycastResult = workspace:Raycast(unitRay.Origin, unitRay.Direction * maxRayDistance, raycastParams)
    local worldPosition = (raycastResult and raycastResult.Position) or (unitRay.Origin + unitRay.Direction * maxRayDistance)

    -- Return position
    return worldPosition
end

local function getUserInfo(): UserInfo
    if not User.Player then
        User.Player = script:FindFirstAncestorWhichIsA("Player")
        User.Character = User.Player and User.Player.Character
        User.Humanoid = User.Character and User.Character:FindFirstChildWhichIsA("Humanoid")
    end
    return {
        Character = User.Character,
        Humanoid = User.Humanoid,
        Player = User.Player,
    }
end

local function onEquipped()
    User.Character = Tool.Parent
    User.Humanoid = User.Character and User.Character:FindFirstChildWhichIsA("Humanoid")
    User.Player = User.Character and Players:GetPlayerFromCharacter(User.Character)
    
    User.UserLoaded:Fire(getUserInfo())
end

local function onUnequipped()
    User.UserUnloaded:Fire(getUserInfo())

    User.Character = nil
    User.Humanoid = nil
    User.Player = nil
end

---------- Calling / connecting functions ----------
Tool.Equipped:Connect(onEquipped)
Tool.Unequipped:Connect(onUnequipped)

---------- Module functions ----------
function User.getMousePosition()
    return getMousePosition()
end

function User.getUserInfo()
    return getUserInfo()
end

function User.isShiftLock()
    return (UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter)
end

---------- Return module ----------
return User
