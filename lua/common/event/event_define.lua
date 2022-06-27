Define.EVENT_POOL =
{
    DEFAULT = "DEFAULT",
    TRIGGER = "TRIGGER",
    OBJECT = "OBJECT",
    LIB = "LIB",
    WINDOW = "WINDOW",
    INSTANCE = "INSTANCE",
}

setmetatable(Define.EVENT_POOL, {
    __index = function(self, Key)
        return self.DEFAULT
    end
})

Define.EVENT_SPACE =
{
    GLOBAL = "GLOBAL",
    OBJECT = "OBJECT",
    WINDOW = "WINDOW",
    INSTANCE = "INSTANCE",
    TWEEN = "TWEEN",
    FREE = "FREE"
}