Doesn't allow players to set some items as quick keys

Based on code by [David Cernat](https://github.com/davidcernat) and [Learwolf](https://github.com/Learwolf).

Requires [DataManager](https://github.com/tes3mp-scripts/DataManager)

Has to be `require`d before any of the modules that use it.

You can find the configuration file in `server/data/custom/__config_QuickKeyCleaner.json` after first server launch.
* `removeRefIds` array of `refId`s that you want to be restricted. Default `[]`.
* `restrictedCells` array of cell names in which players will always have empty quick keys. Default `[]`.
* `hotkeyPlaceholder`  
  * `type` type of permanent custom record used for the item replacing restricted hotkey items. Default `miscellaneous`.
  * `refId` of the placeholder item. Default `hotkey_placeholder`.
  * `name` display name of the placeholder item. Default `Empty`.
  * `icon` of the placeholder item. Default `m\misc_dwrv_Ark_cube00.tga` (dwemer puzzle box).

Using it in your modules
---
Methods:
* `registerFilter(func)` add a filter function that will be called every time a `refId` is checked for being restricted. If the function returns false for a `refId`, the item will be considered restricted.
* `banItem(refId)` add an item to the restricted list dynamically. Does not change the config file and is not saved between restarts.
* `unbanItem(refId)` remove an item from the restricted list dynamically. Does not change the config file and is not saved between restarts.
* `filterQuickKeys(pid)` checks player data for restricted quick keys and clears them.
* `clearSlots(pid, slots)` clears quick key slots in the array `slots` for given user.
