Colors =

  getRandomColor: -> tinycolor.random().toHexString()

  darken: (color, value) -> tinycolor(color).darken(value ? 40).toRgbString()
