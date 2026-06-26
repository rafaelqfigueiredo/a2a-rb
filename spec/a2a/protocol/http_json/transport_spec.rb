# frozen_string_literal: true

require "a2a"
require "webmock/rspec"

RSpec.describe A2A::Protocol::HttpJson::Transport do
  let(:base) { "https://agent.example.com" }
  let(:transport) { described_class.new }
  let(:default_headers) { { "Content-Type" => "application/json", "Accept" => "application/json" } }

  describe "#get" do
    it "performs a GET request and returns parsed JSON" do
      stub_request(:get, "#{base}/tasks/t1")
        .to_return(status: 200, body: '{"id":"t1"}', headers: { "Content-Type" => "application/json" })

      result = transport.get("#{base}/tasks/t1", query: {}, headers: default_headers)

      expect(result).to eq("id" => "t1")
    end

    it "encodes query parameters into the URL" do
      stub_request(:get, "#{base}/tasks")
        .with(query: { "pageSize" => "10" })
        .to_return(status: 200, body: "{}", headers: {})

      transport.get("#{base}/tasks", query: { "pageSize" => "10" }, headers: default_headers)
    end

    it "raises AuthenticationError on 401" do
      stub_request(:get, "#{base}/tasks/t1").to_return(status: 401)
      expect { transport.get("#{base}/tasks/t1", query: {}, headers: default_headers) }
        .to raise_error(A2A::AuthenticationError, /401/)
    end

    it "raises TaskNotFoundError on 404" do
      stub_request(:get, "#{base}/tasks/t1").to_return(status: 404)
      expect { transport.get("#{base}/tasks/t1", query: {}, headers: default_headers) }
        .to raise_error(A2A::TaskNotFoundError, /404/)
    end
  end

  describe "#post" do
    it "performs a POST request and returns parsed JSON" do
      stub_request(:post, "#{base}/tasks")
        .to_return(status: 200, body: '{"task":{"id":"t1"}}', headers: { "Content-Type" => "application/json" })

      result = transport.post("#{base}/tasks", body: { "message" => {} }, headers: default_headers)

      expect(result).to eq("task" => { "id" => "t1" })
    end

    it "serialises the body as JSON" do
      body = { "message" => { "text" => "hi" } }
      stub_request(:post, "#{base}/tasks")
        .with(body: JSON.generate(body))
        .to_return(status: 200, body: "{}")

      transport.post("#{base}/tasks", body: body, headers: default_headers)
    end

    it "raises AuthorizationError on 403" do
      stub_request(:post, "#{base}/tasks").to_return(status: 403)
      expect { transport.post("#{base}/tasks", body: {}, headers: default_headers) }
        .to raise_error(A2A::AuthorizationError, /403/)
    end
  end

  describe "#delete" do
    it "performs a DELETE request and returns nil" do
      stub_request(:delete, "#{base}/tasks/t1/push/cfg1").to_return(status: 204)

      result = transport.delete("#{base}/tasks/t1/push/cfg1", headers: default_headers)

      expect(result).to be_nil
    end

    it "raises TransportError on 500" do
      stub_request(:delete, "#{base}/tasks/t1/push/cfg1").to_return(status: 500)
      expect { transport.delete("#{base}/tasks/t1/push/cfg1", headers: default_headers) }
        .to raise_error(A2A::TransportError, /500/)
    end
  end

  describe "#stream" do
    it "yields the response for a POST stream" do
      stub_request(:post, "#{base}/tasks:sendSubscribe")
        .to_return(status: 200, body: "data: {}\n\n")

      yielded = false
      transport.stream("#{base}/tasks:sendSubscribe",
                       headers: default_headers.merge("Accept" => "text/event-stream"),
                       method: :post, body: {}) do |_r|
        yielded = true
      end

      expect(yielded).to be true
    end

    it "yields the response for a GET stream" do
      stub_request(:get, "#{base}/tasks/t1:subscribe")
        .to_return(status: 200, body: "data: {}\n\n")

      yielded = false
      transport.stream("#{base}/tasks/t1:subscribe",
                       headers: default_headers.merge("Accept" => "text/event-stream"),
                       method: :get) do |_r|
        yielded = true
      end

      expect(yielded).to be true
    end
  end
end
