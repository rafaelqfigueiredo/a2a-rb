# frozen_string_literal: true

require "a2a"
require "webmock/rspec"

RSpec.describe A2A::PushNotification::Dispatcher do
  let(:url) { "https://client.example.com/webhook" }
  let(:auth) { A2A::PushNotification::AuthenticationInfo.new(scheme: "Bearer", credentials: "tok_abc") }
  let(:config) { A2A::PushNotification::Config.new(url: url, authentication: auth) }

  let(:event) do
    A2A::Streaming::Response.new(
      :status_update,
      A2A::Streaming::StatusUpdateEvent.new(
        task_id: "task-1",
        context_id: "ctx-1",
        status: A2A::Task::Status.new(state: A2A::Task::State::COMPLETED)
      )
    )
  end

  describe "#dispatch" do
    it "POSTs the event payload to the config URL" do
      stub = stub_request(:post, url).to_return(status: 200)

      described_class.new.dispatch(config, event)

      expect(stub).to have_been_requested
    end

    it "sends Content-Type: application/json" do
      stub_request(:post, url)
        .with(headers: { "Content-Type" => "application/json" })
        .to_return(status: 200)

      described_class.new.dispatch(config, event)
    end

    it "sends the Authorization header from AuthenticationInfo" do
      stub_request(:post, url)
        .with(headers: { "Authorization" => "Bearer tok_abc" })
        .to_return(status: 200)

      described_class.new.dispatch(config, event)
    end

    it "omits Authorization when config has no authentication" do
      bare_config = A2A::PushNotification::Config.new(url: url)
      stub = stub_request(:post, url).to_return(status: 200)

      described_class.new.dispatch(bare_config, event)

      expect(stub).to have_been_requested
      expect(stub.with(headers: { "Authorization" => anything })).not_to have_been_made
    end

    it "serializes the event as the request body" do
      stub_request(:post, url)
        .with { |req| JSON.parse(req.body).key?("statusUpdate") }
        .to_return(status: 200)

      described_class.new.dispatch(config, event)
    end

    it "raises TransportError on non-2xx response" do
      stub_request(:post, url).to_return(status: 500)

      expect { described_class.new.dispatch(config, event) }
        .to raise_error(A2A::TransportError, /HTTP 500/)
    end

    it "accepts a custom transport" do
      transport = instance_double(A2A::PushNotification::Dispatcher::Transport)
      allow(transport).to receive(:post)

      described_class.new(transport: transport).dispatch(config, event)

      expect(transport).to have_received(:post).with(url, body: event.to_h, headers: anything)
    end
  end
end
