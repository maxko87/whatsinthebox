MIN_BYTES = 100000

formatSizeUnits = (bytes) ->
  if (bytes >> 30) & 0x3FF
    bytes = (bytes >>> 30) + "." + (bytes & (3 * 0x3FF)) + "GB"
  else if (bytes >> 20) & 0x3FF
    bytes = (bytes >>> 20) + "." + (bytes & (2 * 0x3FF)) + "MB"
  else if (bytes >> 10) & 0x3FF
    bytes = (bytes >>> 10) + "." + (bytes & (0x3FF)) + "KB"
  else if (bytes >> 1) & 0x3FF
    bytes = (bytes >>> 1) + "Bytes"
  else
    bytes = bytes + "Byte"
  return bytes

getCSRF = ->
  text = ""
  possible = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
  i = 0
  while i < 15
    text += possible.charAt(Math.floor(Math.random() * possible.length))
    i++
  return text

getURLParameter = (name) ->
  decodeURI (RegExp(name + "=" + "(.+?)(&|$)").exec(location.search) or [null])[1]

getHashParams = ->
  hashParams = {}
  e = undefined
  a = /\+/g # Regex for replacing addition symbol with a space
  r = /([^&;=]+)=?([^&;]*)/g
  d = (s) ->
    decodeURIComponent s.replace(a, " ")
  q = window.location.hash.substring(1)
  hashParams[d(e[1])] = d(e[2])  while e = r.exec(q)
  return hashParams

extractName = (name) ->
  name[(name.lastIndexOf("/") + 1)...(name.length)]

setupTooltip = ->
  $(document).tooltip(
    show:
      effect: "appear"
      duration: 0
    hide:
      effect: "appear"
      duration: 0
    position:
      my: "center top"
      at: "center bottom+20px"
    items:
      ".node"
    content: ->
      return "<b>Name: </b>" + this.__data__.name + "<br><b>Size: </b>" + formatSizeUnits(this.__data__.size)
  )

position = ->
  @style("left", (d) -> d.x + "px" ).style("top", (d) -> d.y + "px" ).style("width", (d) -> Math.max(0, d.dx - 1) + "px" ).style "height", (d) -> Math.max(0, d.dy - 1) + "px"

div = undefined
createDivs = ->
  width = window.innerWidth
  height = window.innerHeight

  margin =
      top: 0
      right: 0
      bottom: 0
      left: 0

  div = d3.select("body").append("div")
    .style("position", "relative")
    .style("width", (width + margin.left + margin.right) + "px")
    .style("height", (height + margin.top + margin.bottom) + "px")
    .style("left", margin.left + "px")
    .style("top", margin.top + "px")

depth = 0

drawTreeMap = (data) ->
  width = window.innerWidth
  height = window.innerHeight
  color = d3.scale.category20c()

  treemap = d3.layout.treemap().size([width, height]).sticky(true).value((d) -> d.size)

  node = div.datum(data, (d) -> d.name).selectAll(".node")
      .data(treemap.nodes)

  node.enter()
      .append("div")
        .attr("class", "node")
        .call(position)
        .style("background-color", (d) -> (if d.children then color(d.name) else null))
        .on "hover", ->
          $('#path').text(d3.select(this).datum().path)
        # .on "click", ->
        #   el = d3.select(this)
        #   data = el.datum()
        #   if depth > 4
        #     return
        #   if depth == 0 
        #     while (data.parent.parent)
        #       data = data.parent
        #   else if depth == 1
        #     while (data.parent.parent.parent)
        #       data = data.parent
        #   else if depth == 2
        #     while (data.parent.parent.parent.parent)
        #       data = data.parent
        #   else if depth == 3
        #     while (data.parent.parent.parent.parent.parent)
        #       data = data.parent
        #   else if depth == 4
        #     while (data.parent.parent.parent.parent.parent.parent)
        #       data = data.parent
        #   depth += 1
        #   console.log("updated to data:")
        #   console.log(data)
        #   drawTreeMap(data)

  node.exit()
    .remove()

  node.transition().duration(1500).call position

  # d3.selectAll("#reset").on "click", ->
  #   depth = 0
  #   drawTreeMap(final)

getDataForUrl = (dict, urlAddon) ->
  $.ajax(
    type: "GET"
    url: "https://api.dropbox.com/1/metadata/dropbox" + urlAddon
    headers:
      "Authorization": "Bearer " + access_token
  ).fail (data) ->
    folder = JSON.parse(data["responseText"])
    dict['name'] = extractName(folder.path)
    children = []
    dict['children'] = children
    # uncomment to view free space
    #if (urlAddon == "/")
      #getFreeSpace(dict)
    for file in folder.contents
      if file.is_dir
        cleaned_path = encodeURI(file.path)
        new_dict = {}
        getDataForUrl(new_dict, cleaned_path)
        children.push(new_dict)
      else
        if file.bytes > MIN_BYTES
          children.push({'name': extractName(file.path), 'size': file.bytes})

getFreeSpace = (dict) ->
  $.ajax(
    type: "GET"
    url: "https://api.dropbox.com/1/account/info"
    headers:
      "Authorization": "Bearer " + access_token
  ).fail (data) ->
    data = JSON.parse(data["responseText"])
    dict['children'].push({"name": 'Free Space', "size": data["quota_info"]["quota"]})

access_token = null
final = {}

$ ->
  $('form').hide()
  $('#loading').hide()
  access_token = getHashParams()['access_token']
  if not access_token
    $('#authentication a').attr('href', $('#authentication a').attr('href') + "&state=" + getCSRF)
  else
    $("#loading").show()
    $('#page1').hide()
    $('#pad').hide()
    setupTooltip()
    createDivs()
    getDataForUrl(final, "/")
    prev_final = {}
    in_id = setInterval (->
      if (JSON.stringify(prev_final) == JSON.stringify(final))
        $('#loading').hide()
        $('form').show()
        clearInterval(in_id)
        #stored_final = jQuery.extend(true, {}, final)
        drawTreeMap(final)
      prev_final = jQuery.extend(true, {}, final)
    ), 1000




    