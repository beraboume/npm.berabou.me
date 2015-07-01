# Private
backSlice= (array,i,volume)->
  if (-i+1)*volume is 0
    array.slice(-i*volume)
  else
    array.slice(-i*volume,(-i+1)*volume)

# Expose for client
module.exports.client= ->
  volume= 7

  resolve:
    user: ($state,$stateParams,$http)->
      return $state.go 'top' unless $stateParams.user

      $http.get '/users/'+$stateParams.user
      .then (result)->
        return $state.go 'top' if result.data is null

        result

  views:
    '':
      template: require './index.jade'
      controller: ($scope,$stateParams,user)->
        $scope.page= 1

        $scope.type= 'bar'
        $scope.types= [
          "bar"
          "area"
          "pie"
        ]
        $scope.user= $stateParams.user

        $scope.prev= ->
          $scope.page++
        $scope.next= ->
          $scope.page--

        prevData= null
        $scope.$watch 'page',->
          {days,packages,total}= user.data
          page= $scope.page
          label= backSlice days,page,volume

          return $scope.page= 0 if label.length is 0

          $scope.days= days.length
          $scope.begin= label[0]
          $scope.end= label[label.length-1]

          pkgs= []

          achieves=
            for name,value of total.packages
              {name,value}
          achieves.sort (a,b)->
            switch
              when a.value > b.value then -1
              when a.value < b.value then 1
              else 0

          for achieve in achieves
            name= achieve.name
            downloads= packages[achieve.name]

            values= backSlice downloads,page,volume
            local= values.reduce (a,b)-> a+b
            global= total.packages[name]

            pkgs.push {name,values,local,global}

          pkgs.sort (a,b)->
            switch
              when a.local > b.local then -1
              when a.local < b.local then 1
              else 0

          columns=
            for pkg,i in pkgs when i< 10
              [pkg.name].concat pkg.values

          newColumns= (column[0] for column in columns)
          if prevData
            unload= (column for column in prevData when not (column in newColumns))

          prevData= newColumns

          $scope.label= label
          $scope.bulk= (pkgs.map (pkg)-> pkg.name).join(',')
          $scope.data= {columns,unload}
          $scope.pkgs= pkgs
          $scope.total=
            local: pkgs.reduce (a,b)-> (a?.local ? a)+b.local
            global: pkgs.reduce (a,b)-> (a?.global ? a)+b.global

# Expose for server
module.exports.server= (app)->
  # Dependencies
  Promise= require 'bluebird'
  npmCount= require 'npm-count'
  npmFetchAvatar= require 'npm-fetch-avatar'
  moment= require 'moment'
  
  fs= require 'fs'
  getPath= (user)->
    data: process.env.DB+user+'.json'
    profile: process.env.DB+user+'.profile.json'

  # Setup api routes
  app.get '/users/',(req,res)->
    res.json null
  app.get '/users/:user',(req,res)->
    user= req.params.user
    userPath= getPath user

    profile= null
    data= null
    try
      profile= require userPath.profile
      data= require userPath.data

      latest= npmCount.last data
      current= moment.utc().add(-1,'days').format 'YYYY-MM-DD'
      throw 'update' if latest < current

      res.json data

    # Update user data and profile
    catch
      npmCount.fetch user,'all'
      .then (data)->
        return res.status(404).end() if Object.keys(data.packages).length is 0

        fs.writeFileSync userPath.data,JSON.stringify data

        new Promise (resolve,reject)->
          npmFetchAvatar user,(error,avatar)->
            return reject error if error

            resolve {user,avatar}
        .then (profile)->
          weekly_downloads= 0
          weekly=
            for name,days of data.packages
              downloads= days.slice(-7).reduce (a,b)-> a+b
              weekly_downloads+= downloads
              {name,downloads}
          weekly.sort (a,b)->
            switch
              when a.downloads > b.downloads then -1
              when a.downloads < b.downloads then 1
              else 0

          profile.weekly_downloads= weekly_downloads
          profile.weekly= weekly

          fs.writeFileSync userPath.profile,JSON.stringify profile
        .then ->
          res.json data

      .catch (error)->
        return res.status(500).end error.message

  app.get '/profile/:user',(req,res)->
    user= req.params.user
    userPath= getPath user

    try
      profile= require userPath.profile

      res.json profile
    catch
      res.status(404).json({})
