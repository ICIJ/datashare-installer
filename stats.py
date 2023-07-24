import json
import csv
from ctypes import Array
from urllib.request import urlopen

TYPES_MAP = {
        'application/vnd.debian.binary-package': 'linux',
        'application/vnd.microsoft.portable-executable': 'windows',
        'application/x-xar': 'mac',
        'application/x-sh': 'docker',
        'application/gzip': 'tarball'
        }
FIELD_NAMES = ['release', 'date'] + list(TYPES_MAP.values())


def get_json():
    releases = []
    current_page = None
    page_nb = 0
    while current_page is None or len(current_page) > 0:
        with urlopen(f'https://api.github.com/repos/ICIJ/datashare-installer/releases?per_page=100&page={page_nb}') as f:
            current_page = json.load(f)
            releases += current_page
            page_nb += 1
    return releases


def write_csv(github_json):
    with open('ds_stats.csv', 'w', newline='') as csvfile:
        writer = csv.DictWriter(csvfile, fieldnames=FIELD_NAMES)
        writer.writeheader() 
        for release in github_json:
            line = dict()
            line['date'] = release['published_at']
            line['release'] = release['name']
            for asset in release['assets']:
                line[TYPES_MAP[asset['content_type']]] = asset['download_count']
            writer.writerow(line)


if __name__ == '__main__':
    write_csv(get_json())