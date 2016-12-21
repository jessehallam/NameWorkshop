app = angular.module('NameWorkshop', ['Panels', 'TreeView'])

app.service('parser', ->
    @lexer = window.Parser_v3.Lexer
    @parser = window.Parser_v3.Parser
    return
)

app.factory('generator', (parser) ->
    stripRepeatingChars = (s, c) ->
        last = '\0'
        count = 0
        r = []
        for ch, i in s
            if ch.toLowerCase() != last.toLowerCase()
                last = ch
                count = 0
            count++
            if count <= c then r.push(ch)
        return r.join('')

    return (input, options) ->
        if input and options.ignoreWhitespace
            input = input.replace(/\s|\r|\n/, -> '')
        lex = new parser.lexer(input)
        par = new parser.parser(lex.readTokens())
        program = par.program()
        if not program then throw new Error('parser error')
        return ->
            val = program.eval()
            if val and options.capitalize
                val = val[0].toUpperCase() + val.substr(1)
            if val and options.maxRepeatingChars
                val = stripRepeatingChars(val, options.maxRepeatingChars)
            return val
)

app.controller('Main', (generator, parser, $rootScope, $scope) ->
    $rootScope.user = {authenticated: true, name: 'User Name'}
    $scope.signin = ->
        $rootScope.user = {authenticated: true, name: 'User Name'}

    $scope.model = {
        editor: {
            capitalize: true
            ignoreWhitespace: false
            maxRepeatingChars: 2
            text: ''
        }
        fileSystem: {
            baseDir: {
                folders: [
                    {
                        name: 'Project 1'
                        folders: [
                            { 
                                name: 'Project 2'
                                files: [
                                    { name: 'File 2.1' }
                                ]
                            }
                        ]
                        files: [
                            { name: 'File 1.1' }
                        ]
                    }
                ]
                files: [
                    { name: 'File 0.1' }
                ]
            }
        }
        results: {
            items: [],
            savedItems: []
        }
    }

    $scope.$watch('model.editor.maxRepeatingChars', (newValue) ->
        if newValue > 999
            $scope.model.editor.maxRepeatingChars = 999
        if newValue < 0 or typeof newValue == 'undefined'
            $scope.model.editor.maxRepeatingChars = 0
    )

    $scope.execute = ->
        g = generator($scope.model.editor.text, {
            capitalize: $scope.model.editor.capitalize,
            ignoreWhitespace: $scope.model.editor.ignoreWhitespace,
            maxRepeatingChars: $scope.model.editor.maxRepeatingChars 
        })
        $scope.model.results.items = []
        for n in [0..100]
            $scope.model.results.items.push(g())

    $scope.removeSavedItem = (index) ->
        $scope.model.results.savedItems.splice(index, 1)

    $scope.saveItem = (value) ->
        $scope.model.results.savedItems.push(value)
)

app.directive('focusWhen', ($timeout) ->
    {
        restrict: 'A',
        link: (scope, element, attrib) ->
            focus = ->
                $(element).focus()

            scope.$watch(attrib.focusWhen, (newValue) ->
                if newValue
                    $timeout(focus, 50)
            )
    })

app.directive('selectAllWhen', ($timeout) ->
    {
        restrict: 'A'
        link: (scope, element, attrib) ->
            selectAll = ->
                element[0].setSelectionRange(0, element[0].value.length)

            scope.$watch(attrib.selectAllWhen, (newValue) ->
                if newValue
                    $timeout(selectAll, 50)
            )
    })

app.directive('whenFocusLost', ($parse) ->
    {
        restrict: 'A'
        link: (scope, element, attrib) ->
            getter = $parse(attrib.whenFocusLost)
            $(element).on('blur', ->
                getter(scope)
                scope.$apply()
            )
    })