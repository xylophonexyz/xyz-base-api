require 'rails_helper'
require "stubs/transloadit_stub"

RSpec.describe MediaTranscodingJob, type: :job do
  include_context 'transloadit stub'

  before :each do
    stub_all_transloadit_calls
  end
end
