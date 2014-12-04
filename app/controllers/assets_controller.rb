class AssetsController < ApplicationController
  before_filter :authenticate_user!, :except => [:show]
  before_filter :find_asset, :only => [:show, :destroy]

  def index
    if (params[:attachable_id].blank?)
      @assets = current_user.assets.orphan
    else
      @assets = Asset.where(attachable_id: params[:attachable_id])
    end
    render :json => @assets.collect { |a| jq_hash(a) }.to_json
  end

  def show
    params[:version] = 'small' if params[:version].blank? && cookies[:resolution].to_i * cookies[:ratio].to_f < 1280
    path = case params[:version]
           when 'small', 'thumb', 'large'
             @asset.file.send(params[:version]).path
           else
             @asset.file.path
           end

    expires_in 1.year
    if File.exists?(path)
      send_file(path, disposition: 'inline') if stale?(:etag => @asset, :last_modified => @asset.updated_at.utc)
    elsif params[:version] == 'thumb'
      send_file(default_thumb(@asset.content_type), disposition: 'inline') if stale?(:etag => @asset, :last_modified => @asset.updated_at.utc)
    elsif File.exists?(@asset.file.path)
      send_file(@asset.file.path, disposition: 'inline') if stale?(:etag => @asset, :last_modified => @asset.updated_at.utc)
    else
      render_404
    end
  end

  def new
    @asset = current_user.assets.new
  end

  def create
    file = params[:asset].delete('file')
    params[:asset].merge! :file => file.last
    
    @asset = current_user.assets.new(asset_params)
    begin
      @asset.attachable = asset_params[:attachable_type].constantize.find(asset_params[:attachable_id])
    rescue => e
      logger.error "[Attachable] " << e.to_s
    end
    respond_to do |format|
      if @asset.save
        format.html {
          render :json => [jq_hash(@asset)].to_json,
          :content_type => 'text/html',
          :layout => false
        }
        format.json {
          render :json => {files: [jq_hash(@asset)]}.to_json, status: :created, location: @asset
        }
      else
        render :json => [{:error => t('views.assets.create_error')}], :status => 304
      end
    end
  end

  def destroy
    @asset.destroy
    render :text => true
  end

  private
  def find_asset
    @asset = Asset.find(params[:id])
  end

  def jq_hash(asset)
    {
      "id" => asset.id.to_s,
      "name" => asset.file_name,
      "size" => asset.file_size,
      "url" => asset_url(asset),
      "thumbnail_url" => asset_url(asset, :version => :thumb),
      "delete_type" => "DELETE"
    }
  end

  def default_thumb(text)
    path = File.join(Rails.root, 'tmp/thumbs', Digest::MD5.hexdigest(text) + '.png')
    unless File.exists?(path)
      FileUtils.mkdir_p(File.split(path).first)
      `convert -size 160x100 xc:transparent +level 80%,80% +matte -pointsize 16 -fill '#888888' -gravity center -draw "text 0,0 '#{text}'" #{path}`
    end
    path
  end
  
  # Never trust parameters from the scary internet, only allow the white list through.
  def asset_params
    params.require(:asset).permit(:file, :attachable_type, :attachable_id)
  end
  
end
