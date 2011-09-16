require 'main'

use Rack::StaticIfPresent, :urls => ["/thumb"], :root => "tmp"
run Sinatra::Application
