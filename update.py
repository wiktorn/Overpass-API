import html.parser
import urllib.request
import json

url = "http://dev.overpass-api.de/releases/"
skip_prefixes = (
    '0.6', 'eta', '0.7.1', '0.7.2', '0.7.3', '0.7.4', '0.7.50', '0.7.52',
    '0.7.54.11',  # invalid CRC in archive
    '0.7.51',  # no autoconf
)


class VersionFinder(html.parser.HTMLParser):
    def error(self, message):
        raise RuntimeError(message)

    def __init__(self):
        super().__init__()
        self.versions = []

    def handle_starttag(self, tag, attrs):
        if attrs:
            href = dict(attrs).get('href')
            if tag == 'a' and href and href.startswith('osm-3s'):
                version = href[len('osm-3s_v'):-len('.tar.gz')]
                self.versions.append(version)


def versions_to_build():
    parser = VersionFinder()
    response = urllib.request.urlopen(url)
    data = response.read().decode(response.headers.get_content_charset())
    parser.feed(data)

    return [
        version for version in parser.versions
        if version != '0.7'
        and not any(version.startswith(skip_prefix) for skip_prefix in skip_prefixes)
    ]


if __name__ == '__main__':
    versions = versions_to_build()
    github_matrix = {
        "include": [{"version": v} for v in versions]
    }
    print(json.dumps(github_matrix, indent=None))
