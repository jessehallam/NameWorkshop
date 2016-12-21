getHashCode = (str) ->
    i = 0
    l = 0
    hval = 0x811c9dc5;
    
    for i in [0..str.length-1]
        hval ^= str.charCodeAt(i)
        hval += (hval << 1) + (hval << 4) + (hval << 7) + (hval << 8) + (hval << 24)
    
    return ("0000000" + (hval >>> 0).toString(16)).substr(-8)

# [min, max)
getRandom = (min, max) ->
    return Math.floor(Math.random() * (max - min)) + min;

lexStates = {
    start: [
        { m: /\(/, t: '(' }
        { m: /\)/, t: ')' }
        { m: /\|/, t: '|' }
        { m: /\^/, t: '^' }
        { m: /</,  t: '<', next: 'named' }
        { m: /\[/, t: '[', next: 'range' }
        { m: /\{/, t: '{', next: 'rep' }
        { m: /\*/, t: 'KLEENESTAR' }
        { m: /./, t: 'CHAR' }
    ]

    named: [
        { m: /[a-zA-Z0-9]/, t: 'CHAR' }
        { m: /-|_/, t: 'ALTCHAR' }
        { m: />/, t: '>', next: 'start' }
    ]

    range: [
        { m: /[a-zA-Z0-9]/, t: 'CHAR' }
        { m: /-/, t: '-' }
        { m: /]/, t: ']', next: 'start'}
    ]

    rep: [
        { m: /\d+/, t: 'INT' }
        { m: /-/, t: '-' }
        { m: /\}/, t: '}', next: 'start' }
    ]
}

class Lexer
    constructor: (@input) ->
        @i = 0
        @state = 'start'
        @line = 0
        @col = 0

    readTokens: ->
        while t = @$readNext()
            t
        
    $advancePos: (s) ->
        for c, i in s
            if c == '\r'
                if c == '\n'
                    @line++
                    @col = 0
            else if c == '\n'
                @line++
                @col = 0
            else
                @col++

    $readNext: ->
        for rule in lexStates[@state]
            if @input.search(rule.m) == 0
                r = rule.m.exec(@input)
                t = {
                    tok: rule.t,
                    val: r[0],
                    match: r,
                    pos: [@line, @col]
                }

                @input = @input.substr(r[0].length)
                if rule.next
                    @state = rule.next
                return t

class ExpressionBase
    eval: -> ""
    toString: -> 'Expression()'

class ConstantExpression extends ExpressionBase
    constructor: (chars) ->
        @val = if not chars then '' else (c.val for c in chars).join('')
    eval: ->
        @val
    toString: ->
        "'" + @val + "'"

class ItemExpression extends ExpressionBase
    constructor: ->
        @item = null
    toString: -> 'ItemExpresion(' + @item + ')'

class CapitalExpression extends ItemExpression
    constructor: (@item) ->
    eval: (context) ->
        val = @item.eval(context)
        if val
            val = val[0].toUpperCase() + val.substr(1)
        return val
    toString: -> 'Capital(' + @item.toString() + ')'

class ItemsExpression extends ExpressionBase
    constructor: ->
        @items = []
    toString: -> 'ItemsExpression(' + @items.join(', ') + ')'

class DistinctExpression extends ItemExpression
    constructor: (@item) ->
    eval: (context) ->
        hash = @getHashCode()
        i = context.distinctGroups[hash].indexOf(this)
        if context.distinctCache[hash] == i
            return @item.eval(context)
        else
            return ''
    
        # context.distinctCache = context.distinctCache or {}
        # if context.distinctCache[@item.toString()] then return ''
        # context.distinctCache[@item.toString()] = true
        # return @item.eval(context)
    getHashCode: -> getHashCode(@toString())
    toString: -> 'DistinctExpression(' + @item + ')'

class ExpressionList extends ItemsExpression
    eval: (context) ->
        return (item.eval(context) for item in @items).join('')
    toString: -> 'ExpressionList(' + @items.join(', ') + ')'

class ExpressionBranch extends ItemsExpression
    eval: (context) ->
        if not @items.length then return ""
        return @items[getRandom(0, @items.length)].eval(context)
    toString: -> @items.join(' | ')

class NameLookupExpression extends ExpressionBase
    constructor: (@name) ->
    eval: (context) ->
        if not context[@name] then return ''
        return context[@name].eval(context)
    toString: ->
        '<' + @name + '>'

class RangeExpression extends ExpressionBase
    constructor: (min, max) ->
        @min = min.charCodeAt(0)
        @max = max.charCodeAt(0) + 1
    eval: ->
        return String.fromCharCode(getRandom(@min, @max))
    toString: -> 'Range[' + String.fromCharCode(@min) + ' - ' + String.fromCharCode(@max - 1) + ']'

class RepeatExpression extends ExpressionBase
    constructor: (@expression, @repetition) ->
    eval: (context) ->
        #count = getRandom(@repetition.min, if @repetition.min == @repetition.max then @repetition.max else @repetition.max + 1)
        count = getRandom(@repetition.min, @repetition.max + 1)
        if count <= 0 then return
        results = []
        for i in [0..count-1]
            results.push(@expression.eval(context))
        return results.join('')
    toString: -> @expression.toString() + '{' + @repetition.min + ' - ' + @repetition.max + '}';

class EvaluationExpression extends ItemExpression
    constructor: (@item, @args) ->
    eval: (context) ->
        context = context or {expressions: {}}
        $.extend(context, @args)
        for hash, collection of context.distinctGroups
            context.distinctCache[hash] = getRandom(0, collection.length)
        return @item.eval(context)
    toString: -> @item.toString()

class Parser
    constructor: (@input) ->
        @i = 0
        @evalArgs = {
            distinctCache: {}
            distinctGroups: {}
        }

    program: ->
        r = @$readExpressionBranch()
        if @$la() then throw new Error('Parse error')
        return new EvaluationExpression(r, @evalArgs)

    $expect: (name) ->
        if @$la(0) == name
            return @input[@i++]

    $invalidToken: (token) ->
        token = token or @input[@i]
        return new Error('Got `' + (if token then token.tok else '') + '` at ' + (if token then token.pos else 'EOF'));
        
    $la: (k = 0) ->
        return @input[@i + k].tok if @input[@i + k]
        
    $readDistinctExpression: ->
        # KLEENESTAR <expression> KLEENESTAR
        #
        if not @$expect('KLEENESTAR') then return
        if not exp = @$readExpression() then throw @$invalidToken()
        if not @$expect('KLEENESTAR') then return
        exp = new DistinctExpression(exp)
        @evalArgs.distinctGroups[exp.getHashCode()] = @evalArgs.distinctGroups[exp.getHashCode()] || []
        @evalArgs.distinctGroups[exp.getHashCode()].push(exp)
        return exp

    $readExpression: ->
        # <capitalExpression>? 
        # (<distinctExpression> | <rangeExpression> | <namedExpression> | '(' <expression> ')' | <constantExpression>)
        # <repeatExpression> ;
        cap = @$expect('^')
        exp = @$readDistinctExpression() ||
            @$readRangeExpression() || 
            @$readNamedExpression() || 
            @$readGroupExpression() ||
            @$readConstantExpression()
        if not exp then return
        rep = @$readRepeatExpression()
        if rep
            exp = new RepeatExpression(exp, rep)
        if cap
            exp = new CapitalExpression(exp)
        return exp

    $readConstantExpression: ->
        # CHAR+ ;
        results = []
        if not c = @$expect('CHAR') then return
        results.push(c)
        while c = @$expect('CHAR')
            results.push(c)
        return new ConstantExpression(results)

    $readExpressionBranch: ->
        # <expressionList> ('|' <expressionList>)* ;
        if a = @$readExpressionList()
            expr = new ExpressionBranch
            expr.items.push(a)
            while pipe = @$expect('|')
                if a = @$readExpressionList()
                    expr.items.push(a)
                else
                    expr.items.push(new ConstantExpression)
                #else
                #    throw @$invalidToken(pipe)
            return expr
        
    $readExpressionList: ->
        # <expression>+ ;
        if a = @$readExpression()
            expr = new ExpressionList
            expr.items.push(a)
            while a = @$readExpression()
                expr.items.push(a)
            return expr

    $readGroupExpression: ->
        if not @$expect('(') then return
        if not exp = @$readExpressionBranch() then throw @$invalidToken()
        if not @$expect(')') then throw @$invalidToken()
        return exp

    $readNamedExpression: ->
        # '<' CHAR (CHAR | ALTCHAR)* '>' ;
        if not @$expect('<') then return
        if not a = @$expect('CHAR') then throw @$invalidToken()
        expr = new NameLookupExpression
        expr.name = a.val
        while a = @$expect('CHAR') || @$expect('ALTCHAR')
            expr.name += a.val
        if not @$expect('>') then throw @$invalidToken()
        return expr

    $readRangeExpression: ->
        # '[' CHAR '-' CHAR ']' ;
        if not @$expect('[') then return
        if not min = @$expect('CHAR') then throw @$invalidToken()
        if not @$expect('-') then throw @$invalidToken()
        if not max = @$expect('CHAR') then throw @$invalidToken()
        if not @$expect(']') then throw @$invalidToken()
        return new RangeExpression(min.val[0], max.val[0])

    $readRepeatExpression: ->
        # '{' INT ('-' INT)? '}'
        if not @$expect('{') then return
        if not min = @$expect('INT') then throw @$invalidToken()
        max = min
        if @$expect('-')
            if not max = @$expect('INT') then throw @$invalidToken()
        if not @$expect('}') then throw @$invalidToken()
        return {min: parseInt(min.val), max: parseInt(max.val)}

@Parser_v3 = {
    Lexer: Lexer,
    Parser: Parser
}