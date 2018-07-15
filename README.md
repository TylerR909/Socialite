# Socialite
This addon tracks the number of times you've grouped up with people.

This file tracks some early planning for cobbling together this addon.

## API Knowledge Base
### Key Events
* GROUP_JOINED - The player joined a group (On switch)
* GROUP_LEFT - The player left a group (Off switch)
* GROUP_ROSTER_UPDATE - This thing seems to fire several times per group join but is also the best event to track so... optimize?
* BOSS_KILL
* CHALLENGE_MODE_COMPLETE
* LFG_COMPLETION_REWARD - Fire when a random dungeon finishes and the player is awarded the completion reward. Could use as a "dungeons completed" with each player, event. Not sure if it'd run in manual groups though.
* C_Timer.After - setTimeout()

### Key API Functions
* UnitGUID - Store players by GUID
* GetPlayerInfoByGUID - WARNING: Client must have seen the GUID in that session so this is good for generating data on the fly about a player (even the mouseover) but can't be used, for example, in a summary pane
* UnitIsPlayer - Verify unit being checked isn't an NPC or something
* IsInRaid/IsInGroup
* GetNumGroupMembers
* GetInstanceInfo - Amongst its returns is an InstanceMapID. May be able to cache that ID and dynamically translate it to get around Localization.
* GetCurrentMapAreaId - Gets an ID from the current map area which can be converted back in to a localized name with other functions
* GetMapNameByID - ID to Map Name
* BNGetFriendInfo - Gets BNet ID by friendIndex

### API Types
* UnitId "partyN"/"raidN" - Functions that take a "unit" can use party1, party2, etc to specify which party member. Should make looping through party members a breeze.
* InstanceMapID - Could be used to circumnavigate Localization and store the ID people ran together. Dynamically convert to localized language ad hoc.
* friendIndex


## Statistics to Track
* Number of boss kills with this person
* Number of dungeon/LFR/etc completed with this person
* Number of PvP BGs completed with this person
* Last Seen Date (List?)

## Friend Aggregation
* Should be able to see runs with a specific toon as well as aggregate multiple runs together using BNet presenceID


## Data Shape
### Character
* GUID
* BNet presenceID (bnetIdAccount)
* Name
* Realm
* First Seen
* Last Seen
* Stats
    * Boss Kills
    * Runs Completed

### Group Session
Example: Notify when a group caps who you've seen before. If someone drops and new people join, don't re-notify about the same people, but notify about the new people.
* Members []
    * GUID
    * 

## Logic
### RegisterTallyEvents
Registers all the events on which SCL should tally an event. Could look something like:
```
local events = [
    {
        nativeEvent: "BOSS_KILL",
        pool: "BOSSES",
        handler: tallyBoss  -- Function
    },
    {
        nativeEvent: "CHALLENGE_MODE_COMPLETE",
        pool: "DUNGEONS",
        handler: tallyDungeon  -- Callback
    },
    {
        nativeEvent: "LFG_COMPLETION_AWARD",
        pool: "DUNGEONS",
        handler: tallyDungeon  -- Callback
    },
    {
        nativeEvent: "BATTLEGROUND_COMPLETED",
        pool: "BATTLEGROUNDS",
        handler: tallyBattleground  -- Callback
    }
]
```

Might not need "Pool" if a custom function is made for each type of event. Or the registrar taking in this array can pass pool as an argument to each callback to make it more dynamic.

