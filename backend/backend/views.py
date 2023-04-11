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

    results = extract_keywords(data['text'])
    results['news'] = get_news(results['dates'])

    return jsonify(results), 200


# if __name__ == '__main__':
#     app.run(debug=True, host='0.0.0.0', port=3000)
