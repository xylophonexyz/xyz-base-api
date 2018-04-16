# frozen_string_literal: true

# Helper for bundling files associated with Component objects.
module ComponentFilesBundleHelper
  include ComponentsHelper
  private

  def published_child_components(composition)
    pages_relation = Page.where(composition: composition, published: true)
    collections_relation = ComponentCollection.where(collectible: pages_relation)
    Component.where(component_collection: collections_relation)
  end

  def file_bundle_from_composition(composition)
    # given a composition, this method returns an array of objects where each object
    # in the array takes the form of [:file, :name]
    # the :file portion is either a url to download a file from a remote location or a ruby file object
    # the :name portion is a directory structure beginning with the title of associated page
    bundle = []
    published_child_components(composition).each_with_index do |component, _index|
      files_from_component(component).map { |f| bundle << f } if can_get_files_from_component?(component)
    end
    bundle
  end

  def files_from_component(component)
    return [] unless component.media.respond_to?(:[]) && component.media[:transcoding]
    media = ActiveModelSerializers::SerializableResource.new(component).as_json[:media] || {}
    files_from_serialized_resource(media)
  end

  def files_from_serialized_resource(media)
    files = []
    files << signed_file(media) if media.dig(:upload, :bucket) && media.dig(:upload, :key)
    # use the processed version of the original upload
    files << { file: media[:url], name: File.basename(media[:url]) } if media[:url]
  end

  def signed_file(media)
    signer = Aws::S3::Presigner.new
    url = signer.presigned_url(:get_object, bucket: media[:upload][:bucket], key: media[:upload][:key])
    { file: url, name: File.basename(media[:upload][:key]) }
  end

  def can_get_files_from_component?(component)
    media_component?(component)
  end
end
