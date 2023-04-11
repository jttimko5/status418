import logging
import os
from logging.config import dictConfig

from flask import Flask

# Create and configure logger
# logging.basicConfig(filename="newfile.log",
#                     encoding='utf-8',
#                     level=logging.DEBUG,
#                     format='[%(asctime)s] %(levelname)s in %(module)s: %(message)s')


class FilterModule(logging.Filter):
    def __init__(self, module_name=None):
        self.module_name = module_name

    def filter(self, record):
        if self.module_name is None:
            return True
        else:
            # disallow all logs coming from module_name
            return record.module != self.module_name

dictConfig({
    'version': 1,
    'formatters': {
        'default': {
            'format': '[%(asctime)s] %(name)s - %(levelname)s in %(module)s: %(message)s',
        }},
    'filters': {
        'filterServices': {
            '()': FilterModule,
            'module_name': 'services',
        },
        'filterExtractor': {
            '()': FilterModule,
            'module_name': 'extractor',
        },
        'filter_internal': {
            '()': FilterModule,
            'module_name': '_internal',
        }
    },
    'handlers': {
        'wsgi': {
            'class': 'logging.StreamHandler',
            'stream': 'ext://flask.logging.wsgi_errors_stream',
            'formatter': 'default',
            'filters': ['filterServices', 'filterExtractor']
        },
        'file': {
            'class': 'logging.FileHandler',
            'filename': 'backend.log',
            'encoding': 'utf-8',
            'formatter': 'default',
            'filters': ['filter_internal']
        },
        'everything_file': {
            'class': 'logging.FileHandler',
            'filename': 'everything.log',
            'encoding': 'utf-8',
            'formatter': 'default',
        }
    },
    'root': {
        'level': 'INFO',
        'handlers': ['wsgi', 'file', 'everything_file']
    }
})


def create_app(test_config=None):
    # create and configure the app
    app = Flask(__name__, instance_relative_config=True)
    app.config.from_mapping(
        SECRET_KEY='dev',
        # DATABASE=os.path.join(app.instance_path, 'flaskr.sqlite'),
    )

    if test_config is None:
        # load the instance config, if it exists, when not testing
        app.config.from_pyfile('config.py', silent=True)
    else:
        # load the test config if passed in
        app.config.from_mapping(test_config)

    # ensure the instance folder exists
    try:
        os.makedirs(app.instance_path)
    except OSError:
        pass

    # register blueprints for routes
    from . import views
    app.register_blueprint(views.bp)

    return app
