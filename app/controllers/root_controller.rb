class RootController < ApplicationController
  layout 'full'

  def index
    @user = User.first
  end
end
