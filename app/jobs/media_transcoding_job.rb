# frozen_string_literal: true

#
# Perform transcoding on MediaComponent objects
#
# Subclasses that implement this job must provide a definition for the create_new_transcoding_job! method
#
# This method defines the steps in the assembly that will execute on the given media object.
# Additionally, this job requires that the media component has a valid key in S3 and it is accessible by
# reaching into component.media[:upload][:key]
# This job will store the response of the transcoding job into component.media[:transcoding]
# This job will check to see if the job is done, and continue to schedule the same job recursively until it is
# complete. it will only perform the transcoding operation once per component lifecycle, or until the :transcoding
# object is removed from the media attribute
#
class MediaTranscodingJob < ApplicationJob

  queue_as :critical

  def perform(component_id)
    component = Component.find component_id
    response = refresh_assembly_status component
    finalize_transcoding_job(component, response)
  end

  private

  def finalize_transcoding_job(component, response)
    # set the value of the :transcoding attribute as the response returned by the service
    component.media[:transcoding] = JSON.generate(response.body)
    if response.finished?
      component.media_processing = false
      component.media[:error] = response.body['message'] if response.error?
      # ensure billing account reflects new usage
      BillingDataQuantifierJob.perform_later(component)
    else
      # schedule a new job to update the status of the transcoding. In prod, this will be done through the notify_url
      self.class.set(wait: 2.seconds).perform_later(component.id) if Rails.env == 'development'
    end
    component.save
  end

  def refresh_assembly_status(component)
    if transcoding_attribute_present? component
      # a transcoding job has already been started, refresh the status
      assembly_id = JSON.parse(component.media[:transcoding])['assembly_id']
      get_transcoding_job_status!(assembly_id)
    else
      # this is a new transcoding invocation
      create_new_transcoding_job!(component)
    end
  end

  def transcoding_attribute_present?(component)
    component&.media && component.media[:transcoding]
  end

  def import(path)
    transloadit_client.step('import', '/s3/import', {
      key: ENV.fetch('AWS_ACCESS_KEY_ID'),
      secret: ENV.fetch('AWS_SECRET_ACCESS_KEY'),
      bucket: ENV.fetch('S3_BUCKET'),
      bucket_region: ENV.fetch('AWS_REGION'),
      path: path
    })
  end

  def store_key
    # this method must be implemented by the subclass
    ''
  end

  def store
    transloadit_client.step('store', '/s3/store', {
      key: ENV.fetch('AWS_ACCESS_KEY_ID'),
      secret: ENV.fetch('AWS_SECRET_ACCESS_KEY'),
      bucket: ENV.fetch('S3_BUCKET'),
      bucket_region: ENV.fetch('AWS_REGION'),
      url_prefix: ENV.fetch('ASSET_HOST'),
      use: store_key
    })
  end

  def create_new_transcoding_job!(component)
    assembly = transloadit_client.assembly(assembly_payload(component))
    assembly.create!
  rescue StandardError => error
    component.media_processing = false
    component.media[:error] = 'Exception thrown while creating transcoding job'
    component.save
    raise error
  end

  def assembly_payload(component)
    path = extract_s3_upload_path(component)
    payload = { notify_url: notify_url(component) }
    payload.merge(transcoding_steps(path))
  end

  def transcoding_steps(path)
    # subclass must implement this method
    raise ':transcoding_steps method must be implemented by subclass'
  end

  def get_transcoding_job_status!(assembly_id)
    req = Transloadit::Request.new('/assemblies/' + assembly_id.to_s, ENV.fetch('TRANSLOADIT_SECRET'))
    req.get.extend!(Transloadit::Response::Assembly)
  end

  def transloadit_client
    @transloadit ||= Transloadit.new({
      key: ENV.fetch('TRANSLOADIT_KEY'),
      secret: ENV.fetch('TRANSLOADIT_SECRET')
    })
  end

  def extract_s3_upload_path(component)
    component.media[:upload][:key]
  end

  def notify_url(component)
    "#{ENV.fetch('HOST_URL')}/v1/components/#{component.id}/notify"
  end
end
