#Hubot Reminder Bot
A hubot script to schedule recurring reminders using a natural language parser

###Dependencies
  * coffee-script
  * later
  * underscore
  * moment

###Configuration
  * None

###Commands
  - ``hubot remind [me|us] to `<reminder>` <interval>`` - schedule `<reminder>` to occur at `<interval>`
  - `hubot reminder list` - List all scheduled reminders
  - `hubot reminder remove job <number>` - Removes the given reminder job
