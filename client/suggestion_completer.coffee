EventEmitter = require("events").EventEmitter

class SuggestionCompleter extends EventEmitter

  constructor: (@inputEl, @listEl, @options={}) ->
    @host = @options.host || 'localhost'
    @port = @options.port || '9200'
    @suggestionField = @options.suggestionField || "suggest"
    @suggestionName = @options.suggestionName || "placesuggest"
    @indexName = @options.indexName || "places"
    @term = null
    @inputEl.on('input', (e) =>
      q = $("#q").val()
      if q.length >= 2 and q != @term
        @term = q
        @getAutoCompleteResults(q).then (result) =>
          @emit('result', result)
          completions = result[@suggestionName][0].options
          @listEl.empty()
          $.map(completions, (completion) =>
            li = $("<li data-payload='" +
                JSON.stringify(completion.payload) +
                  "'>"+completion.text+"</li>")
            li.on('click', (e) =>
              $("##{@listEl.attr('id')} li").removeClass('selected')
              li.addClass('selected')
              @submit(e)
            )
            @listEl.append(li)
          )
    )
    @index = 0
    @payload = null
    @inputEl.on('keydown', (e) =>
      suggestionEls = $("##{@listEl.attr('id')} li")
      keycode = event.which || event.keyCode
      @index = suggestionEls.index($("##{@listEl.attr('id')} li.selected"))
      switch keycode
        when 40 # Down
          if @index == -1 or @index > suggestionEls.length-2
            @index = 0
          else
            @index++
          suggestionEls.removeClass('selected')
          $(suggestionEls[@index]).addClass('selected')
          @emit('arrowdown',
            $("##{@listEl.attr('id')} li.selected").first()
          )
        when 38 # Up
          if @index < 0
            @index = suggestionEls.length-1
          else
            @index--
          suggestionEls.removeClass('selected')
          $(suggestionEls[@index]).addClass('selected')
          @emit('arrowup',
            $("##{@listEl.attr('id')} li.selected").first()
          )
        when 13, 9 # Enter, tab
          @submit(e)
    )

  submit: (e) ->
    $("##{@listEl.attr('id')} li").removeClass("current")
    @payload = $("##{@listEl.attr('id')} li.selected").first().data("payload")
    @emit('submit',
      {el: $("##{@listEl.attr('id')} li.selected").first(), payload: @payload}
    )
    $("##{@listEl.attr('id')} li.selected").first().addClass("current")
    e.preventDefault()

  getAutoCompleteResults: (q) ->
    params = '{"' +
      @suggestionName + '": {"text": "' +
        q + '", "completion": {"field": "' +
          @suggestionField +
            '", "size": 6}}}'
    $.post('http://'+@host + ':' +
        @port +
          '/'+@indexName+'/_suggest', params
    )


module.exports = SuggestionCompleter
