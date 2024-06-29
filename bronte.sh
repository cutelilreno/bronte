#!/usr/bin/env bash
cd $(dirname $0)
RNUM='^[0-9]+$'
# Check configuration
if [ -f ./bronte.conf ]; then
  source bronte.conf
  echo Using conf file
fi
if [ -z $DISCORDWEBHOOK ]; then
  echo DISCORDWEBHOOK has not been defined.
  RUN=0
elif [ -z $DYNMAPAPI ]; then
  echo DYNMAPAPI has not been defined. 
  RUN=0
elif [ -z $PINGID ]; then
  echo PINGID has not been defined.
  RUN=0
else
  RUN=1
fi
if [ -z $POLLDELAY ]; then
  echo POLLDELAY not set, using default 60 seconds.
  POLLDELAY=60
elif [[ $POLLDELAY =~ $RNUM ]]; then
  echo Waiting $POLLDELAY seconds between thunder checks.
else
  RUN=0
  echo POLLDELAY is not set to a numerical value
fi

# Initialisations
DISCFLAG="false"
# Check if target is a channel thread or not
if [ -z $THREADID ]; then
  URLPARAM=""
  WAITWEBHOOK=$DISCORDWEBHOOK'?wait=true'
else
  URLPARAM='?thread_id='$THREADID
  WAITWEBHOOK=$DISCORDWEBHOOK'?wait=true&thread_id='$THREADID
  echo Using thread id: $THREADID
fi
# Prep Directories if missing
[ ! -d "./logs" ] && mkdir ./logs
[ ! -d "./tmp" ] && mkdir ./tmp

# curl was being bitchy so I just did it like this ¯\_(ツ)_/¯
function sendMsg () {
    MSG='{"username": "Bronte", "content": "'$*'"}'
    echo $MSG > ./tmp/msg.tmp
    curl \
        -H "Content-Type: application/json" \
        --data-binary @./tmp/msg.tmp \
        $WAITWEBHOOK 2> /dev/null > ./tmp/response.tmp
}
function appendLastMsg () {
    MSG='{"content": "'`cat ./tmp/msg.tmp | jq '.content' | sed s/\"//g`' '$*'"}'
    echo $MSG > ./tmp/append.tmp
    PATCHWEBHOOK=$DISCORDWEBHOOK'/messages/'`cat ./tmp/response.tmp | jq '.id' | sed s/\"//g`$URLPARAM
    curl \
        -H "Content-Type: application/json" \
        --data-binary @./tmp/append.tmp \
        -X PATCH \
        $PATCHWEBHOOK 2> /dev/null > ./tmp/debug.tmp
}
function updateDiscTimestamp () {
    TIMESTAMP=`date -u +%s`
    DISCTIMESTAMP="<t:"$TIMESTAMP":R>"
}
function calcDurationTimestamp () {
    local SUBTRACT=$((`date -u +%s`-$TIMESTAMP))
    ELAPSEDTIME=`date -d@$SUBTRACT -u +%Hh%Mm`
}

# Main program loop, and i'll just manage this via systemd
while [ $RUN = 1 ]
do
  # grab and process json from dynmap
  curl $DYNMAPAPI 2>/dev/null > ./tmp/json.tmp
  ISTHUNDER=`cat ./tmp/json.tmp | jq '.isThundering'`
  HASSTORM=`cat ./tmp/json.tmp | jq '.hasStorm'`
  if [[ $ISTHUNDER == "true" && $HASSTORM == "true" ]]; then
    THUNDER="true"
  else
    THUNDER="false"
  fi

  # For the logs/console spam
  STATE='('`date -R`') - Thundering: '$THUNDER'; Discord: '$DISCFLAG'; isThundering: '$ISTHUNDER'; hasStorm: '$HASSTORM

  # core bot
  if [[ $THUNDER == "false" && $DISCFLAG == "false" ]]; then
    echo $STATE > /dev/null # decided to mute this
  elif [[ $THUNDER == "true" && $DISCFLAG == "true" ]]; then
    echo $STATE > /dev/null # decided to mute this
  elif [[ $THUNDER == "true" && $DISCFLAG == "false" ]]; then
    echo $STATE
    echo Started thundering - $STATE >> ./logs/`date -I`-log
    updateDiscTimestamp
    sendMsg 'Hey <@'$PINGID'>, a new thunderstorm started '$DISCTIMESTAMP'. '
    DISCFLAG="true"
  elif [[ $THUNDER == "false" && $DISCFLAG == "true" ]]; then
    echo $STATE
    echo Thunderstorm ended - $STATE >> ./logs/`date -I`-log
    calcDurationTimestamp
    appendLastMsg 'The __**thunderstorm is no more**__. Bronte giveth, and she taketh away! *Duration approx '$ELAPSEDTIME'*'
    DISCFLAG="false"
  else
    echo Script error, reinitialise and log
    echo Script Error - $STATE >> ./logs/`date -I`-log
    DISCFLAG="false"
  fi

  sleep $POLLDELAY
done
echo Program terminated.
