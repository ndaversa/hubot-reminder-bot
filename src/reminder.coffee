# Description:
# A hubot script to schedule recurring reminders using a natural language parser
#
# Dependencies:
# - coffee-script
# - later
# - underscore
# - moment
#
# Configuration:
# None
#
# Commands:
#   hubot remind [me|us] to `<reminder>` <interval> - schedule <reminder> to occur at <interval>
#   hubot reminder list - List all scheduled reminders
#   hubot reminder remove <number> - Removes the scheduled reminder
#
# Author:
#   ndaversa

_ = require 'underscore'
moment = require 'moment'
later = require 'later'

later.date.localTime()
scheduled = []

module.exports = (robot) ->

  create = (job) ->
    sched = later.parse.text job.time
    later.setInterval (-> run job ), sched

  run = (job) ->
    robot.adapter.send room: job.room, job.text

  getReminders = () ->
    robot.brain.get('reminders') or []

  save = (reminders) ->
    robot.brain.set 'reminders', reminders

  schedule = (text, room, interval) ->
    reminders = getReminders()
    reminder =
      id: Date.now()
      text: text
      room: room
      time: interval
    scheduled[reminder.id] = create reminder
    reminders.push reminder
    save reminders
    return reminder

  isValid = (text) ->
    sched = later.parse.text text
    return sched.error is -1

  remove = (number, room) ->
    reminders = getReminders()
    reminder = reminders[number]

    if reminder
      if scheduled[reminder.id]
        scheduled[reminder.id].clear()
        delete scheduled[reminder.id]
      scheduled = _(scheduled).compact()

      delete reminders[number]
      reminders = _(reminders).compact()
      save reminders

      return yes
    return no

  robot.respond /(?:remind|reminder|reminders) list( all)?/i, (msg) ->
    [ __, all ] = msg.match
    room = if all then undefined else msg.message.room
    message = ""

    for reminder, index in getReminders()
      if not room or room and room is reminder.room
        sched = later.parse.text reminder.time
        next = moment later.schedule(sched).next(1, Date.now())
        message += "#{index}) Reminder to `#{reminder.text}` has been scheduled to run in <##{reminder.room}> #{reminder.time} and will next run #{next.fromNow()}\n"
    message = "No reminders have been scheduled" if not message

    robot.messageRoom msg.message.room, message
    msg.finish()

  robot.respond /(?:remind|reminder|reminders) (?:remove|delete|cancel) (\d)/i, (msg) ->
    [ __, id ] = msg.match
    if remove id, msg.message.room
      msg.reply "Reminder ##{id} successfully removed"
    else
      msg.reply "Sorry I'm unable to remove reminder ##{id}"
    msg.finish()

  robot.respond /(?:remind|reminder|reminders)(?: me| us)? to\s*`([^]+)`\s*([^]+)/i, (msg) ->
    [ __, text, time ] = msg.match
    room = msg.message.room

    if isValid time
      reminder = schedule text, room, time
      sched = later.parse.text time
      next = moment later.schedule(sched).next(1, Date.now())
      msg.reply "Reminder ##{getReminders().length - 1} has been scheduled to run in <##{room}> #{time} and will next run #{next.fromNow()}"
    else
      msg.reply "Sorry I don't understand when to set the reminder for :cry:"
    msg.finish()

  robot.brain.once 'loaded', ->
    scheduled[reminder.id] = create reminder for reminder in getReminders()
