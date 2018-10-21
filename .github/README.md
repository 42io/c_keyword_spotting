# C Keyword Spotting
No C++, no dependency hell. Suitable for embedded devices.

### Demo
Default models pretrained on four words: house zero marvin visual.

    ~$ arecord -f S16_LE -c1 -r16000 -d1 test.wav
    ~$ aplay test.wav
    ~$ src/features/build.sh
    ~$ src/brain/build.sh
    ~$ bin/fe test.wav | bin/guess models/mlp.model
    ~$ bin/fe test.wav | bin/guess models/cnn.model

### Training
See [google speech commands dataset](https://storage.cloud.google.com/download.tensorflow.org/data/speech_commands_v0.02.tar.gz) for available words.

    ~$ apt install gcc fdupes sox wget
    ~$ dataset/main.sh house zero marvin visual

It takes some time, be patient. Finally you'll see confusion matrix.

    MLP confusion matrix...
    house   | 0.959259 0.000000 0.003704 0.007407 0.029630 | 270
    zero    | 0.003317 0.888889 0.018242 0.021559 0.067993 | 603
    marvin  | 0.000000 0.000000 0.945736 0.003876 0.050388 | 258
    visual  | 0.000000 0.013514 0.004505 0.936937 0.045045 | 222
    #unk#   | 0.046575 0.026027 0.132877 0.023288 0.771233 | 730


    CNN confusion matrix...
    house   | 0.974074 0.000000 0.000000 0.000000 0.025926 | 270
    zero    | 0.001658 0.966833 0.000000 0.006633 0.024876 | 603
    marvin  | 0.000000 0.000000 0.980620 0.000000 0.019380 | 258
    visual  | 0.000000 0.013514 0.000000 0.977477 0.009009 | 222
    #unk#   | 0.015068 0.026027 0.013699 0.012329 0.932877 | 730

### Heap Memory Usage
Some magic numbers to know before stepping into embedded world.

    ~$ valgrind bin/fe test.wav                              # 1,047,256 bytes allocated
    ~$ bin/fe test.wav | valgrind bin/guess models/mlp.model # 616,944 bytes allocated
    ~$ bin/fe test.wav | valgrind bin/guess models/cnn.model # 2,437,708 bytes allocated

See [ESP32](https://github.com/42io/esp32_kws) example.

### Just for Fun
   This is how our neural network sees the world.

    ~$ bin/fe /tmp/google_speech_commands/_human_words_/happy/ab00c4b2_nohash_0.wav | awk '
         BEGIN { print "plot \"-\" with image notitle" }
         { for (i=1;i<=NF;i++) print NR, i, $i }
         END { print "e" }
         ' | gnuplot -p

![Features](mfcc_happy.png?raw=true "Features")
