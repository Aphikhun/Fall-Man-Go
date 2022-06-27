local math_sqrt = math.sqrt
local math_sin = math.sin
local math_cos = math.cos
local math_rad = math.rad

local guiMgr = L("guiMgr", GUIManager:Instance())
local imgMgr = L("imgMgr", CEGUIImageManager:getSingleton())
local winMgr = L("winMgr", CEGUIWindowManager:getSingleton())

local worldCfg = World.cfg
local longTouchTickTime = worldCfg.longTouchTickTime or 5 -- 长按多久触发时间
local cdNumTipTickTime = worldCfg.cdNumTipTickTime or 2 -- 技能数字倒计时的计时间隔
--[[ -- GLOBAL SKILL CONFIG,任何技能的配置都可以通过配上这几个来添加对应的东西(风格类技能配在风格类的配置位置才能起效)
    enableProgressMask -- 是否启用技能进度条
    enableCdMask -- 是否启用技能遮罩
    mainPageSkillDesc -- 是否在主界面技能位置显示技能名称，是的话会将配置的mainPageSkillDesc显示上去
    enableCdTip -- 是否启用cd数字倒计时提示
    horizontalAlignment = 0/1/2 （left/center/right） -- 
    verticalAlignment = 0/1/2 （top/center/bottom） --  
    useTopLineSkillStyle true -- 在全局配置了启用横排技能风格栏的情况下，该技能可以配这个为true，那么该技能就会使用这个风格栏
    useRightSectorSkillStyle true -- 在全局配置了启用右侧弧形技能风格栏的情况下，该技能可以配这个为true，那么该技能就会使用这个风格栏
    icon = true -- 配置这个才会显示图标
    showImage = -- 注意：新UI的技能配置必须这样！比如plugin/myplugin/skill/a/a.png，配置如下
    { image = { name = "a", asset = "plugin/myplugin/skill/a" }, resourceGroup = "gameres" }
    pushImage = 
    { image = { name = "a", asset = "plugin/myplugin/skill/a" }, resourceGroup = "gameres" }

    ----- 特殊配置
    progressShowInEnd -- 如果启用进度条，是否让进度条满的是时候不消失
    touchTimeMax -- 如果启用进度条，那么进度条最大多长时间按满
    skillSize -- 技能半径。 注：该配置仅对零散技能和定制技能起效
    cdTime --
    castInterval -- 点击类技能再长按的时候是否长按时一直触发释放该技能，配这个的话就会一直触发，这个就是间隔
    isTouch --
    castTouchSkill -- 某种特殊技能技能点击触发又能长按触发，此时这个是长按时触发技能(此种技能不能配置isTouch:true)
    castClickSkill -- 某种特殊技能技能点击触发又能长按触发，此时这个是点击时触发技能

    showIndex -- 在配置了使用风格技能栏，比如上面的横排技能/右下角圆形技能时，可以配一个这个来显示这个展示位置
    -----
    -- config相关的default可全局配置，也可技能内配置
    holderConfig = -- 坑位
    {
        image = { name = xx, asset = xx }, 
        resourceGroup = xx
    }
    progressMaskConfig = { -- 技能进度条，默认会创建，具体显示不显示还是根据技能配置
        horizontalAlignment = 0/1/2 （left/center/right） -- 默认 1
        verticalAlignment = 0/1/2 （top/center/bottom） --  默认 1
        image = {
            leftImage = {name = xx, asset = xx}
            rightImage = {name = xx, asset = xx}
            resourceGroup = xx
            scale = xx - xx 默认是1，即原来图片的大小
        }, 
        clockwise = xx -- 顺时针
        progressSize = xx --进度条比技能大多少，默认比技能大10px
    }
    cdMaskConfig = 技能进cd时遮罩显示，默认会创建，具体显示不显示还是根据技能配置
    {
        horizontalAlignment = 0/1/2 （left/center/right） -- 默认 1
        verticalAlignment = 0/1/2 （top/center/bottom） --  默认 1
        image = {
            leftImage = {name = xx, asset = xx}
            rightImage = {name = xx, asset = xx}
            resourceGroup = xx
            scale = xx - xx 默认是1，即原来图片的大小
        }
        clockwise = xx -- 顺时针
        area = {{xx, xx}, {xx, xx}, {xx, xx}, {xx, xx}} -- 一般不填，默认和技能等大
    }
    mainPageSkillDescConfig = 技能描述/名字，默认会创建，具体显示不显示还是根据技能配置
    {
        horizontalAlignment = 0/1/2 （left/center/right） -- 默认 1
        verticalAlignment = 0/1/2 （top/center/bottom） --  默认 2
        font = xx, 
        color = xx, 
        area = {{xx, xx}, {xx, xx}, {xx, xx}, {xx, xx}} -- 控制文字相较于技能的位置,默认处于技能下方位置
    }
    cdNumTipConfig = 技能进cd时显示倒计时，默认会创建，具体显示不显示还是根据技能配置
    {
        horizontalAlignment = 0/1/2 （left/center/right） -- 默认 1
        verticalAlignment = 0/1/2 （top/center/bottom） --  默认 1
        font = xx, 
        fontHorizontalAlignment = 0/1/2 （left/right/center） -- 默认 2
        fontVerticalAlignment = 0/1/2 （top/center/bottom） --  默认 1
        color = xx, 
        area = {{xx, xx}, {xx, xx}, {xx, xx}, {xx, xx}} -- 控制文字相较于技能的位置,默认处于中间位置
    }
]]

local defaultHolderConfig = worldCfg.holderConfig

local defaultProgressMaskConfig = worldCfg.progressMaskConfig or 
{
    horizontalAlignment = 1,
    verticalAlignment = 1,
    imageScale = 1,
    progressSize = 10
}

local defaultCdMaskConfig = worldCfg.cdMaskConfig or 
{
    horizontalAlignment = 1,
    verticalAlignment = 1,
    --width = 88,
    --height = 88,
    --area = {{0, 0}, {0, 0}, {1, 0}, {1, 0}},
    --image = "cd_img/rectangle1",
    --resourceGroup = "_imagesets_",

    FillPosition = "Top_With360Degree",
    FillType = "With360Degree",
    AntiClockwise = false
    
}

local defaultMainPageSkillDescConfig = worldCfg.mainPageSkillDescConfig or 
{
    horizontalAlignment = 1,
    verticalAlignment = 2,
    progressSize = 0
}

local defaultCdNumTipConfig = worldCfg.cdNumTipConfig or 
{
    horizontalAlignment = 1,
    verticalAlignment = 1,
    area = {{0, 0}, {0, 0}, {1, 0}, {1, 0}}
}


local useTopLineSkillStyle = worldCfg.useTopLineSkillStyle or false -- 全局技能都使用横排风格技能栏(不覆盖技能自定义位置)，默认false
local topLineSkillStyleConfig = worldCfg.topLineSkillStyleConfig or {}
--[[
    topLineSkillStyleConfig =
    {
        verticalInitialHeight = num -- 垂直方向初始高度 默认64
        verticalInterval = num -- 垂直方向技能的间隔 默认10
        verticalGroup = [ num, num, num ] -- 垂直方向分组，比如[4,3,2]，就是从上往下三横排，依次为4个坑位3个坑位2个坑位， 默认[4]
        horizontalAlignment = 0/1/2 （left/center/right） -- 水平对齐方式：左对齐/中对齐/右对齐(举例：左对齐就是技能从左上开始排列) 默认 1
        horizontalInterval = num 水平对齐技能的间隔(每个技能的间隔) 默认是10
        offset = {x = [0, 0], y = [0, 0]} 所有技能整体偏移 默认 {x = [0, 0], y = [0, 0]}
        skillSize = num 单个技能的大小(正方形) 默认64
    }
]]
local useRightSectorSkillStyle = worldCfg.useRightSectorSkillStyle or false -- 全局技能都使用右下侧扇形风格技能栏(不覆盖技能自定义位置)，默认false
local rightSectorSkillStyleConfig = worldCfg.rightSectorSkillStyleConfig or {}
--[[
    -- 注：该风格技能默认右下角对齐，即下面的计算x/y的时候理应使用负数
    rightSectorSkillStyleConfig =
    {
        radian = num 技能栏的窄度，比如填60，那么就是左下角90度中的15-75度用来计算技能圈， 默认90
        firstRadius = num 第一组技能的距离偏移点的距离(初圈弧半径) 默认150
        groupInterval = num 每组的间隔 默认10
        group = [ num, num, num ] 技能分组，比如[2,3,4]，那么就是第一圈两个技能，第二圈三个技能，第三圈四个技能 默认[3]
        offset = {x = [0, 0], y = [0, 0]} 所有技能整体偏移 默认 {x = [0, 0], y = [0, 0]}
        skillSize = num 单个技能的大小(正方形) 默认64
    }
]]
--[[
    风格栏的技能都会事先创建好坑位(可以不显示坑位)，技能显示的时候是按照坑位显示的。
]]

local scatteredSkillConfig = worldCfg.scatteredSkillConfig or 
{
    verticalAlignment = 2,
    horizontalAlignment = 2,
    verticalInitialHeight = -250,
    skillSize = 70,
    horizontalInterval = 10,
}
--[[ 
    scatteredSkillConfig 零散技能全局统一配置
    ·零散技能没有固定数量，没有坑位分组，但是是用一个holder+xx的形式，方便管理
    ·零散技能默认从右下侧往上一点的位置依次往左边排列，
    `默认高度是-250，默认大小70，默认间隔是10，
]]

--[[
    customizeSkill 定制技能，该技能不遵守任何全局配置(除了Config那几个)，任何属性需要手动配置
    customizeSkill : true, 如果配了这个，那么这个技能就是定制技能，只使用自己技能配置的属性/位置/大小状态等
    area = {{xx, xx}, {xx, xx}, {xx, xx}, {xx, xx}} -- 必须配置
    verticalAlignment = xx, -- 
    horizontalAlignment = xx, -- 
]]
------------------------------------
------------------------------------
------------------------------------

self.topLineSkills = {}
self.rightSectorSkills = {}
--[[
    topLineSkills/rightSectorSkills = {
        [行数/圈数][从左往右数第几个/从上往下数第几个] = {
            holderInstance = xx -- 坑位UI
            progressInstance = xx -- 进度条
            imageInstance = xx -- 技能UI
            cdMaskInstance = xx -- 遮罩界面
            skillDescInstance = xx -- 技能主界面显示描述
            cdNumTipInstance = xx -- 技能cd的计时
            skillData = { -- 技能对应的数据，比如fullName/event等
                fullName = xx
                cfg = xx
                resetFuncs = xx
            }
        }
    }
    此处的 xxInstance是下面对应的cell包了一层外壳包成Instance用来监听各种事件，
        需要在这个ui被销毁时调用Instance:close()即可，会自动销毁下面的window
                    progress          -- 0
                    image             -- 1
    holder -child>  cdMask            -- 2
                    skillDesc         -- 3
                    cdNumTip          -- 4
]]
self.scatteredSkills = {}
self.customizeSkills = {}
--[[
    scatteredSkills/customizeSkills = {
        fullName = 
        {
            内容同上
        }
    }
]]

local SKILL_TYPE = 
{
    [1] = "STYLE_SKILL",
    [2] = "CUSTOMIZE_SKILL",
    [3] = "SCATTERED_SKILL"
}

local Logic = L("Logic", {})
local Init = L("Init", {})
------------------------------------------------------------- local
local holderCount = 0
local function createSkillCellData(self, holderData, holderConfig, progressMaskConfig, cdMaskConfig, cdNumTipConfig, mainPageSkillDescConfig)
    local ret = {}
    local holderName = (holderData.name or "skills-holder-")..holderCount
    holderCount = holderCount + 1

    -- 注：create出来的win需要包一个外壳变成instance才能触发各种事件（UI:getWindowInstance(window, autoCreate)）
    local holder = winMgr:createWindow("Engine/StaticImage", holderName) 
    self:addChild(holder)
    holder:setProperty("FrameEnabled", false)
    holder:setHorizontalAlignment(holderData.horizontalAlignment or 0)
    holder:setVerticalAlignment(holderData.verticalAlignment or 0)
    holder:setArea2(table.unpack(holderData.area or {{0,0},{0,0},{1,0},{1,0}}))
    holder:setMousePassThroughEnabled(true)
    holder:setVisible(true)
    if holderConfig then
        Logic.setImage(holder, "Image", holderConfig.image, holderConfig.resourceGroup)
    end
    ret.holderInstance = UI:getWindowInstance(holder, true)

    local progressMaskInstance = UI:openWindow("progressMask", holderName.."-progressMask", "_layouts_", {imageConfig = progressMaskConfig.image})
    holder:addChild(progressMaskInstance:getWindow())
    local progressMask = progressMaskInstance:getWindow()
    progressMask:setHorizontalAlignment(progressMaskConfig.horizontalAlignment or 1)
    progressMask:setVerticalAlignment(progressMaskConfig.verticalAlignment or 1)
    progressMask:setArea2({0, 0}, {0, 0}, {1, progressMaskConfig.progressSize or 10}, {1, progressMaskConfig.progressSize or 10})
    progressMask:setMousePassThroughEnabled(true)
    progressMask:setVisible(false)
    ret.progressMaskInstance = progressMaskInstance

    local skill = winMgr:createWindow("Engine/StaticImage", "staticImage")
    local skillContainer = UI:createWindow(holderName.."-skill", "DragContainer")
    skillContainer:setDraggingEnabled(false)
    skillContainer:setArea2({0, 0}, {0, 0}, {1, 0}, {1, 0})
    skillContainer:addChild(skill)
    skillContainer:setVisible(false)
    skill:setProperty("FrameEnabled", false)
    skill:setArea2({0, 0}, {0, 0}, {1, 0}, {1, 0})
    skill:setMousePassThroughEnabled(true)
    holder:addChild(skillContainer.__window)
    ret.imageInstance = skillContainer

    local cdMaskInstance = UI:openWindow("CDMask", holderName.."-cdMask", "_layouts_", {imageConfig = cdMaskConfig.image})
    holder:addChild(cdMaskInstance:getWindow())
    local cdMask = cdMaskInstance:getWindow()
    cdMask:setHorizontalAlignment(cdMaskConfig.horizontalAlignment or 1)
    cdMask:setVerticalAlignment(cdMaskConfig.verticalAlignment or 1)
    cdMask:setArea2(table.unpack(cdMaskConfig.area or {{0,0},{0,0},{1,0},{1,0}}))
    cdMask:setVisible(false)
    if holderData.area and not cdMaskConfig.width and not cdMaskConfig.height then 
        cdMaskConfig.width = holderData.area[3][2]
        cdMaskConfig.height = holderData.area[4][2]
    end
    cdMaskInstance:resetMaskImage(cdMaskConfig)
    ret.cdMaskInstance = cdMaskInstance

    local mainPageSkillDesc = winMgr:createWindow("Engine/StaticText", holderName.."-mainPageSkillDesc")
    holder:addChild(mainPageSkillDesc)
    mainPageSkillDesc:setHorizontalAlignment(mainPageSkillDescConfig.horizontalAlignment or 1)
    mainPageSkillDesc:setVerticalAlignment(mainPageSkillDescConfig.verticalAlignment or 2)
    mainPageSkillDesc:setArea2(table.unpack(mainPageSkillDescConfig.area or {{0,0},{0,0},{1,0},{1,0}}))
    mainPageSkillDesc:setMousePassThroughEnabled(true)
    mainPageSkillDesc:setVisible(false)
    if mainPageSkillDescConfig.font then
        mainPageSkillDesc:setFont(mainPageSkillDescConfig.font)
    end
    if mainPageSkillDescConfig.color then
        mainPageSkillDesc:setProperty("TextColours", mainPageSkillDescConfig.color)-- "ffffffff")
        -- mainPageSkillDesc:setTextColours(mainPageSkillDescConfig.color)
    end
    ret.skillDescInstance = UI:getWindowInstance(mainPageSkillDesc, true)

    local cdNum = winMgr:createWindow("Engine/StaticText", holderName.."-cdNum")
    holder:addChild(cdNum)
    cdNum:setHorizontalAlignment(cdNumTipConfig.horizontalAlignment or 1)
    cdNum:setVerticalAlignment(cdNumTipConfig.verticalAlignment or 1)
    cdNum:getWindowRenderer():setHorizontalFormatting(cdNumTipConfig.fontHorizontalAlignment or 2)
    cdNum:getWindowRenderer():setVerticalFormatting(cdNumTipConfig.fontVerticalAlignment or 1)
    cdNum:setArea2(table.unpack(cdNumTipConfig.area or {{0,0},{0,0},{1,0},{1,0}}))
    cdNum:setMousePassThroughEnabled(true)
    cdNum:setVisible(false)
    if cdNumTipConfig.font then
        cdNum:setFont(cdNumTipConfig.font)
    end
    if cdNumTipConfig.color then
        cdNum:setProperty("TextColours", cdNumTipConfig.color)-- "ffffffff")
        -- cdNum:setTextColours(cdNumTipConfig.color)
    end
    ret.cdNumTipInstance = UI:getWindowInstance(cdNum, true)

    ret.skillData = 
    {
        fullName = nil,
        cfg = nil,
        resetFuncs = {}
    }

    return ret
end

local function resetSkillCellData(self, skillCellData)
    local skillData = skillCellData.skillData
    skillData.fullName = nil
    skillData.cfg = nil
    for i, func in pairs(skillData.resetFuncs) do
        func()
    end
    skillData.resetFuncs = {}

    skillCellData.progressMaskInstance:resetWnd()
    skillCellData.progressMaskInstance:getWindow():setVisible(false)
    skillCellData.imageInstance:child("staticImage"):setProperty("Image", "")
    skillCellData.imageInstance:getWindow():setVisible(false)
    skillCellData.cdMaskInstance:resetWnd()
    skillCellData.cdMaskInstance:getWindow():setVisible(false)
    skillCellData.skillDescInstance:getWindow():setVisible(false)
    skillCellData.cdNumTipInstance:getWindow():setVisible(false)
end

local function openCDMask(cdMask, cdMaskInstance, beginTime, endTime, lessCdTime)
    cdMask:setVisible(true)
    cdMaskInstance:onReopen({
        beginTime = beginTime,
        endTime = endTime,
        curTime = lessCdTime and (endTime - lessCdTime) or beginTime,
        callback = function()
            cdMaskInstance:resetWnd()
            cdMask:setVisible(false)
        end
    })
end

local function getCDNumTipTimeStr(time,isShowCdPoint)
   local tempTime = time / 20
   if not isShowCdPoint then 
       return math.modf(tempTime)
   else 
       return tempTime - tempTime%0.1
   end 
end

local function openCDNumTip(resetFuncs, cdNumTip, lessCdTime, isShowCdPoint)
    if resetFuncs.closeCdNumTipFunc then
        resetFuncs.closeCdNumTipFunc()
    end
    cdNumTip:setText(getCDNumTipTimeStr(lessCdTime,isShowCdPoint))
    cdNumTip:setVisible(true)
    local tempCdNumTipTickTime = worldCfg.cdNumTipTickTime or (isShowCdPoint and 2 or 20)
    resetFuncs.closeCdNumTipFunc = World.Timer(tempCdNumTipTickTime, function()
        lessCdTime = lessCdTime - tempCdNumTipTickTime
        if lessCdTime <= 0 then
            resetFuncs.closeCdNumTipFunc = nil
            cdNumTip:setVisible(false)
            return false
        end
        cdNumTip:setText(getCDNumTipTimeStr(lessCdTime,isShowCdPoint))
        return true
    end)
end

local function updateSkillCellDataProp(self, skillCellData, skillCfg)
    local skillData = skillCellData.skillData
    local skillFullName = skillCfg.fullName
    skillData.fullName = skillFullName
    skillData.cfg = skillCfg
    local resetFuncs = skillData.resetFuncs

    local cdMaskInstance = skillCellData.cdMaskInstance
    local cdNumTipInstance = skillCellData.cdNumTipInstance
    local skillDescInstance = skillCellData.skillDescInstance
    local imageInstance = skillCellData.imageInstance
    local progressMaskInstance = skillCellData.progressMaskInstance
    local cdMask = cdMaskInstance:getWindow()
    local cdNumTip = cdNumTipInstance:getWindow()
    local skillDesc = skillDescInstance:getWindow()
    local imageWin = imageInstance:child("staticImage")
    local progressMask = progressMaskInstance:getWindow()

    local lessCdTime = Me:checkCD(skillCfg.cdKey)
    if skillCfg.cdTime and lessCdTime then
        if skillCfg.enableCdMask then
            openCDMask(cdMask, cdMaskInstance, 0, skillCfg.cdTime, lessCdTime)
        end
        if skillCfg.enableCdTip then
            openCDNumTip(resetFuncs, cdNumTip, lessCdTime,skillCfg.isShowCdPoint)
        end
    end

    if skillCfg.mainPageSkillDesc then
        skillDesc:setText(Lang:toText(skillCfg.mainPageSkillDesc))
        skillDesc:setVisible(true)
    end

    if skillCfg.draggingEnabled then
        imageInstance:setDraggingEnabled(skillCfg.draggingEnabled)
    end

    local showImage = skillCfg.showImage
    local pushImage = skillCfg.pushImage
    if showImage then
        Logic.setImage(imageWin, "Image", showImage.image, showImage.resourceGroup)
        imageInstance:setVisible(true)
        if skillCfg.enableCdMask then 
            cdMask:getMaskWin():setImage(showImage.image, showImage.resourceGroup)
        end
    elseif skillCfg.icon and  skillCfg.icon ~= ""  then
        print("GUILib.loadImage(skillCfg.icon, skillCfg)", GUILib.loadImage(skillCfg.icon, skillCfg))
        Logic.setImage(imageWin, "Image", {name = GUILib.loadImage(skillCfg.icon, skillCfg)})
        if skillCfg.enableCdMask then 
           cdMaskInstance:getMaskWin():setImage(GUILib.loadImage(skillCfg.icon, skillCfg))
        end
        imageInstance:setVisible(true)
    end
    if resetFuncs.longTouchTimer then
        resetFuncs.longTouchTimer()
    end
    if resetFuncs.stopCastLoop then
        resetFuncs.stopCastLoop()
    end
    local longTouchStartFunc = function()
        local castInterval = skillCfg.castInterval
        if castInterval and castInterval > 0 then
            --该条件是长按连发
            if resetFuncs.stopCastLoop then
                resetFuncs.stopCastLoop()
            end
            local function tick()
                 Skill.Cast(skillFullName)
                 return true
            end
            resetFuncs.stopCastLoop = World.Timer(castInterval, tick)
        end
        ------------------------------
        local castSkillName
        if skillCfg.isTouch then
            --该条件表面长按释放
            castSkillName = skillFullName
        end
        if skillCfg.castTouchSkill then
            --castTouchSkill字段编辑器并未导出，暂不明确意思
            castSkillName = skillCfg.castTouchSkill
        end
        if castSkillName then
            local touchSkillCfg = Skill.Cfg(castSkillName)
            if touchSkillCfg.enableProgressMask then
                local callback = function()
                    if not touchSkillCfg.progressShowInEnd then
                        progressMaskInstance:resetWnd()
                        progressMask:setVisible(false)
                    end
                end
                progressMask:setVisible(true)
                progressMaskInstance:onReopen({
                    beginTime = 0,
                    endTime = touchSkillCfg.touchTimeMax,
                    callback = callback
                })
            end
            Skill.TouchBegin({name = castSkillName})
        end
    end
    local longTouchStopFunc = function()
        if resetFuncs.stopCastLoop then
            resetFuncs.stopCastLoop()
            resetFuncs.stopCastLoop = nil
        end
        if showImage then
            Logic.setImage(imageWin, "Image", showImage.image, showImage.resourceGroup)
        end
        if resetFuncs.longTouchTimer then
            resetFuncs.longTouchTimer()
            resetFuncs.longTouchTimer = nil
        end

        progressMaskInstance:resetWnd()
        progressMask:setVisible(false)
        Skill.TouchEnd()
    end
    imageInstance.onMouseButtonDown = function()
        if pushImage and pushImage.image then
            Logic.setImage(imageWin, "Image", pushImage.image, pushImage.resourceGroup)
        end
        resetFuncs.longTouchTimer = World.Timer(longTouchTickTime, function()
            longTouchStartFunc()
            resetFuncs.longTouchTimer = nil
        end)
    end
    imageInstance.onMouseButtonUp = function()
        longTouchStopFunc()
    end
    imageInstance.onMouseLeavesArea = function()
        longTouchStopFunc()
    end
    
    imageInstance.onMouseMove = function (instance, window, posX, posY, moveDeltaX, moveDeltaY)
        if instance:isDraggingEnabled() then
            local yaw = moveDeltaX * (skillCfg.sensitivityFactor or 1)
            local pitch = -moveDeltaY * (skillCfg.sensitivityFactor or 1)
            Blockman:Instance():setAngles(yaw, pitch)
        else
            local size = imageInstance:getPixelSize()
            local pos = imageInstance:getPixelPosition()
            if posX < pos.x or posY < pos.y or posX > pos.x + size.width or posY > pos.y + size.height then
                longTouchStopFunc()
            end
        end
    end

    if not skillCfg.isTouch then
        imageInstance.onMouseClick = function()
            if skillCfg.castInterval and skillCfg.castInterval > 0 then
                --如果是长按定时发送技能，就不执行单次的释放技能
                return
            end
            local skillName = skillFullName
            if skillCfg.castClickSkill then
                skillName = skillCfg.castClickSkill
            end
            Skill.Cast(skillName)
        end
    end

    -- TODO 原UI的skill.trackCamera暂未处理
end

local function removeSkillCellData(self, skillCellData)
    local skillData = skillCellData.skillData
    for i, func in pairs(skillData.resetFuncs) do
        func()
    end
    skillCellData.skillData = nil

    skillCellData.progressMaskInstance:resetWnd()
    skillCellData.progressMaskInstance:close()
    skillCellData.imageInstance:close()
    skillCellData.cdMaskInstance:resetWnd()
    skillCellData.cdMaskInstance:close()
    skillCellData.skillDescInstance:close()
    skillCellData.cdNumTipInstance:close()

    skillCellData.holderInstance:close()
    self:removeChild(skillCellData.holderInstance)
end

local function getCheckStyleSkillArray(self, skillCfg)
    local ret = {}
    if useTopLineSkillStyle and skillCfg.useTopLineSkillStyle then
        ret[#ret+1] = self.topLineSkills
    end
    if useRightSectorSkillStyle and skillCfg.useRightSectorSkillStyle then
        ret[#ret+1] = self.rightSectorSkills
    end
    return ret
end

local function getStyleSkillFreeCellData(self, skillCfg)
    if not skillCfg then
        return nil
    end
    for _, compomentTable in ipairs(getCheckStyleSkillArray(self, skillCfg)) do
        for row, columnDatas in ipairs(compomentTable) do
            for _, skillCellData in pairs(columnDatas) do
                if not skillCellData.skillData.fullName then
                    return skillCellData, SKILL_TYPE[1]
                end
            end
        end
    end
end

local function getStyleSkillCellDataByIndex(self, skillCfg, index)
    if not skillCfg then
        return nil
    end
    local index = index or skillCfg.showIndex
    if not index then
        return nil
    end
    for _, compomentTable in ipairs(getCheckStyleSkillArray(self, skillCfg)) do
        local count = 0
        for row, columnDatas in ipairs(compomentTable) do
            if (count + #columnDatas) >= index then
                return compomentTable[row][index - count], SKILL_TYPE[1]
            end
            count = count + #columnDatas
        end
    end
end

local function getStyleSkillCellDataByFullName(self, skillCfg, fullName)
    if not skillCfg then
        return nil
    end
    local fullName = fullName or skillCfg.fullName
    for _, compomentTable in ipairs(getCheckStyleSkillArray(self, skillCfg)) do
        for row, columnDatas in ipairs(compomentTable) do
            for _, skillCellData in pairs(columnDatas) do
                if skillCellData.skillData.fullName == fullName then
                    return skillCellData, SKILL_TYPE[1]
                end
            end
        end
    end
end

local function getSkillCellDataInAllSkills(self, skillCfg)
    if self.customizeSkills[skillCfg.fullName] then
        return self.customizeSkills[skillCfg.fullName], SKILL_TYPE[2]
    end
    if self.scatteredSkills[skillCfg.fullName] then
        return self.scatteredSkills[skillCfg.fullName], SKILL_TYPE[3]
    end
    return getStyleSkillCellDataByFullName(self, skillCfg, skillCfg.fullName)
end

local function recalcScatteredSkillsPos(self)
    local sortTable = {}
    local scatteredSkills = self.scatteredSkills
    for fullName, skillCellData in pairs(self.scatteredSkills) do
        sortTable[#sortTable + 1] = fullName
    end
    table.sort(sortTable)
    for i, fullName in ipairs(sortTable) do
        local skillCfg = Skill.Cfg(fullName)
        local skillSize = skillCfg.skillSize or scatteredSkillConfig.skillSize
        scatteredSkills[fullName].holderInstance:getWindow():setArea2({0,-(i * (skillSize + scatteredSkillConfig.horizontalInterval))}, {0,scatteredSkillConfig.verticalInitialHeight}, 
            {0, skillSize}, {0, skillSize})
    end
end
------------------------------------------------------------- Init
function Init.initTopLineSkills(self)
    if not useTopLineSkillStyle then
        return
    end
    
    local verticalInitialHeight = topLineSkillStyleConfig.verticalInitialHeight or 64
    local verticalInterval = topLineSkillStyleConfig.verticalInterval or 10
    local verticalGroup = topLineSkillStyleConfig.verticalGroup or{[1] = 4}
    local horizontalAlignment = topLineSkillStyleConfig.horizontalAlignment or 1
    local horizontalInterval = topLineSkillStyleConfig.horizontalInterval or 10
    local offset = topLineSkillStyleConfig.offset or {x = {0 ,0}, y = {0 ,0}}
    local skillSize = topLineSkillStyleConfig.skillSize or 64

    local holderConfig = topLineSkillStyleConfig.holderConfig or defaultHolderConfig
    local progressMaskConfig = topLineSkillStyleConfig.progressMaskConfig or defaultProgressMaskConfig
    local cdMaskConfig = topLineSkillStyleConfig.cdMaskConfig or defaultCdMaskConfig 
    local cdNumTipConfig = topLineSkillStyleConfig.cdNumTipConfig or defaultCdNumTipConfig
    local mainPageSkillDescConfig = topLineSkillStyleConfig.mainPageSkillDescConfig or defaultMainPageSkillDescConfig

    local topLineSkills = self.topLineSkills
    for row, holderCount in ipairs(verticalGroup) do
        local y = row * verticalInitialHeight + row * verticalInterval
        local beginX = -(horizontalAlignment * 0.5 * (holderCount * skillSize + (holderCount - 1) * horizontalInterval))
        topLineSkills[row] = {}
        for column = 1, holderCount do
            local x = beginX + (horizontalInterval + skillSize) * (column - 1)
            local holderData = {
                name = "skills-topLineSkill-"..row .. "-" ..column .. "-".. "holder",
                area = {{offset.x[1], offset.x[2] + x}, {offset.y[1], offset.y[2] + y}, {0, skillSize}, {0, skillSize}},
                horizontalAlignment = horizontalAlignment,
                verticalAlignment = 0
            }
            topLineSkills[row][column] = createSkillCellData(self, holderData, holderConfig, progressMaskConfig, cdMaskConfig, cdNumTipConfig, mainPageSkillDescConfig)
        end
    end
end

function Init.initRightSectorSkills(self)
    if not useRightSectorSkillStyle then
        return
    end

    local radian = rightSectorSkillStyleConfig.radian or 90
    local beginRadian = (90 - radian) / 2
    local offset = rightSectorSkillStyleConfig.offset or {x = {0, 0}, y = {0, 0}}
    local firstRadius = rightSectorSkillStyleConfig.firstRadius or 150
    local groupInterval = rightSectorSkillStyleConfig.groupInterval or 10
    local group = rightSectorSkillStyleConfig.group or {[1] = 3}
    local skillSize = rightSectorSkillStyleConfig.skillSize or 64

    local holderConfig = rightSectorSkillStyleConfig.holderConfig or defaultHolderConfig
    local progressMaskConfig = rightSectorSkillStyleConfig.progressMaskConfig or defaultProgressMaskConfig
    local cdMaskConfig = rightSectorSkillStyleConfig.cdMaskConfig or defaultCdMaskConfig 
    local cdNumTipConfig = rightSectorSkillStyleConfig.cdNumTipConfig or defaultCdNumTipConfig
    local mainPageSkillDescConfig = rightSectorSkillStyleConfig.mainPageSkillDescConfig or defaultMainPageSkillDescConfig

    local rightSectorSkills = self.rightSectorSkills
    for ringNum, holderCount in ipairs(group) do
        rightSectorSkills[ringNum] = {}
        for index = 1, holderCount do
            local targetRadian = beginRadian + (radian * (index / holderCount))
            local targetRadius = firstRadius + (groupInterval + skillSize) * (index - 1)
            local x = -(targetRadius * math_cos(math_rad(targetRadian)))
            local y = -(targetRadius * math_sin(math_rad(targetRadian)))

            local holderData = {
                name = "skills-rightSectorSkill-"..ringNum .. "-" ..index .. "-".. "holder",
                area = {{offset.x[1], offset.x[2] + x - skillSize}, {offset.y[1], offset.y[2] + y - skillSize}, {0, skillSize}, {0, skillSize}},
                horizontalAlignment = 2,
                verticalAlignment = 2
            }
            rightSectorSkills[ringNum][index] = createSkillCellData(self, holderData, holderConfig, progressMaskConfig, cdMaskConfig, cdNumTipConfig, mainPageSkillDescConfig)
        end
    end

end

function Init.initLibSubEvent(self)
    Lib.subscribeEvent(Event.EVENT_SHOW_SKILL, function(skillCfg, show)
        if not show then
            local skillCellData, skillType = getSkillCellDataInAllSkills(self, skillCfg)
            if not skillCellData then
                return
            end
            if skillType == SKILL_TYPE[2] then
                removeSkillCellData(self, skillCellData)
                self.customizeSkills[skillCfg.fullName] = nil
                return
            end
            if skillType == SKILL_TYPE[3] then
                removeSkillCellData(self, skillCellData)
                self.scatteredSkills[skillCfg.fullName] = nil
                recalcScatteredSkillsPos(self)
                return
            end
            resetSkillCellData(self, skillCellData)
            return
        end
        local skillCellData
        if (useTopLineSkillStyle and skillCfg.useTopLineSkillStyle) or (useRightSectorSkillStyle and skillCfg.useRightSectorSkillStyle) then
            local index = Me:getSkillEquipIndex(skillCfg.fullName)
            skillCellData = getStyleSkillCellDataByIndex(self, skillCfg, index) or getStyleSkillFreeCellData(self, skillCfg)
            -- print("================================ had find ?? skillCellData == nil?? ", skillCellData == nil, skillCfg.fullName)
            if skillCellData then
                resetSkillCellData(self, skillCellData)
            end
        end
        if not skillCellData then
            -- print("================================ create skillCellData ", skillCfg.fullName)
            local holderData = 
            {
                name = skillCfg.fullName,
            }
            if skillCfg.customizeSkill then
                holderData.area = skillCfg.area or {{0,0}, {0,0}, {0,skillCfg.skillSize}, {0,skillCfg.skillSize}}
                holderData.horizontalAlignment = skillCfg.horizontalAlignment
                holderData.verticalAlignment = skillCfg.verticalAlignment
            else
                holderData.horizontalAlignment = scatteredSkillConfig.horizontalAlignment
                holderData.verticalAlignment = scatteredSkillConfig.verticalAlignment
                local count = 1
                for _, _ in pairs(self.scatteredSkills) do
                    count = count + 1
                end
                local skillSize = skillCfg.skillSize or scatteredSkillConfig.skillSize
                holderData.area = {{0,-(count * (skillSize + scatteredSkillConfig.horizontalInterval))}, {0,scatteredSkillConfig.verticalInitialHeight}, 
                    {0, skillSize}, {0, skillSize}}
            end
            skillCellData = createSkillCellData(self, holderData, skillCfg.holderConfig or defaultHolderConfig,
                skillCfg.progressMaskConfig or defaultProgressMaskConfig, 
                skillCfg.cdMaskConfig or defaultCdMaskConfig, 
                skillCfg.cdNumTipConfig or defaultCdNumTipConfig, 
                skillCfg.mainPageSkillDescConfig or defaultMainPageSkillDescConfig
            )
            if skillCfg.customizeSkill then
                self.customizeSkills[skillCfg.fullName] = skillCellData
            else
                self.scatteredSkills[skillCfg.fullName] = skillCellData
                recalcScatteredSkillsPos(self)
            end
        end
        if not skillCellData then
            return
        end
        updateSkillCellDataProp(self, skillCellData, skillCfg)
    end)

    
    Lib.subscribeEvent(Event.EVENT_SHOW_CD_MASK,function(skillMap)
        local skillCellData = getSkillCellDataInAllSkills(self, Skill.Cfg(skillMap.name))
        if not skillCellData then
            return
        end
        local skillBeginCdTime = skillMap.beginTime
        local skillEndCdTime = skillMap.endTime
        if skillMap.cdMask then
            openCDMask(skillCellData.cdMaskInstance:getWindow(), skillCellData.cdMaskInstance, skillBeginCdTime, skillEndCdTime, nil)
        end
        if skillMap.cdTip then
            openCDNumTip(skillCellData.skillData.resetFuncs, skillCellData.cdNumTipInstance:getWindow(), skillEndCdTime - skillBeginCdTime,Skill.Cfg(skillMap.name).isShowCdPoint)
        end
    end)
    
    Lib.subscribeEvent(Event.EVENT_UPDATE_SKILL_JACK_AREA, function(info)
        -- TODO 暂未实现
    end)
end

------------------------------------------------------------- Logic
function Logic.setImage(self, property, image, resourceGroup)
    resourceGroup = resourceGroup or "gameres"
    if property == "Image" then
        self:setImage(image.name, resourceGroup)
    elseif property == "NormalImage" then
        self:setNormalImage(image.name, resourceGroup)
    elseif property == "PushedImage" then
        self:setPushedImage(image.name, resourceGroup)
    end
end

-- function Logic.createElement(type, name)
--     -- winMgr:createWindow(type, name) -- type:加载好的scheme，里面的一个winType，例如 type=WindowsLook/Button name=xxx
--     return winMgr:createWindow(type, name)
-- end

-- function Logic.removeElement(element)
--     winMgr:removeWindow(element)
-- end

------------------------------------------------------------- self
function self:init()
    self:setMousePassThroughEnabled(true)
    Init.initTopLineSkills(self)
    Init.initRightSectorSkills(self)
    Init.initLibSubEvent(self)

end


------------------------------------------------------------- open close
local openCount = 0
function self:onOpen()
    print("skills onOpen , openCount = ", openCount)
    openCount = openCount + 1

end

function self:onClose()
    print("skills onClose ")

end

self:init()
print("skills startup .")