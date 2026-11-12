class SessionsController < ApplicationController
  def new
  end

  def create
    session[:user] = params[:name]
    redirect_to secret_path
  end
end
