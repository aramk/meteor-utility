Paths =

  getExtension: (filename) ->
    matches = filename?.match(/\.([^./]*)$/)
    return null unless matches
    matches[1].toLowerCase()
