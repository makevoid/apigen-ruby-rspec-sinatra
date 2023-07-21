LANG = "ruby"
# LANG = "js"
# LANG = "python"

def lang_framework_select
  case LANG
  when "ruby"
    "sinatra"
  when "js"
    "express"
  when "python"
    "fastapi"
  else
    raise "Invalid Lang - please specify either ruby, python or js"
  end
end

LANG_FRAMEWORK = lang_framework_select

PROMPT_SYSTEM_ASSISTANT_PERSONALITY = "You are an expert senior software developer. With your skills in writing high quality #{LANG} code you can produce very well coded applications. You can efficiently create edit and fix #{LANG} code files, run tests and fix any implementation or test errors."

PROMPT_SYSTEM_ASSISTANT_PERSONALITY_PLAN = "You are an expert senior software developer. With your skills in writing high quality #{LANG} code you can produce very well coded applications. You can plan applications in high details thinking step by step of all the actions needed to implement the application functionality, you can create files, edit files, write code, at the end of the planning we will run the tests to see if the application is working as expected. Create maximum 5 tests, do not create more than 5 tests."

PROMPT_PREPROMPT = "Create a software plan to write a #{LANG} #{LANG_FRAMEWORK} JSON REST API with this functionality:"

PROMPT_CODE_INSTRUCTIONS_RUBY = "Use rack/test and rspec to implement tests. Put require_relative './app' and 'rack/test` at the top of the test file, do not require spec_helper. The test file needs to be called app_spec.rb. Make sure that the code is well formatted and indented. Make sure you follow all the best practices. If you get `undefined method get/post/put/delete, the issue is that you are not requiring rack/test.` On every test `it` block, after executing the get/post/put/delete request, write this line: `puts \"\\nSPEC_NAME\\n\#{last_response.body[0..80]}\\n---\\n\", writing this line means you can see why the requests are erroring if they error, replace SPEC_NAME with the test name defined in the `it \"...\" do` block, make sure the newlines and the \#{...} are evaluated. Specs should contain code, not only comments. If you need to use a database use Sequel with sqlite3. Please ignore expecting `id` fields to match in your test expectations. Make sure to use the `create_or_edit_file`, `create_file`, `edit_file`, `fix_file` function to generate code. Make sure that you write sinatra apps with `show_exceptions` turned off. On `app_spec.rb` create maximum 5 tests, do not create more than 5 tests."

PROMPT_CODE_INSTRUCTIONS_PYTHON = "Use `fastapi.testclient` to implement tests. Use `fastapi.testclient` to implement tests. Make sure you are passing the right types. Make sure that the code is well formatted and indented. Make sure you follow all the best practices. Assuming that FUNCTION_NAME is the name of the current test function. On every test function, before the first `assert` call, write this code `print(f'FUNCTION_NAME {response.text()[:60]}')`, where FUNCTION_NAME is the name of the test function. Identify if the error is in the implementation or if it's in the test code. If the error is in the implementation, fix the implementation. If the error is in the test code, fix the test file. If you need to use a database too solve the problem use Pewee ORM with sqlite3 and make sure that the database code is used. Make sure to not connect tp the database twice. Make sure you run `create_tables()` if they're not present. Make sure to name your functions so they don't collide between files. When fixing errors, always reply with code contents, I don't need explanations. If you get `SyntaxError: unmatched '}'` it probably means that you need to delete a `}` at the end of the file. Note that paths that start with `~/` need to be expanded with `expanduser()`. Make sure to use the `create_or_edit_file`, `create_file`, `edit_file`, `fix_file` function to generate or edit code files. Try to avoid using async when not needed. Do not use `typing` or any typing checks. Do not use pydantic to validate endpoints. Do not use pytest.fixture, do not use fixtures on tests. Make sure you go through the app.py implementation as last step to see if you left any comments that are not implemented and implement them. When testing a third paty API such as a weather or movies api be sure to use mocks using `unittest.mock` `patch`. When testing endpoints don't use zero as id in the routes (e.g. use `/notes/1`, not `/notes/0`)."

PROMPT_PLAN_TEST_PYTHON = "Use soft tabs with 2 spaces. Implement the main JSON REST API app file in `app.py`. Implement a test file to test the app, save this file in test_app.py. Make sure you follow all the best practices. Make sure to implement all the functionality described:".strip

PROMPT_PLAN_TEST_RUBY = "Implement the main JSON REST API app file in `app.rb`. Implement a test file to test the app, save this file in app_spec.rb. Make sure you follow all the best practices. Make sure that in the plan you write the API spec they need to adhere (GET/POST/PUT/DELETE method and parameters). Make sure to implement all the functionality described:".strip


def prompt_plan_test
  case LANG
  when "ruby"
    PROMPT_PLAN_TEST_RUBY
  when "python"
    PROMPT_PLAN_TEST_PYTHON
  when "js"
    PROMPT_PLAN_TEST_JS
  else
    raise "Invalid Lang - please specify either ruby, python or js"
  end
end

def prompt_code_instructions
  case LANG
  when "ruby"
    PROMPT_CODE_INSTRUCTIONS_RUBY
  when "python"
    PROMPT_CODE_INSTRUCTIONS_PYTHON
  when "js"
    PROMPT_CODE_INSTRUCTIONS_JS
  else
    raise "Invalid Lang - please specify either ruby, python or js"
  end
end

PROMPT_CODE_INSTRUCTIONS = prompt_code_instructions
PROMPT_PLAN_TEST         = prompt_plan_test

module GPTPrompts
  def gpt_request_error_fix_prompt_user(error_output:, run_idx:)
    code_to_edit = prompt_existing_files run_idx: run_idx
    <<-PROMPT.strip
Code to edit to fix the issue:
#{code_to_edit}

Error output from running the tests:
-----
#{error_output}
-----
    PROMPT
  end

  def prompt_existing_file(file_name:, file_ext:, file_contents:)
    <<-PROMPT.strip
```ruby
# #{file_name}

#{file_contents}
```
    PROMPT
  end

  # TODO: extract - move in a cloc module
  def cloc(run_idx:)
    # cloc_path = "/Users/makevoid/.rvm/gems/ruby-3.2.2/bin/cloc"
    cloc_path = "cloc"
    dir_path = "./tmp_#{run_idx}"
    cloc_cmd = "#{cloc_path} #{dir_path} --quiet --json | jq .#{LANG.capitalize}.code"
    cloc_output = `#{cloc_cmd}`
    # puts "Cloc:"
    # puts cloc_output
    cloc_output.strip!
    cloc_output = cloc_output.to_i
    cloc_output
  end

  # TODO: extract
  def prompt_existing_files(run_idx:)
    tmp_dir = "./tmp_#{run_idx}"
    prompt_code_files = []
    Dir.glob("#{tmp_dir}/*").map do |file_name|
      next if file_name.include? "#{tmp_dir}/.keep"
      next if File.directory? file_name
      file_ext = File.extname file_name
      file_ext = file_ext[1..-1]
      file_contents = File.read file_name
      file_contents = file_contents.encode "UTF-8", invalid: :replace, replace: " "
      file_contents.strip!
      file_contents = "#{file_contents}\n"
      file_basename = File.basename file_name
      prompt_code_files << prompt_existing_file(file_name: file_basename, file_ext: file_ext, file_contents: file_contents)
    end
    contents = prompt_code_files.join "\n\n"
    locs_count = cloc run_idx: run_idx

    # puts "-" * 80
    # puts "Code size: #{contents.size} chars"
    # puts "LoCs: #{locs_count} LoCs"

    # TODO: increase this to ~4200 and add a check for the size of the context, not via char estimation - GPTMaxTokenReached4K
    raise GPTMaxTokenReached4K if contents.size > 4000 if MODEL_SEL == "gpt-3.5-turbo"
    raise GPTMaxTokenReached16K if contents.size > 16200

    contents
  end

  # todo - code current is unused
  def gpt_request_data_edit_prompt(prompt:, file_name:, code_current:, prompt_app:, run_idx:)
    code_to_edit = prompt_existing_files run_idx: run_idx
    <<-PROMPT.strip
Code to edit:
#{code_to_edit}

Instructions:
#{prompt}

Respond only with '```ruby' blocks containing the edited code. Do not provide any text outside the code blocks.
    PROMPT
  end

  def gpt_request_data_plan_prompt(prompt:)
    <<-PROMPT.gsub(/^\s{6}/, "").strip
      #{PROMPT_SYSTEM_ASSISTANT_PERSONALITY_PLAN}

      Please write detailed code instructions from a text prompt, the instructions should specify your actions required to build a complete app described in the prompt, the code instructions can be of type 'code_new' and 'code_edit'.

      Instructions of type 'code_new' are interpreted as #{LANG} code that will be written to a new file.
      Instructions of type 'code_edit' are interpreted as #{LANG} code that will take the contents of an existing #{LANG} file, read it, get all comments present in the file and translate each code comment in well written implementation code, output the final code that will overwrite the file adding the new fixes/functionality.

      Here is a description of the functionality that you need to understand and break down generating multiple steps of application code changes made of 'code_new' and 'code_edit' operations.

      Here is a description explaining the application functionality:
      #{prompt}

      Please think carefully and generate the best app code changes you can to solve the task you were prompted, they need to be complete, descriptive and use the best #{LANG} libraries to solve each task. Keep the maximum number of total code_new and code_edit to 3 operations. Please have a maximum of 1 edit per file. Do not include snippets of code, only provide descriptions of implementation guidance operations. Implement a test file to test the app using pytest, save this file in test_app.py. In the plan, when you are defining the prompt for creating or editing the text file, please specify guidance for the assertions that will need to be implemented to effectively test the functionality.

      Plan step by step a coding session.

      Your steps should always be:
      - new file app.rb
      - new file app_spec.rb - add first spec
      - edit app_spec.rb - add all remaining specs

      Describe extensively what you will code in each step.
    PROMPT
  end

  def gpt_request_data_new_prompt(prompt:, prompt_app:, run_idx:, file_name:)
    <<-PROMPT.strip
I have an application that needs to conform to this description:
#{prompt_app}
---
#{PROMPT_SYSTEM_ASSISTANT_PERSONALITY}
---
Please write a #{LANG} file `#{file_name}` that implements the functionality described by this text description of the code:
#{prompt}
---
Please follow these coding guidelines and instructions to produce high quality code:
#{PROMPT_CODE_INSTRUCTIONS}
---
I have existing files that contain #{LANG} code, the files are the following:
-----
#{prompt_existing_files run_idx: run_idx}
-----
Make sure that if you add comments to the code to specify new implementation details that you will want to write in the future to improve the code. Make sure that all the functions are implemented, the comments should only describe new fuctionality. The code should be complete and it should work at first run.
    PROMPT
  end

end
