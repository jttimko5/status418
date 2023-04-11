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
    Returns: {
                "dates": [String], 
                "keywords": [String], 
                "news": [Object {"title": String, "source": String, "link": String}]
              }
    Extracts the keywords and dates from the passed in text 
    and gets top news arcticles from the dates found.

### Info

Install
- Use poetry: `poetry install`
- There is an extra dependency that needs to be installed with pip
  - within python venv, `pip install --no-deps pygooglenews`

Make sure you have your API keys set as an env variables:
- In bash/zsh profile add: 
  - `export OPENAI_API_KEY="sk-..."`
  - `export SCRAPING_BEE_API="..."`
- Or in an .env file (needed for gunicorn, add path to this file during setup)
  - `OPENAI_API_KEY="sk-..."`
  - `SCRAPING_BEE_API="..."`

To run locally:
- Activate python shell: `poetry shell`
- Run flask: `flask --app backend run --port=8000`
- Or run flask in debug mode: `flask --app backend run --port=8000 --debug`
- Or without activating the shell: `poetry run flask --app backend run --port=8000`
    