Package.describe({
  name: 'aramk:utility',
  summary: 'A collection of utility modules',
  version: '0.4.2',
  git: 'https://github.com/aramk/meteor-utility.git'
});

Package.onUse(function(api) {
  api.versionsFrom('METEOR@0.9.0');
  api.use(['coffeescript', 'underscore', 'stevezhu:lodash@0.2.0'], ['client', 'server']);
  api.use(['deps', 'templating', 'jquery'], 'client');
  // NOTE: I am using a custom fork at:
  // https://github.com/aramk/meteor-collection-hooks/tree/feature/exceptions
  api.use(['aldeed:autoform@4.0.7', 'mrt:moment@2.8.1', 'matb33:collection-hooks@0.7.6'],
    'client', {weak: true});
  api.export([
    'Arrays', 'Booleans', 'Collections', 'Dates', 'Maths', 'Objects', 'Setter', 'Strings', 'Types'
  ], ['client', 'server']);
  api.export([
    'Buffers'
  ], 'server');
  api.export([
    'Blobs', 'Forms', 'Templates', 'Window'
  ], 'client');
  api.addFiles([
    'src/Arrays.coffee', 'src/Booleans.coffee', 'src/Collections.coffee', 'src/Dates.coffee',
    'src/Maths.coffee',  'src/Objects.coffee', 'src/Setter.coffee', 'src/Strings.coffee',
    'src/Types.coffee'
  ], ['client', 'server']);
  api.addFiles([
    'src/Blobs.coffee', 'src/Forms.coffee', 'src/Templates.coffee', 'src/Window.coffee'
  ], 'client');
  api.addFiles([
    'src/Buffers.coffee'
  ], 'server');
});
