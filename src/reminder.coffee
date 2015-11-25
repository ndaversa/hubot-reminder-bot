# Description:
# A hubot script to setup reminders using a natural language parser
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
#   hubot remind [me|us] to `<reminder>` <interval> - Setup <reminder> to occur at <interlval>
#   hubot reminder list - List all the pending reminders
#   hubot reminder remove job <number> - Removes the given reminder job
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
    robot.adapter.customMessage
      channel: job.room
      text: job.text

  getJobs = ->
    robot.brain.get('reminder-jobs') or []

  saveJobs = (jobs) ->
    robot.brain.set 'reminder-jobs', jobs

  setupJob = (text, room, cronTime) ->
    jobs = getJobs()
    job =
      id: Date.now()
      text: text
      room: room
      time: cronTime
    scheduled[job.id] = create job
    jobs.push job
    saveJobs jobs
    return job

  validSchedule = (text) ->
    sched = later.parse.text text
    return sched.error is -1

  removeJob = (number) ->
    jobs = getJobs()
    job = jobs[number]

    if job
      if scheduled[job.id]
        scheduled[job.id].clear()
        delete scheduled[job.id]
      scheduled = _(scheduled).compact()

      delete jobs[number]
      jobs = _(jobs).compact()
      saveJobs jobs

      return yes
    else
      return no

  listJobs = (room) ->
    message = ""
    for job, index in getJobs()
      sched = later.parse.text job.time
      next = moment(later.schedule(sched).next(1, Date.now()))
      message += "#{index}) Reminder to `#{job.text}` has been scheduled to run in ##{room} #{job.time} and will next run #{next.fromNow()}\n"

    message = "No reminders have been scheduled" if not message
    robot.messageRoom room, message

  robot.respond /(?:remind|reminder|reminders) list/, (msg) ->
    listJobs msg.message.room
    msg.finish()

  robot.respond /(?:reminder|reminder|reminders) (?:remove|delete|cancel)(?: job)? (\d)/, (msg) ->
    [ __, id ] = msg.match
    if removeJob id
      msg.reply "Reminder ##{id} successfully removed"
    else
      msg.reply "Unable to remove Job ##{id}"
    msg.finish()

  regex = /(?:remind|reminder|reminders)(?: me| us)? to\s*`([^]+)`\s*([^]+)/
  robot.respond regex, (msg) ->
    [ __, text, time ] = msg.message.rawText.match regex
    if validSchedule time
      job = setupJob text, msg.message.room, time
      sched = later.parse.text time
      next = moment(later.schedule(sched).next(1, Date.now()))
      msg.reply "Reminder ##{getJobs().length - 1} has been scheduled to run in ##{msg.message.room} #{time} and will next run #{next.fromNow()}"
    else
      msg.reply "Sorry, I was unable to parse your time interval"
    msg.finish()

  robot.brain.once 'loaded', ->
    scheduled[job.id] = create job for job in getJobs()
