class PostsController < ApplicationController
  before_filter :authenticate_user!, :except => [:index, :show, :feed]
  before_filter :find_post, :only => [:show, :edit, :update, :destroy]

  def index
    @tags = Tag.used.desc(:count)
    @posts = Post.published.desc(:created_at)

    respond_to do |format|
      format.html { render :index, layout: 'full' }
      format.json { render json: @posts.page(params[:page]) }
    end
  end

  def drafts
    @posts = Post.where(published: false).desc(:updated_at).page(params[:page])

    respond_to do |format|
      format.html
      format.json { render json: @posts }
    end
  end

  def show
    render_404 unless user_signed_in? || @post.published?

    respond_to do |format|
      format.html
      format.json { render json: @post }
    end
  end

  def new
    @post = current_user.posts.new

    respond_to do |format|
      format.html
      format.json { render json: @post }
    end
  end

  def edit
  end

  def create
    @post = current_user.posts.new(params[:post])

    respond_to do |format|
      if @post.save
        @post.assets = Asset.find(params[:asset_ids] || [])
        format.html { redirect_to @post, notice: t('flash.posts.success.create') }
        format.json { render json: @post, status: :created, location: @post }
      else
        @errors = @post.errors.full_messages
        format.html { render action: "new" }
        format.json { render json: @post.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @post.update_attributes(params[:post])
        @post.assets = Asset.find(params[:asset_ids] || [])
        format.html { redirect_to @post, notice: t('flash.posts.success.update') }
        format.json { head :no_content }
      else
        @errors = @post.errors.full_messages
        format.html { render action: "edit" }
        format.json { render json: @post.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @post.destroy

    respond_to do |format|
      format.html { redirect_to posts_url, notice: t('flash.posts.success.destroy') }
      format.json { head :no_content }
    end
  end

  def feed
    @posts = Post.published.desc(:created_at).limit(16)

    respond_to do |format|
      format.atom
    end
  end

  private
  def find_post
    @post = Post.find(params[:id])
  end
end
