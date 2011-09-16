module AssetHelpers
  def asset_path(name)
    "/assets/#{name}"
  end
end

Sinatra::Application.sprockets.context_class.instance_eval do
  include AssetHelpers
end

helpers do
  include AssetHelpers

  def header
    haml :"partial/header"
  end

  def footer
    haml :"partial/footer"
  end

  def script src
    if @scripts
      @scripts.push src
    else
      @scripts = [src]
    end
  end
end
