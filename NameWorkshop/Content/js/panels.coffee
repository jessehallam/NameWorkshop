app = angular.module('Panels', [])

app.directive('panelTools', ->
	{
		link: (_, element) ->
			$('.btn', element).mousedown(->
				$(this).css('top', '1px')
			).mouseup(->
				$(this).css('top', '')
			)
		restrict: 'C'
	})
