# Expose for client
module.exports.client= ->
  resolve:
    users: ($http)->
      $http.get '/users'

  views:
    '':
      template: require './index.jade'

      controller: ($scope,users)->
        $scope.users= users.data

# Expose for server
module.exports.server= (app)->
  # Dependencies
  fs= require 'fs'
  path= require 'path'

  app.get '/users',(req,res)->
    fs.readdir process.env.DB,(error,files)->
      return res.status(500).end error.message if error

      # e.g: ['.gitignore','59naga.json','59naga.profile.json'] -> ['59naga']
      users=
        for file in files when file[0] isnt '.'
          strs= file.split '.'
          continue if strs[1] is 'profile'

          strs[0]
      res.json users
  
