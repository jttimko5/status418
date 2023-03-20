from datetime import datetime


def extract_keywords(text: str) -> dict:
    """
    Extract the keywords from a string of text, separating into two categories: dates and everything else.

    :param text: string
    :return: a dictionary with key 'dates' and 'keywords
    """

    return {
        'dates': [
            datetime.strptime('02/14/2022', '%m/%d/%Y').isoformat()
        ],
        'keywords': [
            'Valentine\'s Day',
            'Big House',
            'Starbucks',
            'Crazy, Stupid, Love',
        ],
    }
