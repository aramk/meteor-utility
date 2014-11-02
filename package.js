Package.describe({
  name: 'aramk:utility',
  summary: 'A collection of utility modules',
  version: '0.2.1',
  git: 'https://github.com/aramk/meteor-utility.git'
});

Package.onUse(function(api) {
  api.versionsFrom('METEOR@0.9.0');
  api.use(['coffeescript', 'underscore', 'stevezhu:lodash@0.2.0'], ['client', 'server']);
  api.use(['deps', 'templating', 'jquery'], 'client');
  // NOTE: I am using a custom fork at:
  // https://github.com/aramk/meteor-collection-hooks/tree/feature/exceptions
  api.use(['aldeed:autoform@3.2.0', 'mrt:moment@2.8.1', 'matb33:collection-hooks@0.7.6'],
    'client', {weak: true});
  api.export([
    'Arrays', 'Booleans', 'Collections', 'Dates', 'Objects', 'Setter', 'Strings', 'Types'
  ], ['client', 'server']);
  api.export([
    'Buffers'
  ], 'server');
  api.export([
    'Blobs', 'Forms', 'Window'
  ], 'client');
  api.addFiles([
    'Arrays.coffee', 'Booleans.coffee', 'Collections.coffee', 'Dates.coffee', 'Objects.coffee',
    'Setter.coffee', 'Strings.coffee', 'Types.coffee'
  ], ['client', 'server']);
  api.addFiles([
    'Blobs.coffee', 'Forms.coffee', 'Window.coffee'
  ], 'client');
  api.addFiles([
    'Buffers.coffee'
  ], 'server');
});
