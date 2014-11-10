Maths =
  
  interpolateRatio: (a, b, ratio) -> a + ratio * (b - a)

  calcUniformBinValue: (bins, input, maxInput) ->
    binCount = bins.length
    throw new Error('Must have non-empty array of bins.') unless binCount > 0
    binSize = maxInput / binCount
    binFloat = input / binSize
    lowerBinIndex = Math.floor(binFloat)
    upperBinIndex = Math.ceil(binFloat)
    # If the upper bin exceeds the number of bins, use the first bin to form a cycle.
    if upperBinIndex >= binCount
      upperBinIndex = 0
    binRatio = binFloat - lowerBinIndex
    lowerBinValue = bins[lowerBinIndex]
    upperBinValue = bins[upperBinIndex]
    if !lowerBinValue? && !upperBinValue?
      null
    else if !lowerBinValue?
      upperBinValue
    else if !upperBinValue?
      lowerBinValue
    else
      Maths.interpolateRatio(lowerBinValue, upperBinValue, binRatio)

  # @param {Array} array - An array of items.
  # @param {Function} [getValue] - A function when given the item returns its numerical value.
  # @returns {Number} The sum of all the numerical values of the given items.
  sum: (array, getValue) ->
    getValue ?= (item) -> item
    _.reduce array, ((memo, item) -> memo + getValue(item)), 0
