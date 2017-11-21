module ModelHelper

  def stub_serializers
    allow_any_instance_of(ActiveModelSerializers::SerializableResource).to receive(:as_json).and_return(
      ActiveSupport::HashWithIndifferentAccess.new({
        media: {
          audio_track: 'http://example.com',
          url: 'http://example.com',
          images: %w(http://example.com http://example.com),
          poster: 'http://example.com',
          encode: 'http://example.com',
          thumbs: %w[http://example.com http://example.com]
        }
      })
    )
  end

  def random_string
    ('a'..'z').to_a.shuffle[0, 8].join
  end

  def parse_response
    @res = JSON.parse(response.body)
  end

  def new_audio_component
    AudioComponent.new
  end

  def new_audio_file
    File.open('test/helpers/file.mp3')
  end

  def new_image_component
    ImageComponent.new
  end

  def new_image_file
    File.open('test/helpers/file.png')
  end

  def new_video_component
    VideoComponent.new
  end

  def new_video_file
    File.open('test/helpers/file.mp4')
  end

  def new_media_component
    MediaComponent.new
  end

  def new_media_file
    File.open("test/helpers/file.#{ext}")
  end

  def new_user
    User.new(user_params)
  end

  def new_comment
    Comment.new(:body => random_string)
  end

  def new_page
    page = Page.new(page_params)
    page.user = new_user
    page
  end

  def new_composition
    composition = Composition.new({
      title: "My Composition - #{Random.rand}"
    })
    composition.user = new_user
    composition
  end

  def new_nod
    Nod.new
  end

  def new_vote
    Vote.new
  end

  private

  def flush_cache
    Rails.cache.clear
  end

  def page_params
    {
      title: 'My Page',
      description: 'A brief description'
    }
  end

  def user_params
    {
      username: random_string,
      email: random_string + '@example.com'
    }
  end
end
