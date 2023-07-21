module GPTPlan

  def gpt_request_data_plan(prompt:)
    req_params = {
      model: MODEL_PLAN,
      messages: [{
        role: "user",
        content: gpt_request_data_plan_prompt(prompt: prompt)
      }],
      functions: [{
        name: "return_app_code_changes",
        description: "Return app code changes for each 'code_new' and 'code_edit' step. Make sure that if you edit a file, the file name is tne same. E.g. if in the prompt you write 'Implement the test file test_app.py', :file_name needs to match (test_app.py). ",
        parameters: gpt_request_plan_function_params,
      }],
    }
    req_params.merge GPT_DEFAULT_PARAMS
    req_params.merge GPT_DEFAULT_PARAMS_PLAN
    req_params
  end

  def gpt_request_function_params_plan_items
    {
      type: "object",
      properties: {
        file_name: {
          type: "string",
          description: "Name of the file.",
        },
        prompt: {
          type: "string",
          description: "The description explaining the structure of the code to be implemented, you will need to use this description as instructions to generate the code. Keep this as valid json, use \\n for new lines.",
        },
        code_step_type: {
          type: "string",
          description: "Type of operation. Either 'code_new' or 'code_edit'",
        },
      },
      required: %w(file_name prompt code_step_type),
    }
  end

  def gpt_request_plan_function_params
    {
      type: "object",
      properties: {
        app_code_changes: {
          type: "array",
          description: "List of files to be coded or edited - keep this array of maximum 5 items.",
          items: gpt_request_function_params_plan_items,
        },
      },
      required: %w(app_code_changes),
    }
  end

end