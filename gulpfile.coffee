gulp = require('gulp')
coffee = require('gulp-coffee')
concat = require('gulp-concat')
uglify = require 'gulp-uglify'
sourcemaps = require('gulp-sourcemaps')
browserify = require('gulp-browserify')
rename = require 'gulp-rename'
rimraf = require 'gulp-rimraf'
gulpif = require 'gulp-if'
ignore = require 'gulp-ignore'
git = require 'gulp-git'
debug = require 'gulp-debug'
coffeelint = require 'gulp-coffeelint'
mocha = require 'gulp-mocha'
run = require 'gulp-run'
ljs = require 'gulp-ljs'

gulp.task 'default', ['clean', 'build', 'test', 'literate']
gulp.task 'build', ['lint', 'lib', 'browser']

files =
  lib : ['./lib/**/*.coffee']
  browser : ['./lib/**/*.coffee']
  test : ['./test/**/*.coffee']
  gulp : ['./gulpfile.coffee']
  examples : ['./examples/**/*.js']


files.all = []
for name,file_list of files
  files.all = files.all.concat file_list

gulp.task 'lib', ->
  gulp.src files.lib
    .pipe sourcemaps.init()
    .pipe coffee()
    .pipe uglify()
    .pipe sourcemaps.write './'
    .pipe gulp.dest 'build/node/'
    .pipe gulpif '!**/', git.add({args : "-A"})

gulp.task 'browser', ->
  gulp.src files.browser, { read: false }
    .pipe browserify
      transform: ['coffeeify']
      extensions: ['.coffee']
      debug : true
    .pipe rename
      extname: ".js"
    .pipe gulp.dest './build/browser'
    .pipe uglify()
    .pipe rename
      extname: ".min.js"
    .pipe gulp.dest 'build/browser'
    .pipe gulpif '!**/', git.add({args : "-A"})

gulp.task 'test', ->
  gulp.src files.test, { read: false }
    .pipe mocha {reporter : 'list'}
    .pipe ignore.include '**/*.coffee'
    .pipe browserify
      transform: ['coffeeify']
      extensions: ['.coffee']
      debug: true
    .pipe rename
      extname: ".js"
    .pipe gulp.dest 'build/test/'
    .pipe gulpif '!**/', git.add({args : "-A"})

gulp.task 'lint', ->
  gulp.src files.all
    .pipe ignore.include '**/*.coffee'
    .pipe coffeelint {
      "max_line_length":
        "level": "ignore"
      }
    .pipe coffeelint.reporter()

gulp.task 'watch', ['default'], ->
  gulp.watch files.lib, ['build', 'test']
  gulp.watch files.test, ['test']
  gulp.watch files.examples, ['literate']

gulp.task 'literate', ->
  gulp.src files.examples
    .pipe ljs { code : true }
    .pipe rename
      basename : "README"
      extname : ".md"
    .pipe gulp.dest 'examples/'
    .pipe gulpif '!**/', git.add({args : "-A"})

gulp.task 'clean', ->
  gulp.src './build/{browser,test,node}/*.{js,map}', { read: false }
    .pipe ignore '*.html'
    .pipe rimraf()
