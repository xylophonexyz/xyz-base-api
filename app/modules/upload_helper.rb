# frozen_string_literal: true

# Helper for handling uploads to S3
module UploadHelper
  private

  def complete_multipart_upload(upload_id, key)
    upload_client = Aws::S3::MultipartUpload.new(bucket_name: s3_bucket, object_key: key, id: upload_id)
    upload_client.complete(compute_parts: true)
  end

  def create_multipart_upload(key)
    # create a multipart upload with the specified key, returns a metadata object that can be used to infer
    # information about the upload
    # TODO: do we want this to be public read?
    response = s3_client.create_multipart_upload(acl: 'public-read', bucket: s3_bucket, key: key)
    {
      bucket: response.bucket,
      key: response.key,
      upload_id: response.upload_id,
      uploaded_size: 0,
      total_size: upload_metadata[:total_size],
      last_uploaded_part_number: nil,
      uploaded_parts: [],
      upload_complete: false
    }
  end

  def minimum_upload_size
    5 * 1024 * 1024
  end

  def multipart_upload_complete?(uploaded_size)
    uploaded_size == upload_metadata[:total_size]
  end

  def s3_bucket
    ENV['S3_BUCKET']
  end

  def s3_client
    @s3_client ||= Aws::S3::Client.new(credentials: Aws::Credentials.new(ENV['AWS_ACCESS_KEY_ID'],
                                                                         ENV['AWS_SECRET_ACCESS_KEY']),
                                       region: ENV['AWS_REGION'])
  end

  def should_use_multipart?
    # check if first chunk is less than 5MB. if so use a regular upload. MultiPart uploads have a 5MB minimum
    upload_metadata[:total_size] > minimum_upload_size
  end

  def upload_file(key, file)
    # upload a file in full to a bucket given a specified key
    response = s3_client.put_object(acl: 'public-read', # TODO: change control policy from public read access
                                    key: key,
                                    body: params[:file].read,
                                    bucket: s3_bucket)
    upload_file_response_object(file, key, response)
  end

  def upload_file_response_object(file, key, response)
    {
      bucket: s3_bucket,
      last_uploaded_etag: response.etag,
      version: response.version_id,
      key: key,
      uploaded_size: file.size,
      total_size: upload_metadata[:total_size],
      upload_id: nil,
      last_uploaded_part_number: nil,
      uploaded_parts: nil
    }
  end

  def upload_metadata(options = { set_defaults: true })
    # this method relies on a `params` method to be accessible by the caller that returns
    # a hash or request params object
    {
      total_size: total_size(options),
      part_number: part_number(options),
      upload_size: upload_size
    }
  end

  def part_number(options)
    # part number starts at zero from client, we increment. this is the minimum value that s3 accepts.
    if params[:_part_number]
      params[:_part_number].to_i + 1
    elsif options[:set_defaults]
      # assume we want to upload in one part if no part_number is supplied
      1
    end
  end

  def total_size(options)
    # the total size of the current upload/chunk.
    # if no total size parameter is given we assume that the upload should be completed in one part and
    # set the total_size parameter to the size of the file uploaded
    if params[:_total_size]
      params[:_total_size].to_i
    elsif options[:set_defaults]
      upload_size
    end
  end

  def upload_part(upload_id, key, file)
    uploader = Aws::S3::MultipartUploadPart.new(bucket_name: s3_bucket,
                                                object_key: key,
                                                multipart_upload_id: upload_id,
                                                part_number: upload_metadata[:part_number])
    request = uploader.upload(body: file.read)
    file.close
    request.etag
  end

  def upload_size
    params[:file].size
  end

  def uploaded_object(key)
    Aws::S3::Object.new(key: key, bucket_name: s3_bucket)
  end

  def handle_upload_request_error
    return not_found unless @component
    msg = 'One or parameters is invalid or upload is not supported for this type of component'
    render json: { errors: msg }, status: :bad_request
  end

  def process_new_upload(key)
    @component.media ||= {}
    # a multipart upload has not already been created for this object. create one
    @component.media[:upload] = create_multipart_upload(key) if should_use_multipart?
    # the file is small enough to upload directly
    @component.media[:upload] = upload_file(key, params[:file]) unless should_use_multipart?
  end

  def process_multipart_upload(key)
    # perform the upload of this part
    etag = upload_part(@component.media[:upload][:upload_id], key, params[:file])
    # store etag information in case reconstruction or debugging is necessary
    @component.media[:upload][:last_uploaded_etag] = etag
    # write additional upload metadata
    write_upload_metadata
    # the upload is complete, finish up
    finish_multipart_upload(key) if multipart_upload_complete? @component.media[:upload][:uploaded_size]
  end

  def write_upload_metadata
    # keep track of the last part that was uploaded successfully, even if it is out of order
    @component.media[:upload][:last_uploaded_part_number] = upload_metadata[:part_number]
    # check if we've used this part number previously
    return if @component.media[:upload][:uploaded_parts].include?(upload_metadata[:part_number])
    write_uploaded_parts_metadata
    write_upload_size_metadata
  end

  def write_upload_size_metadata
    # increase the :uploaded_size parameter only if this is a newly uploaded part
    @component.media[:upload][:uploaded_size] += upload_metadata[:upload_size]
  end

  def write_uploaded_parts_metadata
    # add this part number to the :uploaded_parts Set
    @component.media[:upload][:uploaded_parts] << upload_metadata[:part_number]
  end

  def process_standard_upload(key)
    complete_upload(uploaded_object(key))
  end

  def finish_multipart_upload(key)
    complete_upload(complete_multipart_upload(@component.media[:upload][:upload_id], key))
  end

  def complete_upload(uploaded_object)
    @component.media[:original] = { url: uploaded_object.public_url }
    @component.media[:upload][:upload_complete] = true
  end

  def process_upload_for_component
    key = "#{Rails.env}/components/#{@component.id}/#{@filename_for_upload}"
    # check if this a new upload or a continuation of a previous one
    process_new_upload key unless @component.media&.dig(:upload)

    if should_use_multipart?
      # split this upload into parts
      process_multipart_upload key
    else
      # dealing with a single file upload, finish up
      process_standard_upload key
    end
  end

  def validate_params_for_upload
    # reject if an upload has already been started but :total_size has been omitted for the current cycle
    return false if total_size_param_nil?
    file_params_valid?
  end

  def total_size_param_nil?
    @component&.media && @component.media[:upload] && upload_metadata(set_defaults: false)[:total_size].nil?
  end

  def file_params_valid?
    @component.is_a?(MediaComponent) && params[:file] && params[:filename]
  end
end
