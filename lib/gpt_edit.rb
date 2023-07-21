module GPTEdit

  def gpt_request_data_edit_prompt_system
    <<-PROMPT.strip
You are a software development assistant that helps editing #{LANG} code files, you edit code according to the instructions.

---
Please follow these coding guidelines and instructions to produce high quality code:
#{PROMPT_CODE_INSTRUCTIONS}
---

You return only '```ruby' blocks, no extra comments, at every request return a '```ruby ... ```' block with the code you generated based on the user's request. You specify the name of the file in a comment at the top of the 'ruby' block like in the examples. Return only a 'ruby' block like in this example:

Existing code files you need to edit:
```ruby
# hello_world.rb

class HelloWorld
  HELLO_WORLD_TEXT = ""

  def initialize
    # ...
  end

  def announce
    HELLO_WORLD_TEXT
  end
end

if __FILE__ == $PROGRAM_NAME
  hello_world = HelloWorld.new
  puts hello_world.announce
end
```

```ruby
# hello_world_spec.rb

require_relative 'hello_world'

describe "HelloWorld" do
  describe "#announce" do
    it "returns the HELLO_WORLD_TEXT" do
      hello_world = HelloWorld.new
      expect(hello_world.announce).to eq(HelloWorld::HELLO_WORLD_TEXT)
    end
  end

  describe "#initialize" do
    it "initializes the HELLO_WORLD_TEXT" do
      hello_world = HelloWorld.new
      expect(hello_world.HELLO_WORLD_TEXT).to eq("")
    end
  end

  describe "#announce_upcase" do
    it "returns the HELLO_WORLD_TEXT in uppercase" do
      hello_world = HelloWorld.new
      expect(hello_world.announce_upcase).to eq(HelloWorld::HELLO_WORLD_TEXT.upcase)
    end
  end
end
```

Instructions:
- edit the file hello_world.rb
- add a new method called 'announce_upcase' that returns the HELLO_WORLD_TEXT in uppercase, write tests

Your Code Changes response:

```ruby
# hello_world.rb

class HelloWorld
  HELLO_WORLD_TEXT = ""

  def initialize
    # ...
  end

  def announce
    HELLO_WORLD_TEXT
  end

  def announce_upcase
    HELLO_WORLD_TEXT.upcase
  end
end

if __FILE__ == $PROGRAM_NAME
  hello_world = HelloWorld.new
  puts hello_world.announce
end
```

```ruby
# hello_world_spec.rb

require_relative 'hello_world'

describe "HelloWorld" do
  describe "#announce" do
    it "returns the HELLO_WORLD_TEXT" do
      hello_world = HelloWorld.new
      expect(hello_world.announce).to eq(HelloWorld::HELLO_WORLD_TEXT)
    end
  end

  describe "#initialize" do
    it "initializes the HELLO_WORLD_TEXT" do
      hello_world = HelloWorld.new
      expect(hello_world.HELLO_WORLD_TEXT).to eq("")
    end
  end

  describe "#announce_upcase" do
    it "returns the HELLO_WORLD_TEXT in uppercase" do
      hello_world = HelloWorld.new
      expect(hello_world.announce_upcase).to eq(HelloWorld::HELLO_WORLD_TEXT.upcase)
    end
  end
end
```

respond always in this format, specifying the file you want to edit as first line of ruby block in a comment (e.g. '# filename.rb'), do not use another format.
    PROMPT
  end

  def gpt_request_data_edit_prompt_user_pre
    <<-PROMPT.strip
Code to edit:

```ruby
# app.rb

require "sinatra"
require "sinatra/json"
require "json"


COMMENTS = [
  { id: 1, text: "Hi, this is a Hello World comment." },
  { id: 2, text: "This is another example comment." },
]

class App < Sinatra::Base

  get "/" do
    json status: "ok"
  end

  get "/comments" do
    COMMENTS.to_json
  end
end

if __FILE__ == $PROGRAM_NAME
  CommentsAPI.run!
end
```

```ruby
# app_spec.rb

require_relative 'app'
require 'rack/test'

def app
  CommentsAPI.new
end

describe "CommentsAPI" do
  include Rack::Test::Methods

  describe "GET /" do
    it "returns status ok" do
      get "/"
      expect(last_response.status).to eq(200)
      expect(JSON.parse(last_response.body)).to eq({"status" => "ok"})
    end
  end

  describe "GET /comments" do
    it "returns the comments" do
      get "/comments"
      expect(last_response.status).to eq(200)
      expect(JSON.parse(last_response.body)).to eq(COMMENTS)
    end
  end
end
```

Instructions:
- edit the file comments_api.rb and add a new POST /comments endpoint
- the endpoint should accept a JSON body with a 'text' key
- the endpoint should return a JSON body with the new comment
- edit the file app_spec.rb and add a new POST /comments endpoint test
- the test should send a POST request to /comments with a JSON body with a 'text' key
    PROMPT
  end

  def gpt_request_data_edit_prompt_assistant
    <<-PROMPT.strip

```ruby
# app.rb

require "sinatra"
require "sinatra/json"
require "json"

# application state (in-memory database)
# TODO: replace with redis

COMMENTS = [
  { id: 1, text: "Hi, this is a Hello World comment." },
  { id: 2, text: "This is another example comment." },
]

# api

class App < Sinatra::Base

  # root route

  get "/" do
    json status: "ok"
  end

  # comments routes (CR of CRUD is implemented)

  get "/comments" do
    comments = COMMENTS
    # NOTE: you can apply filtering here
    comments.to_json
  end

  post "/comments" do
    id = new_comment_id
    created_at = Time.now
    text = get_comment_text request: request
    comment = {
      id:         id,
      text:       text,
      created_at: created_at,
    }
    COMMENTS << comment
    comment.to_json
  end

  private

  def new_comment_id
    COMMENTS.size + 1
  end

  def get_comment_text(request:)
    comment_data = JSON.parse request.body.read
    text = comment_data.fetch "text"
    text
  end
end

if __FILE__ == $PROGRAM_NAME
  CommentsAPI.run!
end
```

```ruby
# app_spec.rb

require_relative 'app'
require 'rack/test'

def app
  CommentsAPI.new
end

describe "CommentsAPI" do
  include Rack::Test::Methods

  describe "GET /" do
    it "returns status ok" do
      get "/"
      puts "\ncalled: GET /\n - got response:\n\#{last_response.body[0..80]}\n---\n"

      expect(last_response.status).to eq 200
      expect(JSON.parse last_response.body).to eq({"status" => "ok"})
    end
  end

  describe "GET /comments" do
    it "returns the comments" do
      get "/comments"
      puts "\ncalled: GET /comments\n - got response:\n\#{last_response.body[0..80]}\n---\n"

      expect(last_response.status).to eq 200
      expect(JSON.parse last_response.body).to eq COMMENTS
    end
  end

  describe "POST /comments" do
    it "creates a new comment" do
      post "/comments", { text: "This is a new comment" }.to_json
      puts "\ncalled: POST /comments\n - got response:\n\#{last_response.body[0..80]}\n---\n"

      expect(last_response.status).to eq 200
      comment_id = COMMENTS.size + 1
      resp = last_response.body
      resp.delete "created_at"
      expect(JSON.parse(resp)).to eq({
        "id"         => comment_id,
        "text"       => "This is a new comment",
      })
    end
  end
end
```
    PROMPT
  end

  def gpt_request_data_edit(prompt:, file_name:, code_current:, prompt_app:, run_idx:)
    puts "prompt: #{prompt}"
    # puts "file_name: #{file_name}"
    # puts "code_current: #{code_current}"

    prompt = "No description was provided." if !prompt || prompt.empty?

    {
      model: MODEL,
      messages: [{
        role: "system",
        content: gpt_request_data_edit_prompt_system,
      }, {
        role: "user",
        content: gpt_request_data_edit_prompt_user_pre,
      }, {
        role: "assistant",
        content: gpt_request_data_edit_prompt_assistant,
      }, {
        role: "user",
        content: gpt_request_data_edit_prompt(prompt: prompt, file_name: file_name, code_current: code_current, prompt_app: prompt_app, run_idx: run_idx),
      }],
    }.merge GPT_DEFAULT_PARAMS
  end

end