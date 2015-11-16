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
    func = eval job.func
    args = JSON.parse job.args
    func.apply @, args

  getJobs = ->
    robot.brain.get('reminder-jobs') or []

  saveJobs = (jobs) ->
    robot.brain.set 'reminder-jobs', jobs

  setupJob = (text, room, cron) ->
    jobs = getJobs()
    job =
      text: text
      room: room
      time: cron
    jobs.push job
    saveJobs jobs
    crons.push createCron job
    return job

  removeJob = (number) ->
    jobs = getJobs()
    if jobs[number]
      delete jobs[number]
      jobs = _(jobs).compact()
      saveJobs jobs

      crons[number].stop()
      delete crons[number]
      crons = _(crons).compact()
      return yes
    else
      return no

  listJobs = (room) ->
    message = ""
    for job, index in getJobs()
      message += "#{index}) Reminder to `#{job.text}` at cron `#{job.time}`\n"
    message = "No reminders have be scheduled" if not message
    robot.messageRoom room, message

  robot.respond /reminder list/, (msg) ->
    listJobs msg.message.room
    msg.finish()

  robot.respond /reminder remove job (\d)/, (msg) ->
    [ __, id ] = msg.match
    if removeJob id
      msg.reply "Job ##{id} successfully removed"
    else
      msg.reply "Unable to remove Job ##{id}"
    msg.finish()

  robot.respond /remind(?: me)to ([^\s]+)(?: at ([^]+))?/, (msg) ->
    [ __, text, cron ] = msg.match
    job = setupJob text, msg.message.room, cron
    msg.reply "Reminder ##{getJobs().length - 1} has been scheduled to run at cron `#{job.time}`"
    msg.finish()

  robot.brain.once 'loaded', ->
    crons.push createCron job for job in getJobs()

# robot.adapter.customMessage
#   channel: room
#   text: message
