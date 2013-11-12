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

getDataForUrl = (dict, urlAddon) ->
  $.ajax(
    type: "GET"
    url: "https://api.dropbox.com/1/metadata/dropbox" + urlAddon
    headers:
      "Authorization": "Bearer " + access_token
  ).fail (data) ->
    folder = JSON.parse(data["responseText"])
    console.log(folder)
    # for file in folder.contents
    #   if file.is_dir
    #     cleaned_path = encodeURI(file.path)
    #     console.log(cleaned_path)
    #     new_dict = {}
    #     getDataForUrl(new_dict, cleaned_path)
    #     dict[file.path] = new_dict
    #   else
    #     dict[file.path] = file
    dict['name'] = extractName(folder.path)
    children = []
    dict['children'] = children
    for file in folder.contents
      if file.is_dir
        cleaned_path = encodeURI(file.path)
        console.log(cleaned_path)
        new_dict = {}
        getDataForUrl(new_dict, cleaned_path)
        children.push(new_dict)
      else
        children.push({'name': extractName(file.path), 'size': file.bytes})

setupTooltip = ->
  $(document).tooltip(
    show:
      effect: "appear"
      duration: 0
    hide:
      effect: "appear"
      duration: 0
  )

drawTreeMap = () ->
  position = ->
    @style("left", (d) -> d.x + "px" ).style("top", (d) -> d.y + "px" ).style("width", (d) -> Math.max(0, d.dx - 1) + "px" ).style "height", (d) -> Math.max(0, d.dy - 1) + "px"

  margin =
    top: 0
    right: 0
    bottom: 0
    left: 0

  # width = 960 - margin.left - margin.right
  # height = 500 - margin.top - margin.bottom
  width = window.innerWidth
  height = window.innerHeight
  color = d3.scale.category20c()
  treemap = d3.layout.treemap().size([width, height]).sticky(true).value((d) -> d.size)
  div = d3.select("body").append("div")
    .style("position", "relative")
    .style("width", (width + margin.left + margin.right) + "px")
    .style("height", (height + margin.top + margin.bottom) + "px")
    .style("left", margin.left + "px")
    .style("top", margin.top + "px")
  node = div.datum(final).selectAll(".node")
      .data(treemap.nodes)
    .enter()
      .append("div")
        .attr("class", "node")
        .call(position)
        .style("background", (d) -> (if d.children then color(d.name) else null))
        .attr("title", (d) -> (if d.children then null else d.name))
      #.text((d) -> (if d.children then null else d.name))
  d3.selectAll("input").on "change", change = ->
    value = switch (@value)
      when "count" then 1
      when "size" then (d) -> d.size
    node.data(treemap.value(value).nodes).transition().duration(1500).call position

access_token = null
final = {}

$ ->
  $('form').hide()
  $('#loading').hide()
  access_token = getHashParams()['access_token']
  if not access_token
    state = "09asd82n20fh90ds0h0sna0"
    $('#authentication a').attr('href', $('#authentication a').attr('href') + "&state=" + state)
  else
    console.log("authorized!")
    $("#loading").show()
    $('#page1').hide()
    $('#pad').hide()
    setupTooltip()
    getDataForUrl(final, "/")
    prev_final = {}
    in_id = setInterval (->
      if (JSON.stringify(prev_final) == JSON.stringify(final))
        $('#loading').hide()
        $('form').show()
        console.log(final)
        drawTreeMap()
        clearInterval(in_id)
      prev_final = jQuery.extend(true, {}, final)
    ), 1000




    