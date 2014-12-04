class TagsController < ApplicationController
  before_filter :authenticate_user!, :except => [:index, :show]
  before_filter :find_tag, :only => [:show, :edit, :update, :destroy]

  def index
    @tags = Tag.where(title: /#{params[:search]}/i).desc(:count)

    respond_to do |format|
      format.html
      format.json { render json: @tags }
    end
  end

  def show
    @posts = @tag.posts.published.desc(:created_at).page(params[:page])

    respond_to do |format|
      format.html
      format.json { render json: @posts }
    end
  end

  def edit
  end

  def update
    respond_to do |format|
      if @tag.update_attributes(tag_params)
        format.html { redirect_to @tag, notice: t('flash.tags.success.update') }
        format.json { head :no_content }
      else
        @errors = @tag.errors.full_messages
        format.html { render action: "edit" }
        format.json { render json: @tag.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @tag.destroy

    respond_to do |format|
      format.html { redirect_to tags_url, notice: t('flash.tags.success.destroy') }
      format.json { head :no_content }
    end
  end

  private
  def find_tag
    @tag = Tag.find(params[:id])
  end
  
  # Never trust parameters from the scary internet, only allow the white list through.
  def tag_params
    params.require(:tag).permit(:title, :count)
  end
  
end
