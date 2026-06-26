# frozen_string_literal: true

require "a2a"
require "webmock/rspec"

RSpec.describe A2A::Protocol::JsonRpc::Transport do
  let(:url) { "https://agent.example.com/rpc" }
  let(:transport) { described_class.new }
  let(:body) { { "jsonrpc" => "2.0", "method" => "GetTask", "id" => "1", "params" => {} } }
  let(:default_headers) { { "Content-Type" => "application/json", "Accept" => "application/json" } }

  describe "#post" do
    context "when the server returns 200" do
      it "parses and returns the JSON body" do
        stub_request(:post, url)
          .to_return(status: 200, body: '{"jsonrpc":"2.0","id":"1","result":{}}',
                     headers: { "Content-Type" => "application/json" })

        result = transport.post(url, body: body, headers: default_headers)

        expect(result).to eq("jsonrpc" => "2.0", "id" => "1", "result" => {})
      end
    end

    context "when the server returns 401" do
      it "raises AuthenticationError" do
        stub_request(:post, url).to_return(status: 401, body: "Unauthorized")

        expect { transport.post(url, body: body, headers: default_headers) }
          .to raise_error(A2A::AuthenticationError, /401/)
      end
    end

    context "when the server returns 403" do
      it "raises AuthorizationError" do
        stub_request(:post, url).to_return(status: 403, body: "Forbidden")

        expect { transport.post(url, body: body, headers: default_headers) }
          .to raise_error(A2A::AuthorizationError, /403/)
      end
    end

    context "when the server returns 404" do
      it "raises TaskNotFoundError" do
        stub_request(:post, url).to_return(status: 404, body: "Not Found")

        expect { transport.post(url, body: body, headers: default_headers) }
          .to raise_error(A2A::TaskNotFoundError, /404/)
      end
    end

    context "when the server returns 500" do
      it "raises TransportError" do
        stub_request(:post, url).to_return(status: 500, body: "Internal Server Error")

        expect { transport.post(url, body: body, headers: default_headers) }
          .to raise_error(A2A::TransportError, /500/)
      end
    end

    context "request headers" do
      it "sends the headers supplied by the caller" do
        stub_request(:post, url)
          .with(headers: { "Content-Type" => "application/json", "X-Custom" => "yes" })
          .to_return(status: 200, body: "{}")

        transport.post(url, body: body, headers: default_headers.merge("X-Custom" => "yes"))
      end
    end

    context "request body" do
      it "serialises the body hash as JSON" do
        stub_request(:post, url)
          .with(body: JSON.generate(body))
          .to_return(status: 200, body: "{}")

        transport.post(url, body: body, headers: default_headers)
      end
    end

    context "with an HTTPS URL" do
      it "enables SSL" do
        stub_request(:post, url).to_return(status: 200, body: "{}")

        http_spy = instance_spy(Net::HTTP)
        allow(http_spy).to receive(:request).and_return(
          instance_double(Net::HTTPSuccess, code: "200", body: "{}")
        )
        allow(Net::HTTP).to receive(:new).and_return(http_spy)

        transport.post(url, body: body, headers: default_headers)

        expect(http_spy).to have_received(:use_ssl=).with(true)
      end
    end
  end
end
