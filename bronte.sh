#!/bin/bash
# This is messy but pretend I didn't do this
RNUM='^[0-9]+$'
# Check configuration
if [ -z $DISCORDWEBHOOK ]; then
  echo DISCORDWEBHOOK has not been defined.
  RUN=0
elif [ -z $THUNDERWEBAPI ]; then
  echo THUNDERWEBAPI has not been defined. 
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
DISCNOTIFIED="false"
# Check if target channel thread or not
if [ -z $THREADID ]; then
  URLPARAM=""
  WAITWEBHOOK=$DISCORDWEBHOOK'?wait=true'
else
  URLPARAM='?thread_id='$THREADID
  WAITWEBHOOK=$DISCORDWEBHOOK'?wait=true&thread_id='$THREADID
  echo Using thread id: $THREADID
fi

# curl was being bitchy so I just did it like this ¯\_(ツ)_/¯
function sendMsg () {
    MSG='{"username": "Bronte", "content": "'$*'"}'
    echo $MSG > msg.tmp
    curl \
        -H "Content-Type: application/json" \
        --data-binary @msg.tmp \
        $WAITWEBHOOK 2> /dev/null > response.tmp
}
function appendLastMsg () {
    MSG='{"content": "'`cat msg.tmp | jq '.content' | sed s/\"//g`' '$*'"}'
    echo $MSG > append.tmp
    PATCHWEBHOOK=$DISCORDWEBHOOK'/messages/'`cat response.tmp | jq '.id' | sed s/\"//g`$URLPARAM
    curl \
        -H "Content-Type: application/json" \
        --data-binary @append.tmp \
        -X PATCH \
        $PATCHWEBHOOK 2> /dev/null > debug.tmp
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
  # grab and process json
  curl $THUNDERWEBAPI 2>/dev/null > json.tmp
  ISTHUNDER=`cat json.tmp | jq '.isThundering'`
  HASSTORM=`cat json.tmp | jq '.hasStorm'`
  if [[ $ISTHUNDER == "true" && $HASSTORM == "true" ]]; then
    THUNDER="true"
  else
    THUNDER="false"
  fi

  # For the console spam
  STATE='('`date -R`') - Thundering: '$THUNDER'; Discord: '$DISCNOTIFIED'; isThundering: '$ISTHUNDER'; hasStorm: '$HASSTORM

  # core bot
  if [[ $THUNDER == "false" && $DISCNOTIFIED == "false" ]]; then
    echo $STATE
  elif [[ $THUNDER == "true" && $DISCNOTIFIED == "true" ]]; then
    echo $STATE
  elif [[ $THUNDER == "true" && $DISCNOTIFIED == "false" ]]; then
    echo $STATE
    echo Started thundering - $STATE >> `date -I`-log
    updateDiscTimestamp
    sendMsg 'Hey <@'$PINGID'>, a new thunderstorm started '$DISCTIMESTAMP'. '
    DISCNOTIFIED="true"
  elif [[ $THUNDER == "false" && $DISCNOTIFIED == "true" ]]; then
    echo $STATE
    echo Thunderstorm ended - $STATE >> `date -I`-log
    calcDurationTimestamp
    appendLastMsg 'The **thunderstorm is no more**. Bronte giveth, and she taketh away! *Duration approx '$ELAPSEDTIME'*'
    DISCNOTIFIED="false"
  else
    echo Script error, reinitialise and log
    echo Script Error - $STATE >> `date -I`-log
    DISCNOTIFIED="false"
    THUNDER=""
  fi

  sleep $POLLDELAY
done
echo Program terminated.