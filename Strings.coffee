@Strings =

# @returns {String} The string converted to title case.
  toTitleCase: (str) ->
    parts = str.split(/\s+/)
    title = ''
    for part, i in parts
      if part != ''
        title += part.slice(0, 1).toUpperCase() + part.slice(1, part.length);
        if i != parts.length - 1 and parts[i + 1] != ''
          title += ' '
    title

  firstToLowerCase: (str) ->
    str.replace /(^\w)/, (firstChar) -> firstChar.toLowerCase()

  firstToUpperCase: (str) ->
    str.replace /(^\w)/, (firstChar) -> firstChar.toUpperCase()

  isNumber: (str) -> !/[^\d\.E-]/g.test(str)

# TODO(aramk) Improve naive pluralize methods.

  singular: (plural) ->
    plural.replace /s$/, ''

  plural: (singular) ->
    singular + 's'

  pluralize: (singular, count, plural) ->
    count ?= 0
    plural ?= @plural(singular)
    if count == 1 then singular else plural

# @param {String} name
# @param {Object} args
# @param {Function} args.validator - A function which should return whether the generated name
# is satisfactory or should continue to be generated.
# @param {Function} [args.transformer] - Transforms the name. Passed the prefix and the
# index of the current try. Must return unique output for each try to avoid infinite looping.
# @param {Number} [args.limit=100] - The number of times to try suffixing before giving up.
# @returns {String} A name using the prefix and a suffix if necessary to distinguish the name
# from those existing.
  generateName: (name, args) ->
    defaultTransformer = (origName, currName, i) ->
      origName + ' ' + (i + 1)
    args = _.extend args, {limit: 100, transformer: defaultTransformer}
    origName = name
    validator = args.validator
    transformer = args.transformer
    limit = args.limit
    tryCount = 0
    while tryCount < limit
      if validator(name, tryCount)
        break
      newName = transformer(origName, name, tryCount)
      if newName == name
        throw new Error('Transformer gave same output between tries. name: ' + name + ' tryCount: ' + tryCount)
      name = newName
      tryCount++
    name

  format:
    sup: (str) -> str.replace(/\^(\w+)/g, '<sup>$1</sup>')
    sub: (str) -> str.replace(/_(\w+)/g, '<sub>$1</sub>')
    scripts: (str) -> @.sup(@.sub(str))

