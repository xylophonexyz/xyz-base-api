# frozen_string_literal: true

module V1
  # CommentsController
  class CommentsController < PolymorphicResourceController
    skip_before_action :authenticate_user!, only: %i[index show]

    def index
      if get_parent params[:page_id], 'Page'
        render json: @parent.root_comments
      else
        not_found
      end
    rescue NameError
      unknown_class
    end

    def create
      @comment = Comment.new(body: comment_params[:body], parent_id: comment_params[:parent_id], user: current_user)
      handle_comment_reply
      complete_create_request(@comment)
    rescue NameError
      unknown_class
    end

    def show
      complete_show_request(get_comment)
    end

    def update
      complete_update_request(get_comment, comment_params)
    end

    def destroy
      complete_destroy_request(get_comment)
    end

    private

    def create_new_comment(id, type)
      @parent.comments.push @comment if get_parent(id, type)
    end

    def add_reply_to_parent(parent_id, comment)
      parent = Comment.where(id: parent_id).first
      comment.commentable = parent.commentable
      parent.add_reply(comment)
    end

    def handle_comment_reply
      if comment_params[:parent_id]
        add_reply_to_parent comment_params[:parent_id], @comment
      else
        create_new_comment comment_params[:resource_id], comment_params[:resource_type]
      end
    end

    def get_comment(id = params[:id])
      @comment = Comment.where(id: id).first
    end

    def comment_params
      params.permit(:body, :parent_id, :resource_type, :resource_id)
    end

    def resource_params
      comment_params
    end
  end
end
