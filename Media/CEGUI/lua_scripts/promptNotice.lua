local top_notification, top_notification_bg,
center_notification, bottom_notification,
toast_notification, toast_notification_bg

local func = {
    _close_toptip = nil,
    _close_centertip = nil,
    _close_bottomtip = nil,
    _close_chat = nil
}

function M:setAllUiTouchAble(parentNode, touchAble)
    for index = 1, parentNode:getChildCount() do
        local wnd = parentNode:getChildElementAtIdx(index - 1)
        wnd:setMousePassThroughEnabled(touchAble)
        self:setAllUiTouchAble(wnd, touchAble)
    end
end

function M:onOpen()
    self:setMousePassThroughEnabled(true)
    self:setAllUiTouchAble(self, true)
    top_notification = self.PromptNotice_Top_System.PromptNotice_Top_System_Notification
    top_notification_bg = self.PromptNotice_Top_System.PromptNotice_Top_System_Notification_BackGround
    center_notification = self.PromptNotice_Center_System_Notification
    bottom_notification = self.PromptNotice_Bottom_System_Notification
    toast_notification = self.PromptNotice_Toast_System.PromptNotice_Toast_System_Notification
    toast_notification_bg = self.PromptNotice_Toast_System.PromptNotice_Toast_System_Notification_BackGround

    self:setAlwaysOnTop(true)

    top_notification_bg:setVisible(false)
    toast_notification_bg:setVisible(false)
end

local function insertTable(t, ins_t)
    local res = Lib.copy(t)
    if ins_t.var then
        table.insert(res, (ins_t.insert or 1) + 1, ins_t.var)
    end
    return res
end

function M:sendTip(_type, tip, tipBg, keepTime, vars, regId, textArgs, modName)
    if func[_type] then
        func[_type]()
        func[_type] = nil
    end
    local kTime = keepTime and keepTime / 20 or 2
    local always = kTime < 0
    local tVar, tVars, timing = nil, textArgs, nil
    if vars then
        local consumedTime = os.time() - (vars.nowTime or os.time())
        vars.var = vars.var - consumedTime * 20
        timing = math.floor(vars.timing and vars.timing / 20 or -1)
        tVar = math.floor(vars.var / 20)
        vars.var = timing > 0 and 1 or tVar
        tVars = insertTable(textArgs, vars)
    end
    if tVar and tVar <= 0 then
        return
    end
    local msg = Lang:toText(tVars)
    tip:setText(tostring(msg))
    tip:setProperty("ClippedByParent", "false")
    tip:setVisible(kTime > 0 or always)
    if tipBg then
        tipBg:setVisible(kTime > 0 or always)
        tipBg:setProperty("ClippedByParent", "false")
        tipBg:setHeight({0, tip:getHeight()[2] + 2})
    end
    local function tick()
        kTime = kTime - 1
        if not self then
            return
        end
        if tVar then
            vars.var = vars.var + timing
            tVars = insertTable(textArgs, vars)
            msg = Lang:toText(tVars)
            tip:setText(tostring(msg))
        end
        tip:setVisible(kTime > 0 or always or (tVar and vars.var > 0 and vars.var <= tVar))
        if tipBg then
            tipBg:setVisible(kTime > 0 or always or (tVar and vars.var > 0 and vars.var <= tVar))
        end
        if tVar and not (vars.var > 0 and vars.var <= tVar) and regId then
            Me:doCallBack(modName, "key", regId)
        end
        if tVar and (vars.var > 0 and vars.var <= tVar) then
            return true
        end
        if kTime <= 0 then
            return false
        end
        return true
    end
    func[_type] = World.Timer(20, tick)
    self.reloadArg = table.pack(func[_type], _type, tip, tipBg, keepTime, vars, regId, textArgs)
end

function M:sendTopTips(keepTime, vars, regId, textArgs)
    self:sendTip("_close_toptip", top_notification, top_notification_bg, keepTime, vars, regId, textArgs, "SendTip1")
end

function M:sendCenterTips(keepTime, vars, regId, textArgs)
    self:sendTip("_close_centertip", center_notification, nil, keepTime, vars, regId, textArgs, "SendTip2")
end

function M:sendBottomTips(keepTime, vars, regId, textArgs)
    self:sendTip("_close_bottomtip", bottom_notification, nil, keepTime, vars, regId, textArgs, "SendTip3")
end

function M:sendToastTips(keepTime, vars, regId, textArgs)
    self:sendTip("_close_bottomtip", toast_notification, toast_notification_bg, keepTime, vars, regId, textArgs, "SendTip6")
end

function M:onReload(reloadArg)
    local closeTimer, _type, tip, tipBg, keepTime, vars, _event, textArgs = table.unpack(reloadArg or {}, 1, reloadArg and reloadArg.n)
    if closeTimer then
        closeTimer()
        closeTimer = nil
    end
end