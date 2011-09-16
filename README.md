# DrawerBrowser

## Install

### Install pikl

<http://pikl.rubyforge.org/>

#### Install on Linux

Require:
* libjpeg
* libjpeg-dev
* libpng
* libpng-dev

Comment out /usr/include/pngconf.h: 371, 372

### Install RubyGems

### Install Bundler (>= 1.0)

    $ sudo gem install bundler

### Install gems

    $ cd MY/APP
    $ bundle install --path vendor/bundle

### Install CoffeeScript

## Update gems

    $ bundle update

## Usage

Webrick:

    $ ruby main.rb

Rackup:

    $ rackup

Thin:

    $ thin start

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
