---@private
---@type table<string|number, InstanceInfo>
VGT._instances = {}

---@private
---@param instanceId integer
---@param instanceName string
---@param isRaid boolean
---@param x number
---@param y number
---@param continentId integer
---@return InstanceInfo
function VGT:RegisterInstance(instanceId, instanceName, isRaid, x, y, continentId)
  ---@class InstanceInfo
  local instance = {
    Name = instanceName,
    Id = instanceId,
    IsRaid = isRaid,
    IsDungeon = not isRaid,
    X = x,
    Y = y,
    ContinentId = continentId,
    ---@type EncounterInfo[]
    Encounters = {}
  };

  ---Adds an encounter to this instance
  ---@param encounterId integer
  ---@param encounterName string
  function instance:AddEncounter(encounterId, encounterName)
    ---@class EncounterInfo
    local encounter = {
      Name = encounterName,
      Id = encounterId
    };
    instance.Encounters[encounterId] = encounter;
  end

  self._instances[instanceId] = instance;
  self._instances[instanceName] = instance;

  return instance;
end

---Gets an instance by its name or id
---@param nameOrId string|integer
---@return InstanceInfo?
function VGT:GetInstance(nameOrId)
  return self._instances[nameOrId];
end

do
  local instance

  instance = VGT:RegisterInstance(533, "Naxxramas", true, 3132.7, -3731.2, 0)

  instance = VGT:RegisterInstance(309, "Zul'Gurub", true, -1206.9, -11916.2, 0)
  instance:AddEncounter(14834, "Hakkar")
  instance:AddEncounter(14510, "High Priestess Mar'li")
  instance:AddEncounter(11380, "Jin'do the Hexxer")
  instance:AddEncounter(14517, "High Priestess Jeklik")
  instance:AddEncounter(15114, "Gahz'ranka")
  instance:AddEncounter(14507, "High Priest Venoxis")
  instance:AddEncounter(15083, "Hazza'rah")
  instance:AddEncounter(11382, "Bloodlord Mandokir")
  instance:AddEncounter(14515, "High Priestess Arlokk")
  instance:AddEncounter(14509, "High Priest Thekal")

  instance = VGT:RegisterInstance(509, "Ruins of Ahn'Qiraj", true, 1502.4, -8415.7, 1)
  instance:AddEncounter(15348, "Kurinnaxx")
  instance:AddEncounter(15339, "Ossirian the Unscarred")
  instance:AddEncounter(15369, "Ayamiss the Hunter")
  instance:AddEncounter(15370, "Buru the Gorger")
  instance:AddEncounter(15341, "General Rajaxx")
  instance:AddEncounter(15340, "Moam")

  instance = VGT:RegisterInstance(409, "Molten Core", true, -1039.7, -7508.3, 0)
  instance:AddEncounter(12264, "Shazzrah")
  instance:AddEncounter(12118, "Lucifron")
  instance:AddEncounter(11988, "Golemagg the Incinerator")
  instance:AddEncounter(12098, "Sulfuron Harbinger")
  instance:AddEncounter(1198200, "Magmadar")
  instance:AddEncounter(12018, "Majordomo Executus")
  instance:AddEncounter(12259, "Gehennas")
  instance:AddEncounter(12057, "Garr")
  instance:AddEncounter(12056, "Baron Geddon")
  instance:AddEncounter(11502, "Ragnaros")

  instance = VGT:RegisterInstance(531, "Temple of Ahn'Qiraj", true, 1993.3, -8239, 1)
  instance:AddEncounter(15276, "Emperor Vek'lor")
  instance:AddEncounter(15727, "C'Thun")
  instance:AddEncounter(15275, "Emperor Vek'nilash")
  instance:AddEncounter(15517, "Ouro")
  instance:AddEncounter(15509, "Princess Huhuran")
  instance:AddEncounter(15544, "Vem")
  instance:AddEncounter(15299, "Viscidus")
  instance:AddEncounter(15511, "Lord Kri")
  instance:AddEncounter(15510, "Fankriss the Unyielding")
  instance:AddEncounter(15263, "The Prophet Skeram")
  instance:AddEncounter(15543, "Princess Yauj")
  instance:AddEncounter(15516, "Battleguard Sartura")

  instance = VGT:RegisterInstance(469, "Blackwing Lair", true, -1228.4, -7524.7, 0)
  instance:AddEncounter(12435, "Razorgore the Untamed")
  instance:AddEncounter(14020, "Chromaggus")
  instance:AddEncounter(11583, "Nefarian")
  instance:AddEncounter(11983, "Firemaw")
  instance:AddEncounter(13020, "Vaelastrasz the Corrupt")
  instance:AddEncounter(14601, "Ebonroc")
  instance:AddEncounter(11981, "Flamegor")
  instance:AddEncounter(12017, "Broodlord Lashlayer")

  instance = VGT:RegisterInstance(47, "Razorfen Kraul", false, -1664.3, -4463.3, 1)
  instance:AddEncounter(6168, "Roogug")
  instance:AddEncounter(4422, "Agathelos the Raging")
  instance:AddEncounter(4421, "Charlga Razorflank")
  instance:AddEncounter(4428, "Death Speaker Jargba")
  instance:AddEncounter(4424, "Aggem Thorncurse")
  instance:AddEncounter(4420, "Overlord Ramtusk")

  instance = VGT:RegisterInstance(109, "The Temple of Atal'Hakkar", false, -3995.4, -10176.6, 0)
  instance:AddEncounter(5710, "Jammal'an the Prophet")
  instance:AddEncounter(8443, "Avatar of Hakkar")
  instance:AddEncounter(5720, "Weaver")
  instance:AddEncounter(5713, "Gasher")
  instance:AddEncounter(5722, "Hazzas")
  instance:AddEncounter(5712, "Zolo")
  instance:AddEncounter(5716, "Zul'Lor")
  instance:AddEncounter(8580, "Atal'alarion")
  instance:AddEncounter(5715, "Hukku")
  instance:AddEncounter(5714, "Loro")
  instance:AddEncounter(5719, "Morphaz")
  instance:AddEncounter(5711, "Ogom the Wretched")
  instance:AddEncounter(5709, "Shade of Eranikus")
  instance:AddEncounter(5721, "Dreamscythe")
  instance:AddEncounter(5717, "Mijan")

  instance = VGT:RegisterInstance(429, "Dire Maul", false, 1078.4, -3520.2, 1)
  instance:AddEncounter(11487, "Magister Kalendris")
  instance:AddEncounter(13280, "Hydrospawn")
  instance:AddEncounter(14506, "Lord Hel'nurath")
  instance:AddEncounter(14323, "Guard Slip'kik")
  instance:AddEncounter(14327, "Lehtendris")
  instance:AddEncounter(14322, "Stomper Kreeg")
  instance:AddEncounter(11490, "Zevrim Thornhoof")
  instance:AddEncounter(11467, "Tsu'zee")
  instance:AddEncounter(11486, "Prince Tortheldrin")
  instance:AddEncounter(14324, "Cho'Rush the Observer")
  instance:AddEncounter(14354, "Pusillin")
  instance:AddEncounter(11496, "Immol'thar")
  instance:AddEncounter(11488, "Illyanna Ravenoak")
  instance:AddEncounter(11489, "Tendris Warpwood")
  instance:AddEncounter(11501, "King Gordok")
  instance:AddEncounter(14325, "Captain Kromcrush")
  instance:AddEncounter(14321, "Guard Fengus")
  instance:AddEncounter(11492, "Alzzin the Wildshaper")
  instance:AddEncounter(14326, "Guard Mol'dar")

  instance = VGT:RegisterInstance(249, "Onyxia's Lair", false, -3754.4, -4750.4, 1)
  instance:AddEncounter(10184, "Onyxia")

  instance = VGT:RegisterInstance(48, "Blackfathom Deeps", false, 743.4, 4246.7, 1)
  instance:AddEncounter(4832, "Twilight Lord Kelris")
  instance:AddEncounter(12902, "Lorgus Jett")
  instance:AddEncounter(4830, "Old Serra'kis")
  instance:AddEncounter(4829, "Aku'mai")
  instance:AddEncounter(4831, "Lady Sarevess")
  instance:AddEncounter(6243, "Gelihast")
  instance:AddEncounter(12876, "Baron Aquanis")
  instance:AddEncounter(4887, "Ghamoo-ra")

  instance = VGT:RegisterInstance(189, "Scarlet Monastery", false, -823.6, 2915.1, 0)
  instance:AddEncounter(3974, "Houndmaster Loksey")
  instance:AddEncounter(3975, "Herod")
  instance:AddEncounter(4542, "High Inquisitor Fairbanks")
  instance:AddEncounter(6489, "Ironspine")
  instance:AddEncounter(6487, "Arcanist Doan")
  instance:AddEncounter(4543, "Bloodmage Thalnos")
  instance:AddEncounter(6490, "Azshir the Sleepless")
  instance:AddEncounter(3983, "Interrogator Vishas")
  instance:AddEncounter(3977, "High Inquisitor Whitemane")
  instance:AddEncounter(6488, "Fallen Champion")
  instance:AddEncounter(3976, "Scarlet Commander Mograine")

  instance = VGT:RegisterInstance(33, "Shadowfang Keep", false, 1567.5, -233, 0)
  instance:AddEncounter(3865, "Shadow Charger")
  instance:AddEncounter(4279, "Odo the Blindwatcher")
  instance:AddEncounter(3864, "Fel Steed")
  instance:AddEncounter(4275, "Archmage Arugal")
  instance:AddEncounter(3914, "Rethilgore")
  instance:AddEncounter(3887, "Baron Silverlaine")
  instance:AddEncounter(3872, "Deathsworn Captain")
  instance:AddEncounter(4278, "Commander Springvale")
  instance:AddEncounter(3886, "Razorclaw the Butcher")
  instance:AddEncounter(3927, "Wolf Master Nandos")
  instance:AddEncounter(4274, "Fenrus the Devourer")

  instance = VGT:RegisterInstance(34, "The Stockade", false, 845.5, -8766.1, 0)
  instance:AddEncounter(1666, "Kam Deepfury")
  instance:AddEncounter(1717, "Hamhock")
  instance:AddEncounter(1663, "Dextren Ward")
  instance:AddEncounter(1716, "Bazil Thredd")
  instance:AddEncounter(1696, "Targorr the Dread")
  instance:AddEncounter(1720, "Bruegal Ironknuckle")

  instance = VGT:RegisterInstance(389, "Ragefire Chasm", false, -4419.2, 1815, 1)
  instance:AddEncounter(11517, "Oggleflint")
  instance:AddEncounter(11518, "Jergosh the Invoker")
  instance:AddEncounter(11519, "Bazzalan")
  instance:AddEncounter(11520, "Taragaman the Hungerer")

  instance = VGT:RegisterInstance(229, "Blackrock Spire", false, -1228.4, -7524.7, 0)
  instance:AddEncounter(10363, "General Drakkisath")
  instance:AddEncounter(10584, "Urok Doomhowl")
  instance:AddEncounter(9736, "Quartermaster Zigris")
  instance:AddEncounter(10596, "Mother Smolderweb")
  instance:AddEncounter(10899, "Goraluk Anvilcrack")
  instance:AddEncounter(10509, "Jed Runewatcher")
  instance:AddEncounter(10429, "Warchief Rend Blackhand")
  instance:AddEncounter(9237, "War Master Voone")
  instance:AddEncounter(10430, "The Beast")
  instance:AddEncounter(10268, "Gizrul the Slavener")
  instance:AddEncounter(9568, "Overlord Wyrmthalak")
  instance:AddEncounter(9816, "Pyroguard Emberseer")
  instance:AddEncounter(9236, "Shadow Hunter Vosh'gajin")
  instance:AddEncounter(9196, "Highlord Omokk")
  instance:AddEncounter(10339, "Gyth")
  instance:AddEncounter(10220, "Halycon")

  instance = VGT:RegisterInstance(230, "Blackrock Depths", false, -922.2, -7178.3, 0)
  instance:AddEncounter(9018, "High Interrogator Gerstahn")
  instance:AddEncounter(9034, "Hate'rel")
  instance:AddEncounter(9025, "Lord Roccor")
  instance:AddEncounter(10096, "High Justice Grimstone")
  instance:AddEncounter(9035, "Anger'rel")
  instance:AddEncounter(9443, "Dark Keeper Pelver")
  instance:AddEncounter(9499, "Plugger Spazzring")
  instance:AddEncounter(9041, "Warder Stilgiss")
  instance:AddEncounter(9502, "Phalanx")
  instance:AddEncounter(9019, "Emperor Dagran Thaurissan")
  instance:AddEncounter(9017, "Lord Incendius")
  instance:AddEncounter(8983, "Golem Lord Argelmach")
  instance:AddEncounter(9016, "Bael'Gar")
  instance:AddEncounter(9438, "Dark Kepper Bethek")
  instance:AddEncounter(9441, "Dark Keeper Zimrel")
  instance:AddEncounter(9938, "Magmus")
  instance:AddEncounter(9024, "Pyromancer Loregrain")
  instance:AddEncounter(9439, "Dark Keeper Uggel")
  instance:AddEncounter(9037, "Gloom'rel")
  instance:AddEncounter(9156, "Ambassador Flamelash")
  instance:AddEncounter(9033, "General Angerforge")
  instance:AddEncounter(9056, "Fineous Darkvire")
  instance:AddEncounter(9537, "Hurley Blackbreath")
  instance:AddEncounter(9038, "Seeth'rel")
  instance:AddEncounter(8929, "Princess Moira Bronzebear")
  instance:AddEncounter(9319, "Houndmaster Grebmar")
  instance:AddEncounter(9039, "Doom'rel")
  instance:AddEncounter(9543, "Ribbly Screwspigot")
  instance:AddEncounter(9040, "Dope'rel")
  instance:AddEncounter(9042, "Verek")
  instance:AddEncounter(9036, "Vile'rel")
  instance:AddEncounter(9437, "Dark Keeper Vorfalk")
  instance:AddEncounter(9442, "Dark Keeper Ofgut")

  instance = VGT:RegisterInstance(43, "Wailing Caverns", false, -2217.8, -738.5, 1)
  instance:AddEncounter(3653, "Kresh")
  instance:AddEncounter(5775, "Verdan the Everliving")
  instance:AddEncounter(3671, "Lady Anacondra")
  instance:AddEncounter(3673, "Lord Serpentis")
  instance:AddEncounter(5912, "Deviate Faerie Dragon")
  instance:AddEncounter(3670, "Lord Pythas")
  instance:AddEncounter(3654, "Mutanus the Devourer")
  instance:AddEncounter(3674, "Skum")
  instance:AddEncounter(3669, "Lord Cobrahn")

  instance = VGT:RegisterInstance(70, "Uldaman", false, -2954.6, -6066.3, 0)
  instance:AddEncounter(7228, "Ironaya")
  instance:AddEncounter(7023, "Obsidian Sentinel")
  instance:AddEncounter(6910, "Revelosh")
  instance:AddEncounter(7291, "Galgann Firehammer")
  instance:AddEncounter(7206, "Ancient Stone Keeper")
  instance:AddEncounter(6906, "Baelog")
  instance:AddEncounter(4854, "Grimlok")
  instance:AddEncounter(2748, "Archaedas")

  instance = VGT:RegisterInstance(36, "The Deadmines", false, 1675.9, -11208.7, 0)
  instance:AddEncounter(645, "Cookie")
  instance:AddEncounter(642, "Sneed's Shredder")
  instance:AddEncounter(1763, "Gilnid")
  instance:AddEncounter(639, "Edwin VanCleef")
  instance:AddEncounter(3586, "Miner Johnson")
  instance:AddEncounter(646, "Mr. Smite")
  instance:AddEncounter(647, "Captain Greenskin")
  instance:AddEncounter(644, "Rhahk'Zor")

  instance = VGT:RegisterInstance(329, "Stratholme", false, -4048.3, 3233.1, 0)
  instance:AddEncounter(10811, "Archivist Galford")
  instance:AddEncounter(10440, "Baron Rivendare")
  instance:AddEncounter(10809, "Stonespine")
  instance:AddEncounter(10437, "Nerub'enkan")
  instance:AddEncounter(10436, "Baroness Anastari")
  instance:AddEncounter(11121, "Black Guard Swordsmith")
  instance:AddEncounter(10516, "The Unforgiven")
  instance:AddEncounter(10997, "Cannon Master Willey")
  instance:AddEncounter(11143, "Postmaster Malown")
  instance:AddEncounter(11058, "Fras Siabi")
  instance:AddEncounter(10808, "Timmy the Cruel")
  instance:AddEncounter(10813, "Balnazzar")
  instance:AddEncounter(10558, "Hearthsinger Forresten")
  instance:AddEncounter(11120, "Crimson Hammersmith")
  instance:AddEncounter(10438, "Maleki the Pallid")
  instance:AddEncounter(10439, "Ramstein the Gorger")
  instance:AddEncounter(10435, "Magistrate Barthilas")
  instance:AddEncounter(11032, "Malor the Zealous")
  instance:AddEncounter(10393, "Skul")

  instance = VGT:RegisterInstance(289, "Scholomance", false, -2553.1, 1273.9, 0)
  instance:AddEncounter(10503, "Jandice Barov")
  instance:AddEncounter(10507, "The Ravenian")
  instance:AddEncounter(10502, "Lady Illucia Barov")
  instance:AddEncounter(10506, "Kirtonos the Herald")
  instance:AddEncounter(10504, "Lord Alexei Barov")
  instance:AddEncounter(10433, "Marduk Blackpool")
  instance:AddEncounter(10432, "Vectus")
  instance:AddEncounter(11261, "Doctor Theolen Krastinov")
  instance:AddEncounter(10508, "Ras Frostwhisper")
  instance:AddEncounter(10901, "Lorekeeper Polkelt")
  instance:AddEncounter(11622, "Rattlegore")
  instance:AddEncounter(10505, "Instructor Malicia")
  instance:AddEncounter(1853, "Darkmaster Gandling")

  instance = VGT:RegisterInstance(209, "Zul'Farrak", false, -2890.6, -6795.6, 1)
  instance:AddEncounter(10080, "Sandarr Dunereaver")
  instance:AddEncounter(7795, "Hydromancer Velratha")
  instance:AddEncounter(8127, "Antu'sul")
  instance:AddEncounter(7604, "Sergeant Bly")
  instance:AddEncounter(7797, "Ruuzlu")
  instance:AddEncounter(7272, "Theka the Martyr")
  instance:AddEncounter(10081, "Dustwraith")
  instance:AddEncounter(7796, "Nekrum Gutchewer")
  instance:AddEncounter(7271, "Witch Doctor Zum'rah")
  instance:AddEncounter(7275, "Shadowpriest Sezz'ziz")
  instance:AddEncounter(7267, "Chief Ukorz Sandscalp")
  instance:AddEncounter(10082, "Zerills")

  instance = VGT:RegisterInstance(349, "Maraudon", false, 2614.2, -1468.2, 1)
  instance:AddEncounter(13282, "Noxxion")
  instance:AddEncounter(12258, "Razorlash")
  instance:AddEncounter(12225, "Celebras the Cursed")
  instance:AddEncounter(13596, "Rotgrip")
  instance:AddEncounter(12201, "Princess Theradas")
  instance:AddEncounter(13601, "Tinkerer Gizlock")
  instance:AddEncounter(12203, "Landslide")
  instance:AddEncounter(12236, "Lord Vyletongue")

  instance = VGT:RegisterInstance(90, "Gnomeregan", false, 927.7, -5162.6, 0)
  instance:AddEncounter(6229, "Crowd Pummeler 9-60")
  instance:AddEncounter(7800, "Mekgineer Thermaplugg")
  instance:AddEncounter(6235, "Electrocutioner 6000")
  instance:AddEncounter(6228, "Dark Iron Ambassador")
  instance:AddEncounter(7361, "Grubbis")
  instance:AddEncounter(7079, "Viscous Fallout")

  instance = VGT:RegisterInstance(129, "Razorfen Downs", false, -2524.2, -4659.6, 1)
  instance:AddEncounter(7357, "Mordresh Fire Eye")
  instance:AddEncounter(7354, "Ragglesnout")
  instance:AddEncounter(7358, "Amnennar the Coldbringer")
  instance:AddEncounter(7355, "Tuten'kash")
  instance:AddEncounter(8567, "Glutton")
  instance:AddEncounter(7356, "Plaguemaw the Rotting")
end

-- special thanks to:
-- Grogazm, Puggly, Dirka, Celestine, Diebin, Lirah, Kählan, Deaddreamer, Hangingshoe
