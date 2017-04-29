# channel watch

## setup

install reqs:

    pip install -r requirements.txt

setup a `config.py` at `secret/config.py`. it should have the following values:

- `WATCH_CHAN`: the slug of the are.na chan to watch
- `ARENA_TOKEN`: auth token for are.na api access

## usage

run `main.py`


# pdf / web parsing from Are.na Channel

## setup

install reqs:

    R

add `ARCHIVE_CHAN = 'channel-slug'` to `secret/config.py` with token above

create directories `media` and `txt` if they don't exist

## usage

- run `rscript pulldown.R`
