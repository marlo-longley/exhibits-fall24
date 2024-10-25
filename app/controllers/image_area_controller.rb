class ImageAreaController < ApplicationController
    # TODO: we probably want auth 
    skip_before_action :verify_authenticity_token, only: [:create]
  
    def create
    # debugger
      # data will be stringified JSON
      data = request.body.read
      file_path = Rails.root.join('fakestate.json')
  
      File.open(file_path, 'w') do |file|
        file.write(data)
      end
  
      render json: { status: 'success' }, status: :ok
    rescue StandardError => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end
  