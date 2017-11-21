# frozen_string_literal: true

# Helper for handling Compositions
module CompositionsControllerHelper
  private

  def publish_composition(options = { save: true, value: nil })
    if options[:value] || options[:value].nil?
      @composition.published_on = Date.today
      @composition.save if options[:save]
    else
      unpublish_composition(options)
    end
    self
  end

  def unpublish_composition(options = { save: true })
    @composition.published_on = nil
    @composition.save if options[:save]
  end

  def add_parent
    @composition.parent = Composition.where(id: params[:parent]).first
  end

  def add_cover_image
    @composition.image = ComponentCollection.new(components: [ImageComponent.new])
  end

  def composition_params
    payload = params.permit(:title)
    payload = payload.merge(metadata: parse_metadata) if metadata_key_present?
    payload
  end

  def remove_cover_image
    @composition&.image&.destroy
    @composition&.image = nil
  end

  def sanitize_params
    # avoid overriding the existing model value on update by sanitizing only if the key is present in params
    params[:title] = strip_tags(params[:title]) if title_key_present?
  end

  def fetch_composition
    id = params[:id] || params[:composition_id]
    query = composition_query_includes(Composition.where(id: id))
    @composition = query.first
  end

  def composition_query_includes(query)
    query.includes(:compositions).includes(:parent).includes(pages: [:views, :tags, nods: [:user], votes: [:user]])
  end

  def fetch_page
    @page = Page.where(id: params[:page_id]).includes(:views, :tags, nods: [:user], votes: [:user]).first
  end

  def should_add_cover_image?
    ActiveRecord::Type::Boolean.new.deserialize(params[:add_cover])
  end

  def should_remove_cover_image?
    ActiveRecord::Type::Boolean.new.deserialize(params[:remove_cover])
  end

  def should_add_parent?
    !params[:parent].nil?
  end

  def should_publish?
    ActiveRecord::Type::Boolean.new.deserialize(params[:publish])
  end

  def should_unlink?
    @page.composition == @composition
  end

  def update_cover_image
    # TODO: perform cleanup tasks around removing the old image (delete from s3)
    remove_cover_image
    add_cover_image
  end

  def perform_update_tasks
    add_parent if should_add_parent?
    update_cover_image if should_add_cover_image?
    remove_cover_image if should_remove_cover_image?
  end

  def parse_metadata
    params.permit![:metadata]
  end

  def metadata_key_present?
    params.key?(:metadata)
  end

  def title_key_present?
    params.key?(:title)
  end
end
