# frozen_string_literal: true

# Helper for Components based logic
module ComponentsHelper
  private

  def fetch_collection
    @collection = ComponentCollection.where(id: params[:collection_id] || params[:id]).includes(:components).first
  end

  def fetch_component
    @component = Component.where(id: params[:component_id] || params[:id]).first
  end

  def fetch_collectible
    @collectible = Page.where(id: params[:page_id]).includes(component_collections: [:components]).first
  end

  def component_collection_payload
    {
      index: parse_collection_params[:index],
      metadata: parse_collection_params[:metadata] || {},
      type: parse_collection_params[:type],
      collectible_id: parse_collection_params[:collectible_id],
      collectible_type: parse_collection_params[:collectible_type],
      components: components_from_params(parse_collection_params[:components] || [])
    }
  end

  def components_from_params(params)
    params.collect do |data|
      Component.new(component_payload(data))
    end
  end

  def component_payload(params = parse_component_params)
    {
      media: sanitize_media(params[:media]),
      index: params[:index],
      metadata: params[:metadata],
      type: params[:type]
    }
  end

  def parse_collection_params
    collection_params = params.permit(:index, :type, :collectible_id, :collectible_type)
    collection_params = collection_params.merge(components: parse_components)
    collection_params = collection_params.merge(metadata: parse_metadata) if metadata_key_present?
    collection_params
  end

  def parse_component_params
    component_params = params.permit(:media, :index, :type)
    component_params = component_params.merge(metadata: parse_metadata) if metadata_key_present?
    component_params
  end

  def parse_metadata
    params.permit![:metadata]
  end

  def parse_components
    params.permit![:components]
  end

  def metadata_key_present?
    params.key?(:metadata)
  end

  def unlink_key_present?
    params.key?(:unlink)
  end

  def sanitize_media(media)
    # remove files from params. files are uploaded to media components in a separate step
    media unless media.respond_to? :read
  end

  def get_component_transcoding_data(component)
    JSON.parse(component.media[:transcoding])
  end

  def media_component?(component)
    component.is_a?(ImageComponent) || component.is_a?(AudioComponent) ||
      component.is_a?(MediaComponent) || component.is_a?(VideoComponent)
  end

  def component_has_uploaded_media?(component)
    component.media && !component.media_processing && media_component?(component) && component.media[:transcoding]
  end
end
