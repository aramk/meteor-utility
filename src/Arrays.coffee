Arrays =

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

  arrayBufferFromString: (str) ->
    encodedStr = Strings.encodeUtf8(str)
    buffer = new ArrayBuffer(encodedStr.length)
    bytes = new Uint8Array(buffer)
    for i in [0..encodedStr.length]
      bytes[i] = encodedStr.charCodeAt(i)
    buffer

  stringFromArrayBuffer: (buffer) ->
    # TODO(aramk) This can fail for large strings. See http://stackoverflow.com/questions/6965107.
    encodedStr = String.fromCharCode.apply(null, new Uint8Array(buffer))
    Strings.decodeUtf8(encodedStr)
