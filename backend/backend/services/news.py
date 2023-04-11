import logging
import os
import pprint

from pygooglenews import GoogleNews
from datetime import date, timedelta


def get_news(dates: list[str]) -> list[dict]:
    """
    Grab top news stories from the dates given.
    :param dates: List of dates in ISO format.
    :return: List of articles with keys 'title', 'source', and 'link'.
    """
    if not date:
        return []

    news_results = []

    gn = GoogleNews(lang='en', country='US')
    query = 'top stories'

    for start_date in dates[:5]:
        end_date = str(date.fromisoformat(start_date) + timedelta(days=1))
        query_result = gn.search(query, helper=True,
                                 from_=start_date, to_=end_date,
                                 scraping_bee=os.getenv('SCRAPING_BEE_API'))

        logging.debug('Query result for %s: %s' % (start_date, query_result))

        for entry in query_result["entries"][:5]:
            news_results.append({
                'title': entry['title'],
                'source': entry['source']['title'],
                'link': entry['link']
            })

    logging.info('Found articles: %s' % news_results)

    return news_results


def test_get_news():
    dates = ['2017-02-14']
    results = get_news(dates=dates)
    pprint.pprint(results, depth=2)


if __name__ == '__main__':
    test_get_news()
