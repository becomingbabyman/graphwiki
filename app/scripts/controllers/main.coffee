'use strict'

angular.module('graphwikiApp')
	.controller 'MainCtrl', ($scope, $http, $q, $sce, $compile, $location) ->

		$scope.wikiSearch = ''
		$scope.searchSuggests = []
		$scope.browseHistory = []

		$scope.showNodes = false
		$scope.loading = false

		$scope.$watch(() ->
			$location.path();
		, () ->
			if $location.path() != '/'
				$scope.wikiSearch = $location.path().substr(6)
				$scope.searchWiki($scope.wikiSearch)
		)

		$scope.toggleGraph = () -> 
			$scope.showNodes = !$scope.showNodes

		# how we render the graph
		Renderer = (canv) ->
			canvas = $(canv).get(0)
			ctx = canvas.getContext("2d")
			gfx = arbor.Graphics(canvas)
			particleSystem = null
			that =
				init: (system) ->
					particleSystem = system
					particleSystem.screenSize canvas.width, canvas.height
					particleSystem.screenPadding 40
					that.initMouseHandling()
					return

				redraw: ->
					return  unless particleSystem
					gfx.clear() # convenience ƒ: clears the whole canvas rect
					
					# draw the nodes & save their bounds for edge drawing
					nodeBoxes = {}
					particleSystem.eachNode (node, pt) ->
						
						# node: {mass:#, p:{x,y}, name:"", data:{}}
						# pt:   {x:#, y:#}  node position in screen coords
						
						# determine the box size and round off the coords if we'll be 
						# drawing a text label (awful alignment jitter otherwise...)
						label = node.data.label or ""
						w = ctx.measureText("" + label).width + 10
						unless ("" + label).match(/^[ \t]*$/)
							pt.x = Math.floor(pt.x)
							pt.y = Math.floor(pt.y)
						else
							label = null
						
						# draw a rectangle centered at pt
						if node.data.color
							ctx.fillStyle = node.data.color
						else
							ctx.fillStyle = "rgba(0,0,0,.2)"
						ctx.fillStyle = "white"  if node.data.color is "none"
						if node.data.shape is "dot"
							gfx.oval pt.x - w / 2, pt.y - w / 2, w, w,
								fill: ctx.fillStyle

							nodeBoxes[node.name] = [
								pt.x - w / 2
								pt.y - w / 2
								w
								w
							]
						else
							gfx.rect pt.x - w / 2, pt.y - 10, w, 20, 4,
								fill: ctx.fillStyle

							nodeBoxes[node.name] = [
								pt.x - w / 2
								pt.y - 11
								w
								22
							]
						
						# draw the text
						if label
							ctx.font = "12px Helvetica"
							ctx.textAlign = "center"
							ctx.fillStyle = "white"
							ctx.fillStyle = "#333333"  if node.data.color is "none"
							ctx.fillText label or "", pt.x, pt.y + 4
							ctx.fillText label or "", pt.x, pt.y + 4
						return

					
					# draw the edges
					particleSystem.eachEdge (edge, pt1, pt2) ->
						
						# edge: {source:Node, target:Node, length:#, data:{}}
						# pt1:  {x:#, y:#}  source position in screen coords
						# pt2:  {x:#, y:#}  target position in screen coords
						weight = edge.data.weight
						color = edge.data.color
						color = null  if not color or ("" + color).match(/^[ \t]*$/)
						
						# find the start point
						tail = intersect_line_box(pt1, pt2, nodeBoxes[edge.source.name])
						head = intersect_line_box(tail, pt2, nodeBoxes[edge.target.name])
						ctx.save()
						ctx.beginPath()
						ctx.lineWidth = (if (not isNaN(weight)) then parseFloat(weight) else 1)
						ctx.strokeStyle = (if (color) then color else "#cccccc")
						ctx.fillStyle = null
						ctx.moveTo tail.x, tail.y
						ctx.lineTo head.x, head.y
						ctx.stroke()
						ctx.restore()
						
						# draw an arrowhead if this is a -> style edge
						if edge.data.directed
							ctx.save()
							
							# move to the head position of the edge we just drew
							wt = (if not isNaN(weight) then parseFloat(weight) else 1)
							arrowLength = 6 + wt
							arrowWidth = 2 + wt
							ctx.fillStyle = (if (color) then color else "#cccccc")
							ctx.translate head.x, head.y
							ctx.rotate Math.atan2(head.y - tail.y, head.x - tail.x)
							
							# delete some of the edge that's already there (so the point isn't hidden)
							ctx.clearRect -arrowLength / 2, -wt / 2, arrowLength / 2, wt
							
							# draw the chevron
							ctx.beginPath()
							ctx.moveTo -arrowLength, arrowWidth
							ctx.lineTo 0, 0
							ctx.lineTo -arrowLength, -arrowWidth
							ctx.lineTo -arrowLength * 0.8, -0
							ctx.closePath()
							ctx.fill()
							ctx.restore()
						return

					return

				initMouseHandling: ->
					
					# no-nonsense drag and drop (thanks springy.js)
					selected = null
					nearest = null
					dragged = null
					oldmass = 1
					time = null
					
					# set up a handler object that will initially listen for mousedowns then
					# for moves and mouseups while dragging
					handler =
						clicked: (e) ->
							time = Date.now()
							pos = $(canvas).offset()
							_mouseP = arbor.Point(e.pageX - pos.left, e.pageY - pos.top)
							selected = nearest = dragged = particleSystem.nearest(_mouseP)
							dragged.node.fixed = true  if dragged.node isnt null
							$(canvas).bind "mousemove", handler.dragged
							$(window).bind "mouseup", handler.dropped
							false

						dragged: (e) ->
							old_nearest = nearest and nearest.node._id
							pos = $(canvas).offset()
							s = arbor.Point(e.pageX - pos.left, e.pageY - pos.top)
							return  unless nearest
							if dragged isnt null and dragged.node isnt null
								p = particleSystem.fromScreen(s)
								dragged.node.p = p
							false

						dropped: (e) ->
							return  if dragged is null or dragged.node is `undefined`
							dragged.node.fixed = false  if dragged.node isnt null
							dragged.node.tempMass = 1000
							dragged = null
							if Date.now() - time < 400 and selected.node.data.label != "START"
								$scope.wikiSearch = selected.node.data.label
								$scope.searchWiki(false)
							selected = null
							time = null
							$(canvas).unbind "mousemove", handler.dragged
							$(window).unbind "mouseup", handler.dropped
							_mouseP = null
							false

					$(canvas).mousedown handler.clicked
					return

			
			# helpers for figuring out where to draw arrows (thanks springy.js)
			intersect_line_line = (p1, p2, p3, p4) ->
				denom = ((p4.y - p3.y) * (p2.x - p1.x) - (p4.x - p3.x) * (p2.y - p1.y))
				return false  if denom is 0 # lines are parallel
				ua = ((p4.x - p3.x) * (p1.y - p3.y) - (p4.y - p3.y) * (p1.x - p3.x)) / denom
				ub = ((p2.x - p1.x) * (p1.y - p3.y) - (p2.y - p1.y) * (p1.x - p3.x)) / denom
				return false  if ua < 0 or ua > 1 or ub < 0 or ub > 1
				arbor.Point p1.x + ua * (p2.x - p1.x), p1.y + ua * (p2.y - p1.y)

			intersect_line_box = (p1, p2, boxTuple) ->
				p3 =
					x: boxTuple[0]
					y: boxTuple[1]

				w = boxTuple[2]
				h = boxTuple[3]
				tl =
					x: p3.x
					y: p3.y

				tr =
					x: p3.x + w
					y: p3.y

				bl =
					x: p3.x
					y: p3.y + h

				br =
					x: p3.x + w
					y: p3.y + h

				intersect_line_line(p1, p2, tl, tr) or intersect_line_line(p1, p2, tr, br) or intersect_line_line(p1, p2, br, bl) or intersect_line_line(p1, p2, bl, tl) or false

			that



		# Create graph
		graph = arbor.ParticleSystem(1000, 600, 0.5) # create the system with sensible repulsion/stiffness/friction
		graph.parameters gravity: true
		# use center-gravity to make the graph settle nicely (ymmv)
		graph.renderer = Renderer("#viewport") # our newly created renderer will have its .init() method called shortly by sys...


		$scope.$watch 'wikiSearch', () ->
			$http.jsonp('http://en.wikipedia.org/w/api.php?action=opensearch&search=' + $scope.wikiSearch + '&limit=8&namespace=0&format=json&callback=JSON_CALLBACK').success (data) ->
				$scope.searchSuggests = data[1]
				# console.log(data)


		$scope.searchWiki = (trackSearch = true) ->
			defered = $q.defer()

			$scope.loading = true
			$http.jsonp('http://en.wikipedia.org/w/api.php?action=parse&page=' + $scope.wikiSearch + '&prop=text&format=json&callback=JSON_CALLBACK').success((data) ->
				wikiLinkFixer = (text) ->
					text.replace(/href="\/wiki\/(.*?)"/g, "href='/wiki/$1'")
				$scope.wikiText = wikiLinkFixer data.parse.text['*']
				# console.log($scope.wikiText)
				# console.log(data)
				nodeName = $scope.wikiSearch.replace(/[_ ]/g, '-')
				if trackSearch
					edge = graph.addEdge(($scope.browseHistory.slice(-1)[0] or "start"), nodeName, {directed: true, length: 0.2, color: "black"})
					if $scope.browseHistory.length == 0
						edge.source.data.label = "START"
					edge.target.data.label = $scope.wikiSearch
					edge.target.data.color = "black"
				$scope.browseHistory.push nodeName

				defered.resolve(data.parse.text['*'])
				$scope.loading = false
			).error (data) ->
				defered.reject("WIKIPEDIA FUCKED UP")

			defered.promise
