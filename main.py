import arena
import config
import random
import pandas as pd
from time import sleep

adj_mat = pd.read_csv('data.csv', index_col='id')

arena.access_token = config.ARENA_TOKEN

patterns = [
    'This reminds of this passage:',
    'You might find this relevant:',
    'Sounds like this might be useful:',
    'I\'m reminded of:',
    'Have you read this before?',
    'Have you considered:',
]


def watch_chan(chan, on_new_block, poll_every=1, prob=0.02, replay=True):
    chan = arena.channels.channel(chan)
    blocks, _ = chan.contents()

    if replay:
        for b in blocks:
            on_new_block(b)

    while True:
        blocks_, _ = chan.contents()
        if len(blocks_) > len(blocks):
            new_blocks = blocks_[len(blocks):]
            for b in new_blocks:
                # wait until block data is written
                while b.title is None:
                    b = arena.Block(b.id)
                    sleep(poll_every*2)
                on_new_block(b)
            blocks = blocks_
        else:
            if random.random() < prob/poll_every:
                on_new_block(blocks[-1])
        sleep(poll_every)


def say(block):
    pattern = random.choice(patterns)
    id = get_similar(str(block.id))
    para = sample_text(id)
    para = '\n\n> {}\n'.format(para)
    statement = pattern + para
    print(statement)
    print('---')


def get_similar(id, choices=3):
    """returns the most similar id for the specified id"""
    choices = adj_mat.loc[id].sort_values(ascending=False).index[1:1+choices]
    return random.choice(choices)


def sample_text(id):
    """returns a random paragraph from block text of the specified id"""
    with open('texts/{}.txt'.format(id)) as f:
        text = f.read()
    paras = [p for p in text.split('\n') if p.strip()]
    return random.choice(paras)


if __name__ == '__main__':
    def on_new_block(block):
        say(block)

    try:
        watch_chan(config.WATCH_CHAN, on_new_block, replay=False)
    except (KeyboardInterrupt, SystemExit):
        pass