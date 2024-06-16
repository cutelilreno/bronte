# Bronte
Simple discord bot to ping players when there's a thunderstorms in game. This script uses a json API on a modifed dynmap to check `hasStorm` and `isThundering` json keys are both true.

It's best to manage this via systemd, but the script is very simple so you can run it basically any old tech. It also works fine in termux on an old android phone, or you can throw it on a raspberry pi. Configure using environment variables.

## Requirements
Scripts needs the following:
* jq - a json processor https://jqlang.github.io/jq/
* curl

## Configuration
The following environment variables need to be set to configure the script.

**Required**

`DISCORDWEBHOOK`set to webhook url provided by discord

`THUNDERWEBAPI` set to the url for the dynmap json api.

`PINGID` set to the discord user id or role id. (role id's must have `&` at the beginning to work)

**Optional**

`THREADID` allows you to target a specific thread in a channel. Set to thread id to use.

`POLLDELAY` The number of seconds to wait between checking for thunderstorms. (default is 60)

## License
Copyright (c) 2024 Jamie W (cutelilreno/cuddlyMonster)

Permission to use, copy, modify, and distribute this software for any
purpose with or without fee is hereby granted, provided that the above
copyright notice and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.