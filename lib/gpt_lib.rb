module GPTLib

  def parse_write_resp_files(resp:, run_idx:)
    resp = resp.split "\n"
    resp = resp[1..-2]
    resp = resp.join "\n"
    output_code = resp

    # puts "=" * 80
    # puts "output_code:"
    # puts "=" * 80
    # puts output_code
    # puts "=" * 80

    output_code = output_code.split "\n```ruby\n"

    output_code.map! { |code| code.strip }
    output_code.reject! { |code| code.empty? }
    output_code.compact!
    files = output_code

    files_output = []

    files.each do |file|

      puts "=" * 80
      puts "file:"
      puts "=" * 80
      puts file
      puts "=" * 80

      # file = file.gsub /^```/, ""
      file = file.split "```\n\n"
      file = file[0]
      file = file.split "```"
      file = file[0]

      file.strip!

      lines = file.split "\n"
      file_name = lines[0]
      file_name = file_name.gsub /^#\s/, ""

      file_name_valid = File.basename(file_name) == file_name

      unless file_name_valid
        puts "file_name: #{file_name}"
        raise "FileNameNotValidError"
      end

      lines = lines[1..-1]
      code = lines.join "\n"
      code = code.strip

      puts "-" * 80
      puts "file_name: #{file_name}"
      puts "-" * 80
      puts code
      puts "-" * 80

      write_code file_name: file_name, code: code, run_idx: run_idx
      puts "file written: #{file_name}"

      files_output << {
        file_name: file_name,
        output_code: code,
      }
    end

    files_output
  end

  def gpt_request_data_new_prompt_system
    <<-PROMPT.strip
you write code, return only ```ruby blocks, at every request return a ```ruby block with the code you generated based on the user's request, return only a ```ruby block like in this example:

user prompt, description of the code you will generate:
hello world

result - your response:
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
respond always in this format, do not use another format.
    PROMPT
  end

  def gpt_request_data_new_prompt_user_pre
    <<-PROMPT.strip
write GET hello world in ruby roda
    PROMPT
  end

  def gpt_request_data_new_prompt_assistant
    <<-PROMPT.strip
```ruby
# hello_world.rb

require 'roda'

class HelloWorldApp < Roda
  route do |r|
    r.is 'hello' do
      'Hello, World!'
    end
  end
end
```
    PROMPT
  end

  def gpt_request_headers
    {
      "Content-Type"  => "application/json",
      "Authorization" => "Bearer #{OPENAI_API_KEY}",
    }
  end

  def gpt_request_function_params
    {
      type: "object",
      properties: {
        file_name: {
          type: "string",
          description: "Name of the file.",
        },
        output_code: {
          type: "string",
          description: "The #{LANG} code to be returned",
        }
      },
      required: %w(file_name output_code),
    }
  end

  def gpt_request_data_new(prompt:, prompt_app:, run_idx:, file_name:)
    {
      model: MODEL,
      messages: [{
        role: "system",
        content: gpt_request_data_new_prompt_system#(prompt: prompt, prompt_app: prompt_app, run_idx: run_idx)
      }, {
        role: "user",
        content: gpt_request_data_new_prompt_user_pre#(prompt: prompt, prompt_app: prompt_app, run_idx: run_idx)
      }, {
        role: "assistant",
        content: gpt_request_data_new_prompt_assistant#(prompt: prompt, prompt_app: prompt_app, run_idx: run_idx)
      }, {
        role: "user",
        content: gpt_request_data_new_prompt(prompt: prompt, prompt_app: prompt_app, run_idx: run_idx, file_name: file_name)
      }],
      # functions: [{
      #   name: "create_or_edit_file",
      #   description: "Create or Edit a file, write into the file the #{LANG} code based on the information you have.",
      #   parameters: gpt_request_function_params,
      # }],
    }.merge(GPT_DEFAULT_PARAMS)
  end

  def gpt_request(request_data:, run_idx:, file_name:)
    if DEBUG
      puts "DEBUG:"
      puts "-" * 80
      puts request_data.to_yaml.colorize :cyan
      puts "-" * 80
    end

    response = Excon.post(
      GPT_CHAT_ENDPOINT,
      body:     request_data.to_json,
      headers:  gpt_request_headers,
    )

    resp = response.body

    begin
      resp = JSON.parse resp
    rescue JSON::ParserError => err
      raise ResponseParseError
    end

    if resp["error"]
      puts "OpenAI API response error:"
      puts resp["error"]
      raise GPTResponseError
    end

    resp = resp.fetch("choices").fetch(0).fetch "message"
    resp = resp.fetch "content"

    # without functions
    files = parse_write_resp_files resp: resp, run_idx: run_idx

    files
  end


  def gpt_request_fix(request_data:, run_idx:)
    if DEBUG
      puts "DEBUG:"
      puts "-" * 80
      puts request_data.to_yaml.colorize :cyan
      puts "-" * 80
    end

    response = Excon.post(
      GPT_CHAT_ENDPOINT,
      body:     request_data.to_json,
      headers:  gpt_request_headers,
    )

    resp = response.body

    begin
      resp = JSON.parse resp
    rescue JSON::ParserError => err
      raise ResponseParseError
    end

    if resp["error"]
      puts "OpenAI API response error:"
      puts resp["error"]

      err_code = resp["error"]["code"]
      if err_code == "context_length_exceeded"
        raise GPTContextLengthExceededError
      end

      raise GPTResponseError
    end

    resp = resp.fetch("choices").fetch(0).fetch "message"
    resp = resp.fetch "content"

    # without functions
    files = parse_write_resp_files resp: resp, run_idx: run_idx

    files
  end

  def gpt_request_array(request_data:)
    response = Excon.post(
      GPT_CHAT_ENDPOINT,
      body: request_data.to_json,
      headers: gpt_request_headers
    )

    resp = response.body
    resp = JSON.parse resp

    if resp["error"]
      puts "Error: #{resp["error"]}"
      exit
    end

    resp = resp.dig "choices", 0, "message", "function_call", "arguments"

    resp = JSON.parse resp
    app_code_changes = resp.fetch "app_code_changes"

    app_code_changes.each do |app_code_change|
      app_code_change.transform_keys! &:to_sym
    end
    app_code_changes
  end

  def gpt_new(prompt:, prompt_app:, run_idx:, file_name:)
    request_data = gpt_request_data_new prompt: prompt, prompt_app: prompt_app, run_idx: run_idx, file_name: file_name

    retries = 0
    output_files = nil
    begin
      output_files = gpt_request request_data: request_data, run_idx: run_idx, file_name: file_name
    rescue CodeParseError, FunctionCallNotPresentError, GPTResponseError => err
      retries += 1
      retry unless retries > GPT_MAX_RETRIES
      puts "err: #{err.class} - gpt_new"
      raise MaxRetriesError
    end
    raise NoOutputError unless output_files

    output_files
  end

  def gpt_edit(prompt:, file_name:, code_current: nil, prompt_app:, run_idx:)
    request_data = gpt_request_data_edit prompt: prompt, file_name: file_name, code_current: code_current, prompt_app: prompt_app, run_idx: run_idx

    retries = 0
    output_files = nil
    begin
      output_files = gpt_request request_data: request_data, run_idx: run_idx, file_name: file_name
    rescue CodeParseError, FunctionCallNotPresentError, GPTResponseError => err
      retries += 1
      retry unless retries > GPT_MAX_RETRIES
      puts "err: #{err.class} - gpt_edit"
      raise MaxRetriesError
    end
    raise NoOutputError unless output_files

    output_files
  end

  def gpt_plan(prompt:)
    request_data = gpt_request_data_plan prompt: prompt

    gpt_request_array request_data: request_data
  end

end
