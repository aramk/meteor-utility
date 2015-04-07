Buffers =

  fromStream: (stream) ->
    Promises.runSync (done) ->
      buffers = []
      stream.on 'data', (buffer) -> buffers.push(buffer)
      stream.on 'end', -> done(null, Buffer.concat(buffers))

  fromArrayBuffer: (arrayBuffer) ->
    buffer = new Buffer(arrayBuffer.byteLength)
    view = new Uint8Array(arrayBuffer)
    for value, i in buffer
      buffer[i] = view[i]
    buffer

  toArrayBuffer: (buffer) ->
    arrayBuffer = new ArrayBuffer(buffer.length)
    view = new Uint8Array(arrayBuffer)
    for value, i in buffer
      view[i] = buffer[i]
    arrayBuffer
