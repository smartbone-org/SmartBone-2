"use strict";(self.webpackChunkdocs=self.webpackChunkdocs||[]).push([[496],{41267:e=>{e.exports=JSON.parse('{"functions":[{"name":"ClipVelocity","desc":"Clips velocity on specified vector, Position is where we are at our current physics step (Before we set self.Position)\\r","params":[{"name":"Position","desc":"","lua_type":"Vector3"},{"name":"Vector","desc":"","lua_type":"Vector3"}],"returns":[],"function_type":"method","source":{"line":388,"path":"src/Components/Bone.lua"}},{"name":"PreUpdate","desc":"","params":[{"name":"BoneTree","desc":"","lua_type":"BoneTree"}],"returns":[],"function_type":"method","source":{"line":394,"path":"src/Components/Bone.lua"}},{"name":"StepPhysics","desc":"Force passed in via BoneTree:StepPhysics()\\r","params":[{"name":"BoneTree","desc":"","lua_type":"BoneTree"},{"name":"Force","desc":"","lua_type":"Vector3"},{"name":"Delta","desc":"\u0394t","lua_type":"number"}],"returns":[],"function_type":"method","source":{"line":451,"path":"src/Components/Bone.lua"}},{"name":"Constrain","desc":"","params":[{"name":"BoneTree","desc":"","lua_type":"BoneTree"},{"name":"ColliderObjects","desc":"","lua_type":"Vector3"},{"name":"Delta","desc":"\u0394t","lua_type":"number"}],"returns":[],"function_type":"method","source":{"line":484,"path":"src/Components/Bone.lua"}},{"name":"SkipUpdate","desc":"Returns bone to rest position\\r","params":[],"returns":[],"function_type":"method","source":{"line":538,"path":"src/Components/Bone.lua"}},{"name":"SolveTransform","desc":"Solves the cframe of the bones\\r","params":[{"name":"BoneTree","desc":"","lua_type":"BoneTree"},{"name":"Delta","desc":"\u0394t","lua_type":"number"}],"returns":[],"function_type":"method","source":{"line":553,"path":"src/Components/Bone.lua"}},{"name":"ApplyTransform","desc":"Sets the world cframes of the bones to the calculated world cframe (solved in Bone:SolveTransform())\\r","params":[{"name":"BoneTree","desc":"","lua_type":"BoneTree"}],"returns":[],"function_type":"method","source":{"line":587,"path":"src/Components/Bone.lua"}},{"name":"DrawDebug","desc":"","params":[{"name":"BoneTree","desc":"","lua_type":"any"},{"name":"DRAW_CONTACTS","desc":"","lua_type":"boolean"},{"name":"DRAW_PHYSICAL_BONE","desc":"","lua_type":"boolean"},{"name":"DRAW_BONE","desc":"","lua_type":"boolean"},{"name":"DRAW_AXIS_LIMITS","desc":"","lua_type":"boolean"},{"name":"DRAW_ROTATION_LIMIT","desc":"","lua_type":"boolean"}],"returns":[],"function_type":"method","realm":["Client"],"source":{"line":620,"path":"src/Components/Bone.lua"}},{"name":"DrawOverlay","desc":"","params":[{"name":"Overlay","desc":"","lua_type":"ImOverlay"}],"returns":[],"function_type":"method","realm":["Client"],"source":{"line":811,"path":"src/Components/Bone.lua"}}],"properties":[{"name":"Bone","desc":"","lua_type":"Bone","readonly":true,"source":{"line":236,"path":"src/Components/Bone.lua"}},{"name":"FreeLength","desc":"","lua_type":"number","source":{"line":239,"path":"src/Components/Bone.lua"}},{"name":"Weight","desc":"","lua_type":"number","source":{"line":242,"path":"src/Components/Bone.lua"}},{"name":"ParentIndex","desc":"","lua_type":"number","readonly":true,"source":{"line":246,"path":"src/Components/Bone.lua"}},{"name":"HeirarchyLength","desc":"","lua_type":"number","readonly":true,"source":{"line":250,"path":"src/Components/Bone.lua"}},{"name":"Transform","desc":"","lua_type":"CFrame","source":{"line":253,"path":"src/Components/Bone.lua"}},{"name":"LocalTransform","desc":"","lua_type":"CFrame","source":{"line":256,"path":"src/Components/Bone.lua"}},{"name":"RootPart","desc":"","lua_type":"BasePart","readonly":true,"source":{"line":260,"path":"src/Components/Bone.lua"}},{"name":"RootBone","desc":"","lua_type":"Bone","readonly":true,"source":{"line":264,"path":"src/Components/Bone.lua"}},{"name":"Radius","desc":"","lua_type":"number","source":{"line":267,"path":"src/Components/Bone.lua"}},{"name":"AnimatedWorldCFrame","desc":"Bone.TransformedWorldCFrame\\r","lua_type":"CFrame","readonly":true,"source":{"line":272,"path":"src/Components/Bone.lua"}},{"name":"TransformOffset","desc":"","lua_type":"CFrame","readonly":true,"source":{"line":276,"path":"src/Components/Bone.lua"}},{"name":"LocalTransformOffset","desc":"","lua_type":"CFrame","readonly":true,"source":{"line":280,"path":"src/Components/Bone.lua"}},{"name":"RestPosition","desc":"","lua_type":"Vector3","readonly":true,"source":{"line":284,"path":"src/Components/Bone.lua"}},{"name":"CalculatedWorldCFrame","desc":"","lua_type":"CFrame","readonly":true,"source":{"line":288,"path":"src/Components/Bone.lua"}},{"name":"Position","desc":"Internal representation of the bone\\r","lua_type":"Vector3","source":{"line":292,"path":"src/Components/Bone.lua"}},{"name":"Anchored","desc":"","lua_type":"boolean","source":{"line":295,"path":"src/Components/Bone.lua"}},{"name":"AxisLocked","desc":"XYZ order\\r","lua_type":"{ boolean, boolean, boolean }","source":{"line":299,"path":"src/Components/Bone.lua"}},{"name":"XAxisLimits","desc":"","lua_type":"NumberRange","source":{"line":302,"path":"src/Components/Bone.lua"}},{"name":"YAxisLimits","desc":"","lua_type":"NumberRange","source":{"line":305,"path":"src/Components/Bone.lua"}},{"name":"ZAxisLimits","desc":"","lua_type":"NumberRange","source":{"line":308,"path":"src/Components/Bone.lua"}},{"name":"FirstSkipUpdate","desc":"","lua_type":"boolean","source":{"line":311,"path":"src/Components/Bone.lua"}},{"name":"CollisionHits","desc":"","lua_type":"{}","source":{"line":314,"path":"src/Components/Bone.lua"}},{"name":"CollisionData","desc":"","lua_type":"{}","source":{"line":317,"path":"src/Components/Bone.lua"}}],"types":[],"name":"Bone","desc":"Internal class for all bones\\n:::caution Caution:\\nChanges to the syntax in this class will not count to the major version in semver.\\n:::\\r","source":{"line":232,"path":"src/Components/Bone.lua"}}')}}]);