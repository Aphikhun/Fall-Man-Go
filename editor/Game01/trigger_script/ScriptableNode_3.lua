--You can use 'params.parameter name' to get the parameters defined in the node. 					
--For example, if a parameter named 'entity' is defined in the node, you can use 'params.entity' to get the value of the parameter.
local _player = params.player
local team = Game.CreateTeam(5)
//local team1 = Game.GetTeam(5, true)
print(team.id)
print(_player.name)
--team1.joinEntity(_player)
--team1.joinEntity(params.player)