Package.describe({
  name: 'aramk:utility',
  summary: 'A collection of utility modules',
  version: '0.6.0',
  git: 'https://github.com/aramk/meteor-utility.git'
});

Package.onUse(function(api) {
  api.versionsFrom('METEOR@0.9.0');
  api.use(['coffeescript', 'underscore', 'stevezhu:lodash@0.2.0', 'aramk:q@1.0.1_1'],
    ['client', 'server']);
  api.use(['deps', 'templating', 'jquery'], 'client');
  // NOTE: Using a custom fork:
  // https://github.com/aramk/meteor-collection-hooks.git#feature/exceptions
  api.use(['aldeed:autoform@4.0.7', 'mrt:moment@2.8.1', 'matb33:collection-hooks@0.7.6'],
    'client', {weak: true});
  api.use(['meteorhacks:async@1.0.0'], 'server', {weak: true});
  // Make these available to the app to allow working with tiem and deferreds.
  api.imply(['mrt:moment', 'aramk:q'], ['client'], ['server'])
  api.export([
    'Arrays', 'Booleans', 'Collections', 'Dates', 'Maths', 'Objects', 'Promises', 'Setter',
    'Strings', 'Types'
  ], ['client', 'server']);
  api.export([
    'Buffers'
  ], 'server');
  api.export([
    'Blobs', 'Forms', 'Templates', 'Window'
  ], 'client');
  api.addFiles([
    'src/Arrays.coffee', 'src/Booleans.coffee', 'src/Collections.coffee', 'src/Dates.coffee',
    'src/Maths.coffee',  'src/Objects.coffee', 'src/Promises.coffee', 'src/Setter.coffee',
    'src/Strings.coffee', 'src/Types.coffee'
  ], ['client', 'server']);
  api.addFiles([
    'src/Blobs.coffee', 'src/Forms.coffee', 'src/Templates.coffee', 'src/Window.coffee'
  ], 'client');
  api.addFiles([
    'src/Buffers.coffee'
  ], 'server');
});
