local _, ns = ...

-- Zone-map percentages from the user-installed Leatrix Maps Forever POI list.
-- This table contains locations, names and faction labels, not its artwork.
ns.POIData = {
    [1411] = {
        { kind = "spirit", x = 44.2, y = 69.4, name = "Spirit Healer", faction = "horde" },
        { kind = "spirit", x = 47, y = 17.5, name = "Spirit Healer", faction = "horde" },
        { kind = "spirit", x = 53.5, y = 44.5, name = "Spirit Healer", faction = "horde" },
        { kind = "spirit", x = 57.5, y = 73.2, name = "Spirit Healer", faction = "horde" },
    },
    [1412] = {
        { kind = "spirit", x = 42.6, y = 78, name = "Spirit Healer", faction = "horde" },
        { kind = "spirit", x = 46.5, y = 55.5, name = "Spirit Healer", faction = "horde" },
    },
    [1413] = {
        { kind = "flight", x = 44.5, y = 59.1, name = "Camp Taurajo", faction = "horde" },
        { kind = "flight", x = 51.5, y = 30.4, name = "Crossroads", faction = "horde" },
        { kind = "flight", x = 63.1, y = 37.1, name = "Ratchet", faction = "neutral" },
        { kind = "spirit", x = 45.2, y = 61, name = "Spirit Healer", faction = "horde" },
        { kind = "spirit", x = 50.7, y = 32.5, name = "Spirit Healer", faction = "horde" },
        { kind = "spirit", x = 60.2, y = 39.8, name = "Spirit Healer", faction = "neutral" },
    },
    [1416] = {
    },
    [1417] = {
        { kind = "flight", x = 45.8, y = 46.1, name = "Refuge Pointe", faction = "alliance" },
        { kind = "flight", x = 73.1, y = 32.6, name = "Hammerfall", faction = "horde" },
        { kind = "spirit", x = 48.7, y = 55.5, name = "Spirit Healer", faction = "alliance" },
    },
    [1418] = {
        { kind = "flight", x = 4.1, y = 44.9, name = "Kargath", faction = "horde" },
        { kind = "spirit", x = 8.2, y = 55.5, name = "Spirit Healer", faction = "neutral" },
        { kind = "spirit", x = 56.9, y = 24.5, name = "Spirit Healer", faction = "neutral" },
    },
    [1419] = {
        { kind = "flight", x = 65.5, y = 24.4, name = "Nethergarde Keep", faction = "alliance" },
        { kind = "spirit", x = 51, y = 12.2, name = "Spirit Healer", faction = "neutral" },
    },
    [1420] = {
        { kind = "spirit", x = 31.2, y = 64.8, name = "Spirit Healer", faction = "horde" },
        { kind = "spirit", x = 56.2, y = 49.4, name = "Spirit Healer", faction = "horde" },
        { kind = "spirit", x = 79, y = 40.8, name = "Spirit Healer", faction = "neutral" },
        { kind = "spirit", x = 82, y = 69.5, name = "Spirit Healer", faction = "neutral" },
    },
    [1421] = {
        { kind = "flight", x = 45.6, y = 42.4, name = "The Sepulcher", faction = "horde" },
        { kind = "spirit", x = 44.2, y = 41.5, name = "Spirit Healer", faction = "horde" },
    },
    [1422] = {
        { kind = "flight", x = 42.9, y = 85, name = "Chillwind Camp", faction = "alliance" },
        { kind = "spirit", x = 45.5, y = 85.5, name = "Spirit Healer", faction = "alliance" },
        { kind = "spirit", x = 65.5, y = 74.6, name = "Spirit Healer", faction = "neutral" },
    },
    [1423] = {
        { kind = "flight", x = 71.7, y = 49.6, name = "Light's Hope Chapel", faction = "alliance" },
        { kind = "flight", x = 70.4, y = 47.6, name = "Light's Hope Chapel", faction = "horde" },
        { kind = "spirit", x = 38.2, y = 70.5, name = "Spirit Healer", faction = "neutral" },
        { kind = "spirit", x = 39, y = 92.5, name = "Spirit Healer", faction = "neutral" },
        { kind = "spirit", x = 47.2, y = 44.4, name = "Spirit Healer", faction = "neutral" },
        { kind = "spirit", x = 80, y = 64.5, name = "Spirit Healer", faction = "neutral" },
    },
    [1424] = {
        { kind = "flight", x = 49.4, y = 52.1, name = "Southshore", faction = "alliance" },
        { kind = "flight", x = 60.2, y = 18.8, name = "Tarren Mill", faction = "horde" },
        { kind = "spirit", x = 51.6, y = 52.5, name = "Spirit Healer", faction = "alliance" },
        { kind = "spirit", x = 63.5, y = 19.5, name = "Spirit Healer", faction = "horde" },
    },
    [1425] = {
        { kind = "flight", x = 11.1, y = 46.1, name = "Aerie Peak", faction = "alliance" },
        { kind = "flight", x = 81.7, y = 81.9, name = "Revantusk Village", faction = "horde" },
        { kind = "spirit", x = 16.8, y = 44.6, name = "Spirit Healer", faction = "alliance" },
        { kind = "spirit", x = 60.5, y = 38.6, name = "Spirit Healer", faction = "neutral" },
        { kind = "spirit", x = 62, y = 26.8, name = "Spirit Healer", faction = "neutral" },
        { kind = "spirit", x = 72.6, y = 68, name = "Spirit Healer", faction = "neutral" },
    },
    [1426] = {
        { kind = "spirit", x = 29.5, y = 69.8, name = "Spirit Healer", faction = "alliance" },
        { kind = "spirit", x = 47, y = 55, name = "Spirit Healer", faction = "alliance" },
        { kind = "spirit", x = 54.2, y = 39, name = "Spirit Healer", faction = "alliance" },
    },
    [1427] = {
        { kind = "flight", x = 37.9, y = 30.4, name = "Thorium Point", faction = "alliance" },
        { kind = "flight", x = 34.8, y = 30.6, name = "Thorium Point", faction = "horde" },
        { kind = "spirit", x = 35.5, y = 22.6, name = "Spirit Healer", faction = "neutral" },
    },
    [1428] = {
        { kind = "flight", x = 84.4, y = 68.3, name = "Morgan's Vigil", faction = "alliance" },
        { kind = "flight", x = 65.6, y = 24.2, name = "Flame Crest", faction = "horde" },
        { kind = "spirit", x = 63.2, y = 23.5, name = "Spirit Healer", faction = "horde" },
    },
    [1429] = {
        { kind = "spirit", x = 39.5, y = 60.5, name = "Spirit Healer", faction = "alliance" },
        { kind = "spirit", x = 49.5, y = 43.4, name = "Spirit Healer", faction = "alliance" },
        { kind = "spirit", x = 83.5, y = 69.5, name = "Spirit Healer", faction = "alliance" },
    },
    [1430] = {
        { kind = "spirit", x = 40, y = 75.3, name = "Spirit Healer", faction = "neutral" },
    },
    [1431] = {
        { kind = "flight", x = 77.6, y = 44.4, name = "Darkshire", faction = "alliance" },
        { kind = "spirit", x = 20, y = 49.4, name = "Spirit Healer", faction = "alliance" },
        { kind = "spirit", x = 44.8, y = 67.2, name = "Spirit Healer", faction = "alliance" },
        { kind = "spirit", x = 47.8, y = 45.6, name = "Spirit Healer", faction = "alliance" },
        { kind = "spirit", x = 75, y = 59, name = "Spirit Healer", faction = "alliance" },
    },
    [1432] = {
        { kind = "flight", x = 33.9, y = 50.8, name = "Thelsamar", faction = "alliance" },
        { kind = "spirit", x = 32.5, y = 46.7, name = "Spirit Healer", faction = "alliance" },
    },
    [1433] = {
        { kind = "flight", x = 25.3, y = 59, name = "Lakeshire", faction = "alliance" },
        { kind = "spirit", x = 20.8, y = 56.5, name = "Spirit Healer", faction = "alliance" },
    },
    [1434] = {
        { kind = "flight", x = 27.5, y = 77.7, name = "Booty Bay", faction = "alliance" },
        { kind = "flight", x = 26.8, y = 77, name = "Booty Bay", faction = "horde" },
        { kind = "flight", x = 32.5, y = 29.3, name = "Grom'gol", faction = "horde" },
        { kind = "spirit", x = 30, y = 73, name = "Spirit Healer", faction = "neutral" },
        { kind = "spirit", x = 38.4, y = 8.8, name = "Spirit Healer", faction = "neutral" },
    },
    [1435] = {
        { kind = "flight", x = 46.1, y = 54.7, name = "Stonard", faction = "horde" },
        { kind = "spirit", x = 50.2, y = 62.2, name = "Spirit Healer", faction = "horde" },
    },
    [1436] = {
        { kind = "flight", x = 56.6, y = 52.7, name = "Sentinel Hill", faction = "alliance" },
        { kind = "spirit", x = 51.6, y = 49.6, name = "Spirit Healer", faction = "alliance" },
    },
    [1437] = {
        { kind = "flight", x = 9.5, y = 59.7, name = "Menethil Harbor", faction = "alliance" },
        { kind = "spirit", x = 11.5, y = 43.4, name = "Spirit Healer", faction = "neutral" },
        { kind = "spirit", x = 49.5, y = 41.5, name = "Spirit Healer", faction = "neutral" },
    },
    [1438] = {
        { kind = "flight", x = 58.4, y = 93.9, name = "Rut'theran Village", faction = "alliance" },
        { kind = "spirit", x = 56.2, y = 63.2, name = "Spirit Healer", faction = "alliance" },
        { kind = "spirit", x = 58.7, y = 42.5, name = "Spirit Healer", faction = "alliance" },
    },
    [1439] = {
        { kind = "flight", x = 36.4, y = 45.6, name = "Auberdine", faction = "alliance" },
        { kind = "spirit", x = 41.8, y = 36.5, name = "Spirit Healer", faction = "alliance" },
        { kind = "spirit", x = 43.5, y = 92.3, name = "Spirit Healer", faction = "neutral" },
    },
    [1440] = {
        { kind = "flight", x = 34.5, y = 48, name = "Astranaar", faction = "alliance" },
        { kind = "flight", x = 73.3, y = 61.7, name = "Splintertree Post", faction = "horde" },
        { kind = "flight", x = 12.2, y = 33.8, name = "Zoram'gar Outpost", faction = "horde" },
        { kind = "spirit", x = 17.8, y = 11, name = "Spirit Healer", faction = "neutral" },
        { kind = "spirit", x = 22.2, y = 28.2, name = "Spirit Healer", faction = "horde" },
        { kind = "spirit", x = 40.2, y = 53, name = "Spirit Healer", faction = "alliance" },
        { kind = "spirit", x = 51.5, y = 63.2, name = "Spirit Healer", faction = "neutral" },
        { kind = "spirit", x = 80.6, y = 58, name = "Spirit Healer", faction = "horde" },
        { kind = "spirit", x = 84.2, y = 56.8, name = "Spirit Healer", faction = "horde" },
        { kind = "spirit", x = 93.2, y = 42.2, name = "Spirit Healer", faction = "neutral" },
    },
    [1441] = {
        { kind = "flight", x = 45, y = 49.1, name = "Freewind Post", faction = "horde" },
        { kind = "spirit", x = 30.5, y = 23.5, name = "Spirit Healer", faction = "neutral" },
        { kind = "spirit", x = 69.1, y = 53.5, name = "Spirit Healer", faction = "neutral" },
    },
    [1442] = {
        { kind = "flight", x = 36.5, y = 7.2, name = "Stonetalon Peak", faction = "alliance" },
        { kind = "flight", x = 45.2, y = 59.9, name = "Sun Rock Retreat", faction = "horde" },
        { kind = "spirit", x = 57.5, y = 62, name = "Spirit Healer", faction = "neutral" },
    },
    [1443] = {
        { kind = "flight", x = 64.7, y = 10.4, name = "Nijel's Point", faction = "alliance" },
        { kind = "flight", x = 21.6, y = 74, name = "Shadowprey Village", faction = "horde" },
        { kind = "spirit", x = 50.2, y = 62.8, name = "Spirit Healer", faction = "neutral" },
    },
    [1444] = {
        { kind = "flight", x = 30.3, y = 43.3, name = "Feathermoon", faction = "alliance" },
        { kind = "flight", x = 89.5, y = 45.9, name = "Thalanaar", faction = "alliance" },
        { kind = "flight", x = 75.4, y = 44.3, name = "Camp Mojache", faction = "horde" },
        { kind = "spirit", x = 31.5, y = 48, name = "Spirit Healer", faction = "alliance" },
        { kind = "spirit", x = 44, y = 7.4, name = "Spirit Healer", faction = "neutral" },
        { kind = "spirit", x = 50.4, y = 13.4, name = "Spirit Healer", faction = "neutral" },
        { kind = "spirit", x = 54.8, y = 47.6, name = "Spirit Healer", faction = "neutral" },
        { kind = "spirit", x = 73, y = 44.8, name = "Spirit Healer", faction = "horde" },
    },
    [1445] = {
        { kind = "flight", x = 67.5, y = 51.2, name = "Theramore", faction = "alliance" },
        { kind = "flight", x = 35.6, y = 31.8, name = "Brackenwall Village", faction = "horde" },
        { kind = "spirit", x = 39.6, y = 30.8, name = "Spirit Healer", faction = "horde" },
        { kind = "spirit", x = 63.5, y = 43, name = "Spirit Healer", faction = "alliance" },
    },
    [1446] = {
        { kind = "flight", x = 51, y = 29.3, name = "Gadgetzan", faction = "alliance" },
        { kind = "flight", x = 51.6, y = 25.5, name = "Gadgetzan", faction = "horde" },
        { kind = "spirit", x = 54, y = 28.6, name = "Spirit Healer", faction = "neutral" },
    },
    [1447] = {
        { kind = "flight", x = 11.9, y = 77.5, name = "Talrendis Point", faction = "alliance" },
        { kind = "flight", x = 22, y = 49.7, name = "Valormok", faction = "horde" },
        { kind = "spirit", x = 14.5, y = 78.5, name = "Spirit Healer", faction = "alliance" },
        { kind = "spirit", x = 54.2, y = 71.4, name = "Spirit Healer", faction = "neutral" },
        { kind = "spirit", x = 70.4, y = 15.6, name = "Spirit Healer", faction = "neutral" },
    },
    [1448] = {
        { kind = "flight", x = 62.5, y = 24.2, name = "Talonbranch Glade", faction = "alliance" },
        { kind = "flight", x = 34.4, y = 53.9, name = "Bloodvenom Post", faction = "horde" },
        { kind = "spirit", x = 49.5, y = 30.6, name = "Spirit Healer", faction = "neutral" },
        { kind = "spirit", x = 56.2, y = 86.6, name = "Spirit Healer", faction = "neutral" },
    },
    [1449] = {
        { kind = "flight", x = 45.3, y = 6, name = "Marshal's Refuge", faction = "neutral" },
        { kind = "spirit", x = 80, y = 49.8, name = "Spirit Healer", faction = "neutral" },
    },
    [1450] = {
        { kind = "flight", x = 47.9, y = 67.1, name = "Moonglade", faction = "alliance" },
        { kind = "flight", x = 32.2, y = 66.3, name = "Moonglade", faction = "horde" },
        { kind = "spirit", x = 62, y = 69.5, name = "Spirit Healer", faction = "neutral" },
    },
    [1451] = {
        { kind = "flight", x = 50.7, y = 34.6, name = "Cenarion Hold", faction = "alliance" },
        { kind = "flight", x = 48.8, y = 36.7, name = "Cenarion Hold", faction = "horde" },
        { kind = "spirit", x = 28, y = 87.5, name = "Spirit Healer", faction = "neutral" },
        { kind = "spirit", x = 47, y = 38.5, name = "Spirit Healer", faction = "neutral" },
        { kind = "spirit", x = 80.6, y = 19.8, name = "Spirit Healer", faction = "neutral" },
    },
    [1452] = {
        { kind = "flight", x = 62.3, y = 36.6, name = "Everlook", faction = "alliance" },
        { kind = "flight", x = 60.5, y = 36.3, name = "Everlook", faction = "horde" },
        { kind = "spirit", x = 61.2, y = 34.8, name = "Spirit Healer", faction = "neutral" },
    },
    [1453] = {
        { kind = "flight", x = 71.6, y = 72.3, name = "Stormwind", faction = "alliance" },
    },
    [1454] = {
        { kind = "flight", x = 45.3, y = 63.7, name = "Orgrimmar", faction = "horde" },
    },
    [1455] = {
        { kind = "flight", x = 55.9, y = 47.9, name = "Ironforge", faction = "alliance" },
    },
    [1456] = {
        { kind = "flight", x = 46.7, y = 49.9, name = "Thunder Bluff", faction = "horde" },
        { kind = "spirit", x = 56.5, y = 17.9, name = "Spirit Healer", faction = "horde" },
    },
    [1457] = {
        { kind = "spirit", x = 77.2, y = 26.7, name = "Spirit Healer", faction = "alliance" },
    },
    [1458] = {
        { kind = "flight", x = 63.1, y = 48.3, name = "Undercity", faction = "horde" },
        { kind = "spirit", x = 67.7, y = 14.2, name = "Spirit Healer", faction = "horde" },
    },
    [2482] = {
        { kind = "flight", x = 68.6, y = 44.1, name = "Summit of Eternity", faction = "neutral" },
        { kind = "flight", x = 55.1, y = 82.5, name = "Tainted Foothills", faction = "neutral" },
    },
    [2521] = {
    },
    [2548] = {
        { kind = "flight", x = 60.6, y = 81.6, name = "Farholde Keep", faction = "alliance" },
        { kind = "flight", x = 59.6, y = 45.1, name = "Rog'mar", faction = "horde" },
    },
}
