# C Keyword Spotting
No C++, no dependency hell. Suitable for embedded devices.

### Demo
Default models pretrained on two words: house, zero.

    ~$ arecord -f S16_LE -c1 -r16000 -d1 test.wav
    ~$ aplay test.wav
    ~$ src/features/build.sh
    ~$ src/brain/build.sh
    ~$ bin/fe test.wav | bin/guess models/mlp.model
    ~$ bin/fe test.wav | bin/guess models/cnn.model

### Training
See [google speech commands dataset](https://storage.cloud.google.com/download.tensorflow.org/data/speech_commands_v0.02.tar.gz) for available words.

    ~$ apt install gcc fdupes sox wget
    ~$ dataset/main.sh house zero

It takes some time, be patient. Finally you'll see confusion matrix.

    MLP confusion matrix...
    house   | 0.951852 0.003704 0.044444 | 270
    zero    | 0.000000 0.929630 0.070370 | 270
    #unk#   | 0.018519 0.051852 0.929630 | 270

    CNN confusion matrix...
    house   | 0.970370 0.000000 0.029630 | 270
    zero    | 0.000000 0.974074 0.025926 | 270
    #unk#   | 0.014815 0.062963 0.922222 | 270

### Heap Memory Usage
Some magic numbers to know before stepping into embedded world.

    ~$ valgrind bin/fe test.wav                              # 1,047,256 bytes allocated
    ~$ bin/fe test.wav | valgrind bin/guess models/mlp.model # 615,280 bytes allocated
    ~$ bin/fe test.wav | valgrind bin/guess models/cnn.model # 2,908,048 bytes allocated

See [ESP32](https://github.com/42io/esp32_kws) example.

### Just for Fun
   This is how our neural network sees the world.

    ~$ bin/fe /tmp/google_speech_commands/happy/ab00c4b2_nohash_0.wav | awk '
         BEGIN { print "plot \"-\" with image notitle" }
         { for (i=1;i<=NF;i++) print NR, i, $i }
         END { print "e" }
         ' | gnuplot -p

![Features](mfcc_happy.png?raw=true "Features")
