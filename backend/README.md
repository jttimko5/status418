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

Install using poetry: `poetry install`

To run:
- Activate python shell: `poetry shell`
- Run flask: `flask --app backend run --port=8000`
- Run flask in debug mode: `flask --app backend run --port=8000 --debug`
    