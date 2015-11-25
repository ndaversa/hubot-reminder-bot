# Description:
# A hubot script to setup reminders using cron time
#
# Dependencies:
# - coffee-script
# - cron
# - underscore
# - moment
#
# Configuration:
# None
#
# Commands:
#   hubot remind [me] to <reminder> at <crontime> - Setup <reminder> to occur at <crontime> interval
#   hubot reminder list - List all the pending reminders
#   hubot reminder remove job <number> - Removes the given reminder job
#
# Author:
#   ndaversa

_ = require 'underscore'
moment = require 'moment'
cronJob = require("cron").CronJob
crons = []

module.exports = (robot) ->

  createCron = (job) ->
    new cronJob(job.time, (-> run job ), null, true)

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
    crons[job.id] = createCron job
    jobs.push job
    saveJobs jobs
    return job

  removeJob = (number) ->
    jobs = getJobs()
    job = jobs[number]

    if job
      crons[job.id].stop()
      delete crons[job.id]
      crons = _(crons).compact()

      delete jobs[number]
      jobs = _(jobs).compact()
      saveJobs jobs

      return yes
    else
      return no

  listJobs = (room) ->
    message = ""
    for job, index in getJobs()
      message += "#{index}) Reminder to `#{job.text}` with a cron interval of `#{job.time}` will next run in `#{moment(crons[job.id].nextDate()).fromNow()}`\n"
    message = "No reminders have been scheduled" if not message
    robot.messageRoom room, message

  robot.respond /(?:remind|reminder|reminders) list/, (msg) ->
    listJobs msg.message.room
    msg.finish()

  robot.respond /(?:reminder|reminder|reminders) remove(?: job)? (\d)/, (msg) ->
    [ __, id ] = msg.match
    if removeJob id
      msg.reply "Job ##{id} successfully removed"
    else
      msg.reply "Unable to remove Job ##{id}"
    msg.finish()

  regex = /(?:remind|reminder|reminders)(?: me| us)? to ([^]+)(?: (?:at|on) ([^]+))/
  robot.respond regex, (msg) ->
    [ __, text, cron ] = msg.message.rawText.match regex
    job = setupJob text, msg.message.room, cron
    msg.reply "Reminder ##{getJobs().length - 1} has been scheduled with a cron interval of `#{job.time}` and the next run will be in `#{moment(crons[job.id].nextDate()).fromNow()}`"
    msg.finish()

  robot.brain.once 'loaded', ->
    crons[job.id] = createCron job for job in getJobs()
