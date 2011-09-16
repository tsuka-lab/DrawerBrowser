class Util
  @months: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
  @days:   ['Sun','Mon','Tue','Wed','Thu','Fri','Sat']

  @dateToHoursMinString: (date) ->
    dd = date.getHours()
    mm = date.getMinutes()
    if dd < 10
      dd = '0' + dd
    if mm < 10
      mm = '0' + mm
    "#{dd}:#{mm}"

BoxIdLabel =
  '01': 'Display Cables'
  '02': 'Camera'
  '03': 'Audio Cables'
  '04': 'Lighting'
  '05': 'Input Devices'
  '06': 'Audio Devices'
  '07': 'LAN Cables'
  '08': 'USB Cables'
  '09': 'Web Cams'
  '10': 'Computer Peripherals'
  '11': 'Input Devices 2'
  '12': 'Sanitary'

ImageType =
  inner: 1
  outer: 2

class Image extends Backbone.Model
  defaults:
    'filename': '' ## 08_1_1304687608.jpg

  initialize: ->
    values = @getFilename().split('.')[0].split('_')
    @boxId = values[0]
    @type  = if values[1] == '1' then ImageType.inner else ImageType.outer
    @timeSecString = values[2]
    @timeSec = parseInt(@timeSecString)
    date = new Date()
    date.setTime(@timeSec * 1000)
    @date = date

  getFilename: -> @get 'filename'
  getBoxId: -> @boxId
  getType:  -> @type
  getDate:  -> @date
  getDateString: -> "#{@date.getFullYear()}-#{@date.getMonth() + 1}-#{@date.getDate()}"
  getTimeSecString: -> @timeSecString
  getTimeSec: -> @timeSec
  getPath:  -> "/drawer-images/#{ @getFilename() }"
  getThumbMiddlePath: -> "/thumb/middle/#{ @getFilename() }"
  getThumbSmallPath: -> "/thumb/small/#{ @getFilename() }"

#
# 箱の内側と外側の画像のペア
#
class ImagePair extends Backbone.Model
  defaults:
    id: ''

  initialize: ->
    @innerImage = null
    @outerImage = null

  addImage: (image) ->
    switch image.getType()
      when ImageType.inner
        @innerImage = image
      when ImageType.outer
        @outerImage = image

  getInnerImage: -> @innerImage
  getOuterImage: -> @outerImage
  getInnerOrOuterImage: ->
    @innerImage || @outerImage
  getDate: ->
    image = @innerImage || @outerImage
    if image
      image.getDate()
    else
      new Date()

class ImagePairList extends Backbone.Collection
  model: ImagePair

  comparator: (imagePair) ->
    imagePair.getDate().getTime()

  addImage: (image) ->
    imagePair = @get image.getTimeSecString()  # @imagePairs[image.getTimeSecString()]
    unless imagePair
      imagePair = new ImagePair({id: image.getTimeSecString()})
      @add imagePair
    imagePair.addImage image

#
# 箱を1回開けたときの一連の画像
#
class Sequence extends Backbone.Model
  defaults:
    id: ''
    boxId: ''

  initialize: ->
    @imagePairs = new ImagePairList()

  addImage: (image) ->
    @imagePairs.addImage image
    @set({id: image.getTimeSecString()}) unless @get 'id'
    @set({boxId: image.getBoxId()}) unless @get 'boxId'

  getImagePairList: -> @imagePairs
  getDate: ->
    @imagePairs.at(0).getDate()

class SequenceList extends Backbone.Collection
  model: Sequence

  comparator: (seq) ->
    (new Date()).getTime() - seq.getDate().getTime()

  initialize: ->
    @images = []

  addImage: (image) ->
    # とりあえず画像を配列に突っ込んでおいて、あとでSequenceを分類する。
    @images.push image

  classifySequence: ->
    # 時間順に並べて、時間の近いものをくっつけていく
    images = _.sortBy @images, (img) -> img.getTimeSec()
    seq = null
    prev = null
    _.each images, (img) =>
      if prev == null # 初回
        seq = new Sequence()
      else if (img.getTimeSec() - prev.getTimeSec()) > 10
        ## 10秒以上離れていたら新しいSequenceを作成
        @add seq
        seq = new Sequence()
      seq.addImage img
      prev = img
    @add seq ## 最後のSequenceを追加

#
# 1日
#
class Day extends Backbone.Model
  defaults:
    id: ''
    date: null
    boxId: ''

  initialize: ->
    @sequenceList = new SequenceList()

  addImage: (image) ->
    @sequenceList.addImage image

  classifySequence: ->
    @sequenceList.classifySequence()

  getSequenceList: -> @sequenceList

  getDate: -> @get 'date'

  setOtherBoxes: (boxList) ->
    @boxList = boxList

  getAllBoxSequenceList: ->
    ## 同一日（同一id）のsequence
    sequenceList = new SequenceList()
    @boxList.each (box) =>
      day = box.getDates().get(@id)
      if day
        day.getSequenceList().each (seq) =>
          sequenceList.add seq
    sequenceList

class DateList extends Backbone.Collection
  model: Day

  comparator: (day) ->
    (new Date()).getTime() - day.getDate().getTime()

  addImage: (image) ->
    day = @get image.getDateString()
    unless day
      day = new Day
        id:    image.getDateString()
        date:  image.getDate()
        boxId: image.getBoxId()
      @add day
    day.addImage image

  classifySequence: ->
    @each (day) ->
      day.classifySequence()

  setOtherBoxes: (boxList) ->
    @each (day) =>
      day.setOtherBoxes(boxList)

#
# 箱
#
class Box extends Backbone.Model
  initialize: ->
    @dates = new DateList()

  addImage: (image) ->
    @dates.addImage image

  classifySequence: ->
    @dates.classifySequence()

  setOtherBoxes: (boxList) ->
    @dates.setOtherBoxes(boxList)

  getDates: -> @dates

class BoxList extends Backbone.Collection
  model: Box

  comparator: (box) -> box.id

  initialize: ->
    @currentBox = null

  getCurrentBox: => @currentBox

  setCurrentBoxId: (boxId) =>
    @currentBox = @get boxId

  setImageList: (imageList) ->
    ## 先に各箱1日ごとに画像を分類
    imageList.each (image) =>
      @addBoxAndImage image
    ## さらにSequence単位で分類する
    @each (box) =>
      box.classifySequence()
    @each (box) =>
      box.setOtherBoxes(@)
    @currentBox = @at(0) unless @currentBox

  addBoxAndImage: (image) ->
    box = @get image.getBoxId()
    unless box
      box = new Box({id: image.getBoxId()})
      @add box
    box.addImage image

class Timeline extends Backbone.Model
  setImageList: (imageList) ->
    @allDateList = new DateList()
    imageList.each (image) =>
      @allDateList.addImage image
    @allDateList.classifySequence()

  getAllDateList: ->
    @allDateList

#
# サーバから読み込む画像一覧
#
class ImageList extends Backbone.Collection
  model: Image
  url:  'images.json'


#
# 写真のView
#
class ImageView extends Backbone.View
  tagName: 'div'
  className: 'img-container'

  initialize: -> @render()

  render: ->
    if @model
      $('<img/>').attr(
        'src', @model.getThumbMiddlePath()
      ).appendTo(@el)
    @

class ImagePairView extends Backbone.View
  tagName: 'td'

  initialize: -> @render()

  render: ->
    wrapper = $('<div/>').addClass('pair').appendTo(@el)
    outerImageView = new ImageView({model: @model.getOuterImage()})
    innerImageView = new ImageView({model: @model.getInnerImage()})
    wrapper.append(outerImageView.el)
    wrapper.append(innerImageView.el)
    @

class SequenceView extends Backbone.View
  tagName: 'td' 

  imageRendered: false

  initialize: ->
    $(@el).attr('id', "sequence#{ @model.get('id') }").addClass('sequence-container')
    setTimeout(() =>
      $(window).bind('scroll', @lazyRender).triggerHandler('scroll')
    , 300)

  isDisplayedInnerWindow: (elem) ->
    elemLeft = $(elem).offset().left
    winLeft = $(window).scrollLeft()
    winRight = winLeft + $(window).width()
    (winLeft-100 <= elemLeft <= winRight+100)

  lazyRender: () =>
    return unless @isDisplayedInnerWindow(@el)
    @render()
    $(window).unbind('scroll', @lazyRender)

  render: ->
    ## 時間表示
    date = @model.getDate()
    $('<div/>').addClass('time').text(
      Util.dateToHoursMinString(date)
    ).appendTo(@el)

    table = $('<table/>').addClass('sequence').appendTo(@el)
    tr = $('<tr/>').appendTo(table)

    # とりあえず最初の1つだけ
    # pair = @model.getImagePairList().at(0)
    # pairView = new ImagePairView({model: pair})
    # tr.append(pairView.el)

    # とりあえずPairを全部並べる
    # @model.getImagePairList().each (pair) =>
    #   pairView = new ImagePairView({model: pair})
    #   tr.append(pairView.el)

    # 複数あるときはアニメーションさせる
    if @model.getImagePairList().length > 1
      elems = []
      @model.getImagePairList().each (pair) =>
        pairView = new ImagePairView({model: pair})
        tr.append(pairView.el)
        elems.push pairView.el
      @animation elems
    else
      pairView = new ImagePairView({model: @model.getImagePairList().at(0)})
      tr.append(pairView.el)

  animation: (elems) =>
    for elem in elems
      $(elem).hide()
    @_animation(elems, 0)

  _animation: (elems, index) =>
    $(elems[index]).show()
    if index >= elems.length-1
      setTimeout( =>
        $(elems[index]).hide()
        @_animation(elems, 0)
      , 1500)
    else
      setTimeout( =>
        $(elems[index]).hide()
        @_animation(elems, index+1)
      , 200)

class DayView extends Backbone.View
  tagName: 'td'

  initialize: ->
    @render()

  render: ->
    container = $('<div/>').addClass('day-container').appendTo(@el)
    @makeDateElem().appendTo(container)

    table = $('<table/>').addClass('sequences').appendTo(container)
    tr = $('<tr/>').appendTo(table)

    ## 同一日の他の箱も含む
    prevLinksContainer = null
    prevLinkBoxId = null
    prevLinksCount = 0
    @shownSeqCount = 0
    @max = 20

    @model.getAllBoxSequenceList().each (seq) =>
      if seq.get('boxId') == @model.get('boxId') ## この箱
        ## 選択中の箱ならSequenceViewを追加
        prevLinkContainer = null
        prevLinkBoxId = null
        return if @shownSeqCount >= @max ## 1日に極端に画像が多いときは省略
        seqView = new SequenceView({model: seq})
        tr.append(seqView.el)
        @shownSeqCount += 1
      else
        ## リンクを追加
        linksContainer = prevLinksContainer
        if !linksContainer || prevLinksCount >= 4
          linksContainer = $('<td/>').addClass('box-link-container').appendTo(tr)
          prevLinksContainer = linksContainer
          prevLinksCount = 0
        if prevLinkBoxId != seq.get('boxId')
          linksContainer.append( @makeLink(seq) )
          prevLinkBoxId = seq.get('boxId')
          prevLinksCount += 1

    ## prevLinkContainerに入ってたら追加

  makeLink: (seq) =>
    labelText = BoxIdLabel[seq.get('boxId')]
    timeLabel = $('<div>').addClass('time-label').text( Util.dateToHoursMinString(seq.getDate()) )
    boxLabel = $('<div/>').addClass('box-label').text(labelText)
    div = $('<div/>').addClass('box-link').attr('title', labelText)
    div.append(boxLabel)
    div.append(timeLabel)

    ## 画像をあとから追加
    setTimeout(() =>
      $(window).bind('scroll', {seq: seq, container: div}, @lazyAppendImage).triggerHandler('scroll')
    , 600)

    div.click () ->
      appRouter.navigate "box/#{ seq.get('boxId') }/#{ seq.get('id') }", true
    div

  lazyAppendImage: (args) =>
    return unless @isDisplayedInnerWindow(@el)
    @appendImage(args.data.seq, args.data.container)
    $(window).unbind('scroll', @lazyAppendImage)

  appendImage: (seq, container) ->
    image = seq.getImagePairList().at(0).getInnerOrOuterImage()
    img = $('<img/>').attr('src', image.getThumbSmallPath()).appendTo(container)

  isDisplayedInnerWindow: (elem) ->
    elemLeft = $(elem).offset().left
    winLeft = $(window).scrollLeft()
    winRight = winLeft + $(window).width()
    (winLeft-100 <= elemLeft <= winRight+100)

  makeDateElem: ->
    date = @model.getDate()
    div = $('<div/>').addClass('date-label')
    
    $('<div/>').addClass('month').text(
      Util.months[date.getMonth()]
    ).appendTo(div)
    $('<span/>').addClass('date').text(
      date.getDate()
    ).appendTo(div)
    $('<span/>').addClass('year').text(
      date.getFullYear()
    ).appendTo(div)
    $('<span/>').addClass('day').text(
      "(#{Util.days[date.getDay()]})"
    ).appendTo(div)
    div


#
# 箱のView
# modelはBox
#
class BoxView extends Backbone.View
  tagName: 'table'
  className: 'box'

  initialize:  ->
    @render()

  render: ->
    tr = $('<tr/>')
    $(@el).html tr
    ## Dayを描画
    @max = 30 # 1日最大何件
    @shownDaysCount = 0
    @model.getDates().each (day) =>
      return if @shownDaysCount >= @max
      dayView = new DayView({model: day})
      tr.append dayView.el
      @shownDaysCount += 1
    $(@el).mousewheel (event, delta) =>
      win = $(window)
      d = if delta > 0
            win.scrollLeft() - 80
          else
            win.scrollLeft() + 80
      win.scrollLeft(d)

#
# Timeline
#
class TimelineDateView extends Backbone.View
  tagName: 'td'

  initialize: ->
    ## modelはDay
    @render()

  render: ->
    # 1日
    container = $('<div/>').addClass('day').appendTo(@el)
    # 日付
    date = @model.getDate()
    $('<span/>').addClass('month').text(Util.months[date.getMonth()]).appendTo(container)
    $('<span/>').addClass('date').text(date.getDate()).appendTo(container)

    canvas = $('<canvas/>').attr({width: 48, height: 20}).appendTo(container)
    prevHours = 0
    count = 0
    @model.getSequenceList().each (seq) =>
      date = seq.getDate()
      hours = date.getHours()
      if hours == prevHours
        count += 1
      else
        count = 1
      prevHour = hours
      x = 48 - date.getHours() * 2
      canvas.drawLine
        strokeStyle: '#FFFFFF'
        strokeWidth: 1
        x1: x, y1: 0
        x2: x, y2: 20

class TimelineView extends Backbone.View
  tagName: 'table'
  className: 'timeline'

  events:
    'mousedown': 'onMousedown'
    'mouseup':   'onMouseup'

  initialize: () ->
    @render()

  render: ->
    #table = $('<table/>').addClass('timeline').appendTo(@el)
    tr = $('<tr/>').appendTo(@el)
    @model.getAllDateList().each (date) =>
      timelineDateView = new TimelineDateView({model: date})
      tr.append(timelineDateView.el)

  dragStartMouseX: 0
  dragStartMouseY: 0
  dragging: false

  onMousedown: (event) =>
    @dragStartMouseX = event.pageX
    @dragStartMouseY = event.pageY
    @dragging = true

  onDrag: (event) =>
    return unless @dragging

  onMouseup: (event) =>
    @dragging = false
    
#
# 全体のView: modelはBoxList
#
class AppView extends Backbone.View
  el: $('#main')

  targetSequenceId: null

  initialize: (boxId, sequenceId) ->
    ## 読み込んで最初のBoxViewを表示
    @targetSequenceId = sequenceId if sequenceId?
    imageList = new ImageList()
    imageList.bind 'reset', () =>
      @boxList = new BoxList()
      @boxList.setImageList(imageList)
      @boxList.setCurrentBoxId(boxId)

      ## 全体タイムライン用
      @timeline = new Timeline()
      @timeline.setImageList(imageList)
      @renderTimeline()

      @render()
    imageList.fetch()

  render: =>
    @el.empty()
    @renderTabs()
    $(window).scrollLeft(0) ## 一度左に戻す
    boxView = new BoxView({ model: @boxList.getCurrentBox() })
    @el.html boxView.el
    if @targetSequenceId?
      seq = $('#sequence'+@targetSequenceId)
      if seq.length
        setTimeout(() =>
          $(window).scrollLeft(seq.offset().left - 10)
          #$("html,body").animate({scrollLeft: seq.offset().left - 10}, 300);
        , 500)

  renderTabs: =>
    tabs = $('#tabs')
    tabs.empty()
    @boxList.each (box) =>
      tab = $('<div/>').addClass('tab').appendTo(tabs)
      if (@boxList.getCurrentBox().id == box.id)
        tab.addClass('selected').text(BoxIdLabel[box.id])
      else
        tab.text(BoxIdLabel[box.id]).click () =>
          appRouter.navigate "box/#{box.id}", true

  switchBox: (boxId, sequenceId) =>
    @boxList.setCurrentBoxId(boxId)
    @targetSequenceId = sequenceId if sequenceId?
    @render()

  renderTimeline: =>
    $('#timeline').append( new TimelineView({model: @timeline}).el )

#
# メインコントローラ
#
class AppRouter extends Backbone.Router
  routes:
    '': 'index'
    'box/:boxId': 'box'
    'box/:boxId/:sequenceId': 'box'

  index: ->
    @navigate "box/01"

  box: (boxId, sequenceId) ->
    if AppRouter.appView
      AppRouter.appView.switchBox(boxId, sequenceId)
    else
      AppRouter.appView = new AppView(boxId, sequenceId)

  @appView: null

appRouter = null
$ ->
  appRouter = new AppRouter()
  Backbone.history.start()
