Buffers =

  fromStream: (stream) ->
    Promises.runSync (done) ->
      # TODO(aramk) If stream has ended, we need to use read() sychronously and add it into a
      # Buffer.
      buffers = []
      stream.on 'data', (buffer) -> buffers.push(buffer)
      stream.on 'error', (err) -> done(err, null)
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
