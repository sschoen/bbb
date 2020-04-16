#!/usr/bin/python3

#
# checkbbb.py
# Frank Schiebel frank@linuxmuster.net
# GPL v3
#

import os
import sys
import socket
import hashlib
import requests
from collections import defaultdict
from xml.dom.minidom import parse, parseString

def getApiChecksum():
    # get API Scret and strip newline
    stream = os.popen('bbb-conf --secret | grep Secret: | awk -F":" \'{print $2}\' | sed -e "s/\s*//g" | sed -e "s/\\n//g"')
    sharedsecret = stream.read().rstrip()
    # assemble querystring + apisecret
    qstringwithsecret = "getMeetings" + sharedsecret
    # return SHA1 hash as API checksum
    return hashlib.sha1(qstringwithsecret.encode('utf-8')).hexdigest()

def getMeetingData(checksum):
    fqdn = socket.getfqdn()
    fullQueryUri = "https://"+fqdn+"/bigbluebutton/api/getMeetings?checksum="+checksum
    result = requests.get(fullQueryUri)
    return(result.status_code, result.text)

(status, xml) = getMeetingData(getApiChecksum())



checkName    = "BBB"
nagiosState  = 3
numMeetings  = 0
numAttendees = 0
numWithVideo = 0
numWithVoice = 0
numListeners  = 0

if status != 200:
    checkstring = str(nagiosState) + ' ' + checkName + " HTTP return code was not 200/OK"
    print(checkstring)
    sys.exit(nagiosState)

meetingdata = parseString(xml)

returncode=meetingdata.getElementsByTagName("returncode")[0]
returncode=returncode.firstChild.wholeText

if returncode != "SUCCESS":
    checkstring = str(nagiosState) + ' ' + checkName + " API returncode was not SUCCESS"
    print(checkstring)
    sys.exit(nagiosState)

# Dict for origins
origins = defaultdict(dict)

# get numbers from active meetings
meetings=meetingdata.getElementsByTagName("meeting")
for m in meetings:
    p = m.getElementsByTagName("bbb-origin-server-name")[0]
    origin = str(p.firstChild.wholeText)

    if ( str(dict(origins[origin])) == "{}" ): 
        origins[origin]['meetings'] = 0
        origins[origin]['attendees'] = 0
        origins[origin]['video'] = 0
        origins[origin]['voice'] = 0
        origins[origin]['listen'] = 0

    numMeetings += 1
    origins[origin]["meetings"] +=1

    p = m.getElementsByTagName("participantCount")[0]
    numAttendees += int(p.firstChild.wholeText) 
    origins[origin]['attendees'] += int(p.firstChild.wholeText)

    p = m.getElementsByTagName("listenerCount")[0]
    numListeners += int(p.firstChild.wholeText) 
    origins[origin]['listen'] += int(p.firstChild.wholeText)

    p = m.getElementsByTagName("voiceParticipantCount")[0]
    numWithVoice += int(p.firstChild.wholeText) 
    origins[origin]['voice'] += int(p.firstChild.wholeText)

    p = m.getElementsByTagName("videoCount")[0]
    numWithVideo += int(p.firstChild.wholeText) 
    origins[origin]['video'] += int(p.firstChild.wholeText)



perfdata = 'numMeetings=' + str(numMeetings) + '|numAttendees=' + str(numAttendees)
perfdata += '|numWithVoice=' + str(numWithVoice) + '|numWithVideo=' + str(numWithVideo)
perfdata += '|numListeners=' + str(numListeners)

checkstring  = "0 " + checkName + " " + perfdata 
checkstring += " [ServerSum M:" + str(numMeetings) 
checkstring += " Att:" + str(numAttendees) 
checkstring += " Vid:" + str(numWithVideo) 
checkstring += " Voi:" + str(numWithVoice)
checkstring += " Lis:" + str(numListeners)
checkstring += "] "



originstats = ""
for key in origins:
    originstats += "[" + key + " M:" +str(origins[key]["meetings"])
    originstats += " Att:" + str(origins[key]["attendees"])
    originstats += " Vid:" + str(origins[key]["video"])
    originstats += " Voi:" + str(origins[key]["voice"])
    originstats += " Lis:" + str(origins[origin]["listen"])
    originstats += "] "

checkstring += originstats

print(checkstring)
sys.exit(0)



