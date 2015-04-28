Dates =

  MAX_DAY_INDEX: 6

  toLong: (date) -> moment(date).format('ddd Do MMM YYYY - h:mm:ss A')

  toTime: (date) -> moment(date).format('h:mm:ss A')

  toIdentifier: (date) -> moment(date).format().replace(/[^\w-]+/g, '-')

  # @returns {String} The current timezone offset in ISO-8601 format (e.g. +01:00).
  getCurrentOffset: -> moment().format().match(/[+-]\d+:\d+$/)[0]

  # @param {String} date - A date string containing a UTC offset.
  # @returns {Number} The UTC offset in minutes for the given date.
  getUtcOffset: (date) -> @getByOffset(date).utcOffset()

  # @param {String} local - A local date without a timezone offset.
  # @returns {String} The given date with the current timezone offset.
  fromLocal: (local) ->
    # Timezone offset is handled my moment().
    moment(local)

  # @param {String} date
  # @returns {String} The given date without the timezone offset.
  toLocal: (date) -> moment(date).format().replace(/[+-]\d{2}:\d{2}$/, '')

  # @param startDate
  # @param endDate
  # @returns {String} The duration between the start and end dates in a humanized format.
  toDurationString: (startDate, endDate) ->
    # TODO(aramk) Improve by using minutes and seconds.
    hours = moment.duration(moment(endDate).diff(moment(startDate))).asHours()
    hours.toFixed(2) + ' hours'

  # @returns {String}
  getCurrent: -> moment().format()

  isValidRange: (startDate, endDate) ->
    endDate = moment(endDate)
    startDate = moment(startDate)
    endDate.isAfter(startDate) || endDate.isSame(startDate)

  isInRange: (date, startDate, endDate) ->
    date = moment(date)
    startDate = moment(startDate)
    endDate = moment(endDate)
    (date.isAfter(startDate) && date.isBefore(endDate)) || date.isSame(startDate) ||
      date.isSame(endDate)

  millisFromStartOfWeek: (date, utcOffset) ->
    # Keep the existing zone, otherwise we will compare it to the start of the week in the local
    # timezone, which will cause a discrepancy from the input timezone.
    date = @getByOffset(date, utcOffset)
    startOfWeek = date.clone().startOf('week')
    date.diff(startOfWeek)

  # @param {String} date
  # @param {String} startDate
  # @param {String} endDate
  # @returns {Boolean} Whether the given date exists between the start and end dates when all dates are
  # standardised to the amount of time from the start of their respective week.
  inBetweenWeek: (date, startDate, endDate, utcOffset) ->
    dateFrom = @millisFromStartOfWeek(date, utcOffset)
    startFrom = @millisFromStartOfWeek(startDate, utcOffset)
    endFrom = @millisFromStartOfWeek(endDate, utcOffset)
    if startFrom > endFrom
      millisInWeek = moment.duration(1, 'week').as('milliseconds')
      if dateFrom >= startFrom
        endFrom += millisInWeek
      else
        startFrom -= millisInWeek
    dateFrom >= startFrom && dateFrom <= endFrom

  # @param {String} date
  # @param {Number} dayIndex - A number from 0 to 6, where 0 is Sunday and 6 is Saturday.
  # @returns {Number} The number of days until the next occurrence of the given week day from the
  # given date.
  daysUntilWeekday: (date, dayIndex, utcOffset) ->
    currentIndex = @getByOffset(date, utcOffset).day()
    indexDiff = dayIndex - currentIndex
    if indexDiff >= 0
      indexDiff
    else
      indexDiff + @MAX_DAY_INDEX + 1

  # @param {String} date
  # @param {Number} dayIndex - A number from 0 to 6, where 0 is Sunday and 6 is Saturday.
  # @returns {String} The date of the next occurrence of the given week day index from the given
  # date.
  getNextWeekday: (date, dayIndex, utcOffset) ->
    daysUntil = @daysUntilWeekday(date, dayIndex, utcOffset)
    @getByOffset(date, utcOffset).clone().add(daysUntil, 'days').format()

  # @param {String} date
  # @returns {String} A string which only contains alphanumeric characters or hyphens.
  toHyphenated: (date) -> moment(date).format().replace(/[^\w]/g, '-')

  # @param {String|Date} date
  # @param {Number} [utcOffset] - The UTC offset in minutes. If not provided, the date must be a
  #     string with a UTC offset. Otherwise, automatic conversion to the local timezone will prevent
  #     determining the offset of the original date.
  # @returns {Moment} The given date in the given UTC offset.
  getByOffset: (date, utcOffset) ->
    if !Types.isString(date) && !utcOffset?
      throw new Error('Date must be string to prevent automatic conversion to local timezone, ' +
          'or UTM offset must be provided.')
    if utcOffset?
      moment.parseZone(moment(date).format()).utcOffset(utcOffset)
    else
      moment.parseZone(date)
