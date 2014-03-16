'use strict'

angular.module('graphwikiApp')
  .controller 'MainCtrl', ($scope, $http) ->
    $scope.awesomeThings = [
      'HTML5 Boilerplate'
      'AngularJS'
      'Karma'
    ]

    $scope.wiki_search = ''
    $scope.search_suggests = []

    $scope.$watch('wiki_search', () ->
      $http.jsonp('http://en.wikipedia.org/w/api.php?action=opensearch&search=' + $scope.wiki_search + '&limit=8&namespace=0&format=json&callback=JSON_CALLBACK').success((data) ->
        $scope.search_suggests = data[1]
        #console.log(data)
      )
    )

    # $http.jsonp('http://en.wikipedia.org/w/api.php?action=parse&page=pizza&prop=text&format=json&callback=JSON_CALLBACK').success((data) ->
    #   $scope.wiki_text = data.parse.text['*']
    #   console.log(data)
    #   ).error((data) ->
    #     $scope.blah = 'fail'
    #   )