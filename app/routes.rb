require 'fileutils'

get '/' do
  haml :index
end

get '/test' do
  haml :test
end

get '/images.json' do
  content_type :json
  images = []
  Dir::chdir(settings.drawer_images_dir) {
    images = Dir::glob('*.jpg').map {|filename|
      {:filename => filename}
    }
  }
  images.to_json
end

get '/thumb/:size/:filename' do
  content_type :jpeg
  original =  File.join settings.drawer_images_dir, params[:filename]
  thumb_dir = File.join "tmp/thumb/", params[:size]
  thumb =     File.join thumb_dir, params[:filename]
  FileUtils.mkdir_p(thumb_dir) unless File.exists?(thumb_dir)
  unless File.exists? thumb
    #puts "--- create thumb #{params[:filename]} ---"
    sizeToPixel = {'middle' => 200, 'small' => 50}
    pixel = sizeToPixel[params[:size]]
    Pikl::Image.open(original) do |img|
      img.fit(pixel, pixel).save(thumb, :jpeg)
    end
  end
  send_file thumb
end

get '/assets/*' do
  new_env = env.clone
  new_env["PATH_INFO"].gsub!("/assets", "")
  Sinatra::Application.sprockets.call(new_env)
end
