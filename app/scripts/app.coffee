'use strict'

angular.module('graphwikiApp', [
  'ngCookies',
  'ngResource',
  'ngSanitize',
  'ngRoute',
  'ui.bootstrap'
])
  # .config ($routeProvider) ->
  #   $routeProvider
  #     .when '/',
  #       templateUrl: 'views/main.html'
  #       controller: 'MainCtrl'
  #     .when '/wiki/:wiki',
  #       templateUrl: 'views/main.html'
  #       controller: 'MainCtrl'
  #     # .otherwise
  #     #   redirectTo: '/'
  .config ($routeProvider, $locationProvider) ->
    $locationProvider.html5Mode(true)
