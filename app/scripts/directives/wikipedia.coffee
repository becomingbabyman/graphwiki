'use strict'

angular.module('graphwikiApp')
  .directive('wikipedia', () ->
    template: '<div></div>'
    restrict: 'E'
    compile: (element, attrs) ->
    	element.append("<a ng-click='count = count + 1'>Google</a>")
  )
