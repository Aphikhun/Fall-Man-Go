local closeHelp = self.HelpWindows.Button
local Txt_info1 = self:child('Txt_info1')
local Txt_info2 = self:child('Txt_info2')
local Txt_info3 = self:child('Txt_info3')

function self:onOpen()
  Txt_info1:setText(Lang:toText('LangKey_UI_Help_info1'))
  Txt_info2:setText(Lang:toText('LangKey_UI_Help_info2'))
  Txt_info3:setText(Lang:toText('LangKey_UI_Help_info3'))
end

closeHelp.onMouseClick = function()
  UI:closeWindow(self)
end
