Package.describe({
  name: 'aramk:utility',
  summary: 'A collection of utility modules'
});

Package.onUse(function(api) {
  api.versionsFrom('METEOR@0.9.0');
  api.use(['coffeescript', 'underscore', 'stevezhu:lodash'], ['client', 'server']);
  api.use(['deps', 'templating', 'jquery'], 'client');
  api.use(['aldeed:autoform', 'mrt:moment'], 'client', {weak: true});
  api.export([
    'Arrays', 'Booleans', 'Collections', 'Dates', 'Objects', 'Setter', 'Strings', 'Types'
  ], ['client', 'server']);
  api.export([
    'Forms', 'Window'
  ], 'client');
  api.addFiles([
    'Arrays.coffee', 'Booleans.coffee', 'Collections.coffee', 'Dates.coffee', 'Objects.coffee',
    'Setter.coffee', 'Strings.coffee', 'Types.coffee'
  ], ['client', 'server']);
  api.addFiles([
    'Forms.coffee', 'Window.coffee'
  ], 'client');
});
