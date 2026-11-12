class ApplicationController < ActionController::Base
  private

  def signed_in?
    session[:user].present?
  end
end
