# Dependencies
env= require './server/env'
app= require './server/express'
cronjob= require './server/cronjob'
wanderer= require 'wanderer'

path= require 'path'

# Setup routes
files= wanderer.seekSync './client/**/*.coffee'
for file in files
  state= require file
  continue unless state.server

  state.server app

app.use (req,res,next)->
  res.status 404
  res.end()

# Boot if "coffee index.coffee"
if module.parent is null
  port= env.PORT or 59798
  app.listen port,->
    console.log 'Listen to http://localhost:%s/',port

# Expose
module.exports= app
