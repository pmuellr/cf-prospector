# Licensed under the Apache License. See footer for details.

#-------------------------------------------------------------------------------
# use this file with jbuild: https://www.npmjs.org/package/jbuild
# install jbuild with:
#    linux/mac: sudo npm -g install jbuild
#    windows:        npm -g install jbuild
#-------------------------------------------------------------------------------

fs   = require "fs"
path = require "path"
zlib = require "zlib"

AtomShellVersion   = "0.17.2"
AtomShellPlatforms = [
  "darwin-x64",
  "linux-ia32",
  "linux-x64",
  "win32-ia32",
]

#-------------------------------------------------------------------------------
tasks = defineTasks exports,
  build:     "run a build"
  watch:     "watch for source file changes, then run build"
  buildAtom: "get the latest versions of atom-shell"
  buildIcns: "build .icns file on a Mac"

WatchSpec = "lib lib/**/* www www/**/*"

mkdir "-p", "tmp"

#-------------------------------------------------------------------------------
tasks.build = ->
  log "running build"

  unless test "-d", "node_modules"
    exec "npm install"

oldBuildJunk = ->
  cleanDir "www"

  cp "-R", "www-src/*", "www"
  cp "package.json",    "www"

  copyBowerFiles  "www/bower"

  buildViews "www-src/views", "www/lib/views.json"

  browserify "www/lib/main.js --outfile tmp/node-modules.js --debug"
  cat_source_map "--fixFileNames tmp/node-modules.js www/node-modules.js"

  rm "-Rf", "www/lib"
  rm "-Rf", "www/views"

  # gzipize "www"

#-------------------------------------------------------------------------------
watchIter = ->
  tasks.build()
  tasks.serve()
  # tasks.test()

#-------------------------------------------------------------------------------
tasks.watch = ->
  watchIter()

  watch
    files: WatchSpec.split " "
    run:   watchIter

  watchFiles "jbuild.coffee" :->
    log "jbuild file changed; exiting"
    process.exit 0

#-------------------------------------------------------------------------------
tasks.buildAtom = ->

  urlPrefix = "https://github.com/atom/atom-shell/releases/download/v"

  for platform in AtomShellPlatforms
    log "----------------------------------------------"
    log "building atom-shell v#{AtomShellVersion} for #{platform}"

    cleanDir "atom-bin/#{platform}"

    file    = "atom-shell-v#{AtomShellVersion}-#{platform}.zip"
    options = "--output atom-bin/#{file} --location"
    url     = "#{urlPrefix}#{AtomShellVersion}/#{file}"

    unless test "-f", "atom-bin/#{file}"
      log "getting atom-shell v#{AtomShellVersion} for #{platform}"
      exec "curl #{options} #{url}"

    exec "unzip -q atom-bin/#{file} -d atom-bin/#{platform}"

    buildPlatform[platform]()

  log ""

  return

#-------------------------------------------------------------------------------
buildPlatform_darwin_x64 = ->
  cp "-f", "platform/darwin-x64/cf-prospector.icns",
           "atom-bin/darwin-x64/Atom.app/Contents/Resources/"

  cp "-f", "platform/darwin-x64/Info.plist",
           "atom-bin/darwin-x64/Atom.app/Contents"

#  mv "atom-bin/darwin-x64/Atom.app/Contents/MacOS/Atom",
#     "atom-bin/darwin-x64/Atom.app/Contents/MacOS/cf-prospector"

  mv "atom-bin/darwin-x64/Atom.app",
     "atom-bin/darwin-x64/cf-prospector.app"

  rm "atom-bin/darwin-x64/LICENSE"
  rm "atom-bin/darwin-x64/version"

#-------------------------------------------------------------------------------
buildPlatform_linux_ia32 = ->

#-------------------------------------------------------------------------------
buildPlatform_linux_x64 = ->

#-------------------------------------------------------------------------------
buildPlatform_win32_ia32 = ->

#-------------------------------------------------------------------------------
buildPlatform =
  "darwin-x64": buildPlatform_darwin_x64
  "linux-ia32": buildPlatform_linux_ia32
  "linux-x64":  buildPlatform_linux_x64
  "win32-ia32": buildPlatform_win32_ia32

#-------------------------------------------------------------------------------
tasks.buildIcns = ->
  cleanDir "tmp/icns.iconset"

  exec "sips -z    16 16  icon/cf-prospector.png --out tmp/icns.iconset/icon_16x16.png"
  exec "sips -z    32 32  icon/cf-prospector.png --out tmp/icns.iconset/icon_16x16@2x.png"
  exec "sips -z    32 32  icon/cf-prospector.png --out tmp/icns.iconset/icon_32x32.png"
  exec "sips -z    64 64  icon/cf-prospector.png --out tmp/icns.iconset/icon_32x32@2x.png"
  exec "sips -z  128 128  icon/cf-prospector.png --out tmp/icns.iconset/icon_128x128.png"
  exec "sips -z  256 256  icon/cf-prospector.png --out tmp/icns.iconset/icon_128x128@2x.png"
  exec "sips -z  256 256  icon/cf-prospector.png --out tmp/icns.iconset/icon_256x256.png"
  exec "sips -z  512 512  icon/cf-prospector.png --out tmp/icns.iconset/icon_256x256@2x.png"
  exec "sips -z  512 512  icon/cf-prospector.png --out tmp/icns.iconset/icon_512x512.png"
  exec "sips -z 1024 1024 icon/cf-prospector.png --out tmp/icns.iconset/icon_512x512@2x.png"

  exec "iconutil --convert icns --output platform/darwin-x64/cf-prospector.icns tmp/icns.iconset"

#-------------------------------------------------------------------------------
copyBowerFiles = (dir) ->

  bowerConfig = require "./bower-config"

  cleanDir dir

  for name, {version, files} of bowerConfig
    unless test "-d", "bower_components/#{name}"
      exec "bower install #{name}##{version}"
      log ""

  for name, {version, files} of bowerConfig
    for src, dst of files
      src = "bower_components/#{name}/#{src}"

      if dst is "."
        dst = "#{dir}/#{name}"
      else
        dst = "#{dir}/#{name}/#{dst}"

      mkdir "-p", dst

      cp "-R", src, dst

  return

#-------------------------------------------------------------------------------
cleanDir = (dir) ->
  mkdir "-p", dir
  rm "-rf", "#{dir}/*"

#-------------------------------------------------------------------------------
# Copyright IBM Corp. 2014
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#-------------------------------------------------------------------------------
