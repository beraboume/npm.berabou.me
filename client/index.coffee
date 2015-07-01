return unless window? # No execute for server-side require

app= angular.module 'npm',[
  'angular-loading-bar'
	'ui.router'
  'ngAnimate'
	'ngAria'
	'ngMaterial'
]

require './services/c3'
require './services/ng-src-via-profile'

app.config ($mdThemingProvider)->
  $mdThemingProvider
    .theme 'default'
    .primaryPalette 'red'
    .accentPalette 'grey'

app.config ($stateProvider)->
  top= (require './top').client()
  $stateProvider.state 'top',
    url: ''
    resolve: top.resolve
    views: top.views
    
  users= (require './users').client()
  $stateProvider.state 'users',
    url: '/:user'
    resolve: users.resolve
    views: users.views
    
  $stateProvider.state 'error',
    url: '*path'
    template: '400'

app.run ($rootScope,$state,$window,$mdDialog,cfpLoadingBar,$mdToast)->
  $rootScope.$state= $state
  $rootScope.location= (url)->
    $window.location.href= url
    false

  $rootScope.$on '$viewContentLoaded',->
    $.material.init()
  $rootScope.$on '$stateChangeStart',->
    cfpLoadingBar.start()
  $rootScope.$on '$stateChangeSuccess',->
    cfpLoadingBar.complete()
  $rootScope.$on '$stateChangeError',(event,toState,toParams,fromState,fromParams,error)->
    cfpLoadingBar.complete()

    console.log error.statusText

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

      template: require './top/add.jade'
      controller: ($scope,$mdDialog)->
        $scope.submit= ->
          user= $scope.user
          $state.go 'users',{user}
          $mdDialog.hide()
        $scope.cancel= (event)->
          $mdDialog.cancel()
