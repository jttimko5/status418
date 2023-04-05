from _datetime import datetime

from keybert import KeyBERT
import datefinder
import pprint


def extract_everything(text: str) -> dict:
    return {
        'dates': extract_dates(text),
        'keywords': extract_keywords(text),
    }


def extract_keywords(text: str) -> list:
    """
    Extract the keywords from a string of text, separating into two categories: dates and everything else.

    :param text: string
    :return: a dictionary with key 'dates' and 'keywords
    """
    kw_model = KeyBERT()
    keywords = kw_model.extract_keywords(text,
                                         keyphrase_ngram_range=(1, 1),
                                         use_mmr=True,
                                         diversity=1)

    return [key_score[0] for key_score in keywords]


def extract_dates(text: str) -> list[str]:
    """
    Find occurrences of dates in text and get them in iso string format.

    :param text: A string that may contain dates in various formats.
    :return: List of dates found in iso format.
    """
    # if there are missing components in a date, assume today's components
    base_date = datetime.now().replace(hour=0, minute=0, second=0, microsecond=0)

    # ambiguous dates are assumed to be month-day-year
    dates_first_pass = datefinder.find_dates(text, first='month', strict=False,
                                             base_date=base_date)

    # set to remove duplicate dates
    all_dates = {d.isoformat() for d in dates_first_pass}

    # in rare cases, dates are missed because of bugs, e.g., date followed by "today"
    # split the text and try to in each substring
    dates_second_pass = []
    for s in text.split():
        dates_second_pass.append(datefinder.find_dates(s, first='month', strict=False,
                                                       base_date=base_date))
    for d in dates_second_pass:
        # there can be at most one date, since substrings were split on whitespace
        d = next(d, None)
        if d:
            all_dates.add(d.isoformat())

    return sorted(list(all_dates))


def test_extract_keywords():
    text = """
Journal Entry 2/14/22
Today is Valentines Day, I went on 
a walk with my dog to the Big House.
Later today I'm Going to go to Starbucks
with some friends. I really want to watch
a movie later, maybe "Crazy, Stupid, Love".
Yesterday I found a great song called "You get
what you give."
"""

    response = extract_keywords(text)

    pp = pprint.PrettyPrinter(depth=4)
    pp.pprint(response)


def test_extract_dates():
    text = """
Journal Entry 2/14/2022
Today is Valentines Day, I went on
a walk with my dog to the Big House. also, Feb 14, 2023
Later today I'm Going to go to Starbucks
with some friends. I really want to watch
a movie later, maybe "Crazy, Stupid, Love".
Yesterday I found a great song called "You get
what you give." 2/2/2022 and 2/Jan/2000 and October 25 and 10/25/2023
"""

    text = text.replace('\n', ' ')

    print(text)

    response = extract_dates(text)

    print(response)


def test_extracteverything():
    text = """
Journal Entry 2/14/2022
Today is Valentines Day, I went on
a walk with my dog to the Big House. also, Feb 14, 2023
Later today I'm Going to go to Starbucks
with some friends. I really want to watch
a movie later, maybe "Crazy, Stupid, Love".
Yesterday I found a great song called "You get
what you give." 2/2/2022 and 2/Jan/2000 and October 25 and 10/25/2023
"""

    text = text.replace('\n', ' ')
    print(text)
    response = extract_everything(text)
    pprint.pprint(response, depth=2, compact=False)


if __name__ == '__main__':
    test_extracteverything()
    # test_extract_keywords()
    # test_extract_dates()
