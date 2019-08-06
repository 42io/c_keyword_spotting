# C Keyword Spotting
No C++, no dependency hell. Suitable for embedded devices.

### Demo
Default models pretrained on 0-9 words: zero one two three four five six seven eight nine.

    ~$ arecord -f S16_LE -c1 -r16000 -d1 test.wav
    ~$ aplay test.wav
    ~$ dataset/dataset/google_speech_commands/src/features/build.sh
    ~$ src/brain/build.sh
    ~$ alias fe=dataset/dataset/google_speech_commands/bin/fe
    ~$ fe test.wav | bin/guess models/mlp.model
    ~$ fe test.wav | bin/guess models/cnn.model
    ~$ fe test.wav | bin/guess models/rnn.model

### Training
See [google speech commands dataset](https://github.com/42io/dataset/tree/master/google_speech_commands#custom-words) for available words.

    ~$ apt install gcc lrzip wget
    ~$ wget https://github.com/42io/dataset/releases/download/v1.0/0-9up.lrz -O /tmp/0-9up.lrz
    ~$ lrunzip /tmp/0-9up.lrz -o /tmp/0-9up.data # md5 87fc2460c7b6cd3dcca6807e9de78833
    ~$ dataset/train.sh /tmp/0-9up.data 49 13 12 # inputs height, inputs width, outputs

It takes some time, be patient. Finally you'll see confusion matrix.

    MLP confusion matrix...
    zero  | 0.91 0.00 0.03 0.00 0.00 0.00 0.00 0.00 0.00 0.00 0.05 0.00 | 603
    one   | 0.00 0.92 0.00 0.01 0.00 0.01 0.00 0.00 0.00 0.02 0.05 0.00 | 575
    two   | 0.01 0.00 0.89 0.01 0.01 0.00 0.00 0.01 0.00 0.00 0.05 0.01 | 564
    three | 0.00 0.00 0.01 0.92 0.00 0.01 0.00 0.01 0.02 0.00 0.03 0.01 | 548
    four  | 0.00 0.01 0.01 0.00 0.89 0.00 0.00 0.00 0.00 0.00 0.07 0.00 | 605
    five  | 0.00 0.01 0.00 0.01 0.00 0.84 0.00 0.01 0.01 0.02 0.08 0.00 | 607
    six   | 0.00 0.00 0.00 0.00 0.00 0.00 0.97 0.00 0.00 0.00 0.01 0.01 | 462
    seven | 0.01 0.00 0.01 0.01 0.00 0.00 0.01 0.93 0.00 0.00 0.03 0.00 | 574
    eight | 0.00 0.00 0.01 0.03 0.00 0.00 0.01 0.00 0.91 0.00 0.03 0.01 | 547
    nine  | 0.00 0.03 0.00 0.01 0.00 0.01 0.00 0.00 0.00 0.86 0.08 0.01 | 596
    #unk# | 0.01 0.03 0.02 0.04 0.03 0.03 0.01 0.02 0.02 0.03 0.76 0.01 | 730
    #pub# | 0.00 0.00 0.00 0.00 0.01 0.00 0.01 0.01 0.00 0.00 0.01 0.95 | 730
    MLP guessed wrong 773...

    CNN confusion matrix...
    zero  | 0.97 0.00 0.00 0.00 0.00 0.00 0.00 0.00 0.00 0.00 0.03 0.00 | 603
    one   | 0.00 0.93 0.00 0.00 0.00 0.00 0.00 0.00 0.00 0.01 0.06 0.00 | 575
    two   | 0.01 0.00 0.95 0.00 0.01 0.00 0.00 0.00 0.00 0.00 0.02 0.00 | 564
    three | 0.00 0.00 0.01 0.94 0.00 0.00 0.00 0.00 0.01 0.00 0.03 0.00 | 548
    four  | 0.00 0.00 0.00 0.00 0.94 0.00 0.00 0.00 0.00 0.00 0.05 0.00 | 605
    five  | 0.00 0.00 0.00 0.00 0.00 0.95 0.00 0.00 0.00 0.00 0.04 0.00 | 607
    six   | 0.00 0.00 0.00 0.00 0.00 0.00 0.99 0.00 0.00 0.00 0.00 0.00 | 462
    seven | 0.00 0.00 0.00 0.00 0.00 0.00 0.00 0.98 0.00 0.00 0.01 0.00 | 574
    eight | 0.00 0.00 0.00 0.00 0.00 0.00 0.00 0.00 0.97 0.00 0.01 0.00 | 547
    nine  | 0.00 0.00 0.00 0.00 0.00 0.00 0.00 0.00 0.00 0.94 0.05 0.00 | 596
    #unk# | 0.00 0.01 0.00 0.01 0.01 0.00 0.00 0.00 0.00 0.00 0.95 0.01 | 730
    #pub# | 0.00 0.00 0.00 0.00 0.00 0.00 0.00 0.00 0.00 0.00 0.00 0.99 | 730
    CNN guessed wrong 291...

    RNN confusion matrix...
    zero  | 0.98 0.00 0.00 0.00 0.00 0.00 0.00 0.01 0.00 0.00 0.01 0.00 | 603
    one   | 0.00 0.95 0.00 0.00 0.00 0.01 0.00 0.00 0.00 0.01 0.03 0.00 | 575
    two   | 0.01 0.00 0.96 0.01 0.01 0.00 0.00 0.00 0.00 0.00 0.01 0.00 | 564
    three | 0.00 0.00 0.00 0.94 0.00 0.00 0.00 0.00 0.02 0.00 0.02 0.00 | 548
    four  | 0.00 0.00 0.00 0.00 0.97 0.00 0.00 0.00 0.00 0.00 0.02 0.00 | 605
    five  | 0.00 0.00 0.00 0.00 0.01 0.98 0.00 0.00 0.00 0.00 0.00 0.00 | 607
    six   | 0.00 0.00 0.00 0.00 0.00 0.00 0.98 0.00 0.00 0.00 0.01 0.00 | 462
    seven | 0.00 0.00 0.00 0.00 0.00 0.00 0.01 0.98 0.00 0.00 0.01 0.00 | 574
    eight | 0.00 0.00 0.00 0.01 0.00 0.01 0.00 0.00 0.97 0.00 0.01 0.00 | 547
    nine  | 0.00 0.00 0.00 0.00 0.00 0.01 0.00 0.00 0.00 0.97 0.01 0.01 | 596
    #unk# | 0.01 0.02 0.00 0.01 0.02 0.01 0.00 0.01 0.01 0.01 0.92 0.01 | 730
    #pub# | 0.00 0.00 0.00 0.00 0.00 0.00 0.00 0.00 0.00 0.00 0.01 0.98 | 730
    RNN guessed wrong 254...

### Heap Memory Usage
Some magic numbers to know before stepping into embedded world.

    ~$ valgrind dataset/dataset/google_speech_commands/bin/fe test.wav # 606,416 bytes allocated
    ~$ fe test.wav | valgrind bin/guess models/mlp.model               # 622,768 bytes allocated
    ~$ fe test.wav | valgrind bin/guess models/cnn.model               # 2,445,100 bytes allocated
    ~$ fe test.wav | valgrind bin/guess models/rnn.model               # 403,772 bytes allocated

See [ESP32](https://github.com/42io/esp32_kws) example.
