class UploadsController < ApplicationController
  def new
  end

  def create
    @files = uploaded_files
    @caption = params[:caption]
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.update("upload-result", partial: "uploads/result", locals: { files: @files, caption: @caption }) }
      format.html
    end
  end

  private

  def uploaded_files
    [ params[:document], *params[:attachments] ].compact_blank
  end
end
