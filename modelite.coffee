###
  modelite.js
  轻量级数据双向绑定工具
###

do ->
  throw new Error "First require jQuery!" unless jQuery


  ###
    产生随机数或字符串
    可自定义字符串随机字符表
  ###

  random = (max = 10, stringMode = no) ->
    [max, stringMode] = [8, max] if typeof max is "boolean"
    return Math.floor (do Math.random) * max unless stringMode
    charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    charset = stringMode if typeof stringMode is "string" 
    str = ""
    while str.length < max
      str += charset[random charset.length]
    str


  ###
    根据 keypath 从源数据对象中获得数据
  ###

  getData = (source, keypath) ->
    return unless source
    index = keypath.indexOf "."
    return source[keypath] if index is -1
    field = keypath.substr 0, index
    field = num unless isNaN num = parseInt field
    return unless source[field]
    getData source[field], keypath.substr index + 1


  ###
    根据 keypath 将新数据存入源数据对象中
  ###

  setData = (source, keypath, value) ->
    index = keypath.indexOf "."
    if index is -1
      if typeof value is "undefined" then delete source[keypath]
      else source[keypath] = value
      return value
    field = keypath.substr 0, index
    field = num unless isNaN num = parseInt field
    keypath = keypath.substr index + 1
    unless source[field]
      test = keypath
      index = keypath.indexOf "."
      test = test.substr 0, index unless index is -1
      source[field] = if isNaN parseInt test then {} else []
    setData source[field], keypath, value


  ###
    element 事件绑定
    事件设置：
      ml-events="(eventType)eventName:argValue, ...; (eventType)..."
      ml-events="(eventType)eventName:argName=argValue, ...; (eventType)...
    insert 和 remove 动作事件设置：
      ml-insert="keypath"
      ml-remove="keypath"
  ###

  deal = (dealIt) ->
    eventReg = /\( *(\w+) *\) *(\w+) *\:?([^\(]*)/g
    while result = eventReg.exec dealIt.attr "ml-events"
      [type, name, raw] = result[1..3]
      type = "ml-#{type}" if type in ["repeat", "each", "insert", "remove"]

      tagName = do dealIt[0].tagName.toLowerCase
      if type is "change" and tagName is "input"
        type = "ml-change"

      dealIt.on type, {type, name, raw}, (event, args...) ->
        do event.stopPropagation

        {type, name, raw} = event.data
        raw ?= ""

        handler = ml.EVENTS?[name]
        return if typeof handler isnt "function"

        it = $ @
        rootIt = it.closest "[name='#']"
        rootStr = rootIt.attr "ml-binding"
        if typeof rootStr is "string"
          regExp = new RegExp rootStr.replace /\d+/g, '#'

        parseData = (val = "") ->
          val = do val.trim
          if regExp and (val.indexOf "#") isnt -1
            val = val.replace regExp, rootStr
          val

        event.data = parseData raw
        if (raw.indexOf "=") isnt -1
          event.data = {}
          for str in raw.split "," when str 
            [key, val] = str.split "="
            event.data[do key.trim] = parseData val

        args.unshift event
        handler.apply it, args

    # 绑定默认 insert 和 remove 动作事件
  
    for type in ["insert", "remove"]
      continue unless keypath = dealIt.attr "ml-#{type}"

      dealIt.on "click", {type, keypath}, (event) ->
        do event.stopPropagation

        {type, keypath} = event.data
        keypath ?= ""

        handler = ml[type]
        return if typeof handler isnt "function"

        it = $ @
        keypath = do keypath.trim
        if (keypath.indexOf "#") isnt -1
          rootIt = it.closest "[name='#']"
          rootStr = rootIt.attr "ml-binding"
          regExp = new RegExp rootStr.replace /\d+/g, '#'
          keypath = keypath.replace regExp, rootStr

        handler.call it, keypath
        setTimeout -> it.triggerHandler "ml-#{type}", keypath



  ###
    缓存数组类型数据的 element 模版
  ###

  build = (templateIt) ->
    ml.TEMPLATES ?= {}
    return build templateIt if ml.TEMPLATES[id = random yes]
    rootIt = templateIt.closest "[name][name!='#']"
    ml.TEMPLATES[id] = templateIt
    rootIt.attr "ml-template", id
    do templateIt.detach


  ###
    双向绑定数据到 element
  ###

  update = (rootIt, data) ->
    keypath = rootIt.attr "ml-binding"
    unless keypath
      rootIt.attr "ml-binding", keypath = rootIt.attr "name"
    data = getData ml.DATA, keypath unless data

    subIts = rootIt.find "[name]"
    template = rootIt.attr "ml-template"

    unless template
      if subIts.length is 0
        return update.single keypath, rootIt, data

      data = setData ml.DATA, keypath, {} unless data
      subIts.each ->
        it = $ @
        return if not update.bound and it.attr "ml-binding"
        name = it.attr "name"
        it.attr "ml-binding", "#{keypath}.#{name}"
        update it, data[name]
      return

    unless $.isArray data
      data = setData ml.DATA, keypath, []
    data.reserve = 0
    unless isNaN num = parseInt rootIt.attr "ml-reserve"
      data.reserve = num
    len = data.reserve - data.length
    data.push null for i in [0...len] if len > 0

    update.repeat rootIt, ml.TEMPLATES[template], data
    rootIt.triggerHandler "ml-repeat", data.length

  # 绑定数组类型数据

  update.repeat = (rootIt, templateIt, data) ->
    do rootIt.empty
    return unless $.isArray data

    rootStr = rootIt.attr "ml-binding"
    template = rootIt.attr "ml-template"

    length = data.length
    for val, i in data
      keypath = "#{rootStr}.#{i}"
      repeatIt = templateIt.clone true
      repeatIt.attr "ml-binding", keypath
      repeatIt.attr "ml-belong", template
      rootIt.append repeatIt

      update.repeat.mode repeatIt, i, length

      valueIt = repeatIt.find "[name='$']"
      unless valueIt.length
        update repeatIt, val 
      else
        update.single keypath, valueIt, val
      repeatIt.triggerHandler "ml-each", i

  # 根据模式设置来显示数组元素

  update.repeat.mode = (repeatIt, index, length) ->
    lastIndex = length - 1
    template = repeatIt.attr "ml-belong"
    repeatIt.find("[ml-repeat]").each ->
      it = $ @
      mode = it.attr "ml-repeat"
      if template is it.closest("[name='#']").attr "ml-belong"
        it.css "display", ""
        switch it.attr "ml-repeat"
          when "header" then it.css "display", "none" if index > 0
          when "body" then it.css "display", "none" unless 0 < index < lastIndex
          when "odd" then it.css "display", "none" unless index % 2
          when "even" then it.css "display", "none" if index % 2
          when "footer" then it.css "display", "none" if index < lastIndex


  # 绑定其他数据类型数据
      
  update.single = (keypath, singleIt, data) ->

    # 获得默认数据

    if typeof data is "undefined" or data is null or data.length is 0
      data = (singleIt.attr "ml-default") or null
      if typeof data is "string" and /^[\[\{]/.test data
        data = JSON.parse data
      setData ml.DATA, keypath, data

    # 根据 element 标签类型绑定数据

    switch do singleIt[0].tagName.toLowerCase
      when "input"
        type = (singleIt.attr "type") or "text"
        switch do type.toLowerCase
          when "text", "email"
            eventType = "keyup blur"
          else
            eventType = "change"

        unless singleIt.data "changeEvent"
          singleIt.data "changeEvent", true
          singleIt.on eventType, {type}, (event) ->
            do event.stopPropagation

            inputIt = $ @
            isCheckbox = event.data.type is "checkbox"
            keypath = inputIt.attr "ml-binding"
            value = inputIt.data "value"

            if typeof value is "undefined"
              switch event.data.type
                when "checkbox", "radio"
                  its = $ "[ml-binding='#{keypath}'][type='#{event.data.type}']"
                  value = its.index inputIt
                else
                  value = do inputIt.val
            oldValue = getData ml.DATA, keypath

            if isCheckbox
              oldValue = [] unless $.isArray oldValue
              if inputIt.prop "checked"
                return if oldValue.indexOf(value) isnt -1
                oldValue.push value
                setData ml.DATA, keypath, oldValue
              else
                return if oldValue.indexOf(value) is -1
                oldValue.splice oldValue.indexOf(value), 1
                setData ml.DATA, keypath, oldValue
            else
              return if oldValue is value
              setData ml.DATA, keypath, value

            inputIt.triggerHandler "ml-change"
            $ "[ml-binding='#{keypath}']"
              .not inputIt
              .each ->
                it = $ @
                valueIt = it.find "[name='$']"
                unless valueIt.length
                  update.single keypath, it, value
                else
                  update.single keypath, valueIt, value

        switch type
          when "checkbox"
            return unless $.isArray data
            $ "[ml-binding='#{keypath}'][type='checkbox']"
              .not singleIt
              .each (i) ->
                it = $ @
                value = parseInt it.data "value"
                value = i if isNaN value
                it.prop "checked", (data.indexOf value) isnt -1

          when "radio"
            return if isNaN(num = parseInt data)
            $ "[ml-binding='#{keypath}'][type='radio']"
              .not singleIt
              .each (i) ->
                it = $ @
                value = parseInt it.data "value"
                value = i if isNaN value
                it.prop "checked", num is value

          else
            singleIt.val data

      when "meta"
        setData ml.DATA, keypath, singleIt.attr "content"

      when "img"
        data ?= singleIt.attr "ml-placeholder"
        singleIt.attr "src", data

      else
        data ?= singleIt.attr "ml-placeholder"
        singleIt.text data


  ###
    插入 element
  ###

  insert = (rootIt, index, data) ->
    unless template = rootIt.attr "ml-template"
      return throw new Error "template is #{template}"

    rootStr = rootIt.attr "ml-binding"
    keypath = "#{rootStr}.#{index}"
    repeatIt = ml.TEMPLATES[template].clone true
    repeatIt.attr "ml-binding", keypath
    repeatIt.attr "ml-belong", template

    beforeIt = rootIt.find "[ml-binding='#{keypath}']"
    unless beforeIt.length then rootIt.append repeatIt
    else repeatIt.insertBefore beforeIt
    order rootIt

    singleIt = repeatIt.find "[name='$']"
    unless singleIt.length then update repeatIt, data 
    else update.single keypath, singleIt, data
    repeatIt.triggerHandler "ml-each", index

    
  ###
    删除 element
  ###

  remove = (rootIt, index) ->
    rootStr = rootIt.attr "ml-binding"
    keypath = "#{rootStr}.#{index}"
    removeIt = rootIt.find "[ml-binding='#{keypath}']"
    unless removeIt.length
      return throw new Error "not found #{keypath}"
    setTimeout removeIt.remove, 1000
    do removeIt.detach
    order rootIt


  ###
    重新整理 element 序列号
  ###

  order = (rootIt) ->
    rootStr = rootIt.attr "ml-binding"
    template = rootIt.attr "ml-template"
    orderReg = new RegExp "#{rootStr}\\.\\d+", "g"

    repeatIts = rootIt.find "[ml-belong='#{template}']"
    length = repeatIts.length

    repeatIts.each (i) ->
      it = $ @
      repeatStr = it.attr "ml-binding"

      replaceStr = "#{rootStr}.#{i}"
      it.attr "ml-binding", repeatStr.replace orderReg, replaceStr
      update.repeat.mode it, i, length

      it.find "[ml-binding*='#{repeatStr}']"
        .each ->
          it = $ @
          keypath = it.attr "ml-binding"
          it.attr "ml-binding", keypath.replace orderReg, replaceStr


  ###
    数据操作
  ###

  modelite = window.ml = window.modelite = (keypath, data) ->
    if typeof keypath isnt "string"
      return throw TypeError "#{keypath} is not string"
    if typeof data is "undefined"
      return getData ml.DATA, keypath
    setData ml.DATA, keypath, data

    $ "[ml-binding='#{keypath}']"
      .each ->
        update $ @
  
  # 清除数据

  ml.clear = (keypath) ->
    ml keypath, null

  # 插入数据

  ml.insert = (keypath, data = null) ->
    if typeof keypath isnt "string"
      return throw TypeError "#{keypath} is not string"

    nIndex = keypath.lastIndexOf "."
    index = NaN
    if nIndex isnt -1
      index = parseInt keypath.substr nIndex + 1
    if isNaN index
      index = Number.MAX_VALUE
    else
      keypath = keypath.substr 0, nIndex

    source = getData ml.DATA, keypath
    unless $.isArray source
      source = setData ml.DATA, keypath, []
    length = source.length
    index = length if index > length
    index = length + index if index < 0
    index = 0 if index < 0
    source.splice index, 0, data

    $ "[ml-binding='#{keypath}']"
      .each ->
        insert ($ @), index, data

  # 移除数据

  ml.remove = (keypath) ->
    if typeof keypath isnt "string"
      return throw TypeError "#{keypath} is not string"

    nIndex = keypath.lastIndexOf "."
    index = NaN
    if nIndex isnt -1
      index = parseInt keypath.substr nIndex + 1
    if isNaN index
      index = Number.MAX_VALUE
    else
      keypath = keypath.substr 0, nIndex

    source = getData ml.DATA, keypath
    return unless ($.isArray source) and source.length

    lastIndex = source.length - 1
    index = lastIndex if index > lastIndex
    index = lastIndex + index if index < 0
    index = 0 if index < 0
    source.splice index, 1

    $ "[ml-binding='#{keypath}']"
      .each ->
        remove ($ @), index

    if source.length < source.reserve
      for i in [source.length...source.reserve]
        ml.insert keypath


  ###
    手动触发事件
  ###

  ml.emit = (name, args...) ->
    if args.length is 1 and typeof args[0] is "string"
      it = $ "[ml-binding='#{name}']"
      return it.triggerHandler args[0]
    ml.EVENTS?[name]?.apply null, args


  ###
    多语言配置
  ###

  ml.localizeString = (id, text) ->
    I18N = ml "_I18N"
    text = I18N[id] if typeof I18N[id] is "string"
    text or id


  ###
    自动初始化
  ###

  $ ->
    ml.DATA ?= {}
    ml.EVENTS ?= {}
    $ "[ml-events], [ml-insert], [ml-remove]"
      .each ->
        deal $ @
    $ "[name='#']"
      .each ->
        build $ @
    $ "[name]"
      .each ->
        update $ @
    update.bound = yes


# EOF
