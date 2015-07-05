# Dependencies
app= require './server/express'
wanderer= require 'wanderer'

path= require 'path'

# Environment
process.env.ROOT= __dirname+path.sep
process.env.DB= __dirname+path.sep+'db'+path.sep
process.env.SERVER= __dirname+path.sep+'server'+path.sep
process.env.CLIENT= __dirname+path.sep+'client'+path.sep

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
  port= process.env.PORT or 59798
  app.listen port,->
    console.log 'Listen to http://localhost:%s/',port

# Expose
module.exports= app
