from pygooglenews import GoogleNews
import json
import datetime
import time

def get_news(keywords[], dates[]):
    gn = GoogleNews(lang = 'en', country = 'US')
    query = ''
    # date is in YYYY-MM-DD format
    date = datetime.date(2022,2,14)
    date2 = datetime.date(2022,2,15)
    print(date.strftime('%Y-%m-%d'))
    result = gn.search(query, helper=True, from_=date.strftime('%Y-%m-%d'), to_=date2.strftime('%Y-%m-%d'))
    # topics = gn.topic_headlines('BUSINESS', from_=date.strftime('%Y-%m-%d'), to_=date2.strftime('%Y-%m-%d'))
    entries = result["entries"]
    count = 0
    for entry in entries:
    count = count + 1
    print(
        str(count) + ". " + entry["title"] + entry["published"]
    )
    time.sleep(0.1)