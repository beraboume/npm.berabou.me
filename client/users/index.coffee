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
      $http.get '/count/'+$stateParams.user
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
  npmCount= require 'npm-count'
  npmFetchAvatar= require 'npm-fetch-avatar'
  moment= require 'moment'
  
  fs= require 'fs'

  # Setup api routes
  app.get '/count/',(req,res)->
    res.json null
  app.get '/profile/:user',(req,res)->
    user= req.params.user
    userPath= process.env.DB+user+'.profile.json'

    try
      data= require userPath
      res.json data
    catch
      npmFetchAvatar user,(error,avatar)->
        return res.status(500).end error.message if error

        data= {user,avatar}

        fs.writeFileSync userPath,JSON.stringify data

        res.json data

  app.get '/count/:user',(req,res)->
    user= req.params.user
    userPath= process.env.DB+user+'.json'

    try
      data= require userPath

      latest= npmCount.last data
      current= moment.utc().add(-1,'days').format 'YYYY-MM-DD'
      throw 'update' if latest < current

      res.json data
    catch
      npmCount.fetch user,'all'
      .then (data)->
        return res.status(404).end() if Object.keys(data.packages).length is 0

        fs.writeFileSync userPath,JSON.stringify data

        res.json data
      .catch (error)->
        return res.status(500).end error.message
