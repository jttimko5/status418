from pygooglenews import GoogleNews
import json
import datetime
import time

def get_news(keywords, dates):
    gn = GoogleNews(lang = 'en', country = 'US')
    query = 'top stories BBC WSJ NYT AP BLOOMBERG -"COVID-19: Top news stories about the pandemic on"'
    # date is in YYYY-MM-DD format
    for date in dates:
        date_ints = date.split('-')
        for x in date_ints:
            print(x)
        first = datetime.date(int(date_ints[0]), int(date_ints[1]), int(date_ints[2]))
        second = datetime.date(int(date_ints[0]), int(date_ints[1]), int(date_ints[2]) + 1)
        print(str(first) + ' ' + str(second))
        start = first.strftime('%Y-%m-%d')
        end = second.strftime('%Y-%m-%d')
        result = gn.search(query, helper=True, from_=start, to_=end)
        # topics = gn.topic_headlines('BUSINESS', from_=date.strftime('%Y-%m-%d'), to_=date2.strftime('%Y-%m-%d'))
        entries = result["entries"]
        count = 0
        for entry in entries:
            count = count + 1
            print(str(count) + ". " + entry["title"] + entry["published"])

if __name__ == '__main__':
    keywords = ['big house', 'dog']
    dates = ['2022-02-14', '2022-09-26']
    get_news(keywords=keywords, dates=dates)