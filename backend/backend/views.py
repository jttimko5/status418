import datetime

from flask import (
    Blueprint, jsonify, request
)

from .services import get_news, extract_keywords

bp = Blueprint('auth', __name__, url_prefix='/')


@bp.route('/')
def hello_world():  # put application's code here
    return 'Hello World!'


@bp.route('/keywords', methods=['POST'])
def keywords():
    data = request.get_json(silent=True)
    if not data:
        return jsonify({
            'status': 400,
            'error': 'Failed to decode JSON object.'
        }), 400

    if "text" not in data:
        return jsonify({
            'status': 400,
            'error': 'Missing field \'text\'.'
        }), 400
    if not data['text']:
        return jsonify({
            'status': 400,
            'error': 'Field \'text\' is empty.'
        }), 400
    if not isinstance(data['text'], str):
        return jsonify({
            'status': 400,
            'error': 'Field \'text\', expected String got %s.' % type(data['text'])
        }), 400

    return jsonify(
        {
            "dates": [
                "2018-04-09",
                "2015-04-11"
            ],
            "keywords": [
                "dog",
                "man",
                "ChatGPT"
            ]
        }, 200
    )

    return jsonify(extract_keywords(data['text'])), 200


@bp.route('/news', methods=['GET', 'POST'])
def news():
    if request.method == 'POST':
        data = request.get_json(silent=True)
        if not data:
            return jsonify({
                'status': 400,
                'error': 'Failed to decode JSON object.'
            }), 400
        if 'dates' not in data:
            return jsonify({
                'status': 400,
                'error': 'Missing field \'text\'.'
            }), 400
        if isinstance(data['dates'], list):
            dates = data['dates']
        elif isinstance(data['dates'], str):
            dates = [data['dates']]
        else:
            return jsonify({
                'status': 400,
                'error': 'Field \'text\' in unknown format.'
            }), 400
    else:
        dates = [request.args.get('date')]

    for d in dates:
        try:
            datetime.date.fromisoformat(d)
        except ValueError:
            return jsonify({
                'status': 400,
                'error': 'Date or dates not in ISO format.'
            }), 400

    # result = get_news(dates)
    result = [{
        'link': 'https://news.google.com/rss/articles/CBMiQmh0dHBzOi8vdGltZS5jb20vNDY2OTYxNC92YWxlbnRpbmVzLWRheS1raW0tam9uZy11bi1taWNoYWVsLWZseW5uL9IBS2h0dHBzOi8vdGltZS5jb20vNDY2OTYxNC92YWxlbnRpbmVzLWRheS1raW0tam9uZy11bi1taWNoYWVsLWZseW5uLz9hbXA9dHJ1ZQ?oc=5',
        'source': 'TIME',
        'title': "The Morning Brief: Michael Flynn's Resignation, Kim Jong Un's "
                 "Half-Brother's Death and Valentine’s Day - TIME"},
        {
            'link': 'https://news.google.com/rss/articles/CBMiS2h0dHBzOi8vd3d3LnBvbGl0aWNvLmNvbS9zdG9yeS8yMDE3LzAyL2Zha2UtbmV3cy1tb3ZpZS1jdXJlLXdlbGxuZXNzLTIzNTAxN9IBVWh0dHBzOi8vd3d3LnBvbGl0aWNvLmNvbS9zdG9yeS8yMDE3LzAyL2Zha2UtbmV3cy1tb3ZpZS1jdXJlLXdlbGxuZXNzLTIzNTAxNz9fYW1wPXRydWU?oc=5',
            'source': 'POLITICO',
            'title': 'Fake news stories promote a movie about a fake spa - POLITICO'},
        {
            'link': 'https://news.google.com/rss/articles/CBMiXGh0dHBzOi8vbmV3cy53dHR3LmNvbS8yMDE3LzAyLzE0L2J1enpmZWVkLWVkaXRvci1ob3ctbGl2ZS13b3JsZC1taXNpbmZvcm1hdGlvbi1hbmQtZmFrZS1uZXdz0gEA?oc=5',
            'source': 'WTTW News',
            'title': 'BuzzFeed Editor: How to Live in a World of Misinformation and Fake '
                     '... - WTTW News'},
        {
            'link': 'https://news.google.com/rss/articles/CBMiVGh0dHBzOi8vbmV3cy5jb3JuZWxsLmVkdS9zdG9yaWVzLzIwMTcvMDIvc2NobG9tLWVsZWN0ZWQtbmF0aW9uYWwtYWNhZGVteS1lbmdpbmVlcmluZ9IBAA?oc=5',
            'source': 'Cornell Chronicle',
            'title': 'Schlom elected to National Academy of Engineering | Cornell ... - '
                     'Cornell Chronicle'},
        {
            'link': 'https://news.google.com/rss/articles/CBMiNWh0dHBzOi8vd3d3LmJiYy5jb20vbmV3cy9zY2llbmNlLWVudmlyb25tZW50LTM4OTcxNTA00gE5aHR0cHM6Ly93d3cuYmJjLmNvbS9uZXdzL3NjaWVuY2UtZW52aXJvbm1lbnQtMzg5NzE1MDQuYW1w?oc=5',
            'source': 'BBC',
            'title': 'First live birth evidence in dinosaur relative - BBC'}]

    return jsonify(result), 200

# if __name__ == '__main__':
#     app.run(debug=True, host='0.0.0.0', port=3000)
