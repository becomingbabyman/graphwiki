'use strict'

describe 'Directive: wikipedia', () ->

  # load the directive's module
  beforeEach module 'graphwikiApp'

  scope = {}

  beforeEach inject ($controller, $rootScope) ->
    scope = $rootScope.$new()

  it 'should make hidden element visible', inject ($compile) ->
    element = angular.element '<wikipedia></wikipedia>'
    element = $compile(element) scope
    expect(element.text()).toBe 'this is the wikipedia directive'
