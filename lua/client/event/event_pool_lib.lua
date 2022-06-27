local EventPoolLib = EventPoolLib
local LIB = Define.EVENT_POOL.LIB
local Creator = BindableEventLib.new

--用于兼容Lib.subscribeEvent系统的EventPool子类

function EventPoolLib:ctor(ID, Owner, EventSpace)
    self.super.ctor(self, ID, Owner, EventSpace)
    self.__EventCreator = Creator
    self.__PoolType = LIB
end
