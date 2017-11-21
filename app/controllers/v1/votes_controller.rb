# frozen_string_literal: true

module V1
  # VotesController
  class VotesController < PolymorphicResourceController
    before_action :fail_if_no_parent, only: [:create]

    def create
      @vote = check_for_existing_vote || Vote.new
      @vote.votable = @parent
      @vote.user = current_user
      @vote.value = vote_params[:value]
      complete_create_request(@vote)
    end

    def update
      complete_update_request(fetch_vote, value: vote_params[:value])
    end

    private

    def check_for_existing_vote
      @vote = Vote.where(votable: @parent, user: current_user).first
    end

    def fetch_vote
      @vote = Vote.where(id: params[:id]).first
    end

    def vote_params
      params.permit(:resource_id, :resource_type, :value)
    end

    def resource_params
      vote_params
    end
  end
end
