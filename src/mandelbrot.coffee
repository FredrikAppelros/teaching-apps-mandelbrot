class Renderer
  constructor: (canvas, @maxItr = 1000, @palette = chroma.scale 'RdYlBu') ->
    @ctx = canvas.getContext '2d'
    @image = @ctx.createImageData canvas.width, canvas.height
    @width = @image.width
    @height = @image.height
    @numPixels = @width * @height
    @colorCache = {}

    # Set the alpha channel for all pixels in the image
    for i in [0...@numPixels]
      @image.data[i * 4 + 3] = 255

  mandelbrot: (region, px, py) ->
    x0 = px / @width * region.width + region.left
    y0 = py / @height * region.height + region.bottom
    x = 0
    y = 0

    itr = 0
    while x * x + y * y < (1 << 16) and itr < @maxItr
      tx = x * x - y * y + x0
      y = 2 * x * y + y0
      x = tx
      itr++

    if itr < @maxItr
      zn = Math.sqrt x * x + y * y
      nu = Math.log(Math.log zn / Math.log 2) / Math.log 2
      itr = itr + 1 - nu

    itr - 1

  renderPixel: (idx) ->
    v = @values[idx]
    c = @colorCache[v]

    unless c?
      level = Math.floor v + 1
      phue = hue = 0
      for i in [0..level]
        phue = hue
        hue += @hgram[i]

      c1 = @palette(phue / @numPixels)
      c2 = @palette(hue / @numPixels)
      c = chroma(chroma.interpolate c1, c2, v % 1)
      @colorCache[v] = c

    [r, g, b] = c.rgb()
    @image.data[idx * 4 + 0] = r
    @image.data[idx * 4 + 1] = g
    @image.data[idx * 4 + 2] = b

  renderImage: (region) ->
    @values = new Array @numPixels
    @hgram = (0 for i in [0...@maxItr])

    for y in [0...@height]
      for x in [0...@width]
        v = @mandelbrot region, x, y
        @values[y * @width + x] = v
        @hgram[Math.round v]++

    for i in [0...@numPixels]
      @renderPixel i

    @ctx.putImageData @image, 0, 0

container = document.getElementById 'container'
canvas = document.getElementById 'canvas'
overlay = document.createElement 'canvas'
ctx = overlay.getContext '2d'
renderer = new Renderer canvas

region =
  left: -2.5
  bottom: -1
  width: 3.5
  height: 2

keepRatio = true

drawImage = ->
  start = new Date().getTime()

  renderer.renderImage region

  end = new Date().getTime()

  console.log 'Time elapsed:', end - start, 'ms'

startX = startY = endX = endY = 0

onMouseDown = (event) ->
  startX = event.layerX
  startY = event.layerY

  overlay.addEventListener 'mousemove', onMouseMove
  overlay.addEventListener 'mouseup', onMouseUp
  overlay.removeEventListener 'mousedown', onMouseDown

onMouseMove = (event) ->
  endX = event.layerX
  endY = event.layerY

  if keepRatio
    ratio = canvas.width / canvas.height

    w = endX - startX
    h = endY - startY


    if (Math.abs(w) / canvas.width) > (Math.abs(h) / canvas.height)
      signX = w / Math.abs w
      endX = startX + Math.abs(h) * ratio * signX
    else
      signY = h / Math.abs h
      endY = startY + Math.abs(w) / ratio * signY

  x = Math.min endX, startX
  y = Math.min endY, startY
  w = Math.abs endX - startX
  h = Math.abs endY - startY

  ctx.clearRect 0, 0, overlay.width, overlay.height
  ctx.strokeRect x, y, w, h

onMouseUp = (event) ->
  x = Math.min endX, startX
  y = Math.min endY, startY
  w = Math.abs endX - startX
  h = Math.abs endY - startY

  ctx.clearRect 0, 0, overlay.width, overlay.height

  newRegion =
    left: x / overlay.width * region.width + region.left
    bottom: y / overlay.height * region.height + region.bottom
    width: w / overlay.width * region.width
    height: h / overlay.height * region.height

  region = newRegion

  drawImage()

  overlay.addEventListener 'mousedown', onMouseDown
  overlay.removeEventListener 'mousemove', onMouseMove
  overlay.removeEventListener 'mouseup', onMouseUp

overlay.id = 'overlay'
overlay.width = canvas.width
overlay.height = canvas.height
container.appendChild overlay
overlay.addEventListener 'mousedown', onMouseDown

drawImage()
