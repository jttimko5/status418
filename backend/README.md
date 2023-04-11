## Backend Rest API for SmartNote

### Routes

    Route: /
    Method: GET
    Returns: "Hello World"
    Simply for testing purposes.
<!-- -->
    Route: /keywords
    Method: POST
    Params: {"text": String}
    Returns: {"dates": [String], "keywords": [String]}
    Extracts the keywords and dates from the passed in text.

### Info

Install
- Use poetry: `poetry install`
- There is an extra dependency that needs to be installed with pip
  - within env, `pip install pygooglenews`

Make sure you have your OpenAI API key set as an env variable:
- In bash/zsh profile, add `export OPENAI_API_KEY="sk-..."`

To run:
- Activate python shell: `poetry shell`
- Run flask: `flask --app backend run --port=8000`
- Or run flask in debug mode: `flask --app backend run --port=8000 --debug`
- Or without activating the shell: `poetry run flask --app backend run --port=8000`
    