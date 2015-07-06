# Dependencies
env= require './env'
update= require './update'

CronJob= (require 'cron').CronJob

Promise= require 'bluebird'
throat= require 'throat'
fs= Promise.promisifyAll require 'fs'
path= require 'path'

cronJob= new CronJob
  cronTime: '0 0 1 * * *' # midnight 1 o'clock everyday
  onTick: ->
    fs.readdirAsync env.DB
    .then (files)->
      begin= Date.now()

      success= 0
      failure= 0
      authors=
        for file,i in files when file[0] isnt '.'
          author= file.split('.')[0]
          authorPath= env.DB+file

          {author,authorPath}

      Promise.all authors.map throat 15,({author,authorPath},i)->
        # console.log '%s. Updating the %s to %s',('00'+i).slice(-3),author,(path.relative process.cwd(),authorPath)

        update author,authorPath
        .then (normalized)->
          success++
          # console.log '%s. Success the %s',('00'+i).slice(-3),author
        .catch (error)->
          failure++
          # console.log '%s. Failure the %s',('00'+i).slice(-3),author,error

      .then ->
        console.error 'Finish. %s success %s failure %s authors. %s sec',
          success, failure, authors.length, (Date.now()-begin)/1000

cronJob.start()

module.exports= cronJob
