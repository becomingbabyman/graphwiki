'use strict'

angular.module('graphwikiApp')
	.directive('a', () ->
		restrict: 'E'
		link: (scope, element, attrs) ->

			if attrs.href 
				console.log(attrs.href)
				if attrs.href.slice(0, 5) == '/wiki'
					elem.on 'click', (e) ->
					e.prevenDefault()
	)
