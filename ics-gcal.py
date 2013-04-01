#!/usr/bin/python2
# vim: set fileencoding=utf-8 :
"""
ics-gcal.py (c) 2008, 2010 Matthew Ernisse <mernisse@ub3rgeek.net>
2013 updates by Alex Rodriguez

Cobbled together with help from gdata API documentation:
http://code.google.com/apis/calendar/developers_guide_python.html

To Use:
Add the following to your .mailcap and then you can simply exec the attachment
and it will get added to your google calendar.  If the event has a reminder set
it will set a reminder using your default method for 30 minutes prior to the
event. You can also override the default reminder with -r <mins> and -R.

text/calendar; ~/.mutt/ics-gcal.py -f %s; needsterminal
text/calendar; ~/.mutt/ics-gcal.py -f %s -o; copiousoutput

You may now use a configuration file to setup your username, password and
calendar. NOTE this is not actually any more secure than using the command line
in your .mailcap configuration file assuming sane permissions.

In ~/.gcal/ics-gcal.conf you may specify the following tokens:
email    = <gcal user>
password = <gcal password>
calendar = "calendar name"

If the command line has these options specified they will OVERRIDE the
config file.  None are required as long as between the config file and
the command like all required options are set.

Calendar name can be found on the calendar details page, or based
on your calendar's xml/ical links.  

If your XML link is:
http://www.google.com/calendar/feeds/yourname@gmail.com/public/basic
then your calendar name is yourname@gmail.com

Requires:
  gdata python bindings
  atom python module
  vobject python module
  Google Calendar account

  You to create the directory ~/.gcal even if you don't use the
  configuration file as the local data store is saved there.

You will probably want to set PYTHONIOENCODING to something (utf_8). This will
make sure the print statements work properly when people insert weird shit
in their descriptions.

When you view an email with an ics invite in mutt, the invite will be parsed and
displayed. You can then view the attachment to process it. The script will check
a local store to see if this invite was already processed, will check your
google calendar for conflicts, and then will prompt you for what to do.

"""
import getopt
import time
import datetime
import sys
import os
import vobject
import pytz
import re
import shelve
import codecs

from datetime import datetime
from datetime import timedelta
from gdata.calendar.service import *
from gdata.calendar.data import (CalendarEventEntry, When, CalendarWhere,
    IcalUIDProperty, SyncEventProperty)
from gdata.data import Reminder, Recurrence
from gdata.calendar import client
from pytz import timezone

"""
def replaceErrors(exc):
  print exc
  return codecs.replace_errors(exc)

codecs.register_error('strict', replaceErrors)
"""

def Usage():
  """Print usage statement

  Returns:
    None
 
  """
  print("""\
      Usage: %s [-hRo] [-c calendar] [-f file] [-p password] [-r minutes] [-u username]
  Take a vcalendar stream from a file and insert to it into a Google
  calendar

  Arguments:
  -c <calendar> - Which calendar to upload to, default = 'default'
  -f <file>     - ics file for input
  -h            - Show Usage and exit.
  -p <password> - Google Calendar password
  -r <minutes>  - Number of minutes for reminder length, default = 30
  -R            - Force adding a reminder even if the ics does not have
                        an alarm set.
  -u <username> - Google Calendar username
  -o            - Just print the calendar information

  """) % (sys.argv[0])

  return None


def printCalendar(ics, event=None):
  tz = timezone(os.environ['TZ'])
  start = getTime(ics.vevent.dtstart.value).astimezone(tz)
  end = getTime(ics.vevent.dtend.value).astimezone(tz)
  description = getAttribute(ics, "description");
  if getattr(ics.vevent, "organizer", None):
    if getattr(ics.vevent.organizer, "CN_param", None):
      organizer = "%s (%s)" % ( ics.vevent.organizer.CN_param,
          ics.vevent.organizer.value )
    else:
      organizer = ics.vevent.organizer.value
  else:
    organizer = ""
  location = getAttribute(ics, "location")
  summary = getAttribute(ics, "summary")

  # Only show current status if the event actually exists
  currentstatus = None
  if event:
    d = getLocalEvent(ics)
    if d:
      currentstatus = d["status"]

  print('Calendar Event')
  print('--------------')
  #print('Summary:     %s' % summary.encode('utf-8', 'backslashreplace'))
  print('Summary:     %s' % summary)
  print('Organizer:   %s' % organizer)
  print('Start time:  %s' % start.strftime('%a, %b %d, %Y %I:%M %p (UTC%z)'))
  print('End time:    %s' % end.strftime('%a, %b %d, %Y %I:%M %p (UTC%z)'))
  print('Location:    %s' % location)
  #print('Description:\n%s' % description.encode('utf-8', 'backslashreplace'))
  print('Description:\n%s' % description)
  if event and currentstatus:
    print
    print('This event was already processed. The status is %s. Event details:' % currentstatus)
    print('  Summary:     %s' % event.title.text)
    print('  Start time:  %s' % formatGoogleDate(event.when[0].start))
    print('  End time:    %s' % formatGoogleDate(event.when[0].end))
  return

def promptReply(ics, event):
  reply = "cancel"
  printCalendar(ics, event)
  print
 
  if event:
    res = raw_input("Update existing event (y|N)? ")
    if re.match('y', res, re.I):
      print("Event will be updated.")
      reply = "update"
  else:
    res = raw_input("(A)ccept, (R)eject, or (C)ancel this event? ")
    if re.match('a', res, re.I):
      print("Event accepted.")
      reply = "accepted"
    elif re.match('r', res, re.I):
      print("Event rejected.")
      reply = "rejected"
    else:
      print("Event ignored.")

  return reply

def getAttribute(ics, attr, default=""):
  if getattr(ics.vevent, attr, None):
    return getattr(ics.vevent, attr).value
  else:
    return default

def getTime(dt):
  if type(' ') == type(dt):
    return time.strptime(dt, "%Y%m%dT%H%M%S")
  else:
    return dt

def checkConflictingEvent(client, uri, startTime, endTime, existingid=None):
  cont = True
 
  start = startTime.strftime("%Y-%m-%dT%H:%M:%S.000Z")
  end = endTime.strftime("%Y-%m-%dT%H:%M:%S.000Z")
 
  query = gdata.calendar.client.CalendarEventQuery()
 
  # Expand the bounds a bit to find collisions
  td = timedelta(minutes=1)
  query.start_min = (startTime - td).strftime("%Y-%m-%dT%H:%M:%S.000Z")
  query.start_max = (endTime + td).strftime("%Y-%m-%dT%H:%M:%S.000Z")

  feed = client.GetCalendarEventFeed(q=query, uri=uri)
  tempfeed = ()
  if feed and len(feed.entry) > 0:
    for i, event in enumerate(feed.entry):
      if existingid != event.id.text:
        tempfeed.append(event)
 
  if len(tempfeed) > 0:
    print("The following conflicting events were found:")
    for event in enumerate(tempfeed):
      eventstart = formatGoogleDate(event.when[0].start)
      eventend = formatGoogleDate(event.when[0].end)
      print("%s from %s to %s" % (event.title.text, eventstart, eventend))

    res = raw_input("Continue (y|N)? ")
    if not re.match('y', res, re.I):
      cont = False
 
  return cont

def checkExistingEvent(client, ics):
  uri = None
  currentstatus = None
  d = getLocalEvent(ics)
  if d:
    currentstatus = d["status"]
    uri = d["uri"]
    if uri:
      return client.GetEventEntry(uri=uri)

  return None

def formatGoogleDate(date):
  tz = date[-6:]
  return datetime.strptime(date[0:-6],
      "%Y-%m-%dT%H:%M:%S.000").strftime('%a, %b %d, %Y %I:%M %p (UTC' + tz + ')')

def uploadToGoogle(ics, email, password, calendar="default", reminder=30, \
                   forceReminder=False):
  """ Upload to your Google Calendar.

  Arguments:
    ics - vobject vevent object.
    email - string, your gcal account name
    password - string, your gcal password
    calendar - string, which calendar to upload to.
    reminder - integer, number of minutes to set
         reminder for.  Default 30
    forceReminder - boolean, If true, always set a
              reminder.

  Returns:
    True on success, None on failure
  """
 
  event = None
 
  # Create calendar client
  client = gdata.calendar.client.CalendarClient(source="alexbr")
  try:
    client.ClientLogin(email, password, client.source)
  except Exception as e:
    print("Cannot login to Google Calendar: %s"  % (str(e)))
    return None
 
  # Check for existing event
  event = checkExistingEvent(client, ics)

  # Prompt for what to do
  update = False
  res = promptReply(ics, event)
  if res == "rejected" or res == "cancel":
    return None
  elif event and res == "update":
    update = True
  if not event:
    event = CalendarEventEntry()

  tz = timezone(os.environ['TZ'])
  startTime = getTime(ics.vevent.dtstart.value).astimezone(tz)
  start = startTime.strftime("%Y-%m-%dT%H:%M:%S.000")
  endTime = getTime(ics.vevent.dtend.value).astimezone(tz)
  end = endTime.strftime("%Y-%m-%dT%H:%M:%S.000")

  event.title = atom.data.Title(text=ics.vevent.summary.value)
  description = getAttribute(ics, "description")
  event.content = atom.data.Content(text=description)
  location = getAttribute(ics, "location")
  event.where.append(CalendarWhere(value=location))
  uid = getAttribute(ics, "uid")

  if getattr(ics.vevent, "rrule", None):
    try:
      event.recurrence = Recurrence(text=("%s\r\n%s\r\n%s\r\n") % (
        "DTSTART:%s" % (
          time.strftime("%Y%m%dT%H%M%S",
            ics.vevent.dtstart.value.utctimetuple())
          ),
        "DTEND:%s" % (
          time.strftime("%Y%m%dT%H%M%S",
            ics.vevent.dtend.value.utctimetuple())
          ),
        "RRULE:%s" % (
          ics.vevent.rrule.value
          )
        )
      )
    except Exception as e:
      print("Could not add Recurrence to event, %s" % (str(e)))
      return None
  else:
    if update:
      event.when[0] = When(start=start, end=end)
    else:
      event.when.append(When(start=start, end=end))


  # set a reminder if forced or it's set in the calendar
  if forceReminder:
    for when in event.when:
      when.reminder.append(Reminder(minutes=str(reminder), method="alert"))
  elif 'valarm' in ics.vevent.contents:
    for when in event.when:
      if len(when.reminder) > 0:
        when.reminder[0].minutes = str(reminder)
      else:
        when.reminder.append(Reminder(minutes=str(reminder), method="alert"))
 
  newevent = None
  uri = 'https://www.google.com/calendar/feeds/%s/private/full' % calendar

  # Check conflicts
  if update:
    cont = checkConflictingEvent(client, uri, startTime, endTime, event.id.text)
  else:
    cont = checkConflictingEvent(client, uri, startTime, endTime)
  if not cont:
    print("Calendar will not be updated.")
    return None

  if not update:
    print("Uploading event to google...")
    try:
      newevent = client.InsertEvent(event, uri)
    except Exception as e:
      print("Cannot upload event to Google Calendar: %s"  % (str(e)))
      return None
  else:
    try:
      newevent = client.Update(event)
    except Exception as e:
      print("Cannot update event in Google Calendar: %s"  % (str(e)))
      return None
   
  if newevent and uid:
    saveLocalEvent(ics, newevent, "accepted")

  print('New event inserted/updated: %s' % (newevent.id.text,))
  print('\tEvent edit URL: %s' % (newevent.GetEditLink().href,))
  print('\tEvent HTML URL: %s' % (newevent.GetHtmlLink().href,))

  return True

def saveLocalEvent(ics, event, status):
  uid = getAttribute(ics, "uid")
  if not uid:
    return None
  uid = str(uid)
  d = shelve.open(os.path.expanduser('~/.gcal/events.db'))
  if not d.has_key(uid):
    d[uid] = {}
  uiddict = d[uid]
  uiddict["uri"] = event.GetEditLink().href
  uiddict["id"] = event.id.text
  uiddict["status"] = status
  d[uid] = uiddict
  d.close()
  return

def getLocalEvent(ics):
  uid = getAttribute(ics, "uid")
  if not uid:
    return None
  uid = str(uid)
  try:
    d = shelve.open(os.path.expanduser('~/.gcal/events.db'))
    if d.has_key(uid):
      return d[uid]
    return None
  except Exception as e:
    print("Could not get event data %s" % str(e))
  finally:
    if d:
      d.close();

def Main(argv = None):
  if not argv:
    argv = sys.argv[1:]

  if not len(argv) >= 1:
    Usage()
    return 2

  try:
    optlist, args = getopt.getopt(argv, "hRou:p:f:c:r:")
  except getopt.GetoptError as e:
    print(str(e))
    Usage()
    return 2

  calendar = "default"
  email = None
  fd = None
  force = None
  password = None
  reminder = 30
  printonly = False

  try:
    fd = open(os.path.expanduser('~/.gcal/ics-gcal.conf'))
    for line in fd.readlines():
      try:
        token, value = line.split(r'=', 2)
      except ValueError:
        pass

      token = token.strip().lower()
      value = value.strip()

      if token == 'email':
        email = value  
      elif token == 'password':
        password = value
      elif token == 'calendar':
        calendar = value

    fd.close()
    fd = None

  except (OSError, IOError):
    pass

  for o,v in optlist:
    if o == "-c":
      calendar = v

    elif o == "-f":
      try:
        fd = open(v)
      except IOError as e:
        print(str(e))
        return 1
    elif o == "-h":
      Usage()
      return 0

    elif o == "-p":
      password = v

    elif o == "-r":
      reminder = int(v)

    elif o == "-R":
      force = True

    elif o == "-u":
      email = v

    elif o == "-o":
      printonly = True

  if printonly and not fd:
    print("You did not specify the required arguments (file)")
    Usage()
    return 2

  if not printonly and (not fd or not email or not password):
    print("You did not specify the required arguments (username, password, and file)")
    Usage()
    return 2

  try:
    ics = vobject.readOne(fd)
    fd.close()
  except Exception as e:
    print("Cannot parse vcal input file: %s"  % ( str(e) ))
    return 1

  if printonly:
    printCalendar(ics)
    return 0
  elif not uploadToGoogle(ics, email, password, calendar, reminder, force):
    return 1

  return 0

if __name__ == "__main__":
  sys.exit(Main(sys.argv[1:]))
