VGT._itemsForToken = {}
VGT._tokenForItem = {}

---@class IntArray
---@field [integer] integer

---@param tokenId integer
---@return IntArray|nil
function VGT:GetItemsForToken(tokenId)
  return self._itemsForToken[tokenId]
end

---@param itemId integer
---@return integer|nil
function VGT:GetTokenForItem(itemId)
  return self._tokenForItem[itemId]
end

---@param itemOrTokenId integer
---@param action fun(id:integer)
---@return nil
function VGT:RepeatForAllRelatedItems(itemOrTokenId, action)
  action(itemOrTokenId)
  local tokenRewards = VGT:GetItemsForToken(itemOrTokenId)
  if tokenRewards then
    for _, rewardId in ipairs(tokenRewards) do
      action(rewardId)
    end
  end
  local tokenId = VGT:GetTokenForItem(itemOrTokenId)
  if tokenId then
    action(tokenId)
  end
end

local function AddToken(tokenId, rewards)
  VGT._itemsForToken[tokenId] = rewards

  for _, rewardId in ipairs(rewards) do
    VGT._tokenForItem[rewardId] = tokenId
  end
end

AddToken(40610, {39497, 39515, 39523, 39629, 39633, 39638}) -- Chestguard of the Lost Conqueror
AddToken(40611, {39579, 39588, 39592, 39597, 39606, 39611}) -- Chestguard of the Lost Protector
AddToken(40612, {39492, 39538, 39547, 39554, 39558, 39617, 39623}) -- Chestguard of the Lost Vanquisher
AddToken(40613, {39500, 39519, 39530, 39632, 39634, 39639}) -- Gloves of the Lost Conqueror
AddToken(40614, {39582, 39591, 39593, 39601, 39609, 39622}) -- Gloves of the Lost Protector
AddToken(40615, {39495, 39543, 39544, 39557, 39560, 39618, 39624}) -- Gloves of the Lost Vanquisher
AddToken(40616, {39496, 39514, 39521, 39628, 39635, 39640}) -- Helm of the Lost Conqueror
AddToken(40617, {39578, 39583, 39594, 39602, 39605, 39610}) -- Helm of the Lost Protector
AddToken(40618, {39491, 39531, 39545, 39553, 39561, 39619, 39625}) -- Helm of the Lost Vanquisher
AddToken(40619, {39498, 39517, 39528, 39630, 39636, 39641}) -- Leggings of the Lost Conqueror
AddToken(40620, {39580, 39589, 39595, 39603, 39607, 39612}) -- Leggings of the Lost Protector
AddToken(40621, {39493, 39539, 39546, 39555, 39564, 39620, 39626}) -- Leggings of the Lost Vanquisher
AddToken(40622, {39499, 39518, 39529, 39631, 39637, 39642}) -- Spaulders of the Lost Conqueror
AddToken(40623, {39581, 39590, 39596, 39604, 39608, 39613}) -- Spaulders of the Lost Protector
AddToken(40624, {39494, 39542, 39548, 39556, 39565, 39621, 39627}) -- Spaulders of the Lost Vanquisher
AddToken(40625, {40423, 40449, 40458, 40569, 40574, 40579}) -- Breastplate of the Lost Conqueror
AddToken(40626, {40503, 40508, 40514, 40523, 40525, 40544}) -- Breastplate of the Lost Protector
AddToken(40627, {40418, 40463, 40469, 40471, 40495, 40550, 40559}) -- Breastplate of the Lost Vanquisher
AddToken(40628, {40420, 40445, 40454, 40570, 40575, 40580}) -- Gauntlets of the Lost Conqueror
AddToken(40629, {40504, 40509, 40515, 40520, 40527, 40545}) -- Gauntlets of the Lost Protector
AddToken(40630, {40415, 40460, 40466, 40472, 40496, 40552, 40563}) -- Gauntlets of the Lost Vanquisher
AddToken(40631, {40421, 40447, 40456, 40571, 40576, 40581}) -- Crown of the Lost Conqueror
AddToken(40632, {40505, 40510, 40516, 40521, 40528, 40546}) -- Crown of the Lost Protector
AddToken(40633, {40416, 40461, 40467, 40473, 40499, 40554, 40565}) -- Crown of the Lost Vanquisher
AddToken(40634, {40422, 40448, 40457, 40572, 40577, 40583}) -- Legplates of the Lost Conqueror
AddToken(40635, {40506, 40512, 40517, 40522, 40529, 40547}) -- Legplates of the Lost Protector
AddToken(40636, {40417, 40462, 40468, 40493, 40500, 40556, 40567}) -- Legplates of the Lost Vanquisher
AddToken(40637, {40424, 40450, 40459, 40573, 40578, 40584}) -- Mantle of the Lost Conqueror
AddToken(40638, {40507, 40513, 40518, 40524, 40530, 40548}) -- Mantle of the Lost Protector
AddToken(40639, {40419, 40465, 40470, 40494, 40502, 40557, 40568}) -- Mantle of the Lost Vanquisher
AddToken(45632, {46137, 46154, 46168, 46173, 46178, 46193}) -- Breastplate of the Wayward Conqueror
AddToken(45633, {46141, 46146, 46162, 46198, 46205, 46206}) -- Breastplate of the Wayward Protector
AddToken(45634, {46111, 46118, 46123, 46130, 46159, 46186, 46194}) -- Breastplate of the Wayward Vanquisher
AddToken(45635, {45374, 45375, 45381, 45389, 45395, 45421}) -- Chestguard of the Wayward Conqueror
AddToken(45636, {45364, 45405, 45411, 45413, 45424, 45429}) -- Chestguard of the Wayward Protector
AddToken(45637, {45335, 45340, 45348, 45354, 45358, 45368, 45396}) -- Chestguard of the Wayward Vanquisher
AddToken(45638, {46140, 46156, 46172, 46175, 46180, 46197}) -- Crown of the Wayward Conqueror
AddToken(45639, {46143, 46151, 46166, 46201, 46209, 46212}) -- Crown of the Wayward Protector
AddToken(45640, {46115, 46120, 46125, 46129, 46161, 46184, 46191}) -- Crown of the Wayward Vanquisher
AddToken(45641, {46135, 46155, 46163, 46174, 46179, 46188}) -- Gauntlets of the Wayward Conqueror
AddToken(45642, {46142, 46148, 46164, 46199, 46200, 46207}) -- Gauntlets of the Wayward Protector
AddToken(45643, {46113, 46119, 46124, 46132, 46158, 46183, 46189}) -- Gauntlets of the Wayward Vanquisher
AddToken(45644, {45370, 45376, 45383, 45387, 45392, 45419}) -- Gloves of the Wayward Conqueror
AddToken(45645, {45360, 45401, 45406, 45414, 45426, 45430}) -- Gloves of the Wayward Protector
AddToken(45646, {45337, 45341, 45345, 45351, 45355, 45397, 46131}) -- Gloves of the Wayward Vanquisher
AddToken(45647, {45372, 45377, 45382, 45386, 45391, 45417}) -- Helm of the Wayward Conqueror
AddToken(45648, {45361, 45402, 45408, 45412, 45425, 45431}) -- Helm of the Wayward Protector
AddToken(45649, {45336, 45342, 45346, 45356, 45365, 45398, 46313}) -- Helm of the Wayward Vanquisher
AddToken(45650, {45371, 45379, 45384, 45388, 45394, 45420}) -- Leggings of the Wayward Conqueror
AddToken(45651, {45362, 45403, 45409, 45416, 45427, 45432}) -- Leggings of the Wayward Protector
AddToken(45652, {45338, 45343, 45347, 45353, 45357, 45367, 45399}) -- Leggings of the Wayward Vanquisher
AddToken(45653, {46139, 46153, 46170, 46176, 46181, 46195}) -- Legplates of the Wayward Conqueror
AddToken(45654, {46144, 46150, 46169, 46202, 46208, 46210}) -- Legplates of the Wayward Protector
AddToken(45655, {46116, 46121, 46126, 46133, 46160, 46185, 46192}) -- Legplates of the Wayward Vanquisher
AddToken(45656, {46136, 46152, 46165, 46177, 46182, 46190}) -- Mantle of the Wayward Conqueror
AddToken(45657, {46145, 46149, 46167, 46203, 46204, 46211}) -- Mantle of the Wayward Protector
AddToken(45658, {46117, 46122, 46127, 46134, 46157, 46187, 46196}) -- Mantle of the Wayward Vanquisher
AddToken(45659, {45373, 45380, 45385, 45390, 45393, 45422}) -- Spaulders of the Wayward Conqueror
AddToken(45660, {45363, 45404, 45410, 45415, 45428, 45433}) -- Spaulders of the Wayward Protector
AddToken(45661, {45339, 45344, 45349, 45352, 45359, 45369, 45400}) -- Spaulders of the Wayward Vanquisher
AddToken(46052, {46320, 46321, 46322, 46323}) -- Reply-Code Alpha
AddToken(46053, {45588, 45608, 45614, 45618}) -- Reply-Code Alpha
AddToken(47242, {47753, 47754, 47755, 47756, 47757, 47778, 47779, 47780, 47781, 47782, 47983, 47984, 47985, 47986, 47987, 48077, 48078, 48079, 48080, 48081, 48133, 48134, 48135, 48136, 48137, 48163, 48164, 48165, 48166, 48167, 48208, 48209, 48210, 48211, 48212, 48223, 48224, 48225, 48226, 48227, 48255, 48256, 48257, 48258, 48259, 48285, 48286, 48287, 48288, 48289, 48316, 48317, 48318, 48319, 48320, 48346, 48347, 48348, 48349, 48350, 48376, 48377, 48378, 48379, 48380, 48430, 48446, 48450, 48452, 48454, 48481, 48482, 48483, 48484, 48485, 48538, 48539, 48540, 48541, 48542, 48575, 48576, 48577, 48578, 48579, 48607, 48608, 48609, 48610, 48611, 48637, 48638, 48639, 48640, 48641}) -- Trophy of the Crusade
AddToken(47557, {47788, 47789, 47790, 47791, 47792, 48029, 48031, 48033, 48035, 48037, 48082, 48083, 48084, 48085, 48086, 48580, 48581, 48582, 48583, 48584, 48612, 48613, 48614, 48615, 48616, 48642, 48643, 48644, 48645, 48646}) -- Regalia of the Grand Conqueror
AddToken(47558, {48260, 48261, 48262, 48263, 48264, 48290, 48291, 48292, 48293, 48294, 48321, 48322, 48323, 48324, 48325, 48351, 48352, 48353, 48354, 48355, 48381, 48382, 48383, 48384, 48385, 48433, 48447, 48451, 48453, 48455}) -- Regalia of the Grand Protector
AddToken(47559, {47758, 47759, 47760, 47761, 47762, 48138, 48139, 48140, 48141, 48142, 48168, 48169, 48170, 48171, 48172, 48203, 48204, 48205, 48206, 48207, 48228, 48229, 48230, 48231, 48232, 48486, 48487, 48488, 48489, 48490, 48543, 48544, 48545, 48546, 48547}) -- Regalia of the Grand Vanquisher
AddToken(49644, {49485, 49486, 49487}) -- Head of Onyxia
AddToken(52025, {51125, 51126, 51127, 51128, 51129, 51130, 51131, 51132, 51133, 51134, 51135, 51136, 51137, 51138, 51139, 51140, 51141, 51142, 51143, 51144, 51145, 51146, 51147, 51148, 51149, 51155, 51156, 51157, 51158, 51159, 51185, 51186, 51187, 51188, 51189}) -- Vanquisher's Mark of Sanctification
AddToken(52026, {51150, 51151, 51152, 51153, 51154, 51190, 51191, 51192, 51193, 51194, 51195, 51196, 51197, 51198, 51199, 51200, 51201, 51202, 51203, 51204, 51210, 51211, 51212, 51213, 51214, 51215, 51216, 51217, 51218, 51219}) -- Protector's Mark of Sanctification
AddToken(52027, {51160, 51161, 51162, 51163, 51164, 51165, 51166, 51167, 51168, 51169, 51170, 51171, 51172, 51173, 51174, 51175, 51176, 51177, 51178, 51179, 51180, 51181, 51182, 51183, 51184, 51205, 51206, 51207, 51208, 51209}) -- Conqueror's Mark of Sanctification
AddToken(52028, {51250, 51251, 51252, 51253, 51254, 51280, 51281, 51282, 51283, 51284, 51290, 51291, 51292, 51293, 51294, 51295, 51296, 51297, 51298, 51299, 51300, 51301, 51302, 51303, 51304, 51305, 51306, 51307, 51308, 51309, 51310, 51311, 51312, 51313, 51314}) -- Vanquisher's Mark of Sanctification
AddToken(52029, {51220, 51221, 51222, 51223, 51224, 51225, 51226, 51227, 51228, 51229, 51235, 51236, 51237, 51238, 51239, 51240, 51241, 51242, 51243, 51244, 51245, 51246, 51247, 51248, 51249, 51285, 51286, 51287, 51288, 51289}) -- Protector's Mark of Sanctification
AddToken(52030, {51230, 51231, 51232, 51233, 51234, 51255, 51256, 51257, 51258, 51259, 51260, 51261, 51262, 51263, 51264, 51265, 51266, 51267, 51268, 51269, 51270, 51271, 51272, 51273, 51274, 51275, 51276, 51277, 51278, 51279}) -- Conqueror's Mark of Sanctification