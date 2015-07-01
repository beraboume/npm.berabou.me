return unless window?

app= angular.module 'npm'

app.directive 'ngSrcViaProfile',($http)->
  link:(scope,element,attr)->
    $http.get '/profile/'+attr.ngSrcViaProfile
    .then (response)->
      element.attr 'src',response.data.avatar
