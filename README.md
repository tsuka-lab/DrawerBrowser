# DrawerBrowser

## Install

### Install Ruby and RubyGems

### Install pikl

<http://pikl.rubyforge.org/>

#### Install on Linux

Require:

- libjpeg
- libjpeg-dev
- libpng
- libpng-dev

Comment out /usr/include/pngconf.h: Line 371, 372

### Install Bundler (>= 1.0)

    $ sudo gem install bundler

### Install gems

Modify "Gemfile" when you install on Windows.

    $ cd DrawerBrowser
    $ bundle install --path vendor/bundle

## Update gems

    $ bundle update

## Settings

environment.rb

    set :drawer_image_dir, "PATH/TO/IMAGES"

## Usage

Webrick:

    $ ruby main.rb

Rackup:

    $ rackup

Thin:

    $ bundle exec thin start

Thin (production):

    $ bundle exec thin start -C thin.yaml
    $ bundle exec thin stop  -C thin.yaml

## Reference

- <http://www.sinatrarb.com/documentation>
- <http://haml-lang.com/docs.html>
- <http://jashkenas.github.com/coffee-script/>
- <http://gembundler.com/>
- <http://html5boilerplate.com/>

Sprockets:

- <https://github.com/sstephenson/sprockets>
- <http://blog.envylabs.com/2011/08/using-the-asset-pipeline-outside-of-rails-serving-and-running-coffeescript-2/>
- <https://github.com/stevehodgkiss/sinatra-asset-pipeline>
