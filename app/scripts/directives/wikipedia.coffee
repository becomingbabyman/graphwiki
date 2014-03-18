'use strict'

angular.module('graphwikiApp')
  .directive('wikipedia', () ->
    template: '<div></div>'
    restrict: 'E'
    link: (scope, element, attrs) ->
      element.text 'this is the wikipedia directive'
  )
