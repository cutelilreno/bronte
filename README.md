# Bronte
Simple discord bot to ping players when there's a thunderstorms in game. This script uses a json API on dynmap to check for thunderstorms.

It's best to manage this via systemd, but the script is very simple so you can run it basically any old tech. It also works fine in termux on an old android phone, or you can throw it on a raspberry pi. Configure using environment variables.

## Requirements
Scripts needs the following:
* jq - a json processor https://jqlang.github.io/jq/
* curl

## Configuration
Configuration can be done either in the bronte.conf file, or via environment variables. (You must remove bronte.conf if setting configuration via environment)

The following need to be set to configure Bronte:

**Required**

`DISCORDWEBHOOK`set to webhook url provided by discord

`THUNDERWEBAPI` set to the url for the dynmap json api - i.e. `https://yourdomain.com/up/world/worldname/0`

`PINGID` set to the discord user id or role id. (role id's must have `&` at the beginning to work)

**Optional**

`THREADID` allows you to target a specific thread in a channel. Set to thread id to use.

`POLLDELAY` The number of seconds to wait between checking for thunderstorms. (default is 60)