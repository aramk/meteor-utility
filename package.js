Package.describe({
  name: 'aramk:utility',
  summary: 'A collection of utility modules',
  version: '0.9.0',
  git: 'https://github.com/aramk/meteor-utility.git'
});

Package.onUse(function(api) {
  api.versionsFrom('METEOR@0.9.0');
  api.use([
    'coffeescript',
    'underscore',
    'minimongo',
    'stevezhu:lodash@0.2.0',
    'aramk:q@1.0.1_1',
    'aramk:tinycolor@1.1.0_1'
  ], ['client', 'server']);
  api.use([
    'deps',
    'jquery',
    'less',
    'templating'
  ], 'client');
  // NOTE: Using a custom fork:
  // https://github.com/aramk/meteor-collection-hooks.git#feature/exceptions
  api.use([
    'aldeed:autoform@5.1.2',
    'momentjs:moment@2.10.3',
    'matb33:collection-hooks@0.7.6',
    'semantic:ui-css@1.11.5',
  ], 'client', {weak: true});
  // Either of these will contain the Async module, but we don't want to strongly require either
  // since we don't know which is being used.
  api.use([
    'meteorhacks:async@1.0.0',
    'meteorhacks:npm@1.2.2'
  ], 'server', {weak: true});
  api.use([
    'aldeed:simple-schema@1.3.0',
    'aldeed:collection2@2.3.2'
  ], ['client', 'server']);
  // Make these available to the app to allow working with tiem and deferreds.
  api.imply(['momentjs:moment', 'aramk:q'], ['client','server'])
  api.export([
    'Arrays',
    'Booleans',
    'Collections',
    'Colors',
    'Dates',
    'DeferredQueue',
    'DeferredQueueSet',
    'DeferredQueueMap',
    'Depends',
    'Environment',
    'Functions',
    'Logger',
    'Maths',
    'Numbers',
    'Objects',
    'Paths',
    'Promises',
    'Setter',
    'Strings',
    'Types'
  ], ['client', 'server']);
  api.export([
    'Buffers'
  ], 'server');
  api.export([
    'Blobs',
    'Forms',
    'Templates',
    'Window'
  ], 'client');
  api.addFiles([
    'src/Arrays.coffee',
    'src/Booleans.coffee',
    'src/Collections.coffee',
    'src/Colors.coffee',
    'src/data/DeferredQueue.coffee',
    'src/data/DeferredQueueSet.coffee',
    'src/data/DeferredQueueMap.coffee',
    'src/Dates.coffee',
    'src/Depends.coffee',
    'src/Environment.coffee',
    'src/Functions.coffee',
    'src/Log.coffee',
    'src/Maths.coffee',
    'src/Numbers.coffee',
    'src/Objects.coffee',
    'src/Paths.coffee',
    'src/Promises.coffee',
    'src/Setter.coffee',
    'src/Strings.coffee',
    'src/Types.coffee'
  ], ['client', 'server']);
  api.addFiles([
    'src/Blobs.coffee',
    'src/Forms.coffee',
    'src/Templates.coffee',
    'src/Window.coffee',
    'src/forms.less'
  ], 'client');
  api.addFiles([
    'src/Buffers.coffee'
  ], 'server');
});
