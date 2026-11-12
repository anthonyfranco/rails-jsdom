class ItemsController < ApplicationController
  def create
    @name = params[:name]
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to root_path }
    end
  end

  def destroy
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.remove("item_#{params[:id]}") }
      format.html { redirect_to root_path }
    end
  end
end
