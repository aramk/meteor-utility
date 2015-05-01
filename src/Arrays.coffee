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

  # @param {Array} array
  # @param {Number} size - The maximum size of each bucket.
  # @returns {Array.<Array>} - The set of arrays obtained by splitting into buckets of the given
  #     size.
  buckets: (array, size) ->
    unless size > 0
      throw new Error('Bucket size must be greater than 0')
    currIndex = 0
    arrays = []
    loop
      bucket = array.slice(currIndex, currIndex + size)
      if bucket.length == 0 then break
      arrays.push bucket
      currIndex += size
    arrays
