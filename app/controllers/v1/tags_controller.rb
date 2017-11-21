# frozen_string_literal: true

module V1
  # TagsController
  class TagsController < ApplicationController
    skip_before_action :authenticate_user!

    def index
      render json: Tag.all.limit(10)
    end
  end
end
