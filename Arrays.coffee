@Arrays =

  getRandomIndex: (array) ->
    index = Math.floor(Math.random() * array.length)
    index

  getRandomItem: (array) ->
    array[@getRandomIndex(array)]

  toMap: (array) ->
    obj = {}
    for value in array
      obj[value] = true
    obj
