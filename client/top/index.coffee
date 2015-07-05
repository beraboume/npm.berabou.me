# Expose for client
module.exports.client= ->
  resolve:
    authors: ($http)->
      $http.get '/authors'
      .then (response)->
        response.data

  views:
    '':
      template: require './index.jade'

      controller: ($scope,authors)->
        $scope.authors= authors

# Expose for server
module.exports.server= (app)->
  # Dependencies
  fs= require 'fs'
  path= require 'path'

  app.get '/authors',(req,res)->
    fs.readdir process.env.DB,(error,files)->
      return res.status(500).end error.message if error

      # e.g: ['.gitignore','59naga.json'] -> [authorData]
      authors=
        for file in files when file[0] isnt '.'
          strs= file.split '.'

          authorData= require process.env.DB+path.sep+file

          # disuse at ./top
          delete authorData.days
          delete authorData.packages

          authorData

      res.json authors
  
