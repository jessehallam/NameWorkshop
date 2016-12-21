app = angular.module('TreeView', [])

###
app.directive('tvParent', ->
	{
		link: (_, element) ->

		restrict: 'C'
	})
###
app.directive('tvToggle', ->
	{
		restrict: 'C'
		link: (_, element) ->
			$(element).on('click', ->
				$(this).next().slideToggle(115)
				$(this).toggleClass('tv-open')
				)
	})

app.directive('tvFolder', ->
	{
		restrict: 'E'
		replace: true
		scope: {
			folder: '=value'
		}
		templateUrl: '/Templates/tvFolder.html'
		link: (scope, element, attrib) ->
	})