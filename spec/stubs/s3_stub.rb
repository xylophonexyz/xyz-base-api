RSpec.shared_context 's3 stub', :shared_context => :metadata do

  def stub_all_s3_calls
    stub_s3_client
    stub_multipart_upload_client
  end

  def stub_multipart_upload_client
    complete_handler = double('complete')
    allow(complete_handler).to receive(:public_url) { 'http://example.com/test/1/2/file.jpg' }

    upload_handler = double('upload')
    allow(upload_handler).to receive(:etag) { 'MOCK_TEST_ETAG' }

    allow_any_instance_of(Aws::S3::MultipartUpload).to receive(:complete) { complete_handler }
    allow_any_instance_of(Aws::S3::MultipartUploadPart).to receive(:upload) { upload_handler }
  end

  def stub_s3_client
    create_handler = double('create')
    allow(create_handler).to receive(:bucket) { 'MOCK_TEST_BUCKET' }
    allow(create_handler).to receive(:key) { 'MOCK_TEST_KEY' }
    allow(create_handler).to receive(:upload_id) { 'MOCK_UPLOAD_ID' }

    put_handler = double('put_object')
    allow(put_handler).to receive(:etag) { 'MOCK_TEST_ETAG' }
    allow(put_handler).to receive(:version_id) { 'MOCK_VERSION_ID' }

    allow_any_instance_of(Aws::S3::Client).to receive(:create_multipart_upload) { create_handler }
    allow_any_instance_of(Aws::S3::Client).to receive(:put_object) { put_handler }
  end
end