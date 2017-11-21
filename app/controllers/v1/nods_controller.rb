# frozen_string_literal: true

module V1
  # NodsController
  class NodsController < PolymorphicResourceController
    before_action :fail_if_no_parent, only: [:create]

    def create
      @nod = Nod.new
      @nod.user = current_user
      @nod.noddable = @parent
      complete_create_request(@nod)
    end

    def destroy
      complete_destroy_request(fetch_nod)
    end

    private

    def complete_create_request(record)
      super(record)
    end

    def fetch_nod
      @nod = Nod.where(id: params[:id]).first
    end

    def nod_params
      params.permit(:resource_id, :resource_type)
    end

    def resource_params
      nod_params
    end
  end
end
