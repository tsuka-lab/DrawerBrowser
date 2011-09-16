configure do
  set :site_title, "DrawerBrowser"
  set :drawer_images_dir, "/home/kambara/Desktop/drawer-images"

  set :haml, {:format => :html5}
  set :views, File.dirname(__FILE__) + '/app/views'
  set :root, File.expand_path('../', __FILE__)
  set :sprockets, Sprockets::Environment.new(settings.root)
  settings.sprockets.append_path File.join(settings.root, 'assets')
end

configure :production do
end

configure :test do
end

configure :development do
end
