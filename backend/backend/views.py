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

    return jsonify(get_news(dates)), 200

# if __name__ == '__main__':
#     app.run(debug=True, host='0.0.0.0', port=3000)
