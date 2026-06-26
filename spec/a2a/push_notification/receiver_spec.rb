# frozen_string_literal: true

require "a2a"
require "a2a/push_notification/receiver"
require "rack/test"

RSpec.describe A2A::PushNotification::Receiver do
  include Rack::Test::Methods

  def sse_body(payload_hash)
    JSON.generate(payload_hash)
  end

  def status_update_payload
    {
      "statusUpdate" => {
        "taskId" => "task-1",
        "contextId" => "ctx-1",
        "status" => { "state" => A2A::Task::State::COMPLETED },
        "final" => true
      }
    }
  end

  def task_payload
    {
      "task" => {
        "id" => "task-1",
        "status" => { "state" => A2A::Task::State::COMPLETED },
        "artifacts" => [],
        "history" => []
      }
    }
  end

  let(:received_events) { [] }
  let(:inner_app) { ->(_env) { [200, {}, ["pass-through"]] } }

  def build_app(path: "/a2a/webhook", credentials: nil, scheme: "Bearer", &handler)
    handler ||= ->(e) { received_events << e }
    described_class.new(inner_app, path: path, scheme: scheme, credentials: credentials, &handler)
  end

  let(:app) { build_app(credentials: "secret") }

  describe "routing" do
    it "passes non-matching paths through to the inner app" do
      post "/other/path", sse_body(status_update_payload),
           "CONTENT_TYPE" => "application/json",
           "HTTP_AUTHORIZATION" => "Bearer secret"

      expect(last_response.body).to eq("pass-through")
    end

    it "passes GET requests on the webhook path through to the inner app" do
      get "/a2a/webhook"

      expect(last_response.body).to eq("pass-through")
    end

    it "handles POST requests on the configured path" do
      post "/a2a/webhook", sse_body(status_update_payload),
           "CONTENT_TYPE" => "application/json",
           "HTTP_AUTHORIZATION" => "Bearer secret"

      expect(last_response.status).to eq(200)
    end
  end

  describe "authentication" do
    it "returns 401 when Authorization header is missing and credentials are configured" do
      post "/a2a/webhook", sse_body(status_update_payload), "CONTENT_TYPE" => "application/json"

      expect(last_response.status).to eq(401)
    end

    it "returns 401 when credentials do not match" do
      post "/a2a/webhook", sse_body(status_update_payload),
           "CONTENT_TYPE" => "application/json",
           "HTTP_AUTHORIZATION" => "Bearer wrong"

      expect(last_response.status).to eq(401)
    end

    it "accepts valid Bearer credentials" do
      post "/a2a/webhook", sse_body(status_update_payload),
           "CONTENT_TYPE" => "application/json",
           "HTTP_AUTHORIZATION" => "Bearer secret"

      expect(last_response.status).to eq(200)
    end

    it "is case-insensitive for the full header value comparison" do
      post "/a2a/webhook", sse_body(status_update_payload),
           "CONTENT_TYPE" => "application/json",
           "HTTP_AUTHORIZATION" => "bearer secret"

      expect(last_response.status).to eq(200)
    end

    context "when no credentials are configured" do
      let(:app) { build_app(credentials: nil) }

      it "skips auth" do
        post "/a2a/webhook", sse_body(status_update_payload),
             "CONTENT_TYPE" => "application/json"

        expect(last_response.status).to eq(200)
      end
    end
  end

  describe "event parsing" do
    before do
      post "/a2a/webhook", sse_body(status_update_payload),
           "CONTENT_TYPE" => "application/json",
           "HTTP_AUTHORIZATION" => "Bearer secret"
    end

    it "calls the handler with a Streaming::Response" do
      expect(received_events.length).to eq(1)
      expect(received_events.first).to be_a(A2A::Streaming::Response)
    end

    it "deserialises a status_update event" do
      expect(received_events.first).to be_status_update
      expect(received_events.first.payload.task_id).to eq("task-1")
    end
  end

  it "deserialises a task event" do
    post "/a2a/webhook", sse_body(task_payload),
         "CONTENT_TYPE" => "application/json",
         "HTTP_AUTHORIZATION" => "Bearer secret"

    expect(received_events.first).to be_task
  end

  describe "error handling" do
    it "returns 400 on invalid JSON" do
      post "/a2a/webhook", "not json",
           "CONTENT_TYPE" => "application/json",
           "HTTP_AUTHORIZATION" => "Bearer secret"

      expect(last_response.status).to eq(400)
      expect(JSON.parse(last_response.body)).to have_key("error")
    end

    it "returns 400 when the JSON is valid but not a recognised StreamResponse" do
      post "/a2a/webhook", '{"unknown":"payload"}',
           "CONTENT_TYPE" => "application/json",
           "HTTP_AUTHORIZATION" => "Bearer secret"

      expect(last_response.status).to eq(400)
    end
  end

  describe "response format" do
    it "returns JSON with ok: true on success" do
      post "/a2a/webhook", sse_body(status_update_payload),
           "CONTENT_TYPE" => "application/json",
           "HTTP_AUTHORIZATION" => "Bearer secret"

      body = JSON.parse(last_response.body)
      expect(body).to eq("ok" => true)
    end

    it "sets Content-Type: application/json" do
      post "/a2a/webhook", sse_body(status_update_payload),
           "CONTENT_TYPE" => "application/json",
           "HTTP_AUTHORIZATION" => "Bearer secret"

      expect(last_response.headers["Content-Type"]).to eq("application/json")
    end
  end
end
