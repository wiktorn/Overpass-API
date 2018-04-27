import html.parser
import os
import pathlib
import shutil
import urllib.request

url = "http://dev.overpass-api.de/releases/"


class VersionFinder(html.parser.HTMLParser):
    def __init__(self):
        super().__init__()
        self.versions = []

    def handle_starttag(self, tag, attrs):
        if attrs:
            href = dict(attrs).get('href')
            if tag == 'a' and href and href.startswith('osm-3s'):
                version = href[len('osm-3s_v'):-len('.tar.gz')]
                self.versions.append(version)


def main():
    parser = VersionFinder()
    response = urllib.request.urlopen(url)
    data = response.read().decode(response.headers.get_content_charset())
    parser.feed(data)
    with open("Dockerfile.template") as f:
        template = f.read()
    for ver in parser.versions:
        os.mkdir(ver)
        with open(pathlib.Path(ver) / "Dockerfile", "w+") as f:
            f.write(template.format(version=ver))
        for i in ("etc", "bin"):
          shutil.copytree(i, pathlib.Path(ver) / i)
        shutil.copyfile("docker-entrypoint.sh", pathlib.Path(ver) / "docker-entrypoint.sh")

if __name__ == '__main__':
    main()
