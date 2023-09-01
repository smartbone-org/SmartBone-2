--!nocheck

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BonePhysics = require(ReplicatedStorage:WaitForChild("SmartBone"))

BonePhysics.Start()
