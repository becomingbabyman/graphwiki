'use strict'

angular.module('graphwikiApp', [
  'ngCookies',
  'ngResource',
  'ngSanitize',
  'ngRoute',
  'ui.bootstrap'
])
  .config ($routeProvider, $locationProvider) ->
    $locationProvider.html5Mode(true)
