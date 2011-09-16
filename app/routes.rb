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
  Dir::chdir('public/drawer-images') {
    images = Dir::glob('*.jpg').map {|filename|
      {:filename => filename}
    }
  }
  images.to_json
end

get '/thumb/:size/:filename' do
  content_type :jpeg
  original = "public/drawer-images/#{params[:filename]}"
  thumb_dir = "tmp/thumb/#{params[:size]}"
  thumb = "#{thumb_dir}/#{params[:filename]}"
  FileUtils.mkdir_p(thumb_dir) unless File.exists?(thumb_dir)
  unless File.exists? thumb
    sizeToPixel = {'middle' => 200, 'small' => 50}
    p sizeToPixel[params[:size]]
    pixel = sizeToPixel[params[:size]]
    Pikl::Image.open(original) do |img|
      img.fit(pixel, pixel).save(thumb, :jpeg)
    end
  end
  File.open(thumb, 'rb')
end

get '/assets/*' do
  new_env = env.clone
  new_env["PATH_INFO"].gsub!("/assets", "")
  Sinatra::Application.sprockets.call(new_env)
end
