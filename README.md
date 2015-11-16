#Hubot Reminder Bot
A hubot script to setup reminders using cron time

###Dependencies
  * coffee-script
  * cron
  * underscore
  * moment

###Configuration
  * None

###Commands
 - `hubot remind [me] to <reminder> at <crontime>` - Setup <reminder> to occur at <crontime> interval
 - `hubot reminder list` - List all the pending reminders
 - `hubot reminder remove job <number>` - Removes the given reminder job

###Cron Ranges
Internally this uses [node-cron](https://github.com/ncb000gt/node-cron)

When specifying your cron values you'll need to make sure that your values fall within the ranges. For instance, some cron's use a 0-7 range for the day of week where both 0 and 7 represent Sunday. We do not.

  * Seconds: 0-59
  * Minutes: 0-59
  * Hours: 0-23
  * Day of Month: 1-31
  * Months: 0-11
  * Day of Week: 0-6
