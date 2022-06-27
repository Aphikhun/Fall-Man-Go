local Def = require "we.def"
local Meta = require "we.gamedata.meta.meta"
local IWorld = require "we.engine.engine_world"

local serializer = {
	["Vector3"] = function(val)
		return string.format("x:%s y:%s z:%s", val.x, val.y, val.z or 1.0)
	end,

	["Vector2"] = function(val)
		return string.format("x:%s y:%s", val.x, val.y)
	end,

	["Color"] = function(val)
		return string.format("r:%s g:%s b:%s a:%s", val.r/255, val.g/255, val.b/255, val.a/255)
	end,

	["PartTexture"] = function(val)
		if string.sub(val, -4) ~= ".tga" then
			val = val .. ".tga"
		end
		return val
	end
}

local deserializer = {
	["Vector3"] = function(str)
		if not str then
			return
		end
		local x, y, z = string.match(str, "x:(.+) y:(.+) z:(.+)")

		return { x = tonumber(x), y = tonumber(y), z = tonumber(z) }
	end,

	["Vector2"] = function(str)
		if not str then
			return
		end
		local x, y = string.match(str, "x:(.+) y:(.+)")

		return { x = tonumber(x), y = tonumber(y)}
	end,

	["Color"] = function(str)
		if not str then
			return
		end
		local function transform(number)
			local value = tonumber(number) * 255
			if value ~= 0 then
				value = math.ceil(value)
			end
			return value
		end
		local r, g, b, a = string.match(str, "r:([^ ]+) g:([^ ]+) b:([^ ]+)(.*)")
		if a ~= "" then
			a = transform(string.match(a, " a:([^ ]+)"))
		else
			a = nil
		end
		return { r = transform(r), g = transform(g), b = transform(b), a = a}
	end,

	["PartTexture"] = function(str)
		if not str then
			return
		end
		if string.sub(str, -4) ~= ".tga" then
			str = str .. ".tga"
		end
		return str
	end,

	["Bool"] = function(str)
		if not str then
			return
		end
		local value = str == "true" and true or false
		return value
	end
}

local function seri_prop(type, val)
	if not val then
		return nil
	end

	local proc = serializer[type]
	assert(proc, string.format("property [%s] is not support", type))

	return proc(val)
end

local function deseri_prop(type, str)
	local proc = deserializer[type]
	assert(proc, string.format("property [%s] is not support", type))

	return proc(str)
end


local class_prop_processor
class_prop_processor = {
	["Instance"] = {
		export = function(properties, val, ...)
			properties["name"] = val.name
			properties["id"] = val.id ~= "" and tostring(val.id) or nil
		end,

		import = function(val, properties, ...)
			val.id = properties["id"]
			val.name = properties["name"]
		end
	},

	["Folder"] = {
		export = function(properties, val, ...)
			class_prop_processor["Instance"].export(properties, val, ...)

			properties["isDataSet"] = tostring(val.isDataSet)
		end,

		import = function(val, properties, ...)
			class_prop_processor["Instance"].import(val, properties, ...)

			val.isDataSet = deseri_prop("Bool", properties["isDataSet"])
		end,
	},

	["MovableNode"] = {
		export = function(properties, val, ...)
			class_prop_processor["Instance"].export(properties, val, ...)

			properties["position"] = seri_prop("Vector3", val.position)
			properties["rotation"] = seri_prop("Vector3", val.rotation)
			if val.class ~= "Model" then
				properties["originSize"] = seri_prop("Vector3", val.originSize)
				properties["scale"] = seri_prop("Vector3", val.scale)
			end
			properties["selectable"] = tostring(val.selectable)
			properties["needSync"] = tostring(val.needSync)
			properties["batchType"] = tostring(val.batchType)
		end,

		import = function(val, properties, ...)
			class_prop_processor["Instance"].import(val, properties, ...)
			val.position = deseri_prop("Vector3", properties["position"])
			val.rotation = deseri_prop("Vector3", properties["rotation"])
			val.scale = deseri_prop("Vector3", properties["scale"])
			val.originSize = deseri_prop("Vector3", properties["originSize"])
			if not val.originSize then
				local sz = properties["size"]
				if sz then
					val.size = deseri_prop("Vector3",sz)
					val.originSize = {x = val.size.x / val.scale.x, y = val.size.y / val.scale.y, z = val.size.z / val.scale.z }
				else
					val.size = val.scale
					val.originSize = {x = 1,y = 1,z = 1}
				end
			else
				val.size = {x=val.originSize.x*val.scale.x, y=val.originSize.y*val.scale.y, z=val.originSize.z*val.scale.z }
			end 
			val.selectable = deseri_prop("Bool", properties["selectable"])
			val.needSync = deseri_prop("Bool", properties["needSync"])
			val.batchType = properties["batchType"]
		end
	},

	["VoxelTerrain"] = {
		export = function(properties, val, ...)
			class_prop_processor["Instance"].export(properties, val, ...)
			properties["uniqueKey"] = tostring(val.uniqueKey)
		end,

		import = function(val, properties, ...)
			class_prop_processor["Instance"].import(val, properties, ...)

			val.uniqueKey = properties["uniqueKey"]
		end
	},

	["Decal"] = {
		export = function(properties, val, ...)
			class_prop_processor["Instance"].export(properties, val, ...)

			properties["decalOffset"] = seri_prop("Vector3", val.decalOffset)
			properties["decalColor"] = seri_prop("Color", val.decalColor)
			properties["decalAlpha"] = tostring(val.decalAlpha)
			properties["decalSurface"] = tostring(val.decalSurface)
			properties["decalImageType"] = tostring(val.decalImageType)
			properties["decalTiling"] = seri_prop("Vector3", val.decalTiling)
			properties["decalTexture"] = tostring(val.decalTexture["asset"])
		end,

		import = function(val, properties, ...)
			class_prop_processor["Instance"].import(val, properties, ...)

			val.decalOffset = deseri_prop("Vector3", properties["decalOffset"])
			val.decalColor = deseri_prop("Color", properties["decalColor"])
			val.decalAlpha = tonumber(properties["decalAlpha"])
			val.decalSurface = properties["decalSurface"]
			val.decalImageType = properties["decalImageType"]
			val.decalTiling = deseri_prop("Vector3", properties["decalTiling"])
			val.decalTexture = {asset = properties["decalTexture"]}
		end
	},

	["EffectPart"] = {
		export = function(properties, val, ...)
			class_prop_processor["MovableNode"].export(properties, val, ...)
			properties["visible"] = tostring(val.csgShapeVisible)
			properties["effectFilePath"] = val["csgShapeEffect"]["asset"]
			-- properties["position"] = seri_prop("Vector3", val.transform.pos) 构造时候使用世界坐标
			-- properties["rotation"] = seri_prop("Vector3", val.transform.rotate) 
			-- properties["scale"] = seri_prop("Vector3", val.scale)

			-- 因为引擎设计不愿意多存一个字节，所以只能兼容处理
			if val.loop.enable then
				properties["loopCount"] = tostring(-val.loop.play_times)
			else
				properties["loopCount"] = tostring(val.loop.play_times)
			end

			properties["loopInterval"] = tostring(val.loop.interval)
			properties["loopReset"] = tostring(val.loop.reset)
			
		end,

		import = function(val, properties, ...)
			class_prop_processor["MovableNode"].import(val, properties, ...)

			val.csgShapeVisible = deseri_prop("Bool", properties["visible"])
			val["csgShapeEffect"] = {asset = properties["effectFilePath"]}
			val.transform = {}
			val.transform.pos = deseri_prop("Vector3", properties["localPosition"])
			val.transform.rotate = deseri_prop("Vector3", properties["localRotation"])

			val.loop = {}
			local loop_count = tonumber(properties["loopCount"]) 
			if 0 > loop_count then
				val.loop.enable = true
				val.loop.play_times = -loop_count
			else
				val.loop.enable = false
				val.loop.play_times = loop_count
			end
			val.loop.interval = tonumber(properties["loopInterval"])
			val.loop.reset =  deseri_prop("Bool", properties["loopReset"])
		end
	},

	["AudioNode"] = {
		export = function(properties, val, ...)
			class_prop_processor["MovableNode"].export(properties, val, ...)

			properties["audioFilePath"] = val["sound"]["asset"]

			properties["autoState"] = tostring(val.autoState)
			properties["loopState"] = tostring(val.loopState)
			properties["multiPly"] = tostring(val.playRate)
			properties["losslessDistance"] = tostring(val.losslessDistance)
			properties["maxDistance"] = tostring(val.maxDistance)
			properties["attenuationType"] = tostring(val.attenuationType)
			properties["volume"] = tostring(val.volume)
		end,

		import = function(val, properties, ...)
			class_prop_processor["MovableNode"].import(val, properties, ...)

			val["sound"] = {asset = properties["audioFilePath"]}

			val.relative_pos = deseri_prop("Vector3", properties["localPosition"])

			val.autoState =  deseri_prop("Bool", properties["autoState"])
			val.loopState =  deseri_prop("Bool", properties["loopState"])
			val.playRate = tonumber(properties["multiPly"])
			val.losslessDistance = tonumber(properties["losslessDistance"])
			val.maxDistance = tonumber(properties["maxDistance"])
			val.attenuationType = tonumber(properties["attenuationType"])
			val.volume = tonumber(properties["volume"])
		end
	},
	
	["SceneUI"] = {
		export = function(properties, val, ...)
			class_prop_processor["Instance"].export(properties, val, ...)
			local file = val.layoutFile["asset"]
			local layoutFile = string.sub(file,7,string.len(file))

			properties["uiID"] = val.uiID ~= "" and tostring(val.id) or nil
			properties["isTop"] = tostring(val.isTop)
			properties["isFaceCamera"] = tostring(val.isFaceCamera)
			properties["position"] = seri_prop("Vector3", val.position)
			properties["rotation"] = seri_prop("Vector3", val.rotation)
			properties["size"] = seri_prop("Vector2", val.size)
			properties["rangeDistance"] = tostring(val.rangeDistance)
			properties["layoutFile"] = tostring(layoutFile)
			properties["uiScaleMode"] = val.uiScaleMode and "0" or "1"
			properties["stretch"] = tostring(val.stretch)
			properties["isLock"] = tostring(val.isLock)
		end,

		import = function(val, properties, ...)
			class_prop_processor["Instance"].import(val, properties, ...)
			local file = properties["layoutFile"]
			local pre = "asset/"
			local layoutFile = ""
			local path = Lib.combinePath(Def.PATH_GAME_ASSET,file)
			if lfs.attributes(path, "mode") ~= "file" then
				layoutFile = file
			else
				layoutFile = pre..file
			end
			val.uiID = properties["uiID"]
			val.isTop = deseri_prop("Bool", properties["isTop"])
			val.isFaceCamera = deseri_prop("Bool", properties["isFaceCamera"])
			val.position = deseri_prop("Vector3", properties["position"])
			val.rotation = deseri_prop("Vector3", properties["rotation"])
			val.size = deseri_prop("Vector2", properties["size"])
			val.rangeDistance = tonumber(properties["rangeDistance"])
			val.layoutFile = {asset = layoutFile}
			val.uiScaleMode = properties["uiScaleMode"] == "0"
			val.stretch = deseri_prop("Bool", properties["stretch"])
			val.isLock = deseri_prop("Bool", properties["isLock"])
		end
	},

	["Object"] = {
		export = function(properties, val, ...)
			class_prop_processor["MovableNode"].export(properties, val, ...)
		end,

		import = function(val, properties, ...)
			class_prop_processor["MovableNode"].import(val, properties, ...)
		end
	},

	["Entity"] = {
		export = function(properties, val, ...)
			class_prop_processor["Object"].export(properties, val, ...)
		end,

		import = function(val, properties, ...)
			class_prop_processor["Object"].import(val, properties, ...)
		end
	},

	["DropItem"] = {
		export = function(properties, val, ...)
			class_prop_processor["Object"].export(properties, val, ...)
			properties["fixRotation"] = not val.fixRotation
		end,

		import = function(val, properties, ...)
			class_prop_processor["Object"].import(val, properties, ...)
			val.fixRotation = not deseri_prop("Bool", properties["fixRotation"])
		end
	},
	
	["BasePart"] = {
		export = function(properties, val, ...)
			class_prop_processor["MovableNode"].export(properties, val, ...)

			properties["density"] = tostring(val.density)
			properties["collisionUniqueKey"] = tostring(val.collisionUniqueKey)
			properties["restitution"] = tostring(val.restitution)
			properties["friction"] = tostring(val.friction)
			properties["lineVelocity"] = seri_prop("Vector3", val.lineVelocity)
			properties["angleVelocity"] = seri_prop("Vector3", val.angleVelocity)
			properties["useAnchor"] = tostring(val.useAnchor)
			properties["partNavMeshType"] = tostring(val.partNavMeshType)
			properties["useGravity"] = tostring(val.useGravity)
			properties["useCollide"] = tostring(val.useCollide)
			properties["staticObject"] = tostring(val.staticObject)
			properties["cameraCollideEnable"] = tostring(val.cameraCollideEnable)

			--test staticBatchNo
			if val.staticBatchNo then
				properties["staticBatchNo"] = tostring(val.staticBatchNo)
			end
			--if val.enableStaticBatching then
			--	properties["staticBatchNo"] = tostring(val.staticBatchNo)
			--else
			--	properties["staticBatchNo"] = ""
			--end
		end,

		import = function(val, properties, ...)
			class_prop_processor["MovableNode"].import(val, properties, ...)
			
			val.density = tonumber(properties["density"])
			val.collisionUniqueKey = properties["collisionUniqueKey"]
			val.restitution = tonumber(properties["restitution"])
			val.friction = tonumber(properties["friction"])
			val.lineVelocity = deseri_prop("Vector3", properties["lineVelocity"])
			val.angleVelocity = deseri_prop("Vector3", properties["angleVelocity"])
			val.useAnchor = deseri_prop("Bool", properties["useAnchor"])
			val.partNavMeshType =  tostring(properties["partNavMeshType"])
			val.useGravity = deseri_prop("Bool", properties["useGravity"])
			val.useCollide = deseri_prop("Bool", properties["useCollide"])
			val.staticObject = deseri_prop("Bool", properties["staticObject"])
			val.cameraCollideEnable = deseri_prop("Bool", properties["cameraCollideEnable"])
			if(properties["staticBatchNo"]) then
				val.staticBatchNo = properties["staticBatchNo"]
				val.enableStaticBatching = 0 < #val.staticBatchNo
			else
				val.staticBatchNo = nil
				val.enableStaticBatching = false
			end

		end
	},

	["CSGShape"] = {
		export = function(properties, val, ...)
			class_prop_processor["BasePart"].export(properties, val, ...)

			properties["isLockedInEditor"] = tostring(val.isLockedInEditor)
			properties["isVisibleInEditor"] = tostring(val.isVisibleInEditor)
			properties["mass"] = tostring(val.mass)
			properties["materialColor"] = seri_prop("Color", val["material"]["color"])
			properties["materialTexture"] = seri_prop("PartTexture", val["material"]["texture"])
			properties["materialOffset"] = seri_prop("Vector3", val["material"]["offset"])
			properties["materialAlpha"] = tostring(val["material"]["alpha"])
			properties["useTextureAlpha"] = tostring(val["material"]["useTextureAlpha"])
			properties["discardAlpha"] = tostring(val["material"]["discardAlpha"])
			properties["booleanOperation"] = tostring(val.booleanOperation)
			properties["customThreshold"] = tostring(val.customThreshold)
			properties["bloom"] = tostring(val.bloom)
			properties["collisionFidelity"] = val.collisionFidelity
		end,

		import = function(val, properties, ...)
			class_prop_processor["BasePart"].import(val, properties, ...)

			val.isLockedInEditor = deseri_prop("Bool", properties["isLockedInEditor"])
			val.isVisibleInEditor = deseri_prop("Bool", properties["isVisibleInEditor"])
			val.isVisibleInTree =  deseri_prop("Bool", properties["isVisibleInTree"])
			val.mass = tonumber(properties["mass"])
			val["material"] = {}
			val["material"]["color"] = deseri_prop("Color", properties["materialColor"])
			val["material"]["texture"] = deseri_prop("PartTexture", properties["materialTexture"])
			val["material"]["offset"] = deseri_prop("Vector3", properties["materialOffset"])
			val["material"]["alpha"] = tonumber(properties["materialAlpha"])	                                  
			val["material"]["useTextureAlpha"] = tonumber(properties["useTextureAlpha"])
			val["material"]["discardAlpha"] = tonumber(properties["discardAlpha"])
			val.booleanOperation = tonumber(properties["booleanOperation"])
			val.customThreshold = tonumber(properties["customThreshold"])
			val.bloom = deseri_prop("Bool", properties["bloom"])
			val.collisionFidelity = properties["collisionFidelity"]
		end
	},
	
	["MeshPart"] = {
		export = function(properties, val, ...)
			class_prop_processor["CSGShape"].export(properties, val, ...)
			properties["mesh"] = tostring(val.mesh)
			properties["metalness"] = tostring(val.metalness)
			properties["roughness"] = tostring(val.roughness)
			properties["autoAnchor"] = tostring(val.autoAnchor)
			properties["btsKey"] = tostring(val.btsKey)
		end,

		import = function(val, properties, ...)
			class_prop_processor["CSGShape"].import(val, properties, ...)
			val.mesh = properties["mesh"]
			val.metalness = tonumber(properties["metalness"])
			val.roughness = tonumber(properties["roughness"])
			val.autoAnchor = deseri_prop("Bool", properties["autoAnchor"])
			val.mesh_selector = {}
			val.mesh_selector.asset = properties["mesh"]
			val.mesh_selector.selector = properties["mesh"]
			val.btsKey = properties["btsKey"]
		end
	},

	["RegionPart"] = {
		export = function(properties, val, ...)
			class_prop_processor["MovableNode"].export(properties, val, ...)

			properties["cfgName"] = val.cfgName
		end,

		import = function(val, properties, ...)
			class_prop_processor["MovableNode"].import(val, properties, ...)

			val.cfgName = properties["cfgName"]
		end
	},


	["Part"] = {
		export = function(properties, val, ...)
			class_prop_processor["CSGShape"].export(properties, val, ...)

			properties["shape"] = val.shape
			properties["btsKey"] = val.btsKey
		end,

		import = function(val, properties, ...)
			class_prop_processor["CSGShape"].import(val, properties, ...)

			val.shape = properties["shape"]
			val.btsKey = properties["btsKey"]
		end
	},

	["PartOperation"] = {
		export = function(properties, val, ...)
			class_prop_processor["CSGShape"].export(properties, val, ...)
	
			properties["useOriginalColor"] = tostring(val.useOriginalColor)
			properties["mergeShapesDataKey"] = (val.mergeShapesDataKey)
			properties["btsKey"] = tostring(val.btsKey)
		end,
	
		import = function(val, properties, ...)
			class_prop_processor["CSGShape"].import(val, properties, ...)
	
			val.useOriginalColor = deseri_prop("Bool", properties["useOriginalColor"])
			val.mergeShapesDataKey = (properties["mergeShapesDataKey"])
			val.btsKey = properties["btsKey"]
		end
	  },

	["Force"] = {
		export = function(properties, val, ...)
			class_prop_processor["Instance"].export(properties, val, ...)

			properties["useRelativeForce"] = tostring(val.useRelativeForce)
			properties["force"] = seri_prop("Vector3", val["force"])
		end,

		import = function(val, properties, ...)
			class_prop_processor["Instance"].import(val, properties, ...)

			val.useRelativeForce =  deseri_prop("Bool", properties["useRelativeForce"])
			val.force = deseri_prop("Vector3", properties["force"])
		end
	},

	["Torque"] = {
		export = function(properties, val, ...)
			class_prop_processor["Instance"].export(properties, val, ...)

			properties["useRelativeTorque"] = tostring(val.useRelativeTorque)
			properties["torque"] = seri_prop("Vector3", val["torque"])
		end,

		import = function(val, properties, ...)
			class_prop_processor["Instance"].import(val, properties, ...)
			
			val.useRelativeTorque =  deseri_prop("Bool", properties["useRelativeTorque"])
			val.torque = deseri_prop("Vector3", properties["torque"])
		end
	},

	["ConstraintBase"] = {
		export = function(properties, val, ...)
			class_prop_processor["Instance"].export(properties, val, ...)

			properties["slavePartID"] = val.slavePartID
			properties["slaveLocalPos"] = seri_prop("Vector3",val.slaveLocalPos)
			properties["masterLocalPos"] = seri_prop("Vector3",val.masterLocalPos)
			properties["collision"] = tostring(val.collision)
		end,

		import = function(val, properties, ...)
			class_prop_processor["Instance"].import(val, properties, ...)

			val.slavePartID = properties["slavePartID"]
			val.slaveLocalPos = deseri_prop("Vector3", properties["slaveLocalPos"])
			val.masterLocalPos = deseri_prop("Vector3", properties["masterLocalPos"])
			val.collision =  deseri_prop("Bool", properties["collision"])
		end

	},

	["FixedConstraint"] = {
		export = function(properties, val, ...)
			class_prop_processor["ConstraintBase"].export(properties, val, ...)
		end,

		import = function(val, properties, ...)
			class_prop_processor["ConstraintBase"].import(val, properties, ...)
		end
	},

	["HingeConstraint"] = {
		export = function(properties, val, ...)
			class_prop_processor["ConstraintBase"].export(properties, val, ...)

			properties["visible"] = tostring(val.visible)
			properties["useSpring"] = tostring(val.useSpring)
			properties["stiffness"] = tostring(val.stiffness)
			properties["damping"] = tostring(val.damping)
			properties["springTargetAngle"] = tostring(val.springTargetAngle)
			properties["useMotor"] = tostring(val.useMotor)
			properties["motorTargetAngleVelocity"] = tostring(val.motorTargetAngleVelocity)
			properties["motorForce"] = tostring(val.motorForce)
			properties["useAngleLimit"] = tostring(val.useAngleLimit)
			properties["angleUpperLimit"] = tostring(val.angleUpperLimit)
			properties["angleLowerLimit"] = tostring(val.angleLowerLimit)
		end,

		import = function(val, properties, ...)
			class_prop_processor["ConstraintBase"].import(val, properties, ...)
			
			val.useSpring =  deseri_prop("Bool", properties["useSpring"])
			val.stiffness = tonumber(properties["stiffness"])
			val.damping = tonumber(properties["damping"])
			val.springTargetAngle = tonumber(properties["springTargetAngle"])
			val.useMotor =  deseri_prop("Bool", properties["useMotor"])
			val.motorTargetAngleVelocity = tonumber(properties["motorTargetAngleVelocity"])
			val.motorForce = tonumber(properties["motorForce"])
			val.visible =  deseri_prop("Bool", properties["visible"])
			val.useAngleLimit =  deseri_prop("Bool", properties["useAngleLimit"])
			val.angleUpperLimit =  tonumber(properties["angleUpperLimit"])
			val.angleLowerLimit =  tonumber(properties["angleLowerLimit"])
		end
	},

	["RodConstraint"] = {
		export = function(properties, val, ...)
			class_prop_processor["ConstraintBase"].export(properties, val, ...)

			properties["radius"] = tonumber(tostring(val.radius))
			properties["length"] = tonumber(tostring(val.length))
			properties["visible"] = tostring(val.visible)
			properties["fixedJustify"] = tostring(val.fixedJustify)
			properties["color"] = seri_prop("Color", val.color)
		end,

		import = function(val, properties, ...)
			class_prop_processor["ConstraintBase"].import(val, properties, ...)

			val.radius = properties["radius"]
			val.length = properties["length"]
			val.visible =  deseri_prop("Bool", properties["visible"])
			val.fixedJustify =  deseri_prop("Bool", properties["fixedJustify"])
			val.color = deseri_prop("Color", properties["color"])
		end
	},

	["SpringConstraint"] = {
		export = function(properties, val, ...)
			class_prop_processor["ConstraintBase"].export(properties, val, ...)

			properties["radius"] = tostring(val.radius)
			properties["length"] = tostring(val.length)
			properties["visible"] = tostring(val.visible)
			properties["fixedJustify"] = tostring(val.fixedJustify)
			properties["thickness"] = tostring(val.thickness)
			properties["coil"] = tostring(val.coil)
			properties["color"] = seri_prop("Color", val.color)
			properties["stiffness"] = tostring(val.stiffness)
			properties["damping"] = tostring(val.damping)
		end,

		import = function(val, properties, ...)
			class_prop_processor["ConstraintBase"].import(val, properties, ...)

			val.radius = tonumber(properties["radius"])
			val.length = tonumber(properties["length"])
			val.visible =  deseri_prop("Bool", properties["visible"])
			val.fixedJustify =  deseri_prop("Bool", properties["fixedJustify"])
			val.thickness = tonumber(properties["thickness"])
			val.coil = tonumber(properties["coil"])
			val.color = deseri_prop("Color", properties["color"])
			val.stiffness = tonumber(properties["stiffness"])
			val.damping = tonumber(properties["damping"])
		end
	},

	["RopeConstraint"] = {
		export = function(properties, val, ...)
			class_prop_processor["ConstraintBase"].export(properties, val, ...)

			properties["radius"] = tostring(val.radius)
			properties["length"] = tostring(val.length)
			properties["visible"] = tostring(val.visible)
			properties["color"] = seri_prop("Color", val.color)
		end,

		import = function(val, properties, ...)
			class_prop_processor["ConstraintBase"].import(val, properties, ...)

			val.radius = tonumber(properties["radius"])
			val.length = tonumber(properties["length"])
			val.visible = deseri_prop("Bool", properties["visible"])
			val.color = deseri_prop("Color", properties["color"])
		end
	},

	["SliderConstraint"] = {
		export = function(properties, val, ...)
			class_prop_processor["ConstraintBase"].export(properties, val, ...)

			properties["visible"] = tostring(val.visible)
			properties["upperLimit"] = tostring(val.upperLimit)
			properties["lowerLimit"] = tostring(val.lowerLimit)
		end,

		import = function(val, properties, ...)
			class_prop_processor["ConstraintBase"].import(val, properties, ...)

			val.visible = deseri_prop("Bool", properties["visible"])
			val.upperLimit = tonumber(properties["upperLimit"])
			val.lowerLimit = tonumber(properties["lowerLimit"])
		end
	},

	["Model"] = {
		export = function(properties, val, ...)
			class_prop_processor["MovableNode"].export(properties, val, ...)
		end,

		import = function(val, properties, ...)
			class_prop_processor["MovableNode"].import(val, properties, ...)
		end
	},

	["Light"] = {
		export = function(properties, val, ...)
			class_prop_processor["MovableNode"].export(properties, val, ...)
			properties["lightType"] = tostring(val.lightType)
			properties["skyColor"] = seri_prop("Color",val.skyColor)
			properties["skyLineColor"] = seri_prop("Color",val.skyLineColor)
			properties["lightColor"] = seri_prop("Color",val.lightColor)
			properties["lightBrightness"] = tostring(val.lightBrightness)
			properties["lightRange"] = tostring(val.lightRange)
			properties["lightAngle"] = tostring(val.lightAngle)
			properties["lightLength"] = tostring(val.lightLength)
			properties["lightWidth"] = tostring(val.lightWidth)
			properties["lightActived"] = tostring(val.lightActived)
			properties["ID"] = tostring(val.ID)
			properties["shadowsType"] = tostring(val.shadows.shadowsType)
			properties["shadowsIntensity"] = tostring(val.shadows.shadowsIntensity)
			properties["shadowsOffset"] = tostring(val.shadows.shadowsOffset)
			properties["shadowsPresicion"] = tostring(val.shadows.shadowsPresicion)
			properties["shadowsDistance"] = tostring(val.shadows.shadowsDistance)
		end,

		import = function(val, properties, ...)
			class_prop_processor["MovableNode"].import(val, properties, ...)
			val.lightType = properties["lightType"]
			val.skyColor = deseri_prop("Color",properties["skyColor"])
			val.skyLineColor = deseri_prop("Color",properties["skyLineColor"])
			val.lightColor = deseri_prop("Color",properties["lightColor"])
			val.lightBrightness = tonumber(properties["lightBrightness"])
			val.lightRange = tonumber(properties["lightRange"])
			val.lightAngle = tonumber(properties["lightAngle"])
			val.lightLength = tonumber(properties["lightLength"])
			val.lightWidth = tonumber(properties["lightWidth"])
			val.ID = tonumber(properties["ID"])
			val.lightActived = deseri_prop("Bool",properties["lightActived"])
			local shadows = {}
			shadows.shadowsType = properties["shadowsType"]
			shadows.shadowsIntensity = tonumber(properties["shadowsIntensity"])
			shadows.shadowsOffset = tonumber(properties["shadowsOffset"])
			shadows.shadowsPresicion = properties["shadowsPresicion"]
			shadows.shadowsDistance = tonumber(properties["shadowsDistance"])
			val.shadows = shadows
		end
	},
}

local extern = {}	-- [class] = {export = {}, import = {}}}

for class, v in pairs(class_prop_processor) do
	local export = v.export
	local import = v.import

	v.export = function(properties, val, customProperties)
		export(properties, val, customProperties)

		-- extern
		local funcs = extern[class] and extern[class].export
		for _, func in ipairs(funcs or {}) do
			func(customProperties, val)
		end
	end

	v.import = function(val, properties, customProperties)
		import(val, properties, customProperties)

		-- extern
		local funcs = extern[class] and extern[class].import
		for _, func in ipairs(funcs or {}) do
			func(val, customProperties)
		end
	end
end

local function export_inst(val, exclude_children)
	local ret = {
		["class"] = val.class,
		["config"] = val.config,
		["properties"] = {},
		["customProperties"] = {}
	}
	local properties = ret.properties
	local processor = assert(class_prop_processor[val.class].export, val.class)
	processor(properties, val, ret.customProperties)

	if val.AddCustom then
		ret["attributes"] = {}
		for _,attr in pairs(val.AddCustom.attrs) do
			local obj_type = attr.val["__OBJ_TYPE"]
			if (obj_type == "T_String") then
				ret.attributes[attr.key] = tostring(attr.val.rawval)
			elseif(obj_type == "T_Bool") then
				ret.attributes[attr.key] = tostring(attr.val.rawval)
			elseif(obj_type == "T_Double") then
				ret.attributes[attr.key] = tostring(attr.val.rawval)
			elseif(obj_type == "T_Int") then
				ret.attributes[attr.key] = tostring(attr.val.rawval)
			elseif(obj_type == "T_Vector2") then
				ret.attributes[attr.key] = seri_prop("Vector2",attr.val.rawval)
			elseif(obj_type == "T_Vector3") then
				ret.attributes[attr.key] = seri_prop("Vector3",attr.val.rawval)
			elseif(obj_type == "T_Time") then
				ret.attributes[attr.key] = tostring(attr.val.rawval.value)
			elseif(obj_type == "T_Percentage") then
				ret.attributes[attr.key] = tostring(attr.val.rawval.value)
			elseif(obj_type == "T_Color") then
				ret.attributes[attr.key] = seri_prop("Color",attr.val.rawval)
			end
		end
	end

	if next(val.children) and not exclude_children then
		ret.children = {}
		for _, child in ipairs(val.children) do
			table.insert(ret.children, export_inst(child))
		end
	end

	local inst = IWorld:get_instance(math.tointeger(val.id))
	if inst then
		local name = next(ret.properties)
		repeat
			if not name then
				break
			end
			if not inst:isPropertyDirty(name) then
				ret.properties[name] = nil
			end
			name = next(ret.properties, name)
		until(false)
	end

	return ret
end

local function import_inst(item)
	local class = assert(item.class)
	local type = string.format("Instance_%s", class)
	assert(Meta:meta(type), type)

	local ret = {
		[Def.OBJ_TYPE_MEMBER] = type,
		class = class,
		children = {},
		config = item.config
	}

	if class == "PartOperation" then
		local key = item.properties.mergeShapesDataKey
		local path = Lib.combinePath(Def.PATH_MERGESHAPESDATA, string.format("%s.json",key))
		local data = Lib.read_json_file(path)
		
		if nil ~= data and nil ~= data.basicShapesData then
			for _,child in ipairs(data.basicShapesData) do
				table.insert(ret.children, import_inst(child))
			end
		end
	end

	-- properties
	local processor = assert(class_prop_processor[class].import, class)
	processor(ret, item.properties, item.customProperties or {})

	-- attributes
	local attributes22 = item.attributes
	if attributes22 then
		ret.AddCustom = {}
		ret.AddCustom.attrs = {}
		for k,v in pairs(attributes22) do
			ret.AddCustom.attrs["key"] = tostring(k)
			ret.AddCustom.attrs["val"] = {
				__OBJ_TYPE = "T_String",
				rawval = {value = tostring(v)}
			}
		end
	end

	-- children
	if item.children then
		for _, child in ipairs(item.children) do
			table.insert(ret.children, import_inst(child))
		end
	end

	return ret
end

local function calc_min_pos(pos, size, side)
	local Direction = {
		NONE = 0, UP = 1, DOWN = 2, LEFT = 3, RIGHT = 4, FRONT = 5, BACK = 6
	}

	local function CalcPositionRelations(side)
		if side.x ~= 0 then
			return side.x > 0 and Direction.LEFT or Direction.RIGHT
		end
		if side.y ~= 0 then
			return side.y > 0 and Direction.DOWN or Direction.UP
		end
		if side.z ~= 0 then
			return side.z > 0 and Direction.BACK or Direction.FRONT
		end
		return Direction.NONE
	end

    local box_x, box_y, box_z = size.x, size.y, size.z
    if box_x == 1 and box_y == 1 and box_z == 1 then
        return pos
    end
    local dir = CalcPositionRelations(side)
    local minPosition = {}
    minPosition.x = pos.x
    minPosition.y = pos.y
    minPosition.z = pos.z
    if dir == Direction.UP or dir == Direction.DOWN then
        --  ???  x ??  z
        minPosition.x = pos.x - (box_x == 2 and 0 or math.floor(box_x / 2))
        minPosition.z = pos.z - (box_z == 2 and 0 or math.floor(box_z / 2))
        if dir == Direction.UP then
            minPosition.y = minPosition.y - box_y + 1
        end
    elseif dir == Direction.LEFT or dir == Direction.RIGHT then
        --  ???  z ??  y
        minPosition.y = pos.y - (box_y == 2 and 0 or math.floor(box_y / 2))
        minPosition.z = pos.z - (box_z == 2 and 0 or math.floor(box_z / 2))
        if dir == Direction.RIGHT then
            minPosition.x = minPosition.x - box_x + 1
        end
    elseif dir == Direction.FRONT or dir == Direction.BACK then
        --??? x  y
        minPosition.x = pos.x - (box_x == 2 and 0 or math.floor(box_x / 2))
        minPosition.y = pos.y - (box_y == 2 and 0 or math.floor(box_y / 2))
        if dir == Direction.FRONT then
            minPosition.z = minPosition.z - box_z + 1
        end
    end
    return minPosition
end

local function inject(class, export, import)
	extern[class] = extern[class] or { export = {}, import = {}}
	table.insert(extern[class].export, export)
	table.insert(extern[class].import, import)
end

local function raw_check_inst(list_inst)
	local list_check_obj = {}
	if list_inst then
		for _,val in ipairs(list_inst) do
			if val.properties then
				list_check_obj[val.properties.id] = val
			end
		end
	end
	return function(obj)
		local op = obj.properties 
		if op then
			local mt = list_check_obj[op.id]
			if mt then
				for k,v in pairs(mt.properties) do
					if not op[k] then
						obj.properties[k] = v
					end
				end
			end
		end
		return obj
	end
end

return {
	import_inst = import_inst,
	export_inst = export_inst,

	deseri_prop = deseri_prop,
	seri_prop = seri_prop,

	calc_min_pos = calc_min_pos,
	raw_check_inst = raw_check_inst,
	inject = inject
}
