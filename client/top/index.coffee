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
        $scope.search= '' # fixed highlighted the 'undefind'
        $scope.sort= 'total'
        $scope.direction= '-'
        $scope.authors= authors

# Expose for server
module.exports.server= (app)->
  # Dependencies
  fs= require 'fs'

  app.get '/authors',(req,res)->
    fs.readdir process.env.DB,(error,files)->
      return res.status(500).end error.message if error

      # e.g: ['.gitignore','59naga.json'] -> [authorData]
      authors=
        for file in files when file[0] isnt '.'
          strs= file.split '.'

          try
            authorData= require process.env.DB+file
          catch
            continue

          # disuse at ./top
          delete authorData.days
          delete authorData.packages

          authorData

      res.json authors
  
