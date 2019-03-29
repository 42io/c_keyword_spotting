# C Keyword Spotting
No C++, no dependency hell. Suitable for embedded devices.

### Demo
Default models pretrained on 0-9 words: zero one two three four five six seven eight nine.

    ~$ arecord -f S16_LE -c1 -r16000 -d1 test.wav
    ~$ aplay test.wav
    ~$ src/features/build.sh
    ~$ src/brain/build.sh
    ~$ bin/fe test.wav | bin/guess models/mlp.model
    ~$ bin/fe test.wav | bin/guess models/cnn.model
    ~$ bin/fe test.wav | bin/guess models/rnn.model

### Training
See [google speech commands dataset](https://storage.cloud.google.com/download.tensorflow.org/data/speech_commands_v0.02.tar.gz) for available words.

    ~$ apt install gcc fdupes sox mpg123 wget p7zip-full # Ubuntu 18.04
    ~$ dataset/main.sh zero one two three four five six seven eight nine

It takes some time, be patient. Finally you'll see confusion matrix.

    MLP confusion matrix...
    zero  | 0.90 0.00 0.03 0.00 0.00 0.00 0.00 0.02 0.00 0.00 0.04 0.00 | 603
    one   | 0.00 0.86 0.01 0.00 0.01 0.01 0.00 0.01 0.00 0.04 0.06 0.00 | 575
    two   | 0.03 0.01 0.87 0.00 0.02 0.00 0.00 0.02 0.01 0.00 0.03 0.01 | 564
    three | 0.00 0.00 0.02 0.87 0.00 0.00 0.01 0.02 0.03 0.01 0.03 0.00 | 548
    four  | 0.00 0.03 0.02 0.00 0.86 0.01 0.00 0.01 0.00 0.00 0.07 0.00 | 605
    five  | 0.00 0.01 0.00 0.01 0.01 0.82 0.00 0.03 0.01 0.03 0.07 0.00 | 607
    six   | 0.00 0.00 0.00 0.00 0.00 0.00 0.94 0.00 0.00 0.00 0.03 0.01 | 462
    seven | 0.00 0.00 0.00 0.00 0.00 0.00 0.01 0.94 0.00 0.00 0.03 0.01 | 574
    eight | 0.00 0.00 0.01 0.06 0.00 0.01 0.03 0.01 0.84 0.01 0.03 0.01 | 547
    nine  | 0.00 0.05 0.00 0.00 0.00 0.01 0.00 0.02 0.00 0.84 0.07 0.01 | 596
    #unk# | 0.04 0.05 0.03 0.04 0.02 0.05 0.03 0.03 0.01 0.05 0.66 0.02 | 730
    #pub# | 0.00 0.00 0.00 0.00 0.00 0.00 0.00 0.00 0.00 0.00 0.01 0.97 | 730
    MLP guessed wrong 998...

    CNN confusion matrix...
    zero  | 0.94 0.00 0.00 0.00 0.00 0.00 0.00 0.00 0.00 0.00 0.04 0.00 | 603
    one   | 0.00 0.94 0.00 0.00 0.00 0.00 0.00 0.00 0.00 0.01 0.05 0.00 | 575
    two   | 0.01 0.00 0.90 0.00 0.01 0.00 0.00 0.01 0.00 0.00 0.06 0.00 | 564
    three | 0.00 0.00 0.01 0.88 0.00 0.00 0.01 0.00 0.02 0.00 0.08 0.00 | 548
    four  | 0.00 0.00 0.00 0.00 0.91 0.00 0.00 0.00 0.00 0.00 0.07 0.01 | 605
    five  | 0.00 0.00 0.00 0.00 0.00 0.92 0.00 0.00 0.01 0.00 0.06 0.00 | 607
    six   | 0.00 0.00 0.00 0.00 0.00 0.00 0.97 0.00 0.00 0.00 0.02 0.01 | 462
    seven | 0.00 0.00 0.00 0.00 0.00 0.00 0.01 0.95 0.00 0.00 0.05 0.00 | 574
    eight | 0.00 0.00 0.00 0.01 0.01 0.01 0.00 0.00 0.94 0.00 0.03 0.00 | 547
    nine  | 0.00 0.01 0.00 0.00 0.00 0.00 0.00 0.00 0.01 0.90 0.09 0.00 | 596
    #unk# | 0.00 0.01 0.00 0.01 0.01 0.01 0.00 0.00 0.01 0.01 0.94 0.01 | 730
    #pub# | 0.00 0.00 0.00 0.00 0.00 0.00 0.00 0.00 0.00 0.00 0.01 0.98 | 730
    CNN guessed wrong 495...

    RNN confusion matrix...
    zero  | 0.97 0.00 0.00 0.00 0.00 0.00 0.00 0.01 0.00 0.00 0.01 0.00 | 603
    one   | 0.00 0.94 0.00 0.00 0.00 0.01 0.00 0.00 0.00 0.01 0.03 0.00 | 575
    two   | 0.01 0.00 0.96 0.00 0.01 0.00 0.00 0.00 0.00 0.00 0.01 0.01 | 564
    three | 0.00 0.00 0.01 0.94 0.00 0.00 0.00 0.01 0.02 0.00 0.03 0.00 | 548
    four  | 0.00 0.00 0.00 0.00 0.96 0.00 0.00 0.00 0.00 0.00 0.03 0.00 | 605
    five  | 0.00 0.00 0.00 0.00 0.00 0.92 0.00 0.00 0.01 0.01 0.04 0.00 | 607
    six   | 0.00 0.00 0.00 0.00 0.00 0.00 0.98 0.00 0.00 0.00 0.01 0.00 | 462
    seven | 0.00 0.00 0.00 0.00 0.00 0.00 0.00 0.98 0.00 0.00 0.01 0.00 | 574
    eight | 0.00 0.00 0.00 0.01 0.00 0.00 0.00 0.00 0.95 0.00 0.02 0.01 | 547
    nine  | 0.00 0.00 0.00 0.00 0.00 0.01 0.00 0.00 0.00 0.96 0.03 0.00 | 596
    #unk# | 0.01 0.01 0.00 0.01 0.02 0.01 0.00 0.00 0.01 0.01 0.91 0.01 | 730
    #pub# | 0.00 0.00 0.00 0.00 0.00 0.00 0.00 0.00 0.00 0.00 0.00 0.99 | 730
    RNN guessed wrong 320...

### Heap Memory Usage
Some magic numbers to know before stepping into embedded world.

    ~$ valgrind bin/fe test.wav                              # 1,047,256 bytes allocated
    ~$ bin/fe test.wav | valgrind bin/guess models/mlp.model # 622,768 bytes allocated
    ~$ bin/fe test.wav | valgrind bin/guess models/cnn.model # 2,445,100 bytes allocated
    ~$ bin/fe test.wav | valgrind bin/guess models/rnn.model # 403,772 bytes allocated

See [ESP32](https://github.com/42io/esp32_kws) example.

### Just for Fun
   This is how our neural network sees the world.

    ~$ bin/fe /tmp/google_speech_commands/_human_words_/happy/ab00c4b2_nohash_0.wav | awk '
         BEGIN { print "plot \"-\" with image notitle" }
         { for (i=1;i<=NF;i++) print NR, i, $i }
         END { print "e" }
         ' | gnuplot -p

![Features](mfcc_happy.png?raw=true "Features")
