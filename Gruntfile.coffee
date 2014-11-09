###
# Gruntfile

This is a summary of what this Gruntfile does:

* The `grunt` default task transpiles the CoffeeScript and then starts a
  development server and a task to watch for file changes.
* When a CoffeeScript file changes, the files are linted, transpiled, and tests
  are run, in parallel.
* When a JS file changes(from CoffeeScript transpiling), the development server
  is restarted

###
module.exports = (grunt) ->
  grunt.initConfig
    pkg: grunt.file.readJSON 'package.json'

    # Task to watch various sets of files and automatically perform actions
    # when they are changed
    watch:
      # Restart grunt if the gruntfile changes
      gruntfile:
        files: ['Gruntfile.coffee']
        options: reload: true
      # Whenever a coffee file changes, run the concurrent:coffee task which
      # does transpiling, linting, tests, etc.
      coffee:
        files: [
          'Gruntfile.coffee',
          'src/**/*.coffee',
        ]
        tasks: ['concurrent:coffee']
      # Whenever lib or test files are updated, rerun tests
      test:
        files: ['lib/**/*.js', 'test/**/*.coffee', 'config/*.json']
        tasks: ['test']

    # Task to compile src coffee files into lib JS files
    coffee:
      lib:
        expand: true  # Expands the src glob to match files dynamically
        cwd: 'src/'  # Need to use cwd or it ends up as lib/src/blah.js
        src: ['**/*.coffee']
        dest: 'lib/'
        ext: '.js'

    # Task to coffeelint both tests and src files
    coffeelint:
      lib: ['src/**/*.coffee']
      test: ['test/**/*.coffee']

    # Task to run a node server for development with NodeMon
    nodemon:
      dev:
        script: 'lib/server.js'
        options:
          # Don't wait before restarting the server, since it triggers after
          # coffee compilation
          delay: 1
          ext: "js,json"
          watch: ['lib', 'config', 'localconfig.json']

    # Mocha test task, which is run by the watch task when there are changes to
    # test or library files
    mochaTest:
      test:
        src: ['test/**/*.coffee']
        options:
          # This allows Mocha to compile the coffeescript tests directly, as
          # well as activates the fibrous API
          require: ['coffee-script/register', 'chai']

    # Define tasks which can be executed concurrently for faster builds
    concurrent:
      # This is the default "development mode" grunt task. It starts the
      # nodemon server as well as the watch task, which handles compiling,
      # linting, and test running
      dev:
        tasks: ['nodemon', 'watch']
        options:
          logConcurrentOutput: true
      # This runs all the coffee related tasks in parallel, including linting,
      # transpiling, etc.
      coffee:
        tasks: ['coffeelint:lib', 'coffeelint:test', 'newer:coffee:lib']

    # Tasks that set environment variables
    env:
      test:
        NODE_ENV: 'test'

  # Load all our grunt tasks
  require('load-grunt-tasks') grunt;

  # Our default grunt task compiles our coffeescript lib then runs our server
  grunt.registerTask 'default', ['newer:coffee', 'concurrent:dev']
  grunt.registerTask 'test', ['newer:coffee', 'env:test', 'mochaTest']

