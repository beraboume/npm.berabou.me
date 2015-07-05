return unless window? # No execute for server-side require

app= angular.module 'npm',[
  'angular-loading-bar'
	'ui.router'
  'ngAnimate'
	'ngAria'
	'ngMaterial'
]

require './services/c3'

app.filter 'names',->
  (pkgs)->
    (pkg.name for pkg in pkgs).join(', ')
app.filter 'toDays',->
  (period)->
    switch period
      when 'weekly' then 7
      when 'monthly' then 30
      when 'yearly' then 365

app.config ($mdThemingProvider)->
  $mdThemingProvider
    .theme 'default'
    .primaryPalette 'red'
    .accentPalette 'grey'

app.config ($urlRouterProvider,$stateProvider)->
  $urlRouterProvider.when('', '/')

  top= (require './top').client()
  $stateProvider.state 'top',
    url: '/'
    resolve: top.resolve
    views: top.views
    
  authors= (require './authors').client()
  $stateProvider.state 'authors',
    url: '/:author'
    resolve: authors.resolve
    views: authors.views

app.run ($rootScope,$state,$window,$mdDialog,cfpLoadingBar,$mdToast)->
  $rootScope.$state= $state
  $rootScope.location= (url)->
    $window.location.href= url
    false
  $rootScope.period= 'weekly'

  $rootScope.$on '$stateChangeStart',->
    cfpLoadingBar.start()
  $rootScope.$on '$stateChangeSuccess',->
    cfpLoadingBar.complete()
  $rootScope.$on '$stateChangeError',(event,toState,toParams,fromState,fromParams,error)->
    cfpLoadingBar.complete()

    if error
      console.error error
      $mdToast.show(
        $mdToast.simple()
        .content error.statusText
        .position 'top left right' 
        .hideDelay 2000
      )

    $state.go 'top'

  $rootScope.add= (event)->
    $mdDialog.show
      targetEvent: event
      parent: angular.element document.body

      focusOnOpen: false
      clickOutsideToClose: true

      template: require './top/add.jade'
      controller: ($scope,$mdDialog)->
        $scope.submit= ->
          author= $scope.author
          $state.go 'authors',{author}
          $mdDialog.hide()
        $scope.cancel= (event)->
          $mdDialog.cancel()
