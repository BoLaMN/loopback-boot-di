module.exports = ->

  @factory 'events', (utils) ->
    { each } = utils 
    
    events = {}
    data = {}

    iterate = (ev, fn) ->
      if not events
        return

      e = events[ev] or []
      i = e.length - 1

      while i >= 0 and e
        fn e[i] if e[i]
        i--

    id = 0

    add: (ev, cb) ->
      cb.id = id++

      events[ev] ?= []
      events[ev].push cb

      old = data[ev] 

      if old?.length
        old.forEach cb  

      events[ev].length

    on: (ev, cb) ->
      @add ev, cb
      @

    off: (ev, cb) ->
      if not events?[ev]
        return

      itr = iterate.bind @

      itr ev, (e, i) =>
        if e is cb
          events[ev].splice i, 1

      if not events[ev]?.length
        delete events[ev]

    broadcast: (args...) ->
      itr = iterate.bind @

      itr '*', (e) =>
        e.apply @, args

      @

    emit: (ev, args...) ->
      itr = iterate.bind @
      
      data[ev] ?= args

      itr ev, (e) =>
        e.apply @, args

      @broadcast ev, args...

      @

    once: (ev, cb) ->
      return @ if not cb

      c = =>
        events[ev].splice idx, 1
        cb.apply @, arguments

      idx = @add ev, c

      @

    get: (type, names, next) ->

      get = (name, cb) =>
        @once type + ':' + name, cb

      if typeof next isnt 'function'
        if Array.isArray names
          names.map (name) =>
            @[name]
        else
          @[names]
      else
        each names, get, next
