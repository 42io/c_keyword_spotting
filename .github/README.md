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
    house   | 0.955556 0.003704 0.040741 | 270
    zero    | 0.000000 0.944444 0.055556 | 270
    #unk#   | 0.014815 0.125926 0.859259 | 270

    CNN confusion matrix...
    house   | 0.940741 0.003704 0.055556 | 270
    zero    | 0.000000 0.959259 0.040741 | 270
    #unk#   | 0.025926 0.066667 0.907407 | 270

### Just for Fun
   This is how our neural network sees the world.

    ~$ bin/fe /tmp/google_speech_commands/happy/ab00c4b2_nohash_0.wav | awk '
         BEGIN { print "plot \"-\" with image notitle" }
         { for (i=1;i<=NF;i++) print NR, i, $i }
         END { print "e" }
         ' | gnuplot -p

![Features](mfcc_happy.png?raw=true "Features")
