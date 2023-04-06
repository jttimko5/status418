import functools
import logging

from flask import (
    Blueprint, jsonify, request
)

from .extractor.extractor import extract_keywords

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
            'error': 'Failed to decode JSON object'
        }), 400

    if "text" not in data:
        return jsonify({
            'status': 400,
            'error': 'Missing field \'text\''
        }), 400

    return jsonify(extract_keywords(data['text'])), 200


# if __name__ == '__main__':
#     app.run(debug=True, host='0.0.0.0', port=3000)
