print('script_common:hello world')

Entity.addValueDef('DateData',{
    curtWeek = tonumber(Lib.getYearWeekStr(os.time())),
    totalLoginCount = 0,
    lastDay = 0
}
,false,false,true)