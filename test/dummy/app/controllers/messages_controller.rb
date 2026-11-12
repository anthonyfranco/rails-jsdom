class MessagesController < ApplicationController
  def index
  end

  def create
    Turbo::StreamsChannel.broadcast_append_to("messages", target: "messages", html: "<li>#{ERB::Util.html_escape(session[:user])}: #{ERB::Util.html_escape(params[:body])}</li>")
    head :no_content
  end
end
