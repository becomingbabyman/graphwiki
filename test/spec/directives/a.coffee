'use strict'

describe 'Directive: a', () ->

  # load the directive's module
  beforeEach module 'graphwikiApp'

  scope = {}

  beforeEach inject ($controller, $rootScope) ->
    scope = $rootScope.$new()

  it 'should make hidden element visible', inject ($compile) ->
    element = angular.element '<a></a>'
    element = $compile(element) scope
    expect(element.text()).toBe 'this is the a directive'
