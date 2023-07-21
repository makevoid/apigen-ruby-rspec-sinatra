module GPTFix

  def gpt_request_data_fix_prompt_system
    <<-PROMPT.strip
You are a software development assistant that helps and debug fixing code, you will be given with a series of files that are part of your program, implementation files and test files. You will also be provided with two outputs, the output of your program running (that when working should display no output) and the error ouptut of your test suite of tests running. You need to make changes to your code so that the error output is fixed and the program output is empty. You can edit the implementation files or the test files, you can also add new files.

You can require 'webmock/rspec' to use `stub_request` to stub the API response.

return only ```ruby blocks, at every request return a ```ruby block with the code you generated based on the user's request, return only a ```ruby block like in this

Respond always in this format, specifying the file you want to edit as first line of ruby block in a comment (e.g. '# filename.rb'), do not use another format.
Do not explain where the fix is, just return code that fixes the issue.

Example - you have some existing code:

```ruby
# app.rb

require 'sinatra'
require 'json'
require 'net/http'

class App < Sinatra::Base
  configure do
    set :show_exceptions, false
  end

  get '/convert' do
    from_currency = params['from']
    to_currency = params['to']
    amount = params['amount'].to_f

    exchange_rate = fetch_exchange_rate
    converted_amount = convert_currency(amount, exchange_rate, from_currency, to_currency)

    content_type :json
    { from: from_currency, to: to_currency, amount: converted_amount }.to_json
  end

  private

  def fetch_exchange_rate
    api_key = File.read(File.expand_path('~/.exchangerate_api_key')).strip
    url = "https://v6.exchangerate-api.com/v6/\#{api_key}/latest/USD"
    response = Net::HTTP.get(URI(url))
    JSON.parse(response)['conversion_rates']
  end

  def convert_currency(amount, exchange_rate, from_currency, to_currency)
    from_rate = exchange_rate[from_currency]
    to_rate = exchange_rate[to_currency]

    converted_amount = amount * (to_rate / from_rate)
    converted_amount.round(2)
  end
end
```

```ruby
# app_spec.rb

require 'rack/test'
require_relative './app'

describe CurrencyConverterApp do
  include Rack::Test::Methods

  def app
    CurrencyConverterApp
  end

  it "returns the converted amount in the target currency" do
    # Mock the response from the exchange rate API
    exchange_rate = {
      "USD" => 1.0,
      "EUR" => 0.85,
      "GBP" => 0.75
    }
    allow_any_instance_of(CurrencyConverterApp).to receive(:fetch_exchange_rate).and_return(exchange_rate)

    # Perform the request
    get '/convert', from: 'USD', to: 'EUR', amount: 100

    # Verify the response
    expect(last_response).to be_ok
    expect(last_response.body).to eq({ from: 'USD', to: 'EUR', amount: 85.0 }.to_json)
  end
end
```

And you get this error output:
---
F

Failures:

  1) CurrencyConverterApp GET /convert returns an error if the 'from' currency is missing
     Failure/Error: expect(last_response).to be_bad_request
       expected `#<Rack::MockResponse:0x000000011193a780 @original_headers={"Content-Type"=>"text/html;charset=utf-8",.../response.rb:287>, @block=nil, @body=["<h1>Internal Server Error</h1>"], @buffered=true, @length=30>.bad_request?` to be truthy, got false
     # ./app_spec.rb:32:in `block (3 levels) in <top (required)>'

Finished in X seconds (files took X seconds to load)
1 examples, 1 failures

Failed examples:

rspec ./app_spec.rb:10 # CurrencyConverterApp GET /convert returns the converted amount in the target currency
---

Provide a code response that fixes the file by modifying either the implementation or the test file, or both code files. You need to return a ```ruby block with the code that fixes the issue of the whole file.

For each file, respond always in the given format, specifying the file you want to edit as first line of ruby block in a comment (e.g. '# filename.rb'), do not use another format.
Do not explain where the fix is, just return code that fixes the issue.
PROMPT
  end

  def gpt_request_data_fix_prompt_user_pre
    <<-PROMPT.strip
Code to edit to fix the issue:
```ruby
# app.rb

require 'sinatra'
require 'json'
require 'net/http'
require 'dotenv/load'

get '/stocks' do
  stock_symbol = params[:stock_symbol]
  alpha_vantage_api_key = ENV['ALPHA_VANTAGE_API_KEY']

  if stock_symbol.nil? || alpha_vantage_api_key.nil?
    status 400
    return { error: 'Missing stock_symbol or ALPHA_VANTAGE_API_KEY' }.to_json
  end

  uri = URI("https://www.alphavantage.co/query?function=GLOBAL_QUOTE&symbol=\#{stock_symbol}&apikey=#\{alpha_vantage_api_key}")
  response = Net::HTTP.get(uri)
  data = JSON.parse(response)

  if data['Global Quote'].nil?
    status 404
    return { error: 'Stock symbol not found' }.to_json
  end

  stock_data = data['Global Quote']

  {
    stock_symbol: stock_data['01. symbol'],
    price: stock_data['05. price'],
    high: stock_data['03. high'],
    low: stock_data['04. low'],
    volume: stock_data['06. volume']
  }.to_json
end
```

```ruby
require 'rack/test'
require_relative './app'

describe 'Stocks API' do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  it 'returns stock data for a valid stock symbol' do
    get '/stocks', stock_symbol: 'AAPL'
    expect(last_response).to be_ok
    expect(last_response.body).to include('stock_symbol', 'price', 'high', 'low', 'volume')
    puts "\nReturns stock data for a valid stock symbol\n\#{last_response.body[0..80]}\n---\n"
  end

  it 'returns an error for missing stock symbol' do
    get '/stocks'
    expect(last_response.status).to eq(400)
    expect(last_response.body).to include('Missing stock_symbol')
    puts "\nReturns an error for missing stock symbol\n\#{last_response.body[0..80]}\n---\n"
  end
end
```

Error output from running the tests:
-----
F
Returns an error for missing stock symbol
{"error":"Missing stock_symbol or ALPHA_VANTAGE_API_KEY"}
---
.

Failures:

  1) Stocks API returns stock data for a valid stock symbol
     Failure/Error: expect(last_response).to be_ok
       expected `#<Rack::MockResponse:0x000000010fdf8210 @original_headers={"Content-Type"=>"text/html;charset=utf-8",...@body=["{\"error\":\"Missing stock_symbol or ALPHA_VANTAGE_API_KEY\"}"], @buffered=true, @length=57>.ok?` to be truthy, got false
     # ./app_spec.rb:13:in `block (2 levels) in <top (required)>'

Finished in X seconds (files took X seconds to load)
2 examples, 1 failures

Failed examples:

rspec ./app_spec.rb:11 # Stocks API returns stock data for a valid stock symbol
-----
    PROMPT
  end

  def gpt_request_data_fix_prompt_assistant
    <<-PROMPT.strip
```ruby
# app.rb

require 'sinatra'
require 'json'
require 'net/http'
require 'dotenv/load'

# config

ALPHA_VANTAGE_API_KEY = File.read( File.expand_path "~/.alphavantage_api_key" ).strip

# routes

get '/stocks' do
  stock_symbol = params[:stock_symbol]

  if stock_symbol.nil? || ALPHA_VANTAGE_API_KEY.nil?
    status 400
    return {
      error: 'Missing stock_symbol or ALPHA_VANTAGE_API_KEY'
    }.to_json
  end

  uri = URI("https://www.alphavantage.co/query?function=GLOBAL_QUOTE&symbol=\#{stock_symbol}&apikey=\#{alpha_vantage_api_key}")
  response = Net::HTTP.get(uri)
  data = JSON.parse(response)

  if data['Global Quote'].nil?
    status 404
    return { error: 'Stock symbol not found' }.to_json
  end

  stock_data = data['Global Quote']

  {
    stock_symbol: stock_data['01. symbol'],
    price:        stock_data['05. price'],
    high:         stock_data['03. high'],
    low:          stock_data['04. low'],
    volume:       stock_data['06. volume'],
  }.to_json
end
```

```ruby
# app_spec.rb

require 'rack/test'
require_relative './app'

describe 'Stocks API' do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  it 'returns stock data for a valid stock symbol' do
    get '/stocks', stock_symbol: 'AAPL'
    expect(last_response).to be_ok
    expect(last_response.body).to include('stock_symbol', 'price', 'high', 'low', 'volume')
    puts "\nReturns stock data for a valid stock symbol\n\#{last_response.body[0..80]}\n---\n"
  end

  it 'returns an error for missing stock symbol' do
    get '/stocks'
    expect(last_response.status).to eq(400)
    expect(last_response.body).to include('Missing stock_symbol')
    puts "\nReturns an error for missing stock symbol\n\#{last_response.body[0..80]}\n---\n"
  end
end
```
    PROMPT
  end

  # -------------


  def gpt_request_data_fix_prompt_user_pre_2
    <<-PROMPT.strip
Code to edit to fix the issue:
```ruby
# app.rb

require 'sinatra'
require 'json'
require 'net/http'

class CurrencyConverterApp < Sinatra::Base
  configure do
    set :show_exceptions, false
  end

  get '/convert' do
    from_currency = params['from']
    to_currency = params['to']
    amount = params['amount'].to_f

    exchange_rate_api_key = File.read(File.expand_path('~/.exchangerate_api_key')).strip
    exchange_rate_url = "https://v6.exchangerate-api.com/v6/\#{exchange_rate_api_key}/latest/USD"

    uri = URI(exchange_rate_url)
    response = Net::HTTP.get(uri)
    exchange_rates = JSON.parse(response)['conversion_rates']

    if exchange_rates.key?(from_currency) && exchange_rates.key?(to_currency) && amount.is_a?(Numeric)
      converted_amount = amount * (exchange_rates[to_currency] / exchange_rates[from_currency])
      { 'from': from_currency, 'to': to_currency, 'amount': amount, 'converted_amount': converted_amount }.to_json
    else
      status 400
      { 'error': 'Invalid currency' }.to_json
    end
  end
end
```

```ruby
# app_spec.rb

require 'rack/test'
require_relative './app'

describe CurrencyConverterApp do
  include Rack::Test::Methods

  def app
    CurrencyConverterApp
  end

  before do
    allow(File).to receive(:read).and_return("API_KEY")
    allow(Net::HTTP).to receive(:get).and_return('{"conversion_rates": {"USD": 1.0, "EUR": 0.85}}')
  end

  it "returns the converted amount when valid parameters are provided" do
    get '/convert', { from: 'USD', to: 'EUR', amount: 100 }

    expect(last_response.status).to eq(200)
    expect(last_response.body).to eq('{"from":"USD","to":"EUR","amount":100.0,"converted_amount":85.0}')
  end

  it "returns an error when invalid currency is provided" do
    get '/convert', { from: 'USD', to: 'GBP', amount: 100 }

    expect(last_response.status).to eq(400)
    expect(last_response.body).to eq('{"error":"Invalid currency"}')
  end

  it "returns an error when 'from' currency is missing" do
    get '/convert', { to: 'EUR', amount: 100 }

    expect(last_response.status).to eq(400)
    expect(last_response.body).to eq('{"error":"Invalid currency"}')
  end

  it "returns an error when 'to' currency is missing" do
    get '/convert', { from: 'USD', amount: 100 }

    expect(last_response.status).to eq(400)
    expect(last_response.body).to eq('{"error":"Invalid currency"}')
  end

  it "returns an error when 'amount' is missing" do
    get '/convert', { from: 'USD', to: 'EUR' }

    expect(last_response.status).to eq(400)
    expect(last_response.body).to eq('{"error":"Invalid currency"}')
  end

  it "returns an error when 'amount' is not a number" do
    get '/convert', { from: 'USD', to: 'EUR', amount: 'abc' }

    expect(last_response.status).to eq(400)
    expect(last_response.body).to eq('{"error":"Invalid currency"}')
  end
end
```

Error output from running the tests:
-----
....FF

Failures:

  1) CurrencyConverterApp returns an error when 'amount' is missing
     Failure/Error: expect(last_response.status).to eq(400)

       expected: 400
            got: 200

       (compared using ==)
     # ./app_spec.rb:47:in `block (2 levels) in <top (required)>'

  2) CurrencyConverterApp returns an error when 'amount' is not a number
     Failure/Error: expect(last_response.status).to eq(400)

       expected: 400
            got: 200

       (compared using ==)
     # ./app_spec.rb:54:in `block (2 levels) in <top (required)>'

Finished in X seconds (files took X seconds to load)
6 examples, 2 failures

Failed examples:

rspec ./app_spec.rb:44 # CurrencyConverterApp returns an error when 'amount' is missing
rspec ./app_spec.rb:51 # CurrencyConverterApp returns an error when 'amount' is not a number
-----
    PROMPT
  end

  def gpt_request_data_fix_prompt_assistant_2
    <<-PROMPT.strip
```ruby
# app.rb

require 'sinatra'
require 'json'
require 'net/http'

class CurrencyConverterApp < Sinatra::Base
  configure do
    set :show_exceptions, false
  end

  get '/convert' do
    from_currency = params['from']
    to_currency = params['to']
    amount = params['amount'].to_f

    exchange_rate_api_key = File.read(File.expand_path('~/.exchangerate_api_key')).strip
    exchange_rate_url = "https://v6.exchangerate-api.com/v6/\#{exchange_rate_api_key}/latest/USD"

    uri = URI(exchange_rate_url)
    response = Net::HTTP.get(uri)
    exchange_rates = JSON.parse(response)['conversion_rates']

    if exchange_rates.key?(from_currency) && exchange_rates.key?(to_currency) && amount.is_a?(Numeric) && amount > 0
      converted_amount = amount * (exchange_rates[to_currency] / exchange_rates[from_currency])
      { 'from': from_currency, 'to': to_currency, 'amount': amount, 'converted_amount': converted_amount }.to_json
    else
      status 400
      { 'error': 'Invalid currency' }.to_json
    end
  end
end
```

```ruby
# app_spec.rb

require 'rack/test'
require_relative './app'

describe CurrencyConverterApp do
  include Rack::Test::Methods

  def app
    CurrencyConverterApp
  end

  before do
    allow(File).to receive(:read).and_return("API_KEY")
    allow(Net::HTTP).to receive(:get).and_return('{"conversion_rates": {"USD": 1.0, "EUR": 0.85}}')
  end

  it "returns the converted amount when valid parameters are provided" do
    get '/convert', { from: 'USD', to: 'EUR', amount: 100 }

    expect(last_response.status).to eq(200)
    expect(last_response.body).to eq('{"from":"USD","to":"EUR","amount":100.0,"converted_amount":85.0}')
  end

  it "returns an error when invalid currency is provided" do
    get '/convert', { from: 'USD', to: 'GBP', amount: 100 }

    expect(last_response.status).to eq(400)
    expect(last_response.body).to eq('{"error":"Invalid currency"}')
  end

  it "returns an error when 'from' currency is missing" do
    get '/convert', { to: 'EUR', amount: 100 }

    expect(last_response.status).to eq(400)
    expect(last_response.body).to eq('{"error":"Invalid currency"}')
  end

  it "returns an error when 'to' currency is missing" do
    get '/convert', { from: 'USD', amount: 100 }

    expect(last_response.status).to eq(400)
    expect(last_response.body).to eq('{"error":"Invalid currency"}')
  end

  it "returns an error when 'amount' is missing" do
    get '/convert', { from: 'USD', to: 'EUR' }

    expect(last_response.status).to eq(400)
    expect(last_response.body).to eq('{"error":"Invalid currency"}')
  end

  it "returns an error when 'amount' is not a number" do
    get '/convert', { from: 'USD', to: 'EUR', amount: 'abc' }

    expect(last_response.status).to eq(400)
    expect(last_response.body).to eq('{"error":"Invalid currency"}')
  end
end
```
    PROMPT
  end


  # ------------


  def gpt_request_error_fix(prompt_app:, error_output:, run_idx:)
    prompt = {
      model: MODEL,
      messages: [{
        role: "system",
        content: gpt_request_data_fix_prompt_system
      }, {
        role: "user",
        content: gpt_request_data_fix_prompt_user_pre
      }, {
        role: "assistant",
        content: gpt_request_data_fix_prompt_assistant
      }, {
        role: "user",
        content: gpt_request_data_fix_prompt_user_pre_2
      }, {
        role: "assistant",
        content: gpt_request_data_fix_prompt_assistant_2
      }, {
        role: "user",
        content: gpt_request_error_fix_prompt_user(error_output: error_output, run_idx: run_idx)
      }],
    }

    # DEBUG
    #
    # puts "-" * 80
    # prompt[:messages].each do |message|
    #   puts "---"
    #   puts message[:role]
    #   puts "---"
    #   puts message[:content]
    #   puts
    # end

    puts "-" * 80

    prompt.merge! GPT_DEFAULT_PARAMS
    prompt.merge! GPT_DEFAULT_PARAMS_FIX
    prompt
  end

  def gpt_fix(prompt_app:, error_output:, run_idx:)
    request_data = gpt_request_error_fix prompt_app: prompt_app, error_output: error_output, run_idx: run_idx

    retries = 0
    output_files = nil
    begin
      output_files = gpt_request_fix request_data: request_data, run_idx: run_idx
    rescue GPTContextLengthExceededError => err
      puts "GPTContextLengthExceededError - gpt_fix"
      puts "need to terminate..."
      raise err
    rescue CodeParseError, FunctionCallNotPresentError, GPTResponseError => err
      retries += 1
      retry unless retries > GPT_MAX_RETRIES
      puts "err: #{err.class} - gpt_fix"
      raise MaxRetriesError
    end
    raise NoOutputError unless output_files

    output_files
  end

end