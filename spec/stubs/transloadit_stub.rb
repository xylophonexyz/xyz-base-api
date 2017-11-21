RSpec.shared_context 'transloadit stub', :shared_context => :metadata do

  def stub_all_transloadit_calls
    stub_transloadit_client
  end

  def stub_transloadit_client
    step_handler = double('step')
    assembly_handler = double('assembly')
    response_handler = double('response')

    allow(assembly_handler).to receive(:create!) { response_handler }
    allow(response_handler).to receive(:finished?) { true }
    allow(response_handler).to receive(:error?) { false }
    allow(response_handler).to receive(:body) { generic_response }

    allow_any_instance_of(Transloadit).to receive(:step) { step_handler }
    allow_any_instance_of(Transloadit).to receive(:assembly) { assembly_handler }
  end

  def generic_response
    {
      'assembly_id': 123,
      'assembly_url': 'http://example.com/',
      'http_code': 200,
      'url': 'http://example.com/something',
      'results': {
        ':original': [{
          'url': 'http://example.com/something'
        }],
        'encode': [{ url: 'http://example.com/something' }],
        'concat': [{ url: 'http://example.com/something' }],
        'images': [{ url: 'http://example.com/something' }, { url: 'http://example.com/something' }],
        'thumbs': [{ url: 'http://example.com/something' }, { url: 'http://example.com/something' }]
      }
    }
  end
end
