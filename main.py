import arena
import config
from time import sleep

arena.access_token = config.ARENA_TOKEN


def watch_chan(chan, on_new_block, poll_every=1):
    chan = arena.channels.channel(chan)
    blocks, _ = chan.contents()

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
        sleep(poll_every)


if __name__ == '__main__':
    def on_new_block(block):
        print('new block:', block.title)

    try:
        watch_chan(config.WATCH_CHAN, on_new_block)
    except (KeyboardInterrupt, SystemExit):
        pass