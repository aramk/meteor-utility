Dates =

  MAX_DAY_INDEX: 6

  toLong: (date) -> moment(date).format('ddd Do MMM YYYY - h:mm:ss A')

  toTime: (date) -> moment(date).format('h:mm:ss A')

# @returns {String} The current timezone offset in ISO-8601 format (e.g. +01:00).
  getCurrentOffset: -> moment().format().match(/[+-]\d+:\d+$/)[0]

# @param {String} local - A local date without a timezone offset.
# @returns {String} The given date with the current timezone offset.
  fromLocal: (local) -> moment(local + @getCurrentOffset()).zone(moment().zone()).format()

# @param date
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
  getCurrent: ->moment().format()

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

  millisFromStartOfWeek: (date) ->
    # Keep the existing zone, otherwise we will compare it to the start of the week in the local
    # timezone, which will cause a discrepancy from the input timezone.
    date = @_sanitizeZone(date)
    startOfWeek = date.clone().startOf('week')
    date.diff(startOfWeek)

# @param date
# @param startDate
# @param endDate
# @returns (Boolean) Whether the given date exists between the start and end dates when all dates are
# standardised to the amount of time from the start of their respective week.
  inBetweenWeek: (date, startDate, endDate) ->
    dateFrom = @millisFromStartOfWeek(date)
    startFrom = @millisFromStartOfWeek(startDate)
    endFrom = @millisFromStartOfWeek(endDate)
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
  daysUntilWeekday: (date, dayIndex) ->
    currentIndex = @_sanitizeZone(date).day()
    indexDiff = dayIndex - currentIndex
    if indexDiff >= 0
      indexDiff
    else
      indexDiff + @MAX_DAY_INDEX + 1

# @param date
# @param dayIndex - A number from 0 to 6, where 0 is Sunday and 6 is Saturday.
# @returns {String} The date of the next occurrence of the given week day index from the given
# date.
  getNextWeekday: (date, dayIndex) ->
    daysUntil = @daysUntilWeekday(date, dayIndex)
    @_sanitizeZone(date).clone().add(daysUntil, 'days').format()

  _sanitizeZone: (date) ->
    # Passing a Moment into parseZone can sometimes result in UTC instead of the zone provided by
    # .zone() or format().
    moment.parseZone(moment(date).format())
