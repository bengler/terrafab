EventEmitter = require("events").EventEmitter

class SuggestionCompleter extends EventEmitter

  ###
     Give it a qQuery @intputEl (the input(type='text') field)
     and a @listEl (a UL) to move the suggestion elements into.

     Also, options for
      @options.suggestionField - name of the suggest-type field in ES.
      @options.suggestionName, - what to call the response back from ES (key in hash returned as array).
      @options.indexName - the ES index to query.
      @options.host and @options.port - map to Elastic Search server.

    Emits 'submit' when suggestion is selected
    Emits 'arrowdown' and 'arrowup' when the user browse the list with the arrow keys
    Emits 'enter' and 'tab' when user submits with those keys respectively.

  ###

  constructor: (@inputEl, @listEl, @options={}) ->
    @host = @options.host || 'localhost'
    @port = @options.port || '9200'
    @listEl.hide()
    @suggestionField = @options.suggestionField || "suggest"
    @suggestionName = @options.suggestionName || "placesuggest"
    @indexName = @options.indexName || "places"
    @nrOfResults = @options.nrOfResults || 10
    @q = null
    @index = 0
    @payload = null
    @suggestionEls = $()
    @inputEl.on('input', (e) => @onInput(e))
    @inputEl.on('keydown', (e) => @onKeyDown(e))

  onInput: (e) ->
    q = $("#q").val()
    @listEl.empty() if q.length < 2
    if q.length >= 2 and q != @q
      @q = q
      @getResults(q).then (result) =>
        @emit('result', result)
        completions = result[@suggestionName][0].options
        @listEl.empty().show()
        $.map(completions, (completion) =>
          li = $("<li data-payload='" +
              JSON.stringify(completion.payload) +
                "'>"+completion.text+"</li>")
          li.on('click', (e) =>
              @select($(e.target))
              @submit($(e.target))
              @inputEl.focus()
          )
          @listEl.append(li)
        )

  select: (targetEl) ->
    @selectedEl = targetEl || $("##{@listEl.attr('id')} li.selected").first()
    @suggestionEls = $("##{@listEl.attr('id')} li")
    @suggestionEls.removeClass("selected")
    $(@suggestionEls[@index]).addClass('selected')
    @index = @suggestionEls.index($("##{@listEl.attr('id')} li.selected"))
  onKeyDown: (e) ->
    @select()
    keycode = event.which || event.keyCode
    switch keycode
      when 40 # Arrow Down
        if @index == -1 or @index > @suggestionEls.length-2
          @index = 0
        else
          @index++
        @emit('arrowdown', @selectedEl)
      when 38 # Arrow Up
        if @index < 0
          @index = @suggestionEls.length-1
        else
          @index--
        @emit('arrowup', @selectedEl)
      when 13, 9 # Enter, tab (submits)
        if keycode == 9
          @emit('tab', @selectedEl)
        else
          @emit('enter', @selectedEl)
        @select()
        @submit(@selectedEl)
        e.preventDefault()

    @select()

  submit: (selectedEl) ->
    selectedEl ||= $(e.target)
    @suggestionEls.removeClass("current")
    @suggestionEls.removeClass("selected")
    selectedEl.addClass('current')
    @payload = @selectedEl.data("payload")
    @emit('submit', {el: @selectedEl, payload: @payload})

  getResults: (q) ->
    @q = q
    params = {
      "text": q,
      "completion": {
        "field": @suggestionField,
        "size": @nrOfResults
      }
    }
    $.post('http://'+@host + ':' +
        @port + '/'+@indexName+'/_suggest',
      "{\"#{@suggestionName}\":"+JSON.stringify(params)+"}"
    )


module.exports = SuggestionCompleter
