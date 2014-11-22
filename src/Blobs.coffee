Blobs =

  fromString: (str, args) ->
    result = Arrays.arrayBufferFromString(str)
    new Blob([result], args)

  downloadInBrowser: (blob, filename) ->
    link = document.createElement('a')
    link.href = window.URL.createObjectURL(blob)
    link.download = filename
    $(link).attr('data-downloadurl', [blob.type, link.download, link.href].join(':'))
    link.click()
    link.remove()
