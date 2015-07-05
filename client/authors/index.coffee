# Expose for client
module.exports.client= ->
  views:
    '':
      template: require './index.jade'
      controller: ($scope,author,$mdToast)->
        throw new Error 'invalid resolve' unless author[$scope.period]

        $scope.page= 0
        $scope.type= 'bar'
        $scope.types= [
          'bar'
          'area'
          'pie'
        ]
        $scope.author= author.author
        $scope.avatar= author.avatar

        $scope.prev= ->
          $scope.page++
        $scope.next= ->
          if calculated[$scope.period][$scope.page-1]?
            $scope.page--
          else
            $scope.page= calculated[$scope.period].length- 1

        calculated= npmCount.calculate author
        console.log calculated if location.href.indexOf('?debug')>-1

        prevData= null
        $scope.$watch 'page',-> update()
        $scope.$watch 'period',-> update()

        updating= null
        update= ->
          return if updating
          return $scope.page= 0 unless calculated[$scope.period]?[$scope.page]?

          updating= yes

          {start,end,total,average,column}= calculated[$scope.period][$scope.page]
          $scope.length= column.length
          $scope.days= author.days.length
          $scope.start= start
          $scope.end= end

          console.log $scope.period,start,end,total,average,column if location.href.indexOf('?debug')>-1

          # Format the packages for $scope.packages
          packages=
            for pkg,id in calculated.packages
              data= {}
              data.id= id
              data.name= pkg.name
              data.local= pkg[$scope.period][$scope.page].total
              data.global= pkg.total
              data

          # Sort the packages in descending order of weekly total
          packages.sort (a,b)->
            switch
              when a.local > b.local then -1
              when a.local < b.local then 1
              else 0

          # Add label to column each package
          columns=
            for pkg,i in packages when i< 10
              column= calculated.packages[pkg.id][$scope.period][$scope.page].column
              [pkg.name].concat column

          # Unload columns of c3.js
          newColumns= (column[0] for column in columns)
          if prevData
            unload= (column for column in prevData when not (column in newColumns))
          prevData= newColumns

          # Expose
          $scope.label= npmCount.getDays start,end
          $scope.packages= packages
          $scope.data= {columns,unload}

          $scope.total=
            local: total
            global: calculated.total

          $scope.average=
            local: average
            global: calculated.average

          # Generate raw download counts uris
          $scope.queries= (npmCount.getBulkURIs (packages.map (pkg)-> pkg.name),start+':'+end).map (uri)->
            decodeURIComponent uri

          updating= null

  resolve:
    author: ($state,$stateParams,$http,$timeout,$mdToast)->
      return $state.go 'top' unless $stateParams.author

      toast= null
      toaster= $timeout ->
        toaster= null

        toast=
          $mdToast.showSimple
            content: 'update the '+$stateParams.author+'...'
            position: 'bottom left' 
            hideDelay: 10000
      ,500

      $http.get '/authors/'+$stateParams.author
      .then (response)->
        $mdToast.hide toast if toast
        $timeout.cancel toaster if toaster

        return $state.go 'top' if response.data is null

        response.data

# Expose for server
module.exports.server= (app)->
  # Dependencies
  Promise= require 'bluebird'
  npmCount= require 'npm-count'
  npmFetchAvatar= Promise.promisify(require 'npm-fetch-avatar')

  addSummary= require process.env.SERVER+'add-summary'

  fs= Promise.promisifyAll(require 'fs')
  
  # Setup api routes
  app.get '/authors/:author',(req,res)->
    author= req.params.author
    authorPath= process.env.DB+author+'.json'

    npmCount.fetchDays()
    .then (days)->
      current= days[0]

      promise=
        if fs.existsSync authorPath
          fs.readFileAsync authorPath,'utf8'
          .then (data)->
            JSON.parse data
        else
          Promise.resolve null

      promise
      .then (normalized)->
        # get last-day of downloads
        end= normalized?.days.slice(-1)[0]
        if end >= current
          res.json normalized
        else
          res.redirect '/authors/'+author+'/update'

    .catch (error)->
      res.status(500).json error?.message ? error

  app.get '/authors/:author/update',(req,res)->
    author= req.params.author
    authorPath= process.env.DB+author+'.json'

    npmCount.fetch author,'all'
    .then (downloads)->
      if Object.keys(downloads).length
        npmCount.normalize downloads
      else
        Promise.resolve null

    .then (normalized)->
      return null unless normalized

      normalized.author= author

      npmFetchAvatar author
      .then (avatar)->
        normalized.avatar= avatar

        normalized= addSummary normalized
        fs.writeFileAsync authorPath,(JSON.stringify normalized)
        .then ->
          normalized

    .then (normalized)->
      if normalized
        res.json normalized
      else
        res.status(404).json null

    .catch (error)->
      res.status(500).json error?.message ? error
