configure do
  SiteConfig = OpenStruct.new(:title => 'DrawerViewer')

  set :haml, {:format => :html5}
  set :views, File.dirname(__FILE__) + '/app/views'

  root = File.expand_path('../', __FILE__)
  set :sprockets, Sprockets::Environment.new(root)
  Sinatra::Application.sprockets.append_path File.join(root, 'assets')
end

configure :production do
end

configure :test do
end

configure :development do
end
